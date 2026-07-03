#!/bin/sh

# This script bootstraps a OSX laptop for development
# to a point where we can run Ansible on localhost. It:
#  1. Installs:
#    - xcode
#    - homebrew
#    - ansible (via brew)
#  2. Kicks off the ansible playbook:
#    - playbook.yml

fancy_echo() {
  local fmt="$1"; shift

  # shellcheck disable=SC2059
  printf "\n$fmt\n" "$@"
}

fancy_echo "Bootstrapping ..."

trap 'ret=$?; test $ret -ne 0 && printf "failed\n\n" >&2; exit $ret' EXIT

set -e

# Ensure Apple's command line tools are installed
if ! command -v cc >/dev/null; then
  fancy_echo "Installing xcode ..."
  xcode-select --install
else
  fancy_echo "Xcode already installed. Skipping."
fi

if ! command -v brew >/dev/null; then
  fancy_echo "Installing Homebrew..."
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
else
  fancy_echo "Homebrew already installed. Skipping."
fi

# Install Ansible
if ! command -v ansible >/dev/null; then
  fancy_echo "Installing Ansible ..."
  brew install ansible
else
  fancy_echo "Ansible already installed. Skipping."
fi

# Clone or update the repository
if [ -d "$HOME/personal/ansible-macos" ]; then
  fancy_echo "ansible-macos repo exists. Pulling latest ..."
  git -C "$HOME/personal/ansible-macos" pull
else
  fancy_echo "Cloning ansible-macos repo ..."
  git clone https://github.com/yunghans/ansible-macos "$HOME/personal/ansible-macos"
fi

fancy_echo "Running ansible playbook ..."
ansible-playbook "$HOME/personal/ansible-macos/playbook.yml" -vv
