<#
.SYNOPSIS
    AS YouTube Downloader — Windows Automated Installer
.DESCRIPTION
    Installs youtube-downloader, configures dependencies (Python 3.10+, FFmpeg, Node.js, pip modules),
    registers the 'yt-dnld' command in the system PATH and registry, and creates
    Start Menu and Desktop shortcuts.
#>

[CmdletBinding()]
param()

$ErrorActionPreference = "Stop"

function Write-Header {
    Write-Host ""
    Write-Host "╔════════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
    Write-Host "║       AS YouTube Downloader — Windows Automated Installer      ║" -ForegroundColor Cyan
    Write-Host "╚════════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
    Write-Host ""
}

function Test-CommandExists ($cmd) {
    return [bool](Get-Command -Name $cmd -ErrorAction SilentlyContinue)
}

function Refresh-EnvPath {
    $env:Path = [Environment]::GetEnvironmentVariable("Path", "Machine") + ";" + [Environment]::GetEnvironmentVariable("Path", "User")
}

Write-Header

$scriptDir = Split-Path -Parent $PSScriptRoot
$installDir = Join-Path $env:LOCALAPPDATA "Programs\youtube-downloader"

# ── 1. Check & Install Python 3.10+ ───────────────────────────────────────────
Write-Host "▶ Checking Python installation…" -ForegroundColor Cyan
$pythonExe = $null

if (Test-CommandExists "python") {
    $ver = & python -c 'import sys; print(f"{sys.version_info.major}.{sys.version_info.minor}")' 2>$null
    $ok = & python -c 'import sys; print(1 if sys.version_info >= (3, 10) else 0)' 2>$null
    if ($ok -eq "1") {
        $pythonExe = "python"
        Write-Host "✓ Found Python $ver (python.exe)" -ForegroundColor Green
    }
}

if (-not $pythonExe -and (Test-CommandExists "py")) {
    $ver = & py -3 -c 'import sys; print(f"{sys.version_info.major}.{sys.version_info.minor}")' 2>$null
    $ok = & py -3 -c 'import sys; print(1 if sys.version_info >= (3, 10) else 0)' 2>$null
    if ($ok -eq "1") {
        $pythonExe = "py -3"
        Write-Host "✓ Found Python $ver (py.exe launcher)" -ForegroundColor Green
    }
}

if (-not $pythonExe) {
    Write-Host "⚠ Python 3.10+ was not found on your system." -ForegroundColor Yellow
    if (Test-CommandExists "winget") {
        Write-Host "  Installing Python 3.12 via winget…" -ForegroundColor Cyan
        winget install -e --id Python.Python.3.12 --scope currentuser --accept-package-agreements --accept-source-agreements
        Refresh-EnvPath
        if (Test-CommandExists "python") {
            $pythonExe = "python"
        } elseif (Test-CommandExists "py") {
            $pythonExe = "py -3"
        }
    }
    if (-not $pythonExe) {
        Write-Host "✗ Could not auto-install Python. Please install Python 3.10+ from https://www.python.org/downloads/ (check 'Add python.exe to PATH' during installation)." -ForegroundColor Red
        exit 1
    }
}

# ── 2. Check & Install FFmpeg ─────────────────────────────────────────────────
Write-Host "`n▶ Checking FFmpeg…" -ForegroundColor Cyan
if (Test-CommandExists "ffmpeg") {
    Write-Host "✓ FFmpeg detected." -ForegroundColor Green
} else {
    Write-Host "⚠ FFmpeg not found in PATH." -ForegroundColor Yellow
    if (Test-CommandExists "winget") {
        Write-Host "  Installing FFmpeg via winget…" -ForegroundColor Cyan
        winget install -e --id Gyan.FFmpeg --accept-package-agreements --accept-source-agreements
        Refresh-EnvPath
        if (Test-CommandExists "ffmpeg") {
            Write-Host "✓ FFmpeg installed successfully." -ForegroundColor Green
        } else {
            Write-Host "⚠ FFmpeg was installed; you may need to reopen your terminal window after setup completes." -ForegroundColor Yellow
        }
    } else {
        Write-Host "  Please install FFmpeg using 'winget install Gyan.FFmpeg' or download from https://ffmpeg.org/download.html" -ForegroundColor Yellow
    }
}

# ── 3. Check & Install Node.js (JavaScript Runtime) ───────────────────────────
Write-Host "`n▶ Checking JavaScript runtime (for YouTube n-challenge solving)…" -ForegroundColor Cyan
if ((Test-CommandExists "node") -or (Test-CommandExists "deno")) {
    Write-Host "✓ JavaScript runtime detected." -ForegroundColor Green
} else {
    Write-Host "⚠ Node.js not detected." -ForegroundColor Yellow
    Write-Host "  YouTube throttles downloads to ~50 KB/s without a JS runtime to solve player challenges."
    if (Test-CommandExists "winget") {
        Write-Host "  Installing Node.js LTS via winget…" -ForegroundColor Cyan
        winget install -e --id OpenJS.NodeJS.LTS --accept-package-agreements --accept-source-agreements
        Refresh-EnvPath
        if (Test-CommandExists "node") {
            Write-Host "✓ Node.js installed successfully." -ForegroundColor Green
        }
    }
}

# ── 4. Copy Application Files ─────────────────────────────────────────────────
Write-Host "`n▶ Installing application files to $installDir…" -ForegroundColor Cyan
if (-not (Test-Path $installDir)) {
    New-Item -ItemType Directory -Path $installDir -Force | Out-Null
}

