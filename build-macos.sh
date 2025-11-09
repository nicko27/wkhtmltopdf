#!/bin/bash
# Quick build script for macOS
# WebKit is not available on macOS, so we force WebEngine backend

set -e

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${BLUE}Building wkhtmltopdf for macOS with WebEngine backend...${NC}"
echo ""

# Detect Qt path
if [ -d "/opt/homebrew/opt/qt@5" ]; then
    QT_PATH="/opt/homebrew/opt/qt@5"
elif [ -d "/usr/local/opt/qt@5" ]; then
    QT_PATH="/usr/local/opt/qt@5"
else
    echo -e "${RED}Error: Qt@5 not found${NC}"
    echo "Install with: brew install qt@5"
    exit 1
fi

echo -e "${GREEN}✓${NC} Found Qt at: $QT_PATH"

# Set environment
export PATH="$QT_PATH/bin:$PATH"
export LDFLAGS="-L$QT_PATH/lib"
export CPPFLAGS="-I$QT_PATH/include"

# Clean previous build
echo -e "${BLUE}Cleaning previous build...${NC}"
make clean 2>/dev/null || true
rm -f .qmake.stash
find . -name "Makefile*" -type f | grep -v "examples/Makefile" | xargs rm -f 2>/dev/null || true

# Configure with WebEngine backend (WebKit not available on macOS)
echo -e "${BLUE}Configuring with qmake (WebEngine backend)...${NC}"
export RENDER_BACKEND=webengine
$QT_PATH/bin/qmake INSTALLBASE=/usr/local

# Build
echo -e "${BLUE}Compiling...${NC}"
make -j$(sysctl -n hw.ncpu)

echo ""
echo -e "${GREEN}✓ Build successful!${NC}"
echo ""
echo "To install:"
echo "  sudo make install"
echo ""
echo "To test:"
echo "  cd examples && make demo"
