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

Типовий порядок на новій машині: спочатку ізольований профіль (`09`/`12`),
потім — залогінившись під ним — інструменти (`06`/`13`).

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
