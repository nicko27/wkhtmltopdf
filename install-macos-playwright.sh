#!/bin/bash
# Quick installation script for wkhtmltopdf Playwright wrapper on macOS
# Provides modern CSS support (flexbox, grid, etc.)

set -e

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${BLUE}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║  wkhtmltopdf (Playwright wrapper) for macOS               ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════════════════╝${NC}"
echo ""

# Check if Node.js is installed
if ! command -v node >/dev/null 2>&1; then
    echo -e "${YELLOW}⚠ Node.js is not installed${NC}"
    echo ""
    echo "Please install Node.js first:"
    echo "  brew install node"
    echo ""
    echo "Or download from: https://nodejs.org"
    exit 1
fi

NODE_VERSION=$(node --version)
echo -e "${GREEN}✓${NC} Node.js found: $NODE_VERSION"

# Check if npm is installed
if ! command -v npm >/dev/null 2>&1; then
    echo -e "${RED}✗ npm is not installed${NC}"
    exit 1
fi

NPM_VERSION=$(npm --version)
echo -e "${GREEN}✓${NC} npm found: $NPM_VERSION"
echo ""

# Navigate to playwright-wrapper directory
cd playwright-wrapper

# Install dependencies
echo -e "${BLUE}Installing Playwright and dependencies...${NC}"
echo "(This will download Chromium ~300MB on first install)"
echo ""

npm install

echo ""
echo -e "${GREEN}✓${NC} Installation complete!"
echo ""

# Make the script executable
chmod +x wkhtmltopdf.js

# Test the installation
echo -e "${BLUE}Testing installation...${NC}"
if node wkhtmltopdf.js --version >/dev/null 2>&1; then
    echo -e "${GREEN}✓${NC} wkhtmltopdf wrapper is working!"
else
    echo -e "${YELLOW}⚠${NC} Installation may have issues"
fi

echo ""
echo -e "${BLUE}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║  Installation Complete!                                    ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════════════════╝${NC}"
echo ""
echo "Usage:"
echo -e "  ${GREEN}cd playwright-wrapper${NC}"
echo -e "  ${GREEN}node wkhtmltopdf.js input.html output.pdf${NC}"
echo ""
echo "Or install globally:"
echo -e "  ${GREEN}npm install -g .${NC}"
echo -e "  ${GREEN}wkhtmltopdf input.html output.pdf${NC}"
echo ""
echo "Test with modern CSS demo:"
echo -e "  ${GREEN}node wkhtmltopdf.js ../examples/modern_css_demo.html test.pdf${NC}"
echo -e "  ${GREEN}open test.pdf${NC}"
echo ""
echo "Features:"
echo "  ✅ Full CSS3 support (flexbox, grid, transforms)"
echo "  ✅ Modern JavaScript (ES6+)"
echo "  ✅ Same CLI as original wkhtmltopdf"
echo ""
echo "Documentation:"
echo "  cat playwright-wrapper/README.md"
echo ""
