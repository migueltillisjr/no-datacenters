# Changelog

## 1.0.0 - 2026-11-07

### Added

- Added local harness integrations for Claude Code, Codex, GitHub Copilot, and
  OpenCode under `local/`.
- Added Python 3 environment setup scripts for each harness:
  `local/<harness>/setup_python.sh`.
- Added concise Python setup and activation instructions in each harness's
  `PYTHON.md` file.
- Added automatic virtual-environment creation and activation to every
  harness `start.sh` script.
- Added local virtual-environment exclusions to `.gitignore`.

### Changed

- Standardized harness-specific virtual environments:
  `.claude_code`, `.codex`, and `.copilot`.
- Kept OpenCode configuration in `.opencode` and placed its Python environment
  in `.opencode_venv` to avoid overwriting existing configuration.
- Preserved the existing local Ollama startup and harness launch workflows.

### Notes

- Run `./setup_python.sh` from a harness directory to create its environment
  manually; `start.sh` performs this setup automatically when needed.
