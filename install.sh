#!/bin/bash
# wkhtmltopdf Installation Script
# Supports: Ubuntu/Debian, macOS (with Homebrew)

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
RENDER_BACKEND="${RENDER_BACKEND:-both}"  # Default to both backends
INSTALL_PREFIX="${INSTALL_PREFIX:-/usr/local}"
BUILD_TYPE="${BUILD_TYPE:-release}"

print_header() {
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${BLUE}  $1${NC}"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
}

print_success() {
    echo -e "${GREEN}✓${NC} $1"
}

print_error() {
    echo -e "${RED}✗${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}⚠${NC} $1"
}

print_info() {
    echo -e "${BLUE}ℹ${NC} $1"
}

# Detect OS
detect_os() {
    if [[ "$OSTYPE" == "linux-gnu"* ]]; then
        if [ -f /etc/os-release ]; then
            . /etc/os-release
            OS=$ID
            OS_VERSION=$VERSION_ID
        else
            OS="unknown"
        fi
    elif [[ "$OSTYPE" == "darwin"* ]]; then
        OS="macos"
        OS_VERSION=$(sw_vers -productVersion)
    else
        OS="unknown"
    fi
}

# Check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Ubuntu/Debian installation
install_ubuntu() {
    print_header "Installing on Ubuntu/Debian"

    print_info "Updating package list..."
    sudo apt-get update

    print_info "Installing build essentials..."
    sudo apt-get install -y \
        build-essential \
        git \
        cmake \
        pkg-config

    print_info "Installing Qt dependencies..."

    if [[ "$RENDER_BACKEND" == "webkit" ]]; then
        print_info "Installing Qt WebKit (legacy)..."
        sudo apt-get install -y \
            qt5-qmake \
            libqt5webkit5-dev \
            libqt5svg5-dev \
            libqt5xmlpatterns5-dev \
            libqt5network5 \
            qtbase5-dev
    elif [[ "$RENDER_BACKEND" == "webengine" ]]; then
        print_info "Installing Qt WebEngine (modern CSS support)..."
        sudo apt-get install -y \
            qt5-qmake \
            qtwebengine5-dev \
            libqt5webenginewidgets5 \
            libqt5svg5-dev \
            libqt5xmlpatterns5-dev \
            libqt5network5 \
            qtbase5-dev \
            libqt5printsupport5
    else  # both
        print_info "Installing both Qt WebKit and WebEngine..."
        sudo apt-get install -y \
            qt5-qmake \
            libqt5webkit5-dev \
            qtwebengine5-dev \
            libqt5webenginewidgets5 \
            libqt5svg5-dev \
            libqt5xmlpatterns5-dev \
            libqt5network5 \
            qtbase5-dev \
            libqt5printsupport5
    fi

    print_success "Dependencies installed"
}

# macOS installation
install_macos() {
    print_header "Installing on macOS"

    # Check if Homebrew is installed
    if ! command_exists brew; then
        print_error "Homebrew is not installed!"
        echo ""
        echo "Please install Homebrew first:"
        echo "  /bin/bash -c \"\$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)\""
        exit 1
    fi

    print_info "Updating Homebrew..."
    brew update

    print_info "Installing build tools..."
    brew install git cmake pkg-config

    print_info "Installing Qt..."

    # On macOS, Qt WebKit is not available in modern Qt versions
    # Force WebEngine backend
    if [[ "$RENDER_BACKEND" == "webkit" ]] || [[ "$RENDER_BACKEND" == "both" ]]; then
        print_warning "Qt WebKit is not available on macOS with modern Qt."
        print_warning "Switching to WebEngine backend (modern CSS support)."
        RENDER_BACKEND="webengine"
    fi

    print_info "Installing Qt 5 with WebEngine..."
    if brew list qt@5 &>/dev/null; then
        print_info "Qt@5 already installed, upgrading..."
        brew upgrade qt@5 || true
    else
        brew install qt@5
    fi

    # Detect Qt path (Intel vs Apple Silicon)
    if [ -d "/opt/homebrew/opt/qt@5" ]; then
        QT_PATH="/opt/homebrew/opt/qt@5"
    elif [ -d "/usr/local/opt/qt@5" ]; then
        QT_PATH="/usr/local/opt/qt@5"
    else
        print_error "Qt installation not found"
        exit 1
    fi

    # Add Qt to PATH
    export PATH="$QT_PATH/bin:$PATH"
    export LDFLAGS="-L$QT_PATH/lib"
    export CPPFLAGS="-I$QT_PATH/include"
    export PKG_CONFIG_PATH="$QT_PATH/lib/pkgconfig"

    print_success "Dependencies installed"
    print_info "Qt path: $QT_PATH"
}

