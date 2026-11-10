#Requires -RunAsAdministrator
<#
.SYNOPSIS
    Disables advertising ID, activity history, online speech/inking data collection,
    location tracking, cloud/web search and other personal-data tracking.
#>
[CmdletBinding()]
param([switch]$DryRun)

. (Join-Path $PSScriptRoot '..\lib\Common.ps1')
Start-W11Clean -Name 'Privacy' -DryRun:$DryRun

Write-Section 'Advertising ID'
Set-RegValue 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\AdvertisingInfo' 'DisabledByGroupPolicy' 1
Set-RegValue 'HKCU:\Software\Microsoft\Windows\CurrentVersion\AdvertisingInfo' 'Enabled' 0

Write-Section 'General privacy settings'
Set-RegValue 'HKCU:\Control Panel\International\User Profile' 'HttpAcceptLanguageOptOut' 1
Set-RegValue 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced' 'Start_TrackProgs' 0
Set-RegValue 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Explorer' 'AllowOnlineTips' 0

Write-Section 'Activity history / Timeline / cross-device clipboard'
$sys = 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\System'
Set-RegValue $sys 'EnableActivityFeed' 0
Set-RegValue $sys 'PublishUserActivities' 0
Set-RegValue $sys 'UploadUserActivities' 0
Set-RegValue $sys 'AllowCrossDeviceClipboard' 0

Write-Section 'Speech, inking & typing personalization'
Set-RegValue 'HKLM:\SOFTWARE\Policies\Microsoft\InputPersonalization' 'AllowInputPersonalization' 0
Set-RegValue 'HKCU:\Software\Microsoft\Speech_OneCore\Settings\OnlineSpeechPrivacy' 'HasAccepted' 0
Set-RegValue 'HKCU:\Software\Microsoft\InputPersonalization' 'RestrictImplicitInkCollection' 1
Set-RegValue 'HKCU:\Software\Microsoft\InputPersonalization' 'RestrictImplicitTextCollection' 1
Set-RegValue 'HKCU:\Software\Microsoft\InputPersonalization\TrainedDataStore' 'HarvestContacts' 0
Set-RegValue 'HKCU:\Software\Microsoft\Personalization\Settings' 'AcceptedPrivacyPolicy' 0

Write-Section 'Location / Find my device'
Set-RegValue 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\CapabilityAccessManager\ConsentStore\location' 'Value' 'Deny' -Type String
Set-RegValue 'HKLM:\SOFTWARE\Policies\Microsoft\FindMyDevice' 'AllowFindMyDevice' 0

Write-Section 'Search: no Bing/web results, no cloud search, no search history'
$ws = 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Search'
Set-RegValue $ws 'AllowCortana' 0
Set-RegValue $ws 'DisableWebSearch' 1
Set-RegValue $ws 'ConnectedSearchUseWeb' 0
Set-RegValue $ws 'AllowCloudSearch' 0
Set-RegValue $ws 'AllowSearchToUseLocation' 0
Set-RegValue $ws 'EnableDynamicContentInWSB' 0
Set-RegValue 'HKCU:\Software\Policies\Microsoft\Windows\Explorer' 'DisableSearchBoxSuggestions' 1
Set-RegValue 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Search' 'BingSearchEnabled' 0
Set-RegValue 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Search' 'CortanaConsent' 0
$ss = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\SearchSettings'
Set-RegValue $ss 'IsDynamicSearchBoxEnabled' 0
Set-RegValue $ss 'IsMSACloudSearchEnabled' 0
Set-RegValue $ss 'IsAADCloudSearchEnabled' 0
Set-RegValue $ss 'IsDeviceSearchHistoryEnabled' 0

Write-Section 'Delivery Optimization: no peer-to-peer upload to other PCs'
Set-RegValue 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\DeliveryOptimization' 'DODownloadMode' 0

Complete-W11Clean
