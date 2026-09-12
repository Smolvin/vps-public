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

.EXAMPLE
    .\13_setup_dev_environment.ps1            # install the whole set
    .\13_setup_dev_environment.ps1 -Check     # status only
#>
param(
    [switch]$Check
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

if (-not (Get-Command winget -ErrorAction SilentlyContinue)) {
    Write-Error "winget not found — update 'App Installer' from the Microsoft Store and run the script again."
    exit 1
}

if ($Check) {
    Log "=== Status check (changing nothing) ==="
    foreach ($pkg in $Packages) {
        if (Test-WingetPackage $pkg.Id) { Ok-Line $pkg.Name "installed" } else { Miss-Line $pkg.Name }
    }
    $gitName = git config --global user.name 2>$null
    $gitEmail = git config --global user.email 2>$null
    if ($gitName -and $gitEmail) { Ok-Line "git identity" "$gitName <$gitEmail>" } else { Miss-Line "git identity" }
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

# SSH key for GitHub — optional, idempotent (doesn't overwrite an existing one).
Log "=== SSH key (GitHub) ==="
$sshDir = "$env:USERPROFILE\.ssh"
$sshKey = "$sshDir\id_ed25519"
if (Test-Path "$sshKey.pub") {
    Log "[skip] SSH key already exists ($sshKey.pub)."
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

Log "=== Summary ==="
if ($Failed.Count -gt 0) {
    Log "Failed to install: $($Failed -join ', ')"
    Log "Re-run the script (it will only reinstall what's missing) after investigating the cause."
} else {
    Log "Everything installed successfully."
}
