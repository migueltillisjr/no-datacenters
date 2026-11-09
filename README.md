# no-datacenters

Local-first harnesses for experimenting with coding agents, Ollama models,
voice input, and self-hosted observability. The launchers in this repository
keep model inference and speech-to-text on the local machine; Langfuse is an
optional local Docker deployment for tracing.

## What is included

- Local Ollama launchers for Claude Code, Codex, and OpenCode.
- An OpenCode voice workflow using `whisper.cpp` and `ffmpeg`.
- A GitHub Copilot CLI tracing launcher using OpenTelemetry.
- A self-hosted Langfuse stack backed by PostgreSQL, ClickHouse, Redis, and
  MinIO.
- Per-harness Python 3 virtual-environment setup scripts.

## Prerequisites

The supported workflows target macOS and assume:

- [Ollama](https://ollama.com) (the launchers can install it when missing).
- Python 3, for the harness-local virtual environments.
- Node.js and npm for Claude Code, Codex, and GitHub Copilot CLI when those
  CLIs are not already installed.
- Docker Desktop with Docker Compose for Langfuse.
- A microphone, `ffmpeg`, and a `whisper.cpp` model for voice input.

The launchers install or download some missing dependencies. Review a script
before using it on a machine with existing Ollama processes or global CLI
configuration.

## Quick start

**NOTE:** With harnesses can take a while to warm up... but once they do, they work at a decent speed.

From the repository root, choose a harness:

```bash
./local/opencode/start.sh
./local/claude_code/start.sh
./local/codex/start.sh
```

Each launcher creates its harness-specific Python virtual environment on first
run, starts or reuses Ollama, downloads the configured model if necessary, and
opens the selected harness. The default model is `qwen3:4b-instruct`.

To select another model already available in Ollama, set `MODEL`:

```bash
MODEL=qwen2.5-coder:7b ./local/codex/start.sh
```

The launchers accept additional environment variables such as
`OLLAMA_CONTEXT_LENGTH`; see [NO_DATACENTERS.md](./NO_DATACENTERS.md) for the
shared Ollama setup and performance guidance.

## OpenCode voice workflow

The voice workflow records from the microphone, transcribes locally with
Whisper, and sends the transcription to OpenCode:

```bash
./local/opencode/voice_start.sh
```

Press Enter to start recording, press Enter again to stop, and use `Ctrl-C` to
exit. Configure the input device and recording behavior with variables such as
`AUDIO_INPUT`, `MAX_RECORD_SECONDS`, `SILENCE_DURATION`, and
`WHISPER_MODEL_PATH`.

See [local/opencode/README.md](./local/opencode/README.md) for microphone
selection, Whisper model configuration, and troubleshooting details.

## Optional Langfuse tracing

Langfuse is opt-in. To configure the local observability stack:

```bash
cd langfuse
cp .env.example .env
openssl rand -hex 32
```

Replace every `CHANGEME` value in `langfuse/.env`, use the generated value for
`ENCRYPTION_KEY`, then start Langfuse:

```bash
./start.sh
```

Open [http://localhost:3000](http://localhost:3000), create the first user,
create a project, and copy its API keys into `langfuse/.env`. Langfuse does not
provide a default login.

Launch a traced harness from the repository root with the corresponding
wrapper:

```bash
./local/opencode/start_tracing.sh
./local/claude_code/start_tracing.sh
./local/codex/start_tracing.sh
./local/copilot/start_tracing.sh
```

The wrappers validate the Langfuse configuration and configure the appropriate
plugin or OpenTelemetry exporter. See [langfuse/README.md](./langfuse/README.md)
and [langfuse/PLUGIN_SETUP.md](./langfuse/PLUGIN_SETUP.md) for the complete
setup.

To stop the Langfuse containers while keeping their named volumes:

```bash
./langfuse/stop.sh
```

Use `docker compose --env-file langfuse/.env -f langfuse/docker-compose.yml down -v`
only when the stored Langfuse data can be discarded.

## Repository layout

| Path | Purpose |
| --- | --- |
| [`local/opencode/`](./local/opencode/) | OpenCode launcher, voice workflow, and local setup docs |
| [`local/claude_code/`](./local/claude_code/) | Claude Code launcher and tracing wrapper |
| [`local/codex/`](./local/codex/) | Codex launcher and tracing wrapper |
| [`local/copilot/`](./local/copilot/) | GitHub Copilot CLI tracing integration |
| [`langfuse/`](./langfuse/) | Self-hosted Langfuse Compose deployment |
| [`NO_DATACENTERS.md`](./NO_DATACENTERS.md) | Detailed local-model harness instructions |
| [`CHANGELOG.md`](./CHANGELOG.md) | Release notes and implementation history |

## Configuration and security

- Never commit `langfuse/.env`; it contains database credentials and project
  keys.
- Treat Langfuse secret keys and generated Docker secrets as passwords.
- The default Langfuse deployment binds its services to localhost and is for
  local development and testing, not production or high availability.
- The launchers may stop an Ollama process they started when the session exits;
  check the selected script if you need to preserve a separately managed
  Ollama server.

## License

This project is licensed under the [Apache License, Version 2.0](./LICENSE).
Redistributions must preserve the copyright, license, and attribution notices
in [`NOTICE`](./NOTICE).
