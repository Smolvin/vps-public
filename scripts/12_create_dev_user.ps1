<#
.SYNOPSIS
    Creates an isolated, non-admin local Windows user — the same
    principle as 09_create_profiles.sh (see next to it in this same
    repository, the Mac version of the same idea): exactly one admin
    account in the architecture, everything else is a standard user.

.DESCRIPTION
    Design decisions (same as 09_create_profiles.sh, don't change without
    updating this comment):
      - Dry-run by default. Nothing is created unless -Apply is passed.
      - The password is never passed as a parameter or hardcoded — it's
        entered interactively via Read-Host -AsSecureString.
      - First real run (no log yet in this same folder) prints a warning
        and asks for confirmation — creating a real Windows account needs
        admin. Doesn't ask again once a log exists.
      - Idempotent: an existing account is left alone, safe to re-run.
      - If the account somehow ends up in the Administrators group —
        removes it (this role must stay ISOLATED, nothing more).

.PARAMETER UserName
    Name of the new user (default "dev").

.PARAMETER Apply
    Actually create the account. Without this flag — dry-run only.

.EXAMPLE
    .\12_create_dev_user.ps1                  # dry-run
    .\12_create_dev_user.ps1 -Apply           # actually create
#>
param(
    [string]$UserName = "dev",
    [switch]$Apply
)

$ErrorActionPreference = "Stop"

$currentPrincipal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
if (-not $currentPrincipal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Error "Run PowerShell as administrator and try again."
    exit 1
}

$LogDir = Join-Path $PSScriptRoot "logs"
New-Item -ItemType Directory -Force -Path $LogDir | Out-Null
$LogFile = Join-Path $LogDir "12_create_dev_user_$(Get-Date -Format 'yyyyMMdd_HHmmss').log"

function Log($msg) {
    $line = "[{0}] {1}" -f (Get-Date -Format "yyyy-MM-dd HH:mm:ss"), $msg
    Write-Host $line
    Add-Content -Path $LogFile -Value $line
}

$existingLogs = Get-ChildItem -Path $LogDir -Filter "12_create_dev_user_*.log" -ErrorAction SilentlyContinue
if (-not $existingLogs) {
    Write-Host "This looks like the first real run of 12_create_dev_user.ps1 (no log yet)." -ForegroundColor Yellow
    Write-Host "The script creates a real local Windows account and requires administrator rights." -ForegroundColor Yellow
    $confirm = Read-Host "Continue? [y/N]"
    if ($confirm -notmatch '^[Yy]$') {
        Write-Host "Cancelled — nothing was done."
        exit 1
    }
}

Log "=== 12_create_dev_user.ps1 ==="
Log "Mode: $(if ($Apply) { 'APPLY' } else { 'DRY RUN' })"
Log "UserName: $UserName"

$existing = Get-LocalUser -Name $UserName -ErrorAction SilentlyContinue
if ($existing) {
    Log "[skip] User '$UserName' already exists — leaving it alone."
    exit 0
}

if (-not $Apply) {
    Log "[dry-run] Would create user '$UserName' (New-LocalUser, standard, not added to Administrators)."
    Log "Re-run with -Apply to actually create the account."
    exit 0
}

Log "You will now be prompted for a password for '$UserName' (entered hidden)."
$securePassword = Read-Host -AsSecureString "Password for $UserName"

New-LocalUser -Name $UserName -Password $securePassword -FullName $UserName -Description "Isolated dev profile (not admin)" | Out-Null

if (-not (Get-LocalUser -Name $UserName -ErrorAction SilentlyContinue)) {
    Log "[error] '$UserName' was not created — see the New-LocalUser output above."
    exit 1
}

# Safety net: New-LocalUser doesn't add to Administrators by itself, but
# check explicitly — the same caution as in 09_create_profiles.sh.
$adminMembers = Get-LocalGroupMember -Group "Administrators" -ErrorAction SilentlyContinue
$isAdmin = $adminMembers | Where-Object { $_.Name -like "*\$UserName" -or $_.Name -eq $UserName }
if ($isAdmin) {
    Log "[warn] '$UserName' ended up in the Administrators group — removing (this role must stay isolated)."
    Remove-LocalGroupMember -Group "Administrators" -Member $UserName
}

# Make sure the account is in the regular "Users" group (New-LocalUser's
# default, but check explicitly like everything else here).
$usersMembers = Get-LocalGroupMember -Group "Users" -ErrorAction SilentlyContinue
if (-not ($usersMembers | Where-Object { $_.Name -like "*\$UserName" -or $_.Name -eq $UserName })) {
    Add-LocalGroupMember -Group "Users" -Member $UserName
}

Log "[ok] Created standard user '$UserName'."
Log "Verify: Get-LocalUser $UserName; Get-LocalGroupMember Administrators (should not be there)."
Log "Log written to: $LogFile"
