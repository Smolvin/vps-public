# Специфікація: доповнення Mac-онбордингу (v0.2.0)

**[English version](./mac-onboarding-0.2.en.md)**

- **Статус:** узгоджено, до реалізації
- **Додано:** 2026-11-03
- **Джерело:** звірка списків `scripts/06_setup_new_dev_mac.sh` з тим, що
  реально знадобилося на робочому Mac за ~2 місяці активного використання.
- **Цільова версія:** `0.2.0` (`package.json`, `CHANGELOG.md`)

## Мета

1. Привести списки `06` у відповідність до реального використання.
2. Додати те, чого в онбордингу немає зовсім: налаштування git-ідентичностей
   і ssh (новий скрипт `14`) та налаштування shell і macOS (новий скрипт `15`).
3. Зробити наступну таку звірку автоматичною (`06 --inventory`).

Поза межами: Windows-скрипти `12`/`13`, скрипт `09`.

---

## A. Скрипт 06 — доопрацювання на місці

Конвенція не змінюється: ідемпотентний інсталятор, `--check` — тільки статус,
звичайний запуск — ставить відсутнє.

### A.1. Виправлення наявних списків

- `python@3.14` — лишається.
- `restic`, `borgbackup` — переносяться з основного списку в опціональні
  (закоментовані) поруч із `macfuse`/`sshfs-mac`; `docs/mount-tools.md`
  оновлюється відповідно («ставиться за потреби»).
- `claude`, `shottr` (casks) — перевірити, що токени cask-ів актуальні
  (`brew info --cask`); виправити, якщо ні.

### A.2. Нові формули (основний список)

- Безпека (поруч із `gitleaks`): `semgrep`, `trivy`, `osv-scanner`.
- Медіа й документи: `ffmpeg`, `pandoc`, `poppler`, `exiftool`
  (прибирати EXIF/GPS із зображень перед комітом).
- Утиліти: `rsync` (сучасний, замість системного), `pstree`, `jq`, `ripgrep`.

### A.3. Нові формули (опціональні, закоментовані)

`ollama` (локальні LLM), `yt-dlp`, `logrotate`, `gcloud-cli` (cask).

### A.4. Node

Після `nvm install --lts` — `corepack enable` (pnpm/yarn без глобальних
встановлень). Помилка — у список `FAILED`, скрипт продовжує.

### A.5. Нові casks

- Основний список: `coteditor`, `stats`, `vlc`, `obsidian`.
- Група «спілкування та віддалений доступ» — вимкнена за замовчуванням,
  вмикається прапорцем `--with-comms`: `zoom`, `telegram`, `whatsapp`,
  `anydesk`, `teamviewer`, `obs`. `--check --with-comms` показує і їх.

### A.6. `--inventory` (тільки читання)

Друкує дві секції:

1. **Є на машині, немає в скрипті:** `brew leaves`, `brew list --cask`,
   `npm ls -g --depth=0` мінус основні + опціональні списки 06.
2. **Є в скрипті, немає на машині.**

Нічого не встановлює, не пише логів. Вивід — тільки назви пакетів (без
шляхів), щоб його можна було безпечно вставити в issue.

### A.7. `--check` + застарілі пакети

Наприкінці `--check` — `brew outdated` по пакетах зі списків скрипта
(тільки звіт).

---

## B. Новий скрипт 14 — git-ідентичності та ssh

`scripts/14_setup_git_identities.sh` + `.md` + `.en.md`.

**Конвенція:** без аргументів — сухий прогін (друкує, що зробив би, і
готову команду з `--apply`); `--apply` — реальні зміни. Пише лог у
`scripts/logs/` → діє правило «першого запуску» (`[y/N]`).

### B.1. Що робить

Для кожної ідентичності (вводиться інтерактивно, можна кілька за запуск):

- коротке ім'я (`slug`, латиниця/цифри/дефіс), git `user.name`,
  `user.email`, папка з репозиторіями цієї ідентичності;
- `~/.gitconfig-<slug>` з `user.name`/`user.email`;
- у `~/.gitconfig` — `[includeIf "gitdir:<папка>/"] path = ~/.gitconfig-<slug>`;
- ssh-ключ `~/.ssh/id_ed25519_<slug>`, якщо його немає (`ssh-keygen`
  інтерактивно, passphrase — тільки там, ніколи аргументом);
- блок у `~/.ssh/config`:
  `Host github-<slug>` → `HostName github.com`, `User git`,
  `IdentityFile`, `IdentitiesOnly yes`, `UseKeychain yes`,
  `AddKeysToAgent yes`;
- наприкінці — друкує публічний ключ, підказку `gh ssh-key add` і приклад
  remote: `git@github-<slug>:<org>/<repo>.git`.

Додатково, один раз на машину:

