#!/usr/bin/env bash
# ==============================================================================
# AS YouTube Downloader — Linux Uninstaller
# Removes installed application files, CLI symlink, icon, and desktop entry.
# ==============================================================================

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
CYAN='\033[0;36m'
NC='\033[0m'

echo -e "${CYAN}▶ Uninstalling AS YouTube Downloader…${NC}"

# Remove application directory
rm -rf "$HOME/.local/share/youtube-downloader"

# Remove CLI wrapper
rm -f "$HOME/.local/bin/yt-dnld"

# Remove desktop entry and icon
rm -f "$HOME/.local/share/applications/youtube-downloader.desktop"
rm -f "$HOME/.local/share/icons/hicolor/scalable/apps/youtube-downloader.svg"
rm -f "$HOME/Desktop/youtube-downloader.desktop"

# Refresh desktop databases
if command -v update-desktop-database &>/dev/null; then
    update-desktop-database "$HOME/.local/share/applications" 2>/dev/null || true
fi
if command -v gtk-update-icon-cache &>/dev/null; then
    gtk-update-icon-cache -f -t "$HOME/.local/share/icons/hicolor" 2>/dev/null || true
fi

echo -e "${GREEN}✓ AS YouTube Downloader has been uninstalled.${NC}"

