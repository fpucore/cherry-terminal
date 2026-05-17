#!/bin/bash

# Cherry Terminal+ Installer
# Installs Cherry Terminal+ compiled binary to a Linux system

set -e  # Exit on error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}Cherry Terminal+ Installer${NC}"
echo "================================"
echo ""

# Check if running as root
if [ "$EUID" -ne 0 ]; then 
    echo -e "${RED}Error: Please run as root (use sudo)${NC}"
    exit 1
fi

# Check if compiled binaries exist
if [ ! -f "kitty/launcher/cherry-terminal" ]; then
    echo -e "${RED}Error: cherry-terminal binary not found. Did you run ./setup.py first?${NC}"
    exit 1
fi

INSTALL_BASE="/usr/lib/cherry-terminal"

echo -e "${YELLOW}Installing Cherry Terminal+ to ${INSTALL_BASE}...${NC}"

# Remove old installation
if [ -d "${INSTALL_BASE}" ]; then
    echo "  → Removing old installation..."
    rm -rf ${INSTALL_BASE}
fi

# Create directory structure (preserving relative paths from build)
echo "  → Creating directory structure..."
mkdir -p ${INSTALL_BASE}/kitty/launcher

# Install main binary (preserving relative path structure)
echo "  → Installing cherry-terminal binary..."
cp kitty/launcher/cherry-terminal ${INSTALL_BASE}/kitty/launcher/
chmod +x ${INSTALL_BASE}/kitty/launcher/cherry-terminal

# Install kitten binary if it exists
if [ -f "kitty/launcher/kitten" ]; then
    echo "  → Installing kitten binary..."
    cp kitty/launcher/kitten ${INSTALL_BASE}/kitty/launcher/
    chmod +x ${INSTALL_BASE}/kitty/launcher/kitten
fi

# Copy __main__.py to the base (binary looks ../.. from kitty/launcher/)
echo "  → Installing __main__.py..."
cp __main__.py ${INSTALL_BASE}/

# Copy Python package
echo "  → Installing Python libraries..."
cp -r kitty ${INSTALL_BASE}/

# Copy assets (fonts, logos)
if [ -d "fonts" ] || [ -d "kitty/fonts" ]; then
    echo "  → Installing fonts..."
    if [ -d "kitty/fonts" ]; then
        mkdir -p ${INSTALL_BASE}/fonts
        cp -r kitty/fonts/* ${INSTALL_BASE}/fonts/ 2>/dev/null || true
    fi
    if [ -d "fonts" ]; then
        mkdir -p ${INSTALL_BASE}/fonts
        cp -r fonts/* ${INSTALL_BASE}/fonts/ 2>/dev/null || true
    fi
fi

if [ -d "logo" ]; then
    echo "  → Installing logos..."
    mkdir -p ${INSTALL_BASE}/logo
    cp -r logo/* ${INSTALL_BASE}/logo/
fi

# Create symlink in /usr/bin for easy access
echo "  → Creating symlink in /usr/bin..."
ln -sf ${INSTALL_BASE}/kitty/launcher/cherry-terminal /usr/bin/cherry-terminal

# Create kitten symlink if binary exists
if [ -f "${INSTALL_BASE}/kitty/launcher/kitten" ]; then
    ln -sf ${INSTALL_BASE}/kitty/launcher/kitten /usr/bin/kitten
fi

# Create compatibility symlink (kitty → cherry-terminal)
echo -e "${YELLOW}Executing compatibility patch...${NC}"
if [ -L /usr/bin/kitty ]; then
    echo "  → Removing existing kitty symlink..."
    rm /usr/bin/kitty
elif [ -f /usr/bin/kitty ]; then
    echo -e "${YELLOW}  ⚠ Warning: /usr/bin/kitty exists and is a real file, not a symlink${NC}"
    read -p "  Do you want to back it up and replace it? [y/N] " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        mv /usr/bin/kitty /usr/bin/kitty.backup
        echo "  → Original kitty backed up to /usr/bin/kitty.backup"
    else
        echo "  → Skipping kitty symlink creation"
        SKIP_SYMLINK=1
    fi
fi

if [ -z "$SKIP_SYMLINK" ]; then
    ln -s /usr/bin/cherry-terminal /usr/bin/kitty
    echo "  → Created symlink: /usr/bin/kitty → /usr/bin/cherry-terminal"
fi

# Install desktop file
if [ -f "cherry-terminal.desktop" ]; then
    echo "  → Installing desktop file..."
    mkdir -p /usr/share/applications
    cp cherry-terminal.desktop /usr/share/applications/
elif [ -f "kitty.desktop" ]; then
    echo "  → Installing desktop file (using kitty.desktop)..."
    mkdir -p /usr/share/applications
    cp kitty.desktop /usr/share/applications/cherry-terminal.desktop
fi

# Install icon for desktop file
if [ -f "logo/kitty.png" ]; then
    echo "  → Installing application icon..."
    mkdir -p /usr/share/pixmaps
    cp logo/kitty.png /usr/share/pixmaps/cherry-terminal.png
elif [ -f "logo/kitty-128.png" ]; then
    mkdir -p /usr/share/pixmaps
    cp logo/kitty-128.png /usr/share/pixmaps/cherry-terminal.png
fi

echo ""
echo -e "${GREEN}✓ Installation complete!${NC}"
echo ""
echo "Cherry Terminal+ has been installed to:"
echo "  • ${INSTALL_BASE}/ (installation directory)"
echo "  • /usr/bin/cherry-terminal (binary symlink)"
[ -f "/usr/bin/kitten" ] && echo "  • /usr/bin/kitten (utility binary symlink)"
[ -L "/usr/bin/kitty" ] && echo "  • /usr/bin/kitty (compatibility symlink)"
echo ""
echo "You can now run: cherry-terminal"
echo ""
