# Roadmap

**[Українська версія](./ROADMAP.md)**

## Process

All tasks/ideas — first go here, into "Вхідні" (Incoming), with the date
added. Not implemented at the moment they're found. Done items — checked
off and moved to `CHANGELOG.md` with a version.

## Вхідні (Incoming)

_(empty)_

## Зроблено (Done)

### New script 14 -- reduce Windows ads/telemetry (2026-09-13)

The user asked for the new account to be set up so Windows "doesn't ask
anything else" and the system feels as close to Linux as possible --
strip ads/suggestions, analytics, unnecessary "conveniences". Clarified
two questions before building it: how aggressive (chosen: conservative +
machine telemetry, no Windows Update/Defender/app removal) and where to
add it (chosen: a new separate script #14, not folded into 12). Also
recorded an important fact along the way: a local account created via
`New-LocalUser` (as `12` does) does NOT go through full OOBE privacy
questions -- those only happen during the machine's actual initial setup;
logging into a new local account isn't blocked by anything. So the
script solves a different, real problem -- not "unblock login", but
removing non-blocking but annoying nags/ads/telemetry. `-Remove` has
only been verified statically (parsing + code review) -- after an
earlier incident in this same session where a live test of a destructive
path on a real machine accidentally touched real software, it was
decided not to run live tests of destructive branches for 12/13/14
independently anymore; the actual run is left to the user.

- [x] (2026-09-13) Add `14_reduce_windows_bloat.ps1` -- conservative
      Windows ads/suggestions/telemetry reduction, with `-Remove` for
      rollback.

### A -Remove (rollback) flag for 12/13 (2026-09-13)

The user asked for a way to roll back the scripts' actions, so that
repeated runs during debugging/testing don't leave the machine in a
half-done state. Added `-Remove` to both:
`12_create_dev_user.ps1 -Remove [-Apply]` deletes the isolated account
(asks for confirmation every time, doesn't touch the profile folder);
`13_setup_dev_environment.ps1 -Remove` runs `winget uninstall` for
whichever packages are installed (asks for confirmation every time,
doesn't touch git identity/the SSH key). A live test of the destructive
path on a real machine during development was deliberately stopped —
`-Remove` has only been verified statically (parsing + code review); the
actual run on a real machine is left to the user.

- [x] (2026-09-13) Add `-Remove` to 12/13 for rolling back actions; the
      actual run on a real machine is up to the user.

### 12 crashed on a localized Windows over hard-coded group names (2026-09-13)

An actual user run of `12_create_dev_user.ps1 -Apply` (after the earlier
BOM/encoding fix) failed with `Add-LocalGroupMember : Группа Users не
найдена` — the account was already created (`New-LocalUser` succeeded),
it was the group check that failed. Cause: the script looked up
`Administrators`/`Users` by their hard English name, but on an RU/UA
Windows locale those built-in groups are literally named
"Администраторы"/"Пользователи". Fixed by looking them up by well-known
SID (`S-1-5-32-544`/`S-1-5-32-545`) instead — reproduced and verified on
an actual Cyrillic-locale machine (the same bug, the same localized
group names), not guessed. Also fixed an adjacent gap: if the account
already existed and `-Apply` was passed, the script used to just exit
without checking groups at all — now it catches up on membership for an
existing account too, so re-running after exactly this kind of partial
failure actually fixes it.

- [x] (2026-09-13) Fix the hard-coded built-in group name lookup — switch
      to well-known SIDs; make the group check idempotent for an
      already-existing account too.

### 12/13 wouldn't run on a clean Windows machine (2026-09-13)

A user reported being unable to run `12_create_dev_user.ps1`/
`13_setup_dev_environment.ps1`. Investigating with an actual run (not
just reading the code) found three separate causes: (1) a real bug — the
files had no UTF-8 BOM and used an em dash inside string literals, which
broke Windows PowerShell 5.1 parsing when the "language for non-Unicode
programs" is Cyrillic (typical for a Ukrainian Windows locale) — fixed by
adding a BOM; (2) missing administrator rights for `12`, and (3) missing
`winget` for `13` — both now print step-by-step fix instructions straight
to the console. Additionally, `13` now warns if it's run as
administrator (it should run as the target user instead), and cleanly
skips the git-identity/SSH steps if `git`/`ssh-keygen` aren't installed
yet instead of throwing `CommandNotFoundException`. Documented: a
"Troubleshooting" section in `scripts/12_create_dev_user.en.md`/
`13_setup_dev_environment.en.md` plus a "Quickstart on a clean Windows
machine" in `README.en.md` (spelling out that it's two sessions, not one
command).

- [x] (2026-09-13) Figure out why 12/13 wouldn't run on a clean machine,
      fix the bugs found, document the full sequence.

### Donation platform — Buy Me a Coffee (2026-09-11)

Decision made: [buymeacoffee.com/smolvin](https://buymeacoffee.com/smolvin)
— link and badge added to `README.md`. The alternatives (GitHub Sponsors,
Ko-fi, Open Collective, Patreon) listed when this item was filed weren't
needed — the choice was made directly by the user.

- [x] (2026-09-10) Set up a donation platform — Buy Me a Coffee.

### Monobank jar as a second donation channel (2026-09-11)

Added next to Buy Me a Coffee:
[send.monobank.ua/jar/6jiZRYv6CA](https://send.monobank.ua/jar/6jiZRYv6CA)
— in `README.md`.

- [x] (2026-09-11) Add the monobank jar link.

### Bilingual docs (Ukrainian default + English), remove Russian (2026-09-11)

The whole repository moved from Russian to a bilingual scheme: Ukrainian
is the primary version of every file (`NN_name.md`), English is the same
file with an `.en.md` suffix. Code/comments in scripts — English
regardless of documentation language (unified with what `06`/`09` already
had). The convention is documented in `CLAUDE.md`, "Language" section.

- [x] (2026-09-11) Translate all documentation to Ukrainian/English,
      remove Russian from the repository.
