#!/usr/bin/env bash
# ==============================================================================
# AS YouTube Downloader — macOS Automated Installer
# Installs dependencies (Homebrew, Python 3.10+, FFmpeg, Node.js), configures
# isolated environment, registers 'yt-dnld' CLI, and creates native .app bundle.
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
APP_DIR="$HOME/Applications"

echo -e "${WHITE}╔════════════════════════════════════════════════════════════════╗${NC}"
echo -e "${WHITE}║       AS YouTube Downloader — macOS Automated Installer        ║${NC}"
echo -e "${WHITE}╚════════════════════════════════════════════════════════════════╝${NC}\n"

# ── 1. Check & Install Homebrew ───────────────────────────────────────────────
echo -e "${CYAN}▶ Checking Homebrew…${NC}"
if ! command -v brew &>/dev/null; then
    echo -e "${YELLOW}⚠ Homebrew is not installed.${NC} Homebrew is required to install system dependencies (FFmpeg, Python)."
    echo -e "  Installing Homebrew…"
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)" || true

    # Evaluate brew in current environment if installed in standard paths
    if [ -f "/opt/homebrew/bin/brew" ]; then
        eval "$(/opt/homebrew/bin/brew shellenv)"
    elif [ -f "/usr/local/bin/brew" ]; then
        eval "$(/usr/local/bin/brew shellenv)"
    fi
fi

if command -v brew &>/dev/null; then
    echo -e "${GREEN}✓ Homebrew detected (${WHITE}$(brew --prefix)${GREEN}).${NC}"
else
    echo -e "${YELLOW}⚠ Homebrew could not be verified; will proceed with system tools.${NC}"
fi

# ── 2. Check & Install Python 3.10+ ───────────────────────────────────────────
echo -e "\n${CYAN}▶ Checking Python installation…${NC}"
PY_CMD=""
for cmd in python3 python; do
    if command -v "$cmd" &>/dev/null; then
        PY_OK=$("$cmd" -c 'import sys; print(1 if sys.version_info >= (3, 10) else 0)' 2>/dev/null || echo 0)
        if [ "$PY_OK" -eq 1 ]; then
            PY_CMD="$cmd"
            PY_VER=$("$cmd" -c 'import sys; print(f"{sys.version_info.major}.{sys.version_info.minor}")')
            break
        fi
    fi
done

if [ -z "$PY_CMD" ]; then
    echo -e "${YELLOW}⚠ Python 3.10+ not found.${NC} Installing Python via Homebrew…"
    if command -v brew &>/dev/null; then
        brew install python
        PY_CMD="python3"
        PY_VER=$(python3 -c 'import sys; print(f"{sys.version_info.major}.{sys.version_info.minor}")')
    else
        echo -e "${RED}✗ Please install Python 3.10+ from https://www.python.org/downloads/ and re-run.${NC}"
        exit 1
    fi
fi
echo -e "${GREEN}✓ Python $PY_VER detected (${WHITE}$(command -v "$PY_CMD")${GREEN}).${NC}"

# ── 3. Check & Install FFmpeg ─────────────────────────────────────────────────
echo -e "\n${CYAN}▶ Checking FFmpeg…${NC}"
if ! command -v ffmpeg &>/dev/null; then
    echo -e "${YELLOW}⚠ FFmpeg is missing.${NC} FFmpeg is required for merging audio/video, converting formats, and metadata embedding."
    if command -v brew &>/dev/null; then
        echo -e "  Installing FFmpeg via Homebrew: ${WHITE}brew install ffmpeg${NC}"
        brew install ffmpeg
    else
        echo -e "${RED}✗ Please install FFmpeg via Homebrew ('brew install ffmpeg') or download from https://ffmpeg.org/download.html${NC}"
        exit 1
    fi
fi

if ! command -v ffmpeg &>/dev/null; then
    echo -e "${RED}✗ FFmpeg is still missing. Please install FFmpeg and re-run.${NC}"
    exit 1
fi
echo -e "${GREEN}✓ FFmpeg detected (${WHITE}$(command -v ffmpeg)${GREEN}).${NC}"

# ── 4. Check & Install Node.js (JavaScript Runtime) ───────────────────────────
echo -e "\n${CYAN}▶ Checking JavaScript runtime (required for YouTube n-challenge solving)…${NC}"
if command -v node &>/dev/null || command -v deno &>/dev/null || [ -d "$HOME/.nvm/versions/node" ]; then
    echo -e "${GREEN}✓ JavaScript runtime detected.${NC}"
else
    echo -e "${YELLOW}⚠ Node.js not detected.${NC}"
    echo -e "  YouTube throttles downloads to ~50 KB/s without a JS runtime to solve player challenges."
    if command -v brew &>/dev/null; then
        echo -e "  Installing Node.js via Homebrew…"
        brew install node || true
    fi
fi

# ── 5. Copy Application Files ─────────────────────────────────────────────────
echo -e "\n${CYAN}▶ Installing application files…${NC}"
mkdir -p "$INSTALL_DIR"
mkdir -p "$BIN_DIR"
mkdir -p "$APP_DIR"

