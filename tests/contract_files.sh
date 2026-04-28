#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SKILL_DIR="$ROOT_DIR/macos-safari-browser-use"

required=(
  "$ROOT_DIR/README.md"
  "$ROOT_DIR/AGENTS.md"
  "$SKILL_DIR/SKILL.md"
  "$SKILL_DIR/scripts/check-setup.sh"
  "$SKILL_DIR/scripts/safari"
  "$SKILL_DIR/scripts/lib/safari-control.applescript"
  "$SKILL_DIR/references/command-reference.md"
  "$SKILL_DIR/references/permissions-and-setup.md"
  "$SKILL_DIR/references/automation-patterns.md"
  "$SKILL_DIR/references/workflows.md"
  "$SKILL_DIR/references/research-and-validation.md"
  "$SKILL_DIR/assets/js/page-summary.js"
  "$SKILL_DIR/assets/webdriver/safari_smoke_test.py"
  "$ROOT_DIR/tests/applescript_compile.sh"
  "$ROOT_DIR/tests/live_safari_e2e.sh"
)

for file in "${required[@]}"; do
  if [[ ! -f "$file" ]]; then
    echo "missing required file: $file" >&2
    exit 1
  fi
done

if ! grep -q '^---$' "$SKILL_DIR/SKILL.md"; then
  echo "SKILL.md missing YAML front matter" >&2
  exit 1
fi
if ! grep -q '^name: macos-safari-browser-use$' "$SKILL_DIR/SKILL.md"; then
  echo "SKILL.md missing expected name" >&2
  exit 1
fi
if ! grep -q '^description: ' "$SKILL_DIR/SKILL.md"; then
  echo "SKILL.md missing description" >&2
  exit 1
fi

wrapper_count="$(find "$SKILL_DIR/scripts/commands" -type f -name '*.sh' | wc -l | tr -d ' ')"
if [[ "$wrapper_count" -lt 25 ]]; then
  echo "expected at least 25 command wrappers, found $wrapper_count" >&2
  exit 1
fi

tmp_scripts="$(mktemp)"
trap 'rm -f "$tmp_scripts"' EXIT
find "$SKILL_DIR/scripts" -type f \( -name '*.sh' -o -name 'safari' \) >"$tmp_scripts"
while IFS= read -r script; do
  if [[ ! -x "$script" ]]; then
    echo "script is not executable: $script" >&2
    exit 1
  fi
done <"$tmp_scripts"

echo "contract_files: ok"
