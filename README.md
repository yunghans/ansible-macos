# ansible-macos

Automates setup of a fresh Mac with all apps and CLI tools.

## Usage

Run this in Terminal on a fresh Mac:

```sh
curl -fsSL https://raw.githubusercontent.com/yunghans/ansible-macos/main/install.sh -o install.sh && sh install.sh
```

That's it. It will install Xcode CLI tools, Homebrew, Ansible, and then run the playbook to install everything else.

## Updating an existing machine

If you've already set up your Mac and want to sync any new additions to the playbook:

```sh
ansible-playbook ~/personal/ansible-macos/playbook.yml -vv --ask-become-pass
```
