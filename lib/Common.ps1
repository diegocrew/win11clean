#Requires -Version 5.1
# Shared helpers for win11clean scripts. Dot-source this file; do not run it directly.
# Every change is recorded (with the original value) so Restore.ps1 can revert it.

Set-StrictMode -Version 2.0

$script:W11C_DryRun    = $false
$script:W11C_Name      = $null
$script:W11C_Changes   = New-Object 'System.Collections.Generic.List[object]'
$script:W11C_BackupDir = Join-Path (Split-Path $PSScriptRoot -Parent) 'backups'

function Test-IsAdmin {
    $id = [Security.Principal.WindowsIdentity]::GetCurrent()
    (New-Object Security.Principal.WindowsPrincipal $id).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

function Start-W11Clean {
    param(
        [Parameter(Mandatory)][string]$Name,
        [switch]$DryRun
    )
    if (-not (Test-IsAdmin)) {
        throw 'This script must be run from an elevated PowerShell (Run as administrator).'
    }
    $script:W11C_Name   = $Name
    $script:W11C_DryRun = [bool]$DryRun
    $script:W11C_Changes.Clear()
    Write-Host ''
    Write-Host "=== $Name ===" -ForegroundColor Cyan
    if ($DryRun) { Write-Host '    (dry run - nothing will be changed)' -ForegroundColor Yellow }
}

function Write-Section {
    param([string]$Text)
    Write-Host "  -- $Text" -ForegroundColor DarkCyan
}

function Complete-W11Clean {
    $count = $script:W11C_Changes.Count
    if ($script:W11C_DryRun) {
        Write-Host "  Dry run: $count change(s) would be made." -ForegroundColor Yellow
        return
    }
    if ($count -eq 0) {
        Write-Host '  Nothing to change - already configured.' -ForegroundColor Green
        return
    }
    if (-not (Test-Path $script:W11C_BackupDir)) {
        New-Item -ItemType Directory -Path $script:W11C_BackupDir | Out-Null
    }
    $file = Join-Path $script:W11C_BackupDir ('{0:yyyyMMdd-HHmmss}-{1}.json' -f (Get-Date), $script:W11C_Name)
    ConvertTo-Json -InputObject $script:W11C_Changes.ToArray() -Depth 5 | Set-Content -Path $file -Encoding UTF8
    Write-Host "  $count change(s) applied. Original values saved to: $file" -ForegroundColor Green
}

function Set-RegValue {
    param(
        [Parameter(Mandatory)][string]$Path,
        [Parameter(Mandatory)][string]$Name,
        [Parameter(Mandatory)]$Value,
        [ValidateSet('DWord', 'QWord', 'String', 'ExpandString', 'MultiString', 'Binary')]
        [string]$Type = 'DWord'
    )

    try {
        $keyExisted = Test-Path -LiteralPath $Path
        $hadValue = $false
        $oldValue = $null
        $oldType  = $null

        if ($keyExisted) {
            $key = Get-Item -LiteralPath $Path
            if ($key.GetValueNames() -contains $Name) {
                $hadValue = $true
                $oldValue = $key.GetValue($Name, $null, 'DoNotExpandEnvironmentNames')
                $oldType  = $key.GetValueKind($Name).ToString()
            }
        }

        if ($hadValue -and $oldType -eq $Type -and
            $Type -notin @('MultiString', 'Binary') -and "$oldValue" -eq "$Value") {
            return
        }

        Write-Host "    [reg]  $Path\$Name = $Value"
        if (-not $script:W11C_DryRun) {
            if (-not $keyExisted) { New-Item -Path $Path -Force -ErrorAction Stop | Out-Null }
            New-ItemProperty -LiteralPath $Path -Name $Name -Value $Value -PropertyType $Type -Force -ErrorAction Stop | Out-Null
        }

        $script:W11C_Changes.Add([pscustomobject]@{
            Kind       = 'Registry'
            Path       = $Path
            Name       = $Name
            KeyExisted = $keyExisted
            HadValue   = $hadValue
            OldValue   = $oldValue
            OldType    = $oldType
        })
    }
    catch {
        Write-Warning "Failed to set $Path\$Name : $($_.Exception.Message)"
    }
}

function Disable-ServiceSafe {
    # Disabling via the Start value lets Restore.ps1 put back the exact original start type.
    param([Parameter(Mandatory)][string]$Name)

    $svcKey = "HKLM:\SYSTEM\CurrentControlSet\Services\$Name"
    if (-not (Test-Path -LiteralPath $svcKey)) {
        Write-Verbose "Service $Name not present - skipped."
        return
    }
    Set-RegValue -Path $svcKey -Name 'Start' -Value 4
    if (-not $script:W11C_DryRun) {
        $svc = Get-Service -Name $Name -ErrorAction SilentlyContinue
        if ($svc -and $svc.Status -ne 'Stopped') {
            Write-Host "    [svc]  stopping $Name"
            Stop-Service -Name $Name -Force -ErrorAction SilentlyContinue
        }
    }
}

function Disable-TaskSafe {
    param([Parameter(Mandatory)][string]$FullName)   # e.g. '\Microsoft\Windows\Autochk\Proxy'

    $i = $FullName.LastIndexOf('\')
    $taskPath = $FullName.Substring(0, $i + 1)
    $taskName = $FullName.Substring($i + 1)

    $task = Get-ScheduledTask -TaskPath $taskPath -TaskName $taskName -ErrorAction SilentlyContinue
    if (-not $task) {
        Write-Verbose "Task $FullName not present - skipped."
        return
    }
    $oldState = $task.State.ToString()
    if ($oldState -eq 'Disabled') { return }

    Write-Host "    [task] disable $FullName"
    try {
        if (-not $script:W11C_DryRun) {
            Disable-ScheduledTask -TaskPath $taskPath -TaskName $taskName -ErrorAction Stop | Out-Null
        }
        $script:W11C_Changes.Add([pscustomobject]@{
            Kind     = 'Task'
            TaskPath = $taskPath
            TaskName = $taskName
            OldState = $oldState
        })
    }
    catch {
        Write-Warning "Failed to disable task $FullName : $($_.Exception.Message)"
    }
}
