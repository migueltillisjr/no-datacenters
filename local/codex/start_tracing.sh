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
export TRACE_TO_LANGFUSE=true LANGFUSE_PUBLIC_KEY LANGFUSE_SECRET_KEY LANGFUSE_BASE_URL

"$REPO_DIR/langfuse/start.sh"

if ! command -v codex >/dev/null 2>&1; then
    if ! command -v npm >/dev/null 2>&1; then
        echo "Codex is not installed and npm is unavailable." >&2
        exit 1
    fi
    npm install -g @openai/codex
fi

# Use a dedicated Codex home so tracing setup does not rewrite the user's
# existing config or session history. Set CODEX_HOME explicitly to opt out.
CODEX_HOME_DIR="${CODEX_HOME:-$SCRIPT_DIR/.codex_tracing_home}"
export CODEX_HOME="$CODEX_HOME_DIR"
mkdir -p "$CODEX_HOME_DIR"
CODEX_CONFIG="$CODEX_HOME_DIR/config.toml"
if [ ! -f "$CODEX_CONFIG" ]; then
    printf '[features]\nhooks = true\n\n[plugins."tracing@codex-observability-plugin"]\nenabled = true\n' > "$CODEX_CONFIG"
fi

codex plugin marketplace add langfuse/codex-observability-plugin >/dev/null 2>&1 || true
codex plugin add tracing@codex-observability-plugin >/dev/null 2>&1 || true

cd "$REPO_DIR"
exec "$SCRIPT_DIR/start.sh"
