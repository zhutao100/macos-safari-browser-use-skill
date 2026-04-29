# Research and validation summary

Research date: 2026-04-28.

## Standards used

Primary skill standards:

- Codex skills documentation: https://developers.openai.com/codex/skills
- Open Agent Skills specification: https://agentskills.io/specification

Applied requirements:

- Keep a skill directory with required `SKILL.md` metadata.
- Include `name` and `description` front matter.
- Keep the initial skill instructions concise and move conditional detail to `references/`.
- Put executable code in `scripts/` and reusable templates/examples in `assets/`.
- Include root `README.md` and `AGENTS.md` for repository-level use and future agentic development.

## Safari and macOS research used

Primary Apple/WebKit references:

- Safari User Guide, Develop menu: https://support.apple.com/guide/safari/use-the-developer-tools-in-the-develop-menu-sfri20948/mac
- Safari User Guide, Privacy settings: https://support.apple.com/guide/safari/sfri35610/mac
- Safari User Guide, Private Browsing: https://support.apple.com/guide/safari/browse-privately-ibrw1069/mac
- Apple Support, Safari profiles: https://support.apple.com/en-us/105100
- Apple Support, keyboard shortcuts and gestures: https://support.apple.com/guide/safari/keyboard-shortcuts-and-gestures-cpsh003/mac
- Apple Developer, Safari WebDriver docs: https://developer.apple.com/documentation/safari-developer-tools/webdriver
- Apple Developer, Enable WebDriver on macOS: https://developer.apple.com/documentation/safari-developer-tools/macos-enabling-webdriver
- `safaridriver(1)` manual summary: https://manp.gs/mac/1/safaridriver
- WebKit blog, Safari 26.0 features: https://webkit.org/blog/17333/webkit-features-in-safari-26-0/
- WebKit blog, Safari 26.4 features: https://webkit.org/blog/17862/webkit-features-for-safari-26-4/
- Apple Support, macOS Tahoe 26 enterprise notes: https://support.apple.com/en-us/124963
- Apple Support, update Safari through OS updates: https://support.apple.com/en-us/102665

Operational conclusions:

1. Safari is delivered through Apple OS updates, so compatibility must be framed by macOS/Safari release families rather than a standalone browser installer.
2. Modern Safari supports profiles for separation; however, direct profile management through scripting is not a stable public automation surface, so the skill documents manual/managed-profile usage instead of manipulating profile databases.
3. DOM extraction and DOM interaction through Safari AppleScript require the Safari setting **Allow JavaScript from Apple Events**.
4. WebDriver is the correct automation surface for formal repeatable tests; `/usr/bin/safaridriver --enable` is the setup command and can require user/admin authentication.
5. Safari WebDriver is localhost-scoped and Safari can host only one active WebDriver session at a time.
6. UI scripting through `System Events` is avoided because it adds Accessibility permission, localization issues, and fragility across Safari UI redesigns.
7. macOS Tahoe 26 introduced enterprise configurations that may affect Safari browsing experience and private browsing, so managed Macs can fail due to policy rather than script defects.

## Design decisions in this generated repo

| Decision | Reason |
|---|---|
| One consolidated `scripts/safari` plus wrappers | Agents can use one memorable CLI or stable command paths. |
| AppleScript backend | Native, dependency-light, and compatible with Safari’s app dictionary. |
| JSON-only public command output | Easier for agents to parse and chain. |
| No `jq` dependency | Keeps install friction low on clean macOS systems. |
| No History/cookie/password commands | Protects user privacy and avoids private database/schema churn. |
| WebDriver commands included but not auto-enabled | Remote automation is a user-visible setup change. |
| Profiles documented but not scripted | Stable public APIs are insufficient for robust profile manipulation. |
| UI scripting avoided | Reduces permissions and future UI-breakage risk. |
| `make check` includes AppleScript compilation | Catches Safari backend syntax errors before live browser checks. |
| Hosted CI skips read-only Safari smoke checks by default | GitHub-hosted macOS runners can launch Safari into first-run, restore, or permission states that make Apple Events slow or unavailable; set `SAFARI_SMOKE_LIVE=1` only on a prepared runner. |
| `make test-live` is opt-in | It opens a Safari window, mutates a local fixture DOM, captures a screenshot, and is best run in a disposable VM or supervised local session. |
