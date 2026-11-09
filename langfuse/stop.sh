#!/bin/bash

# Purpose: Stop the local Langfuse containers without deleting named volumes.
# Usage:   ./langfuse/stop.sh

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

docker compose --env-file .env down
