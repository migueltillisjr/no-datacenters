# Harness tracing setup

These integrations send harness conversations, model responses, tool calls,
errors, timing, and token usage to the local Langfuse instance. Start the
Langfuse stack first and create a project at `http://localhost:3000`.

Copy the project's public and secret keys into `.env`. Do not commit `.env` or
place the secret key in a tracked harness configuration file.

## Claude Code

Claude Code has a first-party Langfuse observability plugin that uses Claude's
Stop hook. Install it with:

```bash
claude plugin marketplace add langfuse/Claude-Observability-Plugin
claude plugin install langfuse-observability@langfuse-observability
```

Enable tracing for the current shell before starting Claude Code:

```bash
export TRACE_TO_LANGFUSE=true
export LANGFUSE_PUBLIC_KEY="pk-lf-..."
export LANGFUSE_SECRET_KEY="sk-lf-..."
export LANGFUSE_BASE_URL="http://localhost:3000"
claude
```

Restart Claude Code after installation. The plugin captures prompts,
responses, tool calls, sessions, and timing. Review the plugin's privacy
settings before enabling full content capture.

## Codex

Codex has a first-party Langfuse observability plugin using plugin hooks:

```bash
codex plugin marketplace add langfuse/codex-observability-plugin
codex plugin add tracing@codex-observability-plugin
```

Enable hooks and the plugin in `~/.codex/config.toml`:

```toml
[features]
hooks = true

[plugins."tracing@codex-observability-plugin"]
enabled = true
```

Then start a new Codex session with tracing enabled:

```bash
export TRACE_TO_LANGFUSE=true
export LANGFUSE_PUBLIC_KEY="pk-lf-..."
export LANGFUSE_SECRET_KEY="sk-lf-..."
export LANGFUSE_BASE_URL="http://localhost:3000"
codex
```

Approve the Langfuse Stop hook when Codex asks. Send two short messages for
the first verification because the latest turn is finalized by the next hook
invocation.

## GitHub Copilot CLI

Copilot CLI has native OpenTelemetry export; no Langfuse plugin is required.
Set the endpoint and Basic Auth header in the shell that launches Copilot:

```bash
export COPILOT_OTEL_ENABLED=true
export OTEL_EXPORTER_OTLP_ENDPOINT="http://localhost:3000/api/public/otel"
export OTEL_EXPORTER_OTLP_HEADERS="Authorization=Basic $(printf '%s' \"$LANGFUSE_PUBLIC_KEY:$LANGFUSE_SECRET_KEY\" | base64),x-langfuse-ingestion-version=4"
export OTEL_INSTRUMENTATION_GENAI_CAPTURE_MESSAGE_CONTENT=true
copilot
```

Content capture is deliberately opt-in. Set it to `false` to send metadata,
timing, and token usage without storing prompts, responses, or tool arguments.
For CLI sessions, ensure the environment variables are visible to the process
that launches `copilot`.

## OpenCode

OpenCode has a first-party Langfuse observability plugin. Add it to the
OpenCode configuration used by this project. OpenCode 2 uses `plugins`; older
OpenCode 1.18.29+ uses `plugin`:

```jsonc
{
  "plugins": ["@langfuse/opencode-observability-plugin@latest"]
}
```

Set the credentials before launching OpenCode. OpenCode's plugin uses
`LANGFUSE_BASEURL` (without the underscore between `BASE` and `URL`):

```bash
export LANGFUSE_PUBLIC_KEY="pk-lf-..."
export LANGFUSE_SECRET_KEY="sk-lf-..."
export LANGFUSE_BASEURL="http://localhost:3000"
export LANGFUSE_ENVIRONMENT="development"
export LANGFUSE_USER_ID="your-user-id"
opencode
```

## Check reliability in Langfuse

After running each harness, inspect the project in Langfuse and filter by
environment or user. Review failed tool spans, retries, latency, token usage,
and completed versus interrupted turns. Keep content capture disabled for
sensitive work unless storing prompts, responses, and tool inputs is approved.

These instructions follow the maintained [Claude Code](https://langfuse.com/integrations/developer-tools/claude-code), [Codex](https://langfuse.com/integrations/developer-tools/codex), [GitHub Copilot](https://langfuse.com/integrations/developer-tools/github-copilot), and [OpenCode](https://langfuse.com/integrations/developer-tools/opencode) integrations.
