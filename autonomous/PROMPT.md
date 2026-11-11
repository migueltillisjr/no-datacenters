# Autonomous Service Implementation Prompt

Use the following prompt with an existing coding harness to implement the
minimal autonomous service for this repository.

```text
You are implementing a small, local-first autonomous service in the
`autonomous/` directory of the `no-datacenters` repository.

Keep the architecture intentionally simple. Do not introduce LangGraph,
AutoGen, CrewAI, a message broker, a database, or a web dashboard. Reuse the
existing repository harnesses and launcher conventions wherever possible.

## Goal

Build a long-running service that periodically wakes up, checks the configured
status of a task or external service, retrieves the result when it is ready,
retries bounded failures, and exits when the task succeeds or reaches a
terminal failure. Every important event must be written to a durable log.

## Required behavior

1. Read configuration from environment variables or a small local config file.
   Support at least:
   - `AUTONOMOUS_INTERVAL_SECONDS`: delay between status checks.
   - `AUTONOMOUS_MAX_RETRIES`: maximum retries for one failed operation.
   - `AUTONOMOUS_TIMEOUT_SECONDS`: timeout for each command or request.
   - `AUTONOMOUS_STATUS_COMMAND`: allowlisted local command for checking status,
     or an equivalent configurable local status endpoint.
   - `AUTONOMOUS_RESULT_COMMAND`: allowlisted local command for retrieving the
     completed result.
   - `AUTONOMOUS_LOG_FILE`: path to the service log.
   - `AUTONOMOUS_HARNESS`: optional existing harness launcher to invoke when
     work must be performed (`opencode`, `codex`, `claude_code`, or `copilot`).

2. Start by validating configuration and dependencies. Fail clearly if a
   required command, file, or harness is missing.

3. Use the existing launcher scripts under `local/` instead of duplicating
   Ollama startup, model selection, tracing, or process lifecycle behavior.
   Do not kill broad process patterns and do not stop user-managed Ollama
   processes.

4. Implement one straightforward loop:
   - write a `started` event;
   - run the status check with a timeout;
   - classify the response as `ready`, `pending`, or `failed`;
   - if `pending`, sleep for the configured interval;
   - if `failed`, retry until the retry limit is reached;
   - if `ready`, retrieve and persist the result, write a `completed` event,
     and exit successfully;
   - after the retry limit is reached, write a `failed` event and exit nonzero.

5. Handle `SIGINT` and `SIGTERM` gracefully. Write a shutdown event, clean up
   only child processes created by this service, and exit without corrupting
   the log or result.

6. Make logs useful but safe. Include timestamps, event names, attempt number,
   elapsed time, and exit status. Never log API keys, credentials, complete
   environment files, or secret-bearing command output.

7. Make the service restart-safe. It must be possible to run it again after a
   crash without duplicating a completed result. Use a small state file or an
   atomic result file if necessary; do not add a database.

8. Provide a foreground mode for development and a documented example for
   running it as a macOS `launchd` service. Do not require Docker, a downloaded
   model, a microphone, or user credentials for the tests.

## Implementation constraints

- Prefer portable macOS Bash with `set -euo pipefail`, or a small Python
  standard-library service if that makes timeout and signal handling safer.
- Every executable script must begin with `Purpose:` and `Usage:` comments
  immediately after its shebang, plus an `Example:` where useful.
- Keep all reusable process lifecycle behavior in `local/lib/ollama.sh`.
- Use temporary directories for test fixtures and clean them up with traps.
- Do not use `pkill -f`, `docker compose down -v`, or destructive cleanup.
- Do not add a new agent framework. The harness is responsible for model
  interaction; this service is only a scheduler, status checker, retry loop,
  result writer, and logger.

## Deliverables

- The smallest working service under `autonomous/`.
- A sample configuration with safe placeholder values.
- Focused tests for pending, success, retry-then-success, retry exhaustion,
  timeout, malformed status output, restart behavior, and signal handling.
- Documentation explaining configuration, event states, exit codes, logs,
  result storage, and launchd usage.
- Updates to the repository changelog and task documentation when the new
  service creates or completes roadmap work.

## Acceptance criteria

- A single command starts the service in the foreground.
- The service sleeps between checks instead of busy-looping.
- Every failed operation is retried only within the configured limit.
- A successful result is persisted exactly once and the service exits zero.
- Terminal failure exits nonzero and identifies the reason in the log.
- Existing harness launchers remain unchanged unless a small, justified reuse
  improvement is required.
- `./scripts/check.sh` passes, and tests do not need Ollama, Docker, a model,
  a microphone, or credentials.

Before editing files, inspect the existing launchers, shared Ollama helper,
repository instructions, and test conventions. After editing, run the focused
tests and the repository checks, then summarize the files changed and the
manual command used to verify the foreground service.
```
