# no-datacenters

Run OpenCode with local Ollama models and local voice transcription. No cloud
model or hosted speech-to-text service is required.

## Voice control

`voice_start.sh` starts Ollama, installs the local voice dependencies when
needed, records microphone input, transcribes it with `whisper.cpp`, and sends
each command to OpenCode.

### Requirements

- macOS
- [Homebrew](https://brew.sh)
- A microphone
- OpenCode and Ollama (the script can install them)

### Start

```bash
chmod +x voice_start.sh
./voice_start.sh
```

Press Enter to start listening. Press Enter again to stop recording manually,
or let the script stop after 1.2 seconds of silence. The gathered transcription
is then sent as a prompt to the local `qwen3:4b-instruct` Ollama model through
OpenCode. Press `Ctrl-C` to exit.

The script installs or uses:

- [Ollama](https://ollama.com) for local CPU model inference
- [OpenCode](https://opencode.ai) for the coding-agent workflow
- [whisper.cpp](https://github.com/ggml-org/whisper.cpp) for local speech-to-text
- `ffmpeg` for macOS microphone capture

### Configuration

Environment variables can override the defaults:

```bash
MODEL=qwen3:4b-instruct \
AUDIO_INPUT=:1 \
MAX_RECORD_SECONDS=60 \
SILENCE_DURATION=1.2 \
SILENCE_THRESHOLD=-35dB \
./voice_start.sh
```

For the detected audio devices, use `AUDIO_INPUT=:0` for the iPhone
microphone, `AUDIO_INPUT=:1` for the MacBook Pro microphone, or
`AUDIO_INPUT=:2` for AirPods Pro.

`MAX_RECORD_SECONDS` prevents an unattended recording from running forever.
Increase `SILENCE_DURATION` if the command is being cut off between phrases,
or lower `SILENCE_THRESHOLD` if background noise is being mistaken for speech.
While recording, `ffmpeg` prints `silence_start` and `silence_end` events. The
same diagnostics are saved to `$TMPDIR/opencode-voice/ffmpeg.log` (usually a
macOS `/var/folders/...` path).

If Whisper prints `[BLANK_AUDIO]`, the script skips OpenCode because no usable
prompt was recognized. On macOS, list available microphone devices with:

```bash
ffmpeg -f avfoundation -list_devices true -i ""
```

Then select the microphone index, for example:

```bash
# use airpods for auidio input
AUDIO_INPUT=:1 ./voice_start.sh
```

The Whisper model is downloaded to:

```text
~/.cache/whisper.cpp/ggml-base.en.bin
```

To use a different model file or download URL:

```bash
WHISPER_MODEL_PATH=/path/to/model.bin \
WHISPER_MODEL_URL=https://example.com/model.bin \
./voice_start.sh
```

The original non-voice startup flow remains available in `start.sh`.
