# Instructions for Claude on this repository

**[Українська версія](./CLAUDE.md)**

## The user makes commits

Claude does not run `git commit` in this repository on its own — only
`git add`/`git status`/preparing changes on request. The final commit
(and its message) is always made by the user.

## Public repository — sanitization is mandatory

This repository is public. Material sometimes comes in here from other,
non-public sources — before anything gets added or committed here:

- No absolute paths of private machines/repositories
  (`/Users/Shared/...`, `/Users/<name>/...`), no real account names,
  emails, tokens, or IPs/domains of specific infrastructure. If a source
  script references them — replace with a generic phrasing ("see the
  neighboring script in this repo", "your admin account", etc.), don't
  copy as-is.
- Secrets never land here in principle — if a script needs a key/password,
  it's entered interactively or read from a gitignored config, never
  hardcoded or committed "temporarily".
- Before committing — eyeball `git status`/`git diff` for accidentally
  dragged-in personal data, don't rely on `.gitignore` alone.

## Language

- **Documentation** (`.md` files) — bilingual: Ukrainian by default (base
  filename, e.g. `README.md`), English — the same file with an `.en.md`
  suffix (e.g. `README.en.md`). A language-switcher line at the top of
  every file, pointing to the other version. No Russian documentation
  anywhere.
- **Code and in-script comments** (`.sh`/`.ps1`) — English, regardless of
  the documentation language. The only exception is interactive messages
  a script actually prints to the user at runtime (`Log`/`Write-Host`/
  `echo`) — those can stay as originally written until someone translates
  them.
- Changing the docs in one language — **must** sync the other language
  version in the same change, not a separate PR.

## Script numbering canon (mandatory, see `SCRIPTS_CHECKLIST.md`)

- **Sequential numbering**, one counter for the whole repository, never
  reset and no gaps "per platform" — Mac and Windows scripts share the
  same counter (example: `06`/`09` — Mac, `12`/`13` — Windows).
- **Filename = number, fixed forever.** A script gets improved in place
  (new flag, bugfix) — the file is never renamed and never recreated
  under a new number, even if the logic changes substantially.
- **Every script is a pair**: `NN_name.sh`/`.ps1` (code) + `NN_name.md` +
  `NN_name.en.md` (documentation, see "Language" above).
- If a script originally appeared somewhere else under its own number —
  here it **keeps that number** (not renumbered to the next free one) —
  so it can be referenced by the same number regardless of context.
- A new row in `SCRIPTS_CHECKLIST.md` — for every added script, with the
  same number as the filename.

## Parameter and idempotency convention

- By default — no arguments — a dry run, changes nothing. `--apply`/
  `-Apply` — actually applies changes.
- Exception — idempotent installers (don't mutate existing accounts/
  files, self-detect what's already there): instead of dry-run/`--apply`
  they use `--check`/`-Check` (status only) and a plain run (installs
  what's missing). Example — `06`/`13`. A new such exception — must be
  recorded in `SCRIPTS_CHECKLIST.md` next to the rest.
- "First run" (for scripts that write to `scripts/logs/`): before the
  first real execution — a warning + explicit `[y/N]` confirmation, not
  asked again once a log exists.
- Passwords/secrets — interactive input only (`Read-Host -AsSecureString`
  on Windows, `read -s`/a tool like `sysadminctl -password -` on Mac),
  never a command-line argument (visible in history/process list) and
  never hardcoded.
- One failed step must not crash the whole script — collect into a list,
  print a summary at the end, keep going (see `06`/`13`).

## Roadmap workflow

This project keeps a `ROADMAP.md` and a `CHANGELOG.md`:

- Any found problem or idea — first into `ROADMAP.md`, the "Вхідні"
  (Incoming) section (`## Вхідні`), as a TODO with a `(YYYY-MM-DD)` date.
  Not implemented right at the moment it's found.
- After implementing an item — check it off in `ROADMAP.md` and add an
  entry to `CHANGELOG.md`.

## After changes

- A material change (new script, new flag, fixed bug) — an entry in
  `CHANGELOG.md` under the current/new version (semver bump in
  `package.json` if warranted) and an update to the matching row in
  `SCRIPTS_CHECKLIST.md`.
- `README.md`/`README.en.md` — the scripts table gets refreshed in the
  same change if the list changed.
