<!-- DRAFT release notes for tag v7.1.5 in whatupdex/ffmpeg-macos-builds. NOT PUBLISHED. -->
# ffmpeg 7.1.5 for inDEXdown (macOS, universal)

A universal (arm64 + x86_64) ffmpeg 7.1.5 for macOS 13 or later, statically linked, built for
inDEXdown. inDEXdown downloads it and runs it as a separate program when the Mac has no ffmpeg of its own.

## License

FFmpeg is built without `--enable-gpl` and without `--enable-nonfree`, so this binary is licensed
under the **GNU LGPL v2.1 or later**. It statically links:

- LAME 3.100 (`libmp3lame`), GNU LGPL v2 (as shipped in its `COPYING`), built with `--disable-decoder`,
  so LAME's mpglib decoder is not included
- dav1d 1.5.4 (`libdav1d`), BSD 2-Clause

and dynamically links only macOS itself (`/usr/lib/libSystem` and the VideoToolbox, CoreMedia,
CoreVideo, CoreFoundation and CoreServices frameworks). License texts are in `licenses/` in this
repository. MP3 encoding is provided by LAME (https://lame.sourceforge.io).

## Assets

- `ffmpeg`: the universal binary, ad hoc signed (no Developer ID, not notarized)
- `ffmpeg.sha256`: its SHA-256, 64 lowercase hex characters:

  `ab9e96ae25e29c0c278c1323910e75696ba258ab57f916e6cf02aa83cd55c180`

- Corresponding sources, so this release does not depend on upstream mirrors:

| File | SHA-256 | Upstream |
|---|---|---|
| `ffmpeg-7.1.5.tar.xz` | `de668509caf9e35e3cd162473441fdb29538c6d96ed080292b3cf9e6fc5d558f` | https://ffmpeg.org/releases/ffmpeg-7.1.5.tar.xz |
| `ffmpeg-7.1.5.tar.xz.asc` | `7ce4b9d56e3ef0cd4c3a9c0b2c8a034ac91e6c4c011c1f10b05a8aa7292fca35` | FFmpeg's signature for the tarball |
| `lame-3.100.tar.gz` | `ddfe36cab873794038ae2c1210557ad34857a4b6bdc515785d1da9e175b1da1e` | https://downloads.sourceforge.net/lame/lame-3.100.tar.gz |
| `dav1d-1.5.4.tar.xz` | `686616b7c69eb88d44459391ab25cac13b6647a3b288835c5784e71c1514a5c5` | https://downloads.videolan.org/pub/videolan/dav1d/1.5.4/dav1d-1.5.4.tar.xz |
| `lame-3.100-symbols.patch` | `b839a546dbdf9fb8e24283520c2f5aad29825ff34b10ba3e6b3b2431dc111c0a` | this repository, `patches/` (removes the stale `lame_init_old` export) |

The FFmpeg tarball's signature was verified with gpg during the build: good signature by the FFmpeg
release signing key `FCF986EA15E6E293A5644F10B4322F04D67658D8`.

## Configure line (arm64 slice; the x86_64 slice adds `--enable-cross-compile --target-os=darwin`)

```
--arch=arm64 --cc='clang -arch arm64' --disable-gpl --disable-nonfree --disable-autodetect
--enable-static --disable-shared --disable-ffplay --disable-ffprobe --disable-doc --disable-debug
--enable-libmp3lame --enable-libdav1d --enable-videotoolbox --pkg-config-flags=--static
--extra-cflags='-arch arm64 -mmacosx-version-min=13.0 -I<prefix>/include'
--extra-ldflags='-arch arm64 -mmacosx-version-min=13.0 -L<prefix>/lib'
```

(`<prefix>` is the build's private install directory; the exact path is in `ffmpeg -version`.)

## What it can do

- Encoders: `aac`, `libmp3lame`, `h264_videotoolbox`, `hevc_videotoolbox`, `prores`, `prores_ks`,
  `prores_aw`, `prores_videotoolbox`, plus FFmpeg's other built-in LGPL encoders
- Decoders: H.264, HEVC, VP9, AV1 (`libdav1d` and native), AAC, MP3, Opus, Vorbis, FLAC and the rest of
  FFmpeg's built-in decoders
- Not included: `libx264`/`libx265` (GPL), `libfdk-aac` (non-free), `ffprobe`, `ffplay`, `drawtext`

## How to rebuild

On an Apple Silicon Mac with the Xcode command line tools and Homebrew `nasm`, `meson`, `ninja`
(and optionally `gpg` for the signature check):

```
git checkout <tag or commit below>
FFMPEG_VERSION=7.1.5 scripts/build-indexdown.sh
```

The script downloads the sources above, stops on any checksum or signature mismatch, applies the LAME
patch, builds LAME, dav1d and FFmpeg statically for both architectures, joins them with `lipo`, and
signs ad hoc. To use a modified LAME or FFmpeg, change the sources and run the same script; that is how
the LGPL's relinking requirement is met. Builds are not bit-for-bit reproducible across build
directories (see `BUILDINFO.txt` and the notes in `INDEXDOWN-BUILD.md`), which is why the SHA-256 of
the published file is recorded here.

## Provenance

Built locally on the maintainer's Mac (Apple Silicon, Apple clang 17.0.0, macOS SDK 26.2, deployment
target 13.0) with the pinned script at commit `b4185fa94172d25c8830b1b58066214c0007ce2d` of this
repository. Verified on both slices before release (the x86_64 slice under Rosetta 2, not on Intel
hardware): architecture and minimum OS, linkage, signature, encoder and decoder lists, VP9 and AV1 to
H.264 with VideoToolbox, MP3 extraction, ProRes 422 encode, and a clean full decode of every output.
