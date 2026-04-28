#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SAFARI="$ROOT_DIR/macos-safari-browser-use/scripts/safari"

if [[ "$(uname -s 2>/dev/null || true)" != "Darwin" ]]; then
  echo "live_safari_e2e: non-macOS host; skipped"
  exit 0
fi

if [[ "${SAFARI_LIVE_E2E:-0}" != "1" ]]; then
  echo "live_safari_e2e: set SAFARI_LIVE_E2E=1 to run state-changing Safari checks"
  exit 0
fi

if ! /usr/bin/osascript -e 'id of application "Safari"' >/dev/null 2>&1; then
  echo "live_safari_e2e: Safari unavailable" >&2
  exit 1
fi

assert_json_success() {
  JSON_PAYLOAD="$1" /usr/bin/python3 - <<'PY'
import json
import os
import sys

payload = os.environ["JSON_PAYLOAD"]
try:
    data = json.loads(payload)
except Exception as exc:
    print(f"invalid JSON: {exc}: {payload[:500]}", file=sys.stderr)
    raise SystemExit(1)

if data.get("success") is not True:
    print(f"command did not report success: {payload[:500]}", file=sys.stderr)
    raise SystemExit(1)
PY
}

assert_json_expr() {
  JSON_PAYLOAD="$1" JSON_EXPR="$2" JSON_MESSAGE="$3" /usr/bin/python3 - <<'PY'
import json
import os
import sys

data = json.loads(os.environ["JSON_PAYLOAD"])
expr = os.environ["JSON_EXPR"]
if not eval(expr, {"__builtins__": {}}, {"data": data, "len": len}):
    print(os.environ["JSON_MESSAGE"], file=sys.stderr)
    print(json.dumps(data, indent=2, sort_keys=True), file=sys.stderr)
    raise SystemExit(1)
PY
}

json_value() {
  JSON_PAYLOAD="$1" JSON_EXPR="$2" /usr/bin/python3 - <<'PY'
import json
import os

data = json.loads(os.environ["JSON_PAYLOAD"])
value = eval(os.environ["JSON_EXPR"], {"__builtins__": {}}, {"data": data})
print(value)
PY
}

find_tab_by_url() {
  JSON_PAYLOAD="$("$SAFARI" tabs)" TARGET_URL="$1" /usr/bin/python3 - <<'PY'
import json
import os
import sys

data = json.loads(os.environ["JSON_PAYLOAD"])
target = os.environ["TARGET_URL"]
for tab in data.get("tabs", []):
    if tab.get("url") == target:
        print(tab["window"], tab["index"])
        raise SystemExit(0)

print(f"opened tab not found for URL: {target}", file=sys.stderr)
print(json.dumps(data, indent=2, sort_keys=True), file=sys.stderr)
raise SystemExit(1)
PY
}

tmp_dir="$(mktemp -d "${TMPDIR:-/tmp}/safari-live.XXXXXX")"
window_index=""
server_pid=""

cleanup() {
  if [[ -n "$window_index" ]]; then
    "$SAFARI" close-window "$window_index" >/dev/null 2>&1 || true
  fi
  if [[ -n "$server_pid" ]]; then
    kill "$server_pid" >/dev/null 2>&1 || true
    wait "$server_pid" >/dev/null 2>&1 || true
  fi
  rm -rf "$tmp_dir"
}
trap cleanup EXIT

html_path="$tmp_dir/safari-skill-fixture.html"
cat >"$html_path" <<'HTML'
<!doctype html>
<html lang="en">
<head>
  <meta charset="utf-8">
  <title>Safari Skill Fixture</title>
</head>
<body>
  <main>
    <h1>Safari skill fixture</h1>
    <p id="summary">Unique text marker: safari-skill-e2e-2026.</p>
    <a id="docs" href="https://example.com/docs">Example docs</a>
    <label for="q">Query</label>
    <input id="q" name="q" value="">
    <button id="clicker" type="button" onclick="document.body.dataset.clicked = String(Number(document.body.dataset.clicked || 0) + 1)">Click target</button>
  </main>
</body>
</html>
HTML

port_file="$tmp_dir/http.port"
/usr/bin/python3 - "$tmp_dir" "$port_file" >/dev/null 2>"$tmp_dir/http.log" <<'PY' &
from __future__ import annotations

import http.server
import socketserver
import sys
from pathlib import Path

directory = sys.argv[1]
port_file = Path(sys.argv[2])


class Handler(http.server.SimpleHTTPRequestHandler):
    def __init__(self, *args, **kwargs):
        super().__init__(*args, directory=directory, **kwargs)

    def log_message(self, format: str, *args: object) -> None:
        return


with socketserver.TCPServer(("127.0.0.1", 0), Handler) as httpd:
    port_file.write_text(str(httpd.server_address[1]), encoding="utf-8")
    httpd.serve_forever()
PY
server_pid=$!

deadline=$((SECONDS + 10))
while [[ ! -s "$port_file" && $SECONDS -lt $deadline ]]; do
  sleep 0.1
done
if [[ ! -s "$port_file" ]]; then
  echo "test HTTP server did not start" >&2
  sed -n '1,120p' "$tmp_dir/http.log" >&2 || true
  exit 1
