<#
.SYNOPSIS
    AS YouTube Downloader — Windows Uninstaller
.DESCRIPTION
    Removes application directory, shortcuts, and cleans up the User PATH registry entry.
#>

[CmdletBinding()]
param()

Write-Host "▶ Uninstalling AS YouTube Downloader…" -ForegroundColor Cyan

$installDir = Join-Path $env:LOCALAPPDATA "Programs\youtube-downloader"

# 1. Remove install directory
if (Test-Path $installDir) {
    Remove-Item -Path $installDir -Recurse -Force
}

# 2. Remove Start Menu & Desktop shortcuts
$startMenuShortcut = Join-Path $env:APPDATA "Microsoft\Windows\Start Menu\Programs\AS YouTube Downloader.lnk"
if (Test-Path $startMenuShortcut) {
    Remove-Item -Path $startMenuShortcut -Force
}

$desktopShortcut = Join-Path ([Environment]::GetFolderPath("Desktop")) "AS YouTube Downloader.lnk"
if (Test-Path $desktopShortcut) {
    Remove-Item -Path $desktopShortcut -Force
}

# 3. Clean PATH
$userPath = [Environment]::GetEnvironmentVariable("Path", "User")
$paths = $userPath -split ";" | Where-Object { $_ -ne $installDir -and -not [string]::IsNullOrWhiteSpace($_) }
$newUserPath = $paths -join ";"
[Environment]::SetEnvironmentVariable("Path", $newUserPath, "User")

Write-Host "✓ AS YouTube Downloader has been uninstalled." -ForegroundColor Green

