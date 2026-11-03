# 15_setup_shell_and_macos.sh

**[Українська версія](./15_setup_shell_and_macos.md)**

Small but everyday-useful settings for a dev Mac: zsh history, Android
SDK environment variables, Finder appearance and the screenshot folder.

See `SCRIPTS_CHECKLIST.md` #15. Spec —
[`docs/specs/mac-onboarding-0.2.en.md`](../docs/specs/mac-onboarding-0.2.en.md), section C.

## Running it

```bash
cd scripts
./15_setup_shell_and_macos.sh                              # dry run: current -> new, changes nothing
./15_setup_shell_and_macos.sh --apply                      # really apply
./15_setup_shell_and_macos.sh --apply --android            # Android env even if the SDK isn't installed yet
./15_setup_shell_and_macos.sh --apply --with-docker-aliases
./15_setup_shell_and_macos.sh --help
```

| Flag | Description |
|---|---|
| `--apply` | Really changes things (default — dry run only) |
| `--android` | Add the Android SDK variables even if `~/Library/Android/sdk` doesn't exist yet |
| `--with-docker-aliases` | Add `dcu`/`dcd`/`dcl`/`dps` aliases for `docker compose` |
| `-h`, `--help` | Help |

The script asks one thing: the screenshot folder (default — the current
one if set, otherwise `~/Pictures/Screenshots`).

**The first run ever** (no `scripts/logs/15_setup_shell_and_macos_*.log`
yet) prints a warning and asks for confirmation — see the "first run
convention" in `SCRIPTS_CHECKLIST.en.md`.

## What it changes

**`~/.zshrc`** — marker blocks `# >>> vps-infra-public 15 <id> >>>`, only
what's not there yet (your own settings outside the blocks are detected
and not duplicated):

| Block | Contents |
|---|---|
| `zsh-history` | `setopt APPEND_HISTORY INC_APPEND_HISTORY SHARE_HISTORY HIST_IGNORE_DUPS HIST_IGNORE_SPACE` — history shared across all windows, written immediately, no repeats; a command starting with a space isn't saved |
| `android` | `ANDROID_HOME=$HOME/Library/Android/sdk` + `emulator`, `platform-tools`, `cmdline-tools/latest/bin` on `PATH`. Only if the SDK is installed (Android Studio opened at least once) or with `--android` |
| `docker-aliases` | `dcu` = `docker compose up -d`, `dcd` = `down`, `dcl` = `logs -f`, `dps` = `ps`. Only with `--with-docker-aliases` |

**macOS `defaults`:**

| Setting | Key |
|---|---|
| Finder: show all file extensions | `NSGlobalDomain AppleShowAllExtensions` |
| Finder: show hidden files | `com.apple.finder AppleShowAllFiles` |
| Finder: full path in the window title | `com.apple.finder _FXShowPosixPathInTitle` |
| Finder: path bar at the bottom of the window | `com.apple.finder ShowPathbar` |
| Screenshots: save folder | `com.apple.screencapture location` |

The dry run shows `current -> new` for each item. After `--apply`,
Finder / SystemUIServer are restarted only if something actually changed.

## Change safety

- `~/.zshrc` — a copy `~/.zshrc.bak-YYYY-MM-DD-HHMMSS` before the first
  change.
- A re-run with nothing to change writes nothing and restarts nothing.
- One failed step doesn't stop the script — summary at the end.

## How to roll back

- `~/.zshrc` — restore from `.bak-*` or delete the blocks between the
  `vps-infra-public 15` markers.
- `defaults` — `defaults delete <domain> <key>` (back to the system
  default), then `killall Finder` / `killall SystemUIServer`.
