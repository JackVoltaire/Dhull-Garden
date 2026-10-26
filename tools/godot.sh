#!/usr/bin/env bash
# Runs Godot for this project, downloading the right version first if needed. All arguments
# go to Godot, e.g. to run the tests:
#
#   tools/godot.sh --headless --path . res://tests/test_runner.tscn
#
# Set GODOT to the path of a Godot binary you already have to use that instead. Otherwise, on
# 64-bit x86 Linux, the official build is downloaded once, checked against the release's
# SHA-512 checksums, and cached in GODOT_CACHE_DIR (default: ~/.cache/dhull-garden).

set -euo pipefail

# Keep in sync with config/features in project.godot.
GODOT_VERSION="4.7.2"

if [[ -n "${GODOT:-}" ]]; then
  exec "$GODOT" "$@"
fi

if [[ "$(uname -s)" != "Linux" || "$(uname -m)" != "x86_64" ]]; then
  echo "tools/godot.sh can only download Godot on 64-bit x86 Linux." >&2
  echo "Set GODOT to the path of your Godot ${GODOT_VERSION} binary instead." >&2
  exit 1
fi

name="Godot_v${GODOT_VERSION}-stable_linux.x86_64"
cache_dir="${GODOT_CACHE_DIR:-${XDG_CACHE_HOME:-$HOME/.cache}/dhull-garden}/godot-${GODOT_VERSION}"
binary="$cache_dir/$name"

if [[ ! -x "$binary" ]]; then
  echo "Downloading Godot ${GODOT_VERSION}..." >&2
  url="https://github.com/godotengine/godot/releases/download/${GODOT_VERSION}-stable"
  download_dir="$(mktemp -d)"
  trap 'rm -rf "$download_dir"' EXIT
  curl -fsSL -o "$download_dir/$name.zip" "$url/$name.zip"
  curl -fsSL -o "$download_dir/SHA512-SUMS.txt" "$url/SHA512-SUMS.txt"
  # Fails if the zip's checksum doesn't match, or if the checksum file doesn't list it.
  (
    cd "$download_dir"
    awk -v file="$name.zip" '$2 == file' SHA512-SUMS.txt | sha512sum --check --quiet -
  )
  unzip -q "$download_dir/$name.zip" -d "$download_dir"
  mkdir -p "$cache_dir"
  # Copy under a temporary name, then rename, so an interrupted run never leaves a partial
  # binary that looks complete.
  cp "$download_dir/$name" "$binary.partial"
  chmod +x "$binary.partial"
  mv "$binary.partial" "$binary"
  rm -rf "$download_dir"
  trap - EXIT
fi

exec "$binary" "$@"
