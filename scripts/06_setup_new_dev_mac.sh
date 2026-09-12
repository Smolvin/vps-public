#!/usr/bin/env bash
#
# 06_setup_new_dev_mac.sh
#
# Onboarding script for a clean macOS machine: installs the development
# toolchain currently used on this machine (Homebrew formulae/casks, Node
# via nvm, VS Code, mobile dev stack, Git/GitHub setup).
#
# Base software list curated from a real working dev Mac - reusable for
# bootstrapping an isolated `dev` role profile (see 09_create_profiles.sh)
# or a separate new hire's machine.
#
# Usage:
#   chmod +x 06_setup_new_dev_mac.sh
#   ./06_setup_new_dev_mac.sh              # install everything
#   ./06_setup_new_dev_mac.sh --check      # only report what is/isn't installed
#   ./06_setup_new_dev_mac.sh --rclone-only  # install just rclone (+ Homebrew if missing)
#   ./06_setup_new_dev_mac.sh --help       # usage
#
# The script is idempotent and does not abort on a single package failure -
# safe to re-run any time, it just skips what's already there and reports
# anything that failed to install at the end.

set -uo pipefail

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

bold()  { printf '\033[1m%s\033[0m\n' "$1"; }
info()  { printf '\n\033[1;34m==>\033[0m %s\n' "$1"; }
warn()  { printf '\033[1;33m[!]\033[0m %s\n' "$1"; }
ok_line()   { printf "  [OK] %-25s %s\n" "$1" "$2"; }
miss_line() { printf "  [--] %-25s %s\n" "$1" "not installed"; }
ask_yes_no() {
    # ask_yes_no "question" -> returns 0 for yes, 1 for no
    local reply
    read -r -p "$1 [y/N] " reply
    [[ "$reply" =~ ^[Yy]$ ]]
}

MODE="install"
case "${1:-}" in
    --check|--status)
        MODE="check"
        ;;
    --rclone-only)
        MODE="rclone_only"
        ;;
    -h|--help)
        cat <<'EOF'
Usage: setup-new-dev-mac.sh [--check|--rclone-only]

  (no flag)      Install the full dev toolchain (idempotent, safe to re-run).
  --check        Only report what is already installed, install nothing.
  --rclone-only  Install just rclone (and Homebrew itself, if missing).
  --help         Show this message.
EOF
        exit 0
        ;;
    "") ;;
    *)
        echo "Unknown option: $1 (use --help)" >&2
        exit 1
        ;;
esac

if [[ "$(uname -s)" != "Darwin" ]]; then
    echo "This script only supports macOS." >&2
    exit 1
fi

FORMULAE=(
    git                 # version control
    gh                  # GitHub CLI
    nvm                 # Node.js version manager
    python@3.14         # Python
    php                 # PHP
    cocoapods           # iOS/CocoaPods dependency manager (mobile)
    openjdk@17          # Java, needed for Android/Gradle builds (mobile)
    watchman            # file watcher, used by Metro/React Native (mobile)
    mkcert              # locally-trusted TLS certs for local dev
    shellcheck          # shell script linter
    imagemagick         # image processing CLI, common in asset/build pipelines
    gitleaks            # secrets scanner - handy pre-commit / CI check
    rclone              # cloud storage sync/transfer CLI
    restic              # backup tool; `restic mount` needs macFUSE, see docs/mount-tools.md
    borgbackup          # backup tool; `borg mount` needs macFUSE, see docs/mount-tools.md
)

CASKS=(
    visual-studio-code
    iterm2
    docker-desktop
    google-chrome
    "firefox@developer-edition"
    android-studio      # mobile
    figma
    postman
    claude
    shottr              # screenshot tool, handy for bug reports
)

# Optional extras present on this Mac, not installed by default because they
# require extra system permissions (kernel/network extensions) or may be
# specific to this person's setup rather than universal dev needs. Uncomment
# what applies to your team:
# FORMULAE+=(wireguard-tools)   # CLI for company VPN
# CASKS+=(wireguard)            # GUI for company VPN
#
# macFUSE (FUSE for macOS) - needed by sshfs below, and by the `mount`
# subcommand of restic/borgbackup (both already installed above and work
# fine for plain backup/restore without it - only `restic mount`/`borg
# mount` need it). Requires a manual one-time approval in System Settings
# after install, can't be scripted - see docs/mount-tools.md.
# CASKS+=(macfuse)
#
# sshfs on macOS - Homebrew core removed the old `sshfs` formula (macFUSE
# licensing), this tap is the current working replacement. Needs the
# macfuse cask above. See docs/mount-tools.md.
# FORMULAE+=(gromgit/fuse/sshfs-mac)

