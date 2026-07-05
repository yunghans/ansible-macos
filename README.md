# ansible-macos

Automates setup of a fresh Mac with all apps and CLI tools using Homebrew Bundle.

## Usage

Run this in Terminal on a fresh Mac:

```sh
curl -fsSL https://raw.githubusercontent.com/yunghans/ansible-macos/main/install.sh -o install.sh && sh install.sh
```

That's it. It will install Xcode CLI tools, Homebrew, clone this repo, and run the Brewfile to install everything.

## Updating an existing machine

If you've already set up your Mac and want to sync any new additions:

```sh
sh ~/personal/ansible-macos/install.sh
```

## Adding apps

- **Homebrew formula**: add `brew "name"` to `Brewfile`
- **Homebrew cask**: add `cask "name"` to `Brewfile`
- **Mac App Store**: add `mas "App Name", id: 000000000` to `Brewfile` (find the ID on the App Store URL)