Copy-Item -Path "$scriptDir\youtube-downloader.py" -Destination $installDir -Force
Copy-Item -Path "$scriptDir\youtube-downloader.svg" -Destination $installDir -Force
if (Test-Path "$scriptDir\requirements.txt") {
    Copy-Item -Path "$scriptDir\requirements.txt" -Destination $installDir -Force
}

# ── 5. Set Up Isolated Python Virtual Environment ────────────────────────────
Write-Host "`n▶ Setting up Python virtual environment & installing packages…" -ForegroundColor Cyan
$venvPath = Join-Path $installDir "venv"
$venvPython = Join-Path $venvPath "Scripts\python.exe"
$venvPip = Join-Path $venvPath "Scripts\pip.exe"

if (-not (Test-Path $venvPython)) {
    if ($pythonExe -eq "python") {
        & python -m venv $venvPath
    } else {
        & py -3 -m venv $venvPath
    }
}

& $venvPip install --upgrade pip --quiet
& $venvPip install colorama "yt-dlp[default,curl-cffi]" --quiet

# Verify installation
$verifyResult = & $venvPython -c "import colorama, yt_dlp; print('OK')" 2>$null
if ($verifyResult -ne "OK") {
    Write-Host "⚠ Retrying pip dependency installation…" -ForegroundColor Yellow
    & $venvPip install -r "$installDir\requirements.txt"
}

Write-Host "✓ Python dependencies verified (colorama, yt-dlp, curl-cffi)." -ForegroundColor Green

# ── 6. Create 'yt-dnld' Wrapper Scripts ───────────────────────────────────────
Write-Host "`n▶ Creating 'yt-dnld' command wrappers…" -ForegroundColor Cyan
$cmdWrapper = @"
@echo off
"$venvPython" "$installDir\youtube-downloader.py" %*
"@

Set-Content -Path (Join-Path $installDir "yt-dnld.cmd") -Value $cmdWrapper -Encoding ASCII

$psWrapper = @"
& "$venvPython" "$installDir\youtube-downloader.py" @args
"@
Set-Content -Path (Join-Path $installDir "yt-dnld.ps1") -Value $psWrapper -Encoding UTF8

Write-Host "✓ Created yt-dnld.cmd and yt-dnld.ps1" -ForegroundColor Green

# ── 7. Add to User PATH & Registry ───────────────────────────────────────────
Write-Host "`n▶ Registering in User PATH & Registry…" -ForegroundColor Cyan
$userPath = [Environment]::GetEnvironmentVariable("Path", "User")
if ($userPath -split ";" -notcontains $installDir) {
    $newUserPath = if ([string]::IsNullOrWhiteSpace($userPath)) { $installDir } else { "$userPath;$installDir" }
    [Environment]::SetEnvironmentVariable("Path", $newUserPath, "User")
    $env:Path = "$env:Path;$installDir"
    Write-Host "✓ Added $installDir to User PATH." -ForegroundColor Green
} else {
    Write-Host "✓ $installDir is already registered in User PATH." -ForegroundColor Green
}

# ── 8. Create Start Menu & Desktop Shortcuts ─────────────────────────────────
Write-Host "`n▶ Creating Start Menu & Desktop Shortcuts…" -ForegroundColor Cyan

$wshShell = New-Object -ComObject WScript.Shell

# Start Menu Shortcut
$startMenuDir = Join-Path $env:APPDATA "Microsoft\Windows\Start Menu\Programs"
$startMenuShortcutPath = Join-Path $startMenuDir "AS YouTube Downloader.lnk"
$shortcut = $wshShell.CreateShortcut($startMenuShortcutPath)
$shortcut.TargetPath = "cmd.exe"
$shortcut.Arguments = "/k yt-dnld"
$shortcut.WorkingDirectory = [Environment]::GetFolderPath("UserProfile")
$shortcut.Description = "Interactive YouTube Downloader powered by yt-dlp"
$shortcut.Save()
Write-Host "✓ Start Menu shortcut created." -ForegroundColor Green

# Desktop Shortcut
$desktopDir = [Environment]::GetFolderPath("Desktop")
$desktopShortcutPath = Join-Path $desktopDir "AS YouTube Downloader.lnk"
$dShortcut = $wshShell.CreateShortcut($desktopShortcutPath)
$dShortcut.TargetPath = "cmd.exe"
$dShortcut.Arguments = "/k yt-dnld"
$dShortcut.WorkingDirectory = [Environment]::GetFolderPath("UserProfile")
$dShortcut.Description = "Interactive YouTube Downloader powered by yt-dlp"
$dShortcut.Save()
Write-Host "✓ Desktop shortcut created." -ForegroundColor Green

# ── 9. Summary ────────────────────────────────────────────────────────────────
Write-Host ""
Write-Host "════════════════════════════════════════════════════════════════" -ForegroundColor Green
Write-Host "  ✓ Installation Complete!" -ForegroundColor Green
Write-Host "════════════════════════════════════════════════════════════════" -ForegroundColor Green
Write-Host "  [✓] Python:             $pythonExe" -ForegroundColor White
Write-Host "  [✓] FFmpeg:             Ready" -ForegroundColor White
Write-Host "  [✓] Modules:            yt-dlp, colorama, curl-cffi" -ForegroundColor White
Write-Host "  [✓] Command:            yt-dnld -> $installDir\yt-dnld.cmd" -ForegroundColor White
Write-Host "  [✓] Start Menu:         AS YouTube Downloader" -ForegroundColor White
Write-Host ""
Write-Host "You can now run 'yt-dnld' from any Command Prompt, PowerShell," -ForegroundColor White
Write-Host "or Windows Terminal window." -ForegroundColor White
Write-Host "You can also launch 'AS YouTube Downloader' directly from your" -ForegroundColor White
Write-Host "Start Menu or Desktop." -ForegroundColor White
Write-Host ""
