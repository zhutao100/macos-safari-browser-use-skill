#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SAFARI="$ROOT_DIR/macos-safari-browser-use/scripts/safari"

if [[ "$(uname -s 2>/dev/null || true)" != "Darwin" ]]; then
  echo "smoke_safari: non-macOS host; live Safari checks skipped"
  exit 0
fi

if ! /usr/bin/osascript -e 'id of application "Safari"' >/dev/null 2>&1; then
  echo "smoke_safari: Safari unavailable; skipped"
  exit 0
fi

version_out="$($SAFARI version 2>&1)" || {
  echo "smoke_safari: version failed: $version_out" >&2
  exit 1
}
echo "$version_out" | grep -q '"success":true' || {
  echo "smoke_safari: version output did not report success" >&2
  exit 1
}

window_out="$($SAFARI window-count 2>&1)" || true
echo "$window_out" | grep -q '"success"' || {
  echo "smoke_safari: window-count output missing success" >&2
  exit 1
}

tabs_out="$($SAFARI tabs 2>&1)" || true
echo "$tabs_out" | grep -q '"tabs"' || {
  echo "smoke_safari: tabs output missing tabs key" >&2
  exit 1
}

echo "smoke_safari: ok"
