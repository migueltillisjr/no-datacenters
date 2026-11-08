#!/bin/bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
VENV_DIR="$SCRIPT_DIR/.copilot"

if [ ! -x "$VENV_DIR/bin/python" ]; then
    "$SCRIPT_DIR/setup_python.sh"
fi

source "$VENV_DIR/bin/activate"

# The Copilot integration below is still a work in progress.

# MODEL="${MODEL:-qwen3:4b-instruct}"
# OLLAMA_CONTEXT_LENGTH="${OLLAMA_CONTEXT_LENGTH:-32768}"
# LLAMA_ARG_FIT_TARGET="${LLAMA_ARG_FIT_TARGET:-10000}"
# COPILOT_PROVIDER_MAX_OUTPUT_TOKENS="${COPILOT_PROVIDER_MAX_OUTPUT_TOKENS:-2048}"
# COPILOT_PROVIDER_MAX_PROMPT_TOKENS="${COPILOT_PROVIDER_MAX_PROMPT_TOKENS:-$((OLLAMA_CONTEXT_LENGTH - COPILOT_PROVIDER_MAX_OUTPUT_TOKENS))}"
# OLLAMA_LOG_FILE="/tmp/ollama-copilot.log"
# OLLAMA_PID=""
# RUN_DIR="${COPILOT_RUN_DIR:-$PWD}"
# RUN_DIR="$(cd "$RUN_DIR" && pwd -P)"

# export PATH="$HOME/.local/bin:$HOME/.npm-global/bin:$PATH"
# # Use only the configured local Ollama provider by default. Set this to false
# # when GitHub-hosted Copilot features and authentication are needed.
# export COPILOT_OFFLINE="${COPILOT_OFFLINE:-true}"

# run_copilot() {
#     COPILOT_PROVIDER_BASE_URL="${COPILOT_PROVIDER_BASE_URL:-http://localhost:11434/v1}" \
#     COPILOT_PROVIDER_TYPE="${COPILOT_PROVIDER_TYPE:-openai}" \
#     COPILOT_PROVIDER_API_KEY="${COPILOT_PROVIDER_API_KEY:-}" \
#     COPILOT_PROVIDER_WIRE_API="${COPILOT_PROVIDER_WIRE_API:-responses}" \
#     COPILOT_PROVIDER_MAX_PROMPT_TOKENS="$COPILOT_PROVIDER_MAX_PROMPT_TOKENS" \
#     COPILOT_PROVIDER_MAX_OUTPUT_TOKENS="$COPILOT_PROVIDER_MAX_OUTPUT_TOKENS" \
#     COPILOT_MODEL="$MODEL" \
#     copilot "$@"
# }

# configure_trusted_directory() {
#     if ! command -v node >/dev/null 2>&1; then
#         echo "Node.js is required to configure Copilot's trusted directory."
#         exit 1
#     fi

#     local copilot_home="${COPILOT_HOME:-$HOME/.copilot}"
#     local config_file="$copilot_home/config.json"
#     mkdir -p "$copilot_home"

#     node - "$config_file" "$RUN_DIR" <<'NODE'
# const fs = require("fs");
# const configFile = process.argv[2];
# const runDir = process.argv[3];

# function stripJsonComments(source) {
#   let result = "";
#   let string = false;
#   let escape = false;
#   let lineComment = false;
#   let blockComment = false;

#   for (let i = 0; i < source.length; i += 1) {
#     const current = source[i];
#     const next = source[i + 1];

#     if (lineComment) {
#       if (current === "\n") {
#         lineComment = false;
#         result += current;
#       }
#       continue;
#     }
#     if (blockComment) {
#       if (current === "*" && next === "/") {
#         blockComment = false;
#         i += 1;
#       } else if (current === "\n") {
#         result += current;
#       }
#       continue;
#     }
#     if (string) {
#       result += current;
#       if (escape) escape = false;
#       else if (current === "\\") escape = true;
#       else if (current === '"') string = false;
#       continue;
#     }
#     if (current === '"') {
#       string = true;
#       result += current;
#     } else if (current === "/" && next === "/") {
#       lineComment = true;
#       i += 1;
#     } else if (current === "/" && next === "*") {
#       blockComment = true;
#       i += 1;
#     } else {
#       result += current;
#     }
#   }
#   return result;
# }

