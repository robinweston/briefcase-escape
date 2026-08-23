#!/usr/bin/env bash

set -euo pipefail

if [[ "$#" -ne 1 ]]; then
  echo "Usage: $0 PATH_TO_EXPORTED_INDEX_HTML" >&2
  exit 1
fi

html_path="$1"
project_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
build_commit="$(git -C "${project_dir}" rev-parse --short=8 HEAD)"

if [[ ! -f "${html_path}" ]]; then
  echo "Exported HTML was not found: ${html_path}" >&2
  exit 1
fi

if ! grep -q '__BRIEFCASE_COMMIT__' "${html_path}"; then
  echo "Build commit placeholder was not found in: ${html_path}" >&2
  exit 1
fi

BRIEFCASE_BUILD_COMMIT="${build_commit}" perl -0pi -e \
  's/__BRIEFCASE_COMMIT__/$ENV{BRIEFCASE_BUILD_COMMIT}/g' "${html_path}"

echo "Injected Web build commit: ${build_commit}"
