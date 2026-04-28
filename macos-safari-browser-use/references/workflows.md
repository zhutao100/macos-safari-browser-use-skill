# Workflows

## 1. Summarize the active Safari page

```bash
macos-safari-browser-use/scripts/safari current
macos-safari-browser-use/scripts/safari wait 10
macos-safari-browser-use/scripts/safari title
macos-safari-browser-use/scripts/safari url
macos-safari-browser-use/scripts/safari text
```

Agent procedure:

1. Confirm the active tab metadata with `current`.
2. Use `text` for the page body.
3. Summarize only the text returned by the command unless the user asks you to navigate elsewhere.
4. Do not inspect history or cookies to infer context.

## 2. Open a research page and extract links

```bash
macos-safari-browser-use/scripts/safari open https://example.com new-tab
macos-safari-browser-use/scripts/safari wait 15
macos-safari-browser-use/scripts/safari links
```

Use this for user-directed browsing where Safari state matters, such as continuing from the user’s logged-in browser session. For general web research where live Safari state is not needed, prefer the agent’s normal web-research tool.

## 3. Fill a simple search form

```bash
macos-safari-browser-use/scripts/safari open https://example.com/search new-tab
macos-safari-browser-use/scripts/safari wait 15
macos-safari-browser-use/scripts/safari query 'input[name="q"]'
macos-safari-browser-use/scripts/safari type 'input[name="q"]' 'query text'
macos-safari-browser-use/scripts/safari click 'button[type="submit"]'
macos-safari-browser-use/scripts/safari wait 15
macos-safari-browser-use/scripts/safari text
```

Rules:

- Do not type passwords or MFA codes.
- If a form is ambiguous, ask the user to identify the field or provide a selector.
- After submitting, read the resulting URL/title before continuing.

## 4. Work with a specific tab

```bash
macos-safari-browser-use/scripts/safari tabs
macos-safari-browser-use/scripts/safari title --window 2 --tab 4
macos-safari-browser-use/scripts/safari text --window 2 --tab 4
macos-safari-browser-use/scripts/safari focus-tab 2 4
```

Use tab indices from the latest `tabs` output. Re-list tabs after opening, closing, or moving between windows because indices can change.

## 5. Capture a visual state

```bash
macos-safari-browser-use/scripts/safari focus-tab 1 2
macos-safari-browser-use/scripts/safari screenshot /tmp/safari-target.png
```

Use screenshots for visual confirmation only. Avoid collecting screenshots of sensitive pages unless the user explicitly asks and the screenshot is needed for the task.

## 6. Add a page to Reading List

```bash
macos-safari-browser-use/scripts/safari current
macos-safari-browser-use/scripts/safari reading-list-add https://example.com/article
```

Adding to Reading List changes user state. Confirm the exact URL before running this command.

## 7. Prepare Safari WebDriver for a project

```bash
macos-safari-browser-use/scripts/safari webdriver-check
macos-safari-browser-use/scripts/safari webdriver-enable
cp macos-safari-browser-use/assets/webdriver/safari_smoke_test.py ./safari_smoke_test.py
python3 ./safari_smoke_test.py
```

Prefer WebDriver when the desired output is a reproducible test or CI-compatible browser flow. Avoid mixing ad hoc AppleScript DOM mutation and WebDriver in the same test case.

## 8. After Safari or macOS upgrade

```bash
macos-safari-browser-use/scripts/check-setup.sh
macos-safari-browser-use/scripts/safari version
macos-safari-browser-use/scripts/safari open https://example.com new-tab
macos-safari-browser-use/scripts/safari wait 10
macos-safari-browser-use/scripts/safari text
macos-safari-browser-use/scripts/safari webdriver-check
make test-live
```

If `do JavaScript` fails after an upgrade, re-check the Develop-menu setting for JavaScript from Apple Events.
