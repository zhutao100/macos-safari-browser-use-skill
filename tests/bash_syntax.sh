#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

tmp_scripts="$(mktemp)"
trap 'rm -f "$tmp_scripts"' EXIT
find "$ROOT_DIR" -type f \( -name '*.sh' -o -name 'safari' \) > "$tmp_scripts"
while IFS= read -r script; do
  bash -n "$script"
done < "$tmp_scripts"

echo "bash_syntax: ok"
