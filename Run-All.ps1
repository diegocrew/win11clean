#Requires -RunAsAdministrator
<#
.SYNOPSIS
    Runs all win11clean scripts in order (scripts\0*.ps1).
.PARAMETER DryRun
    Show what would change without changing anything.
.PARAMETER NoRestorePoint
    Skip creating a System Restore point before applying changes.
.PARAMETER Skip
    Script names (without .ps1) to skip, e.g. -Skip 05-Edge,04-AI
.EXAMPLE
    powershell -ExecutionPolicy Bypass -File .\Run-All.ps1 -DryRun
#>
[CmdletBinding()]
param(
    [switch]$DryRun,
    [switch]$NoRestorePoint,
    [string[]]$Skip = @()
)

. (Join-Path $PSScriptRoot 'lib\Common.ps1')
if (-not (Test-IsAdmin)) { throw 'Run this from an elevated PowerShell (Run as administrator).' }

if (-not $DryRun -and -not $NoRestorePoint) {
    Write-Host 'Creating System Restore point...' -ForegroundColor Cyan
    try {
        Enable-ComputerRestore -Drive "$env:SystemDrive\" -ErrorAction Stop
        Checkpoint-Computer -Description 'win11clean' -RestorePointType MODIFY_SETTINGS -ErrorAction Stop
    }
    catch {
        Write-Warning "Could not create a restore point ($($_.Exception.Message)). Continuing - JSON backups are still written."
    }
}

Get-ChildItem -Path (Join-Path $PSScriptRoot 'scripts') -Filter '0*.ps1' |
    Sort-Object Name |
    Where-Object { $Skip -notcontains $_.BaseName } |
    ForEach-Object { & $_.FullName -DryRun:$DryRun }

Write-Host ''
if ($DryRun) {
    Write-Host 'Dry run finished. Re-run without -DryRun to apply.' -ForegroundColor Yellow
}
else {
    Write-Host 'Done. Restart Windows for all changes to take effect.' -ForegroundColor Green
    Write-Host 'To undo: .\Restore.ps1' -ForegroundColor Green
}
