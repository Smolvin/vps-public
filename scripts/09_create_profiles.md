# 09_create_profiles.sh

**[English version](./09_create_profiles.en.md)**

Створює стандартні (не-admin) рольові профілі macOS: `personal`, `work`,
`dev`, `sandbox`.

Див. `SCRIPTS_CHECKLIST.md` №9.

## Запуск

Потребує `sudo` — створення акаунтів потребує root/admin-прав, причому
вже на етапі dry-run (перевірка йде до розгалуження по `--apply`).

```bash
cd scripts
sudo ./09_create_profiles.sh                          # dry run, усі 4 профілі
sudo ./09_create_profiles.sh --apply                   # реально створити всі 4
sudo ./09_create_profiles.sh --apply --only work        # створити тільки один
sudo ./09_create_profiles.sh --apply --filevault        # + реєстрація в FileVault unlock-list
```

**Перший запуск будь-коли** (немає жодного логу
`scripts/logs/*create_profiles*.log`) додатково друкує попередження і
запитує підтвердження перед тим, як продовжити — див. «конвенція перший
запуск» у `SCRIPTS_CHECKLIST.md`. Спрацьовує один раз за все життя
скрипта, включно з dry-run.

| Флаг | Опис |
|---|---|
| `--apply` | Реально створює акаунти (за замовчуванням — тільки dry run, друк) |
| `--filevault` | Після створення кожного акаунта реєструє його в FileVault unlock-list (`fdesetup add -usertoadd`) — запросить пароль наявного FileVault-admin |
| `--only <name>` | Обробити тільки один профіль: `personal` \| `work` \| `dev` \| `sandbox` |
| `-h`, `--help` | Показати довідку |

## Як це працює

1. Перевіряє, що запущено під `sudo` — інакше одразу помилка з
   підказкою.
2. Якщо це перший запуск за весь час (див. вище) — запитує
   підтвердження; відмова перериває виконання, нічого не створюється і
   не логується. Після підтвердження (або при будь-якому наступному
   запуску) починає писати лог у
   `scripts/logs/09_create_profiles_<timestamp>.log`.
3. Для кожного профілю (`personal:Personal`, `work:Work`, `dev:Dev`,
   `sandbox:Sandbox`): якщо акаунт вже існує — `[skip]`, не чіпає.
4. Інакше: `sysadminctl -addUser <username> -fullName "<FullName>" -home
   /Users/<username> -shell /bin/zsh -password -` — пароль вводиться
   інтерактивно й безпечно (флаг `-password -` змушує `sysadminctl`
   запитати пароль, а не приймати його як argv-аргумент, який був би
   видно в списку процесів/історії).
5. Якщо створений акаунт несподівано потрапив у групу `admin` —
   автоматично прибирає його звідти: архітектура очікує рівно одного
   admin-акаунта, решта — standard users.
6. При `--filevault` — додатково реєструє акаунт у FileVault
   unlock-list.

## Обмеження

- Ідемпотентний: наявні акаунти не чіпає, безпечно перезапускати.
- Не налаштовує Finder/Dock тощо під новим профілем.
- Не створює SSH-ключі/git-identity для нових профілів — для цього
  залогіньтеся під новим профілем і прогоніть
  [`06_setup_new_dev_mac.sh`](./06_setup_new_dev_mac.md).

## Список профілів — не догма

`PROFILES` на початку скрипта — простий масив `username:FullName`.
Приберіть непотрібні ролі або додайте свої, більше нічого міняти не
потрібно.
