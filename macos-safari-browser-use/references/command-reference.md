# Command reference

All public commands return JSON and live under:

```text
macos-safari-browser-use/scripts/safari
macos-safari-browser-use/scripts/commands/**
```

The wrappers call the consolidated CLI, so these are equivalent:

```bash
macos-safari-browser-use/scripts/safari tabs
macos-safari-browser-use/scripts/commands/tab/list.sh
```

## Setup

```bash
macos-safari-browser-use/scripts/check-setup.sh
macos-safari-browser-use/scripts/safari check
```

Returns:

```json
{
  "success": true,
  "checks": [
    {"name": "macOS", "ok": true, "required": true, "detail": "Darwin 26.4"}
  ],
  "notes": []
}
```

`check-setup.sh` may launch Safari and create an `about:blank` window if no Safari window is open, because `do JavaScript` must run against a tab to verify Safari’s JavaScript-from-Apple-Events setting.

## System

```bash
macos-safari-browser-use/scripts/safari version
macos-safari-browser-use/scripts/safari activate

macos-safari-browser-use/scripts/commands/system/version.sh
macos-safari-browser-use/scripts/commands/system/activate.sh
```

## Windows

```bash
macos-safari-browser-use/scripts/safari windows
macos-safari-browser-use/scripts/safari window-count
macos-safari-browser-use/scripts/safari new-window [url]
macos-safari-browser-use/scripts/safari focus-window <window-index>
macos-safari-browser-use/scripts/safari close-window [window-index]
```

Wrappers:

```bash
macos-safari-browser-use/scripts/commands/window/list.sh
macos-safari-browser-use/scripts/commands/window/count.sh
macos-safari-browser-use/scripts/commands/window/new.sh [url]
macos-safari-browser-use/scripts/commands/window/focus.sh <window-index>
macos-safari-browser-use/scripts/commands/window/close.sh [window-index]
```

Window object shape:

```json
{
  "index": 1,
  "name": "Example Page",
  "tabs_count": 3,
  "current_tab": 2,
  "visible": true,
  "miniaturized": false
}
```

## Tabs

```bash
macos-safari-browser-use/scripts/safari tabs [--window N]
macos-safari-browser-use/scripts/safari tab-count [--window N]
macos-safari-browser-use/scripts/safari current
macos-safari-browser-use/scripts/safari focus-tab <window-index> <tab-index>
macos-safari-browser-use/scripts/safari close-tab [--window N --tab N]
macos-safari-browser-use/scripts/safari reload [--window N --tab N]
macos-safari-browser-use/scripts/safari wait [seconds] [--window N --tab N]
```

Wrappers:

```bash
macos-safari-browser-use/scripts/commands/tab/list.sh [--window N]
macos-safari-browser-use/scripts/commands/tab/count.sh [--window N]
macos-safari-browser-use/scripts/commands/tab/current.sh
macos-safari-browser-use/scripts/commands/tab/focus.sh <window-index> <tab-index>
macos-safari-browser-use/scripts/commands/tab/close.sh [--window N --tab N]
macos-safari-browser-use/scripts/commands/tab/reload.sh [--window N --tab N]
macos-safari-browser-use/scripts/commands/tab/wait.sh [seconds] [--window N --tab N]
```

`wait` defaults to 15 seconds. You can omit the seconds value and pass only `--window`/`--tab` flags.

Tab object shape:

```json
{
  "window": 1,
  "index": 2,
  "current": true,
  "name": "Example Page",
  "url": "https://example.com/"
}
```

## URLs and navigation

```bash
macos-safari-browser-use/scripts/safari open <url> [current|new-tab|background-tab|new-window]
macos-safari-browser-use/scripts/safari new-tab [url]
macos-safari-browser-use/scripts/safari new-window [url]
```

Wrapper:

```bash
macos-safari-browser-use/scripts/commands/url/open.sh <url> [current|new-tab|background-tab|new-window]
```

Notes:

