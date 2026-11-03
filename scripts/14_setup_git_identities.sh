#!/usr/bin/env bash
#
# 14_setup_git_identities.sh
#
# Sets up several git identities on one Mac (e.g. personal + one per client
# or employer), each with its own SSH key for GitHub:
#
#   - ~/.gitconfig-<slug>             user.name / user.email of the identity
#   - ~/.gitconfig                    [includeIf "gitdir:<folder>/"] -> that file
#   - ~/.ssh/id_ed25519_<slug>        a dedicated SSH key (created if missing)
#   - ~/.ssh/config                   "Host github-<slug>" block using that key
#
# Plus, once per machine:
#   - ~/.ssh/config "Host *" with SSH connection sharing (ControlMaster),
#     only if the config has no ControlMaster setting of its own;
#   - a global gitignore (core.excludesfile) with OS/editor noise.
#
# Repositories under <folder> then automatically commit as that identity,
# and remotes of the form git@github-<slug>:<org>/<repo>.git use that key.
#
# Usage:
#   ./14_setup_git_identities.sh            # dry run: asks for identities, prints the plan, changes nothing
#   ./14_setup_git_identities.sh --apply    # really apply the changes
#   ./14_setup_git_identities.sh --help
#
# Safety:
#   - Every file is backed up (<file>.bak-<timestamp>) before its first change.
#   - Insertions into ~/.ssh/config and the global gitignore are marker
#     blocks ("# >>> vps-infra-public 14 <id> >>>"); a re-run updates the
#     block in place instead of duplicating it. ~/.gitconfig is changed only
#     through `git config`, and only when the includeIf entry is missing.
#   - Existing keys, existing ~/.gitconfig-<slug> files with other content,
#     and "Host github-<slug>" entries written by hand are never overwritten:
#     the conflict is reported and the script moves on.
#   - Passphrases are only ever typed into ssh-keygen itself.
#   - One failed step doesn't abort the run; failures are listed at the end.

# Literal "~" in messages and in ~/.gitconfig values is intentional.
# shellcheck disable=SC2088

set -uo pipefail

APPLY=0
for arg in "$@"; do
    case "$arg" in
        --apply) APPLY=1 ;;
        -h|--help)
            sed -n '3,37p' "$0" | sed 's/^# \{0,1\}//'
            exit 0
            ;;
        *)
            echo "Unknown option: $arg (use --help)" >&2
            exit 1
            ;;
    esac
done

if [[ "$(uname -s)" != "Darwin" ]]; then
    echo "This script only supports macOS (it relies on the macOS Keychain for SSH keys)." >&2
    exit 1
fi

# ---------------------------------------------------------------------------
# Log + first-run confirmation (see SCRIPTS_CHECKLIST.md)
# ---------------------------------------------------------------------------

LOG_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/logs"
LOG_FILE="${LOG_DIR}/14_setup_git_identities_$(date +%Y%m%d_%H%M%S).log"
mkdir -p "$LOG_DIR"

if ! ls "${LOG_DIR}"/14_setup_git_identities_*.log >/dev/null 2>&1; then
    echo "This looks like the first time 14_setup_git_identities.sh has been run"
    echo "(no log for it yet in scripts/logs/). With --apply it edits ~/.gitconfig"
    echo "and ~/.ssh/config (with backups) - read scripts/14_setup_git_identities.md first."
    read -r -p "Continue? [y/N] " FIRST_RUN_CONFIRM
    if [[ ! "$FIRST_RUN_CONFIRM" =~ ^[Yy]$ ]]; then
        echo "Aborted - nothing was done."
        exit 1
    fi
fi

exec > >(tee -a "$LOG_FILE") 2>&1
echo "=== 14_setup_git_identities.sh - $(date) ==="
echo "Mode: $([[ $APPLY -eq 1 ]] && echo 'APPLY' || echo 'DRY RUN (nothing will be changed)')"

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

# All messages show $HOME as "~" (shorter, and keeps the user name out of logs).
# (The "~" goes through a variable: bash 3.2 would expand a literal one back to $HOME.)
TILDE='~'
short() { printf '%s' "${1//"$HOME"/$TILDE}"; }
bold() { printf '\033[1m%s\033[0m\n' "$(short "$1")"; }
info() { printf '\n\033[1;34m==>\033[0m %s\n' "$(short "$1")"; }
warn() { printf '\033[1;33m[!]\033[0m %s\n' "$(short "$1")"; }
plan() { printf '  [plan] %s\n' "$(short "$1")"; }
done_() { printf '  [done] %s\n' "$(short "$1")"; }
skip() { printf '  [skip] %s\n' "$(short "$1")"; }

FAILED=()
STAMP="$(date +%Y-%m-%d-%H%M%S)"
BACKED_UP=()

