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

# Source dotfile extras and set up CA trust
EXTRAS="$HOME/personal/ansible-macos/dotfiles/zshrc_extras.sh"

# Add env vars and source extras in .zshrc if not already done
if ! grep -q "zshrc_extras" "$HOME/.zshrc" 2>/dev/null; then
  CERT_BUNDLE="$HOME/personal/ansible-macos/certs/Cloudflare_CA.pem"
  cat >> "$HOME/.zshrc" << ZSHRC

# Cloudflare CA trust and extras — added by install.sh
export NODE_EXTRA_CA_CERTS="$CERT_BUNDLE"
export REQUESTS_CA_BUNDLE="$CERT_BUNDLE"
export SSL_CERT_FILE="$CERT_BUNDLE"
export CURL_CA_BUNDLE="$CERT_BUNDLE"
source "$HOME/personal/ansible-macos/dotfiles/zshrc_extras.sh"
ZSHRC
fi

# Export for current session and inject into launchd so GUI apps (VS Code) inherit them
CERT_BUNDLE="$HOME/personal/ansible-macos/certs/Cloudflare_CA.pem"
export NODE_EXTRA_CA_CERTS="$CERT_BUNDLE"
export REQUESTS_CA_BUNDLE="$CERT_BUNDLE"
export SSL_CERT_FILE="$CERT_BUNDLE"
export CURL_CA_BUNDLE="$CERT_BUNDLE"
launchctl setenv NODE_EXTRA_CA_CERTS "$CERT_BUNDLE"
launchctl setenv REQUESTS_CA_BUNDLE "$CERT_BUNDLE"
launchctl setenv SSL_CERT_FILE "$CERT_BUNDLE"
launchctl setenv CURL_CA_BUNDLE "$CERT_BUNDLE"

# Run trust function for this session
fancy_echo "Trusting Cloudflare CA certificates ..."
. "$EXTRAS"
trust_cloudflare

# Configure VS Code to not enforce strict SSL (needed for Cloudflare SSL inspection)
VSCODE_SETTINGS="$HOME/Library/Application Support/Code/User/settings.json"
mkdir -p "$HOME/Library/Application Support/Code/User"
if [ -f "$VSCODE_SETTINGS" ]; then
  if ! grep -q "proxyStrictSSL" "$VSCODE_SETTINGS"; then
    # Insert before last closing brace
    python3 -c "
import json
with open('$VSCODE_SETTINGS') as f:
    s = json.load(f)
s['http.proxyStrictSSL'] = False
with open('$VSCODE_SETTINGS', 'w') as f:
    json.dump(s, f, indent=2)
"
    echo "Set http.proxyStrictSSL = false in VS Code settings."
  else
    echo "VS Code proxyStrictSSL already configured. Skipping."
  fi
else
  printf '{\n  "http.proxyStrictSSL": false\n}\n' > "$VSCODE_SETTINGS"
  echo "Created VS Code settings with http.proxyStrictSSL = false."
fi

fancy_echo "Running Brewfile ..."
if [ "$1" = "--upgrade" ]; then
  fancy_echo "Upgrade mode: will upgrade already installed packages ..."
  brew bundle install --file="$HOME/personal/ansible-macos/Brewfile" --upgrade || true
else
  fancy_echo "Install mode: skipping already installed packages ..."
  brew bundle install --file="$HOME/personal/ansible-macos/Brewfile" --no-upgrade || true
fi

fancy_echo "Done!"
echo "Run 'source ~/.zshrc' to apply CA env vars to your current terminal session."
