# 09_create_profiles.sh

**[Українська версія](./09_create_profiles.md)**

Creates standard (non-admin) macOS role profiles: `personal`, `work`,
`dev`, `sandbox`.

See `SCRIPTS_CHECKLIST.md` #9.

## Running it

Requires `sudo` — creating accounts requires root/admin rights, and that
check happens already at the dry-run stage (before branching on
`--apply`).

```bash
cd scripts
sudo ./09_create_profiles.sh                          # dry run, all 4 profiles
sudo ./09_create_profiles.sh --apply                   # actually create all 4
sudo ./09_create_profiles.sh --apply --only work        # create just one
sudo ./09_create_profiles.sh --apply --filevault        # + register in the FileVault unlock list
```

**The first run ever** (no `scripts/logs/*create_profiles*.log` log yet)
additionally prints a warning and asks for confirmation before
continuing — see the "first run" convention in `SCRIPTS_CHECKLIST.md`.
Triggers once for the script's whole lifetime, including dry runs.

| Flag | Description |
|---|---|
| `--apply` | Actually creates accounts (default — dry run only, printing) |
| `--filevault` | After creating each account, registers it in the FileVault unlock list (`fdesetup add -usertoadd`) — will prompt for an existing FileVault-admin's password |
| `--only <name>` | Process only one profile: `personal` \| `work` \| `dev` \| `sandbox` |
| `-h`, `--help` | Show help |

## How it works

1. Checks it's running under `sudo` — otherwise fails immediately with a
   hint.
2. If this is the first run ever (see above) — asks for confirmation;
   declining aborts execution, nothing is created or logged. After
   confirming (or on any later run) it starts writing a log to
   `scripts/logs/09_create_profiles_<timestamp>.log`.
3. For each profile (`personal:Personal`, `work:Work`, `dev:Dev`,
   `sandbox:Sandbox`): if the account already exists — `[skip]`, leaves
   it alone.
4. Otherwise: `sysadminctl -addUser <username> -fullName "<FullName>"
   -home /Users/<username> -shell /bin/zsh -password -` — the password is
   entered interactively and securely (the `-password -` flag makes
   `sysadminctl` prompt for it instead of taking it as an argv argument,
   which would be visible in the process list/history).
5. If the created account unexpectedly landed in the `admin` group — it's
   automatically removed: the architecture expects exactly one admin
   account, everything else is a standard user.
6. With `--filevault` — additionally registers the account in the
   FileVault unlock list.

## Limitations

- Idempotent: existing accounts are left alone, safe to re-run.
- Doesn't configure Finder/Dock etc. for the new profile.
- Doesn't create SSH keys/git identity for new profiles — for that, log
  into the new profile and run
  [`06_setup_new_dev_mac.sh`](./06_setup_new_dev_mac.en.md).

## The profile list isn't dogma

`PROFILES` at the top of the script is a plain `username:FullName` array.
Drop roles you don't need or add your own — nothing else needs to change.