# Build the project
build_project() {
    print_header "Building wkhtmltopdf"

    print_info "Render backend: $RENDER_BACKEND"
    print_info "Install prefix: $INSTALL_PREFIX"

    # Clean previous build
    if [ -d "bin" ]; then
        print_info "Cleaning previous build..."
        rm -rf bin
    fi

    # Run qmake
    print_info "Running qmake..."
    export RENDER_BACKEND=$RENDER_BACKEND

    if [[ "$OS" == "macos" ]]; then
        # Detect Qt path on macOS (handle both Intel and Apple Silicon)
        if [ -d "/opt/homebrew/opt/qt@5" ]; then
            QT_PATH="/opt/homebrew/opt/qt@5"
        elif [ -d "/usr/local/opt/qt@5" ]; then
            QT_PATH="/usr/local/opt/qt@5"
        else
            print_error "Qt not found. Please install with: brew install qt@5"
            exit 1
        fi
        export PATH="$QT_PATH/bin:$PATH"
        $QT_PATH/bin/qmake INSTALLBASE=$INSTALL_PREFIX
    else
        qmake INSTALLBASE=$INSTALL_PREFIX
    fi

    # Build
    print_info "Compiling (this may take a while)..."
    make -j$(nproc 2>/dev/null || sysctl -n hw.ncpu 2>/dev/null || echo 2)

    print_success "Build completed successfully"
}

# Install the binaries
install_binaries() {
    print_header "Installing wkhtmltopdf"

    print_info "Installing to $INSTALL_PREFIX..."
    sudo make install

    print_success "Installation completed"

    # Verify installation
    if command_exists wkhtmltopdf; then
        print_success "wkhtmltopdf is now available in your PATH"
        echo ""
        wkhtmltopdf --version
    else
        print_warning "wkhtmltopdf was installed but is not in your PATH"
        print_info "You may need to add $INSTALL_PREFIX/bin to your PATH"
    fi
}

# Test installation
test_installation() {
    print_header "Testing Installation"

    if ! command_exists wkhtmltopdf; then
        print_error "wkhtmltopdf command not found"
        return 1
    fi

    # Check which backends are available
    print_info "Checking available rendering backends..."

    cd examples

    # Test with simple HTML
    echo "<html><body><h1>Test</h1></body></html>" > test.html

    if wkhtmltopdf --help | grep -q "render-backend"; then
        print_success "Multi-backend support detected"

        # Test WebKit if available
        if wkhtmltopdf --render-backend webkit test.html test-webkit.pdf 2>/dev/null; then
            print_success "WebKit backend is working"
            rm -f test-webkit.pdf
        fi

        # Test WebEngine if available
        if wkhtmltopdf --render-backend webengine test.html test-webengine.pdf 2>/dev/null; then
            print_success "WebEngine backend is working (modern CSS supported!)"
            rm -f test-webengine.pdf
        fi
    else
        # Test basic functionality
        if wkhtmltopdf test.html test.pdf 2>/dev/null; then
            print_success "wkhtmltopdf is working"
            rm -f test.pdf
        else
            print_error "wkhtmltopdf test failed"
        fi
    fi

    rm -f test.html
    cd ..
}

