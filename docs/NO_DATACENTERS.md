# Running the Harnesses with Local Models

This guide only covers running the three harnesses discussed in this project
with local models. Ollama provides the local model server; the harnesses remain
separate tools.

## 1. Install Ollama and a local model

On macOS:

```bash
brew install ollama
ollama --version
ollama pull qwen2.5-coder:7b
```

Use Ollama `v0.15+` for the `ollama launch` commands below.

Start Ollama with the shared runtime settings in a separate terminal when
using a harness manually:

```bash
LLAMA_ARG_FIT_TARGET=8138 \
OLLAMA_CONTEXT_LENGTH=8192 \
OLLAMA_NUM_PARALLEL=1 \
OLLAMA_KEEP_ALIVE=-1 \
ollama serve
```

Warm the model once after the server is ready so the first harness request
does not pay the model-load cost:

```bash
curl -sf http://localhost:11434/api/generate \
  -H 'Content-Type: application/json' \
  -d '{"model":"qwen2.5-coder:7b","prompt":"Reply with OK.","stream":false,"keep_alive":-1,"think":false,"options":{"num_predict":1}}' \
  >/dev/null
```

These server settings apply when Ollama starts. If an Ollama server or the
Ollama desktop app is already running, stop it and start it with the settings
above before launching a harness.

Verify the local API and installed models:

```bash
curl http://localhost:11434/api/tags
ollama list
```

The default local chat model in the voice script is `qwen3:4b-instruct`. You
can test it directly with:

```bash
ollama run qwen3:4b-instruct "Say hello in one sentence."
```

The voice workflow also uses the local Whisper.cpp model
`ggml-base.en.bin` for speech-to-text. Whisper is separate from Ollama: it
turns audio into text, and Ollama generates the chat response.

## 2. OpenCode: supported local-model harness

OpenCode is the harness wired directly to Ollama in this repository.

Start the project voice workflow:

```bash
cd local/opencode
chmod +x voice_start.sh
./voice_start.sh
```

[`voice_start.sh`](../local/opencode/voice_start.sh) starts Ollama, pulls the model
if needed, warms it up, transcribes the microphone input, and runs:

```bash
opencode run --model "ollama/$MODEL" "$TEXT"
```

The default is equivalent to:

```bash
MODEL=qwen3:4b-instruct
OPENCODE_MODEL=ollama/qwen3:4b-instruct
```

To use another installed Ollama model:

```bash
cd local/opencode
MODEL=llama3.2:3b ./voice_start.sh
```

For a direct OpenCode session without voice input:

```bash
cd local/opencode
opencode run --model ollama/qwen3:4b-instruct \
  "Explain the purpose of this repository."
```

The project OpenCode agent is
[`.opencode/agents/hello_world.md`](../.opencode/agents/hello_world.md). Its
`model` field is set to `ollama/qwen3:4b-instruct`.

For the non-voice startup path, use:

```bash
cd local/opencode
MODEL=qwen3:4b-instruct OLLAMA_CONTEXT_LENGTH=8192 ./start.sh
```

`start.sh` uses the same context, single-request parallelism, indefinite
keep-alive, RAM fit target, and model warm-up settings as `voice_start.sh`.
Each launcher also sends a harmless `Reply with OK` prompt through its harness
before opening the interactive session, warming both the model and harness
integration path.

The dedicated OpenCode launcher is also available at
[`local/opencode/start.sh`](../local/opencode/start.sh):

```bash
cd local/opencode
./start.sh
```

## 3. Claude Code with a local model

Install Claude Code if needed, then launch the configured local-model workflow:

```bash
cd local/claude_code
./start.sh
```

Override the model or shared settings when needed:

```bash
cd local/claude_code
MODEL=qwen2.5-coder:7b OLLAMA_CONTEXT_LENGTH=8192 ./start.sh
```

Ollama configures Claude Code to use its local Anthropic-compatible endpoint.
The `--model` value must name a model already available in Ollama. Use
`ollama list` to see installed models.

Claude Code still reads its own `CLAUDE.md` and `CLAUDE.local.md` instruction
files; selecting a local model does not change that instruction mechanism.

## 4. Codex with a local model

Install Codex CLI if needed, then launch the configured local-model workflow:

```bash
cd local/codex
./start.sh
```

Override the model or shared settings when needed:

```bash
cd local/codex
MODEL=qwen2.5-coder:7b OLLAMA_CONTEXT_LENGTH=8192 ./start.sh
```

Ollama creates a Codex launch profile that routes model requests to the local
Ollama API. Codex still reads `AGENTS.md` for repository instructions.

You can also launch Codex in Ollama's open-source model mode directly:

```bash
codex --oss -m qwen2.5-coder:7b
```

Use `ollama launch codex --config` to configure without starting Codex, or
`ollama launch codex --restore` to remove the generated Ollama launch profile.

## 5. OpenCode with a local model

For a standalone OpenCode session using the same coding model, use the
dedicated launcher:

```bash
cd local/opencode
./start.sh
```

The existing voice workflow uses OpenCode directly and defaults to
`qwen3:4b-instruct` instead:

```bash
cd local/opencode
MODEL=qwen3:4b-instruct ./voice_start.sh
```

To run the voice workflow with the coding model:

```bash
cd local/opencode
MODEL=qwen2.5-coder:7b ./voice_start.sh
```

## 6. Model and performance settings

The voice script uses these local-model settings:

```bash
MODEL=qwen3:4b-instruct
OLLAMA_CONTEXT_LENGTH=8192
OLLAMA_NUM_PARALLEL=1
OLLAMA_KEEP_ALIVE=-1
```

Use a smaller model for faster CPU responses:

```bash
cd local/opencode
MODEL=llama3.2:3b OLLAMA_CONTEXT_LENGTH=8138 ./voice_start.sh
```

Use a larger model only if the machine has enough memory and you accept slower
responses. The script warms the model before the first recording to avoid
paying the model-load cost on the first prompt.

## Summary

| Harness | Ollama launch command | Model |
| --- | --- | --- |
| Claude Code | Shared settings + `ollama launch claude --model ...` | `qwen2.5-coder:7b` |
| Codex | Shared settings + `ollama launch codex --model ...` | `qwen2.5-coder:7b` |
| OpenCode | Shared settings + `ollama launch opencode --model ...` | `qwen2.5-coder:7b` |

References: [Ollama Launch](https://ollama.com/blog/launch), [Ollama Codex integration](https://github.com/ollama/ollama/blob/main/docs/integrations/codex.mdx),
[Ollama Claude Code integration](https://github.com/ollama/ollama/blob/main/docs/integrations/claude-code.mdx),
and [OpenCode agents](https://opencode.ai/v2/docs/agents).
