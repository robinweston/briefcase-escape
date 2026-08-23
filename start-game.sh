#!/usr/bin/env bash

set -euo pipefail

game_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
game_port="${BRIEFCASE_PORT:-8080}"
open_browser="${BRIEFCASE_OPEN_BROWSER:-1}"
game_url="http://localhost:${game_port}"

if ! command -v godot >/dev/null 2>&1; then
  echo "Godot was not found on PATH. Install it with: brew install --cask godot" >&2
  exit 1
fi

if ! command -v python3 >/dev/null 2>&1; then
  echo "Python 3 is required to serve the browser build." >&2
  exit 1
fi

echo "Exporting Briefcase Game for the browser..."
mkdir -p "${game_dir}/build/web"
godot --headless --path "${game_dir}" \
  --export-release Web "${game_dir}/build/web/index.html"

echo "Starting Briefcase Game at ${game_url}"
echo "Press Ctrl+C to stop."

if [[ "${open_browser}" == "1" ]]; then
  (
    sleep 1
    open "${game_url}"
  ) &
fi

cd "${game_dir}"
exec python3 -m http.server "${game_port}" --directory build/web

