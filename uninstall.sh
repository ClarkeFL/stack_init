#!/bin/bash

# fcode Uninstaller

INSTALL_DIR="/usr/local/bin"
SCRIPT_NAME="fcode"

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

log() { echo -e "${BLUE}[uninstall]${NC} $1"; }
success() { echo -e "${GREEN}[success]${NC} $1"; }
warning() { echo -e "${YELLOW}[warning]${NC} $1"; }

# Check if installed
if [ ! -f "$INSTALL_DIR/$SCRIPT_NAME" ]; then
    warning "fcode is not installed at $INSTALL_DIR/$SCRIPT_NAME"
    exit 0
fi

# Show what will be removed
log "The following will be removed:"
echo "  - $INSTALL_DIR/$SCRIPT_NAME"
echo ""

# Confirmation
read -p "Continue with uninstall? (y/n): " confirm
if [ "$confirm" != "y" ]; then
    log "Uninstall cancelled"
    exit 0
fi

# Remove fcode
log "Removing fcode..."
if [ -w "$INSTALL_DIR/$SCRIPT_NAME" ]; then
    rm "$INSTALL_DIR/$SCRIPT_NAME"
else
    log "Need sudo permission to remove from $INSTALL_DIR"
    sudo rm "$INSTALL_DIR/$SCRIPT_NAME"
fi

# Verify removal
if command -v fcode &> /dev/null; then
    warning "fcode command still found in PATH. You may need to restart your terminal."
else
    success "fcode removed successfully!"
fi

# Optional: Remove Bun
if command -v bun &> /dev/null; then
    echo ""
    read -p "Also remove Bun? (y/n): " remove_bun
    if [ "$remove_bun" = "y" ]; then
        log "Removing Bun..."
        rm -rf "$HOME/.bun"
        
        # Note: Not removing from shell rc files to avoid breaking shell config
        warning "Note: Bun PATH entries in shell config files (~/.bashrc, ~/.zshrc) were not removed."
        warning "You may want to manually remove them if no longer needed."
        
        success "Bun directory removed"
    fi
fi

echo ""
success "Uninstall complete!"
