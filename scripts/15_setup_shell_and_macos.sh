#!/usr/bin/env bash
#
# 15_setup_shell_and_macos.sh
#
# Small quality-of-life settings for a developer Mac:
#
#   ~/.zshrc (marker-delimited blocks, only what's missing):
#     - shared, append-only zsh history without duplicates
#       (APPEND_HISTORY, INC_APPEND_HISTORY, SHARE_HISTORY,
#        HIST_IGNORE_DUPS, HIST_IGNORE_SPACE)
#     - Android SDK env (ANDROID_HOME + emulator/platform-tools/cmdline-tools
#       on PATH) - only if ~/Library/Android/sdk exists, or with --android
#     - docker compose aliases dcu/dcd/dcl/dps - only with --with-docker-aliases
#
#   macOS defaults:
#     - Finder: show all file extensions
#     - Finder: show hidden files
#     - Finder: full POSIX path in the window title + path bar
#     - Screenshots: save into a folder (asked interactively)
#
# Usage:
#   ./15_setup_shell_and_macos.sh                         # dry run: shows current -> new, changes nothing
#   ./15_setup_shell_and_macos.sh --apply                 # really apply
#   ./15_setup_shell_and_macos.sh --apply --android       # add Android env even if the SDK isn't there yet
#   ./15_setup_shell_and_macos.sh --apply --with-docker-aliases
#   ./15_setup_shell_and_macos.sh --help
#
# Safety:
#   - ~/.zshrc is backed up (~/.zshrc.bak-<timestamp>) before its first change.
#   - Settings the user already has in ~/.zshrc (outside this script's
#     blocks) are detected and not duplicated.
#   - A re-run with nothing to change changes nothing (and doesn't restart
#     Finder / SystemUIServer).
#   - One failed step doesn't abort the run; failures are listed at the end.

# Literal "~" and "$PATH" in messages and in lines written to ~/.zshrc are intentional.
# shellcheck disable=SC2088,SC2016

set -uo pipefail

APPLY=0
FORCE_ANDROID=0
DOCKER_ALIASES=0
for arg in "$@"; do
    case "$arg" in
        --apply) APPLY=1 ;;
        --android) FORCE_ANDROID=1 ;;
        --with-docker-aliases) DOCKER_ALIASES=1 ;;
        -h|--help)
            sed -n '3,35p' "$0" | sed 's/^# \{0,1\}//'
            exit 0
            ;;
        *)
            echo "Unknown option: $arg (use --help)" >&2
            exit 1
            ;;
    esac
done

if [[ "$(uname -s)" != "Darwin" ]]; then
    echo "This script only supports macOS." >&2
    exit 1
fi

# ---------------------------------------------------------------------------
# Log + first-run confirmation (see SCRIPTS_CHECKLIST.md)
# ---------------------------------------------------------------------------

LOG_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/logs"
LOG_FILE="${LOG_DIR}/15_setup_shell_and_macos_$(date +%Y%m%d_%H%M%S).log"
mkdir -p "$LOG_DIR"

if ! ls "${LOG_DIR}"/15_setup_shell_and_macos_*.log >/dev/null 2>&1; then
    echo "This looks like the first time 15_setup_shell_and_macos.sh has been run"
    echo "(no log for it yet in scripts/logs/). With --apply it edits ~/.zshrc (with a"
    echo "backup) and changes Finder/screenshot settings - read scripts/15_setup_shell_and_macos.md first."
    read -r -p "Continue? [y/N] " FIRST_RUN_CONFIRM
    if [[ ! "$FIRST_RUN_CONFIRM" =~ ^[Yy]$ ]]; then
        echo "Aborted - nothing was done."
        exit 1
    fi
fi

exec > >(tee -a "$LOG_FILE") 2>&1
echo "=== 15_setup_shell_and_macos.sh - $(date) ==="
echo "Mode: $([[ $APPLY -eq 1 ]] && echo 'APPLY' || echo 'DRY RUN (nothing will be changed)')"

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

# Messages show $HOME as "~" (the "~" goes through a variable: bash 3.2 would
# expand a literal one in the replacement back to $HOME).
TILDE='~'
short() { printf '%s' "${1//"$HOME"/$TILDE}"; }
info() { printf '\n\033[1;34m==>\033[0m %s\n' "$(short "$1")"; }
warn() { printf '\033[1;33m[!]\033[0m %s\n' "$(short "$1")"; }
plan() { printf '  [plan] %s\n' "$(short "$1")"; }
done_() { printf '  [done] %s\n' "$(short "$1")"; }
skip() { printf '  [skip] %s\n' "$(short "$1")"; }

FAILED=()
STAMP="$(date +%Y-%m-%d-%H%M%S)"
ZSHRC="$HOME/.zshrc"
ZSHRC_BACKED_UP=0

marker_begin() { printf '# >>> vps-infra-public 15 %s >>>' "$1"; }
marker_end()   { printf '# <<< vps-infra-public 15 %s <<<' "$1"; }

