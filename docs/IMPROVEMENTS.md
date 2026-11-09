# Repository improvement plan

This document turns the repository's current TODOs into concrete robustness
work. The goal is to make local harness startup predictable, safe to rerun,
and easy to diagnose on a clean macOS machine.

## Highest priority

### 1. Add automated shell validation

The repository is driven primarily by shell scripts, but there is no visible
validation command. Add:

- `bash -n` checks for every launcher and setup script.
- ShellCheck for quoting, unset variables, unsafe expansion, and portability
  warnings.
- A CI job that runs these checks on every change.

Success criteria: a new or modified shell script fails CI when it contains a
syntax error or a high-confidence ShellCheck defect.

### 2. Make process ownership safe

Some launchers manage Ollama processes while others reuse an existing server.
The lifecycle rules should be consistent and must never terminate an unrelated
user-managed process.

Recommended approach:

1. Probe the configured `OLLAMA_HOST` first.
2. Start Ollama only when the endpoint is unavailable.
3. Record the exact child PID started by the launcher.
4. Stop only that child process during cleanup.
5. Report the log path and endpoint when startup fails.

Success criteria: starting and stopping a harness leaves a pre-existing
Ollama server running, while a server started by the launcher is cleaned up.

### 3. Add smoke tests for the launch contract

The launchers have important behavior that can be tested without running a
model. Add tests with mocked commands for:

- missing required tools;
- invalid or placeholder Langfuse credentials;
- unavailable Ollama endpoints;
- model names containing unexpected characters;
- cleanup after an interrupted launch;
- reuse of a healthy existing Ollama server.

Success criteria: the tests cover both successful validation and expected
failure messages without requiring Docker, a microphone, or a downloaded model.

### 4. Centralize configuration and reduce drift

The Claude Code, Codex, Copilot, and OpenCode launchers duplicate environment
handling, model defaults, readiness checks, and installation logic. Duplication
makes fixes easy to apply to one harness but miss another.

Recommended approach:

- Define documented defaults in one place.
- Extract only genuinely shared behavior into a small, well-tested helper.
- Keep harness-specific command construction in each launcher.
- Add a table documenting which variables each launcher supports.

Success criteria: a default or safety fix has one obvious source of truth and
all supported launchers behave consistently.

## Security and privacy

### 5. Add secret and configuration guardrails

Add a pre-commit or CI check that rejects tracked `.env` files, private keys,
and common API-key patterns. Keep `langfuse/.env.example` complete and make
the startup script fail closed for missing required secrets.

Also document:

- where model caches, voice recordings, logs, and traces are stored;
- whether prompt content is captured by Langfuse;
- how to remove local Docker volumes and caches;
- which network endpoints each launcher contacts.

### 6. Pin support boundaries

The scripts install tools from moving URLs and use `latest` for at least one
plugin. Document tested versions or provide optional version variables. For
each upgrade, record the compatibility result for Ollama, the harness CLI,
Docker Compose, and the Langfuse plugin.

## Operations and maintainability

### 7. Add a single validation entry point

Provide one safe command, for example `./scripts/check.sh`, that runs shell
syntax checks, Markdown link checks, and Compose validation when Docker is
available. It should not start a model, alter user configuration, or delete
data.

### 8. Improve failure diagnostics

Every launcher should identify:

- the command that is missing;
- the endpoint and timeout that failed;
- the log file to inspect;
- whether the script started the process;
- the next corrective command.

Avoid printing credentials or full environment files in diagnostics.

### 9. Add clean-install documentation

Document a reproducible first-run sequence for a clean macOS account, plus a
short troubleshooting matrix for:

- Homebrew and Python setup;
- microphone permissions and `ffmpeg` device selection;
- Ollama model download and memory limits;
- Docker resource limits and Langfuse startup;
- tracing plugin installation.

## Documentation quality

### 10. Keep documentation links testable

The repository has moved detailed guides under `docs/`, so relative links can
become stale after file moves. Add a Markdown-link check to CI and keep the
root README as the entry point to detailed guides.

### 11. Clarify integration support levels

Label each integration as `supported`, `experimental`, or `planned`. In
particular, decide whether the Copilot launcher is ready for normal use or
should remain explicitly experimental until its local-model path is complete.

## Suggested implementation order

1. Shell syntax checks and Markdown link checks.
2. Safe Ollama process ownership and shared readiness handling.
3. Mocked launcher smoke tests.
4. Secret scanning and configuration guardrails.
5. Version policy and clean-install troubleshooting.
6. Integration-specific improvements and broader CI coverage.

This order front-loads low-risk checks and the most consequential failure mode:
accidentally changing or stopping a user's existing local service.
