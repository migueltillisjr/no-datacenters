#!/bin/bash

# Purpose: Record microphone input, transcribe it locally, and send it to OpenCode.
# Usage:   ./local/opencode/voice_start.sh
# Example: AUDIO_INPUT=:2 ./local/opencode/voice_start.sh

set -euo pipefail

MODEL="${MODEL:-qwen3:4b-instruct}"
OPENCODE_MODEL="ollama/$MODEL"
WHISPER_MODEL_URL="${WHISPER_MODEL_URL:-https://huggingface.co/ggerganov/whisper.cpp/resolve/main/ggml-base.en.bin?download=true}"
WHISPER_MODEL_PATH="${WHISPER_MODEL_PATH:-$HOME/.cache/whisper.cpp/ggml-base.en.bin}"
# AVFoundation audio devices: :0 iPhone, :1 MacBook Pro, :2 AirPods Pro.
AUDIO_INPUT="${AUDIO_INPUT:-:1}"
MAX_RECORD_SECONDS="${MAX_RECORD_SECONDS:-60}"
SILENCE_DURATION="${SILENCE_DURATION:-1.2}"
SILENCE_THRESHOLD="${SILENCE_THRESHOLD:--35dB}"
START_THRESHOLD="${START_THRESHOLD:--45dB}"
OLLAMA_CONTEXT_LENGTH="${OLLAMA_CONTEXT_LENGTH:-8192}"
OLLAMA_HOST="${OLLAMA_HOST:-127.0.0.1:11434}"
OLLAMA_LOG_FILE="${OLLAMA_LOG_FILE:-${TMPDIR:-/tmp}/ollama-opencode-voice.log}"
WORK_DIR="${TMPDIR:-/tmp}/opencode-voice"
FFMPEG_LOG_FILE="$WORK_DIR/ffmpeg.log"

source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/../lib/ollama.sh"
export OLLAMA_HOST

mkdir -p "$WORK_DIR" "$(dirname "$WHISPER_MODEL_PATH")"

# -----------------------------
# Install local prerequisites
# -----------------------------
if ! command -v brew >/dev/null 2>&1; then
    echo "Homebrew is required to install whisper.cpp and ffmpeg."
    echo "Install it from https://brew.sh, then run this script again."
    exit 1
fi

if ! command -v ollama >/dev/null 2>&1; then
    echo "Ollama not found. Installing..."
    curl -fsSL https://ollama.com/install.sh | sh
fi

if ! command -v opencode >/dev/null 2>&1; then
    echo "OpenCode not found. Installing..."
    curl -fsSL https://opencode.ai/v2/install | bash
fi

export PATH="$HOME/.opencode/bin:$HOME/.local/bin:$PATH"

if ! command -v opencode >/dev/null 2>&1; then
    echo "OpenCode was installed, but it is not currently in PATH."
    echo "Open a new terminal and run this script again."
    exit 1
fi

if ! command -v whisper-cli >/dev/null 2>&1; then
    echo "Installing whisper.cpp..."
    brew install whisper-cpp
fi

if ! command -v ffmpeg >/dev/null 2>&1; then
    echo "Installing ffmpeg..."
    brew install ffmpeg
fi

# -----------------------------
# Download a CPU-friendly Whisper model
# -----------------------------
if [ ! -f "$WHISPER_MODEL_PATH" ]; then
    echo "Downloading Whisper model to $WHISPER_MODEL_PATH..."
    curl -fL "$WHISPER_MODEL_URL" -o "$WHISPER_MODEL_PATH"
fi

# -----------------------------
# Ollama lifecycle
# -----------------------------
FFMPEG_PID=""

cleanup() {
    echo
    if [ -n "$FFMPEG_PID" ]; then
        kill -INT "$FFMPEG_PID" 2>/dev/null || true
    fi

    ollama_cleanup
}

trap cleanup EXIT
trap 'exit 130' INT TERM

echo
echo "Starting Ollama..."
echo "Model: $MODEL"
echo "CPU-focused context: $OLLAMA_CONTEXT_LENGTH"

