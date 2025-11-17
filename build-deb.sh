#!/bin/bash
# Build wkhtmltopdf .deb package with auto-detection
# Qt5 WebEngine for Ubuntu 22.04 (with libwkhtmltox fixes)
# Qt6 WebEngine for Ubuntu 24.04

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

echo_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

echo_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

echo_step() {
    echo -e "${BLUE}[STEP]${NC} $1"
}

# Detect Ubuntu version
if [ -f /etc/lsb-release ]; then
    . /etc/lsb-release
    UBUNTU_VERSION=$DISTRIB_RELEASE
else
    echo_error "Cannot detect Ubuntu version. /etc/lsb-release not found."
    exit 1
fi

echo_info "Detected Ubuntu $UBUNTU_VERSION"

# Determine Qt version and dependencies
if [[ "$UBUNTU_VERSION" == "22.04" ]]; then
    QT_VERSION="qt5"
    QT_MAJOR="5"
    PACKAGE_NAME="wkhtmltopdf-qt5-webengine"
    # Ubuntu 22.04 specific dependencies (note: qt5-default is deprecated but still works)
    DEPS="qtbase5-dev qt5-qmake qtwebengine5-dev libqt5webenginewidgets5 libqt5webenginecore5 libqt5svg5-dev libqt5xmlpatterns5-dev libqt5network5 libqt5printsupport5 libqt5positioning5 libqt5core5a libqt5gui5 build-essential"
    QMAKE_CMD="qmake"

    # Additional system dependencies for Ubuntu 22.04 (fixes libwkhtmltox issues)
    SYS_DEPS="libssl3 libssl-dev libfontconfig1 libfreetype6 libx11-6 libxrender1 libxext6 libnss3 libxcomposite1 libxcursor1 libxdamage1 libxi6 libxtst6 libc6"

elif [[ "$UBUNTU_VERSION" == "24.04" ]]; then
    QT_VERSION="qt6"
    QT_MAJOR="6"
    PACKAGE_NAME="wkhtmltopdf-qt6"
    DEPS="qt6-webengine-dev qt6-base-dev libqt6webenginewidgets6 libqt6webenginecore6 libqt6svg6-dev libqt6network6 libqt6printsupport6 build-essential"
    QMAKE_CMD="qmake6"
    SYS_DEPS="libssl3 libfontconfig1 libfreetype6 libx11-6 libxrender1 libxext6 libc6 libnss3 libxcomposite1 libxcursor1 libxdamage1 libxi6 libxtst6"
else
    echo_error "Unsupported Ubuntu version: $UBUNTU_VERSION"
    echo_error "Supported versions: 22.04 (Qt5), 24.04 (Qt6)"
    exit 1
fi

echo_info "Using $QT_VERSION WebEngine backend only"
if [[ "$UBUNTU_VERSION" == "22.04" ]]; then
    echo_warn "Ubuntu 22.04 detected - will apply libwkhtmltox.so.0 fixes"
fi

# Check if we need to install dependencies
install_deps() {
    echo_step "Installing build dependencies..."
    sudo apt-get update

    echo_info "Installing Qt dependencies..."
    sudo apt-get install -y $DEPS

    echo_info "Installing system dependencies..."
    sudo apt-get install -y $SYS_DEPS

    echo_info "Dependencies installed successfully"
}

# Check for conflicting packages from other Ubuntu versions
check_conflicts() {
    echo_step "Checking for conflicting packages..."

    CONFLICTING_PKGS=$(dpkg -l | grep "^ii  wkhtmltopdf" | grep -v "ubuntu${UBUNTU_VERSION}" | awk '{print $2}' || true)

    if [ -n "$CONFLICTING_PKGS" ]; then
        echo_warn "Found packages built for other Ubuntu versions:"
        echo "$CONFLICTING_PKGS" | sed 's/^/  - /'
        echo ""
        read -p "Remove these packages? (recommended) (y/n) " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            echo "$CONFLICTING_PKGS" | while read pkg; do
                echo_info "Removing $pkg..."
                sudo dpkg -r "$pkg" 2>/dev/null || true
            done
        fi
    fi
}

# Ask user if they want to install dependencies
echo ""
read -p "Install/update build dependencies? (y/n) " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    install_deps
    check_conflicts
else
    echo_warn "Skipping dependency installation. Build may fail if dependencies are missing."
fi

# Clean previous builds
echo_step "Cleaning previous builds..."
make clean 2>/dev/null || true
make distclean 2>/dev/null || true
rm -rf build-temp
rm -f *.deb

# Create build directory
mkdir -p build-temp
cd build-temp

# Set build environment
export RENDER_BACKEND=webengine
export QT_SELECT=$QT_MAJOR

echo_step "Configuring build with $QMAKE_CMD..."
$QMAKE_CMD ../wkhtmltopdf.pro \
    RENDER_BACKEND=webengine \
    CONFIG+=release

# Build
echo_step "Compiling (this may take several minutes)..."
make -j$(nproc)

