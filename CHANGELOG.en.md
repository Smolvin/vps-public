# Changelog

**[Українська версія](./CHANGELOG.md)**

Format — [Keep a Changelog](https://keepachangelog.com/), versioning — [SemVer](https://semver.org/).

## [0.1.0] — 2026-09-10

### Added

- `06_setup_new_dev_mac.sh` + `.md` — dev-tools onboarding on macOS
  (Homebrew, Node.js, VS Code, Git/GitHub, mobile stack). Idempotent,
  `--check` — status only.
- `09_create_profiles.sh` + `.md` — isolated non-admin macOS profiles
  (`personal`/`work`/`dev`/`sandbox`). Dry-run by default, `--apply` —
  actual creation.
- `12_create_dev_user.ps1` + `.md` — Windows analog: isolated non-admin
  `dev` profile. Dry-run by default, `-Apply` — actual creation.
- `13_setup_dev_environment.ps1` + `.md` — Windows analog: dev toolset via
  `winget` + git identity + SSH key. Idempotent, `-Check` — status only.
- `README.md`, `CLAUDE.md`, `SCRIPTS_CHECKLIST.md` — repository
  conventions (sequential numbering, dry-run/`--apply`, "first run",
  public-data sanitization).
- `LICENSE` (MIT) + `"license": "MIT"` in `package.json`.
- `CONTRIBUTING.md` — PR process, requirements for new scripts, minimum
  testing before a PR.
- `06_setup_new_dev_mac.sh`: `restic`/`borgbackup` in the main formula
  list; optional (commented out) `gromgit/fuse/sshfs-mac` next to the
  already-present `macfuse`.
- `docs/mount-tools.md` — reference for sshfs/`restic mount`/`borg mount`/
  macFUSE (macOS) and WinFsp/SSHFS-Win (Windows): why they're needed,
  exact install commands, how to manually approve the system extension on
  macOS (including the Apple Silicon difference between the FSKit and
  legacy kext backend).
- `ROADMAP.md` — task/idea workflow for this repository.
- Donation links ([buymeacoffee.com/smolvin](https://buymeacoffee.com/smolvin),
  [send.monobank.ua/jar/6jiZRYv6CA](https://send.monobank.ua/jar/6jiZRYv6CA))
  in `README.md`.
- Bilingual docs: Ukrainian version of every file by default + English
  (`.en.md`), Russian removed from the repository entirely.
