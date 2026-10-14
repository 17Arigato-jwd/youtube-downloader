# ==============================================================================
# AS YouTube Downloader — Windows Installer Entrypoint
# ==============================================================================

$installer = Join-Path $PSScriptRoot "installers\install-windows.ps1"
if (Test-Path $installer) {
    & $installer @args
} else {
    Write-Error "Installer not found at $installer"
}

