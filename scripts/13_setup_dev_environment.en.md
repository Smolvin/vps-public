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

## Requirements

- Windows 10 (1809+) or Windows 11 — needs `winget` (App Installer from
  the Microsoft Store, already present on most machines).
- Internet connection.
