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
| 14 | macOS | [`14_setup_git_identities.sh`](./scripts/14_setup_git_identities.en.md) | Several git identities (`includeIf`) + a separate SSH key and `Host github-<slug>` for each, global gitignore |
| 15 | macOS | [`15_setup_shell_and_macos.sh`](./scripts/15_setup_shell_and_macos.en.md) | zsh history, Android SDK env vars, Finder settings and screenshot folder |

Typical order on a new machine: isolated profile first (`09`/`12`), then
— logged into it — the tooling (`06`/`13`), then on a Mac — the settings
(`14`, `15`).

## References

- [`docs/mount-tools.en.md`](./docs/mount-tools.en.md) — sshfs,
  `restic mount`, `borg mount`, macFUSE (macOS) / WinFsp (Windows): why
  they're needed and how to set them up manually.
- [`docs/specs/`](./docs/specs/) — specs for planned improvements (currently
  [`mac-onboarding-0.2.en.md`](./docs/specs/mac-onboarding-0.2.en.md)).

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
