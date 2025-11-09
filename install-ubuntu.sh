#!/bin/bash
# wkhtmltopdf Installation Script for Ubuntu/Debian
# Supports Ubuntu 18.04+, Debian 10+

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Configuration
RENDER_BACKEND="${RENDER_BACKEND:-both}"
INSTALL_PREFIX="${INSTALL_PREFIX:-/usr/local}"
BUILD_JOBS=$(nproc)

echo -e "${BLUE}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║  wkhtmltopdf Installation Script for Ubuntu/Debian        ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════════════════╝${NC}"
echo ""

# Check if running on Ubuntu/Debian
if [ ! -f /etc/os-release ]; then
    echo -e "${RED}✗ Cannot detect OS version${NC}"
    exit 1
fi

. /etc/os-release

echo -e "${GREEN}✓${NC} Detected: $PRETTY_NAME"
echo -e "${BLUE}ℹ${NC} Backend: $RENDER_BACKEND"
echo -e "${BLUE}ℹ${NC} Install prefix: $INSTALL_PREFIX"
echo -e "${BLUE}ℹ${NC} Build jobs: $BUILD_JOBS"
echo ""

# Check Ubuntu/Debian version
MIN_VERSION=18
if [[ "$ID" == "ubuntu" ]]; then
    VERSION_NUM=$(echo $VERSION_ID | cut -d. -f1)
    if [ "$VERSION_NUM" -lt "$MIN_VERSION" ]; then
        echo -e "${YELLOW}⚠ Warning: Ubuntu $VERSION_ID is older than recommended (18.04+)${NC}"
        echo -e "${YELLOW}  Some Qt packages may not be available${NC}"
        echo ""
    fi
elif [[ "$ID" == "debian" ]]; then
    VERSION_NUM=$(echo $VERSION_ID)
    if [ "$VERSION_NUM" -lt "10" ]; then
        echo -e "${YELLOW}⚠ Warning: Debian $VERSION_ID is older than recommended (10+)${NC}"
        echo ""
    fi
fi

# Update package list
echo -e "${BLUE}[1/5]${NC} Updating package lists..."
sudo apt-get update -qq

# Install build essentials
echo -e "${BLUE}[2/5]${NC} Installing build tools..."
sudo apt-get install -y -qq \
    build-essential \
    git \
    pkg-config \
    libssl-dev \
    libfontconfig1-dev \
    libfreetype6-dev \
    libx11-dev \
    libxext-dev \
    libxrender-dev

echo -e "${GREEN}✓${NC} Build tools installed"

# Install Qt packages based on backend
echo -e "${BLUE}[3/5]${NC} Installing Qt dependencies..."

COMMON_PACKAGES="
    qt5-qmake
    qtbase5-dev
    qtbase5-dev-tools
    libqt5svg5-dev
    libqt5xmlpatterns5-dev
    libqt5network5
"

if [[ "$RENDER_BACKEND" == "webkit" ]]; then
    echo -e "${BLUE}ℹ${NC} Installing Qt WebKit (legacy)..."
    sudo apt-get install -y -qq $COMMON_PACKAGES \
        libqt5webkit5-dev

elif [[ "$RENDER_BACKEND" == "webengine" ]]; then
    echo -e "${BLUE}ℹ${NC} Installing Qt WebEngine (modern CSS support)..."

    # Check if WebEngine packages are available
    if apt-cache show qtwebengine5-dev >/dev/null 2>&1; then
        sudo apt-get install -y -qq $COMMON_PACKAGES \
            qtwebengine5-dev \
            libqt5webenginewidgets5 \
            libqt5webenginecore5 \
            libqt5printsupport5
    else
        echo -e "${YELLOW}⚠ Warning: Qt WebEngine packages not found in repositories${NC}"
        echo -e "${YELLOW}  Attempting to add universe repository...${NC}"
        sudo add-apt-repository universe -y
        sudo apt-get update -qq
        sudo apt-get install -y -qq $COMMON_PACKAGES \
            qtwebengine5-dev \
            libqt5webenginewidgets5 \
            libqt5webenginecore5 \
            libqt5printsupport5
    fi

else  # both
    echo -e "${BLUE}ℹ${NC} Installing both Qt WebKit and WebEngine..."

    if apt-cache show qtwebengine5-dev >/dev/null 2>&1; then
        sudo apt-get install -y -qq $COMMON_PACKAGES \
            libqt5webkit5-dev \
            qtwebengine5-dev \
            libqt5webenginewidgets5 \
            libqt5webenginecore5 \
            libqt5printsupport5
    else
        echo -e "${YELLOW}⚠ Installing WebKit only (WebEngine not available)${NC}"
        sudo apt-get install -y -qq $COMMON_PACKAGES \
            libqt5webkit5-dev
        RENDER_BACKEND="webkit"
    fi
fi

echo -e "${GREEN}✓${NC} Qt dependencies installed"

# Build the project
echo -e "${BLUE}[4/5]${NC} Building wkhtmltopdf..."

# Clean previous build
if [ -d "bin" ]; then
    echo -e "${BLUE}ℹ${NC} Cleaning previous build..."
    rm -rf bin
fi

# Run qmake
echo -e "${BLUE}ℹ${NC} Configuring with qmake..."
export RENDER_BACKEND=$RENDER_BACKEND
qmake INSTALLBASE=$INSTALL_PREFIX

# Compile
echo -e "${BLUE}ℹ${NC} Compiling (using $BUILD_JOBS jobs)..."
make -j$BUILD_JOBS

echo -e "${GREEN}✓${NC} Build completed"

# Install
echo -e "${BLUE}[5/5]${NC} Installing wkhtmltopdf..."
sudo make install

echo -e "${GREEN}✓${NC} Installation completed"
echo ""

# Verify installation
echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
echo -e "${GREEN}✓ Installation successful!${NC}"
echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
echo ""

if command -v wkhtmltopdf >/dev/null 2>&1; then
    wkhtmltopdf --version
    echo ""

    # Show backend info
    if [[ "$RENDER_BACKEND" == "both" ]]; then
        echo -e "${GREEN}✓${NC} Both rendering backends installed:"
        echo "  • WebKit (legacy) - for simple HTML/CSS"
        echo "  • WebEngine (modern) - for modern CSS (flex, grid, etc.)"
        echo ""
        echo "Usage:"
        echo "  wkhtmltopdf --render-backend webkit input.html output.pdf"
        echo "  wkhtmltopdf --render-backend webengine input.html output.pdf"
    elif [[ "$RENDER_BACKEND" == "webengine" ]]; then
        echo -e "${GREEN}✓${NC} WebEngine backend installed (modern CSS support)"
        echo "  Supports: flexbox, grid, transforms, modern CSS3"
    else
        echo -e "${GREEN}✓${NC} WebKit backend installed (legacy)"
        echo "  Limited CSS3 support"
    fi
else
    echo -e "${YELLOW}⚠ wkhtmltopdf not found in PATH${NC}"
    echo "  You may need to add $INSTALL_PREFIX/bin to your PATH"
    echo "  Add this to your ~/.bashrc:"
    echo "    export PATH=\"$INSTALL_PREFIX/bin:\$PATH\""
fi

echo ""
echo "Next steps:"
echo "  1. Try the examples:"
echo "     cd examples && make demo"
echo ""
echo "  2. Read the documentation:"
echo "     cat MULTI_BACKEND.md"
echo ""
echo "  3. Test modern CSS:"
echo "     wkhtmltopdf --render-backend webengine examples/modern_css_demo.html test.pdf"
echo ""
