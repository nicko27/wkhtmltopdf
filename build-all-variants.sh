#!/bin/bash
# Script complet pour compiler TOUTES les variantes et générer les .deb et tests
# Crée: Qt5 WebKit, Qt5 WebEngine, Qt6 WebEngine (si disponible)

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m'

VERSION_QT5="0.13.0"
VERSION_QT6="1.0.0"
ARCH=$(dpkg --print-architecture 2>/dev/null || echo "amd64")
UBUNTU_VERSION=$(lsb_release -rs 2>/dev/null || echo "22.04")
BUILD_JOBS=$(nproc)

# Dossiers de backup pour les binaires
BACKUP_DIR="build-variants-backup"
mkdir -p "$BACKUP_DIR"

echo -e "${CYAN}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${CYAN}║  Build Complet de Toutes les Variantes wkhtmltopdf        ║${NC}"
echo -e "${CYAN}╚════════════════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "${BLUE}Architecture:${NC} ${ARCH}"
echo -e "${BLUE}Ubuntu:${NC} ${UBUNTU_VERSION}"
echo -e "${BLUE}Jobs:${NC} ${BUILD_JOBS}"
echo ""

# Fonction pour afficher une section
section() {
    echo ""
    echo -e "${MAGENTA}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${MAGENTA}  $1${NC}"
    echo -e "${MAGENTA}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
}

# Fonction pour vérifier les dépendances
check_dependencies() {
    local VARIANT=$1

    section "Vérification des dépendances pour $VARIANT"

    if [ "$VARIANT" = "qt6" ]; then
        # Qt6
        if ! command -v qmake6 >/dev/null 2>&1; then
            echo -e "${RED}✗ qmake6 non trouvé${NC}"
            echo -e "${YELLOW}  Installez Qt6: ./install-qt6-ubuntu.sh${NC}"
            return 1
        fi

        # Vérifier version Ubuntu
        if [ $(echo "$UBUNTU_VERSION" | cut -d. -f1) -lt 24 ]; then
            echo -e "${RED}✗ Qt6 nécessite Ubuntu 24.04+${NC}"
            echo -e "${YELLOW}  Votre version: $UBUNTU_VERSION${NC}"
            return 1
        fi

        echo -e "${GREEN}✓ qmake6 disponible${NC}"
        qmake6 --version | head -1
    else
        # Qt5
        if ! command -v qmake >/dev/null 2>&1; then
            echo -e "${RED}✗ qmake non trouvé${NC}"
            echo -e "${YELLOW}  Installez Qt5: ./install-ubuntu.sh${NC}"
            return 1
        fi

        echo -e "${GREEN}✓ qmake disponible${NC}"
        qmake --version | head -1

        # Vérifier les libs selon le backend
        if [ "$VARIANT" = "webengine" ]; then
            if ! dpkg -l | grep -q libqt5webenginecore5; then
                echo -e "${YELLOW}⚠  libqt5webenginecore5 peut être manquant${NC}"
            else
                echo -e "${GREEN}✓ libqt5webenginecore5 installé${NC}"
            fi
        elif [ "$VARIANT" = "webkit" ]; then
            if ! dpkg -l | grep -q libqt5webkit5; then
                echo -e "${YELLOW}⚠  libqt5webkit5 peut être manquant${NC}"
            else
                echo -e "${GREEN}✓ libqt5webkit5 installé${NC}"
            fi
        fi
    fi

    return 0
}

