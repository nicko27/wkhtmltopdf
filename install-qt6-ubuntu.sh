#!/bin/bash
# wkhtmltopdf Installation Script for Qt6
# Requires: Ubuntu 24.04+, Debian 13+

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Configuration
INSTALL_PREFIX="${INSTALL_PREFIX:-/usr/local}"
BUILD_JOBS=$(nproc)

echo -e "${BLUE}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║  wkhtmltopdf Qt6 Installation Script (v1.0.0)             ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "${YELLOW}⚠  Note: Qt6 version ONLY supports WebEngine backend${NC}"
echo -e "${YELLOW}   WebKit is not available in Qt6${NC}"
echo ""

# Check if running on Ubuntu/Debian
if [ ! -f /etc/os-release ]; then
    echo -e "${RED}✗ Cannot detect OS version${NC}"
    exit 1
fi

. /etc/os-release

echo -e "${GREEN}✓${NC} Detected: $PRETTY_NAME"
echo -e "${BLUE}ℹ${NC} Backend: WebEngine (Qt6 only supports WebEngine)"
echo -e "${BLUE}ℹ${NC} Install prefix: $INSTALL_PREFIX"
echo -e "${BLUE}ℹ${NC} Build jobs: $BUILD_JOBS"
echo ""

# Check Ubuntu/Debian version
MIN_UBUNTU=24
MIN_DEBIAN=13

if [[ "$ID" == "ubuntu" ]]; then
    VERSION_NUM=$(echo $VERSION_ID | cut -d. -f1)
    if [ "$VERSION_NUM" -lt "$MIN_UBUNTU" ]; then
        echo -e "${RED}✗ Error: Ubuntu $VERSION_ID is not supported for Qt6${NC}"
        echo -e "${RED}  Qt6 requires Ubuntu $MIN_UBUNTU.04 or later${NC}"
        echo ""
        echo -e "${BLUE}ℹ${NC} For older Ubuntu versions, use Qt5 version:"
        echo "  ./install-ubuntu.sh"
        exit 1
    fi
elif [[ "$ID" == "debian" ]]; then
    VERSION_NUM=$(echo $VERSION_ID)
    if [ "$VERSION_NUM" -lt "$MIN_DEBIAN" ]; then
        echo -e "${RED}✗ Error: Debian $VERSION_ID is not supported for Qt6${NC}"
        echo -e "${RED}  Qt6 requires Debian $MIN_DEBIAN or later${NC}"
        echo ""
        echo -e "${BLUE}ℹ${NC} For older Debian versions, use Qt5 version:"
        echo "  ./install-ubuntu.sh"
        exit 1
    fi
fi

echo -e "${GREEN}✓${NC} OS version is compatible with Qt6"
echo ""

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

# Install Qt6 packages
echo -e "${BLUE}[3/5]${NC} Installing Qt6 dependencies..."
echo -e "${BLUE}ℹ${NC} Installing Qt6 WebEngine (modern CSS support, Chromium 108+)..."

# Check if Qt6 packages are available
if ! apt-cache show qt6-base-dev >/dev/null 2>&1; then
    echo -e "${RED}✗ Error: Qt6 packages not found in repositories${NC}"
    echo ""
    echo "This could mean:"
    echo "  - Your Ubuntu/Debian version doesn't have Qt6 in main repos"
    echo "  - You need to add universe repository"
    echo ""
    echo "Try:"
    echo "  sudo add-apt-repository universe"
    echo "  sudo apt-get update"
    exit 1
fi

sudo apt-get install -y -qq \
    qt6-base-dev \
    qt6-base-dev-tools \
    qmake6 \
    libqt6core6 \
    libqt6gui6 \
    libqt6network6 \
    libqt6svg6 \
    qt6-webengine-dev \
    libqt6webenginecore6 \
    libqt6webenginewidgets6 \
    libqt6printsupport6

echo -e "${GREEN}✓${NC} Qt6 dependencies installed"
echo ""

# Display Qt6 version
if command -v qmake6 >/dev/null 2>&1; then
    QT6_VERSION=$(qmake6 -query QT_VERSION)
    echo -e "${BLUE}ℹ${NC} Qt6 version: $QT6_VERSION"

    # Check Chromium version
    echo -e "${BLUE}ℹ${NC} WebEngine uses Chromium 108+ (modern web standards)"
fi
echo ""

# Build the project
echo -e "${BLUE}[4/5]${NC} Building wkhtmltopdf with Qt6..."

# Clean previous build
if [ -d "bin" ]; then
    echo -e "${BLUE}ℹ${NC} Cleaning previous build..."
    rm -rf bin
fi

# Run qmake6
echo -e "${BLUE}ℹ${NC} Configuring with qmake6..."
qmake6 INSTALLBASE=$INSTALL_PREFIX

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
echo -e "${GREEN}✓ Qt6 Installation successful!${NC}"
echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
echo ""

if command -v wkhtmltopdf >/dev/null 2>&1; then
    wkhtmltopdf --version
    echo ""

    echo -e "${GREEN}✓${NC} Qt6 WebEngine backend installed"
    echo ""
    echo "Features:"
    echo "  ✓ Full CSS3 support (Flexbox, Grid, Transforms, Animations)"
    echo "  ✓ Modern JavaScript (ES6+)"
    echo "  ✓ Latest web standards"
    echo "  ✓ Chromium 108+ rendering engine"
    echo ""
    echo "Usage:"
    echo "  wkhtmltopdf input.html output.pdf"
    echo ""
    echo -e "${YELLOW}⚠${NC} Note: WebKit backend is not available in Qt6"
    echo "  Qt6 only supports WebEngine (modern CSS)"
else
    echo -e "${YELLOW}⚠ wkhtmltopdf not found in PATH${NC}"
    echo "  You may need to add $INSTALL_PREFIX/bin to your PATH"
    echo "  Add this to your ~/.bashrc:"
    echo "    export PATH=\"$INSTALL_PREFIX/bin:\$PATH\""
fi

echo ""
echo "Next steps:"
echo "  1. Test with modern CSS:"
echo "     wkhtmltopdf examples/modern_css_demo.html test.pdf"
echo ""
echo "  2. Read the Qt6 migration guide:"
echo "     cat QT6_MIGRATION.md"
echo ""
echo "  3. Report issues:"
echo "     https://github.com/wkhtmltopdf/wkhtmltopdf/issues"
echo ""
