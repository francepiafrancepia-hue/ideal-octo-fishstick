FROM python:3.11-slim

WORKDIR /app

RUN pip install --no-cache-dir fastapi uvicorn[standard] httpx

COPY nemo_proxy.py .

EXPOSE 8002

CMD ["uvicorn", "nemo_proxy:app", "--host", "0.0.0.0", "--port", "8002"]
