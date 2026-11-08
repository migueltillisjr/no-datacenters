# MCP with Codex

Codex supports local MCP servers over stdio and remote servers over HTTP. The
CLI configuration is shared with the Codex IDE integration. Run these commands
from this directory.

## Add a local server

```bash
codex mcp add local-tools -- \
  ./.codex/bin/python path/to/server.py
```

For a Node-based server:

```bash
codex mcp add context7 -- npx -y @upstash/context7-mcp
```

## Add a remote server

```bash
codex mcp add context7 --url https://mcp.context7.com/mcp
```

## Verify and use

```bash
codex mcp list
```

Codex stores CLI MCP configuration in `~/.codex/config.toml`. For a project
server, document the expected server name and intended tools in the project's
`AGENTS.md`, then ask Codex to use the server for a specific task.

Never commit API keys or tokens. Use environment variables or the supported
credential flow for authenticated servers, and approve write-capable tools
only when their target and inputs are understood.
