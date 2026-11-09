#!/bin/bash

# Purpose: Start Claude Code with a local Ollama model and managed settings.
# Usage:   ./local/claude_code/start.sh
# Example: MODEL=qwen2.5-coder:7b ./local/claude_code/start.sh

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
VENV_DIR="$SCRIPT_DIR/.claude_code"

if [ ! -x "$VENV_DIR/bin/python" ]; then
    "$SCRIPT_DIR/setup_python.sh"
fi

source "$VENV_DIR/bin/activate"

MODEL="${MODEL:-qwen3:4b-instruct}"
OLLAMA_CONTEXT_LENGTH="${OLLAMA_CONTEXT_LENGTH:-8192}"
LLAMA_ARG_FIT_TARGET="${LLAMA_ARG_FIT_TARGET:-10000}"
OLLAMA_HOST="${OLLAMA_HOST:-127.0.0.1:11434}"
OLLAMA_LOG_FILE="${OLLAMA_LOG_FILE:-${TMPDIR:-/tmp}/ollama-claude-code.log}"
source "$SCRIPT_DIR/../lib/ollama.sh"
export OLLAMA_HOST

export PATH="$HOME/.local/bin:$HOME/.npm-global/bin:$PATH"

if ! command -v ollama >/dev/null 2>&1; then
    echo "Ollama not found. Installing..."
    curl -fsSL https://ollama.com/install.sh | sh
fi

if ! command -v claude >/dev/null 2>&1; then
    if ! command -v npm >/dev/null 2>&1; then
        echo "Claude Code is not installed and npm is unavailable. Install Node.js/npm, then rerun."
        exit 1
    fi
    echo "Claude Code not found. Installing..."
    npm install -g @anthropic-ai/claude-code
fi

cleanup() {
    echo
    ollama_cleanup
}

trap cleanup EXIT INT TERM

echo "Starting Ollama for Claude Code..."
echo "Model:              $MODEL"
echo "Context:            $OLLAMA_CONTEXT_LENGTH"
echo "Fit target:         ${LLAMA_ARG_FIT_TARGET} MB"
echo "Parallel requests:  1"

LLAMA_ARG_FIT_TARGET="$LLAMA_ARG_FIT_TARGET" \
OLLAMA_CONTEXT_LENGTH="$OLLAMA_CONTEXT_LENGTH" \
OLLAMA_NUM_PARALLEL=1 \
OLLAMA_KEEP_ALIVE=-1 \
    ollama_start_or_reuse

if ! ollama list | awk 'NR > 1 {print $1}' | grep -Fxq "$MODEL"; then
    echo "Downloading Ollama model $MODEL..."
    ollama pull "$MODEL"
fi

echo "Warming up Ollama model..."
if ! curl -sf "$OLLAMA_API_URL/api/generate" \
    -H 'Content-Type: application/json' \
    -d "{\"model\":\"$MODEL\",\"prompt\":\"Reply with OK.\",\"stream\":false,\"keep_alive\":-1,\"think\":false,\"options\":{\"num_predict\":1}}" \
    >/dev/null; then
    echo "Warning: Ollama warm-up failed; the first prompt may be slower."
fi

echo "Warming up Claude Code harness..."
if ! ollama launch claude --model "$MODEL" -- \
    -p "Reply with OK only. Do not modify files or run commands." \
    >/dev/null 2>&1; then
    echo "Warning: Claude Code harness warm-up failed; the first prompt may be slower."
fi

echo "Claude Code:"
claude --version || true
echo "Launching Claude Code with local Ollama model..."
ollama launch claude --model "$MODEL"
