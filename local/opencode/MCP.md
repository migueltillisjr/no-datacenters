# MCP with OpenCode

OpenCode supports local and remote MCP servers through its project
configuration. Run the commands from this directory to configure this harness.

## Add a remote server

```bash
opencode mcp add context7 --url https://mcp.context7.com/mcp
opencode mcp list
```

Add `--global` when the server should be available in every OpenCode project.
For OAuth-backed servers, open OpenCode, run `/mcps`, select the server, and
complete sign-in.

## Add a local server

Add a server under `mcp.servers` in `opencode.json` or `opencode.jsonc`:

```jsonc
{
  "$schema": "https://opencode.ai/config.json",
  "mcp": {
    "servers": {
      "local-tools": {
        "type": "local",
        "command": ["./.opencode_venv/bin/python", "path/to/server.py"]
      }
    }
  }
}
```

OpenCode connects configured servers automatically. Use `disabled: true` to
keep a server configured without connecting it.

The `.opencode` directory already contains OpenCode configuration and must not
be replaced by a Python environment. Keep Python MCP dependencies in
`.opencode_venv` and do not commit credentials.
