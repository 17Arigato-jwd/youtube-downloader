#!/usr/bin/env bash
# ==============================================================================
# AS YouTube Downloader — Linux Installer
# Installs youtube-downloader, creates the 'yt-dnld' CLI command, sets up
# dependencies, and registers the application menu and desktop shortcuts.
# ==============================================================================

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
NC='\033[0m'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
INSTALL_DIR="$HOME/.local/share/youtube-downloader"
BIN_DIR="$HOME/.local/bin"
DESKTOP_DIR="$HOME/.local/share/applications"
ICON_DIR="$HOME/.local/share/icons/hicolor/scalable/apps"

echo -e "${WHITE}╔════════════════════════════════════════════════════════════════╗${NC}"
echo -e "${WHITE}║       AS YouTube Downloader — Linux Automated Installer        ║${NC}"
echo -e "${WHITE}╚════════════════════════════════════════════════════════════════╝${NC}\n"

# ── 1. Check Python 3.10+ ─────────────────────────────────────────────────────
echo -e "${CYAN}▶ Checking Python installation…${NC}"
if ! command -v python3 &>/dev/null; then
    echo -e "${RED}✗ Python 3 is not installed.${NC}"
    echo -e "  Please install Python 3.10 or higher using your package manager."
    echo -e "  Ubuntu/Debian: ${YELLOW}sudo apt install python3 python3-venv python3-pip${NC}"
    echo -e "  Fedora:        ${YELLOW}sudo dnf install python3 python3-pip${NC}"
    echo -e "  Arch Linux:    ${YELLOW}sudo pacman -S python python-pip${NC}"
    exit 1
fi

PY_VER=$(python3 -c 'import sys; print(f"{sys.version_info.major}.{sys.version_info.minor}")')
PY_OK=$(python3 -c 'import sys; print(1 if sys.version_info >= (3, 10) else 0)')

if [ "$PY_OK" -ne 1 ]; then
    echo -e "${RED}✗ Python version ($PY_VER) is too old. AS YouTube Downloader requires Python 3.10+.${NC}"
    exit 1
fi
echo -e "${GREEN}✓ Python $PY_VER detected.${NC}"

# ── 2. Check FFmpeg ───────────────────────────────────────────────────────────
echo -e "\n${CYAN}▶ Checking FFmpeg…${NC}"
if ! command -v ffmpeg &>/dev/null; then
    echo -e "${YELLOW}⚠ FFmpeg is missing.${NC} FFmpeg is required for merging audio/video, converting formats, and metadata embedding."
    echo -e "  Attempting to install via system package manager…"

    if command -v apt-get &>/dev/null; then
        echo -e "  Running: ${WHITE}sudo apt update && sudo apt install -y ffmpeg${NC}"
        sudo apt update && sudo apt install -y ffmpeg || true
    elif command -v dnf &>/dev/null; then
        echo -e "  Running: ${WHITE}sudo dnf install -y ffmpeg${NC}"
        sudo dnf install -y ffmpeg || true
    elif command -v pacman &>/dev/null; then
        echo -e "  Running: ${WHITE}sudo pacman -S --noconfirm ffmpeg${NC}"
        sudo pacman -S --noconfirm ffmpeg || true
    elif command -v zypper &>/dev/null; then
        echo -e "  Running: ${WHITE}sudo zypper install -y ffmpeg${NC}"
        sudo zypper install -y ffmpeg || true
    fi

    if ! command -v ffmpeg &>/dev/null; then
        echo -e "${RED}✗ Could not install FFmpeg automatically.${NC}"
        echo -e "  Please install FFmpeg manually using your system package manager."
        exit 1
    fi
fi
echo -e "${GREEN}✓ FFmpeg detected ($(command -v ffmpeg)).${NC}"

# ── 3. Create Directories & Copy Files ────────────────────────────────────────
echo -e "\n${CYAN}▶ Installing application files…${NC}"
mkdir -p "$INSTALL_DIR"
mkdir -p "$BIN_DIR"
mkdir -p "$DESKTOP_DIR"
mkdir -p "$ICON_DIR"

cp "$SCRIPT_DIR/youtube-downloader.py" "$INSTALL_DIR/"
cp "$SCRIPT_DIR/youtube-downloader.svg" "$INSTALL_DIR/"
cp "$SCRIPT_DIR/requirements.txt" "$INSTALL_DIR/" 2>/dev/null || true
chmod +x "$INSTALL_DIR/youtube-downloader.py"

