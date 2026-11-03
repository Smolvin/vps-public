# 06_setup_new_dev_mac.sh

**[English version](./06_setup_new_dev_mac.en.md)**

Онбординг-скрипт для чистого macOS: ставить робочий набір інструментів для
розробки (Homebrew, Node.js, VS Code, Docker, мобільний стек, Git/GitHub).

Базовий список софта взятий з реальної робочої dev-машини — універсальний,
підходить і для налаштування ізольованого профілю `dev` (див.
`09_create_profiles.sh`), і для окремої машини нового розробника.

Див. `SCRIPTS_CHECKLIST.md` №6.

## Запуск

```bash
cd scripts
chmod +x 06_setup_new_dev_mac.sh
```

| Команда | Що робить |
|---|---|
| `./06_setup_new_dev_mac.sh` | Повне встановлення всього набору (див. нижче). Безпечно перезапускати. |
| `./06_setup_new_dev_mac.sh --with-comms` | Те саме + застосунки для спілкування й віддаленого доступу (Zoom, Telegram, WhatsApp, AnyDesk, TeamViewer, OBS). |
| `./06_setup_new_dev_mac.sh --check` | Нічого не встановлює — показує, що вже стоїть, чого немає, і які пакети зі списків застаріли (`brew outdated`). З `--with-comms` перевіряє і групу спілкування. |
| `./06_setup_new_dev_mac.sh --inventory` | Тільки читання: що стоїть на машині, але відсутнє в скрипті, і навпаки. |
| `./06_setup_new_dev_mac.sh --rclone-only` | Ставить тільки rclone (і Homebrew, якщо його немає). |
| `./06_setup_new_dev_mac.sh --help` | Коротка довідка щодо флагів. |

`--check`, `--inventory` і `--rclone-only` взаємовиключні; `--with-comms`
поєднується зі звичайним запуском і з `--check`.

## Як це працює

Скрипт ідемпотентний: перед встановленням кожного компонента перевіряє, чи
стоїть він вже, і пропускає його, якщо так. Його можна запускати скільки
завгодно разів — він або нічого не зробить (усе вже стоїть), або
доставить відсутнє.

Якщо застосунок зі списку casks уже стоїть у `/Applications`, але не через
Homebrew (поставлений з `.dmg` чи App Store), скрипт його не чіпає і
підказує `brew install --cask --adopt <name>`, щоб передати його під
керування Homebrew.

Якщо один конкретний пакет не встановлюється (помилка мережі, конфлікт
тощо), скрипт **не падає цілком** — пише попередження, відкладає цей
пункт у список і йде далі. Наприкінці друкується підсумок, що саме не
встановилося, щоб можна було розібратися і перезапустити скрипт.

Порядок кроків при звичайному запуску:

1. **Xcode Command Line Tools** — перевірка/встановлення (потрібні
   Homebrew, git, CocoaPods, компіляторам).
2. **Homebrew** — встановлення, якщо його немає, плюс `brew update`.
3. **Homebrew formulae**:
   - базові: `git`, `gh`, `nvm`, `python@3.14`, `php`, `mkcert`,
     `shellcheck`, `imagemagick`, `rclone`;
   - мобільний стек: `cocoapods`, `openjdk@17`, `watchman`;
   - безпека: `gitleaks`, `semgrep`, `trivy`, `osv-scanner`;
   - медіа й документи: `ffmpeg`, `pandoc`, `poppler`, `exiftool`
     (прибирати EXIF/GPS із зображень перед комітом);
   - утиліти: `rsync` (сучасний замість системного), `pstree`, `jq`,
     `ripgrep`.
4. **Homebrew casks (застосунки)**: VS Code, iTerm2, Docker Desktop,
   Chrome, Firefox Developer Edition, Android Studio, Figma, Postman,
   Claude, Shottr, CotEditor, Stats, VLC, Obsidian. З `--with-comms` —
   ще Zoom, Telegram, WhatsApp, AnyDesk, TeamViewer, OBS.
5. **Node.js через nvm** — ставить останню LTS-версію, робить її версією
   за замовчуванням, вмикає corepack (pnpm/yarn без глобальних
   встановлень), ставить глобальні npm-пакети зі списку `NPM_GLOBALS`
   (зараз — `eas-cli`).