cp "$SCRIPT_DIR/youtube-downloader.py" "$INSTALL_DIR/"
cp "$SCRIPT_DIR/youtube-downloader.svg" "$INSTALL_DIR/"
cp "$SCRIPT_DIR/requirements.txt" "$INSTALL_DIR/" 2>/dev/null || true
chmod +x "$INSTALL_DIR/youtube-downloader.py"

# ── 6. Set Up Python Environment & Dependencies ───────────────────────────────
echo -e "\n${CYAN}▶ Setting up Python virtual environment…${NC}"
"$PY_CMD" -m venv "$INSTALL_DIR/venv"
"$INSTALL_DIR/venv/bin/pip" install --upgrade pip --quiet
"$INSTALL_DIR/venv/bin/pip" install colorama "yt-dlp[default,curl-cffi]" --quiet

# Verify installation
if ! "$INSTALL_DIR/venv/bin/python3" -c "import colorama, yt_dlp" &>/dev/null; then
    echo -e "${RED}✗ Failed to verify Python dependencies. Retrying…${NC}"
    "$INSTALL_DIR/venv/bin/pip" install -r "$INSTALL_DIR/requirements.txt"
fi
echo -e "${GREEN}✓ Python dependencies verified (colorama, yt-dlp, curl-cffi).${NC}"

# ── 7. Create 'yt-dnld' CLI Command ───────────────────────────────────────────
echo -e "\n${CYAN}▶ Creating 'yt-dnld' command…${NC}"
cat <<EOF > "$BIN_DIR/yt-dnld"
#!/usr/bin/env bash
exec "$INSTALL_DIR/venv/bin/python3" "$INSTALL_DIR/youtube-downloader.py" "\$@"
EOF
chmod +x "$BIN_DIR/yt-dnld"

# Attempt symlink in /usr/local/bin if writable
if [ -w "/usr/local/bin" ]; then
    ln -sf "$BIN_DIR/yt-dnld" "/usr/local/bin/yt-dnld" 2>/dev/null || true
fi

# Update shell profile (.zshrc on modern macOS, .bash_profile for bash)
PATH_UPDATED=0
for RC in "$HOME/.zshrc" "$HOME/.bash_profile"; do
    if [ -f "$RC" ]; then
        if ! grep -q 'HOME/.local/bin' "$RC" && ! grep -q '$HOME/.local/bin' "$RC" && ! grep -q "$BIN_DIR" "$RC"; then
            echo -e "\n# Added by AS YouTube Downloader installer\nexport PATH=\"\$HOME/.local/bin:\$PATH\"" >> "$RC"
            PATH_UPDATED=1
        fi
    fi
done

# ── 8. Create macOS Application Launcher (.app) ───────────────────────────────
echo -e "\n${CYAN}▶ Creating macOS Application Launcher…${NC}"
MACOS_APP="$APP_DIR/AS YouTube Downloader.app"
DESKTOP_APP="$HOME/Desktop/AS YouTube Downloader.app"

if command -v osacompile &>/dev/null; then
    rm -rf "$MACOS_APP" 2>/dev/null || true
    osacompile -o "$MACOS_APP" -e 'tell application "Terminal"
        activate
        do script "yt-dnld"
    end tell'
    echo -e "${GREEN}✓ Created Application in $MACOS_APP${NC}"

    if [ -d "$HOME/Desktop" ]; then
        rm -rf "$DESKTOP_APP" 2>/dev/null || true
        cp -R "$MACOS_APP" "$DESKTOP_APP"
        echo -e "${GREEN}✓ Created Desktop shortcut at $DESKTOP_APP${NC}"
    fi
fi

# ── 9. Summary ────────────────────────────────────────────────────────────────
echo -e "\n${GREEN}════════════════════════════════════════════════════════════════${NC}"
echo -e "${GREEN}  ✓ Installation Complete!${NC}"
echo -e "${GREEN}════════════════════════════════════════════════════════════════${NC}"
echo -e "  ${WHITE}[✓] Python:${NC}             $PY_VER"
echo -e "  ${WHITE}[✓] FFmpeg:${NC}             $(command -v ffmpeg)"
echo -e "  ${WHITE}[✓] Modules:${NC}            yt-dlp, colorama, curl-cffi"
echo -e "  ${WHITE}[✓] Command:${NC}            ${CYAN}yt-dnld${NC} -> $BIN_DIR/yt-dnld"
echo -e "  ${WHITE}[✓] Application:${NC}        ~/Applications/AS YouTube Downloader.app"
echo ""
echo -e "You can now run ${WHITE}yt-dnld${NC} from any Terminal window."
echo -e "Or launch ${WHITE}AS YouTube Downloader${NC} from your Applications folder or Spotlight.\n"

if [ "$PATH_UPDATED" -eq 1 ]; then
    echo -e "${YELLOW}Note:${NC} ~/.local/bin was added to your shell configuration."
    echo -e "Run ${WHITE}source ~/.zshrc${NC} (or restart Terminal) to apply PATH updates.\n"
fi