GITCONFIG="$HOME/.gitconfig"
SSH_DIR="$HOME/.ssh"
SSH_CONFIG="$SSH_DIR/config"

# backup_once <file> - copy <file> to <file>.bak-<timestamp>, once per run.
backup_once() {
    local f="$1" b
    [[ -f "$f" ]] || return 0
    for b in "${BACKED_UP[@]+"${BACKED_UP[@]}"}"; do [[ "$b" == "$f" ]] && return 0; done
    if cp -p "$f" "$f.bak-$STAMP"; then
        BACKED_UP+=("$f")
        echo "  [backup] $(short "$f") -> $(short "$f.bak-$STAMP")"
    else
        warn "Could not back up $f"
        return 1
    fi
}

marker_begin() { printf '# >>> vps-infra-public 14 %s >>>' "$1"; }
marker_end()   { printf '# <<< vps-infra-public 14 %s <<<' "$1"; }

# upsert_block <file> <id> <body>
# Replaces the marker block <id> in <file> with <body> (keeping its position),
# or appends it if absent. No-op if the block already has exactly that body.
upsert_block() {
    local file="$1" id="$2" body="$3" begin end existing tmp
    begin="$(marker_begin "$id")"
    end="$(marker_end "$id")"

    existing=""
    if [[ -f "$file" ]] && grep -qxF "$begin" "$file"; then
        existing="$(awk -v b="$begin" -v e="$end" '$0==e{f=0} f{print} $0==b{f=1}' "$file")"
        if [[ "$existing" == "$body" ]]; then
            skip "$file: block '$id' already up to date"
            return 0
        fi
    fi

    if [[ $APPLY -eq 0 ]]; then
        if [[ -n "$existing" ]]; then plan "$file: update block '$id' to:"; else plan "$file: add block '$id':"; fi
        printf '%s\n' "$body" | sed 's/^/           | /'
        return 0
    fi

    backup_once "$file" || { FAILED+=("backup:$file"); return 1; }
    tmp="$(mktemp)"
    if [[ -n "$existing" ]]; then
        # Replace the block in place.
        awk -v b="$begin" -v e="$end" -v body="$body" '
            $0==b {print; print body; skip=1; next}
            $0==e {skip=0}
            !skip {print}
        ' "$file" > "$tmp"
    else
        [[ -f "$file" ]] && cat "$file" > "$tmp"
        # Make sure the block starts on its own line.
        if [[ -s "$tmp" ]]; then
            [[ -n "$(tail -c1 "$tmp")" ]] && echo >> "$tmp"
            echo >> "$tmp"
        fi
        printf '%s\n%s\n%s\n' "$begin" "$body" "$end" >> "$tmp"
    fi
    # Write through cat so that permissions / symlinked dotfiles are preserved.
    if cat "$tmp" > "$file"; then
        done_ "$file: block '$id' written"
    else
        warn "Failed to write $file"
        FAILED+=("write:$file:$id")
    fi
    rm -f "$tmp"
}

# ---------------------------------------------------------------------------
# 1. Collect identities (interactive; nothing is changed yet)
# ---------------------------------------------------------------------------

SLUGS=(); NAMES=(); EMAILS=(); FOLDERS=()

info "Git identities"
echo "Each identity = a folder with repositories + git name/email + its own GitHub SSH key."
echo "Existing setup in ~/.gitconfig (includeIf entries):"
git config --global --get-regexp '^includeif\.' 2>/dev/null | sed 's/^/    /' || true
[[ -z "$(git config --global --get-regexp '^includeif\.' 2>/dev/null)" ]] && echo "    (none)"

