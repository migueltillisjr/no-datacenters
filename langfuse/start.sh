#!/bin/bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

if [ ! -f .env ]; then
    echo "Missing langfuse/.env. Copy .env.example to .env and set every CHANGEME value." >&2
    exit 1
fi

echo "Starting Langfuse containers..."
docker compose --env-file .env up -d
echo "Langfuse is available at http://localhost:3000"