# Check if binaries were created
if [ ! -f "bin/wkhtmltopdf" ] && [ ! -f "src/pdf/wkhtmltopdf" ]; then
    echo_error "Build failed: wkhtmltopdf binary not found"
    exit 1
fi

# Find the binary location
if [ -f "bin/wkhtmltopdf" ]; then
    BINARY_PATH="bin/wkhtmltopdf"
    IMAGE_BINARY="bin/wkhtmltoimage"
    LIB_PATH="lib/libwkhtmltox.so"
elif [ -f "src/pdf/wkhtmltopdf" ]; then
    BINARY_PATH="src/pdf/wkhtmltopdf"
    IMAGE_BINARY="src/image/wkhtmltoimage"
    LIB_PATH="src/lib/libwkhtmltox.so"
else
    echo_error "Cannot find compiled binary"
    exit 1
fi

echo_info "Binary found at: $BINARY_PATH"

# Check for shared library
if [ -f "$LIB_PATH" ]; then
    echo_info "Shared library found at: $LIB_PATH"
    HAS_SHARED_LIB=1
else
    echo_warn "No shared library found - binaries may be statically linked"
    HAS_SHARED_LIB=0
fi

# Determine architecture
ARCH=$(dpkg --print-architecture)

# Create debian package structure
DEB_DIR="../${PACKAGE_NAME}_0.13.0-${UBUNTU_VERSION}_${ARCH}"
rm -rf "$DEB_DIR"
mkdir -p "$DEB_DIR/DEBIAN"
mkdir -p "$DEB_DIR/usr/local/bin"
mkdir -p "$DEB_DIR/usr/local/lib"
mkdir -p "$DEB_DIR/usr/share/doc/$PACKAGE_NAME"

# Copy binaries
echo_step "Creating package structure..."
echo_info "Copying binaries..."
cp "$BINARY_PATH" "$DEB_DIR/usr/local/bin/wkhtmltopdf"
if [ -f "$IMAGE_BINARY" ]; then
    cp "$IMAGE_BINARY" "$DEB_DIR/usr/local/bin/wkhtmltoimage"
fi

chmod +x "$DEB_DIR/usr/local/bin/"*

# Copy shared library if it exists (critical for Ubuntu 22.04)
if [ $HAS_SHARED_LIB -eq 1 ]; then
    echo_info "Copying shared library..."
    cp "$LIB_PATH" "$DEB_DIR/usr/local/lib/libwkhtmltox.so.0.13.0"

    # Create symlinks
    cd "$DEB_DIR/usr/local/lib"
    ln -sf libwkhtmltox.so.0.13.0 libwkhtmltox.so.0
    ln -sf libwkhtmltox.so.0 libwkhtmltox.so
    cd - > /dev/null
fi

# Copy copyright
if [ -f "../copyright" ]; then
    cp ../copyright "$DEB_DIR/usr/share/doc/$PACKAGE_NAME/"
fi

# Create control file
echo_info "Creating control file..."
cat > "$DEB_DIR/DEBIAN/control" << EOF
Package: $PACKAGE_NAME
Version: 0.13.0-${UBUNTU_VERSION}
Section: utils
Priority: optional
Architecture: $ARCH
Maintainer: wkhtmltopdf Team <support@wkhtmltopdf.org>
Homepage: https://wkhtmltopdf.org
EOF

# Add dependencies based on Qt version
if [[ "$QT_VERSION" == "qt5" ]]; then
    cat >> "$DEB_DIR/DEBIAN/control" << EOF
Depends: libqt5core5a, libqt5gui5, libqt5network5, libqt5svg5, libqt5xmlpatterns5, libqt5webenginecore5, libqt5webenginewidgets5, libqt5printsupport5, libqt5positioning5, libssl3 | libssl1.1, libfontconfig1, libfreetype6, libx11-6, libxrender1, libxext6, libc6, libnss3, libxcomposite1, libxcursor1, libxdamage1, libxi6, libxtst6
Recommends: qtwebengine5-dev
EOF
else
    cat >> "$DEB_DIR/DEBIAN/control" << EOF
Depends: libqt6core6, libqt6gui6, libqt6network6, libqt6svg6, libqt6webenginecore6, libqt6webenginewidgets6, libqt6printsupport6, libssl3, libfontconfig1, libfreetype6, libx11-6, libxrender1, libxext6, libc6, libnss3, libxcomposite1, libxcursor1, libxdamage1, libxi6, libxtst6
Recommends: qt6-webengine-dev
EOF
fi

cat >> "$DEB_DIR/DEBIAN/control" << EOF
Conflicts: wkhtmltopdf-webkit, wkhtmltopdf
Provides: wkhtmltopdf
Description: HTML to PDF converter with $QT_VERSION WebEngine
 wkhtmltopdf with Chromium rendering engine and modern CSS support.
 Built for Ubuntu $UBUNTU_VERSION using $QT_VERSION WebEngine backend.
 .
 This build includes fixes for Ubuntu $UBUNTU_VERSION:
  - Proper libwkhtmltox.so.0 library handling
  - Correct ldconfig configuration
  - All required Qt$QT_MAJOR dependencies
 .
 Features:
  - Modern CSS3 support via Chromium/Blink engine
  - JavaScript execution
  - SVG support
  - HTML5 support
