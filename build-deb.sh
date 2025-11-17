#!/bin/bash
# Script unifié de build pour wkhtmltopdf
# - Ubuntu 22.04 → Qt5 WebKit ou WebEngine
# - Ubuntu 24.04 → Qt6 WebEngine

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo "=========================================="
echo "🚀 wkhtmltopdf - Build Debian Package"
echo "=========================================="
echo ""

# Détection automatique
UBUNTU_VERSION=$(lsb_release -rs 2>/dev/null || echo "unknown")
ARCH=$(dpkg --print-architecture 2>/dev/null || uname -m)

echo "Système détecté:"
echo "  Ubuntu: $UBUNTU_VERSION"
echo "  Architecture: $ARCH"
echo ""

# Vérifier qu'on est dans le bon répertoire
if [ ! -f "wkhtmltopdf.pro" ]; then
    echo -e "${RED}❌ Erreur: wkhtmltopdf.pro introuvable${NC}"
    echo "Lancez ce script depuis le répertoire racine de wkhtmltopdf"
    exit 1
fi

# Configuration selon la version Ubuntu
if [ "$UBUNTU_VERSION" = "22.04" ]; then
    echo -e "${BLUE}📦 Configuration pour Ubuntu 22.04 (Jammy)${NC}"
    QT_VERSION="5"

    echo ""
    echo "Quel backend Qt5 voulez-vous ?"
    echo "1) webkit    - Petit (~40MB), rapide, CSS limité"
    echo "2) webengine - Gros (~200MB), CSS moderne (Flexbox, Grid)"
    read -p "Votre choix (1 ou 2): " CHOICE

    if [ "$CHOICE" = "1" ]; then
        BACKEND="webkit"
        PKG_NAME="wkhtmltopdf-qt5-webkit"
        echo -e "${GREEN}→ Qt5 WebKit sélectionné${NC}"
    else
        BACKEND="webengine"
        PKG_NAME="wkhtmltopdf-qt5-webengine"
        echo -e "${GREEN}→ Qt5 WebEngine sélectionné${NC}"
    fi

elif [ "$UBUNTU_VERSION" = "24.04" ]; then
    echo -e "${BLUE}📦 Configuration pour Ubuntu 24.04 (Noble)${NC}"
    QT_VERSION="6"
    BACKEND="webengine"
    PKG_NAME="wkhtmltopdf-qt6-webengine"
    echo -e "${GREEN}→ Qt6 WebEngine (seule option)${NC}"

else
    echo -e "${YELLOW}⚠ Version Ubuntu non reconnue: $UBUNTU_VERSION${NC}"
    echo ""
    echo "Veuillez choisir manuellement:"
    echo "1) Qt5 WebKit (Ubuntu 22.04)"
    echo "2) Qt5 WebEngine (Ubuntu 22.04)"
    echo "3) Qt6 WebEngine (Ubuntu 24.04)"
    read -p "Votre choix (1-3): " CHOICE

    case $CHOICE in
        1)
            QT_VERSION="5"
            BACKEND="webkit"
            PKG_NAME="wkhtmltopdf-qt5-webkit"
            ;;
        2)
            QT_VERSION="5"
            BACKEND="webengine"
            PKG_NAME="wkhtmltopdf-qt5-webengine"
            ;;
        3)
            QT_VERSION="6"
            BACKEND="webengine"
            PKG_NAME="wkhtmltopdf-qt6-webengine"
            ;;
        *)
            echo -e "${RED}Choix invalide${NC}"
            exit 1
            ;;
    esac
fi

echo ""
echo "Configuration finale:"
echo "  Qt Version: $QT_VERSION"
echo "  Backend: $BACKEND"
echo "  Package: $PKG_NAME"
echo ""

# Installation des dépendances
echo -e "${BLUE}[1/7] Vérification des dépendances...${NC}"
echo ""

MISSING_DEPS=()

if [ "$QT_VERSION" = "5" ]; then
    # Dépendances Qt5
    DEPS="build-essential qt5-qmake qtbase5-dev libqt5core5a libqt5gui5 libqt5network5 libqt5svg5 libqt5xmlpatterns5"

    if [ "$BACKEND" = "webkit" ]; then
        DEPS="$DEPS libqt5webkit5 libqt5webkit5-dev"
    else
        DEPS="$DEPS qtwebengine5-dev libqt5webenginecore5 libqt5webenginewidgets5 libqt5printsupport5 libqt5positioning5"
    fi
