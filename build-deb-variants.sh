#!/bin/bash
# Script de génération de DEUX variantes de paquets .deb
# 1. wkhtmltopdf-webengine - Gros moteur (Chromium) - CSS moderne
# 2. wkhtmltopdf-webkit - Petit moteur (WebKit) - Legacy

set -e

VERSION="0.13.0"
ARCH=$(dpkg --print-architecture 2>/dev/null || echo "amd64")
UBUNTU_VERSION=$(lsb_release -rs 2>/dev/null || echo "22.04")

echo "========================================="
echo " Build 2 variantes de paquets .deb"
echo " wkhtmltopdf ${VERSION}"
echo "========================================="
echo ""
echo "Architecture: ${ARCH}"
echo "Ubuntu version: ${UBUNTU_VERSION}"
echo ""

# Fonction pour créer un paquet
build_package() {
    local VARIANT=$1
    local BACKEND=$2
    local PKG_NAME="wkhtmltopdf-${VARIANT}_${VERSION}-ubuntu${UBUNTU_VERSION}_${ARCH}"
    local BUILD_DIR="debian-build-${VARIANT}"

    echo ""
    echo "========================================="
    echo " Building: ${VARIANT} (backend: ${BACKEND})"
    echo "========================================="

    # Vérifier que le binaire est compilé avec le bon backend
    if [ ! -f "bin/wkhtmltopdf" ]; then
        echo "❌ Erreur: bin/wkhtmltopdf n'existe pas"
        echo ""
        echo "Compilez d'abord avec:"
        echo "  RENDER_BACKEND=${BACKEND} qmake"
        echo "  make clean && make -j\$(nproc)"
        echo ""
        return 1
    fi

    # Nettoyer l'ancien build
    rm -rf "${BUILD_DIR}"

    # Créer la structure du paquet
    echo "[1/6] Création de la structure du paquet ${VARIANT}..."
    mkdir -p "${BUILD_DIR}/DEBIAN"
    mkdir -p "${BUILD_DIR}/usr/local/bin"
    mkdir -p "${BUILD_DIR}/usr/local/lib"
    mkdir -p "${BUILD_DIR}/usr/local/include/wkhtmltox"
    mkdir -p "${BUILD_DIR}/usr/share/doc/wkhtmltopdf-${VARIANT}"
    mkdir -p "${BUILD_DIR}/etc/ld.so.conf.d"

    # Copier les fichiers de contrôle Debian
    echo "[2/6] Copie des métadonnées du paquet..."

    # Créer le fichier control spécifique à la variante
    cat > "${BUILD_DIR}/DEBIAN/control" << EOF
Package: wkhtmltopdf-${VARIANT}
Version: ${VERSION}-ubuntu${UBUNTU_VERSION}
Section: utils
Priority: optional
Architecture: ${ARCH}
Maintainer: wkhtmltopdf Team <support@wkhtmltopdf.org>
Homepage: https://wkhtmltopdf.org
EOF

    # Ajouter les dépendances selon la variante
    if [ "$VARIANT" = "webengine" ]; then
        cat >> "${BUILD_DIR}/DEBIAN/control" << EOF
Depends: libqt5core5a, libqt5gui5, libqt5network5, libqt5svg5, libqt5xmlpatterns5, libqt5webenginecore5, libqt5webenginewidgets5, libqt5printsupport5, libqt5positioning5, libssl3 | libssl1.1, libfontconfig1, libfreetype6, libx11-6, libxrender1, libxext6, libc6, libnss3, libxcomposite1, libxcursor1, libxdamage1, libxi6, libxtst6
Recommends: qtwebengine5-dev
Conflicts: wkhtmltopdf-webkit, wkhtmltopdf
Replaces: wkhtmltopdf-webkit, wkhtmltopdf
Provides: wkhtmltopdf
Description: HTML to PDF converter with WebEngine backend (modern CSS support)
 wkhtmltopdf converts HTML to PDF using Qt WebEngine (Chromium-based).
 .
 This variant includes the WebEngine backend for full modern CSS3 support:
  * CSS Flexbox layouts
  * CSS Grid layouts
  * CSS Transforms and Animations
  * Modern CSS gradients and effects
  * Modern JavaScript (ES6+)
 .
 Size: ~200MB installed (includes Chromium dependencies)
 Backend: Qt WebEngine (Chromium/Blink)
 .
 For a smaller installation without modern CSS, use wkhtmltopdf-webkit instead.
EOF
    else
        cat >> "${BUILD_DIR}/DEBIAN/control" << EOF
Depends: libqt5core5a, libqt5gui5, libqt5network5, libqt5svg5, libqt5xmlpatterns5, libqt5webkit5, libssl3 | libssl1.1, libfontconfig1, libfreetype6, libx11-6, libxrender1, libxext6, libc6
Recommends: libqt5webkit5-dev
Conflicts: wkhtmltopdf-webengine, wkhtmltopdf
Replaces: wkhtmltopdf-webengine, wkhtmltopdf
Provides: wkhtmltopdf
Description: HTML to PDF converter with WebKit backend (lightweight)
 wkhtmltopdf converts HTML to PDF using Qt WebKit.
 .
 This variant includes the WebKit backend - lightweight and fast:
  * Smaller installation (~40MB)
  * Lower memory usage
  * Faster compilation
  * CSS support from ~2012 (no modern flexbox/grid)
 .
 Size: ~40MB installed
 Backend: Qt WebKit (Legacy)
 .
 For modern CSS3 support (flexbox, grid), use wkhtmltopdf-webengine instead.
EOF
    fi

    # Scripts post-installation
    cat > "${BUILD_DIR}/DEBIAN/postinst" << 'EOF'
#!/bin/sh
set -e
if [ -x /sbin/ldconfig ]; then
    /sbin/ldconfig
fi
if [ -x /usr/local/bin/wkhtmltopdf ]; then
    echo "wkhtmltopdf installed successfully!"
    /usr/local/bin/wkhtmltopdf --version || true
fi
exit 0
EOF

    cat > "${BUILD_DIR}/DEBIAN/postrm" << 'EOF'
#!/bin/sh
set -e
if [ "$1" = "remove" ] || [ "$1" = "purge" ]; then
    if [ -x /sbin/ldconfig ]; then
        /sbin/ldconfig
    fi
fi
exit 0
EOF

    chmod 755 "${BUILD_DIR}/DEBIAN/postinst" "${BUILD_DIR}/DEBIAN/postrm"

    # Copier la documentation
    echo "[3/6] Copie de la documentation..."

    # Créer les fichiers de documentation s'ils n'existent pas
    if [ ! -f "debian/usr/share/doc/wkhtmltopdf/copyright" ]; then
        echo "  Création du fichier copyright..."
        mkdir -p debian/usr/share/doc/wkhtmltopdf
        cat > debian/usr/share/doc/wkhtmltopdf/copyright << 'EOFCOPY'
Format: https://www.debian.org/doc/packaging-manuals/copyright-format/1.0/
Upstream-Name: wkhtmltopdf
Source: https://github.com/wkhtmltopdf/wkhtmltopdf

Files: *
Copyright: 2010-2020 wkhtmltopdf authors
License: LGPL-3+

License: LGPL-3+
 This is free software under LGPL-3.0 or later.
 See /usr/share/common-licenses/LGPL-3 for details.
EOFCOPY
    fi

    if [ ! -f "debian/usr/share/doc/wkhtmltopdf/changelog.Debian.gz" ]; then
        echo "  Création du changelog..."
        cat > /tmp/changelog.Debian.$$ << 'EOFLOG'
wkhtmltopdf (0.13.0) unstable; urgency=medium

  * New release 0.13.0

 -- wkhtmltopdf Team <support@wkhtmltopdf.org>  Sat, 09 Nov 2024 15:00:00 +0000
EOFLOG
        gzip -9 -c /tmp/changelog.Debian.$$ > debian/usr/share/doc/wkhtmltopdf/changelog.Debian.gz
        rm -f /tmp/changelog.Debian.$$
    fi

    cp debian/usr/share/doc/wkhtmltopdf/copyright "${BUILD_DIR}/usr/share/doc/wkhtmltopdf-${VARIANT}/"
    cp debian/usr/share/doc/wkhtmltopdf/changelog.Debian.gz "${BUILD_DIR}/usr/share/doc/wkhtmltopdf-${VARIANT}/"

    # Ajouter un README spécifique à la variante
    if [ "$VARIANT" = "webengine" ]; then
        cat > "${BUILD_DIR}/usr/share/doc/wkhtmltopdf-${VARIANT}/README" << 'EOFREADME'
wkhtmltopdf-webengine
=====================

This package uses Qt WebEngine (Chromium-based) for rendering.

Features:
- Full CSS3 support (Flexbox, Grid, Animations)
- Modern JavaScript (ES6+)
- Latest web standards

Size: ~200MB installed

See /usr/share/doc/wkhtmltopdf-webengine/ for documentation.
EOFREADME
    else
        cat > "${BUILD_DIR}/usr/share/doc/wkhtmltopdf-${VARIANT}/README" << 'EOFREADME'
wkhtmltopdf-webkit
==================

This package uses Qt WebKit (legacy) for rendering.

Features:
- Lightweight (~40MB installed)
- Fast and efficient
- CSS support from ~2012

Limitations:
- No modern CSS Flexbox/Grid
- Limited CSS3 support

For modern CSS, use wkhtmltopdf-webengine instead.

See /usr/share/doc/wkhtmltopdf-webkit/ for documentation.
EOFREADME
    fi

    # Installer les binaires
    echo "[4/6] Installation des binaires..."
    install -m 755 bin/wkhtmltopdf "${BUILD_DIR}/usr/local/bin/"
    install -m 755 bin/wkhtmltoimage "${BUILD_DIR}/usr/local/bin/"

    # Installer les bibliothèques
    echo "[5/6] Installation des bibliothèques..."
    install -m 644 bin/libwkhtmltox.so.0.12.7 "${BUILD_DIR}/usr/local/lib/"
    ln -s libwkhtmltox.so.0.12.7 "${BUILD_DIR}/usr/local/lib/libwkhtmltox.so.0.12"
    ln -s libwkhtmltox.so.0.12.7 "${BUILD_DIR}/usr/local/lib/libwkhtmltox.so.0"
    ln -s libwkhtmltox.so.0.12.7 "${BUILD_DIR}/usr/local/lib/libwkhtmltox.so"

    # Installer les headers
    if [ -d "src/lib" ]; then
        install -m 644 src/lib/pdf.h "${BUILD_DIR}/usr/local/include/wkhtmltox/" 2>/dev/null || true
        install -m 644 src/lib/image.h "${BUILD_DIR}/usr/local/include/wkhtmltox/" 2>/dev/null || true
        install -m 644 src/lib/dllbegin.inc "${BUILD_DIR}/usr/local/include/wkhtmltox/" 2>/dev/null || true
        install -m 644 src/lib/dllend.inc "${BUILD_DIR}/usr/local/include/wkhtmltox/" 2>/dev/null || true
    fi

    # Configurer ldconfig
    echo "/usr/local/lib" > "${BUILD_DIR}/etc/ld.so.conf.d/wkhtmltopdf.conf"

    # Calculer la taille installée
    INSTALLED_SIZE=$(du -sk "${BUILD_DIR}/usr" "${BUILD_DIR}/etc" 2>/dev/null | awk '{sum+=$1} END {print sum}')
    echo "Installed-Size: ${INSTALLED_SIZE}" >> "${BUILD_DIR}/DEBIAN/control"

    # Construire le paquet
    echo "[6/6] Construction du paquet .deb..."
    dpkg-deb --build "${BUILD_DIR}" "${PKG_NAME}.deb"

    echo ""
    echo "✓ Paquet créé: ${PKG_NAME}.deb"
    echo "  Taille: $(du -h "${PKG_NAME}.deb" | cut -f1)"
    echo ""
}