# in_zshrc_outside_blocks <ERE> - true if ~/.zshrc has a matching line that
# is not inside one of this script's blocks (i.e. the user set it up already).
in_zshrc_outside_blocks() {
    [[ -f "$ZSHRC" ]] || return 1
    awk '/^# >>> vps-infra-public 15 /{f=1} !f{print} /^# <<< vps-infra-public 15 /{f=0}' "$ZSHRC" \
        | grep -qE "$1"
}

# upsert_block <id> <body> - replace / append the marker block <id> in ~/.zshrc.
upsert_block() {
    local id="$1" body="$2" begin end existing tmp
    begin="$(marker_begin "$id")"
    end="$(marker_end "$id")"

    existing=""
    if [[ -f "$ZSHRC" ]] && grep -qxF "$begin" "$ZSHRC"; then
        existing="$(awk -v b="$begin" -v e="$end" '$0==e{f=0} f{print} $0==b{f=1}' "$ZSHRC")"
        if [[ "$existing" == "$body" ]]; then
            skip "~/.zshrc: block '$id' already up to date"
            return 0
        fi
    fi

    if [[ $APPLY -eq 0 ]]; then
        if [[ -n "$existing" ]]; then plan "~/.zshrc: update block '$id' to:"; else plan "~/.zshrc: add block '$id':"; fi
        printf '%s\n' "$body" | sed 's/^/           | /'
        return 0
    fi

    if [[ -f "$ZSHRC" && $ZSHRC_BACKED_UP -eq 0 ]]; then
        if cp -p "$ZSHRC" "$ZSHRC.bak-$STAMP"; then
            ZSHRC_BACKED_UP=1
            echo "  [backup] ~/.zshrc -> ~/.zshrc.bak-$STAMP"
        else
            warn "Could not back up ~/.zshrc - not changing it."
            FAILED+=("backup:zshrc")
            return 1
        fi
    fi

    tmp="$(mktemp)"
    if [[ -n "$existing" ]]; then
        awk -v b="$begin" -v e="$end" -v body="$body" '
            $0==b {print; print body; skip=1; next}
            $0==e {skip=0}
            !skip {print}
        ' "$ZSHRC" > "$tmp"
    else
        if [[ -f "$ZSHRC" ]]; then cat "$ZSHRC" > "$tmp"; fi
        if [[ -s "$tmp" ]]; then
            [[ -n "$(tail -c1 "$tmp")" ]] && echo >> "$tmp"
            echo >> "$tmp"
        fi
        printf '%s\n%s\n%s\n' "$begin" "$body" "$end" >> "$tmp"
    fi
    if cat "$tmp" > "$ZSHRC"; then
        done_ "~/.zshrc: block '$id' written"
    else
        warn "Failed to write ~/.zshrc"
        FAILED+=("write:zshrc:$id")
    fi
    rm -f "$tmp"
}

# ---------------------------------------------------------------------------
# 1. zsh history
# ---------------------------------------------------------------------------

info "zsh history (~/.zshrc)"
hist_lines=()
for opt in APPEND_HISTORY INC_APPEND_HISTORY SHARE_HISTORY HIST_IGNORE_DUPS HIST_IGNORE_SPACE; do
    if in_zshrc_outside_blocks "^[[:space:]]*setopt[[:space:]]+([A-Za-z_]+[[:space:]]+)*${opt}([[:space:]]|$)"; then
        continue
    fi
    case "$opt" in
        APPEND_HISTORY)     c="append to the history file instead of overwriting it" ;;
        INC_APPEND_HISTORY) c="write each command right away, not only on shell exit" ;;
        SHARE_HISTORY)      c="history is shared between all open terminal windows/tabs" ;;
        HIST_IGNORE_DUPS)   c="don't store a command repeated right after itself" ;;
        HIST_IGNORE_SPACE)  c="a command starting with a space is not saved" ;;
    esac
    hist_lines+=("$(printf 'setopt %-20s # %s' "$opt" "$c")")
