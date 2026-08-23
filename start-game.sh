#!/usr/bin/env bash

set -euo pipefail

game_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
game_port="${BRIEFCASE_PORT:-8080}"
open_browser="${BRIEFCASE_OPEN_BROWSER:-1}"
watch_changes="${BRIEFCASE_WATCH:-1}"
game_url="http://localhost:${game_port}"
watch_process=""
watch_marker=""

if ! command -v godot >/dev/null 2>&1; then
  echo "Godot was not found on PATH. Install it with: brew install --cask godot" >&2
  exit 1
fi

if ! command -v python3 >/dev/null 2>&1; then
  echo "Python 3 is required to serve the browser build." >&2
  exit 1
fi

export_game() {
  echo "Exporting Briefcase Game for the browser..."
  mkdir -p "${game_dir}/build/web"
  godot --headless --path "${game_dir}" \
    --export-release Web "${game_dir}/build/web/index.html"
}

cleanup() {
  if [[ -n "${watch_process}" ]]; then
    kill "${watch_process}" 2>/dev/null || true
  fi
  if [[ -n "${watch_marker}" && -f "${watch_marker}" ]]; then
    rm "${watch_marker}"
  fi
}

watch_and_export() {
  while sleep 0.75; do
    changed_file="$(find "${game_dir}" \
      \( -path "${game_dir}/.godot" -o -path "${game_dir}/build" -o -path "${game_dir}/output" \) -prune -o \
      -type f \( \
        -name '*.gd' -o -name '*.tscn' -o -name '*.tres' -o -name '*.godot' -o -name '*.cfg' -o \
        -name '*.svg' -o -name '*.png' -o -name '*.jpg' -o -name '*.jpeg' -o -name '*.webp' -o \
        -name '*.wav' -o -name '*.ogg' -o -name '*.mp3' -o -name '*.glb' -o -name '*.gltf' -o -name '*.obj' \
      \) -newer "${watch_marker}" -print -quit)"

    if [[ -n "${changed_file}" ]]; then
      # Coalesce the group of writes produced by one editor save.
      sleep 0.25
      touch "${watch_marker}"
      if export_game; then
        echo "Build updated. Refresh ${game_url} to see the changes."
      else
        echo "Export failed; the previous browser build is still being served." >&2
      fi
    fi
  done
}

trap cleanup EXIT INT TERM
export_game

echo "Starting Briefcase Game at ${game_url}"
echo "Press Ctrl+C to stop."

if [[ "${watch_changes}" == "1" ]]; then
  watch_marker="$(mktemp "${TMPDIR:-/tmp}/briefcase-game-watch.XXXXXX")"
  touch "${watch_marker}"
  watch_and_export &
  watch_process=$!
  echo "Watching project files; refresh the browser after an updated-build message."
fi

if [[ "${open_browser}" == "1" ]]; then
  (
    sleep 1
    open "${game_url}"
  ) &
fi

cd "${game_dir}"
python3 -m http.server "${game_port}" --directory build/web
