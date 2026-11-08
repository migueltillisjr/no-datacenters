# OpenCode Langfuse tracing

This setup sends OpenCode prompts, responses, reasoning, tool calls, retries,
compactions, failures, and session metadata to Langfuse.

The Langfuse AI skill from `github.com/langfuse/skills` is installed at the
repository-level `.opencode/skills/langfuse/` directory. OpenCode discovers it
because `start_tracing.sh` launches the harness from the repository root. The
harness-local `opencode.json` is selected explicitly by the launcher and
declares the Langfuse plugin and loopback Ollama provider, so the plugin
remains enabled when OpenCode is launched through Ollama.

For an automated setup that starts Langfuse, configures the version-appropriate
OpenCode plugin key, and launches OpenCode, run:

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
export LANGFUSE_USER_ID="miguel@infopioneer.ai"
opencode
```

The tracing launcher detects the installed OpenCode major version and injects
the matching `plugins` or `plugin` configuration at runtime. It also exports
the Langfuse credentials before the warm-up request and the interactive
session. At startup it writes the values from `langfuse/.env` to
`~/.config/opencode/opencode-langfuse.json` with mode `600`, because the
Langfuse plugin supports that credential file as well as environment
variables. Review the traces in the Langfuse project and avoid enabling
tracing for sensitive sessions.
