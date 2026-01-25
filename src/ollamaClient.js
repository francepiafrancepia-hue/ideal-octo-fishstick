import { setTimeout as sleep } from 'node:timers/promises';

const DEFAULT_HOST = process.env.OLLAMA_HOST ?? 'http://127.0.0.1:11434';
const DEFAULT_MODEL = process.env.OLLAMA_MODEL ?? 'llama3';
const readNumber = (value, fallback) => {
  const parsed = Number(value);
  return Number.isFinite(parsed) ? parsed : fallback;
};
const DEFAULT_TIMEOUT_MS = readNumber(process.env.OLLAMA_TIMEOUT_MS, 30000);
const DEFAULT_MAX_RETRIES = Math.max(0, readNumber(process.env.OLLAMA_MAX_RETRIES, 2));
const RETRY_DELAY_MS = readNumber(process.env.OLLAMA_RETRY_DELAY_MS, 750);

function buildUrl(host, path) {
  const base = host.endsWith('/') ? host.slice(0, -1) : host;
  return `${base}${path}`;
}

async function requestWithTimeout(url, options, timeoutMs) {
  const controller = new AbortController();
  const timeoutId = setTimeout(() => controller.abort(), timeoutMs);
  try {
    const response = await fetch(url, { ...options, signal: controller.signal });
    return response;
  } finally {
    clearTimeout(timeoutId);
  }
}

async function parseError(response) {
  const bodyText = await response.text();
  return bodyText ? `${response.status} ${response.statusText}: ${bodyText}` : `${response.status} ${response.statusText}`;
}

export async function generateCompletion({
  model = DEFAULT_MODEL,
  prompt,
  system,
  options,
  host = DEFAULT_HOST,
  timeoutMs = DEFAULT_TIMEOUT_MS,
  retries = DEFAULT_MAX_RETRIES
}) {
  const payload = {
    model,
    prompt,
    stream: false,
    ...(system ? { system } : {}),
    ...(options ? { options } : {})
  };

  const url = buildUrl(host, '/api/generate');
  let attempt = 0;
  let lastError;

  while (attempt <= retries) {
    try {
      const response = await requestWithTimeout(
        url,
        {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify(payload)
        },
        timeoutMs
      );

      if (!response.ok) {
        throw new Error(await parseError(response));
      }

      const data = await response.json();
      if (!data || typeof data.response !== 'string') {
        throw new Error('Unexpected Ollama response payload.');
      }

      return {
        model: data.model ?? model,
        response: data.response,
        done: data.done ?? true
      };
    } catch (error) {
      lastError = error;
      if (attempt >= retries) {
        break;
      }
      attempt += 1;
      await sleep(RETRY_DELAY_MS * attempt);
    }
  }

  throw lastError;
}

export async function listModels({ host = DEFAULT_HOST, timeoutMs = DEFAULT_TIMEOUT_MS } = {}) {
  const url = buildUrl(host, '/api/tags');
  const response = await requestWithTimeout(url, { method: 'GET' }, timeoutMs);
  if (!response.ok) {
    throw new Error(await parseError(response));
  }
  const data = await response.json();
  const models = Array.isArray(data?.models) ? data.models.map(model => model.name).filter(Boolean) : [];
  return models;
}

export function getDefaults() {
  return {
    host: DEFAULT_HOST,
    model: DEFAULT_MODEL,
    timeoutMs: DEFAULT_TIMEOUT_MS,
    retries: DEFAULT_MAX_RETRIES
  };
}
