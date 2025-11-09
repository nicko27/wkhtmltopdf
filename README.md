# wkhtmltopdf - Multi-Backend Edition

**Modern CSS Support • Multi-Backend Architecture • Production Ready**

[![License: LGPL v3](https://img.shields.io/badge/License-LGPL%20v3-blue.svg)](https://www.gnu.org/licenses/lgpl-3.0)
[![Version](https://img.shields.io/badge/version-0.13.0-green.svg)](VERSION)

## What is this?

This is an **enhanced fork** of [wkhtmltopdf](https://github.com/wkhtmltopdf/wkhtmltopdf) with **multi-backend support**, enabling modern CSS3 features (Flexbox, Grid, Transforms, etc.) while maintaining backward compatibility with the original WebKit-based rendering.

### Key Improvements over Original

| Feature | Original wkhtmltopdf | This Fork |
|---------|---------------------|-----------|
| CSS Flexbox | ❌ No | ✅ Yes (via WebEngine) |
| CSS Grid | ❌ No | ✅ Yes (via WebEngine) |
| Modern CSS3 | ❌ Limited (2012-era) | ✅ Full Chromium support |
| Backend Selection | Fixed (WebKit only) | ✅ Runtime switchable |
| Qt Version | Qt 4.8 / Qt 5 WebKit | ✅ Qt 5/6 WebKit + WebEngine |
| HTML/CSS Validation | ❌ No | ✅ Yes (with suggestions) |
| Error Handling | Basic | ✅ Structured with codes |
| Build Automation | Manual | ✅ Automated scripts |
| Debian Packages | Single variant | ✅ Multiple variants |
| macOS Support | Limited | ✅ Enhanced + Playwright fallback |

## Quick Start

### Installation (Ubuntu/Debian)

```bash
# One-line installation with all dependencies
curl -fsSL https://raw.githubusercontent.com/YOUR_USERNAME/wkhtmltopdf/master/install-ubuntu.sh | bash

# Or clone and install manually
git clone https://github.com/YOUR_USERNAME/wkhtmltopdf.git
cd wkhtmltopdf
chmod +x install-ubuntu.sh
./install-ubuntu.sh
```

### Installation (macOS)

```bash
# Install via Homebrew + build script
./install-macos.sh

# Or use Playwright wrapper (for modern CSS without compilation)
./install-macos-playwright.sh
```

### Basic Usage

```bash
# Use WebEngine backend for modern CSS
wkhtmltopdf --render-backend webengine input.html output.pdf

# Use WebKit backend (legacy, smaller binary)
wkhtmltopdf --render-backend webkit input.html output.pdf

# Auto-select best available backend
wkhtmltopdf input.html output.pdf
```

## Features

### 🎨 Modern CSS Support (via Qt WebEngine)

- **Flexbox layouts** - `display: flex`, `justify-content`, `align-items`, etc.
- **CSS Grid** - `display: grid`, `grid-template-columns`, `grid-areas`, etc.
- **CSS Transforms** - `rotate()`, `scale()`, `translate()`, `skew()`
- **Transitions & Animations** - `transition`, `@keyframes`, `animation`
- **Modern Gradients** - `linear-gradient()`, `radial-gradient()`, `conic-gradient()`
- **Custom Properties** - CSS variables (`--var-name`)
- **calc()** function
- **Advanced Selectors** - `:has()`, `:is()`, `:where()`, `:not()`
- **Modern JavaScript** - ES6+ support

### 🔧 Multi-Backend Architecture

**WebKit Backend** (Legacy)
- Smaller binary size (~20-30 MB)
- Faster startup time
- Lower memory usage
- CSS support circa 2012
- Best for: Simple documents, batch processing

**WebEngine Backend** (Modern - Chromium)
- Full CSS3 support
- Modern JavaScript (ES6+)
- Better web standards compliance
- Larger binary (~100-200 MB)
- Best for: Modern web content, complex layouts

### 🛠️ Enhanced Developer Experience

#### HTML/CSS Validator
```cpp
#include <wkhtmltox/validator.hh>

auto result = Validator::validateHTML(htmlContent);
if (result.hasWarnings()) {
    for (const auto& msg : result.messages) {
        std::cout << msg.message << ": " << msg.suggestion << std::endl;
    }
}

// Check CSS compatibility
auto cssResult = Validator::checkCSSCompatibility(cssContent, RenderBackend::WebKit);
// Returns warnings if flex/grid detected with WebKit backend
```

#### Structured Error Handling
```cpp
#include <wkhtmltox/errors.hh>

ConversionError err = ErrorHandler::fileNotFound("/path/to/file.html");
std::cout << err.formatForCLI() << std::endl;
// Output: [ERR_001] File not found: /path/to/file.html
//         Suggestion: Check that the file path is correct
```

#### Backend Selection API (C)
```c
#include <wkhtmltox/pdf.h>

// Check available backends
if (wkhtmltopdf_is_backend_available(1)) {  // 1 = WebEngine
    printf("WebEngine is available!\n");
}

// Set default backend
wkhtmltopdf_set_default_backend(1);  // Use WebEngine

// Get current backend
int backend = wkhtmltopdf_get_default_backend();
```

#### Backend Selection API (C++)
```cpp
#include <wkhtmltox/renderengine.hh>

// Get best available backend
auto backend = RenderEngineFactory::getBestAvailableBackend();

// Create page with specific backend
auto page = RenderPage::create(RenderBackend::WebEngine, webSettings);

// Check capabilities
QString caps = RenderEngineFactory::backendCapabilities(backend);
```

### 📦 Build Variants

This fork provides multiple pre-built Debian packages:

| Package Variant | Qt Version | Backend | Use Case |
|----------------|------------|---------|----------|
| `wkhtmltopdf-qt5-webkit` | Qt 5 | WebKit only | Legacy compatibility |
| `wkhtmltopdf-qt5-webengine` | Qt 5 | WebEngine only | Modern CSS |
| `wkhtmltopdf-qt6-webengine` | Qt 6 | WebEngine only | Latest Qt + Modern CSS |
| `wkhtmltopdf-both` | Qt 5/6 | Both backends | Maximum flexibility |

Build specific variant:
```bash
# Build WebEngine variant (modern CSS)
RENDER_BACKEND=webengine qmake && make

# Build WebKit variant (legacy)
RENDER_BACKEND=webkit qmake && make

# Build both (switchable at runtime)
RENDER_BACKEND=both qmake && make
```

### 🚀 Automation Scripts

**Installation Scripts**
- `install.sh` - Universal installer (auto-detects OS)
- `install-ubuntu.sh` - Ubuntu/Debian specific
- `install-macos.sh` - macOS with Homebrew
- `install-qt6-ubuntu.sh` - Qt 6 specific installation

**Build Scripts**
- `build-deb.sh` - Build single Debian package
- `build-deb-variants.sh` - Build all package variants
- `build-deb-all.sh` - Build for multiple Ubuntu versions
- `build-all-variants.sh` - Build all configurations
- `build-macos.sh` - macOS build script
- `rebuild.sh` - Quick rebuild during development

**Testing Scripts**
- `test-install.sh` - Validate installation
- `test-all-backends.sh` - Test all backend combinations
- `check-dependencies.sh` - Verify all dependencies

**Utility Scripts**
- `clean-for-git.sh` - Clean build artifacts before commit
- `install-fix.sh` - Fix common installation issues

### 🎭 Playwright Wrapper (macOS)

For macOS users who want modern CSS without compiling Qt WebEngine, we provide a Node.js wrapper using Playwright:

```bash
cd playwright-wrapper
npm install
./wkhtmltopdf.js input.html output.pdf
```

Features:
- Full Chromium CSS support
- No compilation required
- Cross-platform (works on Windows/Linux too)
- Same CLI interface as wkhtmltopdf

## Documentation

- **[INSTALL.md](INSTALL.md)** - Comprehensive installation guide
- **[FEATURES.md](FEATURES.md)** - Complete feature list and capabilities
- **[CHANGELOG_MULTIBACKEND.md](CHANGELOG_MULTIBACKEND.md)** - Multi-backend changelog
- **[DEPENDENCIES.md](DEPENDENCIES.md)** - Dependency requirements
- **[PUBLISHING.md](PUBLISHING.md)** - Guide for publishing this fork
- **[AUTO_BACKEND_DETECTION.md](AUTO_BACKEND_DETECTION.md)** - Backend selection logic
- **[DEB_VARIANTS_GUIDE.md](DEB_VARIANTS_GUIDE.md)** - Debian packaging guide

## Examples

### Modern CSS Demo

See `examples/modern_css_demo.html` for a comprehensive demo of:
- Flexbox layouts with various alignments
- CSS Grid with auto-responsive columns
- CSS Transforms (rotate, scale, skew)
- Gradient backgrounds
- Modern selectors and features

```bash
# Convert with WebEngine to see all features
wkhtmltopdf --render-backend webengine examples/modern_css_demo.html modern_demo.pdf

# Compare with WebKit (some features won't render)
wkhtmltopdf --render-backend webkit examples/modern_css_demo.html legacy_demo.pdf
```

### C API Example

See `examples/backend_selector.c` for a complete example of:
- Checking backend availability
- Selecting backend programmatically
- Converting with callbacks

```bash
cd examples
make backend_selector
./backend_selector webengine modern_css_demo.html output.pdf
```

## Build from Source

### Prerequisites

**Ubuntu/Debian:**
```bash
sudo apt-get install build-essential cmake qt5-qmake qtbase5-dev \
  libqt5webkit5-dev qtwebengine5-dev libssl-dev
```

**macOS:**
```bash
brew install qt@5 openssl
```

### Compilation

```bash
# Clone the repository
git clone https://github.com/YOUR_USERNAME/wkhtmltopdf.git
cd wkhtmltopdf

# Build with both backends (recommended)
RENDER_BACKEND=both qmake
make -j$(nproc)
sudo make install

# Or use the automated script
./install.sh
```

### Building Debian Packages

```bash
# Build all variants for current Ubuntu version
./build-deb-all.sh

# Packages will be in parent directory:
# - wkhtmltopdf-0.13.0-qt5-webkit.deb
# - wkhtmltopdf-0.13.0-qt5-webengine.deb
# - wkhtmltopdf-0.13.0-qt6-webengine.deb
```

## Performance & Binary Size

| Backend | Binary Size | Startup Time | Memory (typical) | CSS Support |
|---------|-------------|--------------|------------------|-------------|
| WebKit | ~25 MB | < 50ms | ~80 MB | CSS 2.1 + partial CSS3 |
| WebEngine | ~180 MB | ~200ms | ~200 MB | Full CSS3 + modern JS |
| Both | ~200 MB | Depends on selection | Depends | Maximum flexibility |

**Recommendations:**
- Use **WebKit** for: Batch processing, simple HTML, legacy documents
- Use **WebEngine** for: Modern web content, CSS Grid/Flexbox, complex layouts
- Build **both** for: Production systems that handle varied content

## Platform Support

| Platform | WebKit | WebEngine | Status |
|----------|--------|-----------|--------|
| Ubuntu 18.04+ | ✅ | ✅ | Fully tested |
| Ubuntu 20.04+ | ✅ | ✅ | Recommended |
| Ubuntu 22.04+ | ⚠️ Limited | ✅ | Use WebEngine |
| Debian 10+ | ✅ | ✅ | Fully tested |
| macOS 10.13+ | ⚠️ Deprecated | ✅ | Use WebEngine or Playwright |
| Windows | ⚠️ Untested | ⚠️ Untested | Should work (Qt support) |

## Migration from Original wkhtmltopdf

This fork is **100% backward compatible** with the original wkhtmltopdf:

1. **Drop-in replacement**: All existing CLI commands work unchanged
2. **API compatible**: C and C++ APIs are fully compatible
3. **Default behavior**: Uses WebKit by default (same as original)
4. **Opt-in to new features**: Add `--render-backend webengine` to use modern CSS

```bash
# Your existing commands work as-is
wkhtmltopdf input.html output.pdf

# Add modern CSS support by adding one flag
wkhtmltopdf --render-backend webengine input.html output.pdf
```

## Troubleshooting

### WebEngine Not Available

```bash
# Check if WebEngine backend was compiled
wkhtmltopdf --version | grep -i webengine

# If not, rebuild with WebEngine support
RENDER_BACKEND=webengine qmake && make && sudo make install
```

### Flexbox/Grid Not Rendering

```bash
# Make sure you're using WebEngine backend
wkhtmltopdf --render-backend webengine input.html output.pdf

# Validate your CSS
# (add validator to your workflow - see FEATURES.md)
```

### Missing Dependencies

```bash
# Run dependency checker
./check-dependencies.sh

# Or use installation script (handles dependencies)
./install-ubuntu.sh
```

## Contributing

Contributions are welcome! This is a fork maintained independently of the original wkhtmltopdf project.

### Areas for Contribution
- Additional backend support (WebAssembly, Headless Chrome, etc.)
- Performance optimizations
- Windows/macOS testing and fixes
- Documentation improvements
- Bug fixes and error handling

Please open an issue or pull request on this repository.

## License

**GNU Lesser General Public License v3 (LGPLv3)**

Copyright (C) 2010-2020 wkhtmltopdf authors (original project)
Copyright (C) 2024-2025 Multi-Backend Contributors (enhancements)

This program is free software: you can redistribute it and/or modify it under the terms of the GNU Lesser General Public License as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later version.

See [LICENSE](LICENSE) for full license text.
See [NOTICE](NOTICE) for attribution requirements.

### Third-Party Licenses
- **Qt Framework**: LGPL v3 / GPL v3 / Commercial
- **Qt WebEngine (Chromium)**: BSD and other permissive licenses
- **Playwright wrapper**: Apache License 2.0 (optional component)

## Acknowledgments

- **Original wkhtmltopdf team** for creating the foundation
- **Qt Project** for Qt WebKit and Qt WebEngine
- **Chromium Project** for the Blink rendering engine
- **Microsoft** for Playwright (macOS wrapper)

## Relation to Original Project

This is an **independent fork** with substantial enhancements. It is **not officially endorsed** by the original wkhtmltopdf project maintainers.

- **Original project**: https://github.com/wkhtmltopdf/wkhtmltopdf
- **This fork**: Adds multi-backend architecture and modern CSS support

For issues with the **original functionality**, please refer to the original project.
For issues with the **multi-backend features**, please use this repository's issue tracker.

---

**Star this project** if you find it useful! ⭐

**Report issues**: [GitHub Issues](https://github.com/YOUR_USERNAME/wkhtmltopdf/issues)

**Version**: 0.13.0 | **Last Updated**: 2025-01-09
