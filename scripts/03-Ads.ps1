#Requires -RunAsAdministrator
<#
.SYNOPSIS
    Removes ads, "suggestions", tips, promoted apps, Spotlight and account nags from Windows 11.
#>
[CmdletBinding()]
param([switch]$DryRun)

. (Join-Path $PSScriptRoot '..\lib\Common.ps1')
Start-W11Clean -Name 'Ads' -DryRun:$DryRun

Write-Section 'Content Delivery Manager (suggestions, promoted & silently installed apps)'
$cdm = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager'
@(
    'ContentDeliveryAllowed'
    'FeatureManagementEnabled'
    'OemPreInstalledAppsEnabled'
    'PreInstalledAppsEnabled'
    'PreInstalledAppsEverEnabled'
    'SilentInstalledAppsEnabled'
    'RotatingLockScreenEnabled'
    'RotatingLockScreenOverlayEnabled'
    'SoftLandingEnabled'
    'SystemPaneSuggestionsEnabled'
    'SubscribedContentEnabled'
    'SubscribedContent-310093Enabled'    # Windows welcome experience
    'SubscribedContent-338387Enabled'    # Lock screen fun facts & tips
    'SubscribedContent-338388Enabled'    # Start suggestions
    'SubscribedContent-338389Enabled'    # Tips and suggestions when using Windows
    'SubscribedContent-338393Enabled'    # Suggested content in Settings
    'SubscribedContent-353694Enabled'    # Suggested content in Settings
    'SubscribedContent-353696Enabled'    # Suggested content in Settings
    'SubscribedContent-353698Enabled'    # Timeline suggestions
    'SubscribedContent-88000326Enabled'  # Spotlight
) | ForEach-Object { Set-RegValue $cdm $_ 0 }

Write-Section 'Cloud content / Spotlight / consumer features'
$ccM = 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\CloudContent'
Set-RegValue $ccM 'DisableWindowsConsumerFeatures' 1
Set-RegValue $ccM 'DisableConsumerAccountStateContent' 1
Set-RegValue $ccM 'DisableCloudOptimizedContent' 1
Set-RegValue $ccM 'DisableSoftLanding' 1
$ccU = 'HKCU:\Software\Policies\Microsoft\Windows\CloudContent'
Set-RegValue $ccU 'DisableWindowsSpotlightFeatures' 1
Set-RegValue $ccU 'DisableThirdPartySuggestions' 1
Set-RegValue $ccU 'DisableSpotlightCollectionOnDesktop' 1
Set-RegValue $ccU 'DisableWindowsSpotlightOnActionCenter' 1
Set-RegValue $ccU 'DisableWindowsSpotlightOnSettings' 1
Set-RegValue $ccU 'DisableWindowsSpotlightWindowsWelcomeExperience' 1

Write-Section 'Start menu, File Explorer & Settings nags'
$adv = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced'
Set-RegValue $adv 'Start_IrisRecommendations' 0      # tips, shortcuts, new apps in Start
Set-RegValue $adv 'Start_AccountNotifications' 0     # Microsoft account nags in Start
Set-RegValue $adv 'ShowSyncProviderNotifications' 0  # OneDrive/M365 ads in File Explorer
Set-RegValue 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\Explorer' 'HideRecommendedPersonalizedSites' 1
Set-RegValue 'HKCU:\Software\Microsoft\Windows\CurrentVersion\UserProfileEngagement' 'ScoobeSystemSettingEnabled' 0
Set-RegValue 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Notifications\Settings\Windows.SystemToast.Suggested' 'Enabled' 0

Complete-W11Clean
