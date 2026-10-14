# ==============================================================================
# AS YouTube Downloader — Windows Uninstaller Entrypoint
# ==============================================================================

$uninstaller = Join-Path $PSScriptRoot "installers\uninstall-windows.ps1"
if (Test-Path $uninstaller) {
    & $uninstaller @args
} else {
    Write-Error "Uninstaller not found at $uninstaller"
}

