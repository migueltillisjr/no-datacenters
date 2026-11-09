#!/bin/bash

# Purpose: Exercise Ollama server reuse and launcher-owned cleanup behavior.
# Usage:   ./tests/test_ollama_lifecycle.sh

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TEST_DIR="$(mktemp -d "${TMPDIR:-/tmp}/no-datacenters-test.XXXXXX")"
trap 'rm -rf "$TEST_DIR"' EXIT

cat >"$TEST_DIR/curl" <<'EOF'
#!/bin/bash
if [ "${FAKE_OLLAMA_READY:-false}" = true ] || [ -f "${FAKE_READY_FILE:-}" ]; then
    exit 0
fi
exit 1
EOF

cat >"$TEST_DIR/ollama" <<'EOF'
#!/bin/bash
if [ "${1:-}" = serve ]; then
    touch "$FAKE_READY_FILE"
    sleep 30
fi
EOF

chmod +x "$TEST_DIR/curl" "$TEST_DIR/ollama"
PATH="$TEST_DIR:$PATH"
export PATH

source "$ROOT_DIR/local/lib/ollama.sh"

OLLAMA_LOG_FILE="$TEST_DIR/ollama.log"
OLLAMA_API_URL="http://127.0.0.1:11434"
OLLAMA_HOST="127.0.0.1:11434"
FAKE_READY_FILE="$TEST_DIR/ready"
export FAKE_READY_FILE

FAKE_OLLAMA_READY=true
export FAKE_OLLAMA_READY
ollama_start_or_reuse
[ "$OLLAMA_STARTED_BY_SCRIPT" = false ]
[ -z "$OLLAMA_PID" ]

FAKE_OLLAMA_READY=false
export FAKE_OLLAMA_READY
ollama_start_or_reuse
[ "$OLLAMA_STARTED_BY_SCRIPT" = true ]
[ -n "$OLLAMA_PID" ]
ollama_cleanup

echo "Ollama lifecycle tests passed."
