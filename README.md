# ffmpeg-macos-builds

LGPL-only universal (arm64 + x86_64) macOS ffmpeg builds.

## Release tracks

- **`vMAJOR.MINOR.PATCH`** (for example `v7.1.5`): the build inDEXdown installs. It is made with
  `scripts/build-indexdown.sh`: FFmpeg with VideoToolbox, libdav1d (AV1 decoding) and LAME (MP3
  encoding, without LAME's decoder), statically linked, macOS 13 or later. See `INDEXDOWN-BUILD.md`
  for the exact sources, configure flags, licenses and rebuild instructions. The newest release
  on this track is GitHub's "Latest".
  - `v7.1.1` is an earlier, LAME-only build made by `.github/workflows/build.yml`.
- **`drawtext-vX.Y.Z`**: a separate build for BurnInProxy (drawtext, ffprobe), made by
  `.github/workflows/build-drawtext.yml`. Never marked Latest.

Each inDEXdown release contains:
- `ffmpeg`: the universal binary
- `ffmpeg.sha256`: its SHA-256 (64 lowercase hex characters)
- from `v7.1.5` on: the corresponding source tarballs, FFmpeg's signature for its tarball, the patch,
  `BUILDINFO.txt` and `licenses.zip`

Published releases are never replaced (apps pin the exact bytes). See "Publishing a release" in
`INDEXDOWN-BUILD.md`.

## License

FFmpeg is built without `--enable-gpl` and without `--enable-nonfree`, so the builds are licensed
under the [GNU Lesser General Public License v2.1 or later](https://www.gnu.org/licenses/old-licenses/lgpl-2.1.html).
LAME is under the GNU Library General Public License v2 and dav1d under the BSD 2-Clause license; their
texts are in `licenses/` and attached to each release. The source code for a release is attached to that
release (from `v7.1.5` on) and is also available from <https://ffmpeg.org/download.html>,
<https://lame.sourceforge.io> and <https://code.videolan.org/videolan/dav1d>.
