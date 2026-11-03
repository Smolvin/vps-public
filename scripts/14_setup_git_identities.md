# 14_setup_git_identities.sh

**[English version](./14_setup_git_identities.en.md)**

Кілька git-ідентичностей на одному Mac (наприклад, особиста + по одній на
кожного клієнта чи роботодавця), у кожної — свій SSH-ключ для GitHub.
Репозиторії в папці ідентичності автоматично комітять від її імені, а
remote виду `git@github-<slug>:<org>/<repo>.git` ходять з її ключем.

Див. `SCRIPTS_CHECKLIST.md` №14. Специфікація —
[`docs/specs/mac-onboarding-0.2.md`](../docs/specs/mac-onboarding-0.2.md), розділ B.

## Запуск

```bash
cd scripts
./14_setup_git_identities.sh            # сухий прогін: питає ідентичності, друкує план, нічого не змінює
./14_setup_git_identities.sh --apply    # реально застосувати
./14_setup_git_identities.sh --help
```

Ідентичності вводяться інтерактивно (можна кілька за запуск):

| Поле | Приклад | Навіщо |
|---|---|---|
| slug | `client-a` | Ім'я у файлах (`~/.gitconfig-client-a`, `~/.ssh/id_ed25519_client-a`) і в аліасі хоста `github-client-a`. Латиниця, цифри, дефіс. |
| `user.name` | `Jane Doe` | Ім'я автора комітів. |
| `user.email` | `jane@client-a.example` | Email автора комітів і мітка SSH-ключа. |
| папка | `~/work/client-a` | Усі репозиторії всередині комітять від цієї ідентичності. |

**Перший запуск будь-коли** (немає жодного логу
`scripts/logs/14_setup_git_identities_*.log`) друкує попередження і
запитує підтвердження — див. «конвенція перший запуск» у
`SCRIPTS_CHECKLIST.md`. Спрацьовує один раз, включно з сухим прогоном.

## Що змінює

Для кожної ідентичності:

1. `~/.gitconfig-<slug>` — `[user] name/email`.
2. `~/.gitconfig` — `[includeIf "gitdir:<папка>/"] path = ~/.gitconfig-<slug>`
   (через `git config`, шляхи під домашньою папкою — з `~`).
3. `~/.ssh/id_ed25519_<slug>` — новий ключ, якщо його ще немає
   (`ssh-keygen` сам запитає passphrase) + додавання в Keychain.
4. `~/.ssh/config` — блок:

   ```
   Host github-<slug>
       HostName github.com
       User git
       IdentityFile ~/.ssh/id_ed25519_<slug>
       IdentitiesOnly yes
       UseKeychain yes
       AddKeysToAgent yes
   ```

Один раз на машину:

- `~/.ssh/config` — `Host *` з `ControlMaster auto`,
  `ControlPath ~/.ssh/cm-%C`, `ControlPersist 10m` (одне SSH-з'єднання на
  хост 10 хвилин — швидші `git fetch`/`push`). Пропускається, якщо в
  конфігу вже є свій `ControlMaster`.
- Глобальний gitignore: `core.excludesfile = ~/.gitignore_global` з
  `.DS_Store`, `.idea/`, `.vscode/`, `*.swp`. Якщо `core.excludesfile` уже
  задано — дописує відсутні рядки у той файл, не перевизначає.

Наприкінці друкує публічні ключі нових ідентичностей, команду
`gh ssh-key add` і приклади `git clone`/`git remote set-url` через аліас.

## Безпека змін

- Перед першою зміною файлу — копія поруч: `<файл>.bak-YYYY-MM-DD-HHMMSS`.
- Вставки в `~/.ssh/config` і gitignore — блоки з маркерами
  `# >>> vps-infra-public 14 <id> >>>` … `# <<< … <<<`. Повторний запуск
  оновлює блок на місці, а не дублює; якщо змінювати нічого — файл не
  чіпається.
- Не перезаписує: наявні ключі, `~/.gitconfig-<slug>` з іншим
  ім'ям/email, `Host github-<slug>`, написаний вручну. Такий конфлікт —
  попередження + рядок у підсумку, скрипт іде далі.
- `~/.ssh` — `chmod 700`, `~/.ssh/config` — `chmod 600`.
- Passphrase вводиться тільки в `ssh-keygen`, ніколи не аргументом.

## Як перевірити

```bash
cd ~/work/client-a/some-repo && git config user.email   # email ідентичності
ssh -T git@github-client-a                              # "Hi <account>! ..."
```

## Як відкотити

Відновити файли з `.bak-*` поруч або видалити блоки між маркерами
`vps-infra-public 14` і рядок `includeIf` у `~/.gitconfig`
(`git config --global --unset-all 'includeIf.gitdir:<папка>/.path'`).
Ключі `~/.ssh/id_ed25519_<slug>` скрипт не видаляє ніколи.
