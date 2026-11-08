# Changelog

## 1.0.1 - 2026-11-07

### Added

- Added Langfuse tracing setup for Claude Code, Codex, GitHub Copilot CLI, and
  OpenCode.
- Added `LANGFUSE_USER_ID` guidance for stable, non-secret trace attribution.

### Changed

- Updated `langfuse/.env.example` with harness tracing and local OTLP settings.
- Added startup validation for required Langfuse environment variables and the
  64-character hexadecimal encryption key.

### Fixed

- Disabled ClickHouse cluster mode for the single-node Docker Compose setup.
- Updated Langfuse container startup guidance to prevent web and worker restart
  loops caused by invalid configuration.

## 1.0.0 - 2026-11-07

- Added local harness integrations for Claude Code, Codex, GitHub Copilot, and
  OpenCode under `local/`.
- Added Python 3 environment setup scripts for each harness:
  `local/<harness>/setup_python.sh`.
- Added concise Python setup and activation instructions in each harness's
  `PYTHON.md` file.
- Added automatic virtual-environment creation and activation to every
  harness `start.sh` script.
- Added local virtual-environment exclusions to `.gitignore`.
- Added a top-level Docker Compose deployment for self-hosted Langfuse under
  `langfuse/`, including PostgreSQL, ClickHouse, Redis, and MinIO services.
- Added Langfuse startup and shutdown scripts with environment validation and
  local health checks.
- Added harness tracing instructions in `langfuse/PLUGIN_SETUP.md` for Claude
  Code, Codex, GitHub Copilot CLI, and OpenCode.

### Changed

- Standardized harness-specific virtual environments:
  `.claude_code`, `.codex`, and `.copilot`.
- Kept OpenCode configuration in `.opencode` and placed its Python environment
  in `.opencode_venv` to avoid overwriting existing configuration.
- Preserved the existing local Ollama startup and harness launch workflows.
- Added Langfuse project credential and trace attribution settings to
  `langfuse/.env.example`, including the optional `LANGFUSE_USER_ID` field.
- Configured the local Langfuse deployment for single-node ClickHouse mode.

### Notes

- Run `./setup_python.sh` from a harness directory to create its environment
  manually; `start.sh` performs this setup automatically when needed.
- Run `langfuse/start.sh` after configuring `langfuse/.env` to start the local
  observability stack, then open `http://localhost:3000` to create a project
  and obtain its API keys.
