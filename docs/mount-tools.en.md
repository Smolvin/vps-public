# Mount tools: sshfs, `restic mount`, `borg mount`, macFUSE/WinFsp

**[Українська версія](./mount-tools.md)**

Reference for packages listed in [`06_setup_new_dev_mac.sh`](../scripts/06_setup_new_dev_mac.en.md).
All of them are in the optional lists (`OPTIONAL_FORMULAE`/`OPTIONAL_CASKS`:
`restic`, `borgbackup`, `macfuse`, `sshfs-mac`) and aren't installed by
default — install as needed (`brew install <name>`) or move them into the
script's main list. Common theme — all three tools give access to "not quite
ordinary" data (a remote directory over SSH, the contents of a backup
archive) as a regular filesystem you can open in Finder/Explorer or walk
with any program, not just a dedicated CLI.

## Why this is needed at all — FUSE and its Windows counterpart

Neither macOS nor Windows can mount a filesystem implemented by an
ordinary user-space program out of the box (unlike Linux, where FUSE is
built into the kernel). A separate component is needed for that:

- **macOS — [macFUSE](https://macfuse.org/)**: installs a system
  extension that grants user-space programs this capability.
- **Windows — [WinFsp](https://winfsp.dev/)**: conceptually the same
  thing, but plugs in via a signed kernel driver on top of a regular MSI
  installer — no separate settings-approval step (see below, the
  difference is significant).

macFUSE/WinFsp don't do anything by themselves — they're infrastructure
used by specific tools (sshfs, `rclone mount`, `restic mount`,
`borg mount`, etc).

## sshfs — mount a directory from a remote server over SSH

Shows the contents of a directory on another machine (reachable over SSH)
as a regular local folder — any program can read/write files, no need for
`scp`/`rsync` for every little thing.

### macOS

```bash
# Homebrew core removed the sshfs formula directly (macFUSE licensing
# reasons) — the working replacement right now is a third-party tap:
brew install --cask macfuse
brew install gromgit/fuse/sshfs-mac
```

After installing — a mandatory manual step, see the macFUSE section below
(without it `sshfs` fails at runtime with an error about an unavailable
FUSE device).

```bash
mkdir -p ~/mnt/remote
sshfs user@host:/path/on/remote ~/mnt/remote
# ...
umount ~/mnt/remote   # unmount
```

### Windows

```powershell
winget install --id SSHFS-Win.SSHFS-Win
```

`WinFsp` is pulled in automatically as a dependency — no need to install
it separately. After installing, the volume can be mounted through
Explorer (`net use`) or `net use X: \\sshfs\user@host`. Details — the
[sshfs-win project README](https://github.com/winfsp/sshfs-win).

## `restic mount` / `borg mount` — open a backup archive as a filesystem

Both [restic](https://restic.readthedocs.io/) and
[BorgBackup](https://borgbackup.readthedocs.io/) are CLI backup tools
with deduplication; the program itself and regular backup/restore
(`restic backup`/`restic restore`, `borg create`/`borg extract`) work
**without** macFUSE/WinFsp at all. FUSE is only needed for the separate
`mount` subcommand — browsing a snapshot's/archive's contents as a
regular folder without restoring it entirely to disk:

```bash
# restic
restic -r /path/to/repo mount ~/mnt/restic
# folders snapshots/<id>/... for each snapshot appear inside ~/mnt/restic
# Ctrl+C or umount ~/mnt/restic when done

# borg
borg mount /path/to/repo::archive-name ~/mnt/borg
# ...
umount ~/mnt/borg
```

Handy when you need to find one file in an old snapshot or compare
versions across several — faster than a full `restic restore`/
`borg extract` and then searching by hand.

**Windows**: restic installs via `winget install --id restic.restic` and
works fine for backup/restore; `restic mount` on Windows also needs
WinFsp (same principle as sshfs above — `winget install --id
WinFsp.WinFsp`, an explicit `--id` is mandatory, the short name sometimes
resolves to the beta version). BorgBackup doesn't officially support
native Windows — `borg mount` there needs WSL (the Linux subsystem),
there's no native winget package.

## Setting up macFUSE manually (macOS)

1. `brew install --cask macfuse` (or download the installer from
   [macfuse.org](https://macfuse.org/)) and run it.
2. macOS will show "System Extension Blocked" — open System Settings via
   the link in that dialog (or manually: **Sequoia (15) and later** —
   Login Items & Extensions; **older versions** — Privacy & Security).
3. Find the entry about developer **"Benjamin Fleischer"**, click
   **Allow**, enter your password.
4. Restart the Mac.

**On Apple Silicon** — two different paths depending on which backend the
installed macFUSE version uses:
- **Recommended (modern macFUSE versions, FSKit backend)** — nothing
  extra to change, just steps 1–4 above.
- **Legacy path (legacy kext backend)** — additionally needs the Startup
  Security Utility (reboot into Recovery, hold `⌘` at startup) → lower
  the security policy to **Reduced Security** → enable "Allow user
  management of kernel extensions from identified developers". Check
  which backend your version uses — if everything already works after
  steps 1–4, the second path isn't needed.

## Setting up WinFsp/SSHFS-Win manually (Windows)

Simpler than on macOS — Windows doesn't require a separate trip to
settings after installing, a regular MSI + UAC confirmation is enough:

```powershell
winget install --id WinFsp.WinFsp
# for sshfs specifically — pulls WinFsp in itself as a dependency, no need to install separately:
winget install --id SSHFS-Win.SSHFS-Win
```

It's important to give the full `--id` (`WinFsp.WinFsp`, not just
`winfsp`) — a known winget issue: the short name sometimes resolves to
`WinFsp.WinFsp.Beta` instead of the stable version.

A reboot usually isn't required after installing — the driver picks up
right away, at most Explorer/the session may need a restart if the
volume didn't show up the first time.
