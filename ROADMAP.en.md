# Roadmap

**[Українська версія](./ROADMAP.md)**

## Process

All tasks/ideas — first go here, into "Вхідні" (Incoming), with the date
added. Not implemented at the moment they're found. Done items — checked
off and moved to `CHANGELOG.md` with a version.

## Вхідні (Incoming)

_(empty)_

## Зроблено (Done)

### Mac onboarding additions — v0.2.0 (2026-11-03)

Spec: [`docs/specs/mac-onboarding-0.2.en.md`](./docs/specs/mac-onboarding-0.2.en.md).

- [x] (2026-11-03) 06: fix lists (restic/borg → optional), new formulae and casks, `corepack enable`, `--with-comms` — spec A.1–A.5.
- [x] (2026-11-03) 06: `--inventory` and `brew outdated` in `--check` — spec A.6–A.7.
- [x] (2026-11-03) New script 14: git identities (`includeIf`), ssh keys and `Host github-<slug>`, global gitignore — spec B.
- [x] (2026-11-03) New script 15: zsh history, Android SDK, macOS `defaults` — spec C.
- [x] (2026-11-03) uk/en docs, checklist, README, CHANGELOG, `package.json` → 0.2.0 — spec D.

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
