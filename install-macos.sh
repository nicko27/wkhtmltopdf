#!/bin/bash
# wkhtmltopdf Installation Script for macOS
# Requires: Homebrew (https://brew.sh)

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Configuration
# Force WebEngine on macOS (WebKit is not available in modern Qt)
RENDER_BACKEND="webengine"
INSTALL_PREFIX="${INSTALL_PREFIX:-/usr/local}"
BUILD_JOBS=$(sysctl -n hw.ncpu 2>/dev/null || echo 4)

echo -e "${BLUE}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║  wkhtmltopdf Installation Script for macOS                ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════════════════╝${NC}"
echo ""

# Detect macOS version
MACOS_VERSION=$(sw_vers -productVersion)
MACOS_MAJOR=$(echo $MACOS_VERSION | cut -d. -f1)

echo -e "${GREEN}✓${NC} Detected: macOS $MACOS_VERSION"
echo -e "${BLUE}ℹ${NC} Backend: $RENDER_BACKEND"
echo -e "${BLUE}ℹ${NC} Install prefix: $INSTALL_PREFIX"
echo -e "${BLUE}ℹ${NC} Build jobs: $BUILD_JOBS"
echo ""

# Check macOS version
if [ "$MACOS_MAJOR" -lt "10" ]; then
    echo -e "${RED}✗ Unsupported macOS version${NC}"
    echo "  Minimum required: macOS 10.13 (High Sierra)"
    exit 1
fi

# Warning for WebKit on macOS
if [[ "$RENDER_BACKEND" == "webkit" ]]; then
    echo -e "${YELLOW}⚠ Warning: Qt WebKit is deprecated on macOS${NC}"
    echo -e "${YELLOW}  Switching to WebEngine backend (modern CSS support)${NC}"
    echo ""
    RENDER_BACKEND="webengine"
fi

# Check if Homebrew is installed
echo -e "${BLUE}[1/5]${NC} Checking for Homebrew..."

if ! command -v brew >/dev/null 2>&1; then
    echo -e "${RED}✗ Homebrew is not installed!${NC}"
    echo ""
    echo "Homebrew is required to install dependencies on macOS."
    echo ""
    echo "Install Homebrew by running:"
    echo '  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"'
    echo ""
    echo "Then run this script again."
    exit 1
fi

echo -e "${GREEN}✓${NC} Homebrew found: $(brew --version | head -n1)"

# Update Homebrew
echo -e "${BLUE}[2/5]${NC} Updating Homebrew..."
brew update

# Install dependencies
echo -e "${BLUE}[3/5]${NC} Installing dependencies..."

# Install build tools
echo -e "${BLUE}ℹ${NC} Installing build tools..."
brew install git pkg-config

# Install Qt
echo -e "${BLUE}ℹ${NC} Installing Qt 5..."

# Check if Qt is already installed
if brew list qt@5 &>/dev/null; then
    echo -e "${YELLOW}⚠${NC} Qt 5 is already installed"
    echo -e "${BLUE}ℹ${NC} Upgrading to latest version..."
    brew upgrade qt@5 || true
else
    brew install qt@5
fi

echo -e "${GREEN}✓${NC} Dependencies installed"

# Set Qt environment variables
echo -e "${BLUE}ℹ${NC} Setting up Qt environment..."

# Detect Qt installation path (handles both Intel and Apple Silicon)
if [ -d "/opt/homebrew/opt/qt@5" ]; then
    # Apple Silicon
    QT_PATH="/opt/homebrew/opt/qt@5"
elif [ -d "/usr/local/opt/qt@5" ]; then
    # Intel Mac
    QT_PATH="/usr/local/opt/qt@5"
else
    echo -e "${RED}✗ Could not find Qt installation${NC}"
    exit 1
fi

export PATH="$QT_PATH/bin:$PATH"
export LDFLAGS="-L$QT_PATH/lib"
export CPPFLAGS="-I$QT_PATH/include"
export PKG_CONFIG_PATH="$QT_PATH/lib/pkgconfig"

echo -e "${GREEN}✓${NC} Qt found at: $QT_PATH"

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
$QT_PATH/bin/qmake INSTALLBASE=$INSTALL_PREFIX

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
    if [[ "$RENDER_BACKEND" == "both" ]] || [[ "$RENDER_BACKEND" == "webengine" ]]; then
        echo -e "${GREEN}✓${NC} WebEngine backend installed (modern CSS support)"
        echo "  Supports: flexbox, grid, transforms, animations, modern CSS3"
        echo ""
        echo "Usage:"
        echo "  wkhtmltopdf input.html output.pdf"
        echo "  wkhtmltopdf --render-backend webengine input.html output.pdf"
    fi
else
    echo -e "${YELLOW}⚠ wkhtmltopdf not found in PATH${NC}"
    echo "  You may need to add $INSTALL_PREFIX/bin to your PATH"
    echo ""
    echo "  Add this to your ~/.zshrc or ~/.bash_profile:"
    echo "    export PATH=\"$INSTALL_PREFIX/bin:\$PATH\""
fi

echo ""
echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
echo -e "${BLUE}Important Notes for macOS:${NC}"
echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
echo ""
echo "1. Qt Environment:"
echo "   Qt is installed via Homebrew and is keg-only (not linked)."
echo "   If you need to build again, set these environment variables:"
echo ""
echo "     export PATH=\"$QT_PATH/bin:\$PATH\""
echo "     export LDFLAGS=\"-L$QT_PATH/lib\""
echo "     export CPPFLAGS=\"-I$QT_PATH/include\""
echo ""
echo "2. Security & Permissions:"
echo "   On macOS 10.15+ (Catalina and later), you may need to grant"
echo "   permissions for wkhtmltopdf to access files."
echo ""
echo "3. Rendering:"
echo "   WebEngine uses Chromium which may require additional permissions"
echo "   for network access and GPU acceleration."
echo ""
echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
echo ""
echo "Next steps:"
echo ""
echo "  1. Try the examples:"
echo "     cd examples && make demo"
echo ""
echo "  2. Read the documentation:"
echo "     cat MULTI_BACKEND.md"
echo ""
echo "  3. Test modern CSS:"
echo "     wkhtmltopdf examples/modern_css_demo.html test.pdf"
echo "     open test.pdf"
echo ""
echo "  4. Add wkhtmltopdf to your PATH permanently:"
echo "     echo 'export PATH=\"$INSTALL_PREFIX/bin:\$PATH\"' >> ~/.zshrc"
echo "     source ~/.zshrc"
echo ""