# ---------------------------------------------------------------------------
# --check mode: report status only, install nothing
# ---------------------------------------------------------------------------

run_check() {
    bold "Dev environment status check"

    info "Prerequisites"
    if xcode-select -p &>/dev/null; then ok_line "Xcode CLT" "installed"; else miss_line "Xcode CLT"; fi
    if command -v brew &>/dev/null; then ok_line "Homebrew" "$(brew --version | head -1 | awk '{print $2}')"; else miss_line "Homebrew"; fi

    if command -v brew &>/dev/null; then
        info "Homebrew formulae"
        for f in "${FORMULAE[@]}"; do
            if brew list --formula --versions "$f" &>/dev/null; then
                ok_line "$f" "$(brew list --formula --versions "$f" | awk '{print $2}')"
            else
                miss_line "$f"
            fi
        done

        info "Homebrew casks (applications)"
        for c in "${CASKS[@]}"; do
            if brew list --cask --versions "$c" &>/dev/null; then
                ok_line "$c" "$(brew list --cask --versions "$c" | awk '{print $2}')"
            else
                miss_line "$c"
            fi
        done
    else
        warn "Homebrew not installed, skipping formula/cask checks."
    fi

    info "Other tools"
    if [[ -s "$HOME/.nvm/nvm.sh" ]] && command -v node &>/dev/null; then
        ok_line "node" "$(node -v)"
    elif command -v node &>/dev/null; then
        ok_line "node" "$(node -v)"
    else
        miss_line "node"
    fi
    if command -v npm &>/dev/null; then ok_line "npm" "$(npm -v)"; else miss_line "npm"; fi
    if npm ls -g eas-cli &>/dev/null; then ok_line "eas-cli" "installed"; else miss_line "eas-cli"; fi
    if [[ -d "/Library/Java/JavaVirtualMachines/openjdk-17.jdk" ]]; then
        ok_line "openjdk@17 (linked)" "installed"
    else
        miss_line "openjdk@17 (linked)"
    fi
    if command -v code &>/dev/null; then ok_line "code CLI" "installed"; else miss_line "code CLI"; fi
    if command -v docker &>/dev/null; then ok_line "docker" "$(docker --version 2>/dev/null)"; else miss_line "docker"; fi

    info "Git / GitHub"
    local gname geemail
    gname="$(git config --global user.name 2>/dev/null || true)"
    geemail="$(git config --global user.email 2>/dev/null || true)"
    if [[ -n "$gname" ]]; then ok_line "git user.name" "$gname"; else miss_line "git user.name"; fi
    if [[ -n "$geemail" ]]; then ok_line "git user.email" "$geemail"; else miss_line "git user.email"; fi
    if [[ -f "$HOME/.ssh/id_ed25519.pub" ]]; then ok_line "SSH key" "$HOME/.ssh/id_ed25519.pub"; else miss_line "SSH key"; fi
    if command -v gh &>/dev/null && gh auth status &>/dev/null; then
        ok_line "gh auth" "logged in"
    else
        miss_line "gh auth"
    fi

    echo
    echo "Run without --check to install anything missing above."
}

FAILED=()

# ---------------------------------------------------------------------------
# Xcode Command Line Tools (needed by Homebrew, git, CocoaPods, compilers)
# ---------------------------------------------------------------------------

ensure_xcode_clt() {
    info "Checking Xcode Command Line Tools"
    if ! xcode-select -p &>/dev/null; then
        echo "Installing Xcode Command Line Tools (a GUI installer will pop up)..."
        xcode-select --install
        echo "Press Enter here once the Command Line Tools installation has finished."
        read -r
    else
        echo "Already installed."
    fi
}

# ---------------------------------------------------------------------------
# Homebrew
# ---------------------------------------------------------------------------

ensure_homebrew() {
    info "Checking Homebrew"
    if ! command -v brew &>/dev/null; then
        echo "Installing Homebrew..."
        if ! /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"; then
            echo "Homebrew installation failed, cannot continue." >&2
            exit 1
        fi

        if [[ -d /opt/homebrew/bin ]]; then
            BREW_PATH="/opt/homebrew/bin/brew"    # Apple Silicon
        else
            BREW_PATH="/usr/local/bin/brew"       # Intel
        fi
        eval "$("$BREW_PATH" shellenv)"

        SHELL_RC="$HOME/.zprofile"
        if ! grep -q "brew shellenv" "$SHELL_RC" 2>/dev/null; then
            echo "eval \"\$($BREW_PATH shellenv)\"" >> "$SHELL_RC"
        fi
    else
        echo "Already installed."
    fi

    if ! command -v brew &>/dev/null; then
        echo "brew is still not on PATH, cannot continue." >&2
        exit 1
    fi

    info "Updating Homebrew"
    brew update || warn "brew update failed, continuing with existing package index."
}

