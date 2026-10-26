#!/usr/bin/env bash
# Runs Godot for this project, downloading the right version first if needed. All arguments
# go to Godot, e.g. to run the tests:
#
#   tools/godot.sh --headless --path . res://tests/test_runner.tscn
#
# Set GODOT to the path of a Godot binary you already have to use that instead. Otherwise, on
# 64-bit x86 Linux or Windows (from Git Bash), the official build is downloaded once, checked
# against the release's SHA-512 checksums, and cached in GODOT_CACHE_DIR
# (default: ~/.cache/dhull-garden).

set -euo pipefail

# Keep in sync with config/features in project.godot.
GODOT_VERSION="4.7.2"

if [[ -n "${GODOT:-}" ]]; then
  exec "$GODOT" "$@"
fi

case "$(uname -s)-$(uname -m)" in
  Linux-x86_64)
    archive="Godot_v${GODOT_VERSION}-stable_linux.x86_64.zip"
    executable="Godot_v${GODOT_VERSION}-stable_linux.x86_64"
    ;;
  MINGW64_NT*-x86_64)
    archive="Godot_v${GODOT_VERSION}-stable_win64.exe.zip"
    # The console build is a small launcher for the main .exe beside it. It keeps Godot's
    # output and exit code in the terminal, which the main .exe on its own doesn't.
    executable="Godot_v${GODOT_VERSION}-stable_win64_console.exe"
    ;;
  *)
    echo "tools/godot.sh can only download Godot on 64-bit x86 Linux or Windows." >&2
    echo "Set GODOT to the path of your Godot ${GODOT_VERSION} binary instead." >&2
    exit 1
    ;;
esac

install_dir="${GODOT_CACHE_DIR:-${XDG_CACHE_HOME:-$HOME/.cache}/dhull-garden}/godot-${GODOT_VERSION}"
binary="$install_dir/$executable"

if [[ ! -x "$binary" ]]; then
  echo "Downloading Godot ${GODOT_VERSION}..." >&2
  url="https://github.com/godotengine/godot/releases/download/${GODOT_VERSION}-stable"
  download_dir="$(mktemp -d)"
  trap 'rm -rf "$download_dir"' EXIT
  curl -fsSL -o "$download_dir/$archive" "$url/$archive"
  curl -fsSL -o "$download_dir/SHA512-SUMS.txt" "$url/SHA512-SUMS.txt"
  # Fails if the zip's checksum doesn't match, or if the checksum file doesn't list it.
  (
    cd "$download_dir"
    awk -v file="$archive" '$2 == file' SHA512-SUMS.txt | sha512sum --check --quiet -
  )
  # Unpack beside the final folder, then rename, so an interrupted run never leaves a partial
  # install that looks complete.
  rm -rf "$install_dir" "$install_dir.partial"
  mkdir -p "$install_dir.partial"
  unzip -q "$download_dir/$archive" -d "$install_dir.partial"
  chmod +x "$install_dir.partial/$executable"
  mv "$install_dir.partial" "$install_dir"
  rm -rf "$download_dir"
  trap - EXIT
fi

exec "$binary" "$@"
