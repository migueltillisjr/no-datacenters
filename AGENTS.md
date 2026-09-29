(- Run `bash start.sh` to install Ollama and OpenCode, start the Ollama server, and launch OpenCode
- Ensure `start.sh` is executable with `chmod +x start.sh` before running
- Ollama and OpenCode are installed automatically if missing
- OpenCode uses the `qwen3:4b-instruct` model by default
- Ollama server runs on port 11434 with 32768 context and 2048 MB RAM reserved
- Wait up to 30 seconds for Ollama API to become ready
- If Ollama fails to start, check `/tmp/ollama.log` for errors
- Run `opencode --version` to verify installation after script completes
- No dependency commands beyond `start.sh` are needed
- After launch, OpenCode will use the configured model for all operations)