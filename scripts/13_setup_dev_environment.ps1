<#
.SYNOPSIS
    Dev tools onboarding on Windows — the same principle as
    06_setup_new_dev_mac.sh (see next to it in this same repository, the
    Mac version of the same idea): idempotent, doesn't crash entirely on
    one failed package, -Check only shows status.

.DESCRIPTION
    The base set is NOT a copy of the Mac list (that one had a
    mobile/iOS stack — Xcode/CocoaPods/Android Studio/Figma — most of
    which doesn't make sense or isn't available on Windows). The common
    denominator that actually carries over: git, VS Code, a terminal,
    GitHub CLI, Node.js LTS, Python. The list isn't dogma, add whatever
    actually turns out to be needed (see $Packages below, a plain array,
    nothing generated from anywhere).

    Run it AS the user the environment is being set up for (e.g. "dev",
    created by 12_create_dev_user.ps1) — not as administrator, otherwise
    git identity/SSH key and per-user winget installs end up in the wrong
    profile. winget itself will only ask for elevation for the packages
    that actually need it.

.PARAMETER Check
    Installs nothing — only shows what's already there and what's
    missing.

.PARAMETER Remove
    Roll back: uninstalls (via winget) whichever of $Packages below is
    currently installed. Asks for confirmation first (every time -- this
    is destructive on every run, not just the first). Does NOT touch git
    identity or the SSH key -- those are left in place, remove them
    manually if you want them gone too.

.EXAMPLE
    .\13_setup_dev_environment.ps1            # install the whole set
    .\13_setup_dev_environment.ps1 -Check     # status only
    .\13_setup_dev_environment.ps1 -Remove    # uninstall what this script installed
#>
param(
    [switch]$Check,
    [switch]$Remove
)

$ErrorActionPreference = "Continue"

$Packages = @(
    @{ Id = "Git.Git";                   Name = "Git" }
    @{ Id = "Microsoft.VisualStudioCode"; Name = "VS Code" }
    @{ Id = "Microsoft.WindowsTerminal";  Name = "Windows Terminal" }
    @{ Id = "GitHub.cli";                 Name = "GitHub CLI" }
    @{ Id = "OpenJS.NodeJS.LTS";          Name = "Node.js LTS" }
    @{ Id = "Python.Python.3.12";         Name = "Python 3.12" }
)

function Log($msg) { Write-Host "[$(Get-Date -Format 'HH:mm:ss')] $msg" }
function Ok-Line($name, $version) { Write-Host ("  [OK] {0,-20} {1}" -f $name, $version) -ForegroundColor Green }
function Miss-Line($name) { Write-Host ("  [--] {0,-20} not installed" -f $name) -ForegroundColor DarkYellow }

function Test-WingetPackage($id) {
    $out = winget list --id $id -e --accept-source-agreements 2>$null
    return ($out -match [regex]::Escape($id))
}

$currentPrincipal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
if ($currentPrincipal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Host "[warn] Running as Administrator." -ForegroundColor Yellow
    Write-Host "This script is meant to run as the regular user it's setting up (e.g. 'dev'," -ForegroundColor Yellow
    Write-Host "created by 12_create_dev_user.ps1) — not as Administrator. Otherwise git" -ForegroundColor Yellow
    Write-Host "identity, the SSH key and per-user winget installs land in the Administrator" -ForegroundColor Yellow
    Write-Host "profile instead of the profile you actually want to develop in." -ForegroundColor Yellow
    if (-not $Check) {
        $confirm = Read-Host "Continue anyway as Administrator? [y/N]"
        if ($confirm -notmatch '^[Yy]$') {
            Write-Host "Cancelled — log in as the target user and re-run this script from there."
            exit 1
        }
    }
}

if (-not (Get-Command winget -ErrorAction SilentlyContinue)) {
    Write-Host "winget not found." -ForegroundColor Red
    Write-Host ""
    Write-Host "How to fix:" -ForegroundColor Yellow
    Write-Host "  1. Open Microsoft Store, search for 'App Installer', click Install/Update."
    Write-Host "  2. No Store access on this machine? Download the latest .msixbundle from"
    Write-Host "     the official winget-cli releases page:"
    Write-Host "     https://github.com/microsoft/winget-cli/releases/latest" -ForegroundColor Cyan
    Write-Host "     then install it with: Add-AppxPackage <downloaded file>.msixbundle"
    Write-Host "  3. Close and reopen PowerShell, then run this script again."
    Write-Host ""
    Write-Host "See the 'Troubleshooting' section in 13_setup_dev_environment.md / .en.md" -ForegroundColor Yellow
    Write-Host "for other common first-run issues (e.g. execution policy)." -ForegroundColor Yellow
    exit 1
}