- `Host *` з `ControlMaster auto`, `ControlPath ~/.ssh/cm-%C`,
  `ControlPersist 10m` — тільки якщо у `~/.ssh/config` немає власного
  `ControlMaster`;
- глобальний gitignore: `core.excludesfile = ~/.gitignore_global` з
  `.DS_Store`, `.idea/`, `.vscode/`, `*.swp`. Якщо `core.excludesfile` вже
  задано — дописує відсутні рядки в наявний файл, не перевизначає.

### B.2. Безпека змін

- Перед першою зміною — бекап `~/.gitconfig` і `~/.ssh/config` поруч
  (`.bak-YYYY-MM-DD-HHMMSS`).
- Усі вставки — блоками з маркерами
  `# >>> vps-infra-public 14 <slug> >>>` / `# <<< … <<<`: повторний
  запуск оновлює блок, а не дублює.
- Наявні ключі, файли `~/.gitconfig-<slug>` і чужі блоки — не
  перезаписуються; конфлікт → попередження + у список помилок.
- `chmod 600` на `~/.ssh/config`, `700` на `~/.ssh`.

---

## C. Новий скрипт 15 — shell і налаштування macOS

`scripts/15_setup_shell_and_macos.sh` + `.md` + `.en.md`.

**Конвенція:** як у 14 — сухий прогін / `--apply`, лог у `scripts/logs/`,
«перший запуск».

### C.1. zsh (`~/.zshrc`, блок із маркерами)

- Історія: `APPEND_HISTORY`, `INC_APPEND_HISTORY`, `SHARE_HISTORY`,
  `HIST_IGNORE_DUPS`, `HIST_IGNORE_SPACE`.
- Android SDK: `ANDROID_HOME=$HOME/Library/Android/sdk` + `emulator`,
  `platform-tools`, `cmdline-tools/latest/bin` у `PATH` — тільки якщо
  папка SDK існує (або прапорець `--android`).
- Опціонально (`--with-docker-aliases`): `dcu`/`dcd`/`dcl`/`dps` для
  `docker compose`.
- Бекап `~/.zshrc` перед зміною.

### C.2. macOS `defaults`

- Finder: показувати всі розширення файлів.
- Finder: показувати приховані файли.
- Finder: повний шлях у заголовку вікна + рядок шляху.
- Скріншоти: папка запитується інтерактивно (за замовчуванням
  `~/Pictures/Screenshots`), створюється, якщо немає.

Сухий прогін показує поточне значення → нове. Після `--apply` —
`killall Finder` / `killall SystemUIServer` тільки якщо щось змінилося.

---

## D. Критерії готовності

- `bash -n` і `shellcheck` чисті (виняток — задокументоване попередження
  info-рівня, як у 06).
- Сухий прогін 14/15 не змінює жодного файлу (звірка контрольних сум
  `~/.gitconfig`, `~/.ssh/config`, `~/.zshrc` до/після).
- Повторний `--apply` нічого не змінює (ідемпотентність).
- `06 --check` і `06 --inventory` нічого не встановлюють.
- У коді, доках і прикладах — жодних реальних імен акаунтів, email,
  хостів, абсолютних шляхів (санітизація за `CLAUDE.md`).
- Документація: `NN_name.md` + `NN_name.en.md` для 14 і 15; оновлено
  `06_setup_new_dev_mac.md`/`.en.md`, `docs/mount-tools.md`/`.en.md`.
- Нові рядки 14/15 у `SCRIPTS_CHECKLIST.md`/`.en.md`; таблиця в
  `README.md`/`README.en.md`; `CHANGELOG.md`/`.en.md` → `0.2.0`;
  `package.json` → `0.2.0` + npm-скрипти для 14/15.

## E. Порядок робіт і оцінка

1. A (06: списки, `--with-comms`, `corepack`, `--inventory`, outdated) · ~2.5 год
2. B (14: git-ідентичності + ssh + глобальний gitignore) · ~2.5 год
3. C (15: zsh + Android + defaults) · ~1.5 год
4. D (доки uk/en, чекліст, README, CHANGELOG, перевірки) · ~1 год

## F. Рішення, прийняті при узгодженні (2026-11-03)

- Склад: усі групи — A.1–A.7, B, C.
- Налаштування оточення — два окремі скрипти: 14 (git/ssh), 15 (shell/macOS).
- `restic`/`borgbackup` — в опціональні.
- Python — `python@3.14`.
- Група «спілкування» — опціонально, прапорцем `--with-comms`.
- `defaults` — усі чотири пункти C.2.

**Взято за замовчуванням (можна змінити до старту реалізації):**
глобальний gitignore і `ControlMaster` — у 14; Android і docker-аліаси — у
15; docker-аліаси вимкнені за замовчуванням.
