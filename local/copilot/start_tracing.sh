#!/bin/bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
LANGFUSE_ENV="$REPO_DIR/langfuse/.env"

if [ ! -f "$LANGFUSE_ENV" ]; then
    echo "Missing $LANGFUSE_ENV. Configure Langfuse before starting tracing." >&2
    exit 1
fi

source "$LANGFUSE_ENV"
: "${LANGFUSE_PUBLIC_KEY:?Set LANGFUSE_PUBLIC_KEY in langfuse/.env}"
: "${LANGFUSE_SECRET_KEY:?Set LANGFUSE_SECRET_KEY in langfuse/.env}"
if [[ "$LANGFUSE_PUBLIC_KEY" == *CHANGEME* || "$LANGFUSE_SECRET_KEY" == *CHANGEME* ]]; then
    echo "Replace the Langfuse project key placeholders in langfuse/.env first." >&2
    exit 1
fi
LANGFUSE_BASE_URL="${LANGFUSE_BASE_URL:-http://localhost:3000}"
export COPILOT_OTEL_ENABLED=true
export OTEL_EXPORTER_OTLP_ENDPOINT="$LANGFUSE_BASE_URL/api/public/otel"
export OTEL_EXPORTER_OTLP_HEADERS="Authorization=Basic $(printf '%s' "$LANGFUSE_PUBLIC_KEY:$LANGFUSE_SECRET_KEY" | base64),x-langfuse-ingestion-version=4"
export OTEL_INSTRUMENTATION_GENAI_CAPTURE_MESSAGE_CONTENT="${OTEL_INSTRUMENTATION_GENAI_CAPTURE_MESSAGE_CONTENT:-true}"

"$REPO_DIR/langfuse/start.sh"

if ! command -v copilot >/dev/null 2>&1; then
    if ! command -v npm >/dev/null 2>&1; then
        echo "GitHub Copilot CLI is not installed and npm is unavailable." >&2
        exit 1
    fi
    npm install -g @github/copilot
fi

cd "$REPO_DIR"
exec copilot