if [[ "$MODE" == "check" ]]; then
    run_check
    exit 0
fi

# ---------------------------------------------------------------------------
# --rclone-only mode: install just rclone (and Homebrew, if missing), then exit
# ---------------------------------------------------------------------------

if [[ "$MODE" == "rclone_only" ]]; then
    bold "Installing rclone only"
    ensure_xcode_clt
    ensure_homebrew

    info "Installing rclone"
    if brew list --formula --versions rclone &>/dev/null; then
        echo "  - rclone (already installed, version $(brew list --formula --versions rclone | awk '{print $2}'))"
    else
        if ! brew install rclone; then
            echo "Failed to install rclone." >&2
            exit 1
        fi
    fi

    echo
    echo "rclone: $(rclone --version 2>/dev/null | head -1 || echo 'n/a')"
    echo "Run 'rclone config' to set up a remote."
    exit 0
fi

# ---------------------------------------------------------------------------
# Install mode
# ---------------------------------------------------------------------------

bold "Development environment setup for a new Mac"
echo "This installs the toolchain used for software development on this team."
echo

ensure_xcode_clt
ensure_homebrew

# ---------------------------------------------------------------------------
# 3. Homebrew formulae & casks (development-related software from this Mac)
# ---------------------------------------------------------------------------

info "Installing Homebrew formulae"
for f in "${FORMULAE[@]}"; do
    if brew list --formula --versions "$f" &>/dev/null; then
        echo "  - $f (already installed)"
        continue
    fi
    echo "  - $f"
    if ! brew install "$f"; then
        warn "Failed to install formula '$f', skipping it and continuing."
        FAILED+=("formula:$f")
    fi
done

info "Installing Homebrew casks (applications)"
for c in "${CASKS[@]}"; do
    if brew list --cask --versions "$c" &>/dev/null; then
        echo "  - $c (already installed)"
        continue
    fi
    echo "  - $c"
    if ! brew install --cask "$c"; then
        warn "Failed to install cask '$c', skipping it and continuing."
        FAILED+=("cask:$c")
    fi
done

# ---------------------------------------------------------------------------
# 4. Node.js via nvm
# ---------------------------------------------------------------------------

info "Setting up Node.js via nvm"
if brew list --formula --versions nvm &>/dev/null; then
    export NVM_DIR="$HOME/.nvm"
    mkdir -p "$NVM_DIR"
    NVM_SH="$(brew --prefix nvm)/nvm.sh"
    if [[ -s "$NVM_SH" ]]; then
        # shellcheck disable=SC1090
        source "$NVM_SH"

        for rc in "$HOME/.zshrc" "$HOME/.bash_profile"; do
            [[ -f "$rc" ]] || continue
            if ! grep -q 'NVM_DIR' "$rc" 2>/dev/null; then
                {
                    echo ''
                    echo 'export NVM_DIR="$HOME/.nvm"'
                    echo '[ -s "'"$(brew --prefix nvm)"'/nvm.sh" ] && \. "'"$(brew --prefix nvm)"'/nvm.sh"'
                } >> "$rc"
            fi
        done

        if command -v nvm &>/dev/null; then
            nvm install --lts || { warn "nvm install --lts failed."; FAILED+=("nvm:node-lts"); }
            nvm alias default 'lts/*' || true
            command -v corepack &>/dev/null && { corepack enable || warn "corepack enable failed."; }

            info "Installing global npm packages"
            if command -v npm &>/dev/null; then
                npm install -g eas-cli || { warn "npm install -g eas-cli failed."; FAILED+=("npm:eas-cli"); }
            else
                warn "npm not available, skipping eas-cli."
                FAILED+=("npm:eas-cli")
            fi
        else
            warn "nvm did not load correctly, skipping Node setup."
            FAILED+=("nvm:load")
        fi
    else
        warn "nvm.sh not found after install, skipping Node setup."
        FAILED+=("nvm:load")
    fi
else
    warn "nvm formula not installed, skipping Node setup."
fi

# ---------------------------------------------------------------------------
# 5. Java (openjdk@17) - make it discoverable by /usr/libexec/java_home
# ---------------------------------------------------------------------------

info "Linking OpenJDK 17 for system Java discovery"
if brew list --formula --versions openjdk@17 &>/dev/null; then
    JAVA_TARGET="/Library/Java/JavaVirtualMachines/openjdk-17.jdk"
    if [[ ! -d "$JAVA_TARGET" ]]; then
        echo "Requires sudo to symlink OpenJDK into /Library/Java/JavaVirtualMachines:"
        if ! sudo ln -sfn "$(brew --prefix openjdk@17)/libexec/openjdk.jdk" "$JAVA_TARGET"; then
            warn "Failed to symlink OpenJDK 17."
            FAILED+=("java:symlink")
        fi
    else
        echo "Already linked."
    fi
