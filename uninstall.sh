#!/usr/bin/env bash
# ==============================================================================
# AS YouTube Downloader — Unified Unix Uninstaller Entrypoint
# ==============================================================================

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OS="$(uname -s)"

case "$OS" in
    Linux*)
        exec "$SCRIPT_DIR/installers/uninstall-linux.sh" "$@"
        ;;
    Darwin*)
        exec "$SCRIPT_DIR/installers/uninstall-macos.sh" "$@"
        ;;
    *)
        echo "Unsupported OS: $OS"
        exit 1
        ;;
esac

