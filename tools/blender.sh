#!/usr/bin/env bash
# Runs Blender for this project, downloading the right version first if needed. All arguments
# go to Blender, e.g. to run a script without opening the interface:
#
#   tools/blender.sh --background --python my_script.py
#
# Set BLENDER to the path of a Blender binary you already have to use that instead. Otherwise,
# on 64-bit x86 Linux or Windows (from Git Bash), the official build is downloaded once,
# checked against the release's SHA-256 checksums, and cached in BLENDER_CACHE_DIR
# (default: ~/.cache/dhull-garden).

set -euo pipefail

# The Blender LTS release the project's .blend files are saved with.
BLENDER_VERSION="5.2.3"

if [[ -n "${BLENDER:-}" ]]; then
  exec "$BLENDER" "$@"
fi

case "$(uname -s)-$(uname -m)" in
  Linux-x86_64)
    name="blender-${BLENDER_VERSION}-linux-x64"
    archive="$name.tar.xz"
    executable="blender"
    ;;
  MINGW64_NT*-x86_64)
    name="blender-${BLENDER_VERSION}-windows-x64"
    archive="$name.zip"
    executable="blender.exe"
    ;;
  *)
    echo "tools/blender.sh can only download Blender on 64-bit x86 Linux or Windows." >&2
    echo "Set BLENDER to the path of your Blender ${BLENDER_VERSION} binary instead." >&2
    exit 1
    ;;
esac

cache_dir="${BLENDER_CACHE_DIR:-${XDG_CACHE_HOME:-$HOME/.cache}/dhull-garden}"
install_dir="$cache_dir/$name"

if [[ ! -x "$install_dir/$executable" ]]; then
  echo "Downloading Blender ${BLENDER_VERSION}..." >&2
  url="https://download.blender.org/release/Blender${BLENDER_VERSION%.*}"
  download_dir="$(mktemp -d)"
  trap 'rm -rf "$download_dir"' EXIT
  curl -fsSL -o "$download_dir/$archive" "$url/$archive"
  curl -fsSL -o "$download_dir/checksums.sha256" "$url/blender-${BLENDER_VERSION}.sha256"
  # Fails if the archive's checksum doesn't match, or if the checksum file doesn't list it.
  (
    cd "$download_dir"
    awk -v file="$archive" '$2 == file' checksums.sha256 | sha256sum --check --quiet -
  )
  # Unpack beside the final folder, then rename, so an interrupted run never leaves a partial
  # install that looks complete. Both archives hold a single folder named after the archive.
  rm -rf "$install_dir" "$install_dir.partial"
  mkdir -p "$install_dir.partial"
  case "$archive" in
    *.tar.xz) tar -xJf "$download_dir/$archive" -C "$install_dir.partial" ;;
    *.zip) unzip -q "$download_dir/$archive" -d "$install_dir.partial" ;;
  esac
  mv "$install_dir.partial/$name" "$install_dir"
  rm -rf "$install_dir.partial" "$download_dir"
  trap - EXIT
fi

exec "$install_dir/$executable" "$@"
