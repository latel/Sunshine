# Homebrew formula for patched Sunshine

This fork also acts as a custom Homebrew source for the local `sunshine-5k` formula.

## Install

```bash
brew tap latel/sunshine https://github.com/latel/Sunshine.git
brew uninstall --force --formula sunshine
brew install --build-from-source latel/sunshine/sunshine-5k
```

The formula builds upstream Sunshine `v2025.924.154138` and applies the embedded macOS VideoToolbox 5K HEVC patch.

## Verify

```bash
brew list --versions sunshine sunshine-5k
realpath /opt/homebrew/opt/sunshine-5k/bin/sunshine
/opt/homebrew/opt/sunshine-5k/bin/sunshine --version
```

Start Sunshine manually:

```bash
/opt/homebrew/opt/sunshine-5k/bin/sunshine "$HOME/.config/sunshine/sunshine.conf"
```
