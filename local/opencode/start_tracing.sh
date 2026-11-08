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
"$REPO_DIR/langfuse/start.sh"
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

# OpenCode's Langfuse plugin supports environment variables, but it also reads
# this credentials file from the OpenCode config directory. Write both sources
# from langfuse/.env so plugin subprocesses receive the same credentials.
OPENCODE_CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/opencode"
OPENCODE_LANGFUSE_CONFIG="$OPENCODE_CONFIG_DIR/opencode-langfuse.json"
mkdir -p "$OPENCODE_CONFIG_DIR"
umask 077
printf '{\n  "publicKey": "%s",\n  "secretKey": "%s",\n  "baseUrl": "%s",\n  "environment": "%s",\n  "userId": "%s"\n}\n' \
    "$LANGFUSE_PUBLIC_KEY" \
    "$LANGFUSE_SECRET_KEY" \
    "$LANGFUSE_BASEURL" \
    "$LANGFUSE_ENVIRONMENT" \
    "$LANGFUSE_USER_ID" \
    > "$OPENCODE_LANGFUSE_CONFIG"
chmod 600 "$OPENCODE_LANGFUSE_CONFIG"
echo "Langfuse credentials configured at $OPENCODE_LANGFUSE_CONFIG."

# The harness start script selects `plugins` for OpenCode 2 and `plugin` for
# OpenCode 1.18.29+, after ensuring the CLI is installed.
export TRACE_TO_LANGFUSE=true
# The launcher starts from the repository root, so explicitly select the
# harness-local OpenCode config instead of relying on cwd-based discovery.
export OPENCODE_CONFIG="opencode.json"

cd "$REPO_DIR"
exec "$SCRIPT_DIR/start.sh"
