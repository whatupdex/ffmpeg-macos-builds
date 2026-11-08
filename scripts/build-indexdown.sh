#!/bin/bash
# Builds the ffmpeg that inDEXdown downloads and manages: a universal (arm64 + x86_64),
# statically linked, LGPL-only binary with exactly the capabilities the app asks of it.
#
#   MP3 encode        libmp3lame (LGPL)         yt-dlp --extract-audio --audio-format mp3
#   H.264 encode      h264_videotoolbox          "Default quality" conversion (Apple hardware/system encoder)
#   AV1 decode        libdav1d (BSD-2-Clause)    AV1 streams downloaded in Default/Highest
#   AAC, mux, copy    built-in
#
# Deliberately NOT included: libx264/libx265 (GPL), ffprobe and drawtext (not used by the app).
#
# Usage: FFMPEG_VERSION=7.1.5 scripts/build-indexdown.sh      (output: build/out/ffmpeg + ffmpeg.sha256)
set -euo pipefail

FFMPEG_VERSION="${FFMPEG_VERSION:-7.1.5}"
LAME_VERSION="3.100"
DAV1D_VERSION="1.5.4"
export MACOSX_DEPLOYMENT_TARGET="${MACOSX_DEPLOYMENT_TARGET:-13.0}"   # the app's minimum macOS

# Pinned source hashes (always checked; a mismatch stops the build). dav1d's hash is the one VideoLAN publishes.
# In addition, when gpg is installed, FFmpeg's tarball signature (ffmpeg-$VERSION.tar.xz.asc) is verified and the
# signing key must be exactly the FFmpeg release signing key below. Without gpg the build says so and records it
# in BUILDINFO.txt; the SHA-256 pin is then the only check.
FFMPEG_SIGNING_KEY_FPR="FCF986EA15E6E293A5644F10B4322F04D67658D8"
SHA_FFMPEG_7_1_5="de668509caf9e35e3cd162473441fdb29538c6d96ed080292b3cf9e6fc5d558f"
SHA_LAME="ddfe36cab873794038ae2c1210557ad34857a4b6bdc515785d1da9e175b1da1e"
SHA_DAV1D="686616b7c69eb88d44459391ab25cac13b6647a3b288835c5784e71c1514a5c5"

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
WORK="${WORK:-$ROOT/build}"
SRC="$WORK/src"; OUT="$WORK/out"
JOBS="$(sysctl -n hw.ncpu)"
mkdir -p "$SRC" "$OUT"

fetch() { # url file sha256
  local url="$1" file="$SRC/$2" want="$3"
  [ -f "$file" ] || curl -fL --retry 4 --retry-delay 3 -o "$file" "$url"
  local got; got="$(shasum -a 256 "$file" | awk '{print $1}')"
  [ "$got" = "$want" ] || { echo "CHECKSUM MISMATCH for $2: $got != $want" >&2; exit 1; }
}

ffmpeg_sha_var="SHA_FFMPEG_${FFMPEG_VERSION//./_}"
[ -n "${!ffmpeg_sha_var:-}" ] || { echo "No pinned checksum for ffmpeg $FFMPEG_VERSION; add $ffmpeg_sha_var" >&2; exit 1; }

