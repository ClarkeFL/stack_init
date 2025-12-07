#!/bin/bash

# fcode Installer

set -e

# --- Configuration ---
# REPLACE THIS URL with the raw URL of your 'fcode' script in your public repo
# Example: https://raw.githubusercontent.com/username/repo/main/fcode
DOWNLOAD_URL="https://raw.githubusercontent.com/YOUR_USERNAME/YOUR_REPO/main/fcode"
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

# If running locally for testing, we might want to just copy the file if it exists nearby.
# But for the curl | bash use case, we download.
# For now, I will add a check: if DOWNLOAD_URL contains "YOUR_USERNAME", warn the user.

if [[ "$DOWNLOAD_URL" == *"YOUR_USERNAME"* ]]; then
    echo "WARNING: You have not configured the DOWNLOAD_URL in install.sh yet."
    echo "For testing purposes, I will look for 'fcode' in the current directory."
    
    if [ -f "./fcode" ]; then
        log "Found local 'fcode' script. Installing from local..."
        
        # Check permissions for /usr/local/bin
        if [ -w "$INSTALL_DIR" ]; then
            cp ./fcode "$INSTALL_DIR/$SCRIPT_NAME"
        else
            log "Need sudo permission to install to $INSTALL_DIR"
            sudo cp ./fcode "$INSTALL_DIR/$SCRIPT_NAME"
        fi
    else
        echo "Error: Could not find 'fcode' locally and DOWNLOAD_URL is not configured."
        exit 1
    fi
else
    # Real download logic
    TEMP_FILE=$(mktemp)
    curl -fsSL "$DOWNLOAD_URL" -o "$TEMP_FILE"
    
    if [ -w "$INSTALL_DIR" ]; then
        mv "$TEMP_FILE" "$INSTALL_DIR/$SCRIPT_NAME"
    else
        log "Need sudo permission to install to $INSTALL_DIR"
        sudo mv "$TEMP_FILE" "$INSTALL_DIR/$SCRIPT_NAME"
    fi
fi

# 3. Finalize
if [ -w "$INSTALL_DIR/$SCRIPT_NAME" ]; then
    chmod +x "$INSTALL_DIR/$SCRIPT_NAME"
else
    sudo chmod +x "$INSTALL_DIR/$SCRIPT_NAME"
fi

success "$SCRIPT_NAME installed successfully!"
echo "Run '$SCRIPT_NAME init' to get started."