fi
server_port="$(cat "$port_file")"

file_url="http://127.0.0.1:$server_port/safari-skill-fixture.html"

out="$("$SAFARI" open "$file_url" new-window)"
assert_json_success "$out"
read -r window_index tab_index < <(find_tab_by_url "$file_url")

out="$("$SAFARI" wait --window "$window_index" --tab "$tab_index")"
assert_json_success "$out"
assert_json_expr "$out" 'data["loaded"] is True' "fixture page did not reach readyState=complete"

out="$("$SAFARI" title --window "$window_index" --tab "$tab_index")"
assert_json_success "$out"
assert_json_expr "$out" 'data["title"] == "Safari Skill Fixture"' "title command returned the wrong title"

out="$("$SAFARI" text '#summary' --window "$window_index" --tab "$tab_index")"
assert_json_success "$out"
assert_json_expr "$out" '"safari-skill-e2e-2026" in data["text"]' "text command did not return the fixture marker"

out="$("$SAFARI" query 'main h1' --window "$window_index" --tab "$tab_index")"
assert_json_success "$out"
assert_json_expr "$out" 'len(data["matches"]) == 1 and data["matches"][0]["text"] == "Safari skill fixture"' "query command did not return the expected h1"

out="$("$SAFARI" links --window "$window_index" --tab "$tab_index")"
assert_json_success "$out"
assert_json_expr "$out" 'len(data["links"]) == 1 and data["links"][0]["href"] == "https://example.com/docs"' "links command did not return the expected link"

out="$("$SAFARI" js 'document.title' --window "$window_index" --tab "$tab_index")"
assert_json_success "$out"
assert_json_expr "$out" 'data["result"] == "Safari Skill Fixture"' "js command returned the wrong result"

out="$("$SAFARI" js-json '({title: document.title, marker: document.querySelector("#summary").textContent.includes("safari-skill-e2e-2026")})' --window "$window_index" --tab "$tab_index")"
assert_json_success "$out"
assert_json_expr "$out" 'data["result"]["title"] == "Safari Skill Fixture" and data["result"]["marker"] is True' "js-json command returned the wrong object"

out="$("$SAFARI" type '#q' 'typed from Safari live e2e' --window "$window_index" --tab "$tab_index")"
assert_json_success "$out"
assert_json_expr "$out" 'data["result"]["typed"] is True' "type command did not report typed=true"

out="$("$SAFARI" js-json '({value: document.querySelector("#q").value})' --window "$window_index" --tab "$tab_index")"
assert_json_success "$out"
assert_json_expr "$out" 'data["result"]["value"] == "typed from Safari live e2e"' "type command did not update the input value"

out="$("$SAFARI" click '#clicker' --window "$window_index" --tab "$tab_index")"
assert_json_success "$out"
assert_json_expr "$out" 'data["result"]["clicked"] is True' "click command did not report clicked=true"

out="$("$SAFARI" js-json '({clicked: Number(document.body.dataset.clicked || 0)})' --window "$window_index" --tab "$tab_index")"
assert_json_success "$out"
assert_json_expr "$out" 'data["result"]["clicked"] == 1' "click command did not update the fixture state"

out="$("$SAFARI" source --window "$window_index" --tab "$tab_index")"
assert_json_success "$out"
assert_json_expr "$out" '"safari-skill-e2e-2026" in data["source"]' "source command did not include the fixture marker"

screenshot_path="$tmp_dir/safari-e2e.png"
"$SAFARI" focus-tab "$window_index" "$tab_index" >/dev/null
out="$("$SAFARI" screenshot "$screenshot_path")"
assert_json_success "$out"
if [[ ! -s "$screenshot_path" ]]; then
  echo "screenshot command did not create a non-empty PNG" >&2
  exit 1
fi

"$SAFARI" close-window "$window_index" >/dev/null
window_index=""

if [[ -n "${SAFARI_LIVE_FIXTURE_HTML:-}" ]]; then
  if [[ ! -f "$SAFARI_LIVE_FIXTURE_HTML" ]]; then
    echo "SAFARI_LIVE_FIXTURE_HTML does not exist: $SAFARI_LIVE_FIXTURE_HTML" >&2
    exit 1
  fi

  cp "$SAFARI_LIVE_FIXTURE_HTML" "$tmp_dir/external-fixture.html"
  file_url="http://127.0.0.1:$server_port/external-fixture.html"
  out="$("$SAFARI" open "$file_url" new-window)"
  assert_json_success "$out"
  read -r window_index tab_index < <(find_tab_by_url "$file_url")

  out="$("$SAFARI" wait --window "$window_index" --tab "$tab_index")"
  assert_json_success "$out"

  out="$("$SAFARI" js-json '({title: document.title, textLength: (document.body && document.body.innerText || "").length, linkCount: document.links.length})' --window "$window_index" --tab "$tab_index")"
  assert_json_success "$out"
  assert_json_expr "$out" 'len(data["result"]["title"]) > 0 and data["result"]["textLength"] > 0' "fixture HTML did not produce readable page content"

  "$SAFARI" close-window "$window_index" >/dev/null
  window_index=""
fi

echo "live_safari_e2e: ok"