fetch "https://ffmpeg.org/releases/ffmpeg-$FFMPEG_VERSION.tar.xz" "ffmpeg-$FFMPEG_VERSION.tar.xz" "${!ffmpeg_sha_var}"
verify_ffmpeg_signature() {
  local tarball="$SRC/ffmpeg-$FFMPEG_VERSION.tar.xz" sig="$SRC/ffmpeg-$FFMPEG_VERSION.tar.xz.asc"
  if ! command -v gpg >/dev/null 2>&1; then
    echo "NOTE: gpg is not installed, so the FFmpeg tarball signature was NOT verified (SHA-256 pin only)." >&2
    SIG_STATUS="not verified: gpg not installed; SHA-256 pin only"
    return 0
  fi
  [ -f "$sig" ] || curl -fL --retry 4 --retry-delay 3 -o "$sig" "https://ffmpeg.org/releases/ffmpeg-$FFMPEG_VERSION.tar.xz.asc"
  local gh; gh="$(mktemp -d)"
  # Import the key into a throwaway keyring (never the user's). Trust comes from the pinned fingerprint
  # checked below, not from where the key file was downloaded.
  if ! { curl -fsSL --retry 3 https://ffmpeg.org/ffmpeg-devel.asc | GNUPGHOME="$gh" gpg --batch --quiet --import; } >/dev/null 2>&1; then
    GNUPGHOME="$gh" gpg --batch --quiet --keyserver hkps://keyserver.ubuntu.com --recv-keys "$FFMPEG_SIGNING_KEY_FPR" >/dev/null 2>&1 \
      || { echo "SIGNATURE CHECK FAILED: could not obtain the FFmpeg signing key" >&2; rm -rf "$gh"; exit 1; }
  fi
  local status; status="$(LC_ALL=C GNUPGHOME="$gh" gpg --batch --status-fd 1 --verify "$sig" "$tarball" 2>/dev/null || true)"
  rm -rf "$gh"
  # VALIDSIG field 12 is the fingerprint of the primary key that made the signature.
  local signer; signer="$(printf '%s\n' "$status" | awk '$2=="VALIDSIG"{print $12}' | head -1)"
  if [ "$signer" != "$FFMPEG_SIGNING_KEY_FPR" ]; then
    echo "SIGNATURE CHECK FAILED for ffmpeg-$FFMPEG_VERSION.tar.xz (signer '${signer:-none}', expected $FFMPEG_SIGNING_KEY_FPR)" >&2
    exit 1
  fi
  echo "FFmpeg tarball signature OK (key $FFMPEG_SIGNING_KEY_FPR)"
  SIG_STATUS="verified with gpg: good signature by FFmpeg release signing key $FFMPEG_SIGNING_KEY_FPR"
}
SIG_STATUS="not checked (NOTICES_ONLY run)"
[ "${NOTICES_ONLY:-0}" = "1" ] || verify_ffmpeg_signature

fetch "https://downloads.sourceforge.net/lame/lame-$LAME_VERSION.tar.gz" "lame-$LAME_VERSION.tar.gz" "$SHA_LAME"
fetch "https://downloads.videolan.org/pub/videolan/dav1d/$DAV1D_VERSION/dav1d-$DAV1D_VERSION.tar.xz" "dav1d-$DAV1D_VERSION.tar.xz" "$SHA_DAV1D"

collect_notices() {
  # License texts are copied verbatim from the pinned source tarballs, so they always match the
  # versions that were built. Also writes BUILDINFO.txt for the release notes.
  local L="$ROOT/licenses"
  mkdir -p "$L/ffmpeg-$FFMPEG_VERSION" "$L/lame-$LAME_VERSION" "$L/dav1d-$DAV1D_VERSION"
  tar -xf "$SRC/ffmpeg-$FFMPEG_VERSION.tar.xz" -C "$L/ffmpeg-$FFMPEG_VERSION" --strip-components=1 \
    "ffmpeg-$FFMPEG_VERSION/COPYING.LGPLv2.1" "ffmpeg-$FFMPEG_VERSION/LICENSE.md"
  tar -xf "$SRC/lame-$LAME_VERSION.tar.gz" -C "$L/lame-$LAME_VERSION" --strip-components=1 \
    "lame-$LAME_VERSION/COPYING" "lame-$LAME_VERSION/LICENSE"
  tar -xf "$SRC/dav1d-$DAV1D_VERSION.tar.xz" -C "$L/dav1d-$DAV1D_VERSION" --strip-components=1 \
    "dav1d-$DAV1D_VERSION/COPYING"
  {
    echo "ffmpeg $FFMPEG_VERSION  https://ffmpeg.org/releases/ffmpeg-$FFMPEG_VERSION.tar.xz  sha256 ${!ffmpeg_sha_var}"
    echo "lame $LAME_VERSION  https://downloads.sourceforge.net/lame/lame-$LAME_VERSION.tar.gz  sha256 $SHA_LAME"
    echo "dav1d $DAV1D_VERSION  https://downloads.videolan.org/pub/videolan/dav1d/$DAV1D_VERSION/dav1d-$DAV1D_VERSION.tar.xz  sha256 $SHA_DAV1D"
    echo "ffmpeg tarball signature: $SIG_STATUS"
    echo "lame patch: patches/lame-$LAME_VERSION-symbols.patch  sha256 $(shasum -a 256 "$ROOT/patches/lame-$LAME_VERSION-symbols.patch" | awk '{print $1}')"
    echo "lame configure: --disable-shared --enable-static --disable-frontend --disable-decoder"
    echo "build script commit $(git -C "$ROOT" rev-parse HEAD 2>/dev/null || echo unknown)$(git -C "$ROOT" diff --quiet HEAD -- scripts patches 2>/dev/null || echo ' (with uncommitted changes)')"
    echo "macOS deployment target $MACOSX_DEPLOYMENT_TARGET"
    [ -f "$OUT/ffmpeg" ] && { echo "--- ffmpeg -version (arm64 slice)"; arch -arm64 "$OUT/ffmpeg" -version 2>/dev/null | head -3; echo "binary sha256 $(shasum -a 256 "$OUT/ffmpeg" | awk '{print $1}')"; }
  } > "$ROOT/BUILDINFO.txt"
}

if [ "${NOTICES_ONLY:-0}" = "1" ]; then collect_notices; echo "notices written to $ROOT/licenses"; exit 0; fi

build_arch() {
  local ARCH="$1"
  local PREFIX="$WORK/prefix-$ARCH" B="$WORK/build-$ARCH"
  local HOST CPU_FAMILY
  case "$ARCH" in
    arm64)  HOST="aarch64-apple-darwin"; CPU_FAMILY="aarch64" ;;
    x86_64) HOST="x86_64-apple-darwin";  CPU_FAMILY="x86_64" ;;
  esac
  local CFLAGS_ARCH="-arch $ARCH -mmacosx-version-min=$MACOSX_DEPLOYMENT_TARGET"
  rm -rf "$B" "$PREFIX"; mkdir -p "$B" "$PREFIX"

  echo "=== [$ARCH] lame $LAME_VERSION"
  tar -xf "$SRC/lame-$LAME_VERSION.tar.gz" -C "$B"
  ( cd "$B/lame-$LAME_VERSION"
    patch -p1 <"$ROOT/patches/lame-$LAME_VERSION-symbols.patch" >/dev/null   # drop lame_init_old; breaks modern linkers
    # --disable-decoder: leave out LAME's mpglib MP3 decoder (ffmpeg has its own and never uses it).
    ./configure --host="$HOST" --prefix="$PREFIX" --disable-shared --enable-static --disable-frontend --disable-decoder \
      CC="clang" CFLAGS="$CFLAGS_ARCH -O2" LDFLAGS="$CFLAGS_ARCH" >"$WORK/lame-$ARCH.log" 2>&1
    make -j"$JOBS" >>"$WORK/lame-$ARCH.log" 2>&1
    make install >>"$WORK/lame-$ARCH.log" 2>&1 )

  echo "=== [$ARCH] dav1d $DAV1D_VERSION"
  tar -xf "$SRC/dav1d-$DAV1D_VERSION.tar.xz" -C "$B"
  cat >"$B/meson-$ARCH.ini" <<MESON
