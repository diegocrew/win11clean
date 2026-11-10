#Requires -RunAsAdministrator
<#
.SYNOPSIS
    Disables Windows Copilot, Recall (AI snapshots) and Click to Do.
.PARAMETER RemoveCopilotApp
    Also uninstalls the Microsoft Copilot app for all users. This is NOT reverted by Restore.ps1
    (reinstall it from the Microsoft Store if needed).
#>
[CmdletBinding()]
param(
    [switch]$DryRun,
    [switch]$RemoveCopilotApp
)

. (Join-Path $PSScriptRoot '..\lib\Common.ps1')
Start-W11Clean -Name 'AI' -DryRun:$DryRun

Write-Section 'Windows Copilot'
Set-RegValue 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsCopilot' 'TurnOffWindowsCopilot' 1
Set-RegValue 'HKCU:\Software\Policies\Microsoft\Windows\WindowsCopilot' 'TurnOffWindowsCopilot' 1
Set-RegValue 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced' 'ShowCopilotButton' 0

Write-Section 'Recall & Click to Do'
$aiM = 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsAI'
Set-RegValue $aiM 'DisableAIDataAnalysis' 1
Set-RegValue $aiM 'AllowRecallEnablement' 0
Set-RegValue $aiM 'DisableClickToDo' 1
$aiU = 'HKCU:\Software\Policies\Microsoft\Windows\WindowsAI'
Set-RegValue $aiU 'DisableAIDataAnalysis' 1
Set-RegValue $aiU 'DisableClickToDo' 1

if ($RemoveCopilotApp) {
    Write-Section 'Removing Microsoft Copilot app'
    $pkgs = @(Get-AppxPackage -AllUsers -Name 'Microsoft.Copilot' -ErrorAction SilentlyContinue)
    foreach ($p in $pkgs) {
        Write-Host "    [appx] remove $($p.PackageFullName)"
        if (-not $DryRun) {
            try { Remove-AppxPackage -Package $p.PackageFullName -AllUsers -ErrorAction Stop }
            catch { Write-Warning "Failed to remove $($p.PackageFullName): $($_.Exception.Message)" }
        }
    }
}

Complete-W11Clean
