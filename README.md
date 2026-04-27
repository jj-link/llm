# llm

A bash CLI that wraps [`llama.cpp`](https://github.com/ggerganov/llama.cpp)'s `llama-server` for fast local model juggling on a single-machine NVIDIA setup. Tested on Ubuntu 22.04+ and WSL.

## Commands

| Command                       | What it does                                                  |
| ----------------------------- | ------------------------------------------------------------- |
| `llm up <model> [opts]`       | Start `llama-server` with a registered model.                 |
| `llm down`                    | Stop the running server.                                      |
| `llm status`                  | Show what's running + per-GPU VRAM.                           |
| `llm models`                  | List registered models, KV-cache modes, GPU names.            |
| `llm logs [N]`                | Tail the last N lines of the server log.                      |
| `llm add <hf-url>`            | Download a GGUF from Hugging Face and register it.            |
| `llm remove <name>...`        | Unregister and (by default) delete model file(s).             |

`llm up` flags: `--kv <mode>`, `--gpu <id>`, `--ctx <size>`, `--np <slots>`, `--port <port>`, `--nfa` (disable flash attention).

## Install

```bash
git clone <this-repo> ~/Projects/llm
cd ~/Projects/llm
./setup.sh
```

Then create a config (the script works without one, but you'll likely want overrides for binary paths):

```bash
mkdir -p ~/.config/llm
cp config.example ~/.config/llm/config
$EDITOR ~/.config/llm/config
```

Authenticate with Hugging Face once so `llm add` can download:

```bash
hf auth login
```

## Prerequisites

`setup.sh` installs the bash/python side. You must provide separately:

- **NVIDIA driver + CUDA toolkit.** `nvidia-smi` must work.
- **A `llama-server` binary.** The default presets `f16`, `q8`, `q4`, `none` work with [mainline llama.cpp](https://github.com/ggerganov/llama.cpp):
  ```bash
  git clone https://github.com/ggerganov/llama.cpp ~/llama.cpp
  cd ~/llama.cpp
  cmake -B build -DGGML_CUDA=ON
  cmake --build build --config Release -j
  ```
  Then point at it via the config:
  ```bash
  export LLM_BUUN_BIN="$HOME/llama.cpp/build/bin/llama-server"
  ```
- **Specialized KV presets.** `tcq`, `tcq2`, `rotor`, `rotor-planar`, `rotor4` require [`buun-llama-cpp`](#) and [`rotorquant-llama-cpp`](#) forks respectively. Standard llama.cpp builds don't ship those KV types.

## Configuration

All settings are env vars; see [`config.example`](./config.example) for the full list. The script auto-sources `~/.config/llm/config` if present (override location with `LLM_CONFIG`).

The model registry (`MODEL_PATHS`/`MODEL_SIZES`) lives in `~/.config/llm/registry`, separate from the script. `llm add` and `llm remove` mutate it. It's gitignored so your personal model paths stay out of version control.

## Layout

```
.
├── llm              # the script (symlinked to ~/.local/bin/llm by setup.sh)
├── config.example   # copy to ~/.config/llm/config and edit
├── setup.sh         # apt + pip + symlink + dep checks
└── README.md
```

## Optional integrations

- **Hermes** — `llm add` appends a `custom_providers` entry to `~/.hermes/config.yaml` so Hermes can route to the local server. Skipped if the file doesn't exist.
- **claude-code-router (CCR)** — `llm up` rewrites CCR's Router slots to point at the freshly-launched model. Disabled by default; opt in by setting `LLM_CCR_CONFIG` to your CCR config path.

## License

MIT
