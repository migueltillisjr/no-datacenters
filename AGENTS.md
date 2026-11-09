## Rules

- when updating changelog use this format
    ```markdown
    # Changelog

    ## 1.0.0 - 2026-11-07
    ```

## Development directions

### Repository purpose

This repository contains local-first coding-agent harnesses backed by Ollama,
an OpenCode voice workflow, and an optional self-hosted Langfuse deployment.
Keep model inference and speech-to-text local unless a change explicitly
documents a different behavior.

### Repository layout

- `local/claude_code/`, `local/codex/`, and `local/opencode/` contain the
  supported harness launchers, setup scripts, and tracing wrappers.
- `local/copilot/` contains the experimental Copilot integration and its
  tracing wrapper.
- `local/lib/` contains shared launcher helpers. Keep reusable process
  lifecycle behavior here rather than copying it into each launcher.
- `langfuse/` contains the local Docker Compose deployment and lifecycle
  scripts.
- `docs/` contains detailed usage, tasks, and improvement plans.
- `scripts/` contains safe repository validation commands.
- `tests/` contains focused launcher tests that must not require a downloaded
  model, microphone, Docker stack, or user credentials.

### Making changes

- Preserve each integration's existing directory-local virtual environment.
- Keep shell scripts portable to macOS Bash and use `set -euo pipefail` for
  executable scripts unless there is a documented reason not to.
- Every maintained script must begin with a short `Purpose:` and `Usage:`
  comment immediately after its shebang. Include an `Example:` when useful.
- Use the shared Ollama lifecycle helper in `local/lib/ollama.sh`. Never use a
  broad process kill such as `pkill -f "ollama serve"`; stop only processes
  started by the current launcher.
- Do not print credentials, complete environment files, or secret-bearing
  command output in logs or error messages.
- Keep user-facing documentation and relative links accurate when files move.
- Update `docs/TASKS.md` and `docs/IMPROVEMENTS.md` when work changes the
  project roadmap or completes a listed improvement.

### Configuration and data safety

- Never commit `langfuse/.env`, generated virtual environments, model caches,
  credentials, API keys, or private keys.
- Treat Docker volumes as user data. Do not use `docker compose down -v`
  unless the user explicitly intends to delete Langfuse data.
- Do not alter or stop an existing user-managed Ollama server during tests.
- Prefer temporary directories for test fixtures and clean them up with traps.

### Documentation and release notes

- Use repository-relative links in Markdown files.
- Add a changelog entry for meaningful behavior, safety, or user-facing
  documentation changes, preserving the existing heading and date format.
- Keep the root `README.md` as the quick-start entry point and link detailed
  instructions from it rather than duplicating long setup procedures.
