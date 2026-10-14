#!/usr/bin/env bash
# ==============================================================================
# AS YouTube Downloader — Linux Automated Installer
# Installs dependencies (Python 3.10+, FFmpeg, Node.js, yt-dlp, colorama),
# sets up an isolated environment, creates the 'yt-dnld' CLI command,
# and configures application menu and desktop shortcuts.
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

# ── Helper: Package Manager Detection & Installer ─────────────────────────────
detect_pkg_manager() {
    if command -v apt-get &>/dev/null; then
        echo "apt"
    elif command -v dnf &>/dev/null; then
        echo "dnf"
    elif command -v pacman &>/dev/null; then
        echo "pacman"
    elif command -v zypper &>/dev/null; then
        echo "zypper"
    elif command -v apk &>/dev/null; then
        echo "apk"
    elif command -v xbps-install &>/dev/null; then
        echo "xbps"
    else
        echo "unknown"
    fi
}

PKG_MANAGER=$(detect_pkg_manager)

run_pkg_install() {
    local packages="$*"
    echo -e "${CYAN}▶ Installing missing system packages: ${WHITE}$packages${NC} (requires sudo)"

    case "$PKG_MANAGER" in
        apt)
            sudo apt-get update && sudo apt-get install -y $packages
            ;;
        dnf)
            sudo dnf install -y $packages
            ;;
        pacman)
            sudo pacman -S --noconfirm --needed $packages
            ;;
        zypper)
            sudo zypper install -y $packages
            ;;
        apk)
            sudo apk add --no-cache $packages
            ;;
        xbps)
            sudo xbps-install -Sy $packages
            ;;
        *)
            echo -e "${RED}✗ Could not automatically detect package manager.${NC}"
            echo -e "  Please install manually: ${YELLOW}$packages${NC}"
            return 1
            ;;
    esac
}

# ── 1. Check & Install Python 3.10+ ───────────────────────────────────────────
echo -e "${CYAN}▶ Checking Python installation…${NC}"

NEED_PY_INSTALL=0
if ! command -v python3 &>/dev/null; then
    NEED_PY_INSTALL=1
else
    PY_OK=$(python3 -c 'import sys; print(1 if sys.version_info >= (3, 10) else 0)' 2>/dev/null || echo 0)
    if [ "$PY_OK" -ne 1 ]; then
        PY_CURR=$(python3 -c 'import sys; print(f"{sys.version_info.major}.{sys.version_info.minor}")' 2>/dev/null || echo "unknown")
        echo -e "${YELLOW}⚠ Python ($PY_CURR) is older than 3.10.${NC}"
        NEED_PY_INSTALL=1
    fi
fi

if [ "$NEED_PY_INSTALL" -eq 1 ]; then
    echo -e "${YELLOW}⚠ Python 3.10+ is required.${NC} Attempting to install…"
    case "$PKG_MANAGER" in
        apt)
            run_pkg_install python3 python3-pip python3-venv
            ;;
        dnf)
            run_pkg_install python3 python3-pip
            ;;
        pacman)
            run_pkg_install python python-pip
            ;;
        zypper)
            run_pkg_install python3 python3-pip
            ;;
        apk)
            run_pkg_install python3 py3-pip
            ;;
        *)
            echo -e "${RED}✗ Please install Python 3.10+ manually with your package manager.${NC}"
            exit 1
            ;;
    esac
fi

if ! command -v python3 &>/dev/null; then
    echo -e "${RED}✗ Python 3 is still not found. Please install Python 3.10+ and re-run.${NC}"
    exit 1
fi

PY_VER=$(python3 -c 'import sys; print(f"{sys.version_info.major}.{sys.version_info.minor}")')
echo -e "${GREEN}✓ Python $PY_VER detected (${WHITE}$(command -v python3)${GREEN}).${NC}"

# ── 2. Check & Install python3-venv / python3-pip ──────────────────────────────
echo -e "\n${CYAN}▶ Checking Python venv and pip modules…${NC}"
VENV_OK=1
if ! python3 -m venv --help &>/dev/null; then
    VENV_OK=0
fi

if [ "$VENV_OK" -eq 0 ]; then
    echo -e "${YELLOW}⚠ python3-venv module is missing.${NC} Installing…"
    if [ "$PKG_MANAGER" = "apt" ]; then
        run_pkg_install python3-venv python3-pip || true
    elif [ "$PKG_MANAGER" = "dnf" ]; then
        run_pkg_install python3-pip || true
    fi
