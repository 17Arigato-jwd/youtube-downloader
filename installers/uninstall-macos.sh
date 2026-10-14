#!/usr/bin/env bash
# ==============================================================================
# AS YouTube Downloader — macOS Uninstaller
# Removes application files, CLI wrapper, and native .app bundle.
# ==============================================================================

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
CYAN='\033[0;36m'
NC='\033[0m'

echo -e "${CYAN}▶ Uninstalling AS YouTube Downloader…${NC}"

rm -rf "$HOME/.local/share/youtube-downloader"
rm -f "$HOME/.local/bin/yt-dnld"
rm -f "/usr/local/bin/yt-dnld" 2>/dev/null || true
rm -rf "$HOME/Applications/AS YouTube Downloader.app"
rm -rf "$HOME/Desktop/AS YouTube Downloader.app"

echo -e "${GREEN}✓ AS YouTube Downloader has been uninstalled.${NC}"

