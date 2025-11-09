# Publishing Guide - wkhtmltopdf Multi-Backend Edition

This guide explains how to properly publish this fork of wkhtmltopdf, ensuring legal compliance and professional presentation.

## Table of Contents

1. [Legal Compliance](#legal-compliance)
2. [Pre-Publication Checklist](#pre-publication-checklist)
3. [Repository Setup](#repository-setup)
4. [Naming Considerations](#naming-considerations)
5. [Release Process](#release-process)
6. [Distribution Channels](#distribution-channels)
7. [Marketing & Communication](#marketing--communication)
8. [Ongoing Maintenance](#ongoing-maintenance)

---

## Legal Compliance

### ✅ License Requirements (LGPL v3)

This fork **MUST** comply with the GNU Lesser General Public License v3:

#### Required Actions

1. **✅ Keep Original License File**
   - File `LICENSE` contains LGPLv3 text
   - Must be included in all distributions

2. **✅ Copyright Notices**
   - Original copyright: `Copyright (C) 2010-2020 wkhtmltopdf authors`
   - Your copyright: `Copyright (C) 2024-2025 [Your Name/Organization]`
   - Both must appear in source files and documentation

3. **✅ Attribution File**
   - File `NOTICE` provides proper attribution
   - Clearly states this is a fork
   - Links to original project

4. **✅ Source Code Availability**
   - Must provide complete source code
   - Include all build scripts and dependencies
   - Document build process

5. **✅ Modification Documentation**
   - File `CHANGELOG_MULTIBACKEND.md` documents all changes
   - Clear indication that code has been modified

6. **✅ Same License Terms**
   - Cannot change license to something more restrictive
   - Must remain LGPLv3
   - Recipients have same freedoms

### ❌ Prohibited Actions

1. **Cannot remove** original copyright notices
2. **Cannot change** license to proprietary
3. **Cannot claim** this is the official wkhtmltopdf
4. **Cannot prevent** others from forking your fork
5. **Cannot hide** source code if you distribute binaries

### Third-Party Component Licenses

This software includes components with different licenses:

| Component | License | Compatibility |
|-----------|---------|---------------|
| Qt Framework | LGPL v3 / GPL v3 | ✅ Compatible |
| Qt WebEngine (Chromium) | BSD + others | ✅ Compatible (permissive) |
| Playwright wrapper | Apache 2.0 | ✅ Compatible (optional) |

**Important**: These licenses are compatible with LGPLv3 distribution.

---

## Pre-Publication Checklist

### Documentation Review

- [x] `README.md` - Complete and accurate
- [x] `FEATURES.md` - Comprehensive feature list
- [x] `NOTICE` - Proper attribution
- [x] `LICENSE` - LGPLv3 included
- [x] `CHANGELOG_MULTIBACKEND.md` - All changes documented
- [x] `INSTALL.md` - Installation instructions
- [ ] Update URLs to point to your repository (not placeholder)

### Code Review

- [ ] Remove any TODO comments that shouldn't be public
- [ ] Ensure no hardcoded credentials or private info
- [ ] Verify all copyright headers in source files
- [ ] Check for debug code or commented-out experiments
- [ ] Ensure code quality meets your standards

### Build Verification

```bash
# Clean everything
./clean-for-git.sh

# Test build with WebKit
RENDER_BACKEND=webkit qmake && make
./bin/wkhtmltopdf --version

# Test build with WebEngine
make clean
RENDER_BACKEND=webengine qmake && make
./bin/wkhtmltopdf --version

# Test build with both
make clean
RENDER_BACKEND=both qmake && make
./bin/wkhtmltopdf --version

# Run installation test
./test-install.sh

# Test all backends
./test-all-backends.sh
```

### File Cleanup

**Remove temporary/personal files:**
```bash
./clean-for-git.sh

# Also consider removing/consolidating these docs:
rm COMPTE_RENDU_FINAL.md
rm RECAP_FINAL.md
rm COMMIT_READY.md
rm CHECKLIST_FINAL.md
# (or consolidate them into CHANGELOG_MULTIBACKEND.md)
```

**Keep these files:**
- All source code (`.cc`, `.hh`, `.c`, `.h`)
- Qt project files (`.pro`, `.pri`)
- Build scripts (`.sh`)
- Documentation (`.md` files listed in checklist)
- Examples (`examples/`)
- Playwright wrapper (`playwright-wrapper/`)
- Debian packaging templates (`debian/`)

---

## Repository Setup

### 1. Choose a Repository Name

**Recommended approach**: Choose a distinct name to avoid confusion

**Good options:**
- `wkhtmltopdf-multibackend`
- `wkhtmltopdf-modern`
- `wkhtmltopdf-ng` (next generation)
- `wk2pdf`
- `htmltopdf-flex` (emphasizes modern CSS)

**Not recommended:**
- `wkhtmltopdf` (exact same name - confusing)
- `wkhtmltopdf-official` (misleading)

### 2. Create GitHub Repository

```bash
# On GitHub, create a new repository with your chosen name
# Then in your local directory:

# Update remote URL
git remote remove origin  # Remove old origin (if cloned from original)
git remote add origin https://github.com/YOUR_USERNAME/YOUR_REPO_NAME.git

# Create initial commit (if starting fresh)
git add .
git commit -m "Initial commit: wkhtmltopdf multi-backend fork v0.13.0

- Multi-backend architecture (WebKit + WebEngine)
- Full CSS3 support via Qt WebEngine
- Backward compatible with original wkhtmltopdf
- Comprehensive build and installation automation
- Multiple Debian package variants
- Enhanced documentation and examples

Based on wkhtmltopdf (https://github.com/wkhtmltopdf/wkhtmltopdf)
Licensed under LGPLv3"

# Push to your repository
git push -u origin master
```

### 3. Repository Description

Set your repository description on GitHub:

```
Modern fork of wkhtmltopdf with multi-backend support (WebKit + WebEngine)
for CSS Grid, Flexbox, and modern CSS3 features. 100% backward compatible.
Licensed under LGPLv3.
```

### 4. Repository Topics/Tags

Add these topics on GitHub:
- `pdf`
- `html-to-pdf`
- `wkhtmltopdf`
- `qt`
- `css3`
- `flexbox`
- `css-grid`
- `webengine`
- `webkit`
- `multi-backend`
- `lgpl`

### 5. README Badge Updates

Update `README.md` to replace placeholders:

```bash
# Find and replace YOUR_USERNAME with your actual GitHub username
sed -i 's/YOUR_USERNAME/yourusername/g' README.md

# Or manually edit:
# - Clone URL
# - Issue tracker URL
# - Curl installation URLs
```

---

## Naming Considerations

### Should You Rename?

**Pros of renaming:**
- ✅ Clear distinction from original project
- ✅ Avoids trademark issues
- ✅ Establishes your project identity
- ✅ Easier to search/find your specific version

**Cons of renaming:**
- ❌ Loses name recognition
- ❌ Existing users may not find it
- ❌ More marketing effort needed
- ❌ Have to change binary/command name

### Recommendation

**Keep "wkhtmltopdf" in the name** but add a distinguisher:

```
Repository name: wkhtmltopdf-multibackend
Binary name:     wkhtmltopdf (stays the same)
Package name:    wkhtmltopdf or wkhtmltopdf-mb
Full name:       "wkhtmltopdf Multi-Backend Edition"
```

This approach:
- Maintains discoverability
- Shows relationship to original
- Clearly indicates it's different
- Keeps command-line compatibility

### Trademark Considerations

"wkhtmltopdf" is associated with the original project but is not a registered trademark. Using it in a fork name with clear indication of being a fork (e.g., "wkhtmltopdf Multi-Backend Edition") is generally acceptable under open source norms.

**Important disclaimers to include:**
- "This is an independent fork of wkhtmltopdf"
- "Not officially endorsed by original wkhtmltopdf maintainers"
- Link to original project

---

## Release Process

### Version Numbering

Current version: `0.13.0`

**Versioning scheme:**
```
MAJOR.MINOR.PATCH

0.13.0 - Major fork release (multi-backend architecture)
0.13.1 - Bug fixes, minor improvements
0.14.0 - New features (e.g., additional backends)
1.0.0 - Production-ready, stable API
```

### Creating a Release

#### 1. Prepare Release

```bash
# Update VERSION file
echo "0.13.0" > VERSION

# Update CHANGELOG
# Add release date to CHANGELOG_MULTIBACKEND.md

# Commit version bump
git add VERSION CHANGELOG_MULTIBACKEND.md
git commit -m "Release v0.13.0"
git push
```

#### 2. Create Git Tag

```bash
# Create annotated tag
git tag -a v0.13.0 -m "Release v0.13.0 - Multi-Backend Edition

Major Features:
- Multi-backend architecture (WebKit + WebEngine)
- Full CSS3 support (Flexbox, Grid, Transforms, etc.)
- Runtime backend selection
- HTML/CSS validation system
- Structured error handling
- Comprehensive automation scripts
- Multiple Debian package variants

Platforms: Ubuntu, Debian, macOS
License: LGPLv3"

# Push tag
git push origin v0.13.0
```

#### 3. Build Release Artifacts

```bash
# Build all Debian package variants
./build-deb-variants.sh

# This creates:
# - wkhtmltopdf-0.13.0-qt5-webkit.deb
# - wkhtmltopdf-0.13.0-qt5-webengine.deb
# - wkhtmltopdf-0.13.0-qt6-webengine.deb

# Build source tarball
git archive --format=tar.gz --prefix=wkhtmltopdf-0.13.0/ v0.13.0 \
  > wkhtmltopdf-0.13.0-source.tar.gz

# Generate checksums
sha256sum wkhtmltopdf-0.13.0-*.deb wkhtmltopdf-0.13.0-source.tar.gz \
  > SHA256SUMS.txt
```

#### 4. Create GitHub Release

On GitHub:
1. Go to "Releases" → "Create a new release"
2. Select tag `v0.13.0`
3. Title: "v0.13.0 - Multi-Backend Edition"
4. Description: (use template below)
5. Upload artifacts:
   - `wkhtmltopdf-0.13.0-qt5-webkit.deb`
   - `wkhtmltopdf-0.13.0-qt5-webengine.deb`
   - `wkhtmltopdf-0.13.0-qt6-webengine.deb`
   - `wkhtmltopdf-0.13.0-source.tar.gz`
   - `SHA256SUMS.txt`
6. Check "This is a pre-release" (for v0.x versions)
7. Publish release

**Release description template:**

```markdown
# wkhtmltopdf v0.13.0 - Multi-Backend Edition

**Modern CSS Support • Multi-Backend Architecture • Production Ready**

This is a major fork of [wkhtmltopdf](https://github.com/wkhtmltopdf/wkhtmltopdf)
with multi-backend support for modern CSS3 features.

## 🎉 Major Features

- **Multi-Backend Architecture**: Choose between WebKit (legacy) and WebEngine (modern)
- **Full CSS3 Support**: Flexbox, Grid, Transforms, Animations, Gradients
- **Runtime Backend Selection**: Switch backends without recompiling
- **100% Backward Compatible**: Drop-in replacement for original wkhtmltopdf
- **HTML/CSS Validator**: Detect compatibility issues before conversion
- **Enhanced Error Handling**: Structured error codes with suggestions
- **Automated Installation**: One-command install on Ubuntu, Debian, macOS
- **Multiple Debian Variants**: Choose Qt5/Qt6, WebKit/WebEngine packages

## 📦 Downloads

Choose the package that fits your needs:

| Package | Backend | Use Case | Size |
|---------|---------|----------|------|
| `wkhtmltopdf-0.13.0-qt5-webkit.deb` | WebKit | Legacy compatibility | ~25 MB |
| `wkhtmltopdf-0.13.0-qt5-webengine.deb` | WebEngine | Modern CSS | ~180 MB |
| `wkhtmltopdf-0.13.0-qt6-webengine.deb` | WebEngine (Qt6) | Latest | ~180 MB |

**Source code**: `wkhtmltopdf-0.13.0-source.tar.gz`

## 🚀 Quick Start

### Ubuntu/Debian Installation
```bash
# Download appropriate .deb package
wget https://github.com/YOUR_USERNAME/YOUR_REPO/releases/download/v0.13.0/wkhtmltopdf-0.13.0-qt5-webengine.deb
sudo dpkg -i wkhtmltopdf-0.13.0-qt5-webengine.deb
sudo apt-get install -f  # Fix dependencies
```

### From Source
```bash
curl -fsSL https://github.com/YOUR_USERNAME/YOUR_REPO/archive/v0.13.0.tar.gz | tar xz
cd wkhtmltopdf-0.13.0
./install-ubuntu.sh  # or install-macos.sh
```

## 📖 Documentation

- [README](https://github.com/YOUR_USERNAME/YOUR_REPO/blob/v0.13.0/README.md)
- [FEATURES](https://github.com/YOUR_USERNAME/YOUR_REPO/blob/v0.13.0/FEATURES.md)
- [INSTALL](https://github.com/YOUR_USERNAME/YOUR_REPO/blob/v0.13.0/INSTALL.md)

## ✅ Verified Platforms

- Ubuntu 18.04, 20.04, 22.04, 24.04
- Debian 10, 11, 12
- macOS 10.13+ (Intel and Apple Silicon)

## 🙏 Credits

Based on [wkhtmltopdf](https://github.com/wkhtmltopdf/wkhtmltopdf)
by the wkhtmltopdf authors.

This is an independent fork with substantial enhancements. Not officially
endorsed by the original project maintainers.

## 📄 License

GNU Lesser General Public License v3 (LGPLv3)

---

**Full Changelog**: [CHANGELOG_MULTIBACKEND.md](CHANGELOG_MULTIBACKEND.md)
```

---

## Distribution Channels

### 1. GitHub Releases (Primary)

✅ **Recommended** - Main distribution channel

**Advantages:**
- Version control integration
- Automatic archive downloads
- Release notes
- Binary hosting
- Free for open source

### 2. Personal Package Archive (PPA)

For Ubuntu users:

```bash
# Create Launchpad account
# Create PPA: ppa:yourname/wkhtmltopdf-multibackend

# Upload packages
dput ppa:yourname/wkhtmltopdf-multibackend wkhtmltopdf_0.13.0-1_source.changes
```

**Users can then:**
```bash
sudo add-apt-repository ppa:yourname/wkhtmltopdf-multibackend
sudo apt-get update
sudo apt-get install wkhtmltopdf
```

### 3. Homebrew Tap (macOS)

Create a Homebrew formula:

```ruby
# homebrew-wkhtmltopdf/Formula/wkhtmltopdf.rb
class Wkhtmltopdf < Formula
  desc "HTML to PDF converter with modern CSS support"
  homepage "https://github.com/YOUR_USERNAME/YOUR_REPO"
  url "https://github.com/YOUR_USERNAME/YOUR_REPO/archive/v0.13.0.tar.gz"
  sha256 "CHECKSUM_HERE"
  license "LGPL-3.0"

  depends_on "qt@5"
  depends_on "openssl@3"

  def install
    system "qmake", "RENDER_BACKEND=both"
    system "make"
    bin.install "bin/wkhtmltopdf"
    bin.install "bin/wkhtmltoimage"
  end

  test do
    system "#{bin}/wkhtmltopdf", "--version"
  end
end
```

**Users install:**
```bash
brew tap yourname/wkhtmltopdf
brew install wkhtmltopdf
```

### 4. Docker Images

```dockerfile
# Dockerfile
FROM ubuntu:22.04

RUN apt-get update && apt-get install -y \
    build-essential qt5-qmake qtwebengine5-dev \
    && rm -rf /var/lib/apt/lists/*

COPY . /wkhtmltopdf
WORKDIR /wkhtmltopdf

RUN RENDER_BACKEND=webengine qmake && make && make install

ENTRYPOINT ["wkhtmltopdf"]
```

**Publish to Docker Hub:**
```bash
docker build -t yourname/wkhtmltopdf:0.13.0 .
docker push yourname/wkhtmltopdf:0.13.0
```

### 5. npm Package (Playwright Wrapper)

```bash
cd playwright-wrapper
npm publish
# Becomes: npm install -g @yourname/wkhtmltopdf
```

---

## Marketing & Communication

### Announce Your Fork

#### 1. GitHub README

Already done - comprehensive README.md showcases all features

#### 2. Social Media Announcement

**Template:**

```
🚀 Introducing wkhtmltopdf Multi-Backend Edition v0.13.0

Finally, convert modern HTML with CSS Grid & Flexbox to PDF!

✅ Full CSS3 support via Qt WebEngine
✅ 100% backward compatible
✅ Runtime backend switching
✅ Easy installation (one command)

Free & open source (LGPLv3)
https://github.com/YOUR_USERNAME/YOUR_REPO

#webdev #pdf #opensource #html2pdf
```

**Platforms:**
- Twitter/X
- Reddit (r/programming, r/webdev)
- Hacker News
- Dev.to
- LinkedIn

#### 3. Blog Post / Dev.to Article

**Title ideas:**
- "wkhtmltopdf Gets Modern CSS Support: Introducing Multi-Backend Edition"
- "How I Added CSS Grid and Flexbox to wkhtmltopdf"
- "Converting Modern HTML to PDF: A wkhtmltopdf Fork Story"

**Structure:**
1. Problem: Original wkhtmltopdf lacks modern CSS
2. Solution: Multi-backend architecture
3. How it works: WebKit vs WebEngine
4. Installation & usage examples
5. Technical details (for developers)
6. Future plans
7. Call to action (star, contribute)

#### 4. Video Demo (YouTube)

**Content:**
- Show side-by-side comparison
- WebKit (no flexbox) vs WebEngine (full flexbox)
- Installation walkthrough
- Real-world use case

### Documentation Website

Consider creating a documentation site with:
- Installation guides
- API documentation
- Examples gallery
- Migration guide
- FAQ

**Options:**
- GitHub Pages (free)
- Read the Docs (free for open source)
- Custom domain

---

## Ongoing Maintenance

### Issue Management

**Label your issues:**
- `bug` - Something broken
- `enhancement` - Feature request
- `backend:webkit` - WebKit specific
- `backend:webengine` - WebEngine specific
- `documentation` - Docs issue
- `question` - User question
- `good first issue` - For new contributors

**Issue templates:**

Create `.github/ISSUE_TEMPLATE/bug_report.md`:

```markdown
---
name: Bug report
about: Report a problem with wkhtmltopdf
---

**Backend used:**
- [ ] WebKit
- [ ] WebEngine
- [ ] Not sure

**Environment:**
- OS: [e.g., Ubuntu 22.04]
- wkhtmltopdf version: [e.g., 0.13.0]
- Qt version: [run `wkhtmltopdf --version`]

**Describe the bug:**


**To Reproduce:**
1. Input HTML: [attach or paste]
2. Command run: `wkhtmltopdf ...`
3. Expected output:
4. Actual output:

**Additional context:**
```

### Pull Request Guidelines

Create `CONTRIBUTING.md`:

```markdown
# Contributing

We welcome contributions! Please follow these guidelines:

## Code Style
- Follow existing code style
- Use Qt naming conventions
- Add Doxygen comments for new APIs

## Testing
- Test with both WebKit and WebEngine backends
- Ensure backward compatibility
- Add examples if adding features

## Commit Messages
- Use clear, descriptive messages
- Reference issues: "Fix flexbox rendering (#42)"

## License
By contributing, you agree your code will be licensed under LGPLv3.
```

### Versioning Strategy

**Semantic Versioning:**
- `0.13.x` - Initial multi-backend release
- `0.14.x` - New features (e.g., new backends, APIs)
- `0.15.x` - Major new features
- `1.0.0` - Stable API, production-ready declaration

**When to bump:**
- Patch (0.13.1): Bug fixes only
- Minor (0.14.0): New features, backward compatible
- Major (1.0.0): Breaking changes, major milestone

### Staying in Sync with Original

**Option 1: Regular merges**
```bash
# Add original as upstream
git remote add upstream https://github.com/wkhtmltopdf/wkhtmltopdf.git

# Pull updates
git fetch upstream
git merge upstream/master

# Resolve conflicts, test, commit
```

**Option 2: Cherry-pick fixes**
```bash
# Pick specific bug fixes from original
git cherry-pick COMMIT_HASH
```

**Option 3: Independent development**
- Fork has diverged significantly
- Original is not actively maintained
- Focus on your enhancements

### Roadmap

Maintain a public roadmap in `ROADMAP.md`:

```markdown
# Roadmap

## v0.13.x (Current)
- [x] Multi-backend architecture
- [x] WebKit + WebEngine support
- [ ] Windows build support
- [ ] macOS Apple Silicon optimization

## v0.14.0 (Q2 2025)
- [ ] Puppeteer backend
- [ ] Configuration file support
- [ ] Watch mode
- [ ] REST API server

## v1.0.0 (Future)
- [ ] Stable API
- [ ] Full platform support
- [ ] Production-ready
- [ ] Comprehensive test coverage
```

---

## Legal Disclaimer Example

Add to your README and website:

```markdown
## Legal

### License
This project is licensed under the GNU Lesser General Public License v3 (LGPLv3).
See [LICENSE](LICENSE) file for details.

### Attribution
This is a fork of [wkhtmltopdf](https://github.com/wkhtmltopdf/wkhtmltopdf)
by the wkhtmltopdf authors.

Original Copyright (C) 2010-2020 wkhtmltopdf authors
Multi-Backend Enhancements Copyright (C) 2024-2025 [Your Name]

### Disclaimer
This project is NOT affiliated with, endorsed by, or officially supported by
the original wkhtmltopdf project maintainers. It is an independent fork
maintained separately.

### Trademarks
"wkhtmltopdf" is a name associated with the original open source project.
This fork uses the name to indicate its origin and compatibility, not to
claim endorsement.

### Warranty Disclaimer
THIS SOFTWARE IS PROVIDED "AS IS" WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED. See LICENSE for full disclaimer.
```

---

## Final Checklist Before Publishing

- [ ] All documentation reviewed and URLs updated
- [ ] Copyright notices present in all source files
- [ ] LICENSE and NOTICE files included
- [ ] No personal/private information in code
- [ ] Build tested on target platforms
- [ ] Installation scripts tested
- [ ] Examples work correctly
- [ ] Git repository clean (no temp files)
- [ ] Version number finalized
- [ ] Git tag created
- [ ] GitHub release created with binaries
- [ ] README badges and links updated
- [ ] Social media announcement prepared

---

## You're Ready to Publish! 🚀

Once you've completed this checklist, you can confidently publish your fork:

1. ✅ **Legally compliant** (LGPLv3 requirements met)
2. ✅ **Well documented** (comprehensive docs)
3. ✅ **Professionally presented** (clear value proposition)
4. ✅ **Easy to install** (automated scripts)
5. ✅ **Community-ready** (issue templates, contributing guide)

**Go ahead and share your work with the world!**

---

**Questions?** Open an issue or discussion in the repository.

**Version**: 0.13.0 | **Last Updated**: 2025-01-09
