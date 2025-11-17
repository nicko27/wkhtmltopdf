#!/bin/bash
# Check build configuration without compiling

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}=== wkhtmltopdf Build Configuration Check ===${NC}\n"

# Detect Ubuntu version
if [ -f /etc/lsb-release ]; then
    . /etc/lsb-release
    UBUNTU_VERSION=$DISTRIB_RELEASE
else
    echo "❌ Cannot detect Ubuntu version"
    exit 1
fi

echo -e "${GREEN}✓ Ubuntu Version:${NC} $UBUNTU_VERSION ($DISTRIB_CODENAME)"

# Determine configuration
if [[ "$UBUNTU_VERSION" == "22.04" ]]; then
    QT_VERSION="Qt5"
    PACKAGE_NAME="wkhtmltopdf-qt5-webengine"
    QMAKE_CMD="qmake"
    DEPS="qtbase5-dev qt5-qmake qtwebengine5-dev libqt5webenginewidgets5 libqt5webenginecore5 libqt5svg5-dev libqt5xmlpatterns5-dev libqt5positioning5"
elif [[ "$UBUNTU_VERSION" == "24.04" ]]; then
    QT_VERSION="Qt6"
    PACKAGE_NAME="wkhtmltopdf-qt6"
    QMAKE_CMD="qmake6"
    DEPS="qt6-webengine-dev qt6-base-dev libqt6webenginewidgets6 libqt6webenginecore6 libqt6svg6-dev"
else
    echo -e "❌ Unsupported Ubuntu version: $UBUNTU_VERSION"
    exit 1
fi

echo -e "${GREEN}✓ Qt Version:${NC} $QT_VERSION WebEngine"
echo -e "${GREEN}✓ Package Name:${NC} $PACKAGE_NAME"
echo -e "${GREEN}✓ QMake Command:${NC} $QMAKE_CMD"
echo -e "${GREEN}✓ Backend:${NC} WebEngine only (WebKit abandoned)"

# Check qmake
echo -e "\n${BLUE}=== Checking Build Tools ===${NC}\n"

if command -v $QMAKE_CMD &> /dev/null; then
    echo -e "${GREEN}✓ $QMAKE_CMD found:${NC} $(command -v $QMAKE_CMD)"
    $QMAKE_CMD --version 2>&1 | head -2
else
    echo -e "${YELLOW}⚠ $QMAKE_CMD not found${NC}"
    echo "  Install: sudo apt-get install qt6-base-dev"
fi

# Check gcc
if command -v gcc &> /dev/null; then
    echo -e "${GREEN}✓ gcc found:${NC} $(gcc --version | head -1)"
else
    echo -e "${YELLOW}⚠ gcc not found${NC}"
fi

# Check make
if command -v make &> /dev/null; then
    echo -e "${GREEN}✓ make found:${NC} $(make --version | head -1)"
else
    echo -e "${YELLOW}⚠ make not found${NC}"
fi

# Check dpkg-deb
if command -v dpkg-deb &> /dev/null; then
    echo -e "${GREEN}✓ dpkg-deb found${NC}"
else
    echo -e "${YELLOW}⚠ dpkg-deb not found${NC}"
fi

# Check Qt packages
echo -e "\n${BLUE}=== Checking Qt Packages ===${NC}\n"

check_pkg() {
    if dpkg -l "$1" 2>/dev/null | grep -q "^ii"; then
        echo -e "${GREEN}✓${NC} $1"
        return 0
    else
        echo -e "${YELLOW}⚠${NC} $1 (not installed)"
        return 1
    fi
}

MISSING_COUNT=0
for pkg in $DEPS; do
    if ! check_pkg "$pkg"; then
        ((MISSING_COUNT++))
    fi
done

# Summary
echo -e "\n${BLUE}=== Summary ===${NC}\n"
echo "Ubuntu Version: $UBUNTU_VERSION"
echo "Target Qt: $QT_VERSION"
echo "Package: $PACKAGE_NAME"
echo "Backend: WebEngine only"
echo "Architecture: $(dpkg --print-architecture)"

if [ $MISSING_COUNT -eq 0 ]; then
    echo -e "\n${GREEN}✓ All dependencies installed! Ready to build.${NC}"
    echo -e "\nRun: ${GREEN}./build-deb.sh${NC}"
else
    echo -e "\n${YELLOW}⚠ Missing $MISSING_COUNT package(s)${NC}"
    echo -e "\nInstall dependencies:"
    echo -e "${GREEN}sudo apt-get update && sudo apt-get install -y $DEPS build-essential${NC}"
fi

# Show expected output
echo -e "\n${BLUE}=== Expected Output ===${NC}\n"
echo "Package file: ${PACKAGE_NAME}_0.13.0-${UBUNTU_VERSION}_$(dpkg --print-architecture).deb"
echo "Install path: /usr/local/bin/wkhtmltopdf"
echo "Binary size: ~1-2 MB (depends on Qt version)"
