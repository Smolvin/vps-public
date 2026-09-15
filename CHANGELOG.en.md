# Changelog

**[Українська версія](./CHANGELOG.md)**

Format — [Keep a Changelog](https://keepachangelog.com/), versioning — [SemVer](https://semver.org/).

## [0.2.0] — 2026-09-13

### Added

- `14_reduce_windows_bloat.ps1` + `.md`/`.en.md` — a new script: turns off
  Start menu ads/suggestions, OneDrive auto-start, Cortana/Bing results
  in search, Widgets, tailored experiences/advertising ID, lock-screen
  Spotlight (`-UserName`'s profile + the Default template), plus
  machine-wide telemetry (`AllowTelemetry`, the `DiagTrack` service,
  `dmwappushsvc`). Deliberately conservative — doesn't touch Windows
  Update, Defender, or pre-installed apps. Dry-run/`-Apply` plus
  `-Remove` for rollback, same conventions as `12`/`13`.
- `12_create_dev_user.ps1` — a `-Remove` flag (with `-Apply` to actually
  apply it, same as `-Apply` for creation): rollback, deletes the
  isolated account. Asks for confirmation every time (not just on the
  script's first run, unlike creation) — deletion is irreversible on
  every run. Doesn't delete the account's profile folder/files — that
  stays a manual step.
- `13_setup_dev_environment.ps1` — a `-Remove` flag: rollback,
  `winget uninstall` for whichever of `$Packages` is installed. Asks for
  confirmation every time. Doesn't touch git identity or the SSH key.

### Fixed

- `12_create_dev_user.ps1`, `14_reduce_windows_bloat.ps1` — `Add-Content`
  for the log file now writes with `-Encoding UTF8` explicitly (it
  defaulted to the system codepage with no BOM -- a real run showed
  Cyrillic/em-dash text in the logs then can't be read correctly by a
  tool that expects UTF-8).
- `12_create_dev_user.ps1`, `13_setup_dev_environment.ps1` — a real bug:
  the files had no UTF-8 BOM and used an em dash inside string literals,
  which broke Windows PowerShell 5.1 parsing on machines where the
  "language for non-Unicode programs" is set to Cyrillic (typical for a
  Ukrainian Windows locale), failing with `The string is missing the
  terminator: "`. Fixed by adding a UTF-8 BOM to both files — reproduced
  and verified with an actual run (not just parsing), not guessed.
- `13_setup_dev_environment.ps1` — the git identity/SSH key checks now
  first confirm `git`/`ssh-keygen` actually exist (`Get-Command`) instead
  of throwing `CommandNotFoundException` when the corresponding installer
  hasn't succeeded yet (typical on a freshly installed system before the
  first successful `winget install`).
- `12_create_dev_user.ps1` — another real bug, found from an actual user
  run: the `Administrators`/`Users` groups were looked up by their hard
  English name, but on a localized Windows (RU/UA) they're literally
  named "Администраторы"/"Пользователи" — `Add-LocalGroupMember : Группа
  Users не найдена`. Fixed by resolving the groups by their well-known
  SID (`S-1-5-32-544`/`S-1-5-32-545`) instead of by name — locale
  independent. Also: if the account already existed and `-Apply` was
  passed, the script used to just exit (`[skip]`) without checking group
  membership at all — now it still catches up on group membership, so
  re-running is safe after exactly this kind of partial failure.

### Changed

- `12_create_dev_user.ps1` — the "not running as administrator" message
  now prints step-by-step instructions (how to open PowerShell as
  administrator) instead of a single line.
- `13_setup_dev_environment.ps1` — added a check: if the script is
  running as administrator, it prints a warning and (outside `-Check`)
  asks for confirmation, since that contradicts the intended run as the
  target user. The "winget not found" message now includes concrete fix
  steps (Microsoft Store, or a direct download from the official
  winget-cli releases page).
- `scripts/12_create_dev_user.md`/`.en.md`,
  `scripts/13_setup_dev_environment.md`/`.en.md` — a "Troubleshooting"
  section (execution policy, administrator rights, missing `winget`, the
  two-session order).
- `README.md`/`README.en.md` — a "Quickstart on a clean Windows machine"
  section: an explicit step-by-step order for 12 -> re-login -> 13,
  explaining why it's two sessions and not one command.

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
