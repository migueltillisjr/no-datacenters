# Autonomous service

This directory contains a small local-first scheduler for work performed by
the repository's existing harnesses. It is intentionally not an agent
framework: it checks status, waits, retries bounded failures, persists one
result, and records JSON-line events.

## Run in the foreground

The service requires two commands. Each command is executed without a shell and
must print either `ready`, `pending`, or `failed` for the status check. JSON such
as `{"status":"ready"}` is also accepted.

```bash
AUTONOMOUS_INTERVAL_SECONDS=30 \
AUTONOMOUS_STATUS_COMMAND='curl --fail --silent http://127.0.0.1:8765/status' \
AUTONOMOUS_RESULT_COMMAND='curl --fail --silent http://127.0.0.1:8765/result' \
./autonomous/service.py
```

Configuration can instead be supplied as JSON:

```bash
./autonomous/service.py --config autonomous/config.example.json
```

The example uses placeholder localhost endpoints and is not an active service.
Override its values through environment variables for a real task.

## Use with OpenCode

For an unattended OpenCode task, use OpenCode's noninteractive `run` command
as the result command. Start Ollama separately and make sure the selected model
is available first:

```bash
ollama serve
ollama pull qwen3:4b-instruct
```

Then configure a status command for the task and let OpenCode produce the
result when the status becomes `ready`:

```bash
AUTONOMOUS_INTERVAL_SECONDS=60 \
AUTONOMOUS_MAX_RETRIES=2 \
AUTONOMOUS_STATUS_COMMAND='curl --fail --silent http://127.0.0.1:8765/status' \
AUTONOMOUS_RESULT_COMMAND='opencode run --standalone --model ollama/qwen3:4b-instruct "Inspect the repository task and return only the final result."' \
AUTONOMOUS_LOG_FILE="$PWD/autonomous/opencode.log" \
AUTONOMOUS_RESULT_FILE="$PWD/autonomous/opencode-result.txt" \
./autonomous/service.py
```

`AUTONOMOUS_RESULT_COMMAND` is executed without a shell, so the quoted prompt
is passed as one argument. Replace it with the actual task prompt. OpenCode's
stdout is written atomically to the result file; its stderr is intentionally
not copied into the service log.

For interactive development, continue using the normal launcher in another
terminal:

```bash
./local/opencode/start.sh
```

Do not set `AUTONOMOUS_HARNESS=opencode` for a `launchd` service. The existing
OpenCode launcher intentionally ends in an interactive `opencode` session and
requires a terminal. Use `opencode run` as the result command for unattended
work, or use `AUTONOMOUS_HARNESS=opencode` only when deliberately running the
service from an interactive terminal.

## Configuration

| Variable | Default | Description |
| --- | --- | --- |
| `AUTONOMOUS_INTERVAL_SECONDS` | `60` | Delay between checks and retries. |
| `AUTONOMOUS_MAX_RETRIES` | `3` | Failed status/result attempts allowed after the first attempt. |
| `AUTONOMOUS_TIMEOUT_SECONDS` | `30` | Timeout for each command. |
| `AUTONOMOUS_STATUS_COMMAND` | required | Non-shell command returning `ready`, `pending`, or `failed`. |
| `AUTONOMOUS_RESULT_COMMAND` | required | Non-shell command whose stdout becomes the result. |
| `AUTONOMOUS_LOG_FILE` | `./autonomous.log` | JSON-lines event log. |
| `AUTONOMOUS_RESULT_FILE` | `./autonomous-result.txt` | Atomically written result file. |
| `AUTONOMOUS_HARNESS` | unset | `opencode`, `codex`, `claude_code`, or `copilot`. |
| `AUTONOMOUS_HARNESS_ARGS` | empty | Arguments passed to the selected existing launcher. |
| `AUTONOMOUS_HARNESS_LOG` | beside service log | Separate harness stdout/stderr log. |

Commands do not use shell expansion, pipelines, redirects, or shell operators.
Use an executable script when a check needs more complex logic.

When `AUTONOMOUS_HARNESS` is set, the corresponding launcher under `local/` is
started as a child process. The service stops only that child on shutdown; it
does not use broad process-kill patterns and does not manage unrelated Ollama
servers. Harness output is kept separate because it may contain model output.

## Events and exit codes

Events include `started`, `harness_started`, `status_checked`, `retrying`,
`completed`, `failed`, `already_completed`, and `shutdown`. Every event has a
UTC timestamp. Status and result command output is not copied into the service
log.

- `0`: result already existed or was completed successfully.
- `1`: retry limit was exhausted.
- `2`: configuration or dependency validation failed.
- `143`: the service received `SIGINT` or `SIGTERM`.
- Command timeouts are recorded as failed attempts internally and return `1`
  when the retry limit is exhausted.

If the result file already exists and is non-empty, the next invocation records
`already_completed` and exits without running another result command. Result
writes use a temporary file and an atomic link, so a crash cannot overwrite an
existing completed result.

## launchd example

Create a user agent plist at
`~/Library/LaunchAgents/com.no-datacenters.autonomous.plist`, changing the
paths and commands for the local task:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>Label</key>
  <string>com.no-datacenters.autonomous</string>
  <key>ProgramArguments</key>
  <array>
    <string>/Users/you/no-datacenters/autonomous/service.py</string>
    <string>--config</string>
    <string>/Users/you/no-datacenters/autonomous/config.json</string>
  </array>
  <key>WorkingDirectory</key>
  <string>/Users/you/no-datacenters</string>
  <key>RunAtLoad</key>
  <true/>
  <key>KeepAlive</key>
  <false/>
  <key>StandardOutPath</key>
  <string>/tmp/no-datacenters-autonomous.stdout.log</string>
  <key>StandardErrorPath</key>
  <string>/tmp/no-datacenters-autonomous.stderr.log</string>
</dict>
</plist>
```

Load it with:

```bash
launchctl load ~/Library/LaunchAgents/com.no-datacenters.autonomous.plist
```

The service itself remains the source of truth for interval timing. `KeepAlive`
is disabled so a terminal failure does not create an uncontrolled restart loop.
