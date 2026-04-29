#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SAFARI="$ROOT_DIR/macos-safari-browser-use/scripts/safari"

if [[ "$(uname -s 2>/dev/null || true)" != "Darwin" ]]; then
  echo "smoke_safari: non-macOS host; live Safari checks skipped"
  exit 0
fi

if [[ "${CI:-}" == "true" && "${SAFARI_SMOKE_LIVE:-0}" != "1" ]]; then
  echo "smoke_safari: CI host detected; set SAFARI_SMOKE_LIVE=1 to run live Safari checks"
  exit 0
fi

if ! /usr/bin/osascript -e 'id of application "Safari"' >/dev/null 2>&1; then
  echo "smoke_safari: Safari unavailable; skipped"
  exit 0
fi

last_stdout=""
last_stderr=""

run_safari_command() {
  local timeout_seconds="$1"
  shift
  local tmp_out tmp_err status

  tmp_out="$(mktemp "${TMPDIR:-/tmp}/safari-smoke-out.XXXXXX")"
  tmp_err="$(mktemp "${TMPDIR:-/tmp}/safari-smoke-err.XXXXXX")"
  set +e
  /usr/bin/python3 - "$timeout_seconds" "$SAFARI" "$@" >"$tmp_out" 2>"$tmp_err" <<'PY'
import subprocess
import sys

timeout_seconds = int(sys.argv[1])
cmd = sys.argv[2:]

try:
    result = subprocess.run(cmd, timeout=timeout_seconds)
except subprocess.TimeoutExpired:
    print(
        f"command timed out after {timeout_seconds}s: {' '.join(cmd)}",
        file=sys.stderr,
    )
    raise SystemExit(124)

raise SystemExit(result.returncode)
PY
  status=$?
  set -e
  last_stdout="$(cat "$tmp_out")"
  last_stderr="$(cat "$tmp_err")"
  rm -f "$tmp_out" "$tmp_err"
  return "$status"
}

print_last_output() {
  local label="$1"
  if [[ -n "$last_stdout" ]]; then
    printf '%s\n' "--- stdout: $label ---" >&2
    printf '%s\n' "$last_stdout" >&2
  fi
  if [[ -n "$last_stderr" ]]; then
    printf '%s\n' "--- stderr: $label ---" >&2
    printf '%s\n' "$last_stderr" >&2
  fi
}

assert_json_expr() {
  local label="$1" expr="$2" message="$3" status
  set +e
  JSON_PAYLOAD="$last_stdout" JSON_EXPR="$expr" JSON_MESSAGE="$message" /usr/bin/python3 - <<'PY'
import json
import os
import sys

payload = os.environ["JSON_PAYLOAD"]
try:
    data = json.loads(payload)
except Exception as exc:
    print(f"invalid JSON: {exc}", file=sys.stderr)
    raise SystemExit(1)

expr = os.environ["JSON_EXPR"]
helpers = {"data": data, "int": int, "isinstance": isinstance, "list": list}
if not eval(expr, {"__builtins__": {}}, helpers):
    print(os.environ["JSON_MESSAGE"], file=sys.stderr)
    raise SystemExit(1)
PY
  status=$?
  set -e
  if [[ "$status" -ne 0 ]]; then
    echo "smoke_safari: $label output failed validation" >&2
    print_last_output "$label"
    exit 1
  fi
}

if ! run_safari_command 30 version; then
  echo "smoke_safari: version failed" >&2
  print_last_output "version"
  exit 1
fi
assert_json_expr "version" 'data.get("success") is True' "version output did not report success"

if ! run_safari_command 30 window-count; then
  echo "smoke_safari: window-count failed" >&2
  print_last_output "window-count"
  exit 1
fi
assert_json_expr "window-count" 'data.get("success") is True and isinstance(data.get("count"), int)' "window-count output did not report success"

if ! run_safari_command 30 tabs; then
  echo "smoke_safari: tabs failed" >&2
  print_last_output "tabs"
  exit 1
fi
assert_json_expr "tabs" 'data.get("success") is True and isinstance(data.get("tabs"), list)' "tabs output missing tabs list"

echo "smoke_safari: ok"
