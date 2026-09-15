<#
.SYNOPSIS
    Quiets Windows down: Start menu ads/suggestions, the OneDrive
    auto-start nag, Cortana/web results bleeding into Start search,
    Widgets, tailored-experience/advertising-ID tracking, lock screen
    Spotlight ads -- plus machine-wide telemetry (the DiagTrack service
    and the AllowTelemetry policy). Same target audience as
    12_create_dev_user.ps1 / 13_setup_dev_environment.ps1: a quiet,
    minimal dev machine, as close to a plain desktop as Windows allows
    without trading away real functionality or security.

.DESCRIPTION
    Deliberately conservative. NOT touched on purpose, because each of
    these trades off real functionality or security: Windows Update,
    Microsoft Defender, removing built-in/provisioned apps, any other
    service beyond the two telemetry-only ones listed below.

    Design decisions (same conventions as 12_create_dev_user.ps1):
      - Dry-run by default. Nothing changes unless -Apply is passed.
        Same -Apply flag also gates -Remove (rollback) -- one "make it
        real" switch for both directions.
      - First real run (no log yet in this same folder) asks for
        confirmation once, for the forward direction. -Remove asks for
        confirmation every time instead -- rolling back is destructive on
        every run, not just the first.
      - Idempotent: re-running only touches values that aren't already
        set the way this script wants them.
      - One failed item doesn't abort the rest -- collected into a
        summary at the end, like 13_setup_dev_environment.ps1.

    SCOPE -- per-profile (targets -UserName's already-existing profile if
    it has logged in at least once, AND the Default profile template so
    any future new local account inherits this too):
      - Start menu ads/suggestions/tips (ContentDeliveryManager)
      - OneDrive auto-start entry at logon (just the nag, not the app)
      - Cortana / Bing web results bleeding into Start menu search
      - Widgets button hidden from the taskbar
      - Tailored experiences from diagnostic data + per-app advertising ID
      - Lock screen Windows Spotlight ads

    SCOPE -- machine-wide (affects every account on this machine,
    including the admin one you're running this from):
      - AllowTelemetry policy set to the minimum this Windows SKU allows
      - Advertising ID disabled machine-wide via policy (belt-and-braces
        on top of the per-profile value above)
      - "Connected User Experiences and Telemetry" (DiagTrack) service
        disabled
      - "WAP Push Message Routing Service" (dmwappushsvc) disabled

.PARAMETER UserName
    Existing local user whose already-created profile (if any) should
    also get the per-profile tweaks, on top of the Default profile
    template (default "dev").

.PARAMETER Apply
    Actually change things. Without this flag -- dry-run only, prints
    what would change.

.PARAMETER Remove
    Roll back: delete the registry values this script set (restoring
    default Windows behavior) and re-enable the two services. Can't
    un-hide anything Windows itself had already changed before you first
    ran this script with -Apply -- there's no way to tell that apart from
    what this script set, so it isn't attempted.

.EXAMPLE
    .\14_reduce_windows_bloat.ps1                  # dry-run
    .\14_reduce_windows_bloat.ps1 -Apply           # actually apply
    .\14_reduce_windows_bloat.ps1 -Remove          # dry-run: what rollback would restore
    .\14_reduce_windows_bloat.ps1 -Remove -Apply   # actually roll back
#>
param(
    [string]$UserName = "dev",
    [switch]$Apply,
    [switch]$Remove
)

$ErrorActionPreference = "Stop"

$currentPrincipal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
if (-not $currentPrincipal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Host "This script must run as Administrator (it changes machine-wide policy and services, and mounts other profiles' registry hives)." -ForegroundColor Red
    Write-Host ""
    Write-Host "How to fix:" -ForegroundColor Yellow
    Write-Host "  1. Close this window."
    Write-Host "  2. Press Win, type PowerShell (or Windows Terminal), right-click it,"
    Write-Host "     choose 'Run as administrator'."
    Write-Host "  3. cd back into this scripts folder and run the exact same command again."
    exit 1
}

$LogDir = Join-Path $PSScriptRoot "logs"
New-Item -ItemType Directory -Force -Path $LogDir | Out-Null
$LogFile = Join-Path $LogDir "14_reduce_windows_bloat_$(Get-Date -Format 'yyyyMMdd_HHmmss').log"

function Log($msg) {
    $line = "[{0}] {1}" -f (Get-Date -Format "yyyy-MM-dd HH:mm:ss"), $msg
    Write-Host $line
    Add-Content -Path $LogFile -Value $line -Encoding UTF8
}

# ---------------------------------------------------------------------------
# What this script manages
# ---------------------------------------------------------------------------

# Per-profile DWORD values. Path is relative to the profile hive root
# (i.e. what would be HKCU:\ for a logged-in user).
$ProfileValues = @(
    @{ Path = "Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager"; Name = "SubscribedContent-338388Enabled"; Value = 0; Desc = "Start menu app suggestions" }
    @{ Path = "Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager"; Name = "SubscribedContent-338389Enabled"; Value = 0; Desc = "Start menu tips/suggestions notifications" }
    @{ Path = "Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager"; Name = "SystemPaneSuggestionsEnabled";    Value = 0; Desc = "Settings app suggestions" }
    @{ Path = "Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager"; Name = "SilentInstalledAppsEnabled";      Value = 0; Desc = "Silently-installed suggested apps" }
    @{ Path = "Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager"; Name = "PreInstalledAppsEnabled";         Value = 0; Desc = "Suggested app pre-installs" }
    @{ Path = "Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager"; Name = "OemPreInstalledAppsEnabled";      Value = 0; Desc = "OEM suggested app pre-installs" }
    @{ Path = "Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager"; Name = "ContentDeliveryAllowed";          Value = 0; Desc = "Content delivery (ads/suggestions) overall" }
    @{ Path = "Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager"; Name = "SoftLandingEnabled";              Value = 0; Desc = "Start menu 'suggested' tile" }
    @{ Path = "Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager"; Name = "RotatingLockScreenEnabled";       Value = 0; Desc = "Lock screen Spotlight rotating images" }
    @{ Path = "Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager"; Name = "RotatingLockScreenOverlayEnabled"; Value = 0; Desc = "Lock screen Spotlight overlay/ads" }
    @{ Path = "Software\Policies\Microsoft\Windows\CloudContent"; Name = "DisableWindowsSpotlightFeatures";                Value = 1; Desc = "Windows Spotlight lock screen ads (policy)" }
    @{ Path = "Software\Policies\Microsoft\Windows\CloudContent"; Name = "DisableTailoredExperiencesWithDiagnosticData";   Value = 1; Desc = "Tailored tips/ads from diagnostic data" }
    @{ Path = "Software\Microsoft\Windows\CurrentVersion\AdvertisingInfo"; Name = "Enabled";                                Value = 0; Desc = "Per-app advertising ID" }
    @{ Path = "Software\Microsoft\Windows\CurrentVersion\Search"; Name = "BingSearchEnabled";                              Value = 0; Desc = "Bing web results in Start search" }
    @{ Path = "Software\Microsoft\Windows\CurrentVersion\Search"; Name = "CortanaConsent";                                 Value = 0; Desc = "Cortana consent / web search" }
    @{ Path = "Software\Microsoft\Windows\CurrentVersion\SearchSettings"; Name = "IsDeviceSearchHistoryEnabled";           Value = 0; Desc = "Device search history" }
    @{ Path = "Software\Microsoft\Windows\CurrentVersion\Feeds"; Name = "ShellFeedsTaskbarViewMode";                       Value = 2; Desc = "Widgets button on the taskbar (2 = hidden)" }
)

# The OneDrive auto-start entry -- handled separately below since forward
# direction is "delete the value" rather than "set it to N".
$ProfileRunKeyPath = "Software\Microsoft\Windows\CurrentVersion\Run"
$ProfileRunKeyName = "OneDrive"

# Machine-wide (HKLM) DWORD values.
$MachineValues = @(
    @{ Path = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection"; Name = "AllowTelemetry";      Value = 0; Desc = "Diagnostic data collection level (policy)" }
    @{ Path = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\AdvertisingInfo"; Name = "DisabledByGroupPolicy"; Value = 1; Desc = "Advertising ID (machine-wide policy)" }
)

# Telemetry-only services. DefaultStartupType is what a stock Windows
# install ships with -- used by -Remove to restore them, since we don't
# snapshot the actual prior value before changing it.
$MachineServices = @(
    @{ Name = "DiagTrack";      DisplayName = "Connected User Experiences and Telemetry"; DefaultStartupType = "Automatic" }
    @{ Name = "dmwappushsvc";   DisplayName = "WAP Push Message Routing Service";          DefaultStartupType = "Manual" }
)

# ---------------------------------------------------------------------------
# Registry helpers (work against any already-reachable key path, whether
# that's HKLM:\... directly or a mounted offline hive's PSDrive)
# ---------------------------------------------------------------------------

function Apply-RegDword {
    param([string]$KeyPath, [string]$Name, [int]$Value, [string]$Desc)

    $existing = $null
    if (Test-Path $KeyPath) {
        $prop = Get-ItemProperty -Path $KeyPath -Name $Name -ErrorAction SilentlyContinue
        if ($prop -and ($prop.PSObject.Properties.Name -contains $Name)) { $existing = $prop.$Name }
    }

    if ($existing -eq $Value) {
        Log "  [skip] $Desc (already $Value)"
        return $null
    }

    if (-not $Apply) {
        Log "  [dry-run] $Desc : $existing -> $Value"
        return $null
    }

    try {
        if (-not (Test-Path $KeyPath)) { New-Item -Path $KeyPath -Force | Out-Null }
        New-ItemProperty -Path $KeyPath -Name $Name -PropertyType DWord -Value $Value -Force | Out-Null
        Log "  [ok] $Desc : $existing -> $Value"
        return $null
    } catch {
        Log "  [warn] $Desc : failed to set -- $_"
        return $Desc
    }
}

function Remove-RegDword {
    param([string]$KeyPath, [string]$Name, [string]$Desc)

    if (-not (Test-Path $KeyPath)) {
        Log "  [skip] $Desc (key not present)"
        return $null
    }
    $prop = Get-ItemProperty -Path $KeyPath -Name $Name -ErrorAction SilentlyContinue
    if (-not $prop -or -not ($prop.PSObject.Properties.Name -contains $Name)) {
        Log "  [skip] $Desc (not set)"
        return $null
    }

    if (-not $Apply) {
        Log "  [dry-run] $Desc : would remove (restores Windows default)"
        return $null
    }

    try {
        Remove-ItemProperty -Path $KeyPath -Name $Name -Force -ErrorAction Stop
        Log "  [ok] $Desc : removed"
        return $null
    } catch {
        Log "  [warn] $Desc : failed to remove -- $_"
        return $Desc
    }
}

function Apply-ProfileValues {
    param([string]$KeyRoot, [string]$Label)

    Log "--- $Label ---"
    $failed = @()
    foreach ($item in $ProfileValues) {
        $keyPath = Join-Path $KeyRoot $item.Path
        $result = Apply-RegDword -KeyPath $keyPath -Name $item.Name -Value $item.Value -Desc $item.Desc
        if ($result) { $failed += "$Label : $result" }
    }

    $runKeyPath = Join-Path $KeyRoot $ProfileRunKeyPath
    if (Test-Path $runKeyPath) {
        $runProp = Get-ItemProperty -Path $runKeyPath -Name $ProfileRunKeyName -ErrorAction SilentlyContinue
        if ($runProp -and ($runProp.PSObject.Properties.Name -contains $ProfileRunKeyName)) {
            if (-not $Apply) {
                Log "  [dry-run] OneDrive auto-start at logon : would remove"
            } else {
                try {
                    Remove-ItemProperty -Path $runKeyPath -Name $ProfileRunKeyName -Force -ErrorAction Stop
                    Log "  [ok] OneDrive auto-start at logon : removed"
                } catch {
                    Log "  [warn] OneDrive auto-start at logon : failed to remove -- $_"
                    $failed += "$Label : OneDrive auto-start"
                }
            }
        } else {
            Log "  [skip] OneDrive auto-start at logon (not set)"
        }
    } else {
        Log "  [skip] OneDrive auto-start at logon (Run key not present)"
    }

    return $failed
}

function Remove-ProfileValues {
    param([string]$KeyRoot, [string]$Label)

    Log "--- $Label ---"
    $failed = @()
    foreach ($item in $ProfileValues) {
        $keyPath = Join-Path $KeyRoot $item.Path
        $result = Remove-RegDword -KeyPath $keyPath -Name $item.Name -Desc $item.Desc
        if ($result) { $failed += "$Label : $result" }
    }
    Log "  [skip] OneDrive auto-start at logon (rollback doesn't re-add it -- the exact original command line isn't known; re-enable manually via Task Manager > Startup apps, or reinstall/repair OneDrive, if you want it back)"
    return $failed
}

# ---------------------------------------------------------------------------
# Offline hive mount/unmount (for profiles that aren't the one running
# this script -- Default template, and -UserName's profile if it exists)
# ---------------------------------------------------------------------------

function Mount-OfflineHive {
    param([string]$NtUserPath)

    $mountName = "TempHive14_$([guid]::NewGuid().ToString('N'))"
    & reg.exe load "HKU\$mountName" "$NtUserPath" 2>&1 | Out-Null
    if ($LASTEXITCODE -ne 0) {
        throw "reg load failed for '$NtUserPath'"
    }
    New-PSDrive -PSProvider Registry -Name $mountName -Root "HKEY_USERS\$mountName" -Scope Script | Out-Null
    return $mountName
}

function Dismount-OfflineHive {
    param([string]$MountName)

    Remove-PSDrive -Name $MountName -Force -ErrorAction SilentlyContinue
    [gc]::Collect()
    [gc]::WaitForPendingFinalizers()
    Start-Sleep -Milliseconds 300
    & reg.exe unload "HKU\$MountName" 2>&1 | Out-Null
    if ($LASTEXITCODE -ne 0) {
        Log "  [warn] Could not unload the temporary hive mount HKU\$MountName -- it should clear on its own after a reboot; harmless otherwise."
    }
}

function Get-TargetProfileHives {
    $hives = @()

    $defaultNtUser = "$env:SystemDrive\Users\Default\NTUSER.DAT"
    if (Test-Path $defaultNtUser) {
        $hives += @{ Label = "Default profile template (future new local accounts)"; NtUserPath = $defaultNtUser }
    } else {
        Log "[warn] Default profile hive not found at $defaultNtUser -- skipping it."
    }

    $userNtUser = "$env:SystemDrive\Users\$UserName\NTUSER.DAT"
    if (Test-Path $userNtUser) {
        $hives += @{ Label = "'$UserName' profile"; NtUserPath = $userNtUser }
    } else {
        Log "[skip] '$UserName' has no profile yet (hasn't logged in) -- only the Default template will be updated; '$UserName' inherits it on first login."
    }

    return $hives
}

# ---------------------------------------------------------------------------
# Services
# ---------------------------------------------------------------------------

function Apply-Service {
    param($Svc)

    $service = Get-Service -Name $Svc.Name -ErrorAction SilentlyContinue
    if (-not $service) {
        Log "  [skip] $($Svc.DisplayName) (service not present on this system)"
        return $null
    }
    if ($service.StartType -eq 'Disabled') {
        Log "  [skip] $($Svc.DisplayName) (already disabled)"
        return $null
    }
    if (-not $Apply) {
        Log "  [dry-run] $($Svc.DisplayName) : $($service.StartType) -> Disabled"
        return $null
    }
    try {
        if ($service.Status -ne 'Stopped') { Stop-Service -Name $Svc.Name -Force -ErrorAction SilentlyContinue }
        Set-Service -Name $Svc.Name -StartupType Disabled
        Log "  [ok] $($Svc.DisplayName) : disabled"
        return $null
    } catch {
        Log "  [warn] $($Svc.DisplayName) : failed to disable -- $_"
        return $Svc.DisplayName
    }
}

function Remove-ServiceDisable {
    param($Svc)

    $service = Get-Service -Name $Svc.Name -ErrorAction SilentlyContinue
    if (-not $service) {
        Log "  [skip] $($Svc.DisplayName) (service not present on this system)"
        return $null
    }
    if ($service.StartType -ne 'Disabled') {
        Log "  [skip] $($Svc.DisplayName) (not disabled)"
        return $null
    }
    if (-not $Apply) {
        Log "  [dry-run] $($Svc.DisplayName) : Disabled -> $($Svc.DefaultStartupType)"
        return $null
    }
    try {
        Set-Service -Name $Svc.Name -StartupType $Svc.DefaultStartupType
        if ($Svc.DefaultStartupType -eq 'Automatic') { Start-Service -Name $Svc.Name -ErrorAction SilentlyContinue }
        Log "  [ok] $($Svc.DisplayName) : restored to $($Svc.DefaultStartupType)"
        return $null
    } catch {
        Log "  [warn] $($Svc.DisplayName) : failed to restore -- $_"
        return $Svc.DisplayName
    }
}

# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------

if ($Remove) {
    Log "=== 14_reduce_windows_bloat.ps1 (remove) ==="
    Log "Mode: $(if ($Apply) { 'REMOVE (APPLY)' } else { 'REMOVE (DRY RUN)' })"
    Log "UserName: $UserName"

    if ($Apply) {
        Write-Host ""
        Write-Host "About to restore machine-wide telemetry policy/services, and remove the" -ForegroundColor Red
        Write-Host "per-profile values this script set (Default profile template + '$UserName' if it exists)." -ForegroundColor Red
        $removeConfirm = Read-Host "Continue? [y/N]"
        if ($removeConfirm -notmatch '^[Yy]$') {
            Log "Cancelled -- nothing was restored."
            exit 1
        }
    }

    $Failed = @()

    Log "=== Machine-wide ==="
    foreach ($item in $MachineValues) {
        $result = Remove-RegDword -KeyPath $item.Path -Name $item.Name -Desc $item.Desc
        if ($result) { $Failed += "machine : $result" }
    }
    foreach ($svc in $MachineServices) {
        $result = Remove-ServiceDisable -Svc $svc
        if ($result) { $Failed += "machine : $result" }
    }

    foreach ($hive in (Get-TargetProfileHives)) {
        try {
            $mount = Mount-OfflineHive -NtUserPath $hive.NtUserPath
            try {
                $Failed += (Remove-ProfileValues -KeyRoot "${mount}:\" -Label $hive.Label)
            } finally {
                Dismount-OfflineHive -MountName $mount
            }
        } catch {
            Log "  [warn] $($hive.Label) : could not mount/process -- $_"
            $Failed += "$($hive.Label) : mount failed"
        }
    }

    Log "=== Summary ==="
    if ($Failed.Count -gt 0) {
        Log "Failed to restore: $($Failed -join '; ')"
    } else {
        Log "Done."
    }
    Log "Log written to: $LogFile"
    exit 0
}

$existingLogs = Get-ChildItem -Path $LogDir -Filter "14_reduce_windows_bloat_*.log" -ErrorAction SilentlyContinue
if (-not $existingLogs) {
    Write-Host "This looks like the first real run of 14_reduce_windows_bloat.ps1 (no log yet)." -ForegroundColor Yellow
    Write-Host "It changes machine-wide telemetry policy/services and per-profile registry values." -ForegroundColor Yellow
    Write-Host "See the .DESCRIPTION in the script (or 14_reduce_windows_bloat.md) for the exact scope." -ForegroundColor Yellow
    $confirm = Read-Host "Continue? [y/N]"
    if ($confirm -notmatch '^[Yy]$') {
        Write-Host "Cancelled -- nothing was done."
        exit 1
    }
}

Log "=== 14_reduce_windows_bloat.ps1 ==="
Log "Mode: $(if ($Apply) { 'APPLY' } else { 'DRY RUN' })"
Log "UserName: $UserName"

$Failed = @()

Log "=== Machine-wide ==="
foreach ($item in $MachineValues) {
    $result = Apply-RegDword -KeyPath $item.Path -Name $item.Name -Value $item.Value -Desc $item.Desc
    if ($result) { $Failed += "machine : $result" }
}
foreach ($svc in $MachineServices) {
    $result = Apply-Service -Svc $svc
    if ($result) { $Failed += "machine : $result" }
}

foreach ($hive in (Get-TargetProfileHives)) {
    try {
        $mount = Mount-OfflineHive -NtUserPath $hive.NtUserPath
        try {
            $Failed += (Apply-ProfileValues -KeyRoot "${mount}:\" -Label $hive.Label)
        } finally {
            Dismount-OfflineHive -MountName $mount
        }
    } catch {
        Log "  [warn] $($hive.Label) : could not mount/process -- $_"
        $Failed += "$($hive.Label) : mount failed"
    }
}

Log "=== Summary ==="
if ($Failed.Count -gt 0) {
    Log "Failed: $($Failed -join '; ')"
    Log "Re-run the script after investigating -- it will only retry what's not already set."
} else {
    Log "Everything applied successfully."
}
if (-not $Apply) {
    Log "Re-run with -Apply to actually change anything."
}
Log "Log written to: $LogFile"
