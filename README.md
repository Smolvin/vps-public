# vps-infra-public

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](./LICENSE)
[![Buy Me A Coffee](https://img.shields.io/badge/-Buy_Me_A_Coffee-FFDD00?style=flat&logo=buy-me-a-coffee&logoColor=black)](https://buymeacoffee.com/smolvin)

**[English version](./README.en.md)**

Публічна частина dev-оточення: ідемпотентні онбординг-скрипти для чистої
машини (macOS та Windows) — ізольований не-admin профіль + базовий набір
dev-інструментів. Нічого специфічного для конкретного сервера/проєкту —
загальний, придатний для повторного використання тулінг.

## Скрипти

| № | Платформа | Скрипт | Що робить |
|---|---|---|---|
| 06 | macOS | [`06_setup_new_dev_mac.sh`](./scripts/06_setup_new_dev_mac.md) | Homebrew, VS Code, Node.js, git/GitHub, мобільний стек |
| 09 | macOS | [`09_create_profiles.sh`](./scripts/09_create_profiles.md) | Ізольовані не-admin профілі (`personal`/`work`/`dev`/`sandbox`) |
| 12 | Windows | [`12_create_dev_user.ps1`](./scripts/12_create_dev_user.md) | Ізольований не-admin профіль `dev` |
| 13 | Windows | [`13_setup_dev_environment.ps1`](./scripts/13_setup_dev_environment.md) | Набір dev-інструментів через winget + git identity + SSH-ключ |
| 14 | Windows | [`14_reduce_windows_bloat.ps1`](./scripts/14_reduce_windows_bloat.md) | Прибрати рекламу/підказки/телеметрію Windows (консервативно) |

Типовий порядок на новій машині: спочатку ізольований профіль (`09`/`12`),
потім — залогінившись під ним — інструменти (`06`/`13`).

## Швидкий старт на чистій Windows-машині

Це **дві окремі сесії Windows, не одна команда** — свідоме архітектурне
рішення (ізоляція), а не недогляд: `12` створює окремий акаунт `dev` і
мусить запускатись від адміністратора; `13` ставить інструменти саме в
цей акаунт і мусить запускатись під ним самим — інакше git identity/
SSH-ключ/winget-пакети підуть у профіль адміністратора, а не туди, де
реально будете розробляти.

1. Відкрити PowerShell **від адміністратора** (Win → `PowerShell` →
   правий клік → «Запуск від імені адміністратора»).
2. Якщо з'явиться `cannot be loaded because running scripts is disabled
   on this system` — одноразово дозволити виконання локальних скриптів:
   ```powershell
   Set-ExecutionPolicy -Scope CurrentUser -ExecutionPolicy RemoteSigned
   ```
3. Створити ізольований акаунт `dev` (спочатку сухий прогін — подивитись,
   що зробить, потім реально):
   ```powershell
   cd шлях\до\репозиторію\scripts
   .\12_create_dev_user.ps1
   .\12_create_dev_user.ps1 -Apply
   ```
4. Вийти з поточного акаунта (не просто заблокувати екран) і залогінитись
   під щойно створеним `dev`.
5. У новій сесії, **вже не від адміністратора**, поставити dev-інструменти:
   ```powershell
   cd шлях\до\репозиторію\scripts
   .\13_setup_dev_environment.ps1 -Check     # що вже є / чого нема
   .\13_setup_dev_environment.ps1             # встановити відсутнє
   ```

Якщо щось із цього не спрацювало — обидва скрипти при помилці друкують
конкретні кроки виправлення прямо в консоль; повний список типових
проблем (execution policy, відсутній `winget`, права адміністратора) — у
[`scripts/12_create_dev_user.md`](./scripts/12_create_dev_user.md) і
[`scripts/13_setup_dev_environment.md`](./scripts/13_setup_dev_environment.md),
розділ «Типові проблеми».

## Довідники

- [`docs/mount-tools.md`](./docs/mount-tools.md) — sshfs, `restic mount`,
  `borg mount`, macFUSE (macOS) / WinFsp (Windows): навіщо потрібні та як
  підняти вручну.

## Конвенції

Див. [`CLAUDE.md`](./CLAUDE.md) — канон репозиторію (нумерація скриптів,
санітизація публічних даних, dry-run/`--apply`, коміти),
[`SCRIPTS_CHECKLIST.md`](./SCRIPTS_CHECKLIST.md) — трекінг фактичних
прогонів кожного скрипта, [`ROADMAP.md`](./ROADMAP.md) — задачі/ідеї,
які ще не зроблені.

## Вимоги

- **macOS**-скрипти: Intel або Apple Silicon, права адміністратора для
  частини кроків.
- **Windows**-скрипти: Windows 10 (1809+) або 11, PowerShell, права
  адміністратора для `12_create_dev_user.ps1` (створення акаунта);
  `13_setup_dev_environment.ps1` — від звичайного користувача.

## Контриб'юторам

Хочете додати скрипт, платформу або виправити баг — див.
[`CONTRIBUTING.md`](./CONTRIBUTING.md) (як влаштована нумерація, що
очікується від PR) і [`CLAUDE.md`](./CLAUDE.md) (канон репозиторію
детальніше).

## Ліцензія

[MIT](./LICENSE) — використовуйте, форкайте, змінюйте, вбудовуйте куди
завгодно, зокрема в закриті проєкти. Єдина умова — зберегти
копірайт-примітку і текст ліцензії при розповсюдженні.

## Автор

`Alex Smolvin` — `https://github.com/Smolvin`

## Підтримати проєкт

- [buymeacoffee.com/smolvin](https://buymeacoffee.com/smolvin)
- [send.monobank.ua/jar/6jiZRYv6CA](https://send.monobank.ua/jar/6jiZRYv6CA)