[binaries]
c = ['clang', '-arch', '$ARCH']
ar = 'ar'
strip = 'strip'
[host_machine]
system = 'darwin'
cpu_family = '$CPU_FAMILY'
cpu = '$CPU_FAMILY'
endian = 'little'
[built-in options]
c_args = ['-mmacosx-version-min=$MACOSX_DEPLOYMENT_TARGET']
c_link_args = ['-arch', '$ARCH', '-mmacosx-version-min=$MACOSX_DEPLOYMENT_TARGET']
MESON
  ( cd "$B/dav1d-$DAV1D_VERSION"
    meson setup _b --cross-file "$B/meson-$ARCH.ini" --prefix "$PREFIX" --libdir lib --buildtype release \
      --default-library static -Denable_tools=false -Denable_tests=false -Denable_examples=false >"$WORK/dav1d-$ARCH.log" 2>&1
    ninja -C _b >>"$WORK/dav1d-$ARCH.log" 2>&1
    ninja -C _b install >>"$WORK/dav1d-$ARCH.log" 2>&1 )

  echo "=== [$ARCH] ffmpeg $FFMPEG_VERSION"
  tar -xf "$SRC/ffmpeg-$FFMPEG_VERSION.tar.xz" -C "$B"
  ( cd "$B/ffmpeg-$FFMPEG_VERSION"
    # Only our own prefix may satisfy pkg-config, never Homebrew's (wrong architecture for the cross slice).
    export PKG_CONFIG_LIBDIR="$PREFIX/lib/pkgconfig" PKG_CONFIG_PATH=""
    local CROSS=()
    [ "$ARCH" != "$(uname -m)" ] && CROSS=(--enable-cross-compile --target-os=darwin)
    ./configure --arch="$ARCH" ${CROSS[@]+"${CROSS[@]}"} --cc="clang -arch $ARCH" \
      --disable-gpl --disable-nonfree --disable-autodetect \
      --enable-static --disable-shared --disable-ffplay --disable-ffprobe --disable-doc --disable-debug \
      --enable-libmp3lame --enable-libdav1d --enable-videotoolbox \
      --pkg-config-flags="--static" \
      --extra-cflags="$CFLAGS_ARCH -I$PREFIX/include" --extra-ldflags="$CFLAGS_ARCH -L$PREFIX/lib" \
      >"$WORK/ffmpeg-configure-$ARCH.log" 2>&1
    make -j"$JOBS" >"$WORK/ffmpeg-make-$ARCH.log" 2>&1
    cp ffmpeg "$OUT/ffmpeg_$ARCH"
    strip "$OUT/ffmpeg_$ARCH" )
}

build_arch arm64
build_arch x86_64

lipo -create "$OUT/ffmpeg_arm64" "$OUT/ffmpeg_x86_64" -output "$OUT/ffmpeg"
chmod +x "$OUT/ffmpeg"
# Ad-hoc sign so both slices carry a valid signature (Apple Silicon refuses unsigned arm64 code).
# This is not a Developer ID signature; the app downloads the file itself, so no quarantine/Gatekeeper step applies.
codesign --force --sign - "$OUT/ffmpeg"
codesign --verify --verbose=2 "$OUT/ffmpeg"
shasum -a 256 "$OUT/ffmpeg" | awk '{print $1}' >"$OUT/ffmpeg.sha256"
lipo -info "$OUT/ffmpeg"
echo "SHA256: $(cat "$OUT/ffmpeg.sha256")"
collect_notices
