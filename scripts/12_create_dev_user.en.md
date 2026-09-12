# 12_create_dev_user.ps1

**[Українська версія](./12_create_dev_user.md)**

Windows version of `09_create_profiles.sh`: creates **one** isolated
(non-admin) local `dev` profile — same principle as on Mac: exactly one
admin account in the architecture, everything else is a standard user.

See `SCRIPTS_CHECKLIST.md` #12.

## Running it

As administrator:

```powershell
.\12_create_dev_user.ps1                  # dry-run
.\12_create_dev_user.ps1 -Apply           # actually create
.\12_create_dev_user.ps1 -Apply -UserName sandbox   # a different name
```

**The first real run ever** (no log yet in `scripts/logs/`) additionally
prints a warning and asks for confirmation — the same convention as
`09_create_profiles.sh`. Triggers once for the script's whole lifetime.

| Parameter | Description |
|---|---|
| `-UserName` | Name of the new user (default `dev`) |
| `-Apply` | Actually create the account (default — dry-run only, printing) |

## How it works

1. Checks it's running as administrator.
2. If this is the first run ever — asks for confirmation.
3. If a user with that name already exists — `[skip]`, leaves it alone
   (idempotent).
4. Otherwise (only with `-Apply`): asks for the password interactively
   (`Read-Host -AsSecureString`, never as an argument), creates it with
   `New-LocalUser`.
5. Checks the account did NOT land in the `Administrators` group —
   removes it if it did (this role must stay isolated).
6. Makes sure the account is a member of the regular `Users` group.

## Limitations

- Idempotent: an existing account is left alone, safe to re-run.
- Doesn't configure the desktop/profile for the new user.
- Doesn't install dev tools — for that, log in as the new user and run
  [`13_setup_dev_environment.ps1`](./13_setup_dev_environment.en.md).
