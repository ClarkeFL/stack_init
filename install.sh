#!/bin/bash

# fcode Installer

set -e

# --- Configuration ---
# REPLACE THIS URL with the raw URL of your 'fcode' script in your public repo
# Example: https://raw.githubusercontent.com/username/repo/main/fcode
DOWNLOAD_URL="https://raw.githubusercontent.com/ClarkeFL/stack_init/main/fcode"
INSTALL_DIR="/usr/local/bin"
SCRIPT_NAME="fcode"

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'

log() { echo -e "${BLUE}[install]${NC} $1"; }
success() { echo -e "${GREEN}[success]${NC} $1"; }

# 1. Check/Install Bun
if ! command -v bun &> /dev/null; then
    log "Bun not found. Installing Bun..."
    curl -fsSL https://bun.sh/install | bash
    
    # Source bun config if possible to make it available immediately
    export BUN_INSTALL="$HOME/.bun"
    export PATH="$BUN_INSTALL/bin:$PATH"
else
    log "Bun is already installed."
fi

# 2. Download and Install fcode
log "Installing $SCRIPT_NAME..."

TEMP_FILE=$(mktemp)
if ! curl -fsSL "$DOWNLOAD_URL" -o "$TEMP_FILE"; then
    echo "Error: Failed to download fcode from $DOWNLOAD_URL"
    rm -f "$TEMP_FILE"
    exit 1
fi

if [ -w "$INSTALL_DIR" ]; then
    mv "$TEMP_FILE" "$INSTALL_DIR/$SCRIPT_NAME"
else
    log "Need sudo permission to install to $INSTALL_DIR"
    sudo mv "$TEMP_FILE" "$INSTALL_DIR/$SCRIPT_NAME"
fi

# 3. Finalize
if [ -w "$INSTALL_DIR/$SCRIPT_NAME" ]; then
    chmod +x "$INSTALL_DIR/$SCRIPT_NAME"
else
    sudo chmod +x "$INSTALL_DIR/$SCRIPT_NAME"
fi

success "$SCRIPT_NAME installed successfully!"
echo "Run '$SCRIPT_NAME init' to get started."
