# Install the patched Sunshine build with Homebrew

This branch exposes a custom Homebrew formula:

```text
Formula/sunshine-5k.rb
```

It builds upstream Sunshine `v2025.924.154138` from source and applies:

```text
patches/macos-vt-5k-hevc.patch
```

## Install

Remove the upstream formula first because both install the `sunshine` binary name:

```bash
brew uninstall --formula sunshine
```

Install the custom formula directly from GitHub:

```bash
brew install --build-from-source \
  https://raw.githubusercontent.com/latel/Sunshine/macos-vt-5k-hevc/Formula/sunshine-5k.rb
```

Confirm the installed binary:

```bash
brew list --formula | grep '^sunshine-5k$'
realpath /opt/homebrew/opt/sunshine-5k/bin/sunshine
/opt/homebrew/opt/sunshine-5k/bin/sunshine --version
```

## Stable 5K host config

Use the existing streaming kit script, or write these keys into `~/.config/sunshine/sunshine.conf`:

```ini
encoder = videotoolbox
max_bitrate = 30000
minimum_fps_target = 30
stream_audio = disabled
vt_coder = auto
vt_software = disabled
vt_realtime = enabled
hevc_mode = 2
av1_mode = 1
```

Keep the correct `output_name` for the current host display. It can change between machines.
