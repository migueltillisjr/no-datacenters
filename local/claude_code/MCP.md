# MCP with Claude Code

Claude Code supports local MCP servers over stdio and remote servers over
Streamable HTTP or SSE. Run these commands from this directory.

## Add a local server

```bash
claude mcp add local-tools --transport stdio -- \
  ./.claude_code/bin/python path/to/server.py
```

For a Node-based server:

```bash
claude mcp add context7 --transport stdio -- \
  npx -y @upstash/context7-mcp
```

## Add a remote server

```bash
claude mcp add --transport http context7 \
  https://mcp.context7.com/mcp
```

Use `--scope project` for a project-specific server, `--scope user` for a
user-wide server, or omit the scope to use the default behavior.

## Verify and use

```bash
claude mcp list
```

Start Claude Code and run `/mcp` to inspect connection status and authenticate
OAuth-backed servers. Ask Claude to use the server by name and confirm the
requested tool before allowing changes or external actions.

Never commit API keys or tokens. Pass non-secret configuration through the
server's environment and keep credentials in the local shell or approved
secret manager.
