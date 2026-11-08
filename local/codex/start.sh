#!/bin/bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
VENV_DIR="$SCRIPT_DIR/.codex"

if [ ! -x "$VENV_DIR/bin/python" ]; then
    "$SCRIPT_DIR/setup_python.sh"
fi

source "$VENV_DIR/bin/activate"

MODEL="${MODEL:-qwen3:4b-instruct}"
OLLAMA_CONTEXT_LENGTH="${OLLAMA_CONTEXT_LENGTH:-8192}"
LLAMA_ARG_FIT_TARGET="${LLAMA_ARG_FIT_TARGET:-10000}"
OLLAMA_LOG_FILE="/tmp/ollama-codex.log"
OLLAMA_PID=""

export PATH="$HOME/.local/bin:$HOME/.npm-global/bin:$PATH"

if ! command -v ollama >/dev/null 2>&1; then
    echo "Ollama not found. Installing..."
    curl -fsSL https://ollama.com/install.sh | sh
fi

if ! command -v codex >/dev/null 2>&1; then
    if ! command -v npm >/dev/null 2>&1; then
        echo "Codex is not installed and npm is unavailable. Install Node.js/npm, then rerun."
        exit 1
    fi
    echo "Codex not found. Installing..."
    npm install -g @openai/codex
fi

cleanup() {
    echo
    if [ -n "$OLLAMA_PID" ]; then
        echo "Stopping Ollama..."
        kill "$OLLAMA_PID" 2>/dev/null || true
    fi
}

trap cleanup EXIT INT TERM

echo "Stopping existing Ollama server..."
pkill -f "ollama serve" 2>/dev/null || true
sleep 1

echo "Starting Ollama for Codex..."
echo "Model:              $MODEL"
echo "Context:            $OLLAMA_CONTEXT_LENGTH"
echo "Fit target:         ${LLAMA_ARG_FIT_TARGET} MB"
echo "Parallel requests:  1"

LLAMA_ARG_FIT_TARGET="$LLAMA_ARG_FIT_TARGET" \
OLLAMA_CONTEXT_LENGTH="$OLLAMA_CONTEXT_LENGTH" \
OLLAMA_NUM_PARALLEL=1 \
OLLAMA_KEEP_ALIVE=-1 \
ollama serve >"$OLLAMA_LOG_FILE" 2>&1 &

OLLAMA_PID=$!

echo "Waiting for Ollama API..."
for i in {1..30}; do
    if curl -sf http://localhost:11434/api/tags >/dev/null; then
        break
    fi

    if ! kill -0 "$OLLAMA_PID" 2>/dev/null; then
        echo "Ollama failed to start. Check $OLLAMA_LOG_FILE."
        cat "$OLLAMA_LOG_FILE"
        exit 1
    fi

    sleep 1
done

if ! curl -sf http://localhost:11434/api/tags >/dev/null; then
    echo "Ollama did not become ready. Check $OLLAMA_LOG_FILE."
    cat "$OLLAMA_LOG_FILE"
    exit 1
fi

if ! ollama list | awk 'NR > 1 {print $1}' | grep -Fxq "$MODEL"; then
    echo "Downloading Ollama model $MODEL..."
    ollama pull "$MODEL"
fi

echo "Warming up Ollama model..."
if ! curl -sf http://localhost:11434/api/generate \
    -H 'Content-Type: application/json' \
    -d "{\"model\":\"$MODEL\",\"prompt\":\"Reply with OK.\",\"stream\":false,\"keep_alive\":-1,\"think\":false,\"options\":{\"num_predict\":1}}" \
    >/dev/null; then
    echo "Warning: Ollama warm-up failed; the first prompt may be slower."
fi

echo "Warming up Codex harness..."
if ! ollama launch codex --model "$MODEL" -- \
    exec "Reply with OK only. Do not modify files or run commands." \
    >/dev/null 2>&1; then
    echo "Warning: Codex harness warm-up failed; the first prompt may be slower."
fi

echo "Codex:"
codex --version || true
echo "Launching Codex with local Ollama model..."
ollama launch codex --model "$MODEL"
