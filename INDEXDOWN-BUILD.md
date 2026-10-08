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

## Licensing

| Component | License | How it is used |
|---|---|---|
| FFmpeg 7.1.x (built without `--enable-gpl` / `--enable-nonfree`) | LGPL v2.1 or later | statically linked into the executable |
| LAME 3.100 (`libmp3lame`) | LGPL v2 or later | statically linked |
| dav1d 1.5.x (`libdav1d`) | BSD 2-Clause | statically linked |
| VideoToolbox, CoreMedia, CoreVideo, CoreFoundation, CoreServices | Apple system frameworks | dynamically linked from macOS |

Not included, on purpose: `libx264` and `libx265` (GPL), `libfdk-aac` (non-free), `ffprobe`, `drawtext`
(freetype/harfbuzz). Nothing here depends on a patent licence beyond what Apple's VideoToolbox already
provides on macOS.

Distribution notes (not legal advice):

- FFmpeg and LAME are LGPL and are **statically linked** into one executable. The LGPL permits that provided
  recipients can relink against a modified library, and the corresponding source is available. Meeting
  that means: (1) publish the exact source tarballs and build script used (this repository, plus the
  upstream URLs and SHA-256 values pinned in `scripts/build-indexdown.sh`), and (2) keep it possible for
  someone to rebuild the binary themselves. The build script is that mechanism.
- inDEXdown runs this binary as a separate process (it is downloaded, not linked into the app), which keeps
  the app itself outside the LGPL's scope. Keep it that way: do not link ffmpeg libraries into the app.
- Ship notices with the app (Help already lists ffmpeg under "Open Source Components"): add LAME (LGPL) and
  dav1d (BSD-2) to that list, with links to their source.
- MP3 encoding patents expired in 2017; no separate MP3 licence is needed.

## Verification performed before release

See the candidate report. Every release should re-run: `-encoders`/`-decoders` checks, the MP3 conversion
through the real yt-dlp command line, the H.264 conversion command inDEXdown issues, a decode matrix, and
both architecture slices.
