## Inputs
```yaml
- agent_name: string
  agent_dir: string (filepath/bucket/url/git/...etc)
  validation_prompt: 
  validation_cmd: 
  autonomous_interval_seconds: 60
  autonomous_max_retries: 3
  autonomous_timeout_seconds: 30
  autonomous_status_command: "" # required: returns ready, pending, or failed
  autonomous_result_command: "" # required: stdout becomes the result
  autonomous_log_file: ./autonomous.log
  autonomous_result_file: ./autonomous-result.txt
  autonomous_harness: "" # optional: opencode, codex, claude_code, or copilot
  autonomous_harness_args: ""
  autonomous_harness_log: "" # optional: defaults beside the service log
```

## Outputs
