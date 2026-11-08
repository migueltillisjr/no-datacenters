# GitHub Copilot CLI Langfuse tracing

Copilot CLI uses native OpenTelemetry export, so no Langfuse plugin is needed.
This setup sends agent turns, model calls, tool calls, timing, and token usage
to Langfuse.

For an automated setup that starts Langfuse, configures OTLP export, and
launches Copilot CLI, run:

```bash
./start_tracing.sh
```

## Prerequisites

1. Start Langfuse with `langfuse/start.sh`.
2. Open `http://localhost:3000` and create a Langfuse project.
3. Copy the project's public and secret keys.

## Configure and start

Run these commands in the same shell that launches Copilot:

```bash
export COPILOT_OTEL_ENABLED=true
export OTEL_EXPORTER_OTLP_ENDPOINT="http://localhost:3000/api/public/otel"
export OTEL_EXPORTER_OTLP_HEADERS="Authorization=Basic $(printf '%s' \"$LANGFUSE_PUBLIC_KEY:$LANGFUSE_SECRET_KEY\" | base64),x-langfuse-ingestion-version=4"
export OTEL_INSTRUMENTATION_GENAI_CAPTURE_MESSAGE_CONTENT=true
copilot
```

Set `OTEL_INSTRUMENTATION_GENAI_CAPTURE_MESSAGE_CONTENT=false` to collect
metadata, timing, and token usage without storing prompts, responses, or tool
arguments. Keep the Basic Auth header out of committed files.