LLAMA_ARG_FIT_TARGET=2048 \
OLLAMA_CONTEXT_LENGTH="$OLLAMA_CONTEXT_LENGTH" \
OLLAMA_NUM_PARALLEL=1 \
OLLAMA_KEEP_ALIVE=-1 \
    ollama_start_or_reuse

if ! ollama list | awk 'NR > 1 {print $1}' | grep -Fxq "$MODEL"; then
    echo "Downloading Ollama model $MODEL..."
    ollama pull "$MODEL"
fi

# Load the model before the first voice command so the first response does not
# pay the model startup cost. Keep it resident for the whole voice session.
echo "Warming up Ollama model..."
if ! curl -sf "$OLLAMA_API_URL/api/generate" \
    -H 'Content-Type: application/json' \
    -d "{\"model\":\"$MODEL\",\"prompt\":\"Reply with OK.\",\"stream\":false,\"keep_alive\":-1,\"think\":false,\"options\":{\"num_predict\":1}}" \
    >/dev/null; then
    echo "Warning: Ollama warm-up failed; the first command may be slower."
fi

echo
echo "Voice control is ready."
echo "Speak after pressing Enter; recording stops after ${SILENCE_DURATION}s of silence."
echo "Maximum recording duration: ${MAX_RECORD_SECONDS}s"
echo "Audio input: $AUDIO_INPUT"
echo "Press Ctrl-C to stop."

# -----------------------------
# Voice command loop
# -----------------------------
while true; do
    printf '\nPress Enter to record, or type q then Enter to quit: '
    IFS= read -r action

    if [ "$action" = "q" ] || [ "$action" = "Q" ]; then
        break
    fi

    AUDIO_FILE="$WORK_DIR/command.wav"
    TRANSCRIPT_PREFIX="$WORK_DIR/transcript"
    TRANSCRIPT_FILE="${TRANSCRIPT_PREFIX}.txt"

    echo "Listening... Press Enter again to stop recording early."
    rm -f "$FFMPEG_LOG_FILE"
    ffmpeg -hide_banner -loglevel info -y \
        -f avfoundation \
        -i "$AUDIO_INPUT" \
        -t "$MAX_RECORD_SECONDS" \
        -af "silencedetect=noise=${SILENCE_THRESHOLD}:d=${SILENCE_DURATION},silenceremove=start_periods=1:start_duration=0.05:start_threshold=${START_THRESHOLD}:stop_periods=1:stop_duration=${SILENCE_DURATION}:stop_threshold=${SILENCE_THRESHOLD}" \
        -ar 16000 \
        -ac 1 \
        -c:a pcm_s16le \
        "$AUDIO_FILE" 2> >(tee "$FFMPEG_LOG_FILE" >&2) &

    FFMPEG_PID=$!

    while kill -0 "$FFMPEG_PID" 2>/dev/null; do
        # macOS's system Bash only accepts whole seconds for read -t.
        if IFS= read -r -t 1; then
            echo "Stopping recording..."
            kill -INT "$FFMPEG_PID" 2>/dev/null || true
            break
        fi
    done

    wait "$FFMPEG_PID" 2>/dev/null || true
    FFMPEG_PID=""

    echo "Audio diagnostics saved to $FFMPEG_LOG_FILE"

    rm -f "$TRANSCRIPT_FILE"
    whisper-cli \
        -m "$WHISPER_MODEL_PATH" \
        -f "$AUDIO_FILE" \
        -nt \
        -otxt \
        -of "$TRANSCRIPT_PREFIX" \
        >/dev/null 2>&1

    if [ ! -s "$TRANSCRIPT_FILE" ]; then
        echo "No speech was recognized."
        continue
    fi

    TEXT=$(tr '\n' ' ' < "$TRANSCRIPT_FILE" | sed 's/[[:space:]]\+/ /g; s/^ //; s/ $//')

    if [ -z "$TEXT" ] || [ "$TEXT" = "[BLANK_AUDIO]" ]; then
        echo "No speech was recognized; OpenCode was not called."
        echo "Check microphone input ($AUDIO_INPUT) or $FFMPEG_LOG_FILE."
        continue
    fi

    echo "Command: $TEXT"
    echo "Sending to OpenCode..."
    opencode run --model "$OPENCODE_MODEL" "$TEXT"
done
