# Spec: Mac onboarding additions (v0.2.0)

**[Українська версія](./mac-onboarding-0.2.md)**

- **Status:** agreed, ready for implementation
- **Added:** 2026-11-03
- **Source:** comparing the lists in `scripts/06_setup_new_dev_mac.sh` with
  what was actually needed on a working Mac over ~2 months of active use.
- **Target version:** `0.2.0` (`package.json`, `CHANGELOG.md`)

## Goal

1. Bring the `06` lists in line with real usage.
2. Add what onboarding doesn't cover at all: git identities and ssh setup
   (new script `14`) and shell + macOS settings (new script `15`).
3. Make the next such review automatic (`06 --inventory`).

Out of scope: Windows scripts `12`/`13`, script `09`.

---

## A. Script 06 — in-place improvements

The convention doesn't change: idempotent installer, `--check` — status
only, plain run — installs what's missing.

### A.1. Fixes to the existing lists

- `python@3.14` — stays.
- `restic`, `borgbackup` — moved from the main list to the optional
  (commented-out) block next to `macfuse`/`sshfs-mac`; `docs/mount-tools.md`
  updated accordingly ("install if needed").
- `claude`, `shottr` (casks) — verify the cask tokens are current
  (`brew info --cask`); fix if not.

### A.2. New formulae (main list)

- Security (next to `gitleaks`): `semgrep`, `trivy`, `osv-scanner`.
- Media and documents: `ffmpeg`, `pandoc`, `poppler`, `exiftool`
  (strip EXIF/GPS from images before committing).
- Utilities: `rsync` (modern, instead of the system one), `pstree`, `jq`,
  `ripgrep`.

### A.3. New formulae (optional, commented out)

`ollama` (local LLMs), `yt-dlp`, `logrotate`, `gcloud-cli` (cask).

### A.4. Node

After `nvm install --lts` — `corepack enable` (pnpm/yarn without global
installs). A failure goes into the `FAILED` list, the script continues.

### A.5. New casks

- Main list: `coteditor`, `stats`, `vlc`, `obsidian`.
- "Communication and remote access" group — off by default, enabled with
  the `--with-comms` flag: `zoom`, `telegram`, `whatsapp`, `anydesk`,
  `teamviewer`, `obs`. `--check --with-comms` reports them too.

### A.6. `--inventory` (read-only)

Prints two sections:

1. **On the machine, not in the script:** `brew leaves`,
   `brew list --cask`, `npm ls -g --depth=0` minus the 06 main + optional
   lists.
2. **In the script, not on the machine.**

Installs nothing, writes no logs. Output is package names only (no paths),
so it's safe to paste into an issue.

### A.7. `--check` + outdated packages

At the end of `--check` — `brew outdated` for the packages in the script's
lists (report only).

---

## B. New script 14 — git identities and ssh

`scripts/14_setup_git_identities.sh` + `.md` + `.en.md`.

**Convention:** no arguments — dry run (prints what it would do and the
ready-to-copy `--apply` command); `--apply` — real changes. Writes a log to
`scripts/logs/` → the "first run" rule applies (`[y/N]`).

### B.1. What it does

For each identity (entered interactively, several per run allowed):

- a short name (`slug`, latin letters/digits/hyphen), git `user.name`,
  `user.email`, the folder holding that identity's repositories;
- `~/.gitconfig-<slug>` with `user.name`/`user.email`;
- in `~/.gitconfig` — `[includeIf "gitdir:<folder>/"] path = ~/.gitconfig-<slug>`;
- ssh key `~/.ssh/id_ed25519_<slug>` if missing (`ssh-keygen`
  interactively; passphrase only there, never as an argument);
- a block in `~/.ssh/config`:
  `Host github-<slug>` → `HostName github.com`, `User git`,
  `IdentityFile`, `IdentitiesOnly yes`, `UseKeychain yes`,
  `AddKeysToAgent yes`;
- at the end — prints the public key, a `gh ssh-key add` hint and an
  example remote: `git@github-<slug>:<org>/<repo>.git`.

Additionally, once per machine:

- `Host *` with `ControlMaster auto`, `ControlPath ~/.ssh/cm-%C`,
  `ControlPersist 10m` — only if `~/.ssh/config` has no `ControlMaster` of
  its own;
- global gitignore: `core.excludesfile = ~/.gitignore_global` with
  `.DS_Store`, `.idea/`, `.vscode/`, `*.swp`. If `core.excludesfile` is
  already set — appends missing lines to the existing file, doesn't
  override it.

### B.2. Change safety

- Before the first change — back up `~/.gitconfig` and `~/.ssh/config`
  alongside (`.bak-YYYY-MM-DD-HHMMSS`).
- Every insertion is a marker-delimited block
  `# >>> vps-infra-public 14 <slug> >>>` / `# <<< … <<<`: a re-run updates
  the block instead of duplicating it.
- Existing keys, `~/.gitconfig-<slug>` files and foreign blocks are never
  overwritten; a conflict → warning + entry in the failure list.
- `chmod 600` on `~/.ssh/config`, `700` on `~/.ssh`.

---

## C. New script 15 — shell and macOS settings

`scripts/15_setup_shell_and_macos.sh` + `.md` + `.en.md`.

**Convention:** same as 14 — dry run / `--apply`, log in `scripts/logs/`,
"first run".

### C.1. zsh (`~/.zshrc`, marker-delimited block)

- History: `APPEND_HISTORY`, `INC_APPEND_HISTORY`, `SHARE_HISTORY`,
  `HIST_IGNORE_DUPS`, `HIST_IGNORE_SPACE`.
- Android SDK: `ANDROID_HOME=$HOME/Library/Android/sdk` + `emulator`,
  `platform-tools`, `cmdline-tools/latest/bin` on `PATH` — only if the SDK
  folder exists (or with the `--android` flag).
- Optional (`--with-docker-aliases`): `dcu`/`dcd`/`dcl`/`dps` for
  `docker compose`.
- Back up `~/.zshrc` before changing it.

### C.2. macOS `defaults`

- Finder: show all file extensions.
- Finder: show hidden files.
- Finder: full path in the window title + path bar.
- Screenshots: folder asked interactively (default
  `~/Pictures/Screenshots`), created if missing.

The dry run shows current value → new value. After `--apply` —
`killall Finder` / `killall SystemUIServer` only if something changed.

---

## D. Definition of done

- `bash -n` and `shellcheck` clean (exception — a documented info-level
  warning, as in 06).
- Dry runs of 14/15 change no files (checksums of `~/.gitconfig`,
  `~/.ssh/config`, `~/.zshrc` before/after).
- A repeated `--apply` changes nothing (idempotency).
- `06 --check` and `06 --inventory` install nothing.
- No real account names, emails, hosts or absolute paths in code, docs or
  examples (sanitization per `CLAUDE.md`).
- Docs: `NN_name.md` + `NN_name.en.md` for 14 and 15; updated
  `06_setup_new_dev_mac.md`/`.en.md`, `docs/mount-tools.md`/`.en.md`.
- New 14/15 rows in `SCRIPTS_CHECKLIST.md`/`.en.md`; table in
  `README.md`/`README.en.md`; `CHANGELOG.md`/`.en.md` → `0.2.0`;
  `package.json` → `0.2.0` + npm scripts for 14/15.

## E. Work order and estimate

1. A (06: lists, `--with-comms`, `corepack`, `--inventory`, outdated) · ~2.5 h
2. B (14: git identities + ssh + global gitignore) · ~2.5 h
3. C (15: zsh + Android + defaults) · ~1.5 h
4. D (uk/en docs, checklist, README, CHANGELOG, checks) · ~1 h

## F. Decisions made during review (2026-11-03)

- Scope: all groups — A.1–A.7, B, C.
- Environment setup — two separate scripts: 14 (git/ssh), 15 (shell/macOS).
- `restic`/`borgbackup` — moved to optional.
- Python — `python@3.14`.
- "Communication" group — optional, via the `--with-comms` flag.
- `defaults` — all four C.2 items.

**Taken as defaults (can be changed before implementation starts):**
global gitignore and `ControlMaster` — in 14; Android and docker aliases —
in 15; docker aliases off by default.