6. **Java** — лінкує `openjdk@17` у `/Library/Java/JavaVirtualMachines`,
   щоб його знаходив `/usr/libexec/java_home` (потрібно для
   Android/Gradle).
7. **Git / GitHub** — питає `user.name`/`user.email`, якщо не задані; за
   бажанням генерує SSH-ключ (ed25519) для GitHub і друкує публічний
   ключ для додавання в акаунт; за бажанням запускає `gh auth login`.
   Кілька git-ідентичностей з окремими ключами — див.
   [`14_setup_git_identities.sh`](./14_setup_git_identities.md).
8. **Мобільна розробка** — друкує, що доставити руками (Xcode і
   TestFlight ставляться тільки з App Store і потребують входу з Apple
   ID — автоматизувати це скриптом не можна).
9. **Підсумок** — виводить версії встановлених інструментів, список
   того, що не встановилося (якщо було), і наступні кроки (`14`, `15`).

`--check` проходить по тому самому списку (формули, кейси, node/npm,
глобальні npm-пакети, pnpm через corepack, Java-симлінк, `code` CLI,
docker, git-конфіг, SSH-ключ, `gh auth status`) і для кожного пункту
друкує `[OK] <версія>` або `[--] not installed`. Наприкінці — пакети зі
списків скрипта, для яких є новіша версія (`[UP] <name>`), за локальним
індексом Homebrew. Нічого не змінює в системі.

`--inventory` порівнює машину зі списками скрипта (включно з
опціональними) і друкує дві секції:

1. **Є на машині, немає в скрипті** — `brew leaves`, casks, `npm -g`:
   кандидати, щоб додати в скрипт.
2. **Є в основних списках скрипта, немає на машині** — плюс окремо
   застосунки, які стоять, але не через Homebrew.

Вивід — тільки назви пакетів, без шляхів: його можна вставити в issue.

## Що не встановлюється автоматично

- **Xcode (повний IDE) і TestFlight** — тільки через App Store, потрібен
  вхід з Apple ID.
- **`code` CLI** — команда `code` у терміналі з'являється тільки після
  того, як один раз відкрити VS Code і виконати `Cmd+Shift+P` →
  *Shell Command: Install 'code' command in PATH*.
- **Docker Desktop** — після встановлення cask потрібно один раз
  відкрити застосунок і прийняти умови використання.
- **Опціональні пакети** — списки `OPTIONAL_FORMULAE`/`OPTIONAL_CASKS` у
  скрипті ніколи не ставляться автоматично (їх знає тільки
  `--inventory`). Щоб ставити котрийсь за замовчуванням — перенесіть його
  в `FORMULAE`/`CASKS`:
  - `restic`, `borgbackup` — backup-інструменти;
  - `ollama` (локальні LLM), `yt-dlp`, `logrotate`;
  - VPN-клієнт `wireguard-tools` / `wireguard`;
  - `gcloud-cli` (Google Cloud SDK);
  - `macfuse` і `sshfs` через `gromgit/fuse/sshfs-mac` — потребують
    схвалення системного розширення.

  Подробиці про `macfuse`/`sshfs`/`restic mount`/`borg mount` (що це,
  навіщо, як вручну підняти на macOS і Windows) —
  [`../docs/mount-tools.md`](../docs/mount-tools.md).

## Вимоги

- macOS (Intel або Apple Silicon).
- Інтернет-з'єднання.
- Права адміністратора (потрібні для встановлення Xcode CLT, Homebrew і
  для `sudo`-симлінка Java).

## Адаптація під свій список софта

Списки на початку скрипта (`FORMULAE`, `CASKS`, `COMMS_CASKS`,
`NPM_GLOBALS`, `OPTIONAL_*`) — не догма, а відправна точка, скопійована з
реальної робочої машини. Приберіть мобільний стек
(`cocoapods`/`openjdk@17`/`watchman`/`android-studio`), якщо він вам не
потрібен, додайте своє. Що додати — підкаже `--inventory` на вашій
робочій машині.