- Bare domains are normalized to `https://<domain>`.
- `about:`, `file:`, `http:`, `https:`, and custom URL schemes are preserved.
- The JSON result includes `window` and `tab` when the opened target can be identified. Use those indexes for follow-up reads instead of assuming the opened tab became the front tab.
- Opening a URL is a write action because it changes browser state.

## Page reads

```bash
macos-safari-browser-use/scripts/safari title [--window N --tab N]
macos-safari-browser-use/scripts/safari url [--window N --tab N]
macos-safari-browser-use/scripts/safari text [selector] [--window N --tab N]
macos-safari-browser-use/scripts/safari links [--window N --tab N]
macos-safari-browser-use/scripts/safari query <selector> [--window N --tab N]
macos-safari-browser-use/scripts/safari source [--window N --tab N]
```

Wrappers:

```bash
macos-safari-browser-use/scripts/commands/tab/title.sh
macos-safari-browser-use/scripts/commands/tab/url.sh
macos-safari-browser-use/scripts/commands/tab/text.sh [selector]
macos-safari-browser-use/scripts/commands/tab/links.sh
macos-safari-browser-use/scripts/commands/tab/query.sh <selector>
macos-safari-browser-use/scripts/commands/tab/source.sh
```

`text`, `links`, `query`, and `source` require Safari’s **Allow JavaScript from Apple Events** setting because they evaluate DOM JavaScript.

`links` returns:

```json
{
  "success": true,
  "links": [
    {"index": 1, "text": "Link text", "href": "https://example.com/target"}
  ],
  "window": 1,
  "tab": 1
}
```

## JavaScript

```bash
macos-safari-browser-use/scripts/safari js <code> [--window N --tab N]
macos-safari-browser-use/scripts/safari js-json <expression> [--window N --tab N]
```

Wrappers:

```bash
macos-safari-browser-use/scripts/commands/javascript/run.sh <code> [--window N --tab N]
macos-safari-browser-use/scripts/commands/javascript/run-json.sh <expression> [--window N --tab N]
```

Examples:

```bash
# Scalar result.
macos-safari-browser-use/scripts/safari js 'document.title'

# Structured result. Pass a JSON-serializable JavaScript expression, not JSON.stringify(...).
macos-safari-browser-use/scripts/safari js-json '({title: document.title, href: location.href})'
```

Use `js-json` when the agent needs structured page data. It wraps the expression in `JSON.stringify(...)` in Safari and returns the parsed JSON as the `result` value.

## DOM interaction

```bash
macos-safari-browser-use/scripts/safari click <selector> [--window N --tab N]
macos-safari-browser-use/scripts/safari type <selector> <text> [--window N --tab N]
```

Wrappers:

```bash
macos-safari-browser-use/scripts/commands/tab/click.sh <selector> [--window N --tab N]
macos-safari-browser-use/scripts/commands/tab/type.sh <selector> <text> [--window N --tab N]
```

These are write actions. Before using them, list or read the target tab and use precise selectors. Avoid typing secrets, payment details, or MFA codes.

## Screenshots

```bash
macos-safari-browser-use/scripts/safari screenshot [/absolute/path.png]
macos-safari-browser-use/scripts/commands/tab/screenshot.sh [/absolute/path.png]
```

The default output is `/tmp/safari-screenshot.png`. On modern macOS, screen capture may require Screen Recording permission for the terminal or agent host app.

## Reading List

```bash
macos-safari-browser-use/scripts/safari reading-list-add <url>
macos-safari-browser-use/scripts/commands/reading-list/add.sh <url>
```

Adding a Reading List item is a write action.

## WebDriver

```bash
macos-safari-browser-use/scripts/safari webdriver-check
macos-safari-browser-use/scripts/safari webdriver-enable

macos-safari-browser-use/scripts/commands/webdriver/check.sh
macos-safari-browser-use/scripts/commands/webdriver/enable.sh
```

`webdriver-enable` runs:

```bash
/usr/bin/safaridriver --enable
```

This can require administrator authentication and changes Safari’s Remote Automation setting. Use it only when the user explicitly asks to enable Safari WebDriver.

## Error shape

```json
{
  "success": false,
  "error": "no Safari windows open"
}
```
