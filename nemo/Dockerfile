FROM nvcr.io/nvidia/nemo:24.05

WORKDIR /app

# Copy guardrails configuration
COPY config/ /app/config/

# Install NeMo Guardrails (separate pip package from NeMo framework)
RUN pip install --no-cache-dir nemoguardrails==0.9.0

EXPOSE 8000

CMD ["nemoguardrails", "server", "--config", "/app/config", "--port", "8000", "--host", "0.0.0.0"]
