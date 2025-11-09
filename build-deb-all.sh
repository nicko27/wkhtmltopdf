#!/bin/bash
# Script de génération de paquets .deb avec choix Qt5/Qt6 et backend
# Supporte:
#   Qt5: WebEngine + WebKit
#   Qt6: WebEngine uniquement

set -e

VERSION="0.13.0"
VERSION_QT6="1.0.0"
ARCH=$(dpkg --print-architecture 2>/dev/null || echo "amd64")
UBUNTU_VERSION=$(lsb_release -rs 2>/dev/null || echo "22.04")

echo "========================================="
echo " Générateur de paquets .deb wkhtmltopdf"
echo "========================================="
echo ""
echo "Architecture: ${ARCH}"
echo "Ubuntu version: ${UBUNTU_VERSION}"
echo ""

# Fonction pour créer un paquet
build_package() {
    local QT_VERSION=$1  # qt5 ou qt6
    local VARIANT=$2     # webengine ou webkit
    local BACKEND=$3     # webengine ou webkit

    if [ "$QT_VERSION" = "qt6" ]; then
        local PKG_VERSION="$VERSION_QT6"
        local PKG_NAME="wkhtmltopdf-qt6_${PKG_VERSION}-ubuntu${UBUNTU_VERSION}_${ARCH}"

        if [ "$VARIANT" != "webengine" ]; then
            echo -e "${YELLOW}⚠ Skipping Qt6 + WebKit (not supported)${NC}"
            return 0
        fi
    else
        local PKG_VERSION="$VERSION"
        local PKG_NAME="wkhtmltopdf-${VARIANT}_${PKG_VERSION}-ubuntu${UBUNTU_VERSION}_${ARCH}"
    fi

    local BUILD_DIR="debian-build-${QT_VERSION}-${VARIANT}"

    echo ""
    echo "========================================="
    echo " Building: ${QT_VERSION} + ${VARIANT}"
    echo "========================================="

    # Vérifier que le binaire est compilé avec le bon backend
    if [ ! -f "bin/wkhtmltopdf" ]; then
        echo "❌ Erreur: bin/wkhtmltopdf n'existe pas"
        echo ""
        echo "Compilez d'abord avec:"
        if [ "$QT_VERSION" = "qt6" ]; then
            echo "  qmake6 && make clean && make -j\$(nproc)"
        else
            echo "  RENDER_BACKEND=${BACKEND} qmake"
            echo "  make clean && make -j\$(nproc)"
        fi
        echo ""
        return 1
    fi

    # Nettoyer l'ancien build
    rm -rf "${BUILD_DIR}"

    # Créer la structure du paquet
    echo "[1/6] Création de la structure du paquet..."
    mkdir -p "${BUILD_DIR}/DEBIAN"
    mkdir -p "${BUILD_DIR}/usr/local/bin"
    mkdir -p "${BUILD_DIR}/usr/local/lib"
    mkdir -p "${BUILD_DIR}/usr/local/include/wkhtmltox"
    mkdir -p "${BUILD_DIR}/usr/share/doc/wkhtmltopdf-${QT_VERSION}-${VARIANT}"
    mkdir -p "${BUILD_DIR}/etc/ld.so.conf.d"

    # Créer le fichier control
    echo "[2/6] Copie des métadonnées du paquet..."

    if [ "$QT_VERSION" = "qt6" ]; then
        # Paquet Qt6 (WebEngine uniquement)
        cat > "${BUILD_DIR}/DEBIAN/control" << EOF
Package: wkhtmltopdf-qt6
Version: ${PKG_VERSION}-ubuntu${UBUNTU_VERSION}
Section: utils
Priority: optional
Architecture: ${ARCH}
Maintainer: wkhtmltopdf Team <support@wkhtmltopdf.org>
Homepage: https://wkhtmltopdf.org
Depends: libqt6core6, libqt6gui6, libqt6network6, libqt6svg6, libqt6webenginecore6, libqt6webenginewidgets6, libqt6printsupport6, libssl3, libfontconfig1, libfreetype6, libx11-6, libxrender1, libxext6, libc6, libnss3, libxcomposite1, libxcursor1, libxdamage1, libxi6, libxtst6
Recommends: qt6-webengine-dev
Conflicts: wkhtmltopdf-webengine, wkhtmltopdf-webkit, wkhtmltopdf
Replaces: wkhtmltopdf-webengine, wkhtmltopdf-webkit, wkhtmltopdf
Provides: wkhtmltopdf
Description: HTML to PDF converter with Qt6 WebEngine (version 1.0.0)
 wkhtmltopdf Qt6 version with modern Chromium 108+ rendering engine.
 .
 This is the next-generation Qt6 version:
  * Chromium 108+ (latest web standards)
  * Enhanced CSS3 support
  * Better JavaScript performance (V8 engine)
  * Modern security patches
  * Active development
 .
 Backend: Qt6 WebEngine only (WebKit not available in Qt6)
 Size: ~220MB installed
 .
 For Qt5 version with WebKit support, use wkhtmltopdf-webkit instead.
EOF
    elif [ "$VARIANT" = "webengine" ]; then
        # Paquet Qt5 WebEngine
        cat > "${BUILD_DIR}/DEBIAN/control" << EOF
Package: wkhtmltopdf-webengine
Version: ${PKG_VERSION}-ubuntu${UBUNTU_VERSION}
Section: utils
Priority: optional
Architecture: ${ARCH}
Maintainer: wkhtmltopdf Team <support@wkhtmltopdf.org>
Homepage: https://wkhtmltopdf.org
Depends: libqt5core5a, libqt5gui5, libqt5network5, libqt5svg5, libqt5xmlpatterns5, libqt5webenginecore5, libqt5webenginewidgets5, libqt5printsupport5, libqt5positioning5, libssl3 | libssl1.1, libfontconfig1, libfreetype6, libx11-6, libxrender1, libxext6, libc6, libnss3, libxcomposite1, libxcursor1, libxdamage1, libxi6, libxtst6
Recommends: qtwebengine5-dev
Conflicts: wkhtmltopdf-webkit, wkhtmltopdf, wkhtmltopdf-qt6
Replaces: wkhtmltopdf-webkit, wkhtmltopdf
Provides: wkhtmltopdf
Description: HTML to PDF converter with Qt5 WebEngine backend (modern CSS support)
 wkhtmltopdf converts HTML to PDF using Qt5 WebEngine (Chromium 87).
 .
 This variant includes the WebEngine backend for full modern CSS3 support:
  * CSS Flexbox layouts
  * CSS Grid layouts
  * CSS Transforms and Animations
  * Modern CSS gradients and effects
  * Modern JavaScript (ES6+)
 .
 Size: ~200MB installed
 Backend: Qt5 WebEngine (Chromium 87)
 .
 For Qt6 version (Chromium 108+), use wkhtmltopdf-qt6 instead.
 For a smaller installation, use wkhtmltopdf-webkit instead.
EOF
    else
        # Paquet Qt5 WebKit
        cat > "${BUILD_DIR}/DEBIAN/control" << EOF
Package: wkhtmltopdf-webkit
Version: ${PKG_VERSION}-ubuntu${UBUNTU_VERSION}
Section: utils
Priority: optional
Architecture: ${ARCH}
Maintainer: wkhtmltopdf Team <support@wkhtmltopdf.org>
Homepage: https://wkhtmltopdf.org
Depends: libqt5core5a, libqt5gui5, libqt5network5, libqt5svg5, libqt5xmlpatterns5, libqt5webkit5, libssl3 | libssl1.1, libfontconfig1, libfreetype6, libx11-6, libxrender1, libxext6, libc6
Recommends: libqt5webkit5-dev
Conflicts: wkhtmltopdf-webengine, wkhtmltopdf, wkhtmltopdf-qt6
Replaces: wkhtmltopdf-webengine, wkhtmltopdf
Provides: wkhtmltopdf
Description: HTML to PDF converter with Qt5 WebKit backend (lightweight)
 wkhtmltopdf converts HTML to PDF using Qt5 WebKit (legacy).
 .
 This variant includes the WebKit backend - lightweight and fast:
  * Smaller installation (~40MB)
  * Lower memory usage
  * Faster compilation
  * CSS support from ~2012 (no modern flexbox/grid)
 .
 Size: ~40MB installed
 Backend: Qt5 WebKit (Legacy)
 .
 For modern CSS3 support, use wkhtmltopdf-webengine or wkhtmltopdf-qt6 instead.
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
        if [ "$QT_VERSION" = "qt6" ]; then
            cat > /tmp/changelog.Debian.$$ << 'EOFLOG'
wkhtmltopdf (1.0.0) unstable; urgency=medium

  * Qt6 version release
  * Chromium 108+ rendering engine
  * WebEngine only (WebKit not available)

 -- wkhtmltopdf Team <support@wkhtmltopdf.org>  Sat, 09 Nov 2024 17:00:00 +0000
EOFLOG
        else
            cat > /tmp/changelog.Debian.$$ << 'EOFLOG'
wkhtmltopdf (0.13.0) unstable; urgency=medium

  * New release 0.13.0

 -- wkhtmltopdf Team <support@wkhtmltopdf.org>  Sat, 09 Nov 2024 15:00:00 +0000
EOFLOG
        fi
        gzip -9 -c /tmp/changelog.Debian.$$ > debian/usr/share/doc/wkhtmltopdf/changelog.Debian.gz
        rm -f /tmp/changelog.Debian.$$
    fi

    cp debian/usr/share/doc/wkhtmltopdf/copyright "${BUILD_DIR}/usr/share/doc/wkhtmltopdf-${QT_VERSION}-${VARIANT}/"
    cp debian/usr/share/doc/wkhtmltopdf/changelog.Debian.gz "${BUILD_DIR}/usr/share/doc/wkhtmltopdf-${QT_VERSION}-${VARIANT}/"

    # Ajouter un README spécifique
    if [ "$QT_VERSION" = "qt6" ]; then
        cat > "${BUILD_DIR}/usr/share/doc/wkhtmltopdf-${QT_VERSION}-${VARIANT}/README" << 'EOFREADME'
wkhtmltopdf-qt6 (v1.0.0)
========================

This is the Qt6 version of wkhtmltopdf.

Features:
- Qt6 WebEngine (Chromium 108+)
- Latest web standards
- Enhanced security
- Better performance
- Active development

Size: ~220MB installed

Note: WebKit backend is not available in Qt6.
Only WebEngine backend is supported.

For Qt5 version with WebKit support, use wkhtmltopdf-webkit package.
EOFREADME
    elif [ "$VARIANT" = "webengine" ]; then
        cat > "${BUILD_DIR}/usr/share/doc/wkhtmltopdf-${QT_VERSION}-${VARIANT}/README" << 'EOFREADME'
wkhtmltopdf-webengine (Qt5)
============================

This package uses Qt5 WebEngine (Chromium 87) for rendering.

Features:
- Full CSS3 support (Flexbox, Grid, Animations)
- Modern JavaScript (ES6+)
- Web standards circa 2020

Size: ~200MB installed

For newer Chromium engine, use wkhtmltopdf-qt6 (Chromium 108+).
For smaller size, use wkhtmltopdf-webkit (~40MB).
EOFREADME
    else
        cat > "${BUILD_DIR}/usr/share/doc/wkhtmltopdf-${QT_VERSION}-${VARIANT}/README" << 'EOFREADME'
wkhtmltopdf-webkit (Qt5)
=========================

This package uses Qt5 WebKit (legacy) for rendering.

Features:
- Lightweight (~40MB installed)
- Fast and efficient
- CSS support from ~2012

Limitations:
- No modern CSS Flexbox/Grid
- Limited CSS3 support

For modern CSS, use wkhtmltopdf-webengine or wkhtmltopdf-qt6.
EOFREADME
    fi

    # Installer les binaires
    echo "[4/6] Installation des binaires..."
    install -m 755 bin/wkhtmltopdf "${BUILD_DIR}/usr/local/bin/"
    install -m 755 bin/wkhtmltoimage "${BUILD_DIR}/usr/local/bin/"

    # Installer les bibliothèques
    echo "[5/6] Installation des bibliothèques..."
    install -m 644 bin/libwkhtmltox.so.* "${BUILD_DIR}/usr/local/lib/"

    # Créer les liens symboliques pour la bibliothèque
    cd "${BUILD_DIR}/usr/local/lib"
    LIB_FULL=$(ls libwkhtmltox.so.*.*.* 2>/dev/null || ls libwkhtmltox.so.*)
    if [ -n "$LIB_FULL" ]; then
        LIB_MAJ=$(echo $LIB_FULL | sed 's/\.[^.]*$//')
        LIB_MIN=$(echo $LIB_MAJ | sed 's/\.[^.]*$//')
        ln -sf $LIB_FULL $LIB_MAJ 2>/dev/null || true
        ln -sf $LIB_FULL $LIB_MIN 2>/dev/null || true
        ln -sf $LIB_FULL libwkhtmltox.so 2>/dev/null || true
    fi
    cd - >/dev/null

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
echo "Quelle version voulez-vous construire ?"
echo ""
echo "=== Qt5 (version stable 0.13.0) ==="
echo "1) Qt5 + WebEngine uniquement (gros, CSS moderne)"
echo "2) Qt5 + WebKit uniquement (petit, legacy)"
echo "3) Qt5 + Les deux variantes"
echo ""
echo "=== Qt6 (version future 1.0.0) ==="
echo "4) Qt6 + WebEngine (Chromium 108+, WebKit non disponible)"
echo ""
echo "=== Tout construire ==="
echo "5) Construire TOUTES les variantes (Qt5 WebEngine + WebKit + Qt6)"
echo ""
read -p "Choix [1-5]: " CHOICE

case $CHOICE in
    1)
        echo ""
        echo "Construction de Qt5 WebEngine..."
        echo ""
        echo "⚠️  Assurez-vous d'avoir compilé avec:"
        echo "   RENDER_BACKEND=webengine qmake"
        echo "   make clean && make -j\$(nproc)"
        echo ""
        read -p "Continuer ? [y/N] " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            build_package "qt5" "webengine" "webengine"
        fi
        ;;
    2)
        echo ""
        echo "Construction de Qt5 WebKit..."
        echo ""
        echo "⚠️  Assurez-vous d'avoir compilé avec:"
        echo "   RENDER_BACKEND=webkit qmake"
        echo "   make clean && make -j\$(nproc)"
        echo ""
        read -p "Continuer ? [y/N] " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            build_package "qt5" "webkit" "webkit"
        fi
        ;;
    3)
        echo ""
        echo "Construction des DEUX variantes Qt5..."
        echo ""
        echo "Cela nécessite de compiler deux fois le projet !"
        echo ""

        # WebEngine
        echo "=== Étape 1/2: Qt5 WebEngine ==="
        echo "Compilation avec WebEngine..."
        make clean || true
        RENDER_BACKEND=webengine qmake
        make -j$(nproc)
        build_package "qt5" "webengine" "webengine"

        # WebKit
        echo ""
        echo "=== Étape 2/2: Qt5 WebKit ==="
        echo "Compilation avec WebKit..."
        make clean || true
        RENDER_BACKEND=webkit qmake
        make -j$(nproc)
        build_package "qt5" "webkit" "webkit"
        ;;
    4)
        echo ""
        echo "Construction de Qt6 WebEngine..."
        echo ""
        echo "⚠️  Assurez-vous d'avoir:"
        echo "   - Qt6 installé (Ubuntu 24.04+)"
        echo "   - Compilé avec: qmake6 && make clean && make -j\$(nproc)"
        echo ""
        echo "Note: WebKit n'est PAS disponible en Qt6"
        echo ""
        read -p "Continuer ? [y/N] " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            # Vérifier qmake6
            if ! command -v qmake6 >/dev/null 2>&1; then
                echo "❌ Erreur: qmake6 non trouvé"
                echo "Installez Qt6 avec: ./install-qt6-ubuntu.sh"
                exit 1
            fi

            make clean || true
            qmake6
            make -j$(nproc)
            build_package "qt6" "webengine" "webengine"
        fi
        ;;
    5)
        echo ""
        echo "Construction de TOUTES les variantes..."
        echo ""
        echo "Cela va compiler et packager:"
        echo "  - Qt5 WebEngine"
        echo "  - Qt5 WebKit"
        echo "  - Qt6 WebEngine"
        echo ""
        echo "Durée estimée: 30-60 minutes"
        echo ""
        read -p "Confirmer ? [y/N] " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            # Qt5 WebEngine
            echo ""
            echo "=== 1/3: Qt5 WebEngine ==="
            make clean || true
            RENDER_BACKEND=webengine qmake
            make -j$(nproc)
            build_package "qt5" "webengine" "webengine"

            # Qt5 WebKit
            echo ""
            echo "=== 2/3: Qt5 WebKit ==="
            make clean || true
            RENDER_BACKEND=webkit qmake
            make -j$(nproc)
            build_package "qt5" "webkit" "webkit"

            # Qt6 WebEngine
            echo ""
            echo "=== 3/3: Qt6 WebEngine ==="
            if command -v qmake6 >/dev/null 2>&1; then
                make clean || true
                qmake6
                make -j$(nproc)
                build_package "qt6" "webengine" "webengine"
            else
                echo "⚠️  Qt6 non disponible, skipping..."
                echo "   Installez Qt6 avec: ./install-qt6-ubuntu.sh"
            fi
        fi
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
ls -lh wkhtmltopdf-*.deb 2>/dev/null || echo "  (aucun)"
echo ""
echo "Pour installer:"
echo "  Qt5 WebEngine: sudo dpkg -i wkhtmltopdf-webengine_${VERSION}-ubuntu${UBUNTU_VERSION}_${ARCH}.deb"
echo "  Qt5 WebKit:    sudo dpkg -i wkhtmltopdf-webkit_${VERSION}-ubuntu${UBUNTU_VERSION}_${ARCH}.deb"
echo "  Qt6 WebEngine: sudo dpkg -i wkhtmltopdf-qt6_${VERSION_QT6}-ubuntu${UBUNTU_VERSION}_${ARCH}.deb"
echo ""
echo "Note: Une seule variante peut être installée à la fois (conflict)"
echo ""
