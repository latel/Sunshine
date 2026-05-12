# macOS VideoToolbox 5K HEVC patch

This branch carries the local macOS VideoToolbox HEVC fix used for stable real 5K (`5120x2880`) streaming.

The patch is kept as `patches/macos-vt-5k-hevc.patch` so a Homebrew formula can build from the upstream release tag and apply the local delta reproducibly.

## What changed

- Detect H.264/HEVC IDR packets by scanning packet NAL units instead of relying only on `AV_PKT_FLAG_KEY`.
- Store the detected IDR state on `packet_raw_avcodec`.
- For macOS VideoToolbox, reset the AVCodecContext options that pushed 5K HEVC into a slow path:
  - `keyint_min`
  - `flags` / `flags2`
  - slice threading fields

## Verified target

- Sunshine `v2025.924.154138`
- Apple M1 Pro host
- VideoToolbox HEVC
- `5120x2880@30`
- Moonlight client using Metal renderer
