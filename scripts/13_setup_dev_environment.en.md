# 13_setup_dev_environment.ps1

**[Українська версія](./13_setup_dev_environment.md)**

Windows version of `06_setup_new_dev_mac.sh`: installs a basic set of dev
tools via `winget` + git identity + optionally an SSH key for GitHub.
Idempotent, one failed install doesn't crash the whole script.

See `SCRIPTS_CHECKLIST.md` #13.

## Running it

**As the user** the environment is being set up for (e.g. `dev`, created
by [`12_create_dev_user.ps1`](./12_create_dev_user.en.md)) — not as
administrator, otherwise git identity/SSH key/per-user winget packages
end up in the wrong profile. `winget` itself will only ask for elevation
for the packages that actually need it.

```powershell
.\13_setup_dev_environment.ps1            # install the whole set
.\13_setup_dev_environment.ps1 -Check     # status only, changes nothing
.\13_setup_dev_environment.ps1 -Remove    # rollback: uninstall the packages it installed
```

Like `06_setup_new_dev_mac.sh` (the Mac version), it doesn't write its
own log to `scripts/logs/` and doesn't follow the "first run" convention
— an idempotent software installer, doesn't mutate existing accounts or
files.

## What gets installed

Via `winget` (`Test-WingetPackage` — checks `winget list --id`, skips
what's already installed):

- Git
- VS Code
- Windows Terminal
- GitHub CLI
- Node.js LTS
- Python 3.12

Plus:
- Git identity (`user.name`/`user.email`) — asked for only if not already
  set.
- An SSH key (ed25519) for GitHub — optional (`y/N`), doesn't overwrite
  an existing one.

## How it works

One failed install doesn't stop the rest — it's collected into a
`$Failed` list, printed as a summary at the end. Re-running will only
reinstall what's missing.

`-Check` walks the same list and prints `[OK] <status>` or
`[--] not installed` for each item, changing nothing.

## The package list isn't dogma

The base set is NOT a copy of the Mac list (that one has a mobile/iOS
stack — Xcode/CocoaPods/Android Studio/Figma — most of which doesn't make
sense or isn't available on Windows). A common denominator plus whatever
turns out to actually be needed — added as it comes up, in `$Packages` at
the top of the script (a plain array of `Id`/`Name` hashtables, nothing
generated from anywhere).

## Rollback (`-Remove`)

Uninstalls (via `winget uninstall`) whichever of `$Packages` is currently
installed:

```powershell
.\13_setup_dev_environment.ps1 -Remove
```

- Prints the full list of packages it's about to touch first, then asks
  for `[y/N]` confirmation — **every time**, since this is destructive on
  every run, not just the first.
- A package that isn't installed — `[skip]`. One failed uninstall doesn't
  stop the rest (same as install) — a `$RemoveFailed` summary at the end.
- **Does not touch** git identity or the SSH key — only the packages
  themselves. Remove those manually too if you want them gone
  (`git config --global --unset user.name`/`user.email`, delete
  `~\.ssh\id_ed25519*`).

## Requirements

- Windows 10 (1809+) or Windows 11 — needs `winget` (App Installer from
  the Microsoft Store, already present on most machines).
- Internet connection.

## Troubleshooting

**`cannot be loaded because running scripts is disabled on this system`**
— running `.ps1` scripts is blocked by PowerShell's execution policy
(typical on a freshly installed system):

```powershell
Set-ExecutionPolicy -Scope CurrentUser -ExecutionPolicy RemoteSigned
```

Or one-off: `powershell -ExecutionPolicy Bypass -File .\13_setup_dev_environment.ps1`.

**`winget not found`** — the script prints exact steps right in the
console: install/update "App Installer" from the Microsoft Store, or, if
the Store isn't available, download the `.msixbundle` from the official
[winget-cli releases page](https://github.com/microsoft/winget-cli/releases/latest)
and install it with `Add-AppxPackage`.

**`[warn] Running as Administrator`** — the script detects this itself
and asks for confirmation before continuing (with `-Check` it just warns,
without asking, since nothing changes). The correct move is to sign out,
log in as the intended user (e.g. `dev`, created by
[`12_create_dev_user.ps1`](./12_create_dev_user.en.md)), and run it from
there.

**`CommandNotFoundException` errors for git/ssh-keygen during install** —
the script checks whether `git`/`ssh-keygen` exist before using them and
cleanly skips (`[skip]`) the corresponding step if the tool isn't there
yet (for example, the `Git` install via `winget` failed — no internet, or
a corporate policy blocking the package). Check the `$Failed` summary at
the end of the output and re-run the script after fixing the cause — it
will only reinstall what's still missing.