else
    warn "openjdk@17 formula not installed, skipping Java linking."
fi

# ---------------------------------------------------------------------------
# 6. Git identity & GitHub auth
# ---------------------------------------------------------------------------

info "Git configuration"
CURRENT_NAME="$(git config --global user.name 2>/dev/null || true)"
CURRENT_EMAIL="$(git config --global user.email 2>/dev/null || true)"

if [[ -z "$CURRENT_NAME" ]]; then
    read -r -p "Git user.name (Full Name): " GIT_NAME
    git config --global user.name "$GIT_NAME"
fi
if [[ -z "$CURRENT_EMAIL" ]]; then
    read -r -p "Git user.email: " GIT_EMAIL
    git config --global user.email "$GIT_EMAIL"
fi
git config --global init.defaultBranch main

if ask_yes_no "Generate a new SSH key for GitHub (ed25519)?"; then
    read -r -p "Email to label the key with [$(git config --global user.email)]: " KEY_EMAIL
    KEY_EMAIL="${KEY_EMAIL:-$(git config --global user.email)}"
    KEY_PATH="$HOME/.ssh/id_ed25519"
    mkdir -p "$HOME/.ssh" && chmod 700 "$HOME/.ssh"
    if [[ -f "$KEY_PATH" ]]; then
        warn "$KEY_PATH already exists, skipping key generation."
    else
        if ssh-keygen -t ed25519 -C "$KEY_EMAIL" -f "$KEY_PATH"; then
            eval "$(ssh-agent -s)"
            ssh-add --apple-use-keychain "$KEY_PATH" 2>/dev/null || ssh-add "$KEY_PATH"
            echo
            bold "Add this public key to GitHub (Settings -> SSH and GPG keys):"
            cat "$KEY_PATH.pub"
            echo
        else
            warn "ssh-keygen failed."
            FAILED+=("ssh:keygen")
        fi
    fi
fi

if ask_yes_no "Run 'gh auth login' now to authenticate the GitHub CLI?"; then
    gh auth login || warn "gh auth login did not complete."
fi

# ---------------------------------------------------------------------------
# 7. Mobile dev stack extras
# ---------------------------------------------------------------------------

info "Mobile development notes"
cat <<'EOF'
Installed: Android Studio, CocoaPods, OpenJDK 17, Watchman, eas-cli.

Manual steps still required (need an Apple ID signed into the App Store):
  - Install Xcode from the App Store (full IDE, required for iOS builds,
    simulators and code signing - Xcode Command Line Tools alone are not
    enough for iOS app development).
  - Install TestFlight from the App Store if you'll test iOS builds.
  - Open Xcode once after installing to accept its license and let it
    install additional components.
  - Open Android Studio once to run through its setup wizard (installs the
    Android SDK, platform tools and an emulator image).
EOF

# ---------------------------------------------------------------------------
# 8. Wrap-up
# ---------------------------------------------------------------------------

info "Done. Versions installed:"
echo "  git:    $(git --version 2>/dev/null || echo 'n/a')"
echo "  gh:     $(gh --version 2>/dev/null | head -1 || echo 'n/a')"
echo "  node:   $(node -v 2>/dev/null || echo 'open a new terminal to load nvm')"
echo "  npm:    $(npm -v 2>/dev/null || echo 'n/a')"
echo "  python: $(python3 --version 2>/dev/null || echo 'n/a')"
echo "  php:    $(php --version 2>/dev/null | head -1 || echo 'n/a')"
echo "  docker: $(docker --version 2>/dev/null || echo 'open Docker.app once to finish setup')"

if [[ ${#FAILED[@]} -gt 0 ]]; then
    warn "Some items failed to install and were skipped:"
    for item in "${FAILED[@]}"; do
        echo "    - $item"
    done
    echo "Re-run this script (or './setup-new-dev-mac.sh --check') after investigating - it will only retry what's missing."
fi

cat <<'EOF'

Remaining manual steps:
  1. Open a new terminal window (or 'source ~/.zshrc') to pick up nvm/PATH changes.
  2. Open Docker Desktop once and accept its terms.
  3. Open VS Code once, then Cmd+Shift+P -> "Shell Command: Install 'code'
     command in PATH" so the 'code' CLI works in the terminal.
  4. Sign into Figma / Postman / Claude apps with your team accounts.
  5. See the "Mobile development notes" above for Xcode/TestFlight.
EOF
