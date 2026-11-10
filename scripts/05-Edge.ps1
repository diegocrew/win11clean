#Requires -RunAsAdministrator
<#
.SYNOPSIS
    Microsoft Edge policies: no diagnostic data, no ad personalization, no shopping/rewards/
    sidebar/Copilot, no promotional content, strict tracking prevention.
.NOTES
    Edge will show "Your browser is managed by your organization" - this is expected for policies.
#>
[CmdletBinding()]
param([switch]$DryRun)

. (Join-Path $PSScriptRoot '..\lib\Common.ps1')
Start-W11Clean -Name 'Edge' -DryRun:$DryRun

$edge = 'HKLM:\SOFTWARE\Policies\Microsoft\Edge'

Write-Section 'Telemetry & personalization'
Set-RegValue $edge 'DiagnosticData' 0
Set-RegValue $edge 'PersonalizationReportingEnabled' 0
Set-RegValue $edge 'UserFeedbackAllowed' 0
Set-RegValue $edge 'ConfigureDoNotTrack' 1
Set-RegValue $edge 'TrackingPrevention' 3            # 3 = Strict
Set-RegValue $edge 'AlternateErrorPagesEnabled' 0
Set-RegValue $edge 'ResolveNavigationErrorsUseWebService' 0
Set-RegValue $edge 'EdgeEnhanceImagesEnabled' 0

Write-Section 'Ads, shopping, rewards & promotions'
Set-RegValue $edge 'ShowRecommendationsEnabled' 0
Set-RegValue $edge 'SpotlightExperiencesAndRecommendationsEnabled' 0
Set-RegValue $edge 'EdgeShoppingAssistantEnabled' 0
Set-RegValue $edge 'ShowMicrosoftRewards' 0
Set-RegValue $edge 'PromotionalTabsEnabled' 0
Set-RegValue $edge 'MicrosoftEdgeInsiderPromotionEnabled' 0
Set-RegValue $edge 'NewTabPageContentEnabled' 0
Set-RegValue $edge 'NewTabPageHideDefaultTopSites' 1
Set-RegValue $edge 'NewTabPageAllowedBackgroundTypes' 1   # 1 = no Bing image of the day

Write-Section 'Sidebar & Copilot'
Set-RegValue $edge 'HubsSidebarEnabled' 0
Set-RegValue $edge 'CopilotPageContext' 0
Set-RegValue $edge 'CopilotCDPPageContext' 0

Complete-W11Clean
