# Dotfiles

## Prereqs (macOS)
- Xcode Command Line Tools
- Git

## Install (macOS)
```bash
# clone
git clone <repo-url> ~/dotfiles
cd ~/dotfiles

# install brew deps + python venv for scripts
./install_macos.sh

# then apply dotfiles (stow/zsh/tmux/vim wiring)
./shell_setup.sh
./setup_all.sh
```

## Maintenance
Update Brewfile after adding/removing CLI dependencies:
```bash
brew bundle dump --file Brewfile --force
```

Update Python requirements after adding/removing imports in `scripts/bin`:
```bash
$HOME/.local/share/dotfiles/venv/bin/pip freeze > scripts/requirements.txt
```

## Quick checks
```bash
command -v brew
command -v dotpy
dotpy -c "import sys; print(sys.executable)"
# Example python script
scripts/bin/typewrite "hello"
```
