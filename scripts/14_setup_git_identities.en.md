# 14_setup_git_identities.sh

**[Українська версія](./14_setup_git_identities.md)**

Several git identities on one Mac (for example, a personal one + one per
client or employer), each with its own SSH key for GitHub. Repositories
in an identity's folder automatically commit as that identity, and
remotes of the form `git@github-<slug>:<org>/<repo>.git` use its key.

See `SCRIPTS_CHECKLIST.md` #14. Spec —
[`docs/specs/mac-onboarding-0.2.en.md`](../docs/specs/mac-onboarding-0.2.en.md), section B.

## Running it

```bash
cd scripts
./14_setup_git_identities.sh            # dry run: asks for identities, prints the plan, changes nothing
./14_setup_git_identities.sh --apply    # really apply
./14_setup_git_identities.sh --help
```

Identities are entered interactively (several per run allowed):

| Field | Example | Why |
|---|---|---|
| slug | `client-a` | Name in files (`~/.gitconfig-client-a`, `~/.ssh/id_ed25519_client-a`) and in the host alias `github-client-a`. Latin letters, digits, hyphen. |
| `user.name` | `Jane Doe` | Commit author name. |
| `user.email` | `jane@client-a.example` | Commit author email and SSH key label. |
| folder | `~/work/client-a` | All repositories inside commit as this identity. |

**The first run ever** (no `scripts/logs/14_setup_git_identities_*.log`
yet) prints a warning and asks for confirmation — see the "first run
convention" in `SCRIPTS_CHECKLIST.en.md`. Triggers once, dry run included.

## What it changes

For each identity:

1. `~/.gitconfig-<slug>` — `[user] name/email`.
2. `~/.gitconfig` — `[includeIf "gitdir:<folder>/"] path = ~/.gitconfig-<slug>`
   (via `git config`; paths under the home folder are stored with `~`).
3. `~/.ssh/id_ed25519_<slug>` — a new key if there isn't one yet
   (`ssh-keygen` asks for the passphrase itself) + added to the Keychain.
4. `~/.ssh/config` — a block:

   ```
   Host github-<slug>
       HostName github.com
       User git
       IdentityFile ~/.ssh/id_ed25519_<slug>
       IdentitiesOnly yes
       UseKeychain yes
       AddKeysToAgent yes
   ```

Once per machine:

- `~/.ssh/config` — `Host *` with `ControlMaster auto`,
  `ControlPath ~/.ssh/cm-%C`, `ControlPersist 10m` (one SSH connection per
  host for 10 minutes — faster `git fetch`/`push`). Skipped if the config
  already has its own `ControlMaster`.
- Global gitignore: `core.excludesfile = ~/.gitignore_global` with
  `.DS_Store`, `.idea/`, `.vscode/`, `*.swp`. If `core.excludesfile` is
  already set — appends the missing lines to that file, doesn't override.

At the end it prints the public keys of new identities, a
`gh ssh-key add` command and `git clone`/`git remote set-url` examples
through the alias.

## Change safety

- Before a file's first change — a copy alongside:
  `<file>.bak-YYYY-MM-DD-HHMMSS`.
- Insertions into `~/.ssh/config` and the gitignore are marker blocks
  `# >>> vps-infra-public 14 <id> >>>` … `# <<< … <<<`. A re-run updates
  the block in place instead of duplicating it; if there's nothing to
  change, the file isn't touched.
- Never overwrites: existing keys, a `~/.gitconfig-<slug>` with another
  name/email, a hand-written `Host github-<slug>`. Such a conflict — a
  warning + a line in the summary, the script moves on.
- `~/.ssh` — `chmod 700`, `~/.ssh/config` — `chmod 600`.
- The passphrase is only typed into `ssh-keygen`, never as an argument.

## How to verify

```bash
cd ~/work/client-a/some-repo && git config user.email   # the identity's email
ssh -T git@github-client-a                              # "Hi <account>! ..."
```

## How to roll back

Restore the files from the `.bak-*` copies, or delete the blocks between
the `vps-infra-public 14` markers and the `includeIf` entry in
`~/.gitconfig`
(`git config --global --unset-all 'includeIf.gitdir:<folder>/.path'`).
The script never deletes `~/.ssh/id_ed25519_<slug>` keys.
