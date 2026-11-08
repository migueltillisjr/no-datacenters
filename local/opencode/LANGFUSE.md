# OpenCode Langfuse tracing

This setup sends OpenCode prompts, responses, reasoning, tool calls, retries,
compactions, failures, and session metadata to Langfuse.

For an automated setup that starts Langfuse, injects the tracing plugin, and
launches OpenCode, run:

```bash
./start_tracing.sh
```

## Prerequisites

1. Start Langfuse with `langfuse/start.sh`.
2. Open `http://localhost:3000` and create a Langfuse project.
3. Copy the project's public and secret keys.

## Add the plugin

For OpenCode 2, add this to the `opencode.json` or `opencode.jsonc` used by
the project:

```jsonc
{
  "plugins": ["@langfuse/opencode-observability-plugin@latest"]
}
```

For OpenCode 1.18.29 or newer, use the singular `plugin` key instead:

```jsonc
{
  "plugin": ["@langfuse/opencode-observability-plugin@latest"]
}
```

## Enable tracing

```bash
export LANGFUSE_PUBLIC_KEY="pk-lf-..."
export LANGFUSE_SECRET_KEY="sk-lf-..."
export LANGFUSE_BASEURL="http://localhost:3000"
export LANGFUSE_ENVIRONMENT="development"
export LANGFUSE_USER_ID="harness"
opencode
```

Restart OpenCode after changing the plugin configuration. Review the traces
in the Langfuse project and avoid enabling tracing for sensitive sessions.
