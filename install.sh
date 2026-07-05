#!/bin/sh

# Bootstraps a fresh Mac by installing Homebrew, then running Brewfile

fancy_echo() {
  local fmt="$1"; shift
  printf "\n$fmt\n" "$@"
}

fancy_echo "Bootstrapping ..."

trap 'ret=$?; test $ret -ne 0 && printf "failed\n\n" >&2; exit $ret' EXIT

set -e

# Ensure Apple's command line tools are installed
if ! command -v cc >/dev/null; then
  fancy_echo "Installing Xcode CLI tools ..."
  xcode-select --install
else
  fancy_echo "Xcode CLI tools already installed. Skipping."
fi

# Install Homebrew if not present
if ! command -v brew >/dev/null; then
  fancy_echo "Installing Homebrew ..."
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
else
  fancy_echo "Homebrew already installed. Skipping."
fi

# Clone or update the repository
if [ -d "$HOME/personal/ansible-macos" ]; then
  fancy_echo "ansible-macos repo exists. Pulling latest ..."
  git -C "$HOME/personal/ansible-macos" pull
else
  fancy_echo "Cloning ansible-macos repo ..."
  git clone https://github.com/yunghans/ansible-macos "$HOME/personal/ansible-macos"
fi

# Symlink Karabiner config
mkdir -p "$HOME/.config/karabiner"
ln -sf "$HOME/personal/ansible-macos/dotfiles/karabiner/karabiner.json" \
  "$HOME/.config/karabiner/karabiner.json"

fancy_echo "Running Brewfile ..."
if [ "$1" = "--upgrade" ]; then
  fancy_echo "Upgrade mode: will upgrade already installed packages ..."
  brew bundle install --file="$HOME/personal/ansible-macos/Brewfile" --upgrade || true
else
  fancy_echo "Install mode: skipping already installed packages ..."
  brew bundle install --file="$HOME/personal/ansible-macos/Brewfile" --no-upgrade || true
fi

fancy_echo "Done!"
