#!/usr/bin/env bash
set -euo pipefail

BREWFILE_PATH="$(cd "$(dirname "$0")" && pwd)/Brewfile"
VENV_DIR="$HOME/.local/share/dotfiles/venv"
REQ_FILE="$(cd "$(dirname "$0")" && pwd)/scripts/requirements.txt"

if [[ "$(uname -s)" != "Darwin" ]]; then
  echo "install_macos.sh is intended for macOS only." >&2
  exit 1
fi

echo "==> Checking Homebrew"
if ! command -v brew >/dev/null 2>&1; then
  echo "==> Installing Homebrew"
  NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  if [[ -x /opt/homebrew/bin/brew ]]; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
  elif [[ -x /usr/local/bin/brew ]]; then
    eval "$(/usr/local/bin/brew shellenv)"
  fi
fi

echo "==> Creating Python venv at $VENV_DIR"
mkdir -p "$(dirname "$VENV_DIR")"

# Try to find python3.11 from PATH first (Homebrew usually exposes it as /opt/homebrew/bin/python3.11)
PY311="$(command -v python3.11 || true)"

# If python3.11 isn't available, install python@3.11 via Homebrew
if [[ -z "$PY311" ]]; then
  echo "==> python3.11 not found in PATH. Installing python@3.11 via Homebrew..."
  brew install python@3.11

  # Re-resolve after install
  PY311="$(command -v python3.11 || true)"
fi

# Hard fail if still missing, to avoid silently falling back to python3 (3.13 etc.)
if [[ -z "$PY311" ]]; then
  echo "ERROR: python3.11 still not found after brew install python@3.11." >&2
  echo "Hint: check Homebrew output. On macOS it should provide /opt/homebrew/bin/python3.11." >&2
  exit 1
fi

# Reuse existing venv if it exists; otherwise create it with python3.11
if [[ -x "$VENV_DIR/bin/python" ]]; then
  echo "==> venv already exists, reusing: $VENV_DIR"
  echo "==> venv python: $("$VENV_DIR/bin/python" -V)"
else
  echo "==> Using interpreter: $PY311 ($("$PY311" -V))"
  "$PY311" -m venv "$VENV_DIR"
fi

"$VENV_DIR/bin/pip" install --upgrade pip
"$VENV_DIR/bin/pip" install -r "$REQ_FILE"

echo "Next steps:"
cat <<'NEXT'
  - Run your existing setup scripts (stow/zsh/tmux/vim wiring):
      ./shell_setup.sh
      ./setup_all.sh
  - Quick checks:
      command -v dotpy
      dotpy -c "import sys; print(sys.executable)"
NEXT
