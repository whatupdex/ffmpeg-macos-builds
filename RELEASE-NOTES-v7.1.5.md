<!-- DRAFT release notes for tag v7.1.5. NOT PUBLISHED. Paste into the GitHub release once approved. -->
ffmpeg 7.1.5, universal macOS binary (arm64 + x86_64, macOS 13 or later), built for inDEXdown.

- Built from https://ffmpeg.org/releases/ffmpeg-7.1.5.tar.xz with `--disable-gpl --disable-nonfree --disable-autodetect --enable-static --disable-shared --enable-libmp3lame --enable-libdav1d --enable-videotoolbox`. Licensed LGPL v2.1 or later.
- Statically linked: LAME 3.100 (LGPL v2) and dav1d 1.5.4 (BSD 2-Clause). Exact source URLs and SHA-256 values, license texts and the build script are in this repository (`INDEXDOWN-BUILD.md`, `licenses/`, `scripts/build-indexdown.sh`, `BUILDINFO.txt`).
- `ffmpeg.sha256` is the SHA-256 of `ffmpeg`:

  b275226ae1c2aba8de7bb480531a0eb37bcf9a9f839fc4a81554ac0f0552b0d5
