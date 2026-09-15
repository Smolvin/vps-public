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
        Same -Apply flag also gates -Remove (see below) -- one "make it
        real" switch for both directions.
      - The password is never passed as a parameter or hardcoded — it's
        entered interactively via Read-Host -AsSecureString.
      - First real run (no log yet in this same folder) prints a warning
        and asks for confirmation — creating a real Windows account needs
        admin. Doesn't ask again once a log exists. -Remove has its own
        confirmation every time instead (see -Remove below), since
        deleting an account is destructive on every run, not just the
        first.
      - Idempotent: an existing account is left alone (create mode just
        re-checks/fixes its group membership), safe to re-run.
      - If the account somehow ends up in the Administrators group —
        removes it (this role must stay ISOLATED, nothing more).

.PARAMETER UserName
    Name of the user to create or remove (default "dev").

.PARAMETER Apply
    Actually create the account (or, with -Remove, actually delete it).
    Without this flag — dry-run only, prints what would happen.

.PARAMETER Remove
    Roll back: delete the local user account instead of creating one.
    Does NOT delete the account's profile folder
    (C:\Users\<UserName>) or its files -- remove those separately if you
    want them gone too.

.EXAMPLE
    .\12_create_dev_user.ps1                  # dry-run create
    .\12_create_dev_user.ps1 -Apply           # actually create
    .\12_create_dev_user.ps1 -Remove          # dry-run: what removal would do
    .\12_create_dev_user.ps1 -Remove -Apply   # actually delete the account
#>
param(
    [string]$UserName = "dev",
    [switch]$Apply,
    [switch]$Remove
)

$ErrorActionPreference = "Stop"

$currentPrincipal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
if (-not $currentPrincipal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Host "This script must run as Administrator (it creates a real Windows account)." -ForegroundColor Red
    Write-Host ""
    Write-Host "How to fix:" -ForegroundColor Yellow
    Write-Host "  1. Close this window."
    Write-Host "  2. Press Win, type PowerShell (or Windows Terminal), right-click it,"
    Write-Host "     choose 'Run as administrator'."
    Write-Host "  3. cd back into this scripts folder and run the exact same command again."
    Write-Host ""
    Write-Host "See the 'Troubleshooting' section in 12_create_dev_user.md / .en.md for" -ForegroundColor Yellow
    Write-Host "other common first-run issues (e.g. execution policy)." -ForegroundColor Yellow
    exit 1
}

$LogDir = Join-Path $PSScriptRoot "logs"
New-Item -ItemType Directory -Force -Path $LogDir | Out-Null
$LogFile = Join-Path $LogDir "12_create_dev_user_$(Get-Date -Format 'yyyyMMdd_HHmmss').log"

function Log($msg) {
    $line = "[{0}] {1}" -f (Get-Date -Format "yyyy-MM-dd HH:mm:ss"), $msg
    Write-Host $line
    Add-Content -Path $LogFile -Value $line -Encoding UTF8
}

if ($Remove) {
    Log "=== 12_create_dev_user.ps1 (remove) ==="
    Log "Mode: $(if ($Apply) { 'REMOVE (APPLY)' } else { 'REMOVE (DRY RUN)' })"
    Log "UserName: $UserName"

    $existingForRemoval = Get-LocalUser -Name $UserName -ErrorAction SilentlyContinue
    if (-not $existingForRemoval) {
        Log "[skip] User '$UserName' does not exist — nothing to remove."
        exit 0
    }

    if (-not $Apply) {
        Log "[dry-run] Would delete local user '$UserName' (Remove-LocalUser)."
        Log "This does NOT delete C:\Users\$UserName or its files -- that's a separate, manual step."
        Log "Re-run with -Remove -Apply to actually delete the account."
        exit 0
    }

    Write-Host ""
    Write-Host "About to permanently delete the local Windows account '$UserName'." -ForegroundColor Red
    Write-Host "This does NOT delete C:\Users\$UserName or its files -- do that separately if you want them gone too." -ForegroundColor Yellow
    $removeConfirm = Read-Host "Continue? [y/N]"
    if ($removeConfirm -notmatch '^[Yy]$') {
        Log "Cancelled — nothing was removed."
        exit 1
    }

    Remove-LocalUser -Name $UserName

    if (Get-LocalUser -Name $UserName -ErrorAction SilentlyContinue) {
        Log "[error] '$UserName' still exists after Remove-LocalUser — see the error above."
        exit 1
    }

    Log "[ok] Removed local user '$UserName'."
    Log "Profile folder (if any) was left in place: C:\Users\$UserName"
    Log "Log written to: $LogFile"
    exit 0
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

if ($existing -and -not $Apply) {
    Log "[skip] User '$UserName' already exists — leaving it alone."
    exit 0
}

if (-not $existing -and -not $Apply) {
    Log "[dry-run] Would create user '$UserName' (New-LocalUser, standard, not added to Administrators)."
    Log "Re-run with -Apply to actually create the account."
    exit 0
}

if ($existing) {
    Log "[skip] User '$UserName' already exists — not touching the account itself, only re-checking its group membership below (safe to re-run, e.g. after a previous run failed partway through)."
} else {
    Log "You will now be prompted for a password for '$UserName' (entered hidden)."
    $securePassword = Read-Host -AsSecureString "Password for $UserName"

    New-LocalUser -Name $UserName -Password $securePassword -FullName $UserName -Description "Isolated dev profile (not admin)" | Out-Null

    if (-not (Get-LocalUser -Name $UserName -ErrorAction SilentlyContinue)) {
        Log "[error] '$UserName' was not created — see the New-LocalUser output above."
        exit 1
    }
}

# Resolve the built-in Administrators/Users groups by their well-known SID
# rather than by English name -- on a localized Windows (e.g. Russian,
# Ukrainian) these groups are actually named "Администраторы"/"Пользователи"
# etc., so "Administrators"/"Users" literal lookups fail with
# GroupNotFoundException even though the groups exist.
$AdministratorsGroup = Get-LocalGroup -SID "S-1-5-32-544"
$UsersGroup = Get-LocalGroup -SID "S-1-5-32-545"

# Safety net: New-LocalUser doesn't add to Administrators by itself, but
# check explicitly — the same caution as in 09_create_profiles.sh.
$adminMembers = Get-LocalGroupMember -Group $AdministratorsGroup -ErrorAction SilentlyContinue
$isAdmin = $adminMembers | Where-Object { $_.Name -like "*\$UserName" -or $_.Name -eq $UserName }
if ($isAdmin) {
    Log "[warn] '$UserName' ended up in the $($AdministratorsGroup.Name) group — removing (this role must stay isolated)."
    Remove-LocalGroupMember -Group $AdministratorsGroup -Member $UserName
}

# Make sure the account is in the regular Users group (New-LocalUser's
# default, but check explicitly like everything else here).
$usersMembers = Get-LocalGroupMember -Group $UsersGroup -ErrorAction SilentlyContinue
if (-not ($usersMembers | Where-Object { $_.Name -like "*\$UserName" -or $_.Name -eq $UserName })) {
    Add-LocalGroupMember -Group $UsersGroup -Member $UserName
}

if ($existing) {
    Log "[ok] '$UserName' group membership verified/fixed."
} else {
    Log "[ok] Created standard user '$UserName'."
}
Log "Verify: Get-LocalUser $UserName; Get-LocalGroupMember $($AdministratorsGroup.Name) (should not be there)."
Log "Log written to: $LogFile"
