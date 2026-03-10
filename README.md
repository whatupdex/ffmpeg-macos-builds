# ffmpeg-macos-builds

LGPL-only universal macOS ffmpeg binaries for as-yet unnamed project.

Each release contains:
- `ffmpeg` — universal binary (arm64 + x86_64), built from official FFmpeg source
- `ffmpeg.sha256` — SHA-256 checksum for the binary

## Build configuration

```
--disable-gpl
--disable-nonfree
--disable-autodetect
--enable-static
--disable-shared
--disable-ffplay
--disable-ffprobe
--disable-doc
--disable-debug
```

## License

FFmpeg is licensed under the [GNU Lesser General Public License v2.1 or later](https://www.gnu.org/licenses/old-licenses/lgpl-2.1.html).

Source code for each release is available at https://ffmpeg.org/download.html