fi

if python3 -m venv --help &>/dev/null; then
    echo -e "${GREEN}✓ Python venv module ready.${NC}"
else
    echo -e "${YELLOW}⚠ Python venv module unavailable; will use pip direct installation fallback.${NC}"
fi

# ── 3. Check & Install FFmpeg ─────────────────────────────────────────────────
echo -e "\n${CYAN}▶ Checking FFmpeg…${NC}"
if ! command -v ffmpeg &>/dev/null; then
    echo -e "${YELLOW}⚠ FFmpeg is missing.${NC} FFmpeg is required for merging audio/video, converting formats, and metadata embedding."
    run_pkg_install ffmpeg || true

    if ! command -v ffmpeg &>/dev/null; then
        echo -e "${RED}✗ FFmpeg installation failed or was cancelled.${NC}"
        echo -e "  Please install FFmpeg manually using your package manager (e.g. 'sudo apt install ffmpeg')."
        exit 1
    fi
fi
echo -e "${GREEN}✓ FFmpeg detected (${WHITE}$(command -v ffmpeg)${GREEN}).${NC}"

# ── 4. Check & Install JavaScript Runtime (Node.js / Deno) ────────────────────
echo -e "\n${CYAN}▶ Checking JavaScript runtime (required for YouTube n-challenge solving)…${NC}"
HAS_JS=0
if command -v node &>/dev/null || command -v nodejs &>/dev/null || command -v deno &>/dev/null; then
    HAS_JS=1
elif [ -d "$HOME/.nvm/versions/node" ] || [ -d "$HOME/.fnm/node-versions" ] || [ -f "$HOME/.deno/bin/deno" ]; then
    HAS_JS=1
fi

if [ "$HAS_JS" -eq 1 ]; then
    JS_PATH="$(command -v node || command -v nodejs || command -v deno || echo "detected in user directory")"
    echo -e "${GREEN}✓ JavaScript runtime detected (${WHITE}$JS_PATH${GREEN}).${NC}"
else
    echo -e "${YELLOW}⚠ No JavaScript runtime found (Node.js / Deno).${NC}"
    echo -e "  YouTube throttles downloads to ~50 KB/s without a JS runtime to solve player challenges."
    if [ "$PKG_MANAGER" != "unknown" ]; then
        echo -e "  Attempting to install Node.js automatically…"
        case "$PKG_MANAGER" in
            apt) run_pkg_install nodejs || true ;;
            dnf) run_pkg_install nodejs || true ;;
            pacman) run_pkg_install nodejs || true ;;
            zypper) run_pkg_install nodejs || true ;;
            apk) run_pkg_install nodejs || true ;;
        esac
    fi
    if command -v node &>/dev/null || command -v nodejs &>/dev/null; then
        echo -e "${GREEN}✓ Node.js installed successfully.${NC}"
    else
        echo -e "${YELLOW}  (Optional) Install Node.js later via your package manager to unlock maximum download speeds.${NC}"
    fi
fi

# ── 5. Copy Application Files ─────────────────────────────────────────────────
echo -e "\n${CYAN}▶ Installing application files to $INSTALL_DIR…${NC}"
mkdir -p "$INSTALL_DIR"
mkdir -p "$BIN_DIR"
mkdir -p "$DESKTOP_DIR"
mkdir -p "$ICON_DIR"

cp "$SCRIPT_DIR/youtube-downloader.py" "$INSTALL_DIR/"
cp "$SCRIPT_DIR/youtube-downloader.svg" "$INSTALL_DIR/"
cp "$SCRIPT_DIR/requirements.txt" "$INSTALL_DIR/" 2>/dev/null || true
chmod +x "$INSTALL_DIR/youtube-downloader.py"

# ── 6. Set Up Python Environment & Dependencies ───────────────────────────────
echo -e "\n${CYAN}▶ Setting up Python environment & installing packages…${NC}"
PYTHON_EXEC=""

# Try virtual environment first for clean isolation
if python3 -m venv "$INSTALL_DIR/venv" 2>/dev/null; then
    echo -e "  Updating pip in isolated virtual environment…"
    "$INSTALL_DIR/venv/bin/pip" install --upgrade pip --quiet 2>/dev/null || true
    echo -e "  Installing colorama, yt-dlp, and curl-cffi…"
    "$INSTALL_DIR/venv/bin/pip" install -r "$INSTALL_DIR/requirements.txt" --quiet
    PYTHON_EXEC="$INSTALL_DIR/venv/bin/python3"
