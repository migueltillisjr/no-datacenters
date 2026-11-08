# Codex Langfuse tracing

This setup sends Codex prompts, responses, reasoning summaries, tool calls,
subagents, token usage, and failed or interrupted turns to Langfuse.

For an automated setup that starts Langfuse, enables an isolated Codex tracing
configuration, and launches Codex, run:

```bash
./start_tracing.sh
```

## Prerequisites

1. Start Langfuse with `langfuse/start.sh`.
2. Open `http://localhost:3000` and create a Langfuse project.
3. Copy the project's public and secret keys.

## Install and enable the plugin

```bash
codex plugin marketplace add langfuse/codex-observability-plugin
codex plugin add tracing@codex-observability-plugin
```

Add this to `~/.codex/config.toml`:

```toml
[features]
hooks = true

[plugins."tracing@codex-observability-plugin"]
enabled = true
```

## Enable tracing

```bash
export TRACE_TO_LANGFUSE=true
export LANGFUSE_PUBLIC_KEY="pk-lf-..."
export LANGFUSE_SECRET_KEY="sk-lf-..."
export LANGFUSE_BASE_URL="http://localhost:3000"
codex
```

Approve the Langfuse Stop hook when Codex asks. Start a new session and send
two short messages; the latest turn is finalized by the next hook invocation.
Never commit these credentials or enable tracing for sensitive sessions.