# Print usage
usage() {
    cat << EOF
Usage: ./install.sh [OPTIONS]

Install wkhtmltopdf with modern CSS support

OPTIONS:
    -h, --help              Show this help message
    -b, --backend BACKEND   Rendering backend: webkit, webengine, or both (default: both)
    -p, --prefix PREFIX     Installation prefix (default: /usr/local)
    -t, --test-only         Only run tests, don't install
    --no-install            Build but don't install
    --clean                 Clean build directory before building

EXAMPLES:
    # Install with both backends (recommended)
    ./install.sh

    # Install with WebEngine only (modern CSS)
    ./install.sh --backend webengine

    # Install to custom location
    ./install.sh --prefix /opt/wkhtmltopdf

    # Build without installing
    ./install.sh --no-install

ENVIRONMENT VARIABLES:
    RENDER_BACKEND          Same as --backend option
    INSTALL_PREFIX          Same as --prefix option

BACKENDS:
    webkit      - Legacy Qt WebKit (smaller binary, limited CSS)
    webengine   - Modern Qt WebEngine (larger binary, full CSS3: flex, grid, etc.)
    both        - Include both backends, selectable at runtime (recommended)

EOF
}

# Main installation flow
main() {
    local DO_INSTALL=true
    local DO_BUILD=true
    local DO_TEST=true
    local CLEAN_BUILD=false

    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            -h|--help)
                usage
                exit 0
                ;;
            -b|--backend)
                RENDER_BACKEND="$2"
                shift 2
                ;;
            -p|--prefix)
                INSTALL_PREFIX="$2"
                shift 2
                ;;
            -t|--test-only)
                DO_BUILD=false
                DO_INSTALL=false
                shift
                ;;
            --no-install)
                DO_INSTALL=false
                shift
                ;;
            --clean)
                CLEAN_BUILD=true
                shift
                ;;
            *)
                print_error "Unknown option: $1"
                usage
                exit 1
                ;;
        esac
    done

    # Validate backend
    if [[ "$RENDER_BACKEND" != "webkit" ]] && [[ "$RENDER_BACKEND" != "webengine" ]] && [[ "$RENDER_BACKEND" != "both" ]]; then
        print_error "Invalid backend: $RENDER_BACKEND"
        echo "Valid options: webkit, webengine, both"
        exit 1
    fi

    print_header "wkhtmltopdf Installation Script"
    echo ""

    # Detect OS
    detect_os
    print_info "Detected OS: $OS $OS_VERSION"
    print_info "Rendering backend: $RENDER_BACKEND"
    print_info "Install prefix: $INSTALL_PREFIX"
    echo ""

    # Install dependencies
    case $OS in
        ubuntu|debian)
            install_ubuntu
            ;;
        macos)
            install_macos
            ;;
        *)
            print_error "Unsupported operating system: $OS"
            echo ""
            echo "Supported systems:"
            echo "  - Ubuntu/Debian"
            echo "  - macOS (with Homebrew)"
            exit 1
            ;;
    esac

    echo ""

    # Clean if requested
    if [[ "$CLEAN_BUILD" == true ]]; then
        print_info "Cleaning build directory..."
        make clean 2>/dev/null || true
        rm -rf bin
    fi

    # Build
    if [[ "$DO_BUILD" == true ]]; then
        build_project
        echo ""
    fi

    # Install
    if [[ "$DO_INSTALL" == true ]]; then
        install_binaries
        echo ""
    fi

    # Test
    if [[ "$DO_TEST" == true ]]; then
        test_installation
        echo ""
    fi

    print_header "Installation Complete!"
    echo ""
    print_success "wkhtmltopdf has been successfully installed!"
    echo ""
    print_info "Quick start:"
    echo "  # Convert HTML to PDF with modern CSS support"
    echo "  wkhtmltopdf --render-backend webengine input.html output.pdf"
    echo ""
    echo "  # Or with legacy WebKit"
    echo "  wkhtmltopdf --render-backend webkit input.html output.pdf"
    echo ""
    print_info "Try the examples:"
    echo "  cd examples"
    echo "  make demo"
    echo ""
    print_info "Documentation:"
    echo "  See MULTI_BACKEND.md for detailed usage instructions"
    echo ""
}

# Run main
main "$@"
