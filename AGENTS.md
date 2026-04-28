# Repo Guide

This repo stores a skill for macOS Safari.app browser use.

## Goal

- Keep Safari automation useful to agents without relying on fragile UI-coordinate scripting.
- Prefer AppleScript/JXA dictionary access and Safari WebDriver over Accessibility scripting.
- Keep public commands JSON-producing and safe to call from agent workflows.
- Preserve progressive disclosure: the skill entrypoint stays concise; conditional detail lives in `references/`.

## Repo layout

- `README.md`: public overview and installation notes.
- `AGENTS.md`: this guide for future agentic development sessions.
- `Makefile`: validation entrypoints.
- `macos-safari-browser-use/SKILL.md`: skill contract and quick-start instructions.
- `macos-safari-browser-use/scripts/safari`: public consolidated CLI.
- `macos-safari-browser-use/scripts/check-setup.sh`: setup and permission diagnostic.
- `macos-safari-browser-use/scripts/lib/safari-control.applescript`: internal AppleScript backend.
- `macos-safari-browser-use/scripts/commands/**`: public command wrappers.
- `macos-safari-browser-use/references/`: conditional docs for commands, setup, patterns, workflows, research.
- `macos-safari-browser-use/assets/`: templates and ready-to-copy examples.
- `tests/`: shell validation and optional live Safari smoke checks.

## Public rule

Use only:

- `macos-safari-browser-use/scripts/check-setup.sh`
- `macos-safari-browser-use/scripts/safari`
- `macos-safari-browser-use/scripts/commands/**`

Do not expose or directly depend on `scripts/lib/**` from user-facing docs except as implementation detail.

## Safety rules

- Never read or export Safari History, cookies, saved passwords, Keychain data, or profile storage internals.
- Never run JavaScript copied from an untrusted web page. JavaScript execution is a user/agent-supplied code path only.
- Treat form-fill, click, close-tab, and WebDriver enabling as write actions; require explicit user intent.
- Do not automate login, MFA, payment, password, or sensitive-account workflows unless the user is actively supervising and explicitly requests each step.
- Use `safaridriver` for test automation when the task is a formal web test; use AppleScript command wrappers for lightweight browser use.

## Validation

After edits:

```bash
make check
make test
```

On a configured Mac or GhostVM test guest, also run:

```bash
macos-safari-browser-use/scripts/check-setup.sh
macos-safari-browser-use/scripts/safari tabs
macos-safari-browser-use/scripts/safari open https://example.com new-tab
macos-safari-browser-use/scripts/safari wait 10
macos-safari-browser-use/scripts/safari text
make test-live
```

`make test-live` is intentionally opt-in and state-changing: it opens a temporary Safari window, runs DOM read/write commands, takes a screenshot, and closes the window.
Set `SAFARI_LIVE_FIXTURE_HTML=/absolute/path/to/sample.html` to include an offline HTML fixture without dumping its contents.

## Editing rules

- Keep `SKILL.md` concise. Add detail to `references/`.
- Keep scripts compatible with macOS `/bin/bash` 3.2 where shell is used.
- Avoid external dependencies such as `jq`; the command backend emits JSON directly.
- Keep the single root `.pre-commit-config.yaml` unless the repo gains real subprojects; current Python/JavaScript files are small validation/assets, not separate workspaces.
- Pre-commit is run through `prek` with `.githooks/pre-commit`; keep `core.hooksPath=.githooks` and run `prek run --all-files` after changing hook config.
- If adding commands, add wrappers under `scripts/commands/**`, update `references/command-reference.md`, and update `tests/contract_files.sh`.
- Do not claim support for Safari profile manipulation unless it is verified on current macOS through a stable, documented API.

## Known gotchas

- `do JavaScript` requires Safari’s **Allow JavaScript from Apple Events** setting.
- `System Events`/Accessibility is intentionally avoided by default. Adding UI scripting raises an additional permission burden and can break across UI redesigns.
- `safaridriver --enable` changes Safari’s remote automation setting and may prompt for an administrator password.
- Safari can host only one active WebDriver session at a time.
