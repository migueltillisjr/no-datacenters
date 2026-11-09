#!/bin/bash

# Purpose: Start OpenCode with a local Ollama model and optional Langfuse tracing.
# Usage:   ./local/opencode/start.sh
# Example: MODEL=qwen2.5-coder:7b ./local/opencode/start.sh

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
VENV_DIR="$SCRIPT_DIR/.opencode_venv"
REPO_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
LANGFUSE_ENV="$REPO_DIR/langfuse/.env"

if [ ! -x "$VENV_DIR/bin/python" ]; then
    "$SCRIPT_DIR/setup_python.sh"
fi

source "$VENV_DIR/bin/activate"

MODEL="${MODEL:-qwen3:4b-instruct}"
OLLAMA_CONTEXT_LENGTH="${OLLAMA_CONTEXT_LENGTH:-8000}"
OLLAMA_HOST="${OLLAMA_HOST:-127.0.0.1:11434}"
OLLAMA_BASE_URL="http://${OLLAMA_HOST%/}/v1"
OPENCODE_WARMUP_TIMEOUT="${OPENCODE_WARMUP_TIMEOUT:-10}"
OLLAMA_LOG_FILE="${OLLAMA_LOG_FILE:-${TMPDIR:-/tmp}/ollama-opencode.log}"
source "$SCRIPT_DIR/../lib/ollama.sh"
export OLLAMA_HOST

# Direct starts should use the local Langfuse project automatically when its
# project keys are configured. start_tracing.sh already exports this flag and
# credentials, so this remains idempotent for both entry points.
if [ "${TRACE_TO_LANGFUSE:-}" != "true" ] && [ -f "$LANGFUSE_ENV" ]; then
    source "$LANGFUSE_ENV"
    if [ -n "${LANGFUSE_PUBLIC_KEY:-}" ] \
        && [ -n "${LANGFUSE_SECRET_KEY:-}" ] \
        && [[ "$LANGFUSE_PUBLIC_KEY" != *CHANGEME* ]] \
        && [[ "$LANGFUSE_SECRET_KEY" != *CHANGEME* ]]; then
        export TRACE_TO_LANGFUSE=true
    fi
fi

if [ "${TRACE_TO_LANGFUSE:-false}" = "true" ]; then
    : "${LANGFUSE_PUBLIC_KEY:?Set LANGFUSE_PUBLIC_KEY in langfuse/.env}"
    : "${LANGFUSE_SECRET_KEY:?Set LANGFUSE_SECRET_KEY in langfuse/.env}"
    LANGFUSE_BASEURL="${LANGFUSE_BASEURL:-${LANGFUSE_BASE_URL:-http://localhost:3000}}"
    export LANGFUSE_PUBLIC_KEY LANGFUSE_SECRET_KEY LANGFUSE_BASEURL
    export LANGFUSE_ENVIRONMENT="${LANGFUSE_ENVIRONMENT:-development}"
    export LANGFUSE_USER_ID="${LANGFUSE_USER_ID:-harness}"
    export OPENCODE_CONFIG="opencode.json"

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

    if [ -x "$REPO_DIR/langfuse/start.sh" ]; then
        "$REPO_DIR/langfuse/start.sh"
    fi
    echo "Langfuse tracing enabled."
fi

export OLLAMA_HOST
export OPENCODE_MODEL="ollama/$MODEL"
OLLAMA_API_URL="http://${OLLAMA_HOST%/}"

# -----------------------------
# Install Ollama if necessary
# -----------------------------
if ! command -v ollama >/dev/null 2>&1; then
    echo "Ollama not found. Installing..."

    curl -fsSL https://ollama.com/install.sh | sh

    echo "Ollama installed."
else
    echo "Ollama already installed."
fi


# -----------------------------
# Install OpenCode if necessary
# -----------------------------
if ! command -v opencode >/dev/null 2>&1; then
    echo "OpenCode not found. Installing..."

    curl -fsSL https://opencode.ai/v2/install | bash

    # OpenCode installer commonly installs into ~/.opencode/bin
    export PATH="$HOME/.opencode/bin:$PATH"

    # Also include common local bin locations
    export PATH="$HOME/.local/bin:$PATH"

    if ! command -v opencode >/dev/null 2>&1; then
        echo "OpenCode was installed, but it is not currently in PATH."
        echo "Try opening a new terminal and running this script again."
        exit 1
    fi

    echo "OpenCode installed."
else
    echo "OpenCode already installed."
fi

