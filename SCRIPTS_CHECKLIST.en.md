# Script run checklist

**[Українська версія](./SCRIPTS_CHECKLIST.md)**

Separate from the rest of the documentation: this is only the physical
fact of scripts being run, so at any moment it's clear which script, with
which parameters, has already been run and at what stage (dry run / real
execution).

**Parameter convention (uniform for all scripts in the project, unless an
exception is noted):** no parameters — dry run (changes nothing);
`--apply`/`-Apply` — actually applies changes. Every script, on a dry run,
prints the ready-to-copy command with `--apply`.

**"First run" convention (uniform for scripts that write to
`scripts/logs/`):** before doing anything else, each such script checks
whether there's at least one of its own logs in `scripts/logs/`. If not —
this is its first real run ever — it prints a warning and asks for
explicit `[y/N]` confirmation before continuing. Declining — exits with
no changes and no log created, so the warning appears again next time.
Confirmation is given once for the script's whole lifetime.

**Exceptions — #06 and #13 (`06_setup_new_dev_mac.sh`,
`13_setup_dev_environment.ps1`):** don't mutate existing files/accounts,
but idempotently install missing software (self-detect what's already
there and skip it), so instead of dry-run/`--apply` they use
`--check`/`-Check` (status report only, changes nothing) and a plain run
(installs what's missing). They also don't write their own log to
`scripts/logs/` — the "first run" convention doesn't apply to them.

**Script filename = the number of its row below.** If a script is later
improved (new flag/key) — the file is **not renamed**: the existing base
is edited under the same name. The number/name is fixed to the script
once.

**Process for each row:**
1. Script added → row appears here (both checkboxes empty).
2. Script actually run (dry run or `--apply`/`-Apply`).
3. Based on the log/fact — the matching checkbox is checked.

---

| # | Script | Dry run | Real execution | Notes |
|---|---|:---:|:---:|---|
| 06 | `scripts/06_setup_new_dev_mac.sh`<br>`scripts/06_setup_new_dev_mac.sh --check` | ⬜ | ⬜ | See `scripts/06_setup_new_dev_mac.en.md`. `bash -n`/`shellcheck` clean (1 info-level SC2016 warning, expected — a literal `$HOME` string in an rc file). Real run not yet confirmed in this repository. |
| 09 | `sudo scripts/09_create_profiles.sh`<br>`sudo scripts/09_create_profiles.sh --apply [--only <name>] [--filevault]` | ⬜ | ⬜ | See `scripts/09_create_profiles.en.md`. `bash -n` clean. Requires `sudo` — real run (creating system accounts) is up to the user. |
| 12 | `scripts\12_create_dev_user.ps1`<br>`scripts\12_create_dev_user.ps1 -Apply` | ⬜ | ⬜ | See `scripts/12_create_dev_user.en.md`. Requires administrator rights and creates a real Windows account — up to the user. |
| 13 | `scripts\13_setup_dev_environment.ps1`<br>`scripts\13_setup_dev_environment.ps1 -Check` | ⬜ | ⬜ | See `scripts/13_setup_dev_environment.en.md`. Not yet run on a real Windows machine. |

---

*New rows are added as new scripts appear.*
