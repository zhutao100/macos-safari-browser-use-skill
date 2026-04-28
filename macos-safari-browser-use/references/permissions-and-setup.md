# Permissions and setup

Safari automation on modern macOS is controlled by several privacy gates. Run the setup check first:

```bash
macos-safari-browser-use/scripts/check-setup.sh
```

## Automation permission

Symptoms:

- `not authorized to send Apple events to Safari`
- `osascript` returns an Apple Events/TCC error

Fix:

1. Open **System Settings**.
2. Go to **Privacy & Security** → **Automation**.
3. Find the terminal or agent host application.
4. Enable access to **Safari**.

Reset when the Automation pane is stuck:

```bash
/usr/bin/tccutil reset AppleEvents com.apple.Terminal
/usr/bin/tccutil reset AppleEvents com.googlecode.iterm2
```

Then rerun `check-setup.sh` to trigger the prompt again.

## JavaScript from Apple Events

Commands that read or interact with the DOM require Safari to permit JavaScript via Apple Events:

- `text`
- `links`
- `query`
- `source`
- `js`
- `js-json`
- `click`
- `type`
- `wait` and `reload` when implemented through page JavaScript

Setup on current Safari:

1. Open Safari.
2. Go to **Safari** → **Settings** → **Advanced**.
3. Enable **Show features for web developers** if the Develop menu is not visible.
4. Open **Develop** in the menu bar.
5. Enable **Allow JavaScript from Apple Events**.

On some releases, Safari may ask for authentication when enabling this setting.

## Screen capture permission

`screenshot` uses `/usr/sbin/screencapture`. If macOS blocks the capture:

1. Open **System Settings** → **Privacy & Security** → **Screen & System Audio Recording** or **Screen Recording**.
2. Enable the terminal or agent host application.
3. Restart the terminal/agent host if macOS requests it.

## WebDriver setup

For formal browser tests, use Safari’s built-in WebDriver server:

```bash
macos-safari-browser-use/scripts/safari webdriver-check
macos-safari-browser-use/scripts/safari webdriver-enable
```

`webdriver-enable` executes:

```bash
/usr/bin/safaridriver --enable
```

Important details:

- This may require administrator authentication.
- It enables Safari Remote Automation for later WebDriver sessions.
- Safari’s WebDriver server accepts localhost connections.
- Safari can host only one active WebDriver session at a time.

Use the ready-to-copy smoke test in:

```text
macos-safari-browser-use/assets/webdriver/safari_smoke_test.py
```

## Profiles

Safari profiles are useful for separating work, personal, and test browsing. Safari 17+ profiles keep separate history, cookies, website data, extensions, Tab Groups, and favorites. The skill does not manipulate profile internals because there is no stable public scripting interface for complete profile management.

Recommended practice:

- Create and maintain profiles manually in Safari settings, or through organization-managed configuration profiles where applicable.
- Ask the user to open the desired profile window before agent browser use.
- Use `windows`, `tabs`, and `current` to verify the active context by URL/title before acting.

## Enterprise and managed Macs

Managed Macs may restrict Safari settings, private browsing, content summarization, bookmarks, extensions, and WebDriver/Developer settings. If commands fail on a managed Mac, inspect MDM restrictions before debugging scripts.

## Troubleshooting table

| Symptom | Likely cause | Action |
|---|---|---|
| `not authorized to send Apple events` | Automation permission missing | Enable Safari under Privacy & Security → Automation. |
| `do JavaScript` fails | JavaScript from Apple Events disabled | Enable the Develop-menu setting. |
| `no Safari windows open` | Read command needs a target tab | Run `open <url> new-tab` or open Safari manually. |
| Screenshot is blank or denied | Screen Recording permission missing | Grant Screen Recording to the terminal/agent app. |
| WebDriver session cannot start | Remote Automation disabled | Run `webdriver-enable`; confirm Develop → Allow Remote Automation. |
| Commands affect wrong page | Front tab changed | Use `tabs`, then pass `--window N --tab N`. |