EOF

# Calculate installed size
INSTALLED_SIZE=$(du -sk "$DEB_DIR" | cut -f1)
echo "Installed-Size: $INSTALLED_SIZE" >> "$DEB_DIR/DEBIAN/control"

# Create postinst script (CRITICAL for Ubuntu 22.04 libwkhtmltox fix)
cat > "$DEB_DIR/DEBIAN/postinst" << 'POSTINST_EOF'
#!/bin/bash
set -e

echo "Configuring wkhtmltopdf..."

# Update alternatives for wkhtmltopdf
if [ -f /usr/local/bin/wkhtmltopdf ]; then
    update-alternatives --install /usr/bin/wkhtmltopdf wkhtmltopdf /usr/local/bin/wkhtmltopdf 100 || true
fi

if [ -f /usr/local/bin/wkhtmltoimage ]; then
    update-alternatives --install /usr/bin/wkhtmltoimage wkhtmltoimage /usr/local/bin/wkhtmltoimage 100 || true
fi

# CRITICAL FIX for Ubuntu 22.04: Configure ldconfig for libwkhtmltox.so.0
if [ -f /usr/local/lib/libwkhtmltox.so.0 ]; then
    echo "Configuring libwkhtmltox.so.0 for ldconfig..."

    # Create ldconfig configuration file
    echo "/usr/local/lib" > /etc/ld.so.conf.d/wkhtmltopdf.conf

    # Update ldconfig cache
    ldconfig

    # Verify the library is in cache
    if ldconfig -p | grep -q "libwkhtmltox"; then
        echo "✓ libwkhtmltox.so.0 successfully registered in ldconfig"
    else
        echo "⚠ Warning: libwkhtmltox.so.0 not found in ldconfig cache"
        echo "  Run: sudo ldconfig"
    fi
fi

echo ""
echo "=========================================="
echo "✓ wkhtmltopdf installed successfully!"
echo "=========================================="
echo ""
echo "Verification:"
wkhtmltopdf --version 2>&1 || {
    echo "⚠ Error running wkhtmltopdf"
    echo "Run diagnostics: ./diagnose-ubuntu2204.sh"
    exit 1
}

echo ""
echo "Usage examples:"
echo "  wkhtmltopdf https://example.com output.pdf"
echo "  echo '<h1>Test</h1>' | wkhtmltopdf - test.pdf"
echo ""

exit 0
POSTINST_EOF

chmod +x "$DEB_DIR/DEBIAN/postinst"

# Create postrm script
cat > "$DEB_DIR/DEBIAN/postrm" << 'POSTRM_EOF'
#!/bin/bash
set -e

# Remove alternatives
update-alternatives --remove wkhtmltopdf /usr/local/bin/wkhtmltopdf 2>/dev/null || true
update-alternatives --remove wkhtmltoimage /usr/local/bin/wkhtmltoimage 2>/dev/null || true

# Remove ldconfig configuration
if [ -f /etc/ld.so.conf.d/wkhtmltopdf.conf ]; then
    rm -f /etc/ld.so.conf.d/wkhtmltopdf.conf
    ldconfig
fi

echo "wkhtmltopdf removed"

exit 0
POSTRM_EOF

chmod +x "$DEB_DIR/DEBIAN/postrm"

# Build the .deb package
echo_step "Building .deb package..."
cd ..
dpkg-deb --build "${PACKAGE_NAME}_0.13.0-${UBUNTU_VERSION}_${ARCH}"

DEB_FILE="${PACKAGE_NAME}_0.13.0-${UBUNTU_VERSION}_${ARCH}.deb"

if [ -f "$DEB_FILE" ]; then
    echo ""
    echo "=========================================="
    echo_info "✓ Package created successfully!"
    echo "=========================================="
    echo ""
    echo "Package: $DEB_FILE"
    echo "Size: $(du -h "$DEB_FILE" | cut -f1)"
    echo ""
    dpkg-deb --info "$DEB_FILE" | grep -E "Package:|Version:|Architecture:|Depends:"
    echo ""

    if [[ "$UBUNTU_VERSION" == "22.04" ]]; then
        echo_info "Ubuntu 22.04 specific notes:"
        echo "  - This package includes libwkhtmltox.so.0 fixes"
        echo "  - ldconfig will be automatically configured on install"
        echo "  - All Qt5 WebEngine dependencies are included"
        echo ""
    fi

    echo "To install:"
    echo "  sudo apt install ./$DEB_FILE"
    echo ""
    echo "After install, verify with:"
    echo "  wkhtmltopdf --version"
    echo "  ldconfig -p | grep libwkhtmltox  # Should show library"
    echo ""
else
    echo_error "Failed to create .deb package"
    exit 1
fi

# Cleanup
echo ""
read -p "Remove build directory? (y/n) " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    rm -rf build-temp "${PACKAGE_NAME}_0.13.0-${UBUNTU_VERSION}_${ARCH}"
    echo_info "Build directory cleaned"
fi

echo ""
echo_info "Build complete!"