while true; do
    echo
    read -r -p "Add an identity? [y/N] " more
    [[ "$more" =~ ^[Yy]$ ]] || break

    read -r -p "  Short name (slug: a-z, 0-9, '-'; used in file names and 'github-<slug>'): " slug
    if [[ ! "$slug" =~ ^[a-z0-9][a-z0-9-]*$ ]]; then
        warn "Invalid slug '$slug' - skipped."
        continue
    fi
    read -r -p "  git user.name: " gname
    read -r -p "  git user.email: " gemail
    if [[ -z "$gname" || ! "$gemail" =~ ^[^@[:space:]]+@[^@[:space:]]+$ ]]; then
        warn "Name is empty or email doesn't look like an email - skipped."
        continue
    fi
    read -r -p "  Folder with this identity's repositories (e.g. ~/work/client-a): " folder
    folder="${folder/#\~/$HOME}"
    folder="${folder%/}"
    if [[ -z "$folder" || "$folder" != /* ]]; then
        warn "Folder must be an absolute path or start with ~ - skipped."
        continue
    fi
    [[ -d "$folder" ]] || warn "Folder $folder doesn't exist yet - the rule will apply once it does."

    SLUGS+=("$slug"); NAMES+=("$gname"); EMAILS+=("$gemail"); FOLDERS+=("$folder")
done

# ---------------------------------------------------------------------------
# 2. Per-identity changes
# ---------------------------------------------------------------------------

NEW_KEYS=()

for i in "${!SLUGS[@]}"; do
    slug="${SLUGS[$i]}"; gname="${NAMES[$i]}"; gemail="${EMAILS[$i]}"; folder="${FOLDERS[$i]}"
    info "Identity '$slug'"

    # 2a. ~/.gitconfig-<slug>
    id_cfg="$HOME/.gitconfig-$slug"
    want_cfg="$(printf '[user]\n\tname = %s\n\temail = %s\n' "$gname" "$gemail")"
    if [[ -f "$id_cfg" ]]; then
        if [[ "$(git config -f "$id_cfg" user.name)" == "$gname" && "$(git config -f "$id_cfg" user.email)" == "$gemail" ]]; then
            skip "$id_cfg already has this name/email"
        else
            warn "$id_cfg exists with a different name/email - not overwriting. Edit it by hand if needed."
            FAILED+=("conflict:$id_cfg")
        fi
    elif [[ $APPLY -eq 0 ]]; then
        plan "create $id_cfg:"
        printf '%s\n' "$want_cfg" | sed 's/^/           | /'
    else
        if printf '%s\n' "$want_cfg" > "$id_cfg"; then done_ "created $id_cfg"; else FAILED+=("write:$id_cfg"); fi
    fi

    # 2b. includeIf in ~/.gitconfig (gitdir patterns need a trailing slash).
    # Paths under $HOME are stored with "~" (git expands it), so the config
    # stays portable and doesn't contain the local user name.
    folder_cfg="$(short "$folder")"
    key="includeIf.gitdir:$folder_cfg/.path"
    if git config --global --get-all "$key" 2>/dev/null | grep -qxF -e "~/.gitconfig-$slug" -e "$id_cfg" \
        || git config --global --get-all "includeIf.gitdir:$folder/.path" 2>/dev/null | grep -qxF -e "~/.gitconfig-$slug" -e "$id_cfg"; then
        skip "~/.gitconfig already includes ~/.gitconfig-$slug for $folder_cfg/"
    elif [[ $APPLY -eq 0 ]]; then
        plan "~/.gitconfig: [includeIf \"gitdir:$folder_cfg/\"] path = ~/.gitconfig-$slug"
    else
        backup_once "$GITCONFIG"
        if git config --global --add "$key" "~/.gitconfig-$slug"; then
            done_ "~/.gitconfig: includeIf gitdir:$folder_cfg/ -> ~/.gitconfig-$slug"
        else
            FAILED+=("gitconfig:includeIf:$slug")
        fi
    fi

    # 2c. SSH key
    key_path="$SSH_DIR/id_ed25519_$slug"
    if [[ -f "$key_path" ]]; then
        skip "SSH key $key_path already exists"
    elif [[ $APPLY -eq 0 ]]; then
        plan "generate SSH key $key_path (ssh-keygen will ask for a passphrase) and add it to the Keychain"
    else
        mkdir -p "$SSH_DIR" && chmod 700 "$SSH_DIR"
        echo "  Generating $key_path - ssh-keygen will ask for a passphrase (recommended):"
        if ssh-keygen -t ed25519 -C "$gemail" -f "$key_path"; then
            ssh-add --apple-use-keychain "$key_path" 2>/dev/null || warn "ssh-add failed - the key will be added on first use (AddKeysToAgent)."
            NEW_KEYS+=("$slug:$key_path.pub")
            done_ "SSH key $key_path"
        else
            warn "ssh-keygen failed for $slug."
            FAILED+=("ssh:keygen:$slug")
        fi
    fi

    # 2d. Host github-<slug> in ~/.ssh/config
    if [[ -f "$SSH_CONFIG" ]] && grep -qiE "^[[:space:]]*Host[[:space:]]+(.*[[:space:]])?github-$slug([[:space:]]|$)" "$SSH_CONFIG" \
        && ! grep -qxF "$(marker_begin "$slug")" "$SSH_CONFIG"; then
        warn "~/.ssh/config already has a hand-written 'Host github-$slug' - not touching it."
        FAILED+=("conflict:ssh-config:github-$slug")
    else
        [[ $APPLY -eq 1 ]] && { mkdir -p "$SSH_DIR" && chmod 700 "$SSH_DIR"; }
        upsert_block "$SSH_CONFIG" "$slug" "$(cat <<BLOCK
Host github-$slug
    HostName github.com
    User git
    IdentityFile ~/.ssh/id_ed25519_$slug
    IdentitiesOnly yes
    UseKeychain yes
    AddKeysToAgent yes
BLOCK
)"
    fi
done

# ---------------------------------------------------------------------------
# 3. Once per machine: SSH connection sharing
# ---------------------------------------------------------------------------

info "SSH connection sharing (ControlMaster)"
if [[ -f "$SSH_CONFIG" ]] && grep -qiE '^[[:space:]]*ControlMaster' "$SSH_CONFIG" \
    && ! grep -qxF "$(marker_begin global)" "$SSH_CONFIG"; then
    skip "~/.ssh/config already configures ControlMaster itself"
else
    [[ $APPLY -eq 1 ]] && { mkdir -p "$SSH_DIR" && chmod 700 "$SSH_DIR"; }
    upsert_block "$SSH_CONFIG" "global" "$(cat <<'BLOCK'
# Reuse one SSH connection per host for 10 minutes (faster git fetch/push).
Host *
    ControlMaster auto
    ControlPath ~/.ssh/cm-%C
    ControlPersist 10m
BLOCK
)"
fi
[[ $APPLY -eq 1 && -f "$SSH_CONFIG" ]] && chmod 600 "$SSH_CONFIG"

# ---------------------------------------------------------------------------
# 4. Once per machine: global gitignore
# ---------------------------------------------------------------------------

info "Global gitignore (core.excludesfile)"
excludes="$(git config --global core.excludesfile 2>/dev/null || true)"
if [[ -z "$excludes" ]]; then
    excludes_path="$HOME/.gitignore_global"
    if [[ $APPLY -eq 0 ]]; then
        plan "git config --global core.excludesfile ~/.gitignore_global"
    else
        backup_once "$GITCONFIG"
        git config --global core.excludesfile "~/.gitignore_global" && done_ "core.excludesfile = ~/.gitignore_global" \
            || FAILED+=("gitconfig:excludesfile")
    fi
else
    excludes_path="${excludes/#\~/$HOME}"
    skip "core.excludesfile already set ($excludes) - adding missing lines there"
fi

# Only add patterns the file doesn't already have (outside our block too).
want_ignores=()
for pat in .DS_Store .idea/ .vscode/ '*.swp'; do
    if [[ -f "$excludes_path" ]] && grep -qxF -- "$pat" "$excludes_path" \
        && ! awk -v b="$(marker_begin gitignore)" -v e="$(marker_end gitignore)" -v p="$pat" \
            '$0==b{f=1} $0==e{f=0} f && $0==p{found=1} END{exit !found}' "$excludes_path"; then
        continue
    fi
    want_ignores+=("$pat")
done
if [[ ${#want_ignores[@]} -eq 0 ]]; then
    skip "$excludes_path already ignores .DS_Store, .idea/, .vscode/, *.swp"
else
    upsert_block "$excludes_path" "gitignore" "$(printf '%s\n' "${want_ignores[@]}")"
fi

# ---------------------------------------------------------------------------
# 5. Summary
# ---------------------------------------------------------------------------

info "Summary"
if [[ ${#SLUGS[@]} -eq 0 ]]; then
    echo "No identities entered - only the machine-wide steps were processed."
fi

for entry in "${NEW_KEYS[@]+"${NEW_KEYS[@]}"}"; do
    slug="${entry%%:*}"; pub="${entry#*:}"
    echo
    bold "Public key for '$slug' - add it to the matching GitHub account (Settings -> SSH and GPG keys):"
    cat "$pub"
    echo "  or, logged into that account with gh:  gh ssh-key add $pub --title \"$(hostname -s) $slug\""
done

if [[ ${#SLUGS[@]} -gt 0 ]]; then
    echo
    echo "How to use:"
    echo "  - Repositories under each folder now commit with that identity (check: git config user.email)."
    echo "  - Clone / set remotes through the per-identity host alias, e.g.:"
    for slug in "${SLUGS[@]}"; do
        echo "      git clone git@github-$slug:<org>/<repo>.git"
        echo "      git remote set-url origin git@github-$slug:<org>/<repo>.git"
    done
    echo "  - Test the key:  ssh -T git@github-${SLUGS[0]}"
fi

if [[ ${#FAILED[@]} -gt 0 ]]; then
    echo
    warn "Some steps failed or were skipped because of conflicts:"
    for item in "${FAILED[@]}"; do echo "    - $(short "$item")"; done
fi

echo
if [[ $APPLY -eq 0 ]]; then
    echo "Dry run - nothing was changed. To apply, run:"
    echo "  $0 --apply"
fi
echo "Log written to: $(short "$LOG_FILE")"
