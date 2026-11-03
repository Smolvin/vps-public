# 15_setup_shell_and_macos.sh

**[English version](./15_setup_shell_and_macos.en.md)**

Дрібні, але щоденно корисні налаштування dev-Mac: історія zsh, змінні
Android SDK, вигляд Finder і папка для скріншотів.

Див. `SCRIPTS_CHECKLIST.md` №15. Специфікація —
[`docs/specs/mac-onboarding-0.2.md`](../docs/specs/mac-onboarding-0.2.md), розділ C.

## Запуск

```bash
cd scripts
./15_setup_shell_and_macos.sh                              # сухий прогін: поточне -> нове, нічого не змінює
./15_setup_shell_and_macos.sh --apply                      # реально застосувати
./15_setup_shell_and_macos.sh --apply --android            # змінні Android, навіть якщо SDK ще не встановлений
./15_setup_shell_and_macos.sh --apply --with-docker-aliases
./15_setup_shell_and_macos.sh --help
```

| Флаг | Опис |
|---|---|
| `--apply` | Реально змінює (за замовчуванням — тільки сухий прогін) |
| `--android` | Додати змінні Android SDK, навіть якщо `~/Library/Android/sdk` ще немає |
| `--with-docker-aliases` | Додати аліаси `dcu`/`dcd`/`dcl`/`dps` для `docker compose` |
| `-h`, `--help` | Довідка |

Скрипт питає одне: папку для скріншотів (за замовчуванням — поточна, якщо
задана, інакше `~/Pictures/Screenshots`).

**Перший запуск будь-коли** (немає жодного логу
`scripts/logs/15_setup_shell_and_macos_*.log`) друкує попередження і
запитує підтвердження — див. «конвенція перший запуск» у
`SCRIPTS_CHECKLIST.md`.

## Що змінює

**`~/.zshrc`** — блоки з маркерами `# >>> vps-infra-public 15 <id> >>>`,
тільки те, чого там ще немає (свої налаштування поза блоками скрипт
бачить і не дублює):

| Блок | Що всередині |
|---|---|
| `zsh-history` | `setopt APPEND_HISTORY INC_APPEND_HISTORY SHARE_HISTORY HIST_IGNORE_DUPS HIST_IGNORE_SPACE` — історія спільна для всіх вікон, пишеться одразу, без повторів; команда з пробілом на початку не зберігається |
| `android` | `ANDROID_HOME=$HOME/Library/Android/sdk` + `emulator`, `platform-tools`, `cmdline-tools/latest/bin` у `PATH`. Тільки якщо SDK встановлений (Android Studio відкривали хоч раз) або з `--android` |
| `docker-aliases` | `dcu` = `docker compose up -d`, `dcd` = `down`, `dcl` = `logs -f`, `dps` = `ps`. Тільки з `--with-docker-aliases` |

**macOS `defaults`:**

| Налаштування | Ключ |
|---|---|
| Finder: показувати всі розширення файлів | `NSGlobalDomain AppleShowAllExtensions` |
| Finder: показувати приховані файли | `com.apple.finder AppleShowAllFiles` |
| Finder: повний шлях у заголовку вікна | `com.apple.finder _FXShowPosixPathInTitle` |
| Finder: рядок шляху внизу вікна | `com.apple.finder ShowPathbar` |
| Скріншоти: папка збереження | `com.apple.screencapture location` |

Сухий прогін показує `поточне -> нове` для кожного пункту. Після
`--apply` Finder / SystemUIServer перезапускаються, тільки якщо щось
справді змінилося.

## Безпека змін

- `~/.zshrc` — копія `~/.zshrc.bak-YYYY-MM-DD-HHMMSS` перед першою зміною.
- Повторний запуск без змін нічого не пише і нічого не перезапускає.
- Один невдалий крок не зупиняє скрипт — підсумок наприкінці.

## Як відкотити

- `~/.zshrc` — відновити з `.bak-*` або видалити блоки між маркерами
  `vps-infra-public 15`.
- `defaults` — `defaults delete <домен> <ключ>` (повернення до
  системного значення), потім `killall Finder` / `killall SystemUIServer`.
