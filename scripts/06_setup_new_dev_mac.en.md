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
| `./06_setup_new_dev_mac.sh --check` | Installs nothing — only shows what's already there and what's missing. |
| `./06_setup_new_dev_mac.sh --help` | Short flag reference. |

## How it works

The script is idempotent: before installing each component it checks
whether it's already there, and skips it if so. It can be run any number
of times — it either does nothing (everything's already installed) or
finishes installing what's missing.

If one specific package fails to install (network error, conflict, etc.),
the script **does not crash entirely** — it prints a warning, defers that
item into a list, and moves on. At the end it prints a summary of what
didn't install, so you can investigate and re-run the script.

Order of steps on a normal run:

1. **Xcode Command Line Tools** — check/install (needed by Homebrew, git,
   CocoaPods, compilers).
2. **Homebrew** — installs it if missing, plus `brew update`.
3. **Homebrew formulae**: `git`, `gh`, `nvm`, `python@3.14`, `php`,
   `cocoapods`, `openjdk@17`, `watchman`, `mkcert`, `shellcheck`,
   `imagemagick`, `gitleaks`, `rclone`, `restic`, `borgbackup` (the last
   two are backup tools; their `mount` subcommand needs macFUSE, see
   `docs/mount-tools.md` — plain backup/restore works fine without it).
4. **Homebrew casks (apps)**: VS Code, iTerm2, Docker Desktop, Chrome,
   Firefox Developer Edition, Android Studio, Figma, Postman, Claude,
   Shottr.
5. **Node.js via nvm** — installs the latest LTS version, makes it the
   default, enables corepack, installs `eas-cli` globally via npm.
6. **Java** — links `openjdk@17` into `/Library/Java/JavaVirtualMachines`
   so `/usr/libexec/java_home` can find it (needed for Android/Gradle).
7. **Git / GitHub** — asks for `user.name`/`user.email` if not set;
   optionally generates an SSH key (ed25519) for GitHub and prints the
   public key to add to your account; optionally runs `gh auth login`.
8. **Mobile development** — prints what to finish installing by hand
   (Xcode and TestFlight only install from the App Store and require an
   Apple ID sign-in — a script can't automate that).
9. **Summary** — prints installed tool versions and the list of what
   didn't install (if anything).

`--check` walks the same list (formulae, casks, node/npm, eas-cli, the
Java symlink, the `code` CLI, docker, git config, the SSH key,
`gh auth status`) and prints `[OK] <version>` or `[--] not installed` for
each, changing nothing on the system.

## What doesn't get installed automatically

- **Xcode (the full IDE) and TestFlight** — App Store only, requires an
  Apple ID sign-in.
- **The `code` CLI** — the `code` terminal command only appears after
  opening VS Code once and running `Cmd+Shift+P` →
  *Shell Command: Install 'code' command in PATH*.
- **Docker Desktop** — after the cask installs, you need to open the app
  once and accept its terms.
- Optional items, commented out in the script itself (the
  `wireguard`/`wireguard-tools` VPN client, `macfuse`, `sshfs` via
  `gromgit/fuse/sshfs-mac`) — require approving system extensions and are
  turned on manually if a given team needs them. Details on
  `macfuse`/`sshfs`/`restic mount`/`borg mount` (what they are, why, how
  to set them up manually on macOS and Windows) —
  [`../docs/mount-tools.en.md`](../docs/mount-tools.en.md).

## Requirements

- macOS (Intel or Apple Silicon).
- Internet connection.
- Administrator rights (needed to install Xcode CLT, Homebrew, and for
  the `sudo` Java symlink).

## Adapting the software list

The formulae/casks list at the top of the script (`FORMULAE`/`CASKS`)
isn't dogma, just a starting point copied from a real working machine.
Drop the mobile stack (`cocoapods`/`openjdk@17`/`watchman`/
`android-studio`) if you don't need it, add your own.
