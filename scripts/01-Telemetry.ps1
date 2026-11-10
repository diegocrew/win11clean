#Requires -RunAsAdministrator
<#
.SYNOPSIS
    Disables Windows diagnostic data (telemetry), CEIP, error reporting and related services/tasks.
.NOTES
    AllowTelemetry=0 ("Security") is honoured only on Enterprise/Education/Server.
    Home/Pro clamp it to 1 ("Required"); disabling DiagTrack below stops the upload on all editions.
#>
[CmdletBinding()]
param([switch]$DryRun)

. (Join-Path $PSScriptRoot '..\lib\Common.ps1')
Start-W11Clean -Name 'Telemetry' -DryRun:$DryRun

$dc = 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection'

Write-Section 'Diagnostic data policies'
Set-RegValue $dc 'AllowTelemetry' 0
Set-RegValue $dc 'MaxTelemetryAllowed' 0
Set-RegValue $dc 'AllowDeviceNameInTelemetry' 0
Set-RegValue $dc 'DoNotShowFeedbackNotifications' 1
Set-RegValue $dc 'DisableOneSettingsDownloads' 1
Set-RegValue $dc 'LimitDiagnosticLogCollection' 1
Set-RegValue $dc 'LimitDumpCollection' 1
Set-RegValue $dc 'DisableEnterpriseAuthProxy' 1
Set-RegValue $dc 'DisableDiagnosticDataViewer' 1
Set-RegValue 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\DataCollection' 'AllowTelemetry' 0

Write-Section 'Tailored experiences / feedback prompts'
Set-RegValue 'HKCU:\Software\Policies\Microsoft\Windows\CloudContent' 'DisableTailoredExperiencesWithDiagnosticData' 1
Set-RegValue 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Privacy' 'TailoredExperiencesWithDiagnosticDataEnabled' 0
Set-RegValue 'HKCU:\Software\Microsoft\Siuf\Rules' 'NumberOfSIUFInPeriod' 0
Set-RegValue 'HKCU:\Software\Microsoft\Input\TIPC' 'Enabled' 0

Write-Section 'Customer Experience Improvement Program / Application telemetry'
Set-RegValue 'HKLM:\SOFTWARE\Policies\Microsoft\SQMClient\Windows' 'CEIPEnable' 0
Set-RegValue 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\AppCompat' 'AITEnable' 0
Set-RegValue 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\AppCompat' 'DisableInventory' 1
Set-RegValue 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\AppCompat' 'DisableUAR' 1

Write-Section 'Windows Error Reporting'
Set-RegValue 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Error Reporting' 'Disabled' 1
Set-RegValue 'HKLM:\SOFTWARE\Microsoft\Windows\Windows Error Reporting' 'Disabled' 1
Set-RegValue 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\HandwritingErrorReports' 'PreventHandwritingErrorReports' 1
Set-RegValue 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\TabletPC' 'PreventHandwritingDataSharing' 1

Write-Section 'Telemetry services'
Disable-ServiceSafe 'DiagTrack'           # Connected User Experiences and Telemetry
Disable-ServiceSafe 'dmwappushservice'    # WAP Push routing (used by telemetry)

Write-Section 'Telemetry scheduled tasks'
@(
    '\Microsoft\Windows\Application Experience\Microsoft Compatibility Appraiser'
    '\Microsoft\Windows\Application Experience\Microsoft Compatibility Appraiser Exp'
    '\Microsoft\Windows\Application Experience\ProgramDataUpdater'
    '\Microsoft\Windows\Application Experience\MareBackup'
    '\Microsoft\Windows\Autochk\Proxy'
    '\Microsoft\Windows\Customer Experience Improvement Program\Consolidator'
    '\Microsoft\Windows\Customer Experience Improvement Program\UsbCeip'
    '\Microsoft\Windows\Customer Experience Improvement Program\KernelCeipTask'
    '\Microsoft\Windows\DiskDiagnostic\Microsoft-Windows-DiskDiagnosticDataCollector'
    '\Microsoft\Windows\Feedback\Siuf\DmClient'
    '\Microsoft\Windows\Feedback\Siuf\DmClientOnScenarioDownload'
    '\Microsoft\Windows\Windows Error Reporting\QueueReporting'
    '\Microsoft\Windows\Maps\MapsToastTask'
    '\Microsoft\Windows\Maps\MapsUpdateTask'
) | ForEach-Object { Disable-TaskSafe $_ }

Write-Section 'Opt out of Microsoft dev-tool telemetry (PowerShell 7, .NET CLI)'
$envKey = 'HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Environment'
Set-RegValue $envKey 'POWERSHELL_TELEMETRY_OPTOUT' '1' -Type String
Set-RegValue $envKey 'DOTNET_CLI_TELEMETRY_OPTOUT' '1' -Type String

Complete-W11Clean
