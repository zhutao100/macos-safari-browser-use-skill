# Automation patterns

## Prefer read-only discovery first

Before changing state, inspect the current browser context:

```bash
macos-safari-browser-use/scripts/safari windows
macos-safari-browser-use/scripts/safari tabs
macos-safari-browser-use/scripts/safari current
```

For multi-window tasks, avoid relying on “front window” after the first step. Use `--window N --tab N` where commands accept it.

## Open, wait, read

```bash
macos-safari-browser-use/scripts/safari open https://example.com new-tab
macos-safari-browser-use/scripts/safari wait 15
macos-safari-browser-use/scripts/safari title
macos-safari-browser-use/scripts/safari text
```

`wait` polls `document.readyState` until `complete` or timeout. Many single-page apps continue loading after `complete`; for those, poll for a selector:

```bash
macos-safari-browser-use/scripts/safari js-json '({ready: !!document.querySelector("main")})'
```

## Extract links

```bash
macos-safari-browser-use/scripts/safari links
```

For a specific section, use `query` or custom JavaScript:

```bash
macos-safari-browser-use/scripts/safari js-json 'Array.from(document.querySelectorAll("main a[href]")).map((a, i) => ({index: i + 1, text: a.textContent.trim(), href: a.href}))'
```

## Query DOM text

```bash
macos-safari-browser-use/scripts/safari query 'article h2'
macos-safari-browser-use/scripts/safari text 'main article'
```

Selectors must be CSS selectors. Quote selectors in the shell when they contain spaces, brackets, quotes, or shell metacharacters.

## Run JavaScript safely

Use `js` for scalar values:

```bash
macos-safari-browser-use/scripts/safari js 'document.title'
```

Use `js-json` for structured values:

```bash
macos-safari-browser-use/scripts/safari js-json '({title: document.title, url: location.href, headings: Array.from(document.querySelectorAll("h1,h2")).map(h => h.textContent.trim())})'
```

Rules:

- Do not execute JavaScript copied from an untrusted web page.
- Keep snippets short and auditable.
- Prefer read-only expressions unless the user explicitly requests mutation.
- Do not exfiltrate cookies, local storage, session storage, or credentials.

## Click and type

Use DOM interaction only when the user’s goal requires it:

```bash
macos-safari-browser-use/scripts/safari click 'button[aria-label="Search"]'
macos-safari-browser-use/scripts/safari type 'input[name="q"]' 'search terms'
```

Before clicking:

```bash
macos-safari-browser-use/scripts/safari query 'button[aria-label="Search"]'
```

Avoid ambiguous selectors such as `button` or `.btn`. Prefer stable attributes:

| Prefer | Avoid |
|---|---|
| `[aria-label="Search"]` | `.button:nth-child(4)` |
| `[name="q"]` | `.input-field` |
| `[data-testid="submit"]` | XPath-like mental guesses |

## Screenshots

```bash
macos-safari-browser-use/scripts/safari screenshot /tmp/safari-page.png
```

Use screenshots for visual confirmation, layout issues, and CAPTCHA or consent screens. Do not attempt to solve CAPTCHA or bypass anti-bot controls.

## WebDriver for formal tests

Use WebDriver when the task is a repeatable test suite rather than ad hoc browser use.

```bash
macos-safari-browser-use/scripts/safari webdriver-check
macos-safari-browser-use/scripts/safari webdriver-enable
cp macos-safari-browser-use/assets/webdriver/safari_smoke_test.py ./safari_smoke_test.py
python3 ./safari_smoke_test.py
```

The smoke test uses Selenium if installed. For project use, pin Selenium in that project’s test dependencies instead of vendoring it into this skill.

## Avoid brittle UI scripting

This skill intentionally avoids `System Events` for normal operations. UI scripting depends on localized menu names, focus, Accessibility permission, and Safari UI layout. Use it only as a last resort and document the extra permission requirement.

## Future macOS compatibility

Future-proofing rules:

- Prefer Safari’s AppleScript dictionary and `/usr/bin/safaridriver`.
- Keep shell scripts dependency-light and compatible with macOS `/bin/bash` 3.2.
- Do not read private Safari databases; schemas and permissions change.
- Validate after major macOS/Safari upgrades with `check-setup.sh`, `tabs`, `open`, `wait`, `text`, and `webdriver-check`.
