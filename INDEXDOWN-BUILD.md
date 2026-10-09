# inDEXdown ffmpeg build

The ffmpeg that inDEXdown downloads and manages on a Mac with no system ffmpeg. Built by
`scripts/build-indexdown.sh`; release tags are plain `vMAJOR.MINOR.PATCH` of the upstream FFmpeg
version (for example `v7.1.5`). Other tracks in this repository (for example `drawtext-*`) are for
other apps and are ignored by inDEXdown.

Each release has two assets:

- `ffmpeg`: universal binary (arm64 + x86_64), statically linked, deployment target macOS 13.0
- `ffmpeg.sha256`: the SHA-256 of `ffmpeg` as 64 lowercase hex characters (no filename)

## What it is for

| inDEXdown does | Needs | Provided by |
|---|---|---|
| MP3 audio downloads (`yt-dlp --extract-audio --audio-format mp3`) | MP3 encoder | `libmp3lame` |
| "Default quality" conversion to H.264 | H.264 encoder | `h264_videotoolbox` (macOS VideoToolbox) |
| Merging video + audio, AAC audio, adding source tags | AAC encoder, muxers, stream copy | built in |
| Reading what sites serve: VP9, AV1, H.264, HEVC; Opus, AAC, MP3, Vorbis, FLAC | decoders | built in, plus `libdav1d` for AV1 |

## Configure flags

```
--arch=<arm64|x86_64> --cc='clang -arch <arch>'            (x86_64 slice: --enable-cross-compile --target-os=darwin)
--disable-gpl --disable-nonfree --disable-autodetect
--enable-static --disable-shared
--disable-ffplay --disable-ffprobe --disable-doc --disable-debug
--enable-libmp3lame --enable-libdav1d --enable-videotoolbox
--pkg-config-flags=--static
--extra-cflags='-arch <arch> -mmacosx-version-min=13.0 -I<prefix>/include'
--extra-ldflags='-arch <arch> -mmacosx-version-min=13.0 -L<prefix>/lib'
```

`configure` reports `License: LGPL version 2.1 or later`.

## Components and licenses

The license texts below are copied verbatim from the exact source tarballs and live in `licenses/`
(regenerate with `NOTICES_ONLY=1 scripts/build-indexdown.sh`).

| Component | Version | License | Text in this repo | Linked how |
|---|---|---|---|---|
| FFmpeg (built without `--enable-gpl` / `--enable-nonfree`) | 7.1.5 | GNU LGPL v2.1 or later | `licenses/ffmpeg-7.1.5/COPYING.LGPLv2.1`, `LICENSE.md` | the executable itself |
| LAME (`libmp3lame`) | 3.100 | GNU Library General Public License v2 (LGPL v2), as shipped in its `COPYING` | `licenses/lame-3.100/COPYING`, `LICENSE` | statically linked |
| dav1d (`libdav1d`) | 1.5.4 | BSD 2-Clause | `licenses/dav1d-1.5.4/COPYING` | statically linked |
| VideoToolbox, CoreMedia, CoreVideo, CoreFoundation, CoreServices | macOS | Apple system frameworks | n/a | dynamically linked from macOS |

LAME's `LICENSE` file asks that products using it acknowledge LAME with a link to its website
(<https://lame.sourceforge.io>). inDEXdown's Help does so.

Not included, on purpose: `libx264` and `libx265` (GPL), `libfdk-aac` (non-free), `ffprobe`, `drawtext`
(freetype/harfbuzz).

## Exact sources (also written to `BUILDINFO.txt` by the build)

| Source | URL | SHA-256 |
|---|---|---|
| ffmpeg-7.1.5.tar.xz | <https://ffmpeg.org/releases/ffmpeg-7.1.5.tar.xz> (signature verified against the FFmpeg release key `FCF986EA15E6E293A5644F10B4322F04D67658D8`) | `de668509caf9e35e3cd162473441fdb29538c6d96ed080292b3cf9e6fc5d558f` |
| lame-3.100.tar.gz | <https://downloads.sourceforge.net/lame/lame-3.100.tar.gz> | `ddfe36cab873794038ae2c1210557ad34857a4b6bdc515785d1da9e175b1da1e` |
| dav1d-1.5.4.tar.xz | <https://downloads.videolan.org/pub/videolan/dav1d/1.5.4/dav1d-1.5.4.tar.xz> (matches the hash VideoLAN publishes) | `686616b7c69eb88d44459391ab25cac13b6647a3b288835c5784e71c1514a5c5` |

## Rebuilding the distributed binary

`FFMPEG_VERSION=7.1.5 scripts/build-indexdown.sh` on an Apple Silicon Mac with Xcode command line tools,
`nasm`, `meson` and `ninja` (Homebrew). It downloads the sources above, refuses to continue on any
checksum mismatch, builds LAME, dav1d and ffmpeg statically for arm64 and x86_64, joins them with `lipo`,
and signs the result ad hoc. Because the three libraries are statically linked into one executable, anyone
who wants to use a modified LAME or FFmpeg can rebuild with this script and their changed sources, which is
how the LGPL's relinking requirement is met. Builds are not guaranteed to be bit-for-bit reproducible, so
every release records the SHA-256 of the exact file that was published.

## Distribution notes (not legal advice)

- inDEXdown downloads this binary and runs it as a **separate program**; it is not linked into the app.
  Keep it that way. If a Mac already has ffmpeg (for example from Homebrew), inDEXdown uses that one instead,
  and that copy is covered by its own license.
- MP3 patents expired in 2017; no separate MP3 licence is needed.

## Verification performed before release

See the candidate report. Every release should re-run: `-encoders`/`-decoders` checks, the MP3 conversion
through the real yt-dlp command line, the H.264 conversion command inDEXdown issues, a decode matrix, and
both architecture slices.
