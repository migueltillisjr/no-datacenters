#!/bin/bash

# Purpose: Run safe repository checks without starting models or deleting data.
# Usage:   ./scripts/check.sh

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

echo "Checking shell syntax..."
while IFS= read -r -d '' script; do
    bash -n "$script"
done < <(find local langfuse scripts tests -type f -name '*.sh' -print0 | sort -z)

if command -v shellcheck >/dev/null 2>&1; then
    echo "Running ShellCheck..."
    find local langfuse scripts tests -type f -name '*.sh' -print0 | xargs -0 shellcheck
else
    echo "ShellCheck not installed; skipping ShellCheck."
fi

echo "Checking Markdown links..."
if python3 -c 'import sys' >/dev/null 2>&1; then
    python3 scripts/check_links.py
else
    echo "Python 3 is unavailable; skipping Markdown link validation." >&2
    echo "Install Python 3 or repair the macOS Command Line Tools installation." >&2
fi

if command -v docker >/dev/null 2>&1; then
    if [ -f langfuse/.env ]; then
        echo "Validating Langfuse Compose configuration..."
        docker compose --env-file langfuse/.env -f langfuse/docker-compose.yml config --quiet
    else
        echo "langfuse/.env not found; skipping Compose validation."
    fi
else
    echo "Docker not installed; skipping Compose validation."
fi

if command -v git >/dev/null 2>&1; then
    echo "Checking for tracked environment files..."
    if tracked_files="$(git ls-files 2>/dev/null)"; then
        if printf '%s\n' "$tracked_files" | grep -Eq '(^|/)(\.env|.*\.env\.local)$'; then
            echo "Tracked environment files are not allowed." >&2
            exit 1
        fi
    else
        echo "Git index unavailable; skipping tracked-file validation." >&2
    fi
fi

echo "Checking for obvious secrets..."
secret_pattern='BEGIN (RSA |EC |OPENSSH )?PRIVATE KEY|sk-[A-Za-z0-9_-]{20,}|AKIA[0-9A-Z]{16}'
if command -v rg >/dev/null 2>&1; then
    if rg -n --hidden \
        --glob '!.git/**' \
        --glob '!**/.env' \
        --glob '!**/.env.*' \
        --glob '!**/.venv/**' \
        --glob '!**/.claude_code/**' \
        --glob '!**/.codex/**' \
        --glob '!**/.codex_tracing_home/**' \
        --glob '!**/.copilot/**' \
        --glob '!**/.opencode_venv/**' \
        --glob '!langfuse/.env.example' \
        --glob '!*.md' \
        --glob '!LICENSE' \
        --glob '!NOTICE' \
        "$secret_pattern" .; then
        echo "Potential secret detected; remove it or add a documented safe exception." >&2
        exit 1
    fi
elif command -v grep >/dev/null 2>&1; then
    if grep -REn \
        -I \
        --exclude-dir=.git \
        --exclude-dir=.venv \
        --exclude-dir='*_venv' \
        --exclude-dir=.codex \
        --exclude-dir=.codex_tracing_home \
        --exclude-dir=.claude_code \
        --exclude-dir=.copilot \
        --exclude='.env' \
        --exclude='*.env.*' \
        --exclude='*.md' \
        --exclude='LICENSE' \
        --exclude='NOTICE' \
        "$secret_pattern" .; then
        echo "Potential secret detected; remove it or add a documented safe exception." >&2
        exit 1
    fi
else
    echo "Neither rg nor grep is available; skipping secret scan." >&2
fi

echo "Repository checks passed."
