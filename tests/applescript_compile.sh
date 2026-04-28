#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SKILL_DIR="$ROOT_DIR/macos-safari-browser-use"

if [[ "$(uname -s 2>/dev/null || true)" != "Darwin" ]]; then
  echo "applescript_compile: non-macOS host; skipped"
  exit 0
fi

if [[ ! -x /usr/bin/osacompile ]]; then
  echo "applescript_compile: /usr/bin/osacompile unavailable; skipped"
  exit 0
fi

tmp_dir="$(mktemp -d "${TMPDIR:-/tmp}/safari-applescript.XXXXXX")"
trap 'rm -rf "$tmp_dir"' EXIT

count=0
while IFS= read -r -d '' script; do
  rel="${script#"$SKILL_DIR"/}"
  out_path="$tmp_dir/${rel%.applescript}.scpt"
  mkdir -p "$(dirname "$out_path")"
  /usr/bin/osacompile -o "$out_path" "$script"
  count=$((count + 1))
done < <(find "$SKILL_DIR" -type f -name '*.applescript' -print0)

echo "applescript_compile: ok ($count files)"
