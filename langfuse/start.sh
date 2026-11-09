#!/bin/bash

# Purpose: Validate Langfuse credentials and start the local Docker Compose stack.
# Usage:   ./langfuse/start.sh

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

if [ ! -f .env ]; then
    echo "Missing langfuse/.env. Copy .env.example to .env and set every CHANGEME value." >&2
    exit 1
fi

required_vars=(
    POSTGRES_PASSWORD
    CLICKHOUSE_PASSWORD
    REDIS_AUTH
    MINIO_ROOT_PASSWORD
    NEXTAUTH_SECRET
    SALT
    ENCRYPTION_KEY
)

for variable in "${required_vars[@]}"; do
    value="$(awk -F= -v key="$variable" '$1 == key { print substr($0, index($0, "=") + 1); exit }' .env)"
    if [ -z "$value" ]; then
        echo "$variable must be set in .env." >&2
        exit 1
    fi
    if [[ "$value" == CHANGEME_* ]]; then
        echo "Warning: $variable is still using a placeholder value." >&2
    fi
done

encryption_key="$(awk -F= '$1 == "ENCRYPTION_KEY" { print substr($0, index($0, "=") + 1); exit }' .env)"
if [[ ! "$encryption_key" =~ ^[0-9a-fA-F]{64}$ ]]; then
    echo "ENCRYPTION_KEY must be exactly 64 hexadecimal characters." >&2
    echo "Generate one with: openssl rand -hex 32" >&2
    exit 1
fi

echo "Validating Langfuse Compose configuration..."
docker compose --env-file .env config --quiet

echo "Starting Langfuse containers..."
docker compose --env-file .env up -d
echo "Langfuse is available at http://localhost:3000"
