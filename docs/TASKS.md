# Project tasks

This file tracks repository-level work. Completed items are retained for
context; active work should have a clear outcome and a verification step.

For the detailed hardening proposal and recommended order, see
[`IMPROVEMENTS.md`](./IMPROVEMENTS.md).

## Completed

- [x] Add MCP integration documentation to each harness directory.
- [x] Keep harness scripts and their Python 3 virtual environments in their
      respective integration directories.
- [x] Add setup and activation instructions for each harness environment.
- [x] Add local Langfuse deployment and startup validation.
- [x] Add Langfuse plugin and OpenTelemetry tracing launchers.
- [x] Add Apache 2.0 licensing and attribution notices.

## Next priorities

### Reliability

- [ ] Add shell linting and syntax checks for every `*.sh` file.
- [ ] Add smoke tests for launcher prerequisites, environment validation,
      model selection, and cleanup behavior.
- [ ] Replace duplicated launcher lifecycle code with a shared, tested helper
      or document the intentional differences between launchers.
- [ ] Make process ownership explicit so a launcher cannot stop an unrelated
      Ollama server.
- [ ] Add health checks and timeout diagnostics for all external services.

### Security and privacy

- [ ] Add an automated check that rejects committed `.env` files and obvious
      secrets.
- [ ] Review every subprocess and download command before allowing automatic
      installation or model downloads.
- [ ] Pin or document supported versions for Ollama, each harness, Docker
      Compose, and tracing plugins.
- [ ] Document exactly which prompts, transcripts, and traces are persisted
      locally and how to remove them.

### Developer experience

- [ ] Add a single validation command that runs all safe checks locally.
- [ ] Add CI for shell syntax, Markdown links, Compose configuration, and
      documentation consistency.
- [ ] Add a troubleshooting guide for common macOS audio, Docker, and Ollama
      failures.
- [ ] Keep the root README and detailed guides checked for broken relative
      links whenever files move.

### Integrations

- [ ] Decide whether GitHub Copilot support is experimental or supported, then
      either complete the launcher or label its limitations explicitly.
- [ ] Verify each tracing wrapper against a clean installation and record the
      expected trace in Langfuse.
- [ ] Add a documented procedure for upgrading the Langfuse Compose stack and
      backing up its named volumes.

## Definition of done

Before marking a task complete:

1. The change has a documented user-facing outcome.
2. A clean-machine or isolated-environment verification step exists where
   practical.
3. Failure behavior and cleanup behavior are documented.
4. Related README links and the changelog are updated when applicable.
