#!/usr/bin/env bash
# ==============================================================================
# AS YouTube Downloader — macOS Installer
# Installs youtube-downloader, configures dependencies, registers 'yt-dnld'
# in the shell PATH, and builds a native macOS Application launcher.
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

# ── 1. Check Homebrew (optional but recommended) ──────────────────────────────
HAS_BREW=0
if command -v brew &>/dev/null; then
    HAS_BREW=1
fi

# ── 2. Check Python 3.10+ ─────────────────────────────────────────────────────
echo -e "${CYAN}▶ Checking Python installation…${NC}"
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
    echo -e "${YELLOW}⚠ Python 3.10+ not found.${NC}"
    if [ "$HAS_BREW" -eq 1 ]; then
        echo -e "  Installing Python via Homebrew: ${WHITE}brew install python${NC}"
        brew install python
        PY_CMD="python3"
    else
        echo -e "${RED}✗ Please install Python 3.10+ from https://www.python.org/downloads/ or install Homebrew (https://brew.sh).${NC}"
        exit 1
    fi
fi
echo -e "${GREEN}✓ Python $PY_VER detected ($PY_CMD).${NC}"

# ── 3. Check FFmpeg ───────────────────────────────────────────────────────────
echo -e "\n${CYAN}▶ Checking FFmpeg…${NC}"
if ! command -v ffmpeg &>/dev/null; then
    echo -e "${YELLOW}⚠ FFmpeg is missing.${NC}"
    if [ "$HAS_BREW" -eq 1 ]; then
        echo -e "  Installing FFmpeg via Homebrew: ${WHITE}brew install ffmpeg${NC}"
        brew install ffmpeg
    else
        echo -e "${YELLOW}  Install FFmpeg via Homebrew (${WHITE}brew install ffmpeg${YELLOW}) or download from https://ffmpeg.org/download.html${NC}"
    fi
else
    echo -e "${GREEN}✓ FFmpeg detected ($(command -v ffmpeg)).${NC}"
fi

# ── 4. Install Files & Set Up Environment ─────────────────────────────────────
echo -e "\n${CYAN}▶ Installing application files…${NC}"
mkdir -p "$INSTALL_DIR"
mkdir -p "$BIN_DIR"
mkdir -p "$APP_DIR"

cp "$SCRIPT_DIR/youtube-downloader.py" "$INSTALL_DIR/"
cp "$SCRIPT_DIR/youtube-downloader.svg" "$INSTALL_DIR/"
cp "$SCRIPT_DIR/requirements.txt" "$INSTALL_DIR/" 2>/dev/null || true
chmod +x "$INSTALL_DIR/youtube-downloader.py"

echo -e "\n${CYAN}▶ Setting up Python virtual environment…${NC}"
"$PY_CMD" -m venv "$INSTALL_DIR/venv"
"$INSTALL_DIR/venv/bin/pip" install --upgrade pip --quiet
"$INSTALL_DIR/venv/bin/pip" install colorama "yt-dlp[default,curl-cffi]" --quiet
echo -e "${GREEN}✓ Dependencies installed in isolated environment.${NC}"

# ── 5. Create 'yt-dnld' CLI Command ───────────────────────────────────────────
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

# ── 6. Create macOS Application Launcher (.app) ───────────────────────────────
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

    # Also place on Desktop
    if [ -d "$HOME/Desktop" ]; then
        rm -rf "$DESKTOP_APP" 2>/dev/null || true
        cp -R "$MACOS_APP" "$DESKTOP_APP"
        echo -e "${GREEN}✓ Created Desktop shortcut at $DESKTOP_APP${NC}"
    fi
fi

echo -e "\n${GREEN}════════════════════════════════════════════════════════════════${NC}"
echo -e "${GREEN}  ✓ Installation Complete!${NC}"
echo -e "${GREEN}════════════════════════════════════════════════════════════════${NC}"
echo -e "You can now run ${WHITE}yt-dnld${NC} from any Terminal window."
echo -e "Or launch ${WHITE}AS YouTube Downloader${NC} from your Applications folder or Spotlight.\n"

if [ "$PATH_UPDATED" -eq 1 ]; then
    echo -e "${YELLOW}Note:${NC} ~/.local/bin was added to your shell configuration."
    echo -e "Run ${WHITE}source ~/.zshrc${NC} (or restart Terminal) to apply PATH updates.\n"
fi

