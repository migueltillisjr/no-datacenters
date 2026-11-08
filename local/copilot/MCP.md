# MCP with GitHub Copilot CLI

GitHub Copilot CLI supports local stdio servers and remote HTTP or SSE
servers. The interactive `/mcp` dashboard can also connect supported
connectors. Run these commands from this directory.

## Add a local server

```bash
copilot mcp add local-tools -- \
  ./.copilot/bin/python path/to/server.py
```

For a Node-based server:

```bash
copilot mcp add context7 -- npx -y @upstash/context7-mcp
```

## Add a remote server

```bash
copilot mcp add --transport http context7 \
  https://mcp.context7.com/mcp
```

Add credentials only when required:

```bash
copilot mcp add --transport http \
  --header "Authorization: Bearer YOUR_TOKEN" \
  context7 https://mcp.example.com/mcp
```

## Verify and use

Start `copilot`, then run `/mcp` to inspect servers and tools. The CLI also
supports `/mcp add` for interactive setup. Project-level servers require the
directory to be trusted before they are loaded.

Copilot stores user-level configuration in `~/.copilot/mcp-config.json`.
Never commit tokens or place real credentials in project configuration.
