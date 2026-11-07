# no-datacenters

## Markdown instructions for coding agents

Codex uses `AGENTS.md` files as repository and directory instructions. Codex
loads instructions from the global Codex configuration, the repository root,
and each directory between the repository root and the current working
directory. More-specific files are applied after broader files.

For the example agent in this repository, start Codex from:

```bash
cd codex/agents/hello_world
codex
```

The instructions are in
[`codex/agents/hello_world/AGENTS.md`](./codex/agents/hello_world/AGENTS.md).
Files such as `README.md` and `CONTEXT.md` are not automatically loaded as
agent instructions; reference them from `AGENTS.md` or ask the agent to read
them.

### Claude Code compatibility

Claude Code uses `CLAUDE.md` and `CLAUDE.local.md` for automatically loaded
project instructions. It does not automatically treat `AGENTS.md` as its
instruction file, so the Codex file above will not control Claude Code by
itself. To share guidance, keep equivalent instructions in both files, or
explicitly ask Claude Code to read the Codex Markdown file.

See the [Codex Prompting Guide](https://developers.openai.com/cookbook/examples/gpt-5/codex_prompting_guide)
and [Claude Code memory documentation](https://docs.anthropic.com/en/docs/claude-code/memory)
for the tool-specific behavior.

### OpenCode compatibility

OpenCode also loads `AGENTS.md` files for persistent project instructions, so
the same repository guidance can be shared with Codex and OpenCode. OpenCode
does not use `CLAUDE.md` as a fallback.

OpenCode reusable agents are a separate feature. Define one as a Markdown file
under `.opencode/agents/` with frontmatter such as `description` and `mode`,
followed by the agent's system prompt:

```markdown
---
description: Answers simple greetings
mode: subagent
---

Respond to a greeting with `Hello, world!`.
```

The filename becomes the agent name. For example,
`.opencode/agents/hello_world.md` creates an OpenCode agent named
`hello_world`. The `AGENTS.md` file controls project-wide instructions; it is
not itself a reusable OpenCode agent definition.

See the [OpenCode instructions documentation](https://opencode.ai/v2/docs/instructions)
and [OpenCode agents documentation](https://opencode.ai/v2/docs/agents).
