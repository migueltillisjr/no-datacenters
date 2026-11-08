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
LANGFUSE_BASEURL="${LANGFUSE_BASEURL:-${LANGFUSE_BASE_URL:-http://localhost:3000}}"
export LANGFUSE_PUBLIC_KEY LANGFUSE_SECRET_KEY LANGFUSE_BASEURL
export LANGFUSE_ENVIRONMENT="${LANGFUSE_ENVIRONMENT:-development}"
export LANGFUSE_USER_ID="${LANGFUSE_USER_ID:-harness}"

# Inject the plugin without modifying the project's existing OpenCode config.
export OPENCODE_CONFIG_CONTENT='{"plugins":["@langfuse/opencode-observability-plugin@latest"]}'

"$REPO_DIR/langfuse/start.sh"

cd "$REPO_DIR"
exec "$SCRIPT_DIR/start.sh"