fi

# Fallback to user pip if venv couldn't be created
if [ -z "$PYTHON_EXEC" ] || [ ! -f "$PYTHON_EXEC" ]; then
    echo -e "${YELLOW}⚠ Setting up via user pip…${NC}"
    pip3 install --user -r "$INSTALL_DIR/requirements.txt" 2>/dev/null || \
    pip3 install --user --break-system-packages -r "$INSTALL_DIR/requirements.txt" 2>/dev/null || \
    python3 -m pip install --user -r "$INSTALL_DIR/requirements.txt"
    PYTHON_EXEC="$(command -v python3)"
fi

# ── 7. Verify Dependencies Actually Import ────────────────────────────────────
echo -e "\n${CYAN}▶ Verifying Python dependencies…${NC}"
if ! "$PYTHON_EXEC" -c "import colorama, yt_dlp" &>/dev/null; then
    echo -e "${RED}✗ Failed to import required packages (colorama / yt_dlp).${NC}"
    echo -e "  Attempting forced installation…"
    "$PYTHON_EXEC" -m pip install colorama "yt-dlp[default,curl-cffi]" --break-system-packages 2>/dev/null || \
    "$PYTHON_EXEC" -m pip install colorama "yt-dlp[default,curl-cffi]"
    if ! "$PYTHON_EXEC" -c "import colorama, yt_dlp" &>/dev/null; then
        echo -e "${RED}✗ Dependency installation failed. Please run manually:${NC}"
        echo -e "  pip install colorama 'yt-dlp[default,curl-cffi]'"
        exit 1
    fi
fi
echo -e "${GREEN}✓ All Python modules verified successfully.${NC}"

# ── 8. Create 'yt-dnld' CLI Command ───────────────────────────────────────────
echo -e "\n${CYAN}▶ Creating 'yt-dnld' global terminal command…${NC}"
cat <<EOF > "$BIN_DIR/yt-dnld"
#!/usr/bin/env bash
exec "$PYTHON_EXEC" "$INSTALL_DIR/youtube-downloader.py" "\$@"
EOF
chmod +x "$BIN_DIR/yt-dnld"
echo -e "${GREEN}✓ Created executable at ${WHITE}$BIN_DIR/yt-dnld${NC}"

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

# ── 9. Install Icon & Desktop Shortcut ────────────────────────────────────────
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
    if command -v gio &>/dev/null; then
        gio set "$USER_DESKTOP/youtube-downloader.desktop" metadata::trusted true 2>/dev/null || true
    fi
    echo -e "${GREEN}✓ Desktop shortcut created at ${WHITE}$USER_DESKTOP/youtube-downloader.desktop${NC}"
fi

# ── 10. Summary ───────────────────────────────────────────────────────────────
echo -e "\n${GREEN}════════════════════════════════════════════════════════════════${NC}"
echo -e "${GREEN}  ✓ Installation Complete!${NC}"
echo -e "${GREEN}════════════════════════════════════════════════════════════════${NC}"
echo -e "  ${WHITE}[✓] Python:${NC}             $PY_VER"
echo -e "  ${WHITE}[✓] FFmpeg:${NC}             $(command -v ffmpeg)"
echo -e "  ${WHITE}[✓] Modules:${NC}            yt-dlp, colorama, curl-cffi"
echo -e "  ${WHITE}[✓] Command:${NC}            ${CYAN}yt-dnld${NC} -> $BIN_DIR/yt-dnld"
echo -e "  ${WHITE}[✓] Application Menu:${NC}   AS YouTube Downloader"
echo ""
echo -e "You can now run ${WHITE}yt-dnld${NC} from anywhere in your terminal."
echo -e "Or launch ${WHITE}AS YouTube Downloader${NC} from your application menu or desktop.\n"

if [ "$PATH_UPDATED" -eq 1 ]; then
    echo -e "${YELLOW}Note:${NC} ~/.local/bin was added to your shell configuration."
    echo -e "Run ${WHITE}source ~/.bashrc${NC} (or restart your terminal) to update PATH in current sessions.\n"
fi
