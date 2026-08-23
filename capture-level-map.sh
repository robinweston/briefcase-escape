#!/usr/bin/env bash

set -euo pipefail

project_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if ! command -v godot >/dev/null 2>&1; then
  echo "Godot was not found on PATH. Install it with: brew install --cask godot" >&2
  exit 1
fi

cd "${project_dir}"
godot \
  --path . \
  --resolution 1280x720 \
  asset_gallery.tscn \
  -- \
  --capture-level-map=res://level-layout-snapshot.png

echo "Updated ${project_dir}/level-layout-snapshot.png"