# OpenCode 2 uses `plugins`; OpenCode 1.18.29+ uses `plugin`. Set the
# observability plugin after installation so the warm-up and user session both
# load the same Langfuse configuration.
if [ "${TRACE_TO_LANGFUSE:-false}" = "true" ]; then
    OPENCODE_VERSION="$(opencode --version 2>/dev/null | head -n 1 | grep -Eo '[0-9]+(\.[0-9]+)+' | head -n 1 || true)"
    OPENCODE_MAJOR="${OPENCODE_VERSION%%.*}"

    if [ "$OPENCODE_MAJOR" -ge 2 ] 2>/dev/null; then
        export OPENCODE_CONFIG_CONTENT="{\"model\":\"$OPENCODE_MODEL\",\"plugins\":[\"@langfuse/opencode-observability-plugin@latest\"],\"providers\":{\"ollama\":{\"name\":\"Ollama\",\"package\":\"@opencode/ai/providers/openai-compatible\",\"settings\":{\"baseURL\":\"$OLLAMA_BASE_URL\",\"apiKey\":\"ollama\"}}}}"
    else
        export OPENCODE_CONFIG_CONTENT="{\"model\":\"$OPENCODE_MODEL\",\"plugin\":[\"@langfuse/opencode-observability-plugin@latest\"],\"provider\":{\"ollama\":{\"npm\":\"@ai-sdk/openai-compatible\",\"options\":{\"baseURL\":\"$OLLAMA_BASE_URL\",\"apiKey\":\"ollama\"}}}}"
    fi

    echo "Langfuse tracing enabled for OpenCode $OPENCODE_VERSION."
fi


cleanup() {
    echo
    ollama_cleanup
}

trap cleanup EXIT INT TERM


echo
echo "Checking Ollama at $OLLAMA_API_URL..."
echo "Model:              $MODEL"
echo "Context:            $OLLAMA_CONTEXT_LENGTH"
echo "Endpoint:           http://$OLLAMA_HOST"
echo "RAM reserve target: 4000 MB"
echo "Parallel requests:  1"

LLAMA_ARG_FIT_TARGET=4000 \
OLLAMA_CONTEXT_LENGTH="$OLLAMA_CONTEXT_LENGTH" \
OLLAMA_NUM_PARALLEL=1 \
OLLAMA_KEEP_ALIVE=-1 \
    ollama_start_or_reuse


# -----------------------------
# Pull model if necessary
# -----------------------------
if ! ollama list | awk 'NR > 1 {print $1}' | grep -Fxq "$MODEL"; then

    echo
    echo "Downloading $MODEL..."

    ollama pull "$MODEL"

else

    echo
    echo "$MODEL already installed."

fi

# Load the model before launching OpenCode so the first prompt does not pay
# the model startup cost. Keep it resident for the whole session.
echo
echo "Warming up Ollama model..."
if ! curl -sf "$OLLAMA_API_URL/api/generate" \
    -H 'Content-Type: application/json' \
    -d "{\"model\":\"$MODEL\",\"prompt\":\"Reply with OK.\",\"stream\":false,\"keep_alive\":-1,\"think\":false,\"options\":{\"num_predict\":1}}" \
    >/dev/null; then
    echo "Warning: Ollama warm-up failed; the first prompt may be slower."
fi

echo "Warming up OpenCode harness..."
WARMUP_LOG="/tmp/opencode-warmup.log"
opencode run --standalone --model "ollama/$MODEL" \
    "Reply with OK only. Do not modify files or run commands." \
    >"$WARMUP_LOG" 2>&1 &
WARMUP_PID=$!
WARMUP_FINISHED=false

for i in $(seq 1 "$OPENCODE_WARMUP_TIMEOUT"); do
    if ! kill -0 "$WARMUP_PID" 2>/dev/null; then
        WARMUP_FINISHED=true
        break
    fi
    sleep 1
done

if [ "$WARMUP_FINISHED" = false ]; then
    kill "$WARMUP_PID" 2>/dev/null || true
    wait "$WARMUP_PID" 2>/dev/null || true
    echo "Warning: OpenCode warm-up exceeded ${OPENCODE_WARMUP_TIMEOUT}s; continuing to the interactive session."
elif wait "$WARMUP_PID"; then
    echo "OpenCode harness warm-up complete."
else
    echo "Warning: OpenCode harness warm-up failed; continuing to the interactive session."
    sed -n '1,80p' "$WARMUP_LOG" 2>/dev/null || true
fi


# -----------------------------
# Display status
# -----------------------------
echo
echo "Installed versions:"
echo "-------------------"

ollama --version

opencode --version || true


# -----------------------------
# Launch OpenCode
# -----------------------------
echo
echo "Launching OpenCode..."
echo "Model: $MODEL"
echo

exec opencode
