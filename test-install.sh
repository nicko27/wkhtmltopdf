#!/bin/bash
# Test script to validate wkhtmltopdf installation
# Tests both WebKit and WebEngine backends if available

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

PASSED=0
FAILED=0
SKIPPED=0

print_test() {
    echo -e "${BLUE}━━━ Test: $1${NC}"
}

print_pass() {
    echo -e "${GREEN}✓${NC} $1"
    PASSED=$((PASSED + 1))
}

print_fail() {
    echo -e "${RED}✗${NC} $1"
    FAILED=$((FAILED + 1))
}

print_skip() {
    echo -e "${YELLOW}⊘${NC} $1"
    SKIPPED=$((SKIPPED + 1))
}

echo -e "${BLUE}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║  wkhtmltopdf Installation Test Suite                      ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════════════════╝${NC}"
echo ""

# Test 1: Command exists
print_test "Checking if wkhtmltopdf command exists"
if command -v wkhtmltopdf >/dev/null 2>&1; then
    print_pass "wkhtmltopdf command found"
else
    print_fail "wkhtmltopdf command not found"
    echo "  Please check your PATH or installation"
    exit 1
fi
echo ""

# Test 2: Version info
print_test "Checking version information"
if VERSION=$(wkhtmltopdf --version 2>&1); then
    print_pass "Version: $(echo "$VERSION" | head -n1)"
else
    print_fail "Could not get version information"
fi
echo ""

# Test 3: Help output
print_test "Checking help output"
if wkhtmltopdf --help >/dev/null 2>&1; then
    print_pass "Help output works"
else
    print_fail "Help output failed"
fi
echo ""

# Test 4: Check for multi-backend support
print_test "Checking for multi-backend support"
if wkhtmltopdf --help 2>&1 | grep -q "render-backend"; then
    print_pass "Multi-backend support detected"
    HAS_MULTI_BACKEND=true
else
    print_skip "Single backend build (older version)"
    HAS_MULTI_BACKEND=false
fi
echo ""

# Create test directory
TEST_DIR=$(mktemp -d)
cd "$TEST_DIR"

# Create simple test HTML
cat > simple.html << 'EOF'
<!DOCTYPE html>
<html>
<head>
    <title>Simple Test</title>
</head>
<body>
    <h1>Hello World</h1>
    <p>This is a simple test document.</p>
</body>
</html>
EOF

# Create modern CSS test HTML
cat > modern.html << 'EOF'
<!DOCTYPE html>
<html>
<head>
    <title>Modern CSS Test</title>
    <style>
        .flex-container {
            display: flex;
            justify-content: space-between;
            gap: 20px;
        }
        .flex-item {
            flex: 1;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            color: white;
            padding: 20px;
            border-radius: 10px;
        }
        .grid-container {
            display: grid;
            grid-template-columns: repeat(3, 1fr);
            gap: 10px;
            margin-top: 20px;
        }
        .grid-item {
            background: #f0f0f0;
            padding: 15px;
            text-align: center;
        }
    </style>
</head>
<body>
    <h1>Modern CSS Features</h1>

    <h2>Flexbox</h2>
    <div class="flex-container">
        <div class="flex-item">Item 1</div>
        <div class="flex-item">Item 2</div>
        <div class="flex-item">Item 3</div>
    </div>

    <h2>Grid</h2>
    <div class="grid-container">
        <div class="grid-item">Grid 1</div>
        <div class="grid-item">Grid 2</div>
        <div class="grid-item">Grid 3</div>
        <div class="grid-item">Grid 4</div>
        <div class="grid-item">Grid 5</div>
        <div class="grid-item">Grid 6</div>
    </div>
</body>
</html>
EOF

# Test 5: Basic conversion
print_test "Testing basic HTML to PDF conversion"
if wkhtmltopdf simple.html simple.pdf 2>/dev/null; then
    if [ -f simple.pdf ] && [ -s simple.pdf ]; then
        print_pass "Basic conversion successful ($(du -h simple.pdf | cut -f1))"
    else
        print_fail "PDF created but is empty or invalid"
    fi
else
    print_fail "Basic conversion failed"
fi
echo ""

# Test 6: WebKit backend (if available)
if [ "$HAS_MULTI_BACKEND" = true ]; then
    print_test "Testing WebKit backend"
    if wkhtmltopdf --render-backend webkit simple.html webkit.pdf 2>/dev/null; then
        if [ -f webkit.pdf ] && [ -s webkit.pdf ]; then
            print_pass "WebKit backend works ($(du -h webkit.pdf | cut -f1))"
        else
            print_fail "WebKit backend created empty PDF"
        fi
    else
        print_skip "WebKit backend not available"
    fi
    echo ""