else
    # Dépendances Qt6
    DEPS="build-essential qt6-base-dev qt6-webengine-dev libqt6core6 libqt6gui6 libqt6webenginecore6 libqt6webenginewidgets6"
fi

DEPS="$DEPS libssl-dev libfontconfig1-dev libfreetype6-dev libx11-dev libxrender-dev libxext-dev"

for dep in $DEPS; do
    if ! dpkg -l | grep -q "^ii  $dep "; then
        MISSING_DEPS+=("$dep")
    fi
done

if [ ${#MISSING_DEPS[@]} -gt 0 ]; then
    echo -e "${YELLOW}Dépendances manquantes:${NC}"
    echo "  ${MISSING_DEPS[@]}"
    echo ""
    read -p "Installer automatiquement? (y/N) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        sudo apt-get update
        sudo apt-get install -y ${MISSING_DEPS[@]}
    else
        echo -e "${RED}Installation annulée. Installez les dépendances manuellement.${NC}"
        exit 1
    fi
fi

echo -e "${GREEN}✓ Toutes les dépendances sont installées${NC}"
echo ""

# Nettoyage
echo -e "${BLUE}[2/7] Nettoyage du build précédent...${NC}"
make distclean 2>/dev/null || true
rm -rf bin/ lib/ build/ .qmake.stash Makefile */Makefile */*/Makefile
rm -rf moc_* ui_* qrc_* *.o */*.o */*/*.o
rm -rf debian-build-*/
echo -e "${GREEN}✓ Nettoyage terminé${NC}"
echo ""

# Préparation
echo -e "${BLUE}[3/7] Préparation des répertoires...${NC}"
mkdir -p bin lib
echo -e "${GREEN}✓ Répertoires créés${NC}"
echo ""

# Configuration
echo -e "${BLUE}[4/7] Configuration avec qmake...${NC}"

if [ "$QT_VERSION" = "5" ]; then
    QMAKE="qmake"
else
    QMAKE="qmake6"
fi

if ! command -v $QMAKE &> /dev/null; then
    echo -e "${RED}❌ $QMAKE introuvable${NC}"
    exit 1
fi

export RENDER_BACKEND=$BACKEND
if ! $QMAKE; then
    echo -e "${RED}❌ Configuration échouée${NC}"
    exit 1
fi

echo -e "${GREEN}✓ Configuration réussie${NC}"
echo ""

# Compilation de la bibliothèque
echo -e "${BLUE}[5/7] Compilation de libwkhtmltox...${NC}"
cd src/lib
if ! make -j$(nproc); then
    echo -e "${RED}❌ Compilation de la bibliothèque échouée${NC}"
    exit 1
fi
cd ../..

if [ ! -f "bin/libwkhtmltox.so" ] && [ ! -f "bin/libwkhtmltox.so.0" ]; then
    echo -e "${RED}❌ libwkhtmltox.so non créée${NC}"
    exit 1
fi

echo -e "${GREEN}✓ Bibliothèque compilée${NC}"
echo ""

# Compilation des exécutables
echo -e "${BLUE}[6/7] Compilation des exécutables...${NC}"
cd src/pdf && make -j$(nproc) && cd ../..
cd src/image && make -j$(nproc) && cd ../..
echo -e "${GREEN}✓ Exécutables compilés${NC}"
echo ""

# Création du package Debian
echo -e "${BLUE}[7/7] Création du package Debian...${NC}"

VERSION="0.13.0"
BUILD_DIR="debian-build-${PKG_NAME}"
DEB_FILE="${PKG_NAME}_${VERSION}-ubuntu${UBUNTU_VERSION}_${ARCH}.deb"

rm -rf "$BUILD_DIR"
mkdir -p "$BUILD_DIR/DEBIAN"
mkdir -p "$BUILD_DIR/usr/local/bin"
mkdir -p "$BUILD_DIR/usr/local/lib"
mkdir -p "$BUILD_DIR/usr/local/include/wkhtmltox"
mkdir -p "$BUILD_DIR/etc/ld.so.conf.d"

# Fichier control
cat > "$BUILD_DIR/DEBIAN/control" << EOF
Package: $PKG_NAME
Version: $VERSION-ubuntu$UBUNTU_VERSION
Section: utils
Priority: optional
Architecture: $ARCH
Maintainer: wkhtmltopdf Team <support@wkhtmltopdf.org>
Homepage: https://wkhtmltopdf.org
EOF

# Dépendances selon la configuration
if [ "$QT_VERSION" = "5" ] && [ "$BACKEND" = "webkit" ]; then
    cat >> "$BUILD_DIR/DEBIAN/control" << EOF
Depends: libqt5core5a, libqt5gui5, libqt5network5, libqt5svg5, libqt5xmlpatterns5, libqt5webkit5, libssl3, libfontconfig1, libfreetype6, libx11-6, libxrender1, libxext6, libc6
Description: HTML to PDF converter - Qt5 WebKit
 Lightweight version with Qt5 WebKit backend.
 Package size: ~40MB
 CSS support: Basic (CSS 2.1 + partial CSS3)
EOF

elif [ "$QT_VERSION" = "5" ] && [ "$BACKEND" = "webengine" ]; then
    cat >> "$BUILD_DIR/DEBIAN/control" << EOF
Depends: libqt5core5a, libqt5gui5, libqt5network5, libqt5svg5, libqt5xmlpatterns5, libqt5webenginecore5, libqt5webenginewidgets5, libqt5printsupport5, libqt5positioning5, libssl3, libfontconfig1, libfreetype6, libx11-6, libxrender1, libxext6, libc6, libnss3, libxcomposite1, libxcursor1, libxdamage1, libxi6, libxtst6
Description: HTML to PDF converter - Qt5 WebEngine
 Modern version with Qt5 WebEngine (Chromium) backend.
 Package size: ~200MB
 CSS support: Full CSS3 (Flexbox, Grid, Transforms)
EOF

else
    cat >> "$BUILD_DIR/DEBIAN/control" << EOF
Depends: libqt6core6, libqt6gui6, libqt6network6, libqt6webenginecore6, libqt6webenginewidgets6, libqt6printsupport6, libssl3, libfontconfig1, libfreetype6, libx11-6, libxrender1, libxext6, libc6, libnss3, libxcomposite1, libxcursor1, libxdamage1, libxi6, libxtst6
Description: HTML to PDF converter - Qt6 WebEngine
 Latest version with Qt6 WebEngine (Chromium) backend.
 Package size: ~200MB
 CSS support: Full CSS3 (Flexbox, Grid, Transforms)
EOF
fi

# Copier les fichiers
echo "Copie des binaires..."
cp -a bin/wkhtmltopdf "$BUILD_DIR/usr/local/bin/"
cp -a bin/wkhtmltoimage "$BUILD_DIR/usr/local/bin/"
cp -a bin/libwkhtmltox.so* "$BUILD_DIR/usr/local/lib/" 2>/dev/null || true

# Headers
cp -a include/wkhtmltox/*.h "$BUILD_DIR/usr/local/include/wkhtmltox/" 2>/dev/null || true

# Configuration ldconfig
echo "/usr/local/lib" > "$BUILD_DIR/etc/ld.so.conf.d/wkhtmltopdf.conf"

# Permissions
chmod 755 "$BUILD_DIR/usr/local/bin/"*
chmod 644 "$BUILD_DIR/usr/local/lib/"*

# Script postinst
cat > "$BUILD_DIR/DEBIAN/postinst" << 'EOFPOST'
#!/bin/bash
ldconfig
EOFPOST
chmod 755 "$BUILD_DIR/DEBIAN/postinst"

# Construire le .deb
dpkg-deb --build "$BUILD_DIR" "$DEB_FILE"

echo ""
echo "=========================================="
echo -e "${GREEN}✅ BUILD RÉUSSI!${NC}"
echo "=========================================="
echo ""
echo "Package créé: $DEB_FILE"
ls -lh "$DEB_FILE"
echo ""
echo -e "${BLUE}Pour installer:${NC}"
echo "  sudo dpkg -i $DEB_FILE"
echo "  sudo apt-get install -f"
echo ""
echo -e "${BLUE}Pour tester:${NC}"
echo "  wkhtmltopdf --version"
echo "  echo '<h1>Test</h1>' > test.html"
echo "  wkhtmltopdf test.html test.pdf"
echo ""
