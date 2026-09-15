# 13_setup_dev_environment.ps1

**[English version](./13_setup_dev_environment.en.md)**

Windows-версія `06_setup_new_dev_mac.sh`: ставить базовий набір
dev-інструментів через `winget` + git identity + опціонально SSH-ключ для
GitHub. Ідемпотентно, одна невдала установка не обвалює весь скрипт.

Див. `SCRIPTS_CHECKLIST.md` №13.

## Запуск

**Під тим користувачем**, для якого налаштовується оточення (наприклад,
`dev`, створеним [`12_create_dev_user.ps1`](./12_create_dev_user.md)) —
не від адміністратора, інакше git identity/SSH-ключ/winget
per-user-пакети потраплять не в той профіль. `winget` сам попросить
elevation тільки для пакетів, яким це дійсно потрібно.

```powershell
.\13_setup_dev_environment.ps1            # встановлення всього набору
.\13_setup_dev_environment.ps1 -Check     # тільки статус, нічого не змінює
.\13_setup_dev_environment.ps1 -Remove    # відкат: видалити встановлені пакети
```

Як і `06_setup_new_dev_mac.sh` (Mac-версія), не пише свій лог у
`scripts/logs/` і не підпорядковується конвенції «перший запуск» —
ідемпотентний інсталятор софту, не мутує наявні акаунти/файли.

## Що встановлюється

Через `winget` (`Test-WingetPackage` — перевірка `winget list --id`,
пропускає вже встановлене):

- Git
- VS Code
- Windows Terminal
- GitHub CLI
- Node.js LTS
- Python 3.12

Плюс:
- Git identity (`user.name`/`user.email`) — запитує, тільки якщо ще не
  налаштовано.
- SSH-ключ (ed25519) для GitHub — за бажанням (`y/N`), не перезаписує
  наявний.

## Як це працює

Одна невдала установка не зупиняє решту — копиться у список `$Failed`,
друкується підсумком наприкінці. Перезапуск перевстановить тільки
відсутнє.

`-Check` проходить по тому самому списку і для кожного пункту друкує
`[OK] <статус>` або `[--] not installed`, нічого не змінюючи.

## Список пакетів — не догма

Базовий набір — НЕ калька з Mac-списку (там мобільний/iOS-стек —
Xcode/CocoaPods/Android Studio/Figma — на Windows більша частина не має
сенсу або недоступна). Спільний знаменник + те, що реально знадобиться —
дописується по факту в `$Packages` на початку скрипта (звичайний масив
хеш-таблиць `Id`/`Name`, нічого не генерується звідкись).

## Відкат (`-Remove`)

Видаляє через `winget uninstall` усе з `$Packages`, що зараз встановлено:

```powershell
.\13_setup_dev_environment.ps1 -Remove
```

- Спочатку друкує повний список пакетів, які зачепить, і питає
  підтвердження `[y/N]` — **щоразу**, це деструктивна дія на кожному
  прогоні, не тільки при першому.
- Пакета нема — `[skip]`. Одна невдала видалка не зупиняє решту (як і
  при встановленні) — підсумок `$RemoveFailed` наприкінці.
- **Не чіпає** git identity і SSH-ключ — тільки самі пакети. Якщо
  потрібно прибрати і їх — вручну (`git config --global --unset
  user.name`/`user.email`, видалити `~\.ssh\id_ed25519*`).

## Вимоги

- Windows 10 (1809+) або Windows 11 — потрібен `winget` (App Installer з
  Microsoft Store, на більшості машин вже стоїть).
- Інтернет-з'єднання.

## Типові проблеми

**`cannot be loaded because running scripts is disabled on this system`**
— виконання `.ps1`-скриптів заблоковано політикою PowerShell (типово на
щойно встановленій системі):

```powershell
Set-ExecutionPolicy -Scope CurrentUser -ExecutionPolicy RemoteSigned
```

Або одноразово: `powershell -ExecutionPolicy Bypass -File .\13_setup_dev_environment.ps1`.

**`winget not found`** — скрипт вивів конкретні кроки прямо в консолі:
поставити/оновити «App Installer» з Microsoft Store, а якщо Store
недоступний — завантажити `.msixbundle` з офіційної сторінки релізів
[winget-cli](https://github.com/microsoft/winget-cli/releases/latest) і
встановити його `Add-AppxPackage`.

**`[warn] Running as Administrator`** — скрипт це детектить сам і питає
підтвердження перед продовженням (з `-Check` — просто попереджає, нічого
не питає, бо нічого не змінює). Правильний варіант — вийти, залогінитись
під потрібним користувачем (напр. `dev`, створеним
[`12_create_dev_user.ps1`](./12_create_dev_user.md)) і запустити звідти.

**Помилки `CommandNotFoundException` за git/ssh-keygen під час
встановлення** — скрипт перевіряє наявність `git`/`ssh-keygen` перед тим,
як їх використовувати, і акуратно пропускає відповідний крок (`[skip]`),
якщо інструмент ще не з'явився (наприклад, установка `Git` через `winget`
не вдалась — немає інтернету чи корпоративна політика блокує пакет).
Перечитайте підсумок `$Failed` наприкінці виводу і перезапустіть скрипт
після усунення причини — він довстановить лише те, чого не вистачає.
