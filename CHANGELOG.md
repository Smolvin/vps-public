# Changelog

**[English version](./CHANGELOG.en.md)**

Формат — [Keep a Changelog](https://keepachangelog.com/), версії — [SemVer](https://semver.org/).

## [0.2.0] — 2026-11-03

Специфікація: [`docs/specs/mac-onboarding-0.2.md`](./docs/specs/mac-onboarding-0.2.md).

### Додано

- `14_setup_git_identities.sh` + `.md` — кілька git-ідентичностей на
  одному Mac: `~/.gitconfig-<slug>` + `includeIf "gitdir:<папка>/"`,
  окремий SSH-ключ і `Host github-<slug>` на кожну, `ControlMaster` для
  SSH, глобальний gitignore. Сухий прогін за замовчуванням, `--apply`,
  бекапи, блоки з маркерами, без перезапису наявного.
- `15_setup_shell_and_macos.sh` + `.md` — історія zsh, змінні Android
  SDK, аліаси docker compose (`--with-docker-aliases`), налаштування
  Finder (розширення, приховані файли, шлях у заголовку, рядок шляху) і
  папка скріншотів. Сухий прогін за замовчуванням, `--apply`.
- `06`: `--inventory` — тільки читання, порівнює машину зі списками
  скрипта в обидва боки.
- `06`: `--with-comms` — група застосунків для спілкування й віддаленого
  доступу (Zoom, Telegram, WhatsApp, AnyDesk, TeamViewer, OBS).
- `06`: нові формули — `semgrep`, `trivy`, `osv-scanner`, `ffmpeg`,
  `pandoc`, `poppler`, `exiftool`, `rsync`, `pstree`, `jq`, `ripgrep`;
  нові casks — `coteditor`, `stats`, `vlc`, `obsidian`.
- `06 --check`: застарілі пакети зі списків скрипта (`brew outdated`).
- `docs/specs/` — специфікації доопрацювань.
- `package.json`: npm-скрипти для `06 --inventory`, `14`, `15`.

### Змінено

- `06`: `restic`, `borgbackup` перенесені з основного списку в
  опціональні (`OPTIONAL_FORMULAE`/`OPTIONAL_CASKS` — разом з `ollama`,
  `yt-dlp`, `logrotate`, `gcloud-cli`, `wireguard`, `macfuse`,
  `sshfs-mac`); `docs/mount-tools.md` оновлено.
- `06`: застосунок, уже встановлений не через Homebrew (`.dmg`, App
  Store), не вважається відсутнім — пропускається з підказкою
  `brew install --cask --adopt`.
- `06`: помилка `corepack enable` тепер потрапляє в підсумок помилок;
  глобальні npm-пакети — списком `NPM_GLOBALS`.
- `06`: `shellcheck` повністю чистий.

## [0.1.0] — 2026-09-10

### Додано

- `06_setup_new_dev_mac.sh` + `.md` — онбординг dev-інструментів на macOS
  (Homebrew, Node.js, VS Code, Git/GitHub, мобільний стек). Ідемпотентний,
  `--check` — тільки статус.
- `09_create_profiles.sh` + `.md` — ізольовані не-admin профілі macOS
  (`personal`/`work`/`dev`/`sandbox`). Dry-run за замовчуванням, `--apply`
  — реальне створення.
- `12_create_dev_user.ps1` + `.md` — Windows-аналог: ізольований не-admin
  профіль `dev`. Dry-run за замовчуванням, `-Apply` — реальне створення.
- `13_setup_dev_environment.ps1` + `.md` — Windows-аналог: набір
  dev-інструментів через `winget` + git identity + SSH-ключ. Ідемпотентний,
  `-Check` — тільки статус.
- `README.md`, `CLAUDE.md`, `SCRIPTS_CHECKLIST.md` — конвенції
  репозиторію (наскрізна нумерація, dry-run/`--apply`, «перший запуск»,
  санітизація публічних даних).
- `LICENSE` (MIT) + `"license": "MIT"` у `package.json`.
- `CONTRIBUTING.md` — процес PR, вимоги до нових скриптів, мінімум
  тестування перед PR.
- `06_setup_new_dev_mac.sh`: `restic`/`borgbackup` в основний список
  формул; опціональний (закоментований) `gromgit/fuse/sshfs-mac` поруч з
  уже наявним `macfuse`.
- `docs/mount-tools.md` — довідка по sshfs/`restic mount`/`borg mount`/
  macFUSE (macOS) і WinFsp/SSHFS-Win (Windows): навіщо потрібні, точні
  команди встановлення, як вручну схвалити system extension на macOS
  (включно з різницею для Apple Silicon між FSKit- і legacy kext-backend).
- `ROADMAP.md` — воркфлоу задач/ідей для цього репозиторію.
- Посилання на донати ([buymeacoffee.com/smolvin](https://buymeacoffee.com/smolvin),
  [send.monobank.ua/jar/6jiZRYv6CA](https://send.monobank.ua/jar/6jiZRYv6CA))
  в `README.md`.
- Двомовність: українська версія кожного файлу за замовчуванням +
  англійська (`.en.md`), російську мову прибрано з репозиторію повністю.
