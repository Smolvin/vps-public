# vps-infra-public

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](./LICENSE)
[![Buy Me A Coffee](https://img.shields.io/badge/-Buy_Me_A_Coffee-FFDD00?style=flat&logo=buy-me-a-coffee&logoColor=black)](https://buymeacoffee.com/smolvin)

**[Українська версія](./README.md)**

Public part of a dev environment: idempotent onboarding scripts for a
clean machine (macOS and Windows) — an isolated non-admin profile + a
basic set of dev tools. Nothing specific to any particular server/project
— general, reusable tooling.

## Scripts

| # | Platform | Script | What it does |
|---|---|---|---|
| 06 | macOS | [`06_setup_new_dev_mac.sh`](./scripts/06_setup_new_dev_mac.en.md) | Homebrew, VS Code, Node.js, git/GitHub, mobile stack |
| 09 | macOS | [`09_create_profiles.sh`](./scripts/09_create_profiles.en.md) | Isolated non-admin profiles (`personal`/`work`/`dev`/`sandbox`) |
| 12 | Windows | [`12_create_dev_user.ps1`](./scripts/12_create_dev_user.en.md) | Isolated non-admin `dev` profile |
| 13 | Windows | [`13_setup_dev_environment.ps1`](./scripts/13_setup_dev_environment.en.md) | winget-based dev toolset + git identity + SSH key |
| 14 | Windows | [`14_reduce_windows_bloat.ps1`](./scripts/14_reduce_windows_bloat.en.md) | Turn off Windows ads/suggestions/telemetry (conservative) |

Typical order on a new machine: isolated profile first (`09`/`12`), then
— logged into it — the tooling (`06`/`13`).

## Quickstart on a clean Windows machine

This is **two separate Windows sessions, not one command** — a deliberate
architectural choice (isolation), not an oversight: `12` creates a
separate `dev` account and must run as administrator; `13` installs
tools into that account and must run as that account itself — otherwise
git identity/SSH key/winget packages land in the administrator's profile
instead of where you'll actually develop.

1. Open PowerShell **as administrator** (Win -> `PowerShell` ->
   right-click -> "Run as administrator").
2. If you get `cannot be loaded because running scripts is disabled on
   this system` — allow local scripts to run, once:
   ```powershell
   Set-ExecutionPolicy -Scope CurrentUser -ExecutionPolicy RemoteSigned
   ```
3. Create the isolated `dev` account (dry-run first to see what it would
   do, then for real):
   ```powershell
   cd path\to\repo\scripts
   .\12_create_dev_user.ps1
   .\12_create_dev_user.ps1 -Apply
   ```
4. Sign out of the current account (not just lock the screen) and log
   into the newly created `dev`.
5. In the new session, **no longer as administrator**, install the dev
   tools:
   ```powershell
   cd path\to\repo\scripts
   .\13_setup_dev_environment.ps1 -Check     # what's there / missing
   .\13_setup_dev_environment.ps1             # install what's missing
   ```

If something along the way fails, both scripts print concrete fix steps
straight to the console on error; the full list of common issues
(execution policy, missing `winget`, administrator rights) is in
[`scripts/12_create_dev_user.en.md`](./scripts/12_create_dev_user.en.md)
and
[`scripts/13_setup_dev_environment.en.md`](./scripts/13_setup_dev_environment.en.md),
"Troubleshooting" section.

## References

- [`docs/mount-tools.en.md`](./docs/mount-tools.en.md) — sshfs,
  `restic mount`, `borg mount`, macFUSE (macOS) / WinFsp (Windows): why
  they're needed and how to set them up manually.

## Conventions

See [`CLAUDE.md`](./CLAUDE.md) — repository canon (script numbering,
public-data sanitization, dry-run/`--apply`, commits),
[`SCRIPTS_CHECKLIST.md`](./SCRIPTS_CHECKLIST.md) — actual run tracking
per script, [`ROADMAP.md`](./ROADMAP.md) — tasks/ideas not done yet.

## Requirements

- **macOS scripts**: Intel or Apple Silicon, administrator rights for
  part of the steps.
- **Windows scripts**: Windows 10 (1809+) or 11, PowerShell,
  administrator rights for `12_create_dev_user.ps1` (account creation);
  `13_setup_dev_environment.ps1` — regular user.

## Contributing

Want to add a script, a platform, or fix a bug — see
[`CONTRIBUTING.md`](./CONTRIBUTING.md) (how numbering works, what's
expected from a PR) and [`CLAUDE.md`](./CLAUDE.md) (repository canon in
more detail).

## License

[MIT](./LICENSE) — use, fork, modify, embed anywhere, including closed
projects. The only condition — keep the copyright notice and the license
text when redistributing.

## Author

`Alex Smolvin` — `https://github.com/Smolvin`

## Support the project

- [buymeacoffee.com/smolvin](https://buymeacoffee.com/smolvin)
- [send.monobank.ua/jar/6jiZRYv6CA](https://send.monobank.ua/jar/6jiZRYv6CA)
