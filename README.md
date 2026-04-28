# macOS Safari Browser Use Skill

A Codex CLI / Open Agent Skills compatible skill repository for using **Safari.app on macOS** through agent-safe shell commands backed by AppleScript.

The repository follows the standards shape:

```text
README.md
AGENTS.md
macos-safari-browser-use/
├── SKILL.md
├── scripts/
├── references/
└── assets/
```

## Scope

Use this skill to let an agent operate Safari on macOS 15 Sequoia, macOS Tahoe 26, and future releases using stable automation surfaces:

- list Safari windows and tabs;
- open URLs in the current tab, a new tab, or a new window;
- focus, close, reload, and wait for tabs;
- read title, URL, source, visible text, links, and selected DOM text;
- run explicitly supplied JavaScript in a tab;
- click/type into DOM elements when a user has explicitly requested interaction;
- add URLs to Reading List;
- check and enable Safari WebDriver support for formal browser tests.

The skill intentionally avoids direct reads of Safari History, cookies, Keychain data, and profiles database internals.

## Install

Copy the repository, then install the skill directory into the agent tool that supports skills. For Codex CLI, place the `macos-safari-browser-use/` directory wherever your Codex skills are stored, or keep the full repo and reference the skill path from your local configuration.

```bash
# Verify the local Safari automation setup.
macos-safari-browser-use/scripts/check-setup.sh

# Use the one-command CLI.
macos-safari-browser-use/scripts/safari tabs
macos-safari-browser-use/scripts/safari open https://example.com new-tab
macos-safari-browser-use/scripts/safari text

# Or call command wrappers directly.
macos-safari-browser-use/scripts/commands/tab/list.sh
macos-safari-browser-use/scripts/commands/url/open.sh https://example.com new-window
```

## Public interface

- `macos-safari-browser-use/scripts/check-setup.sh`
- `macos-safari-browser-use/scripts/safari`
- `macos-safari-browser-use/scripts/commands/**`

All public commands return JSON unless a command is invoked with `help`.

## Prerequisites

- macOS with Safari.app installed.
- `/usr/bin/osascript` available.
- Automation permission for the terminal or agent host application to control Safari.
- Safari Develop setting **Allow JavaScript from Apple Events** enabled for DOM-reading and DOM-interaction commands.
- Optional: `/usr/bin/safaridriver` for WebDriver tests.

See `macos-safari-browser-use/references/permissions-and-setup.md` for the exact setup and troubleshooting steps.

## Development

```bash
make check
make test
```

`make test` runs pure shell contract checks everywhere and skips live Safari checks on non-macOS hosts.
