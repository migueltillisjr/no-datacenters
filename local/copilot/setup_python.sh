#!/bin/bash

# Purpose: Create the Copilot integration's Python 3 virtual environment.
# Usage:   ./local/copilot/setup_python.sh

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
VENV_DIR="$SCRIPT_DIR/.copilot"

if ! command -v python3 >/dev/null 2>&1; then
    echo "Python 3 is required but was not found in PATH." >&2
    exit 1
fi

if [ ! -x "$VENV_DIR/bin/python" ]; then
    echo "Creating Python 3 virtual environment at $VENV_DIR..."
    python3 -m venv "$VENV_DIR"
else
    echo "Python virtual environment already exists at $VENV_DIR."
fi

echo "Activate it with: source $VENV_DIR/bin/activate"
