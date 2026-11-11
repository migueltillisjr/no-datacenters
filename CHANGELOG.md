# Changelog

## 1.0.20 - 2026-11-10

### Changed

- Added autonomous service configuration values to `autonomous/DATA.md`.

## 1.0.19 - 2026-11-10

### Changed

- Documented the supported unattended OpenCode workflow using `opencode run`
  as the autonomous service's noninteractive result command.

## 1.0.18 - 2026-11-10

### Added

- Added the dependency-free `autonomous/` service with bounded retries,
  timeouts, atomic result persistence, signal handling, JSON-line logs, and
  focused tests/documentation.

## 1.0.17 - 2026-11-10

### Added

- Added an implementation prompt for a minimal long-running autonomous service
  that reuses existing harnesses, performs bounded retries, and persists logs.

## 1.0.16 - 2026-11-09

### Fixed

- Made launcher startup stop Ollama instances started through the macOS app as
  well as command-line `ollama serve` processes before starting a fresh server.

## 1.0.15 - 2026-11-09

### Changed

- Updated active harness launchers to stop an existing Ollama server on the
  configured port and start a fresh launcher-owned process.
- Scoped process detection to the configured listening port and verified the
  process is `ollama serve` before stopping it.

## 1.0.14 - 2026-11-09

### Fixed

- Added connection and maximum-duration limits to Ollama warm-up requests so
  a slow or non-responsive model cannot block harness startup indefinitely.

## 1.0.13 - 2026-11-09

### Fixed

- Made all regular harness `start.sh` launchers explicitly non-tracing by
  clearing inherited Langfuse and OTLP settings.
- Isolated Claude Code's tracing plugin configuration so normal Claude Code
  launches do not reuse the tracing setup.

## 1.0.12 - 2026-11-09

### Fixed

- Kept Langfuse container startup confined to the dedicated `start_tracing.sh`
  wrappers, so regular harness launchers do not require Docker when tracing is
  configured against an already-running endpoint.
- Made the default OpenCode configuration non-tracing, preventing a plain
  `start.sh` launch from waiting for Langfuse to be available.

### Changed

- Standardized the documented default model across supported local harnesses on
  `qwen3:4b-instruct`.

## 1.0.11 - 2026-11-09

### Fixed

- Prevented Langfuse `.env` values from overriding the OpenCode launcher’s
  selected model and Ollama runtime settings.

## 1.0.10 - 2026-11-09

### Fixed

- Declared explicit text input, text output, and tool capabilities for the
  configured Ollama models so OpenCode can treat them as tool-capable models.
- Added local OpenCode guidance to use tools for repository operations instead
  of returning command-only instructions.

## 1.0.9 - 2026-11-09

### Changed

- Configured OpenCode to load `local/opencode/AGENTS.md` as default project
  instructions.
- Added a Markdown-response requirement to the OpenCode instructions.
- Updated OpenCode launchers to select the repository configuration reliably
  from any working directory.

## 1.0.8 - 2026-11-09

### Changed

- Added purpose and usage headers to every repository-maintained script.

## 1.0.7 - 2026-11-09

### Added

- Added shared Ollama lifecycle helpers under `local/lib/ollama.sh`.
- Added safe repository validation through `scripts/check.sh`, including shell
  syntax, secret, Markdown link, and optional Compose checks.
- Added an Ollama lifecycle smoke test under `tests/`.

### Changed

- Updated Claude Code, Codex, OpenCode, and voice launchers to reuse healthy
  Ollama servers and stop only processes they started.
- Fixed stale `docs/NO_DATACENTERS.md` paths after the documentation move.
- Documented the validation command and completed robustness tasks in the
  project documentation.

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
