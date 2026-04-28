#!/usr/bin/env bash
set -euo pipefail

json_escape() {
  local s="$1"
  s=${s//\\/\\\\}
  s=${s//\"/\\\"}
  s=${s//$'\n'/\\n}
  s=${s//$'\r'/\\n}
  s=${s//$'\t'/\\t}
  printf '%s' "$s"
}

check_json() {
  local name="$1" ok="$2" detail="$3" required="$4"
  printf '{"name":"%s","ok":%s,"required":%s,"detail":"%s"}' \
    "$(json_escape "$name")" "$ok" "$required" "$(json_escape "$detail")"
}

checks=()
overall=true

add_check() {
  local name="$1" ok="$2" detail="$3" required="${4:-true}"
  checks+=("$(check_json "$name" "$ok" "$detail" "$required")")
  if [[ "$required" == "true" && "$ok" != "true" ]]; then
    overall=false
  fi
}

if [[ "$(uname -s 2>/dev/null || true)" == "Darwin" ]]; then
  os_version="$(/usr/bin/sw_vers -productVersion 2>/dev/null || true)"
  add_check "macOS" true "Darwin ${os_version}" true
else
  add_check "macOS" false "This skill requires macOS; live Safari checks were not run." true
fi

if [[ -x /usr/bin/osascript ]]; then
  add_check "osascript" true "/usr/bin/osascript" true
else
  add_check "osascript" false "/usr/bin/osascript is missing" true
fi

if [[ "$(uname -s 2>/dev/null || true)" == "Darwin" && -x /usr/bin/osascript ]]; then
  safari_id="$(/usr/bin/osascript -e 'id of application "Safari"' 2>&1 || true)"
  if [[ "$safari_id" == "com.apple.Safari" ]]; then
    add_check "Safari.app" true "$safari_id" true
  else
    add_check "Safari.app" false "$safari_id" true
  fi

  automation_out="$(/usr/bin/osascript -e 'tell application "Safari" to get name' 2>&1 || true)"
  if [[ "$automation_out" == "Safari" ]]; then
    add_check "Automation permission" true "Terminal/agent can send Apple Events to Safari." true
  else
    add_check "Automation permission" false "$automation_out" true
  fi

  js_out="$(
    /usr/bin/osascript <<'APPLESCRIPT' 2>&1 || true
try
  tell application "Safari"
    activate
    if (count of windows) is 0 then
      make new document with properties {URL:"about:blank"}
      delay 0.2
    end if
    set jsResult to do JavaScript "1+1" in current tab of front window
    return jsResult as text
  end tell
on error errMsg number errNum
  return errMsg
end try
APPLESCRIPT
  )"
  if [[ "$js_out" == "2" || "$js_out" == "2.0" ]]; then
    add_check "JavaScript from Apple Events" true "Safari accepted do JavaScript in the front tab." true
  else
    add_check "JavaScript from Apple Events" false "$js_out" true
  fi
fi

if [[ -x /usr/sbin/screencapture ]]; then
  add_check "screencapture" true "/usr/sbin/screencapture available for window screenshots." false
else
  add_check "screencapture" false "/usr/sbin/screencapture missing; screenshot command will fail." false
fi

if [[ -x /usr/bin/safaridriver ]]; then
  driver_version="$(/usr/bin/safaridriver --version 2>&1 || true)"
  add_check "safaridriver" true "$driver_version" false
else
  add_check "safaridriver" false "/usr/bin/safaridriver missing; WebDriver commands unavailable." false
fi

IFS=,
printf '{"success":%s,"checks":[%s],"notes":["check-setup may launch Safari and create an about:blank window when no Safari window is open","Enable JavaScript from Apple Events in Safari developer settings for DOM extraction and interaction commands"]}\n' "$overall" "${checks[*]}"