# let config = {};
# if (fs.existsSync(configFile)) {
#   const raw = fs.readFileSync(configFile, "utf8");
#   try {
#     config = raw.trim() ? JSON.parse(stripJsonComments(raw)) : {};
#   } catch (error) {
#     console.error(`Unable to parse ${configFile}: ${error.message}`);
#     process.exit(1);
#   }
# }

# if (!Array.isArray(config.trustedFolders)) config.trustedFolders = [];
# if (!config.trustedFolders.includes(runDir)) {
#   config.trustedFolders.push(runDir);
#   fs.writeFileSync(configFile, `${JSON.stringify(config, null, 2)}\n`, { mode: 0o600 });
#   console.log(`Trusted Copilot directory: ${runDir}`);
# } else {
#   console.log(`Copilot directory already trusted: ${runDir}`);
# }
# NODE
# }

# if ! command -v ollama >/dev/null 2>&1; then
#     echo "Ollama not found. Installing..."
#     curl -fsSL https://ollama.com/install.sh | sh
# fi

# if ! command -v copilot >/dev/null 2>&1; then
#     if ! command -v npm >/dev/null 2>&1; then
#         echo "GitHub Copilot CLI is not installed and npm is unavailable. Install Node.js/npm, then rerun."
#         exit 1
#     fi
#     echo "GitHub Copilot CLI not found. Installing..."
#     npm install -g @github/copilot
# fi

# cleanup() {
#     echo
#     if [ -n "$OLLAMA_PID" ]; then
#         echo "Stopping Ollama..."
#         kill "$OLLAMA_PID" 2>/dev/null || true
#     fi
# }

# trap cleanup EXIT INT TERM

# echo "Stopping existing Ollama server..."
# pkill -f "ollama serve" 2>/dev/null || true
# sleep 1

# echo "Starting Ollama for GitHub Copilot CLI..."
# echo "Model:              $MODEL"
# echo "Context:            $OLLAMA_CONTEXT_LENGTH"
# echo "Fit target:         ${LLAMA_ARG_FIT_TARGET} MB"
# echo "Parallel requests:  1"

# LLAMA_ARG_FIT_TARGET="$LLAMA_ARG_FIT_TARGET" \
# OLLAMA_CONTEXT_LENGTH="$OLLAMA_CONTEXT_LENGTH" \
# OLLAMA_NUM_PARALLEL=1 \
# OLLAMA_KEEP_ALIVE=-1 \
# ollama serve >"$OLLAMA_LOG_FILE" 2>&1 &

# OLLAMA_PID=$!

# echo "Waiting for Ollama API..."
# for i in {1..30}; do
#     if curl -sf http://localhost:11434/api/tags >/dev/null; then
#         break
#     fi

#     if ! kill -0 "$OLLAMA_PID" 2>/dev/null; then
#         echo "Ollama failed to start. Check $OLLAMA_LOG_FILE."
#         cat "$OLLAMA_LOG_FILE"
#         exit 1
#     fi

#     sleep 1
# done

# if ! curl -sf http://localhost:11434/api/tags >/dev/null; then
#     echo "Ollama did not become ready. Check $OLLAMA_LOG_FILE."
#     cat "$OLLAMA_LOG_FILE"
#     exit 1
# fi

# if ! ollama list | awk 'NR > 1 {print $1}' | grep -Fxq "$MODEL"; then
#     echo "Downloading Ollama model $MODEL..."
#     ollama pull "$MODEL"
# fi

# echo "Configuring Copilot trusted directory: $RUN_DIR"
# configure_trusted_directory

# echo "Warming up Ollama model..."
# if ! curl -sf http://localhost:11434/api/generate \
#     -H 'Content-Type: application/json' \
#     -d "{\"model\":\"$MODEL\",\"prompt\":\"Reply with OK.\",\"stream\":false,\"keep_alive\":-1,\"think\":false,\"options\":{\"num_predict\":1}}" \
#     >/dev/null; then
#     echo "Warning: Ollama warm-up failed; the first prompt may be slower."
# fi

# echo "Warming up GitHub Copilot CLI harness..."
# if ! run_copilot \
#     -p "Reply with OK only. Do not modify files or run commands." \
#     --model "$MODEL" \
#     --silent \
#     >/dev/null 2>&1; then
#     echo "Warning: Copilot CLI harness warm-up failed; the first prompt may be slower."
# fi

# echo "GitHub Copilot CLI:"
# run_copilot --help >/dev/null 2>&1 || true
# echo "Launching GitHub Copilot CLI with local Ollama model..."
# run_copilot --model "$MODEL"

echo "Inprogress: This script is a work in progress and may not be fully functional yet."
