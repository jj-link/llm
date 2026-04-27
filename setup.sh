#!/bin/bash
# llm — setup script
# Installs dependencies and symlinks the llm script into ~/.local/bin.
# Idempotent; safe to re-run.

set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
INSTALL_DIR="$HOME/.local/bin"

R='\033[0m' B='\033[1m' G='\033[32m' Y='\033[33m' RD='\033[31m' C='\033[36m'
say()  { echo -e "${C}==>${R} $*"; }
warn() { echo -e "${Y}!!${R}  $*"; }
ok()   { echo -e "${G}✓${R}  $*"; }
fail() { echo -e "${RD}✗${R}  $*"; }

# 1. apt deps
if command -v apt-get &>/dev/null; then
    say "Installing system packages via apt..."
    sudo apt-get update -qq
    sudo apt-get install -y -qq python3 python3-yaml python3-pip curl git
    ok "System packages installed"
else
    warn "apt-get not found — install python3, python3-yaml, python3-pip, curl, git manually"
fi

# 2. Python deps (huggingface CLI)
say "Installing huggingface_hub CLI..."
if pip install --user --upgrade --quiet 'huggingface_hub[cli]'; then
    ok "huggingface_hub[cli] installed"
else
    fail "Failed to install huggingface_hub. Try: pip install --user 'huggingface_hub[cli]'"
    exit 1
fi

# 3. Symlink llm into PATH
mkdir -p "$INSTALL_DIR"
chmod +x "$REPO_DIR/llm"
ln -sf "$REPO_DIR/llm" "$INSTALL_DIR/llm"
ok "Symlinked $INSTALL_DIR/llm -> $REPO_DIR/llm"

# 4. PATH sanity
if ! [[ ":$PATH:" == *":$INSTALL_DIR:"* ]]; then
    warn "$INSTALL_DIR is not on your PATH"
    echo "    Add this to your ~/.bashrc:"
    echo "      export PATH=\"\$HOME/.local/bin:\$PATH\""
fi

# 5. Optional dependency checks (verify only, don't install)
echo ""
say "Optional dependencies:"

if command -v nvidia-smi &>/dev/null; then
    ok "nvidia-smi present ($(nvidia-smi --query-gpu=name --format=csv,noheader 2>/dev/null | head -1))"
else
    warn "nvidia-smi not found — install NVIDIA driver + CUDA before running models"
fi

BUUN_DEFAULT="$HOME/buun-llama-cpp/build/bin/llama-server"
ROTOR_DEFAULT="$HOME/rotorquant-llama-cpp/build/bin/llama-server"
BUUN_BIN="${LLM_BUUN_BIN:-$BUUN_DEFAULT}"
ROTOR_BIN="${LLM_ROTOR_BIN:-$ROTOR_DEFAULT}"
have_server=false
[[ -x "$BUUN_BIN" ]]  && { ok  "buun-llama-cpp llama-server: $BUUN_BIN";  have_server=true; }
[[ -x "$ROTOR_BIN" ]] && { ok  "rotorquant-llama-cpp llama-server: $ROTOR_BIN"; have_server=true; }
if [[ "$have_server" == false ]]; then
    warn "No llama-server binary found. Build at least one of:"
    echo "      $BUUN_BIN"
    echo "      $ROTOR_BIN"
    echo "    See README for mainline llama.cpp build instructions."
fi

# 6. Config reminder (no scaffold — user creates it explicitly)
echo ""
if [[ -f "$HOME/.config/llm/config" ]]; then
    ok "Config present at ~/.config/llm/config"
else
    say "No config yet. Create one from the example:"
    echo "      mkdir -p ~/.config/llm"
    echo "      cp $REPO_DIR/config.example ~/.config/llm/config"
    echo "      \$EDITOR ~/.config/llm/config"
fi

echo ""
ok "Setup complete. Try: ${B}llm --help${R}"
