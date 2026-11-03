# Changelog

**[Українська версія](./CHANGELOG.md)**

Format — [Keep a Changelog](https://keepachangelog.com/), versioning — [SemVer](https://semver.org/).

## [0.2.0] — 2026-11-03

Spec: [`docs/specs/mac-onboarding-0.2.en.md`](./docs/specs/mac-onboarding-0.2.en.md).

### Added

- `14_setup_git_identities.sh` + `.md` — several git identities on one
  Mac: `~/.gitconfig-<slug>` + `includeIf "gitdir:<folder>/"`, a separate
  SSH key and `Host github-<slug>` for each, SSH `ControlMaster`, a global
  gitignore. Dry run by default, `--apply`, backups, marker blocks, never
  overwrites existing settings.
- `15_setup_shell_and_macos.sh` + `.md` — zsh history, Android SDK env
  vars, docker compose aliases (`--with-docker-aliases`), Finder settings
  (extensions, hidden files, path in title, path bar) and the screenshot
  folder. Dry run by default, `--apply`.
- `06`: `--inventory` — read-only, compares the machine with the
  script's lists both ways.
- `06`: `--with-comms` — communication & remote-access apps group (Zoom,
  Telegram, WhatsApp, AnyDesk, TeamViewer, OBS).
- `06`: new formulae — `semgrep`, `trivy`, `osv-scanner`, `ffmpeg`,
  `pandoc`, `poppler`, `exiftool`, `rsync`, `pstree`, `jq`, `ripgrep`;
  new casks — `coteditor`, `stats`, `vlc`, `obsidian`.
- `06 --check`: outdated packages from the script's lists
  (`brew outdated`).
- `docs/specs/` — specs for improvements.
- `package.json`: npm scripts for `06 --inventory`, `14`, `15`.

### Changed

- `06`: `restic`, `borgbackup` moved from the main list to the optional
  ones (`OPTIONAL_FORMULAE`/`OPTIONAL_CASKS` — together with `ollama`,
  `yt-dlp`, `logrotate`, `gcloud-cli`, `wireguard`, `macfuse`,
  `sshfs-mac`); `docs/mount-tools.en.md` updated.
- `06`: an app already installed outside Homebrew (`.dmg`, App Store) is
  no longer treated as missing — it's skipped with a
  `brew install --cask --adopt` hint.
- `06`: a `corepack enable` failure now lands in the failure summary;
  global npm packages come from the `NPM_GLOBALS` list.
- `06`: `shellcheck` fully clean.

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
