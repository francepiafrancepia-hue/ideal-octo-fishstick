# ideal-octo-fishstick

MCP server for Ollama with a small catalog of agent skills.

## Requirements

- Node.js 18+
- An Ollama server running locally (default: `http://127.0.0.1:11434`)

## Setup

```bash
npm install
```

## Run the MCP server

```bash
npm start
```

Environment variables:

- `OLLAMA_HOST` (default: `http://127.0.0.1:11434`)
- `OLLAMA_MODEL` (default: `llama3`)
- `OLLAMA_TIMEOUT_MS` (default: `30000`)
- `OLLAMA_MAX_RETRIES` (default: `2`)
- `OLLAMA_RETRY_DELAY_MS` (default: `750`)

## Available tools

- `ollama_generate`: send a prompt to Ollama.
- `ollama_list_models`: list local Ollama models.
- `agent_skill`: run a curated skill (`summarize`, `outline`, `brainstorm`).
- `list_agent_skills`: list skill names and descriptions.
