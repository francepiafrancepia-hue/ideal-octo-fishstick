"""
NeMo Guardrails proxy — FastAPI service that bridges OpenAI-compatible clients
with the NeMo Guardrails server.

Bugs fixed vs. original:
  1. Added proper SSE streaming support (event: data lines)
  2. Fixed HTTP status code propagation (was always returning 200)
  3. Fixed response ID generation (uuid4 instead of sequential counter)
"""

from __future__ import annotations

import json
import logging
import time
import uuid
from contextlib import asynccontextmanager
from typing import AsyncIterator

import httpx
from fastapi import FastAPI, HTTPException, Request
from fastapi.responses import JSONResponse, StreamingResponse

NEMO_URL = "http://nemo:8000"  # Internal container URL

logger = logging.getLogger("nemo-proxy")

_client: httpx.AsyncClient


@asynccontextmanager
async def lifespan(_app: FastAPI):
    global _client  # noqa: PLW0603
    _client = httpx.AsyncClient(timeout=120.0)
    try:
        yield
    finally:
        await _client.aclose()


app = FastAPI(title="NeMo Proxy", version="1.0.0", lifespan=lifespan)


# ---------------------------------------------------------------------------
# Health check
# ---------------------------------------------------------------------------

@app.get("/health")
async def health() -> dict:
    return {"status": "ok", "service": "nemo-proxy"}


# ---------------------------------------------------------------------------
# Chat completions endpoint
# ---------------------------------------------------------------------------

@app.post("/v1/chat/completions")
async def chat_completions(request: Request) -> StreamingResponse | JSONResponse:
    body: dict = await request.json()

    # Inject config_id so NeMo knows which guardrails config to use
    config_id = body.pop("config_id", "default")

    messages = body.get("messages", [])
    stream: bool = body.get("stream", False)

    # Build NeMo request — NeMo v0.9+ uses /v1/chat/completions with config_id header
    nemo_payload = {
        "config_id": config_id,
        "messages": messages,
        "stream": stream,
    }
    # Forward any extra model parameters
    for key in ("temperature", "max_tokens", "top_p"):
        if key in body:
            nemo_payload[key] = body[key]

    if stream:
        return StreamingResponse(
            _stream_nemo(nemo_payload),
            media_type="text/event-stream",
        )

    return await _chat_nemo(nemo_payload)


# ---------------------------------------------------------------------------
# Non-streaming path
# ---------------------------------------------------------------------------

async def _chat_nemo(payload: dict) -> JSONResponse:
    try:
        resp = await _client.post(
            f"{NEMO_URL}/v1/chat/completions",
            json=payload,
            headers={"Content-Type": "application/json"},
        )
    except httpx.RequestError as exc:
        logger.error("NeMo connection error: %s", exc)
        raise HTTPException(status_code=502, detail="Upstream guardrails service unavailable") from exc

    # Bug fix #2: propagate non-200 status codes; log details server-side only
    if resp.status_code != 200:
        logger.error("NeMo returned %d: %s", resp.status_code, resp.text)
        raise HTTPException(
            status_code=resp.status_code,
            detail="Upstream guardrails service error",
        )

    data = resp.json()

    # Bug fix #3: ensure a stable uuid-based response ID
    if not data.get("id") or data["id"].startswith("chatcmpl-0"):
        data["id"] = f"chatcmpl-{uuid.uuid4().hex}"

    return JSONResponse(content=data)


# ---------------------------------------------------------------------------
# Streaming path
# ---------------------------------------------------------------------------

async def _stream_nemo(payload: dict) -> AsyncIterator[str]:
    """Yield SSE events from NeMo, re-formatted as proper OpenAI SSE chunks."""
    request_id = f"chatcmpl-{uuid.uuid4().hex}"
    created = int(time.time())

    try:
        async with _client.stream(
            "POST",
            f"{NEMO_URL}/v1/chat/completions",
            json=payload,
            headers={"Content-Type": "application/json"},
        ) as resp:
            if resp.status_code != 200:
                error_body = await resp.aread()
                logger.error("NeMo stream error %d: %s", resp.status_code, error_body.decode())
                yield 'data: {"error": "Upstream guardrails service error"}\n\n'
                return

            async for line in resp.aiter_lines():
                line = line.strip()
                if not line:
                    continue

                # NeMo may return raw JSON lines or SSE "data: ..." lines
                if line.startswith("data:"):
                    raw = line[5:].strip()
                else:
                    raw = line

                if raw == "[DONE]":
                    yield "data: [DONE]\n\n"
                    return

                try:
                    chunk = json.loads(raw)
                except json.JSONDecodeError:
                    continue

                # Bug fix #3: normalise chunk ID
                chunk["id"] = request_id
                chunk.setdefault("created", created)
                chunk.setdefault("object", "chat.completion.chunk")
                chunk.setdefault("model", payload.get("model", "nemo-guarded"))

                # Bug fix #1: proper SSE format
                yield f"data: {json.dumps(chunk)}\n\n"

    except httpx.RequestError as exc:
        logger.error("NeMo stream connection error: %s", exc)
        yield 'data: {"error": "Upstream guardrails service unavailable"}\n\n'

    yield "data: [DONE]\n\n"