done
if [[ ${#hist_lines[@]} -eq 0 ]]; then
    skip "~/.zshrc already sets all history options"
else
    upsert_block "zsh-history" "$(printf '%s\n' "${hist_lines[@]}")"
fi

# ---------------------------------------------------------------------------
# 2. Android SDK env
# ---------------------------------------------------------------------------

info "Android SDK environment (~/.zshrc)"
SDK_DIR="$HOME/Library/Android/sdk"
if [[ ! -d "$SDK_DIR" && $FORCE_ANDROID -eq 0 ]]; then
    skip "$SDK_DIR not found (open Android Studio once to install the SDK, or pass --android)"
elif in_zshrc_outside_blocks '^[[:space:]]*export[[:space:]]+ANDROID_HOME='; then
    skip "~/.zshrc already exports ANDROID_HOME"
else
    upsert_block "android" "$(cat <<'BLOCK'
export ANDROID_HOME="$HOME/Library/Android/sdk"
export PATH="$PATH:$ANDROID_HOME/emulator:$ANDROID_HOME/platform-tools:$ANDROID_HOME/cmdline-tools/latest/bin"
BLOCK
)"
fi

# ---------------------------------------------------------------------------
# 3. docker compose aliases (opt-in)
# ---------------------------------------------------------------------------

if [[ $DOCKER_ALIASES -eq 1 ]]; then
    info "docker compose aliases (~/.zshrc)"
    alias_lines=()
    for pair in "dcu:docker compose up -d" "dcd:docker compose down" "dcl:docker compose logs -f" "dps:docker compose ps"; do
        name="${pair%%:*}"; cmd="${pair#*:}"
        if in_zshrc_outside_blocks "^[[:space:]]*alias[[:space:]]+${name}="; then
            skip "alias $name already defined"
            continue
        fi
        alias_lines+=("alias $name='$cmd'")
    done
    if [[ ${#alias_lines[@]} -gt 0 ]]; then
        upsert_block "docker-aliases" "$(printf '%s\n' "${alias_lines[@]}")"
    fi
fi

# ---------------------------------------------------------------------------
# 4. macOS defaults
# ---------------------------------------------------------------------------

info "Finder and screenshot settings (macOS defaults)"

RESTART_FINDER=0
RESTART_UI=0

# set_default <domain> <key> <type> <value> <description> <restart: finder|ui>
set_default() {
    local domain="$1" key="$2" type="$3" value="$4" desc="$5" restart="$6" current want
    current="$(defaults read "$domain" "$key" 2>/dev/null || echo '<not set>')"
    want="$value"
    [[ "$type" == "-bool" ]] && { [[ "$value" == "true" ]] && want="1" || want="0"; }
    if [[ "$current" == "$want" ]]; then
        skip "$desc (already set)"
        return 0
    fi
    if [[ $APPLY -eq 0 ]]; then
        plan "$desc: $current -> $want   (defaults write $domain $key $type \"$value\")"
        return 0
    fi
    if defaults write "$domain" "$key" "$type" "$value"; then
        done_ "$desc: $current -> $want"
        [[ "$restart" == "finder" ]] && RESTART_FINDER=1
        [[ "$restart" == "ui" ]] && RESTART_UI=1
    else
        warn "Failed: defaults write $domain $key"
        FAILED+=("defaults:$domain:$key")
    fi
}

set_default NSGlobalDomain   AppleShowAllExtensions  -bool true "Finder: show all file extensions" finder
set_default com.apple.finder AppleShowAllFiles       -bool true "Finder: show hidden files" finder
set_default com.apple.finder _FXShowPosixPathInTitle -bool true "Finder: full path in window title" finder
set_default com.apple.finder ShowPathbar             -bool true "Finder: path bar at the bottom" finder

current_shots="$(defaults read com.apple.screencapture location 2>/dev/null || true)"
# The value may be stored literally as "~/..." and/or with a trailing slash.
current_shots="${current_shots/#\~/$HOME}"
default_shots="${current_shots:-$HOME/Pictures/Screenshots}"
default_shots="${default_shots%/}"
read -r -p "Folder for screenshots [$(short "$default_shots")]: " shots
shots="${shots:-$default_shots}"
shots="${shots/#\~/$HOME}"
shots="${shots%/}"
if [[ "$shots" != /* ]]; then
    warn "Screenshot folder must be an absolute path or start with ~ - skipping."
    FAILED+=("screenshots:path")
elif [[ "${current_shots%/}" == "$shots" ]]; then
    skip "Screenshots: already saved to $shots"
else
    if [[ ! -d "$shots" ]]; then
        if [[ $APPLY -eq 0 ]]; then plan "create folder $shots"; else mkdir -p "$shots" && done_ "created $shots" || FAILED+=("screenshots:mkdir"); fi
    fi
    set_default com.apple.screencapture location -string "$shots" "Screenshots: save location" ui
fi

if [[ $RESTART_FINDER -eq 1 ]]; then
    killall Finder 2>/dev/null && done_ "Finder restarted to pick up the changes"
fi
if [[ $RESTART_UI -eq 1 ]]; then
    killall SystemUIServer 2>/dev/null && done_ "SystemUIServer restarted (screenshot location)"
fi

# ---------------------------------------------------------------------------
# 5. Summary
# ---------------------------------------------------------------------------

if [[ ${#FAILED[@]} -gt 0 ]]; then
    echo
    warn "Some steps failed:"
    for item in "${FAILED[@]}"; do echo "    - $(short "$item")"; done
fi

echo
if [[ $APPLY -eq 0 ]]; then
    echo "Dry run - nothing was changed. To apply, run:"
    echo "  $0 --apply$([[ $FORCE_ANDROID -eq 1 ]] && echo ' --android')$([[ $DOCKER_ALIASES -eq 1 ]] && echo ' --with-docker-aliases')"
else
    echo "Open a new terminal window (or 'source ~/.zshrc') to pick up the shell changes."
fi
echo "Log written to: $(short "$LOG_FILE")"