fi

# Test 7: WebEngine backend (if available)
if [ "$HAS_MULTI_BACKEND" = true ]; then
    print_test "Testing WebEngine backend"
    if wkhtmltopdf --render-backend webengine simple.html webengine.pdf 2>/dev/null; then
        if [ -f webengine.pdf ] && [ -s webengine.pdf ]; then
            print_pass "WebEngine backend works ($(du -h webengine.pdf | cut -f1))"
        else
            print_fail "WebEngine backend created empty PDF"
        fi
    else
        print_skip "WebEngine backend not available"
    fi
    echo ""
fi

# Test 8: Modern CSS with WebEngine
if [ "$HAS_MULTI_BACKEND" = true ]; then
    print_test "Testing modern CSS (flexbox, grid) with WebEngine"
    if wkhtmltopdf --render-backend webengine modern.html modern-webengine.pdf 2>/dev/null; then
        if [ -f modern-webengine.pdf ] && [ -s modern-webengine.pdf ]; then
            print_pass "Modern CSS conversion successful ($(du -h modern-webengine.pdf | cut -f1))"
            echo "  Note: Manually verify that flexbox and grid are rendered correctly"
        else
            print_fail "Modern CSS conversion created empty PDF"
        fi
    else
        print_skip "WebEngine not available for modern CSS test"
    fi
    echo ""
fi

# Test 9: Test various options
print_test "Testing common command-line options"
OPTIONS_PASSED=true

# Page size
if wkhtmltopdf --page-size A4 simple.html test-a4.pdf 2>/dev/null; then
    print_pass "  --page-size option works"
else
    print_fail "  --page-size option failed"
    OPTIONS_PASSED=false
fi

# Margins
if wkhtmltopdf --margin-top 10mm --margin-bottom 10mm simple.html test-margins.pdf 2>/dev/null; then
    print_pass "  --margin options work"
else
    print_fail "  --margin options failed"
    OPTIONS_PASSED=false
fi

# Orientation
if wkhtmltopdf --orientation Landscape simple.html test-landscape.pdf 2>/dev/null; then
    print_pass "  --orientation option works"
else
    print_fail "  --orientation option failed"
    OPTIONS_PASSED=false
fi

if [ "$OPTIONS_PASSED" = true ]; then
    PASSED=$((PASSED + 1))
else
    FAILED=$((FAILED + 1))
fi
echo ""

# Test 10: Library files
print_test "Checking library installation"
LIB_FOUND=false

for LIB_PATH in /usr/local/lib /usr/lib /opt/homebrew/lib /usr/local/opt/qt@5/lib; do
    if [ -f "$LIB_PATH/libwkhtmltox.so" ] || [ -f "$LIB_PATH/libwkhtmltox.dylib" ] || [ -f "$LIB_PATH/libwkhtmltox.a" ]; then
        print_pass "Library found in $LIB_PATH"
        LIB_FOUND=true
        break
    fi
done

if [ "$LIB_FOUND" = false ]; then
    print_skip "Library not found in standard locations (may be statically linked)"
fi
echo ""

# Test 11: Header files
print_test "Checking header files installation"
if [ -d "/usr/local/include/wkhtmltox" ]; then
    HEADER_COUNT=$(ls /usr/local/include/wkhtmltox/*.h 2>/dev/null | wc -l)
    if [ "$HEADER_COUNT" -gt 0 ]; then
        print_pass "Found $HEADER_COUNT header files in /usr/local/include/wkhtmltox"
    else
        print_fail "Header directory exists but is empty"
    fi
else
    print_skip "Headers not installed in /usr/local/include/wkhtmltox"
fi
echo ""

# Cleanup
cd - >/dev/null
rm -rf "$TEST_DIR"

# Summary
echo -e "${BLUE}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║  Test Summary                                              ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "${GREEN}Passed:${NC}  $PASSED"
echo -e "${RED}Failed:${NC}  $FAILED"
echo -e "${YELLOW}Skipped:${NC} $SKIPPED"
echo ""

if [ $FAILED -eq 0 ]; then
    echo -e "${GREEN}✓ All tests passed!${NC}"
    echo ""
    echo "wkhtmltopdf is properly installed and working."
    echo ""
    echo "Next steps:"
    echo "  • Try the examples: cd examples && make demo"
    echo "  • Read the docs: cat MULTI_BACKEND.md"
    echo "  • Test your own HTML: wkhtmltopdf myfile.html output.pdf"
    echo ""
    exit 0
else
    echo -e "${RED}✗ Some tests failed${NC}"
    echo ""
    echo "Please check the installation and try again."
    echo "For help, see: INSTALL.md"
    echo ""
    exit 1
fi
