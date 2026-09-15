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
.\12_create_dev_user.ps1 -Remove           # dry-run: what a rollback would remove
.\12_create_dev_user.ps1 -Remove -Apply   # actually delete the account (rollback)
```

**The first real run ever** (no log yet in `scripts/logs/`) additionally
prints a warning and asks for confirmation — the same convention as
`09_create_profiles.sh`. Triggers once for the script's whole lifetime.

| Parameter | Description |
|---|---|
| `-UserName` | Name of the new (or, when removing, the existing) user (default `dev`) |
| `-Apply` | Actually create the account (default — dry-run only, printing). With `-Remove` — actually delete it. |
| `-Remove` | Rollback: delete the account instead of creating one. Without `-Apply` — dry-run only (shows what would be removed). |

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

## Rollback (`-Remove`)

To undo what this script did (e.g. after a test run or a mistake):

```powershell
.\12_create_dev_user.ps1 -Remove -UserName alex          # dry-run
.\12_create_dev_user.ps1 -Remove -Apply -UserName alex   # actually delete it
```

- No account by that name — `[skip]`, does nothing.
- With `-Apply` — asks for confirmation **every time** (not just on the
  first run, unlike account creation — deleting an account is
  irreversible on every run, so it's worth confirming every time too),
  then runs `Remove-LocalUser`.
- **Does not delete** the profile folder (`C:\Users\<name>`) or its
  files — that's a separate, manual step if you want those gone too.

## Limitations

- Idempotent: an existing account is left alone, safe to re-run.
- Doesn't configure the desktop/profile for the new user.
- Doesn't install dev tools — for that, log in as the new user and run
  [`13_setup_dev_environment.ps1`](./13_setup_dev_environment.en.md).

## This is not "one command" — by design

The script does **not** set up the whole dev environment by itself.
Creating the isolated account (`12`, as administrator) and installing
tools into it (`13`, as that account itself) are two separate Windows
sessions, because the account `13` runs under has to already exist and
you need to actually be logged into it (otherwise git identity/SSH
key/per-user winget packages land in the administrator's profile instead
of `dev`'s). The full sequence for a clean machine is in
[`README.md`](../README.en.md), "Quickstart on a clean Windows machine".

## Troubleshooting

**`cannot be loaded because running scripts is disabled on this system`**
— running `.ps1` scripts is blocked by PowerShell's execution policy
(typical on a freshly installed system). Allow it for the current user
(no administrator needed, only affects local/signed scripts):

```powershell
Set-ExecutionPolicy -Scope CurrentUser -ExecutionPolicy RemoteSigned
```

Or, one-off, without changing the policy at all:

```powershell
powershell -ExecutionPolicy Bypass -File .\12_create_dev_user.ps1
```

**`This script must run as Administrator`** — the script printed this and
stopped (with instructions right in the console). Close the window, open
PowerShell (or Windows Terminal) via right-click -> "Run as
administrator", `cd` back into this folder, and repeat the same command.

**`Add-LocalGroupMember : Группа Users не найдена` (or `Администраторы`)**
— on a localized Windows (RU/UA) the built-in groups are literally named
"Администраторы"/"Пользователи" etc., not `Administrators`/`Users` — the
script now looks them up by a locale-independent well-known SID, so this
error is fixed. If you hit it on an older version of the script: the
account was already created (the error happens after `New-LocalUser`),
so just re-run `.\12_create_dev_user.ps1 -Apply` again with the updated
script — it will catch up on group membership for the already-existing
account too, not only for a brand-new one.

**The new account doesn't show up on the lock screen right away** —
Windows sometimes only refreshes the sign-in account list after a reboot
or `shutdown /l` (signing out of the current account). If it's still
missing, fully sign out of the current account (not just lock the
screen) or restart the machine.