# Fonction pour compiler une variante
compile_variant() {
    local VARIANT=$1
    local QT_VERSION=$2

    section "Compilation: $VARIANT ($QT_VERSION)"

    # Nettoyer
    echo -e "${BLUE}[1/4]${NC} Nettoyage..."
    make clean >/dev/null 2>&1 || true
    rm -rf bin/

    # Configurer avec qmake
    echo -e "${BLUE}[2/4]${NC} Configuration avec qmake..."

    if [ "$QT_VERSION" = "qt6" ]; then
        # Qt6 (WebEngine uniquement)
        qmake6
    else
        # Qt5 (avec backend spécifique)
        RENDER_BACKEND=$VARIANT qmake
    fi

    if [ $? -ne 0 ]; then
        echo -e "${RED}✗ Erreur lors de la configuration${NC}"
        return 1
    fi

    # Compiler
    echo -e "${BLUE}[3/4]${NC} Compilation (${BUILD_JOBS} jobs)..."
    make -j${BUILD_JOBS}

    if [ $? -ne 0 ]; then
        echo -e "${RED}✗ Erreur lors de la compilation${NC}"
        return 1
    fi

    # Vérifier les binaires
    echo -e "${BLUE}[4/4]${NC} Vérification des binaires..."

    if [ ! -f "bin/wkhtmltopdf" ]; then
        echo -e "${RED}✗ bin/wkhtmltopdf non créé${NC}"
        return 1
    fi

    if [ ! -f "bin/wkhtmltoimage" ]; then
        echo -e "${RED}✗ bin/wkhtmltoimage non créé${NC}"
        return 1
    fi

    # Tester la version
    echo ""
    echo -e "${GREEN}✓ Compilation réussie${NC}"
    echo ""
    echo "Version:"
    ./bin/wkhtmltopdf --version | head -3

    # Backup des binaires
    echo ""
    echo -e "${BLUE}Backup des binaires...${NC}"

    if [ "$QT_VERSION" = "qt6" ]; then
        BACKUP_NAME="qt6-webengine"
    else
        BACKUP_NAME="qt5-$VARIANT"
    fi

    mkdir -p "$BACKUP_DIR/$BACKUP_NAME/bin"
    cp -r bin/* "$BACKUP_DIR/$BACKUP_NAME/bin/"

    echo -e "${GREEN}✓ Binaires sauvegardés dans: $BACKUP_DIR/$BACKUP_NAME/${NC}"

    return 0
}

# Fonction pour créer un .deb
create_deb() {
    local VARIANT=$1
    local QT_VERSION=$2

    section "Création du .deb: $VARIANT ($QT_VERSION)"

    # Restaurer les binaires depuis le backup
    if [ "$QT_VERSION" = "qt6" ]; then
        BACKUP_NAME="qt6-webengine"
    else
        BACKUP_NAME="qt5-$VARIANT"
    fi

    if [ ! -d "$BACKUP_DIR/$BACKUP_NAME/bin" ]; then
        echo -e "${RED}✗ Binaires non trouvés dans backup${NC}"
        return 1
    fi

    echo -e "${BLUE}Restauration des binaires depuis backup...${NC}"
    rm -rf bin/
    cp -r "$BACKUP_DIR/$BACKUP_NAME/bin" .

    # Créer le .deb avec build-deb-all.sh
    echo -e "${BLUE}Génération du paquet .deb...${NC}"
    echo ""

    # Appeler la fonction build_package depuis build-deb-all.sh
    # On va extraire et exécuter la fonction

    if [ "$QT_VERSION" = "qt6" ]; then
        PKG_VERSION="$VERSION_QT6"
        PKG_NAME="wkhtmltopdf-qt6_${PKG_VERSION}-ubuntu${UBUNTU_VERSION}_${ARCH}.deb"
    else
        PKG_VERSION="$VERSION_QT5"
        PKG_NAME="wkhtmltopdf-${VARIANT}_${PKG_VERSION}-ubuntu${UBUNTU_VERSION}_${ARCH}.deb"
    fi

    # Utiliser directement build-deb-all.sh en mode automatique
    # On va créer le .deb manuellement ici pour éviter l'interaction

    BUILD_DIR="debian-build-${QT_VERSION}-${VARIANT}"

    # Nettoyer
    rm -rf "${BUILD_DIR}"

    # Créer la structure
    echo -e "${BLUE}[1/5] Structure du paquet...${NC}"
    mkdir -p "${BUILD_DIR}/DEBIAN"
    mkdir -p "${BUILD_DIR}/usr/local/bin"
    mkdir -p "${BUILD_DIR}/usr/local/lib"
    mkdir -p "${BUILD_DIR}/usr/local/include/wkhtmltox"
    mkdir -p "${BUILD_DIR}/usr/share/doc/wkhtmltopdf-${QT_VERSION}-${VARIANT}"
    mkdir -p "${BUILD_DIR}/etc/ld.so.conf.d"

    # Créer le control
    echo -e "${BLUE}[2/5] Métadonnées...${NC}"

    if [ "$QT_VERSION" = "qt6" ]; then
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
Provides: wkhtmltopdf
Description: HTML to PDF converter with Qt6 WebEngine (v1.0.0)
 wkhtmltopdf Qt6 with Chromium 108+ rendering engine.
EOF
    elif [ "$VARIANT" = "webengine" ]; then
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
Provides: wkhtmltopdf
Description: HTML to PDF converter with Qt5 WebEngine (v0.13.0)
 wkhtmltopdf with Chromium 87 rendering engine and modern CSS support.
EOF
    else
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
Provides: wkhtmltopdf
Description: HTML to PDF converter with Qt5 WebKit (v0.13.0)
 wkhtmltopdf with lightweight WebKit backend (~40MB).
EOF
    fi

    # Scripts postinst/postrm
    cat > "${BUILD_DIR}/DEBIAN/postinst" << 'EOF'
#!/bin/sh
set -e
if [ -x /sbin/ldconfig ]; then /sbin/ldconfig; fi
exit 0
EOF

    cat > "${BUILD_DIR}/DEBIAN/postrm" << 'EOF'
#!/bin/sh
set -e
if [ "$1" = "remove" ] || [ "$1" = "purge" ]; then
    if [ -x /sbin/ldconfig ]; then /sbin/ldconfig; fi
fi
exit 0
EOF

    chmod 755 "${BUILD_DIR}/DEBIAN/postinst" "${BUILD_DIR}/DEBIAN/postrm"

    # Documentation
    echo -e "${BLUE}[3/5] Documentation...${NC}"
    mkdir -p debian/usr/share/doc/wkhtmltopdf

    if [ ! -f "debian/usr/share/doc/wkhtmltopdf/copyright" ]; then
        cat > debian/usr/share/doc/wkhtmltopdf/copyright << 'EOFCOPY'
Format: https://www.debian.org/doc/packaging-manuals/copyright-format/1.0/
Upstream-Name: wkhtmltopdf
Source: https://github.com/wkhtmltopdf/wkhtmltopdf
Files: *
Copyright: 2010-2020 wkhtmltopdf authors
License: LGPL-3+
EOFCOPY
    fi

    cp debian/usr/share/doc/wkhtmltopdf/copyright "${BUILD_DIR}/usr/share/doc/wkhtmltopdf-${QT_VERSION}-${VARIANT}/"

    # Binaires
    echo -e "${BLUE}[4/5] Installation des binaires...${NC}"
    install -m 755 bin/wkhtmltopdf "${BUILD_DIR}/usr/local/bin/"
    install -m 755 bin/wkhtmltoimage "${BUILD_DIR}/usr/local/bin/"

    # Bibliothèques
    install -m 644 bin/libwkhtmltox.so.* "${BUILD_DIR}/usr/local/lib/"

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

    # ldconfig
    echo "/usr/local/lib" > "${BUILD_DIR}/etc/ld.so.conf.d/wkhtmltopdf.conf"

    # Taille
    INSTALLED_SIZE=$(du -sk "${BUILD_DIR}/usr" "${BUILD_DIR}/etc" 2>/dev/null | awk '{sum+=$1} END {print sum}')
    echo "Installed-Size: ${INSTALLED_SIZE}" >> "${BUILD_DIR}/DEBIAN/control"

    # Construire
    echo -e "${BLUE}[5/5] Construction du .deb...${NC}"
    dpkg-deb --build "${BUILD_DIR}" "${PKG_NAME}"

    if [ -f "${PKG_NAME}" ]; then
        SIZE=$(du -h "${PKG_NAME}" | cut -f1)
        echo ""
        echo -e "${GREEN}✓ Paquet créé: ${PKG_NAME}${NC}"
        echo -e "${BLUE}  Taille: ${SIZE}${NC}"
        return 0
    else
        echo -e "${RED}✗ Erreur lors de la création du .deb${NC}"
        return 1
    fi
}

# Fonction pour tester une variante
test_variant() {
    local VARIANT=$1
    local QT_VERSION=$2

    section "Test: $VARIANT ($QT_VERSION)"

    # Restaurer les binaires
    if [ "$QT_VERSION" = "qt6" ]; then
        BACKUP_NAME="qt6-webengine"
        OUTPUT_PDF="test-webengine-qt6.pdf"
    else
        BACKUP_NAME="qt5-$VARIANT"
        OUTPUT_PDF="test-$VARIANT.pdf"
    fi

    if [ ! -d "$BACKUP_DIR/$BACKUP_NAME/bin" ]; then
        echo -e "${RED}✗ Binaires non trouvés${NC}"
        return 1
    fi

    rm -rf bin/
    cp -r "$BACKUP_DIR/$BACKUP_NAME/bin" .

    # Créer dossier résultats
    mkdir -p test-results

    # Vérifier que le HTML existe
    if [ ! -f "test-full-css.html" ]; then
        echo -e "${RED}✗ test-full-css.html non trouvé${NC}"
        return 1
    fi

    echo -e "${BLUE}Conversion HTML → PDF...${NC}"

    if [ "$VARIANT" = "webkit" ] || [ "$VARIANT" = "webengine" ]; then
        ./bin/wkhtmltopdf --render-backend "$VARIANT" \
            --enable-local-file-access \
            test-full-css.html "test-results/$OUTPUT_PDF" 2>&1 | tail -3
    else
        # Qt6
        ./bin/wkhtmltopdf \
            --enable-local-file-access \
            test-full-css.html "test-results/$OUTPUT_PDF" 2>&1 | tail -3
    fi

    if [ -f "test-results/$OUTPUT_PDF" ]; then
        SIZE=$(du -h "test-results/$OUTPUT_PDF" | cut -f1)
        echo ""
        echo -e "${GREEN}✓ PDF généré: test-results/$OUTPUT_PDF${NC}"
        echo -e "${BLUE}  Taille: ${SIZE}${NC}"
        return 0
    else
        echo -e "${RED}✗ Erreur lors de la génération du PDF${NC}"
        return 1
    fi
}

# Menu principal
section "Menu Principal"

echo "Que voulez-vous faire ?"
echo ""
echo -e "${GREEN}1)${NC} Compiler et tester TOUTES les variantes (recommandé)"
echo -e "${GREEN}2)${NC} Compiler uniquement (sans .deb ni tests)"
echo -e "${GREEN}3)${NC} Compiler + créer les .deb (sans tests)"
echo -e "${GREEN}4)${NC} Compiler + tests (sans .deb)"
echo -e "${GREEN}5)${NC} Choisir variantes spécifiques"
echo ""
read -p "Choix [1-5]: " MAIN_CHOICE

# Variables de contrôle
DO_COMPILE=true
DO_DEB=true
DO_TEST=true
ALL_VARIANTS=true

case $MAIN_CHOICE in
    1)
        # Tout faire
        echo ""
        echo -e "${GREEN}Mode complet activé${NC}"
        ;;
    2)
        # Compilation uniquement
        DO_DEB=false
        DO_TEST=false
        echo ""
        echo -e "${YELLOW}Mode: Compilation uniquement${NC}"
        ;;
    3)
        # Compilation + .deb
        DO_TEST=false
        echo ""
        echo -e "${YELLOW}Mode: Compilation + .deb${NC}"
        ;;
    4)
        # Compilation + tests
        DO_DEB=false
        echo ""
        echo -e "${YELLOW}Mode: Compilation + tests${NC}"
        ;;
    5)
        # Choix spécifiques
        ALL_VARIANTS=false
        echo ""
        echo "Choisissez les variantes:"
        echo "1) Qt5 WebKit"
        echo "2) Qt5 WebEngine"
        echo "3) Qt6 WebEngine"
        echo "4) Qt5 WebKit + WebEngine"
        echo "5) Toutes"
        read -p "Choix [1-5]: " VARIANT_CHOICE
        ;;
    *)
        echo -e "${RED}Choix invalide${NC}"
        exit 1
        ;;
esac

# Définir les variantes à construire
VARIANTS_TO_BUILD=()

if [ "$ALL_VARIANTS" = true ] || [ "$VARIANT_CHOICE" = "5" ]; then
    VARIANTS_TO_BUILD=("webkit:qt5" "webengine:qt5" "webengine:qt6")
elif [ "$VARIANT_CHOICE" = "1" ]; then
    VARIANTS_TO_BUILD=("webkit:qt5")
elif [ "$VARIANT_CHOICE" = "2" ]; then
    VARIANTS_TO_BUILD=("webengine:qt5")
elif [ "$VARIANT_CHOICE" = "3" ]; then
    VARIANTS_TO_BUILD=("webengine:qt6")
elif [ "$VARIANT_CHOICE" = "4" ]; then
    VARIANTS_TO_BUILD=("webkit:qt5" "webengine:qt5")
fi

# Résumé
echo ""
section "Résumé"
echo -e "${BLUE}Variantes à construire:${NC}"
for variant in "${VARIANTS_TO_BUILD[@]}"; do
    echo "  • $variant"
done
echo ""
echo -e "${BLUE}Actions:${NC}"
echo "  • Compilation: ${DO_COMPILE}"
echo "  • Création .deb: ${DO_DEB}"
echo "  • Tests PDF: ${DO_TEST}"
echo ""
read -p "Continuer ? [y/N] " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Annulé"
    exit 0
fi

# Début du build
START_TIME=$(date +%s)

section "Démarrage du Build"

# Compteurs
TOTAL=${#VARIANTS_TO_BUILD[@]}
CURRENT=0
SUCCESS=0
FAILED=0

# Construire chaque variante
for variant_info in "${VARIANTS_TO_BUILD[@]}"; do
    CURRENT=$((CURRENT + 1))
    VARIANT=$(echo $variant_info | cut -d: -f1)
    QT_VER=$(echo $variant_info | cut -d: -f2)

    echo ""
    echo -e "${CYAN}═══════════════════════════════════════════════════════════${NC}"
    echo -e "${CYAN}  [$CURRENT/$TOTAL] $VARIANT ($QT_VER)${NC}"
    echo -e "${CYAN}═══════════════════════════════════════════════════════════${NC}"
    echo ""

    # Vérifier les dépendances
    if ! check_dependencies "$VARIANT" "$QT_VER"; then
        echo -e "${YELLOW}⚠  Skipping $VARIANT ($QT_VER) - dépendances manquantes${NC}"
        FAILED=$((FAILED + 1))
        continue
    fi

    # Compilation
    if [ "$DO_COMPILE" = true ]; then
        if ! compile_variant "$VARIANT" "$QT_VER"; then
            echo -e "${RED}✗ Échec de la compilation${NC}"
            FAILED=$((FAILED + 1))
            continue
        fi
    fi

    # Création .deb
    if [ "$DO_DEB" = true ]; then
        if ! create_deb "$VARIANT" "$QT_VER"; then
            echo -e "${YELLOW}⚠  Échec création .deb (compilation OK)${NC}"
        fi
    fi

    # Tests
    if [ "$DO_TEST" = true ]; then
        if ! test_variant "$VARIANT" "$QT_VER"; then
            echo -e "${YELLOW}⚠  Échec test PDF (compilation OK)${NC}"
        fi
    fi

    SUCCESS=$((SUCCESS + 1))
    echo ""
    echo -e "${GREEN}✓ $VARIANT ($QT_VER) terminé${NC}"
done

# Fin
END_TIME=$(date +%s)
DURATION=$((END_TIME - START_TIME))
MINUTES=$((DURATION / 60))
SECONDS=$((DURATION % 60))

section "Résultats Finaux"

echo -e "${BLUE}Temps total:${NC} ${MINUTES}m ${SECONDS}s"
echo -e "${GREEN}Succès:${NC} $SUCCESS/$TOTAL"
echo -e "${RED}Échecs:${NC} $FAILED/$TOTAL"
echo ""

# Lister les fichiers générés
if [ "$DO_DEB" = true ]; then
    echo -e "${BLUE}Paquets .deb créés:${NC}"
    ls -lh wkhtmltopdf-*.deb 2>/dev/null | awk '{print "  " $9 " (" $5 ")"}'
    echo ""
fi

if [ "$DO_TEST" = true ]; then
    echo -e "${BLUE}PDFs de test créés:${NC}"
    ls -lh test-results/*.pdf 2>/dev/null | awk '{print "  " $9 " (" $5 ")"}'
    echo ""
fi

echo -e "${BLUE}Binaires sauvegardés dans:${NC} $BACKUP_DIR/"
echo ""

# Instructions finales
echo -e "${CYAN}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${CYAN}║  Build Terminé !                                           ║${NC}"
echo -e "${CYAN}╚════════════════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "${BLUE}Prochaines étapes:${NC}"
echo ""
echo "1. Installer un paquet .deb:"
echo "   sudo dpkg -i wkhtmltopdf-webengine_*.deb"
echo ""
echo "2. Comparer les PDFs de test:"
echo "   ls -lh test-results/"
echo ""
echo "3. Vérifier les dépendances:"
echo "   ./check-dependencies.sh"
echo ""
