#!/usr/bin/env bash

set -euo pipefail

gallery_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if ! command -v godot >/dev/null 2>&1; then
  echo "Godot was not found on PATH. Install it with: brew install --cask godot" >&2
  exit 1
fi

cd "${gallery_dir}"
exec godot --path . asset_gallery.tscn