if ($Remove) {
    Log "=== Removing dev tools (winget uninstall) ==="
    Write-Host ""
    Write-Host "About to uninstall these packages via winget, whichever are installed:" -ForegroundColor Yellow
    foreach ($pkg in $Packages) { Write-Host "  - $($pkg.Name) ($($pkg.Id))" }
    Write-Host "Git identity and the SSH key are left untouched -- remove those manually if you want them gone too." -ForegroundColor Yellow
    $removeConfirm = Read-Host "Continue? [y/N]"
    if ($removeConfirm -notmatch '^[Yy]$') {
        Log "Cancelled — nothing was removed."
        exit 1
    }

    $RemoveFailed = @()
    foreach ($pkg in $Packages) {
        if (-not (Test-WingetPackage $pkg.Id)) {
            Log "[skip] $($pkg.Name) not installed."
            continue
        }
        Log "Uninstalling $($pkg.Name) ($($pkg.Id))..."
        try {
            winget uninstall --id $pkg.Id -e --silent
            if ($LASTEXITCODE -ne 0) { throw "winget exit code $LASTEXITCODE" }
            Log "[ok] $($pkg.Name) uninstalled."
        } catch {
            Log "[warn] $($pkg.Name) failed to uninstall: $_"
            $RemoveFailed += $pkg.Name
        }
    }

    Log "=== Summary ==="
    if ($RemoveFailed.Count -gt 0) {
        Log "Failed to uninstall: $($RemoveFailed -join ', ')"
    } else {
        Log "Done."
    }
    exit 0
}

if ($Check) {
    Log "=== Status check (changing nothing) ==="
    foreach ($pkg in $Packages) {
        if (Test-WingetPackage $pkg.Id) { Ok-Line $pkg.Name "installed" } else { Miss-Line $pkg.Name }
    }
    if (Get-Command git -ErrorAction SilentlyContinue) {
        $gitName = git config --global user.name 2>$null
        $gitEmail = git config --global user.email 2>$null
        if ($gitName -and $gitEmail) { Ok-Line "git identity" "$gitName <$gitEmail>" } else { Miss-Line "git identity" }
    } else {
        Miss-Line "git identity"
    }
    $sshKey = "$env:USERPROFILE\.ssh\id_ed25519.pub"
    if (Test-Path $sshKey) { Ok-Line "SSH key" $sshKey } else { Miss-Line "SSH key" }
    Log "Run without -Check to install what's missing."
    exit 0
}

$Failed = @()

Log "=== Installing dev tools ==="
foreach ($pkg in $Packages) {
    if (Test-WingetPackage $pkg.Id) {
        Log "[skip] $($pkg.Name) already installed."
        continue
    }
    Log "Installing $($pkg.Name) ($($pkg.Id))..."
    try {
        winget install --id $pkg.Id -e --accept-source-agreements --accept-package-agreements --silent
        if ($LASTEXITCODE -ne 0) { throw "winget exit code $LASTEXITCODE" }
        Log "[ok] $($pkg.Name) installed."
    } catch {
        Log "[warn] $($pkg.Name) failed to install: $_"
        $Failed += $pkg.Name
    }
}

# Git identity — ask only if not already configured (idempotent).
Log "=== Git identity ==="
if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
    Log "[skip] git is not available (its install above may have failed) — re-run the script after fixing that."
} else {
    $gitName = git config --global user.name 2>$null
    $gitEmail = git config --global user.email 2>$null
    if ($gitName -and $gitEmail) {
        Log "[skip] git identity already set: $gitName <$gitEmail>"
    } else {
        $newName = Read-Host "git user.name"
        $newEmail = Read-Host "git user.email"
        if ($newName -and $newEmail) {
            git config --global user.name "$newName"
            git config --global user.email "$newEmail"
            Log "[ok] git identity configured."
        } else {
            Log "[skip] Empty input — git identity not configured, set it manually later."
        }
    }
}

# SSH key for GitHub — optional, idempotent (doesn't overwrite an existing one).
Log "=== SSH key (GitHub) ==="
$sshDir = "$env:USERPROFILE\.ssh"
$sshKey = "$sshDir\id_ed25519"
if (Test-Path "$sshKey.pub") {
    Log "[skip] SSH key already exists ($sshKey.pub)."
} else {
    if (-not (Get-Command ssh-keygen -ErrorAction SilentlyContinue)) {
        Log "[skip] ssh-keygen not found -- enable the 'OpenSSH Client' optional Windows feature"
        Log "       (Settings -> System -> Optional features) and re-run this script."
    } else {
        $genKey = Read-Host "Generate an SSH key (ed25519) for GitHub? [y/N]"
        if ($genKey -match '^[Yy]$') {
            New-Item -ItemType Directory -Force -Path $sshDir | Out-Null
            ssh-keygen -t ed25519 -f $sshKey -N '""'
            Log "[ok] Key created. Public key (add it to GitHub -> Settings -> SSH keys):"
            Write-Host ""
            Get-Content "$sshKey.pub" | Write-Host -ForegroundColor Cyan
            Write-Host ""
        } else {
            Log "[skip] Skipped by choice."
        }
    }
}

Log "=== Summary ==="
if ($Failed.Count -gt 0) {
    Log "Failed to install: $($Failed -join ', ')"
    Log "Re-run the script (it will only reinstall what's missing) after investigating the cause."
} else {
    Log "Everything installed successfully."
}
