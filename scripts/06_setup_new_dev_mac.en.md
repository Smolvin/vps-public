# 06_setup_new_dev_mac.sh

**[Українська версія](./06_setup_new_dev_mac.md)**

Onboarding script for a clean macOS: installs a working set of dev tools
(Homebrew, Node.js, VS Code, Docker, mobile stack, Git/GitHub).

The base software list is taken from a real working dev machine —
generic enough for setting up an isolated `dev` profile (see
`09_create_profiles.sh`) as well as a separate new hire's machine.

See `SCRIPTS_CHECKLIST.md` #6.

## Running it

```bash
cd scripts
chmod +x 06_setup_new_dev_mac.sh
```

| Command | What it does |
|---|---|
| `./06_setup_new_dev_mac.sh` | Full install of the whole set (see below). Safe to re-run. |
| `./06_setup_new_dev_mac.sh --with-comms` | Same + communication & remote-access apps (Zoom, Telegram, WhatsApp, AnyDesk, TeamViewer, OBS). |
| `./06_setup_new_dev_mac.sh --check` | Installs nothing — shows what's already there, what's missing, and which packages from the lists are outdated (`brew outdated`). With `--with-comms` it checks the communication group too. |
| `./06_setup_new_dev_mac.sh --inventory` | Read-only: what's on the machine but missing from the script, and vice versa. |
| `./06_setup_new_dev_mac.sh --rclone-only` | Installs just rclone (and Homebrew, if missing). |
| `./06_setup_new_dev_mac.sh --help` | Short flag reference. |

`--check`, `--inventory` and `--rclone-only` are mutually exclusive;
`--with-comms` combines with a normal run and with `--check`.

## How it works

The script is idempotent: before installing each component it checks
whether it's already there, and skips it if so. It can be run any number
of times — it either does nothing (everything's already installed) or
finishes installing what's missing.

If an app from the casks list is already in `/Applications` but not via
Homebrew (installed from a `.dmg` or the App Store), the script leaves it
alone and suggests `brew install --cask --adopt <name>` to hand it over
to Homebrew.

If one specific package fails to install (network error, conflict, etc.),
the script **does not crash entirely** — it prints a warning, defers that
item into a list, and moves on. At the end it prints a summary of what
didn't install, so you can investigate and re-run the script.

Order of steps on a normal run:

1. **Xcode Command Line Tools** — check/install (needed by Homebrew, git,
   CocoaPods, compilers).
2. **Homebrew** — installs it if missing, plus `brew update`.
3. **Homebrew formulae**:
   - basics: `git`, `gh`, `nvm`, `python@3.14`, `php`, `mkcert`,
     `shellcheck`, `imagemagick`, `rclone`;
   - mobile stack: `cocoapods`, `openjdk@17`, `watchman`;
   - security: `gitleaks`, `semgrep`, `trivy`, `osv-scanner`;
   - media and documents: `ffmpeg`, `pandoc`, `poppler`, `exiftool`
     (strip EXIF/GPS from images before committing);
   - utilities: `rsync` (modern, instead of the system one), `pstree`,
     `jq`, `ripgrep`.
4. **Homebrew casks (apps)**: VS Code, iTerm2, Docker Desktop, Chrome,
   Firefox Developer Edition, Android Studio, Figma, Postman, Claude,
   Shottr, CotEditor, Stats, VLC, Obsidian. With `--with-comms` — also
   Zoom, Telegram, WhatsApp, AnyDesk, TeamViewer, OBS.
5. **Node.js via nvm** — installs the latest LTS version, makes it the
   default, enables corepack (pnpm/yarn without global installs), installs
   the global npm packages from `NPM_GLOBALS` (currently `eas-cli`).
6. **Java** — links `openjdk@17` into `/Library/Java/JavaVirtualMachines`
   so `/usr/libexec/java_home` can find it (needed for Android/Gradle).
7. **Git / GitHub** — asks for `user.name`/`user.email` if not set;
   optionally generates an SSH key (ed25519) for GitHub and prints the
   public key to add to your account; optionally runs `gh auth login`.
   Several git identities with separate keys — see
   [`14_setup_git_identities.sh`](./14_setup_git_identities.en.md).
8. **Mobile development** — prints what to finish installing by hand
   (Xcode and TestFlight only install from the App Store and require an
   Apple ID sign-in — a script can't automate that).
9. **Summary** — prints installed tool versions, the list of what didn't
   install (if anything), and the next steps (`14`, `15`).

`--check` walks the same list (formulae, casks, node/npm, global npm
packages, pnpm via corepack, the Java symlink, the `code` CLI, docker,
git config, the SSH key, `gh auth status`) and prints `[OK] <version>` or
`[--] not installed` for each. At the end — packages from the script's
lists that have a newer version (`[UP] <name>`), per the local Homebrew
index. Changes nothing on the system.

`--inventory` compares the machine with the script's lists (optional ones
included) and prints two sections:

1. **On the machine, not in the script** — `brew leaves`, casks,
   `npm -g`: candidates to add to the script.
2. **In the script's main lists, not on the machine** — plus, separately,
   apps that are present but not via Homebrew.

The output is package names only, no paths: safe to paste into an issue.

## What doesn't get installed automatically

- **Xcode (the full IDE) and TestFlight** — App Store only, requires an
  Apple ID sign-in.
- **The `code` CLI** — the `code` terminal command only appears after
  opening VS Code once and running `Cmd+Shift+P` →
  *Shell Command: Install 'code' command in PATH*.
- **Docker Desktop** — after the cask installs, you need to open the app
  once and accept its terms.
- **Optional packages** — the `OPTIONAL_FORMULAE`/`OPTIONAL_CASKS` lists
  in the script are never installed automatically (only `--inventory`
  knows about them). To install one by default, move it into
  `FORMULAE`/`CASKS`:
  - `restic`, `borgbackup` — backup tools;
  - `ollama` (local LLMs), `yt-dlp`, `logrotate`;
  - the `wireguard-tools` / `wireguard` VPN client;
  - `gcloud-cli` (Google Cloud SDK);
  - `macfuse` and `sshfs` via `gromgit/fuse/sshfs-mac` — require
    approving a system extension.

  Details on `macfuse`/`sshfs`/`restic mount`/`borg mount` (what they
  are, why, how to set them up manually on macOS and Windows) —
  [`../docs/mount-tools.en.md`](../docs/mount-tools.en.md).

## Requirements

- macOS (Intel or Apple Silicon).
- Internet connection.
- Administrator rights (needed to install Xcode CLT, Homebrew, and for
  the `sudo` Java symlink).

## Adapting the software list

The lists at the top of the script (`FORMULAE`, `CASKS`, `COMMS_CASKS`,
`NPM_GLOBALS`, `OPTIONAL_*`) aren't dogma, just a starting point copied
from a real working machine. Drop the mobile stack
(`cocoapods`/`openjdk@17`/`watchman`/`android-studio`) if you don't need
it, add your own. `--inventory` on your working machine will tell you
what to add.
