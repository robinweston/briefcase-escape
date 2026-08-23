#!/usr/bin/env bash

set -euo pipefail

project_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if ! command -v godot >/dev/null 2>&1; then
  echo "Godot was not found on PATH. Install it with: brew install --cask godot" >&2
  exit 1
fi

cd "${project_dir}"
for level in 1 2 3; do
  snapshot="level-${level}-layout-snapshot.png"
  if [[ "${level}" == "1" ]]; then
    snapshot="level-layout-snapshot.png"
  fi
  godot \
    --audio-driver Dummy \
    --path . \
    --resolution 1280x720 \
    asset_gallery.tscn \
    -- \
    --capture-level-map="res://${snapshot}" \
    --start-level="${level}"
  echo "Updated ${project_dir}/${snapshot}"
done
