# Changelog

**[English version](./CHANGELOG.en.md)**

Формат — [Keep a Changelog](https://keepachangelog.com/), версії — [SemVer](https://semver.org/).

## [0.2.0] — 2026-09-13

### Додано

- `14_reduce_windows_bloat.ps1` + `.md`/`.en.md` — новий скрипт: вимикає
  рекламу/підказки в Пуску, авто-запуск OneDrive, Cortana/Bing-результати
  в пошуку, Widgets, tailored experiences/рекламний ID, Spotlight на
  екрані блокування (профіль `-UserName` + Default-шаблон), плюс
  телеметрію на рівні машини (`AllowTelemetry`, служба `DiagTrack`,
  `dmwappushsvc`). Свідомо консервативний — не чіпає Windows Update,
  Defender, попередньо встановлені застосунки. Dry-run/`-Apply` +
  `-Remove` для відкату, той самий конвенції, що й `12`/`13`.
- `12_create_dev_user.ps1` — прапорець `-Remove` (з `-Apply` для реального
  застосування, як і в `-Apply` для створення): відкат, видаляє
  ізольований акаунт. Питає підтвердження щоразу (не тільки при першому
  запуску скрипта, як для створення) — видалення незворотне на кожному
  прогоні. Не видаляє профільну папку/файли акаунта — це залишається
  ручним кроком.
- `13_setup_dev_environment.ps1` — прапорець `-Remove`: відкат,
  `winget uninstall` для всього з `$Packages`, що встановлено. Питає
  підтвердження щоразу. Git identity і SSH-ключ не чіпає.

### Виправлено

- `12_create_dev_user.ps1`, `14_reduce_windows_bloat.ps1` — `Add-Content`
  для файлу логу тепер пише з `-Encoding UTF8` явно (типово писав у
  системну кодову сторінку без BOM — на реальному прогоні виявлено, що
  кирилицю/em dash в логах після цього неможливо коректно прочитати
  інструментом, який очікує UTF-8).
- `12_create_dev_user.ps1`, `13_setup_dev_environment.ps1` — реальний баг:
  файли без UTF-8 BOM з em dash усередині рядкових літералів ламали
  парсинг Windows PowerShell 5.1 на машинах, де мова для програм без
  Unicode виставлена на кирилицю (типово для української локалі Windows),
  з помилкою `The string is missing the terminator: "`. Виправлено
  додаванням UTF-8 BOM до обох файлів — відтворено і перевірено реальним
  запуском (не тільки парсингом), а не лише навмання.
- `13_setup_dev_environment.ps1` — перевірки git identity/SSH-ключа тепер
  спочатку перевіряють, що `git`/`ssh-keygen` взагалі є (`Get-Command`),
  замість того щоб сипати `CommandNotFoundException`, якщо відповідний
  інсталятор ще не спрацював (типова ситуація на щойно встановленій
  системі до першого успішного `winget install`).
- `12_create_dev_user.ps1` — ще один реальний баг, знайдений на живому
  прогоні від користувача: групи `Administrators`/`Users` шукалися по
  жорсткій англійській назві, а на локалізованій Windows (RU/UA) вони
  фізично називаються «Администраторы»/«Пользователи» — `Add-LocalGroupMember
  : Группа Users не найдена`. Виправлено пошуком груп за
  well-known SID (`S-1-5-32-544`/`S-1-5-32-545`) замість імені —
  локале-незалежно. Заразом: якщо акаунт уже існує і передано `-Apply`,
  скрипт раніше просто вигодив (`[skip]`, exit) без перевірки групи —
  тепер він все одно доганяє членство в групах, щоб можна було
  безпечно перезапустити після саме такого часткового збою.

### Змінено

- `12_create_dev_user.ps1` — повідомлення про відсутність прав
  адміністратора тепер друкує покрокову інструкцію (як відкрити
  PowerShell від адміністратора), а не лише одну строку.
- `13_setup_dev_environment.ps1` — додано перевірку: якщо скрипт
  запущено від адміністратора, друкує попередження і (поза `-Check`)
  питає підтвердження, бо це суперечить задуманому запуску від імені
  цільового користувача. Повідомлення про відсутній `winget` тепер
  містить конкретні кроки виправлення (Microsoft Store або пряме
  завантаження з офіційної сторінки релізів winget-cli).
- `scripts/12_create_dev_user.md`/`.en.md`,
  `scripts/13_setup_dev_environment.md`/`.en.md` — розділ «Типові
  проблеми»/`Troubleshooting` (execution policy, права адміністратора,
  відсутній `winget`, порядок двох сесій).
- `README.md`/`README.en.md` — розділ «Швидкий старт на чистій
  Windows-машині»: явний покроковий порядок 12 → перелогін → 13 з
  поясненням, чому це дві сесії, а не одна команда.

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
