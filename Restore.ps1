#Requires -RunAsAdministrator
<#
.SYNOPSIS
    Reverts changes made by win11clean using the JSON backups in .\backups.
.PARAMETER BackupFile
    One or more specific backup files to restore. Default: all files in .\backups (newest first).
.PARAMETER DryRun
    Show what would be restored without changing anything.
.EXAMPLE
    .\Restore.ps1
.EXAMPLE
    .\Restore.ps1 -BackupFile .\backups\20261110-230000-Ads.json
#>
[CmdletBinding()]
param(
    [string[]]$BackupFile,
    [switch]$DryRun
)

Set-StrictMode -Version 2.0

if (-not $BackupFile) {
    $dir = Join-Path $PSScriptRoot 'backups'
    if (-not (Test-Path $dir)) { Write-Host 'No backups found.'; return }
    $BackupFile = Get-ChildItem -Path $dir -Filter '*.json' | Sort-Object Name -Descending | ForEach-Object FullName
}

foreach ($file in $BackupFile) {
    Write-Host "=== Restoring $file ===" -ForegroundColor Cyan
    $changes = @(Get-Content -LiteralPath $file -Raw | ConvertFrom-Json | ForEach-Object { $_ })
    [array]::Reverse($changes)
    $failed = 0

    foreach ($c in $changes) {
        try {
            switch ($c.Kind) {
                'Registry' {
                    if ($c.HadValue) {
                        $value = $c.OldValue
                        switch ($c.OldType) {
                            'Binary'      { $value = [byte[]]@($value) }
                            'MultiString' { $value = [string[]]@($value) }
                        }
                        Write-Host "    [reg]  $($c.Path)\$($c.Name) = $value"
                        if (-not $DryRun) {
                            if (-not (Test-Path -LiteralPath $c.Path)) { New-Item -Path $c.Path -Force | Out-Null }
                            New-ItemProperty -LiteralPath $c.Path -Name $c.Name -Value $value -PropertyType $c.OldType -Force -ErrorAction Stop | Out-Null
                        }
                    }
                    else {
                        Write-Host "    [reg]  remove $($c.Path)\$($c.Name)"
                        if (-not $DryRun -and (Test-Path -LiteralPath $c.Path)) {
                            Remove-ItemProperty -LiteralPath $c.Path -Name $c.Name -ErrorAction SilentlyContinue
                            if (-not $c.KeyExisted) {
                                $key = Get-Item -LiteralPath $c.Path
                                if ($key.ValueCount -eq 0 -and $key.SubKeyCount -eq 0) {
                                    Remove-Item -LiteralPath $c.Path -ErrorAction SilentlyContinue
                                }
                            }
                        }
                    }
                }
                'Task' {
                    if ($c.OldState -ne 'Disabled') {
                        Write-Host "    [task] enable $($c.TaskPath)$($c.TaskName)"
                        if (-not $DryRun) {
                            Enable-ScheduledTask -TaskPath $c.TaskPath -TaskName $c.TaskName -ErrorAction Stop | Out-Null
                        }
                    }
                }
            }
        }
        catch {
            $failed++
            Write-Warning "Restore step failed: $($_.Exception.Message)"
        }
    }

    if (-not $DryRun -and $failed -eq 0) {
        Rename-Item -LiteralPath $file -NewName ((Split-Path $file -Leaf) + '.restored')
    }
}

if (-not $DryRun) { Write-Host 'Restore finished. Restart Windows for all changes to take effect.' -ForegroundColor Green }
