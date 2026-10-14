#!/usr/bin/env bash
# ==============================================================================
# AS YouTube Downloader — Unified Unix Installer Entrypoint
# Dispatches to Linux or macOS installer based on operating system.
# ==============================================================================

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OS="$(uname -s)"

case "$OS" in
    Linux*)
        exec "$SCRIPT_DIR/installers/install-linux.sh" "$@"
        ;;
    Darwin*)
        exec "$SCRIPT_DIR/installers/install-macos.sh" "$@"
        ;;
    *)
        echo "Unsupported OS: $OS"
        echo "Please follow manual installation instructions in README.md."
        exit 1
        ;;
esac

