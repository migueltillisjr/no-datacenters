#!/bin/bash

# Purpose: Start Langfuse and launch Claude Code with tracing enabled.
# Usage:   ./local/claude_code/start_tracing.sh

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
LANGFUSE_ENV="$REPO_DIR/langfuse/.env"

if [ ! -f "$LANGFUSE_ENV" ]; then
    echo "Missing $LANGFUSE_ENV. Configure Langfuse before starting tracing." >&2
    exit 1
fi

# Load the env file without exporting unrelated database credentials.
source "$LANGFUSE_ENV"
"$REPO_DIR/langfuse/start.sh"
: "${LANGFUSE_PUBLIC_KEY:?Set LANGFUSE_PUBLIC_KEY in langfuse/.env}"
: "${LANGFUSE_SECRET_KEY:?Set LANGFUSE_SECRET_KEY in langfuse/.env}"
if [[ "$LANGFUSE_PUBLIC_KEY" == *CHANGEME* || "$LANGFUSE_SECRET_KEY" == *CHANGEME* ]]; then
    echo "Replace the Langfuse project key placeholders in langfuse/.env first." >&2
    exit 1
fi
LANGFUSE_BASE_URL="${LANGFUSE_BASE_URL:-http://localhost:3000}"
export TRACE_TO_LANGFUSE=true LANGFUSE_PUBLIC_KEY LANGFUSE_SECRET_KEY LANGFUSE_BASE_URL

if ! command -v claude >/dev/null 2>&1; then
    if ! command -v npm >/dev/null 2>&1; then
        echo "Claude Code is not installed and npm is unavailable." >&2
        exit 1
    fi
    npm install -g @anthropic-ai/claude-code
fi

claude plugin marketplace add langfuse/Claude-Observability-Plugin >/dev/null 2>&1 || true
claude plugin install langfuse-observability@langfuse-observability >/dev/null 2>&1 || true

cd "$REPO_DIR"
exec "$SCRIPT_DIR/start.sh"
