# Інструменти монтування: sshfs, `restic mount`, `borg mount`, macFUSE/WinFsp

**[English version](./mount-tools.en.md)**

Довідка до пакетів зі списку [`06_setup_new_dev_mac.sh`](../scripts/06_setup_new_dev_mac.md).
Усі вони — в опціональних списках (`OPTIONAL_FORMULAE`/`OPTIONAL_CASKS`:
`restic`, `borgbackup`, `macfuse`, `sshfs-mac`) і за замовчуванням не
ставляться — ставте за потреби (`brew install <name>`) або перенесіть в
основний список скрипта. Спільна тема — всі три інструменти дають доступ до "не
зовсім звичайних" даних (віддалена папка по SSH, вміст бекап-архіву) як
до звичайної файлової системи, яку можна відкрити у Finder/Explorer або
обійти будь-якою програмою, а не тільки спеціальним CLI.

## Навіщо це взагалі — FUSE і його аналог на Windows

Ні macOS, ні Windows не вміють із коробки монтувати файлову систему,
реалізовану звичайною user-space програмою (на відміну від Linux, де FUSE
вбудований у ядро). Для цього потрібен окремий компонент:

- **macOS — [macFUSE](https://macfuse.org/)**: встановлює system
  extension, яка і дає userspace-програмам це право.
- **Windows — [WinFsp](https://winfsp.dev/)**: концептуально те саме, але
  вбудовується через підписаний kernel-драйвер поверх звичайного
  MSI-інсталятора — без окремого кроку схвалення в налаштуваннях (див.
  нижче, різниця суттєва).

Самі по собі macFUSE/WinFsp нічого не роблять — це інфраструктура, яку
використовують конкретні інструменти (sshfs, `rclone mount`,
`restic mount`, `borg mount` тощо).

## sshfs — примонтувати папку з віддаленого сервера по SSH

Показує вміст директорії на іншій машині (доступній по SSH) як звичайну
локальну папку — читати/писати файли можна будь-якою програмою, без
`scp`/`rsync` на кожен чих.

### macOS

```bash
# Homebrew core прибрав формулу sshfs напряму (ліцензійні причини
# macFUSE) — робоча заміна зараз це сторонній tap:
brew install --cask macfuse
brew install gromgit/fuse/sshfs-mac
```

Після встановлення — обов'язковий ручний крок, див. розділ про macFUSE
нижче (без нього `sshfs` у рантаймі впаде з помилкою про недоступний
FUSE-девайс).

```bash
mkdir -p ~/mnt/remote
sshfs user@host:/path/on/remote ~/mnt/remote
# ...
umount ~/mnt/remote   # відмонтувати
```

### Windows

```powershell
winget install --id SSHFS-Win.SSHFS-Win
```

`WinFsp` підтягується автоматично як залежність — окремо ставити не
потрібно. Після встановлення том можна примонтувати через Explorer
(`net use`) або `net use X: \\sshfs\user@host`. Подробиці — [README
проєкту sshfs-win](https://github.com/winfsp/sshfs-win).

## `restic mount` / `borg mount` — відкрити бекап-архів як файлову систему

І [restic](https://restic.readthedocs.io/), і
[BorgBackup](https://borgbackup.readthedocs.io/) — CLI-інструменти для
бекапів з дедуплікацією; сама програма і звичайний бекап/відновлення
(`restic backup`/`restic restore`, `borg create`/`borg extract`)
працюють **без** macFUSE/WinFsp взагалі. FUSE потрібен тільки для окремої
`mount`-підкоманди — подивитися вміст снапшоту/архіву як звичайну папку,
не відновлюючи його цілком на диск:

```bash
# restic
restic -r /path/to/repo mount ~/mnt/restic
# усередині ~/mnt/restic з'являться папки snapshots/<id>/... для кожного снапшоту
# Ctrl+C або umount ~/mnt/restic, коли закінчили

# borg
borg mount /path/to/repo::archive-name ~/mnt/borg
# ...
umount ~/mnt/borg
```

Зручно, коли потрібно знайти один файл у старому снапшоті або порівняти
версії між кількома — швидше, ніж `restic restore`/`borg extract`
цілком і шукати руками.

**Windows**: restic ставиться через `winget install --id restic.restic` і
працює для backup/restore без проблем; `restic mount` на Windows теж
потребує WinFsp (той самий принцип, що і sshfs вище — `winget install
--id WinFsp.WinFsp`, явний `--id` обов'язковий, коротке ім'я інколи
резолвиться в бета-версію). BorgBackup офіційно не підтримує нативний
Windows — для `borg mount` там потрібен WSL (підсистема Linux),
нативного winget-пакета немає.

## Як вручну підняти macFUSE (macOS)

1. `brew install --cask macfuse` (або завантажити інсталятор з
   [macfuse.org](https://macfuse.org/)) і запустити його.
2. macOS покаже "System Extension Blocked" — відкрити System Settings за
   посиланням із цього діалогу (або вручну: **Sequoia (15) і новіше** —
   Login Items & Extensions; **старіші версії** — Privacy & Security).
3. Знайти пункт про розробника **"Benjamin Fleischer"**, натиснути
   **Allow**, ввести пароль.
4. Перезавантажити Mac.

**На Apple Silicon** — два різних шляхи залежно від того, який backend
використовує встановлена версія macFUSE:
- **Рекомендований (сучасні версії macFUSE, backend FSKit)** — нічого
  додатково міняти не потрібно, тільки кроки 1–4 вище.
- **Старий шлях (legacy kext backend)** — додатково потрібен Startup
  Security Utility (перезавантаження в Recovery, `⌘` при старті) →
  знизити політику безпеки до **Reduced Security** → увімкнути "Allow
  user management of kernel extensions from identified developers".
  Перевірте, який backend використовує ваша версія — якщо після кроків
  1–4 все вже працює, другий шлях не потрібен.

## Як вручну підняти WinFsp/SSHFS-Win (Windows)

Простіше, ніж на macOS — Windows не потребує окремого походу в
налаштування після встановлення, звичайний MSI + UAC-підтвердження
достатньо:

```powershell
winget install --id WinFsp.WinFsp
# для sshfs конкретно — тягне WinFsp сам як залежність, окремо ставити не обов'язково:
winget install --id SSHFS-Win.SSHFS-Win
```

Важливо вказувати повний `--id` (`WinFsp.WinFsp`, не просто `winfsp`) —
відома проблема winget: коротке ім'я інколи резолвиться в
`WinFsp.WinFsp.Beta` замість стабільної версії.

Після встановлення перезавантаження зазвичай не потрібне — драйвер
підхоплюється одразу, максимум може знадобитися перезапуск
Explorer/сесії, якщо том не з'явився з першого разу.
