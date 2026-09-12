#!/usr/bin/env bash
#
# 09_create_profiles.sh — creates standard (non-admin) macOS role profiles:
# personal, work, dev, sandbox.
#
# Design decisions baked in (do not change without a reason - see
# SCRIPTS_CHECKLIST.md #9):
#   - Exactly one admin account exists in a well-run architecture like this.
#     Every profile this script creates is a STANDARD user. If sysadminctl
#     ever puts a new account in the admin group, the script removes it.
#   - Passwords are never passed on the command line or hardcoded — each
#     account's password is set interactively via `-password -`, which makes
#     sysadminctl prompt securely instead of taking it as an argv value.
#   - Dry-run by default. Nothing is created unless you pass --apply.
#   - First real run (no matching log yet in scripts/logs/) prints a caution
#     banner and asks for explicit confirmation before doing anything else —
#     this script creates real macOS accounts and needs sudo, so a moment of
#     "have you actually read what this does" is worth the one-time friction.
#     Never asked again once a log exists — see the SCRIPTS_CHECKLIST.md #9
#     note.
#
# Usage:
#   sudo ./09_create_profiles.sh                        # dry run, all 4 profiles
#   sudo ./09_create_profiles.sh --apply                 # actually create all 4
#   sudo ./09_create_profiles.sh --apply --only work      # create just "work"
#   sudo ./09_create_profiles.sh --apply --filevault      # also register each
#                                                          # new account for
#                                                          # FileVault unlock
#
# Safe to re-run: existing accounts are detected and skipped.

set -euo pipefail

PROFILES=(
  "personal:Personal"
  "work:Work"
  "dev:Dev"
  "sandbox:Sandbox"
)

DRY_RUN=1
FILEVAULT=0
ONLY=""

usage() {
  cat <<EOF
Usage: sudo $0 [--apply] [--filevault] [--only <username>]

  --apply       Actually create accounts (default: dry-run, prints only)
  --filevault   After creating each account, also register it for FileVault
                unlock (sudo fdesetup add -usertoadd <user>). This will
                prompt for an existing FileVault-enabled admin's credentials.
  --only NAME   Only process this one profile: personal | work | dev | sandbox
  -h, --help    Show this help
EOF
  exit 1
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --apply) DRY_RUN=0; shift ;;
    --filevault) FILEVAULT=1; shift ;;
    --only) ONLY="${2:-}"; shift 2 ;;
    -h|--help) usage ;;
    *) echo "Unknown argument: $1" >&2; usage ;;
  esac
done

if [[ "$(id -u)" -ne 0 ]]; then
  echo "This script must be run with sudo (account creation requires root/admin auth)." >&2
  echo "Try: sudo $0 ${*}" >&2
  exit 1
fi

LOG_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/logs"
LOG_FILE="${LOG_DIR}/09_create_profiles_$(date +%Y%m%d_%H%M%S).log"
mkdir -p "$LOG_DIR"

if ! ls "${LOG_DIR}"/*create_profiles_*.log >/dev/null 2>&1; then
  echo "⚠ This looks like the first time 09_create_profiles.sh has actually been run"
  echo "  (no log for it yet in scripts/logs/). It creates real macOS accounts and"
  echo "  needs sudo — read scripts/09_create_profiles.md first if you haven't."
  read -r -p "Continue? [y/N] " FIRST_RUN_CONFIRM
  if [[ ! "$FIRST_RUN_CONFIRM" =~ ^[Yy]$ ]]; then
    echo "Aborted — nothing was done."
    exit 1
  fi
fi

exec > >(tee -a "$LOG_FILE") 2>&1
echo "=== 09_create_profiles.sh — $(date) ==="
echo "Mode: $([[ $DRY_RUN -eq 1 ]] && echo 'DRY RUN' || echo 'APPLY')"
echo

user_exists() {
  dscl . -read "/Users/$1" >/dev/null 2>&1
}

is_admin() {
  dseditgroup -o checkmember -m "$1" admin >/dev/null 2>&1
}

create_profile() {
  local username="$1" fullname="$2" home="/Users/${1}"

  echo "=== ${username} (${fullname}) ==="

  if user_exists "$username"; then
    echo "[skip] /Users/${username} already exists, not touching it."
    return 0
  fi

  if [[ "$DRY_RUN" -eq 1 ]]; then
    echo "[dry-run] would run:"
    echo "  sysadminctl -addUser ${username} -fullName \"${fullname}\" -home ${home} -shell /bin/zsh -password -"
    [[ "$FILEVAULT" -eq 1 ]] && echo "  fdesetup add -usertoadd ${username}"
    return 0
  fi

  echo "You will be prompted to set a password for '${username}' (typed securely, not shown):"
  sysadminctl -addUser "${username}" \
    -fullName "${fullname}" \
    -home "${home}" \
    -shell /bin/zsh \
    -password -

  if ! user_exists "$username"; then
    echo "[error] ${username} was not created — check the sysadminctl output above." >&2
    return 1
  fi

  if is_admin "$username"; then
    echo "[warn] ${username} landed in the admin group — removing it (this architecture wants exactly 1 admin account, and this isn't it)."
    dseditgroup -o edit -d "${username}" -t user admin
  fi

  echo "[ok] created standard user ${username} (home: ${home})"

  if [[ "$FILEVAULT" -eq 1 ]]; then
    echo "Registering ${username} for FileVault unlock — you'll be asked for an existing FileVault-enabled admin's credentials, then for ${username}'s password:"
    fdesetup add -usertoadd "${username}"
  fi
}

for entry in "${PROFILES[@]}"; do
  username="${entry%%:*}"
  fullname="${entry##*:}"

  if [[ -n "$ONLY" && "$ONLY" != "$username" ]]; then
    continue
  fi

  create_profile "$username" "$fullname"
  echo
done

if [[ "$DRY_RUN" -eq 1 ]]; then
  echo "Dry run complete — nothing was changed. Re-run with --apply to actually create accounts."
  echo "sudo ${0} --apply"
else
  echo "Done. Verify with: dscl . -list /Users | grep -E '^(personal|work|dev|sandbox)$'"
fi
echo "Log written to: ${LOG_FILE}"
