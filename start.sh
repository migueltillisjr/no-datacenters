#!/bin/bash

set -e

MODEL="qwen3:4b-instruct"

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


# -----------------------------
# Cleanup
# -----------------------------
OLLAMA_PID=""

cleanup() {
    echo

    if [ -n "$OLLAMA_PID" ]; then
        echo "Stopping Ollama..."
        kill "$OLLAMA_PID" 2>/dev/null || true
    fi
}

trap cleanup EXIT INT TERM


# -----------------------------
# Stop existing Ollama server
# -----------------------------
echo "Stopping existing Ollama server..."

pkill -f "ollama serve" 2>/dev/null || true

sleep 1


# -----------------------------
# Start Ollama
# -----------------------------
echo
echo "Starting Ollama..."
echo "Model:              $MODEL"
echo "Context:            32768"
echo "RAM reserve target: 2048 MB"
echo "Parallel requests:  1"
echo

LLAMA_ARG_FIT_TARGET=2048 \
OLLAMA_CONTEXT_LENGTH=32768 \
OLLAMA_NUM_PARALLEL=1 \
OLLAMA_KEEP_ALIVE=-1 \
ollama serve > /tmp/ollama.log 2>&1 &

OLLAMA_PID=$!


# -----------------------------
# Wait for Ollama API
# -----------------------------
echo "Waiting for Ollama API..."

for i in {1..30}; do

    if curl -sf http://localhost:11434/api/tags >/dev/null; then
        break
    fi

    if ! kill -0 "$OLLAMA_PID" 2>/dev/null; then
        echo
        echo "Ollama failed to start."
        echo
        cat /tmp/ollama.log
        exit 1
    fi

    sleep 1

done


# Final readiness check
if ! curl -sf http://localhost:11434/api/tags >/dev/null; then
    echo
    echo "Ollama did not become ready."
    echo
    cat /tmp/ollama.log
    exit 1
fi

echo "Ollama ready."


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

ollama launch opencode --model "$MODEL"
