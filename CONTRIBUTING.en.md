# How to contribute

**[Українська версія](./CONTRIBUTING.md)**

Thanks for your interest — the goal of this repository is exactly to keep
the cold start for a new developer (Mac or Windows) as fast and painless
as possible, together. PRs, issues, suggestions for new scripts — welcome.

## Before opening a PR

1. **One PR — one logical change.** A new script, a bugfix in an existing
   one, a documentation edit — separate PRs, don't mix them.
2. If you're adding a **new script** — open an issue first with a short
   description of what it does and why: numbering in this repository is
   sequential and permanent (see below), a number is assigned when the
   idea is accepted, not after the fact once a PR has already been
   written under an arbitrary name.
3. If you're editing an existing script — **don't rename the file and
   don't change its number**, even if the logic changes substantially.
   Number = filename, fixed once forever (see `CLAUDE.md`).

## Conventions a new/changed script must follow

Details — in [`CLAUDE.md`](./CLAUDE.md), in short:

- **Idempotency.** A repeat run with no flags must not break anything —
  either it does nothing (already applied) or it finishes what's missing.
- **Dry-run by default**, `--apply`/`-Apply` — for actually changing the
  system. Exception — idempotent software installers (don't mutate
  accounts/files): they use `--check`/`-Check` instead.
- **Passwords/secrets, interactive input only.** Never a command-line
  argument and never hardcoded in the script.
- **One failure must not crash the whole script.** Collect errors into a
  list, print a summary at the end, keep going with the rest.
- **A pair of files**: `NN_name.sh`/`.ps1` (code, in English) +
  `NN_name.md` + `NN_name.en.md` (documentation — Ukrainian/English, what
  it does, how to run it, limitations).
- **No private data.** No absolute paths of specific machines, no real
  emails/account names, no tokens/keys — not in the code, not in
  comments, not in command examples.

## Testing before a PR

At minimum:
- `bash -n script.sh` (or `pwsh -Command "... Parser::ParseFile ..."` for
  `.ps1`) — syntax.
- `shellcheck script.sh` — for bash scripts, fix at least warning+ level
  (info-level, e.g. the known `SC2016` on literal `$HOME` strings in rc
  files, can be left if it's intentional).
- A real run on a clean (or snapshot/virtual) machine — if possible. If
  you don't have access to the right OS for a real run — say so in the
  PR, the reviewer can run it themselves before merging.

## After the merge

The maintainer updates `CHANGELOG.md` (semver bump in `package.json` if
warranted) and the matching row in `SCRIPTS_CHECKLIST.md` — doing this in
the PR yourself is not required, but welcome.

## Questions

If something is unclear in `CLAUDE.md`/`SCRIPTS_CHECKLIST.md`, or a
convention feels inconvenient — open an issue to discuss it, conventions
aren't set in stone if there's a good argument to change them.
