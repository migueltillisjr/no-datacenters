# Claude Code Langfuse tracing

This setup sends Claude Code prompts, responses, tool calls, sessions, and
timing data to the local Langfuse instance.

For an automated setup that starts Langfuse, configures the plugin, and
launches Claude Code, run:

```bash
./start_tracing.sh
```

## Prerequisites

1. Start Langfuse with `langfuse/start.sh`.
2. Open `http://localhost:3000` and create a Langfuse project.
3. Copy the project's public and secret keys.

## Install the plugin

```bash
claude plugin marketplace add langfuse/Claude-Observability-Plugin
claude plugin install langfuse-observability@langfuse-observability
```

## Enable tracing

Set these variables in the shell that starts Claude Code:

```bash
export TRACE_TO_LANGFUSE=true
export LANGFUSE_PUBLIC_KEY="pk-lf-..."
export LANGFUSE_SECRET_KEY="sk-lf-..."
export LANGFUSE_BASE_URL="http://localhost:3000"
claude
```

Restart Claude Code after installing or updating the plugin. Confirm traces in
the Langfuse project after completing a turn. Do not enable this for sessions
whose prompts, responses, or tool inputs must not be stored.
