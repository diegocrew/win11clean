# win11clean

PowerShell scripts that disable telemetry, tracking and ads in Windows 11.
Each script saves the original values before changing them, so you can undo everything with `Restore.ps1`.

## Usage

Open **PowerShell as Administrator** in this folder:

```powershell
# Allow scripts in this session only
Set-ExecutionPolicy -Scope Process Bypass -Force

# Preview the changes without applying them
.\Run-All.ps1 -DryRun

# Apply everything. This also creates a System Restore point.
.\Run-All.ps1

# Skip some modules
.\Run-All.ps1 -Skip 05-Edge,04-AI

# Run one module
.\scripts\03-Ads.ps1

# Undo all changes, or only the changes from one backup file
.\Restore.ps1
.\Restore.ps1 -BackupFile .\backups\20261110-230000-Ads.json
```

Restart Windows after you apply or restore changes.

## Scripts

| Script | What it does |
|---|---|
| [scripts/01-Telemetry.ps1](scripts/01-Telemetry.ps1) | Sets diagnostic data policies to the lowest level, disables the `DiagTrack` and `dmwappushservice` services, CEIP, inventory, Windows Error Reporting, feedback prompts and tailored experiences, and turns off telemetry scheduled tasks. Also opts out of PowerShell 7 and .NET CLI telemetry. |
| [scripts/02-Privacy.ps1](scripts/02-Privacy.ps1) | Disables the advertising ID, activity history/Timeline, cross-device clipboard, online speech, inking and typing personalization, location, Find My Device, Bing/web and cloud search, search history and highlights, app-launch tracking and Delivery Optimization peer-to-peer upload. |
| [scripts/03-Ads.ps1](scripts/03-Ads.ps1) | Disables Start, Settings and lock screen suggestions, tips, Spotlight, silently installed or promoted apps, OneDrive/M365 ads in File Explorer, account nags and the "finish setting up" screen. |
| [scripts/04-AI.ps1](scripts/04-AI.ps1) | Disables Windows Copilot, Recall and Click to Do. The optional `-RemoveCopilotApp` switch uninstalls the Copilot app, and `Restore.ps1` cannot undo that. |
| [scripts/05-Edge.ps1](scripts/05-Edge.ps1) | Sets Edge policies to turn off diagnostic data, ad personalization, shopping, Rewards, promotions, new tab page content, the sidebar and Copilot. It also enables Do Not Track and **strict** tracking prevention. |

Shared helpers are in [lib/Common.ps1](lib/Common.ps1).
Backups are written to `backups/`, which git ignores.
After a backup file is restored successfully, `Restore.ps1` renames it to `*.restored`.

## Notes and limitations

- **Edition:** `AllowTelemetry=0` works only on Enterprise and Education. Home and Pro still use "Required" diagnostic data, but disabling the `DiagTrack` service stops the upload.
- **User settings:** `HKCU` settings apply to the account that runs the script. If you elevate with a different administrator account, run the script again as each user, or sign in as an administrator.
- **Policies:** Windows Settings and Edge show *"Some settings are managed by your organization"*. This is expected.
- **Windows Update:** Feature updates can reset some user settings, mainly the `ContentDeliveryManager` settings. Run the scripts again after a feature update. They skip values that are already set.
- **Features turned off:** Location-based features and Find My Device stop working. Bing results no longer appear in Start search. Strict tracking prevention in Edge can break some sites. To use balanced mode instead, set `TrackingPrevention` to `2` in `05-Edge.ps1`.
- **Not changed:**
  - Microsoft Defender cloud protection and sample submission stay on because they protect the PC.
  - The scripts do not block telemetry endpoints in the hosts file or firewall. Those blocks often break Windows Update, the Store or Defender, and Windows bypasses the hosts file for some endpoints.
