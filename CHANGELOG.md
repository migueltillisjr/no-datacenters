# Changelog

## 1.0.6 - 2026-11-08

### Added

- Added the Apache License, Version 2.0 in `LICENSE`.
- Added a `NOTICE` file identifying Miguel Tillis as the copyright holder.

### Changed

- Updated the root `README.md` with the repository license and attribution
  requirements.

## 1.0.5 - 2026-11-08

### Progress

- validated that codex and opencode send traces to langfuse

## 1.0.4 - 2026-11-08

### Fixed

- Fixed OpenCode `provider.transport` connection failures by binding Ollama to
  `127.0.0.1:11434` and using the same endpoint in the OpenCode provider config.
- Changed the launcher to execute OpenCode directly so the Ollama server stays
  available for the complete traced session.
- Explicitly selected the harness-local `opencode.json` from
  `start_tracing.sh`.
- Fixed interactive OpenCode startup by configuring the model through
  `OPENCODE_CONFIG_CONTENT` instead of passing unsupported `--model` flags.
- Updated the OpenCode launcher to reuse a healthy existing Ollama server,
  wait for an already-starting server, and only stop Ollama when the launcher
  started it.
- Bounded the OpenCode warm-up request and made it non-blocking when it times
  out or fails, allowing the interactive session to start.
- Enabled direct `start.sh` launches to load valid Langfuse credentials and
  tracing configuration automatically from `langfuse/.env`.
- Updated the OpenCode 2 Ollama provider to the native OpenCode-compatible
  provider package and increased the managed Ollama context window to improve
  native tool-call handling.

## 1.0.3 - 2026-11-08

### Fixed

- Updated OpenCode tracing startup to configure the Langfuse plugin using the
  correct `plugins` or `plugin` key for the installed OpenCode major version.
- Applied the tracing configuration before both the OpenCode warm-up request
  and the interactive session.
- Wrote the Langfuse credentials from `langfuse/.env` to OpenCode's documented
  `opencode-langfuse.json` file with restrictive permissions before launch.
- Installed the Langfuse AI skill from `github.com/langfuse/skills` under the
  repository-level `.opencode/skills/langfuse/` directory.
- Added a harness-local `opencode.json` plugin and provider declaration so
  tracing remains enabled when OpenCode is launched through Ollama.
- Fixed OpenCode's Ollama launch path to use an explicit loopback endpoint and
  keep the Ollama process alive under the same launcher until OpenCode exits.

## 1.0.2 - 2026-11-07

### Added

- Added `LANGFUSE.md` setup instructions to each harness directory for sending
  traces from Claude Code, Codex, GitHub Copilot CLI, and OpenCode.
- Added `start_tracing.sh` wrappers for each harness to start Langfuse, apply
  tracing configuration, and launch the selected harness.

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