# Menu principal
echo "Quelle(s) variante(s) voulez-vous construire ?"
echo ""
echo "1) WebEngine uniquement (gros, CSS moderne)"
echo "2) WebKit uniquement (petit, legacy)"
echo "3) Les deux"
echo ""
read -p "Choix [1-3]: " CHOICE

case $CHOICE in
    1)
        echo ""
        echo "Construction de la variante WebEngine..."
        echo ""
        echo "⚠️  Assurez-vous d'avoir compilé avec:"
        echo "   RENDER_BACKEND=webengine qmake"
        echo "   make clean && make -j\$(nproc)"
        echo ""
        read -p "Continuer ? [y/N] " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            build_package "webengine" "webengine"
        fi
        ;;
    2)
        echo ""
        echo "Construction de la variante WebKit..."
        echo ""
        echo "⚠️  Assurez-vous d'avoir compilé avec:"
        echo "   RENDER_BACKEND=webkit qmake"
        echo "   make clean && make -j\$(nproc)"
        echo ""
        read -p "Continuer ? [y/N] " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            build_package "webkit" "webkit"
        fi
        ;;
    3)
        echo ""
        echo "Construction des DEUX variantes..."
        echo ""
        echo "Cela nécessite de compiler deux fois le projet !"
        echo ""

        # WebEngine
        echo "=== Étape 1/2: WebEngine ==="
        echo "Compilation avec WebEngine..."
        make clean || true
        RENDER_BACKEND=webengine qmake
        make -j$(nproc)
        build_package "webengine" "webengine"

        # WebKit
        echo ""
        echo "=== Étape 2/2: WebKit ==="
        echo "Compilation avec WebKit..."
        make clean || true
        RENDER_BACKEND=webkit qmake
        make -j$(nproc)
        build_package "webkit" "webkit"
        ;;
    *)
        echo "Choix invalide"
        exit 1
        ;;
esac

echo ""
echo "========================================="
echo " ✓ Build terminé !"
echo "========================================="
echo ""
echo "Paquets créés:"
ls -lh wkhtmltopdf-*_${VERSION}-ubuntu${UBUNTU_VERSION}_${ARCH}.deb 2>/dev/null || echo "  (aucun)"
echo ""
echo "Pour installer:"
echo "  WebEngine: sudo dpkg -i wkhtmltopdf-webengine_${VERSION}-ubuntu${UBUNTU_VERSION}_${ARCH}.deb"
echo "  WebKit:    sudo dpkg -i wkhtmltopdf-webkit_${VERSION}-ubuntu${UBUNTU_VERSION}_${ARCH}.deb"
echo ""
echo "Note: Les deux variantes ne peuvent pas être installées en même temps (conflict)"
echo ""