# ── 4. Set Up Isolated Virtual Environment ────────────────────────────────────
echo -e "\n${CYAN}▶ Setting up Python environment & dependencies…${NC}"
if ! python3 -m venv "$INSTALL_DIR/venv" 2>/dev/null; then
    echo -e "${YELLOW}⚠ python3-venv module missing, attempting pip direct install…${NC}"
    pip3 install --user -r "$INSTALL_DIR/requirements.txt" || pip3 install --user --break-system-packages -r "$INSTALL_DIR/requirements.txt"
    PYTHON_EXEC="$(command -v python3)"
else
    "$INSTALL_DIR/venv/bin/pip" install --upgrade pip --quiet
    "$INSTALL_DIR/venv/bin/pip" install -r "$INSTALL_DIR/requirements.txt" --quiet
    PYTHON_EXEC="$INSTALL_DIR/venv/bin/python3"
fi
echo -e "${GREEN}✓ Dependencies installed successfully.${NC}"

# ── 5. Create 'yt-dnld' CLI Command ───────────────────────────────────────────
echo -e "\n${CYAN}▶ Creating 'yt-dnld' global terminal command…${NC}"
cat <<EOF > "$BIN_DIR/yt-dnld"
#!/usr/bin/env bash
exec "$PYTHON_EXEC" "$INSTALL_DIR/youtube-downloader.py" "\$@"
EOF
chmod +x "$BIN_DIR/yt-dnld"
echo -e "${GREEN}✓ Created executable at $BIN_DIR/yt-dnld${NC}"

# Ensure ~/.local/bin is in PATH in shell config
PATH_UPDATED=0
for RC in "$HOME/.bashrc" "$HOME/.zshrc" "$HOME/.profile"; do
    if [ -f "$RC" ]; then
        if ! grep -q 'HOME/.local/bin' "$RC" && ! grep -q '$HOME/.local/bin' "$RC" && ! grep -q "$BIN_DIR" "$RC"; then
            echo -e "\n# Added by AS YouTube Downloader installer\nexport PATH=\"\$HOME/.local/bin:\$PATH\"" >> "$RC"
            PATH_UPDATED=1
        fi
    fi
done

# ── 6. Install Icon & Desktop Shortcut ────────────────────────────────────────
echo -e "\n${CYAN}▶ Registering Application Menu and Desktop shortcuts…${NC}"
cp "$INSTALL_DIR/youtube-downloader.svg" "$ICON_DIR/youtube-downloader.svg"

cat <<EOF > "$DESKTOP_DIR/youtube-downloader.desktop"
[Desktop Entry]
Name=AS YouTube Downloader
GenericName=YouTube Downloader
Comment=Interactive YouTube video and audio downloader powered by yt-dlp
Exec=sh -c '$BIN_DIR/yt-dnld; echo; read -p "Press Enter to exit..."'
Icon=youtube-downloader
Terminal=true
Type=Application
Categories=AudioVideo;Audio;Video;Network;
Keywords=youtube;downloader;yt-dlp;video;audio;mp3;mp4;
StartupNotify=true
EOF
chmod +x "$DESKTOP_DIR/youtube-downloader.desktop"

# Refresh desktop databases
if command -v update-desktop-database &>/dev/null; then
    update-desktop-database "$DESKTOP_DIR" 2>/dev/null || true
fi
if command -v gtk-update-icon-cache &>/dev/null; then
    gtk-update-icon-cache -f -t "$HOME/.local/share/icons/hicolor" 2>/dev/null || true
fi

# Optional Desktop Shortcut
USER_DESKTOP="$(xdg-user-dir DESKTOP 2>/dev/null || echo "$HOME/Desktop")"
if [ -d "$USER_DESKTOP" ]; then
    cp "$DESKTOP_DIR/youtube-downloader.desktop" "$USER_DESKTOP/"
    chmod +x "$USER_DESKTOP/youtube-downloader.desktop"
    # GNOME trust desktop file if gio is available
    if command -v gio &>/dev/null; then
        gio set "$USER_DESKTOP/youtube-downloader.desktop" metadata::trusted true 2>/dev/null || true
    fi
    echo -e "${GREEN}✓ Desktop shortcut created at $USER_DESKTOP/youtube-downloader.desktop${NC}"
fi

echo -e "\n${GREEN}════════════════════════════════════════════════════════════════${NC}"
echo -e "${GREEN}  ✓ Installation Complete!${NC}"
echo -e "${GREEN}════════════════════════════════════════════════════════════════${NC}"
echo -e "You can now run ${WHITE}yt-dnld${NC} from anywhere in your terminal."
echo -e "Or launch ${WHITE}AS YouTube Downloader${NC} from your application menu / desktop.\n"

if [ "$PATH_UPDATED" -eq 1 ]; then
    echo -e "${YELLOW}Note:${NC} ~/.local/bin was added to your shell configuration."
    echo -e "Run ${WHITE}source ~/.bashrc${NC} (or restart your terminal) to update PATH in current sessions.\n"
fi
