# 14_reduce_windows_bloat.ps1

**[Українська версія](./14_reduce_windows_bloat.md)**

Quiets down the nagging parts of Windows: Start menu ads/suggestions,
OneDrive auto-start at logon, Cortana/Bing results in Start search, the
Widgets taskbar button, "tailored" tips from diagnostic data + the
advertising ID, Windows Spotlight ads on the lock screen — plus
machine-wide telemetry (the `AllowTelemetry` policy + the DiagTrack
service).

See `SCRIPTS_CHECKLIST.md` #14.

**Deliberately conservative.** NOT touched on purpose (each of these
trades real functionality or security away for quiet): Windows Update,
Microsoft Defender, removing built-in/pre-installed apps, any service
beyond the two telemetry-only ones below. A "full debloat" is
deliberately out of scope for this script.

## Running it

As administrator (it changes HKLM policies and mounts other profiles'
registry hives — no way around needing admin for that):

```powershell
.\14_reduce_windows_bloat.ps1                        # dry-run
.\14_reduce_windows_bloat.ps1 -Apply                  # actually apply
.\14_reduce_windows_bloat.ps1 -Apply -UserName sandbox # a different account instead of dev
.\14_reduce_windows_bloat.ps1 -Remove                  # dry-run: what a rollback would restore
.\14_reduce_windows_bloat.ps1 -Remove -Apply           # actually roll back
```

**The first real run ever** (no log yet in `scripts/logs/`) additionally
prints a warning and asks for confirmation — the same convention as
`12_create_dev_user.ps1`. Triggers once for the script's whole lifetime
for the "apply" direction; `-Remove -Apply` asks for confirmation
**every time** instead (rolling back is irreversible on every run, not
just the first).

| Parameter | Description |
|---|---|
| `-UserName` | Existing user whose already-created profile (if any) also gets these settings, on top of the Default template (default `dev`) |
| `-Apply` | Actually apply the changes (default — dry-run only, printing). With `-Remove` — actually roll back. |
| `-Remove` | Rollback: remove the values and restore the services. Without `-Apply` — dry-run only. |

## What exactly changes

**Per-profile** (applied to the Default profile template — so any future
new local account inherits it right away — and to `-UserName`'s profile
too, if it has logged in at least once, i.e. its `NTUSER.DAT` already
exists):

- Start menu / Settings app ads and suggestions (`ContentDeliveryManager`)
- OneDrive auto-start at logon (just the reminder entry, not the app
  itself — OneDrive stays installed, it just doesn't launch itself)
- Cortana / Bing results in Start menu search
- The Widgets taskbar button — hidden
- "Tailored" tips from diagnostic data + the advertising ID
- Windows Spotlight ads on the lock screen

**Machine-wide** (affects every account, including the admin one you're
running the script from):

- `AllowTelemetry` policy — the minimum this Windows edition allows
- Advertising ID — disabled machine-wide by policy (on top of the
  per-profile value above)
- "Connected User Experiences and Telemetry" (`DiagTrack`) service —
  disabled
- "WAP Push Message Routing Service" (`dmwappushsvc`) — disabled

## How it works

- Per-profile values are applied offline: the script mounts each target
  profile's `NTUSER.DAT` via `reg.exe load` into a temporary
  `HKU\TempHive14_...` node, reads/writes through it, then unmounts
  cleanly (`Remove-PSDrive` -> `[gc]::Collect()` -> `reg.exe unload`, to
  avoid a "hive still in use" failure).
- Every item is idempotent: if the value is already what's wanted —
  `[skip]`, nothing touched. One failure doesn't stop the rest — a
  `$Failed` summary at the end, like `13_setup_dev_environment.ps1`.
- `-Remove` deletes the values this script set (restoring stock Windows
  behavior — those values simply didn't exist on a clean install) and
  restores both services to their default startup type. It does **not**
  attempt to restore the OneDrive auto-start entry (the original command
  line isn't known — re-enable it manually via Task Manager > Startup
  apps after a rollback if you want it back).

## Limitations

- Doesn't roll back anything Windows itself had already changed before
  the first `-Apply` run — rollback only knows about what this script
  itself set.
- Doesn't do anything for a profile that has never logged in and isn't
  the Default template — it only gets the Default template's settings
  in that case (and inherits them itself on first login).
- A live run (actually applying or rolling back) on a real machine wasn't
  automatically verified during development — only statically (parsing +
  code review). The first real run is up to you, with the log at
  `scripts/logs/14_reduce_windows_bloat_*.log` to review afterward.
