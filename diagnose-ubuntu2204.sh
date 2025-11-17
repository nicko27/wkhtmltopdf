#!/bin/bash
# Script de diagnostic pour les problèmes de dépendances wkhtmltopdf sur Ubuntu 22.04

set +e  # Ne pas arrêter en cas d'erreur

echo "=========================================="
echo "🔍 Diagnostic wkhtmltopdf - Ubuntu 22.04"
echo "=========================================="
echo ""

# Couleurs
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Vérifier la version d'Ubuntu
echo -e "${BLUE}1. Vérification de la version Ubuntu${NC}"
UBUNTU_VERSION=$(lsb_release -rs 2>/dev/null || echo "unknown")
UBUNTU_CODENAME=$(lsb_release -cs 2>/dev/null || echo "unknown")
echo "   Version: $UBUNTU_VERSION ($UBUNTU_CODENAME)"

if [ "$UBUNTU_VERSION" != "22.04" ]; then
    echo -e "${YELLOW}   ⚠ Ce script est optimisé pour Ubuntu 22.04${NC}"
fi
echo ""

# Vérifier si wkhtmltopdf est installé
echo -e "${BLUE}2. Vérification de l'installation wkhtmltopdf${NC}"
if command -v wkhtmltopdf &> /dev/null; then
    echo -e "${GREEN}   ✓ wkhtmltopdf trouvé${NC}"
    WKHTML_PATH=$(which wkhtmltopdf)
    echo "   Chemin: $WKHTML_PATH"

    # Tester la version
    echo "   Version:"
    wkhtmltopdf --version 2>&1 | head -3 | sed 's/^/     /'
else
    echo -e "${RED}   ✗ wkhtmltopdf non installé${NC}"
fi
echo ""

# Vérifier libwkhtmltox.so
echo -e "${BLUE}3. Vérification de libwkhtmltox.so${NC}"
LIB_LOCATIONS=(
    "/usr/local/lib/libwkhtmltox.so.0"
    "/usr/local/lib/libwkhtmltox.so"
    "/usr/lib/libwkhtmltox.so.0"
    "/usr/lib/libwkhtmltox.so"
    "/usr/lib/x86_64-linux-gnu/libwkhtmltox.so.0"
    "/usr/lib/aarch64-linux-gnu/libwkhtmltox.so.0"
)

LIB_FOUND=0
for lib_path in "${LIB_LOCATIONS[@]}"; do
    if [ -f "$lib_path" ]; then
        echo -e "${GREEN}   ✓ Trouvé: $lib_path${NC}"
        LIB_FOUND=1
        FOUND_LIB="$lib_path"

        # Vérifier les dépendances de la bibliothèque
        echo "   Dépendances:"
        ldd "$lib_path" 2>&1 | grep -E "not found|=>" | sed 's/^/     /'
    fi
done

if [ $LIB_FOUND -eq 0 ]; then
    echo -e "${RED}   ✗ Aucune libwkhtmltox.so trouvée${NC}"
    echo "   Chemins vérifiés:"
    for lib_path in "${LIB_LOCATIONS[@]}"; do
        echo "     - $lib_path"
    done
fi
echo ""

# Vérifier les dépendances Qt5
echo -e "${BLUE}4. Vérification des dépendances Qt5${NC}"
QT5_LIBS=(
    "libqt5core5a"
    "libqt5gui5"
    "libqt5network5"
    "libqt5svg5"
    "libqt5xmlpatterns5"
    "libqt5webkit5"
    "libqt5webenginecore5"
    "libqt5webenginewidgets5"
    "libqt5printsupport5"
)

MISSING_QT5=()
for lib in "${QT5_LIBS[@]}"; do
    if dpkg -l | grep -q "^ii  $lib "; then
        VERSION=$(dpkg -l | grep "^ii  $lib " | awk '{print $3}')
        echo -e "${GREEN}   ✓ $lib${NC} ($VERSION)"
    else
        echo -e "${RED}   ✗ $lib${NC} - MANQUANT"
        MISSING_QT5+=("$lib")
    fi
done
echo ""

# Vérifier les autres dépendances système
echo -e "${BLUE}5. Vérification des dépendances système${NC}"
SYS_LIBS=(
    "libssl3"
    "libssl1.1"
    "libfontconfig1"
    "libfreetype6"
    "libx11-6"
    "libxrender1"
    "libxext6"
    "libnss3"
)

for lib in "${SYS_LIBS[@]}"; do
    if dpkg -l | grep -q "^ii  $lib "; then
        VERSION=$(dpkg -l | grep "^ii  $lib " | awk '{print $3}')
        echo -e "${GREEN}   ✓ $lib${NC} ($VERSION)"
    else
        echo -e "${YELLOW}   ⚠ $lib${NC} - non installé"
    fi
done
echo ""

# Vérifier ldconfig
echo -e "${BLUE}6. Vérification de la configuration ldconfig${NC}"
if [ -f /etc/ld.so.conf.d/wkhtmltopdf.conf ]; then
    echo -e "${GREEN}   ✓ /etc/ld.so.conf.d/wkhtmltopdf.conf existe${NC}"
    echo "   Contenu:"
    cat /etc/ld.so.conf.d/wkhtmltopdf.conf | sed 's/^/     /'
else
    echo -e "${YELLOW}   ⚠ /etc/ld.so.conf.d/wkhtmltopdf.conf n'existe pas${NC}"
fi

echo "   Cache ldconfig:"
if ldconfig -p | grep -q "libwkhtmltox"; then
    echo -e "${GREEN}   ✓ libwkhtmltox dans le cache ldconfig${NC}"
    ldconfig -p | grep "libwkhtmltox" | sed 's/^/     /'
else
    echo -e "${RED}   ✗ libwkhtmltox PAS dans le cache ldconfig${NC}"
fi
echo ""

# Vérifier les packages Debian installés
echo -e "${BLUE}7. Vérification des packages wkhtmltopdf Debian${NC}"
WKHTML_PACKAGES=(
    "wkhtmltopdf"
    "wkhtmltopdf-webkit"
    "wkhtmltopdf-webengine"
    "wkhtmltopdf-qt5-webkit"
    "wkhtmltopdf-qt5-webengine"
    "wkhtmltopdf-qt6"
)
echo -e "${YELLOW}   Note: Le package recommandé pour Ubuntu 22.04 est wkhtmltopdf-qt5-webengine${NC}"

INSTALLED_PACKAGES=()
for pkg in "${WKHTML_PACKAGES[@]}"; do
    if dpkg -l | grep -q "^ii  $pkg "; then
        VERSION=$(dpkg -l | grep "^ii  $pkg " | awk '{print $3}')
        echo -e "${GREEN}   ✓ $pkg${NC} ($VERSION)"
        INSTALLED_PACKAGES+=("$pkg")

        # Vérifier la version Ubuntu du package
        if echo "$VERSION" | grep -q "ubuntu24.04"; then
            echo -e "${RED}     ⚠⚠⚠ PROBLÈME: Package pour Ubuntu 24.04 sur système 22.04!${NC}"
        elif echo "$VERSION" | grep -q "ubuntu22.04"; then
            echo -e "${GREEN}     ✓ Package compatible Ubuntu 22.04${NC}"
        fi
    fi
done

if [ ${#INSTALLED_PACKAGES[@]} -eq 0 ]; then
    echo -e "${YELLOW}   ⚠ Aucun package wkhtmltopdf installé via dpkg${NC}"
fi
echo ""

# Test d'exécution
echo -e "${BLUE}8. Test d'exécution${NC}"
if command -v wkhtmltopdf &> /dev/null; then
    echo "   Tentative d'exécution: wkhtmltopdf --version"
    if wkhtmltopdf --version &> /tmp/wkhtmltopdf_test.log; then
        echo -e "${GREEN}   ✓ wkhtmltopdf s'exécute correctement${NC}"
    else
        echo -e "${RED}   ✗ wkhtmltopdf échoue à l'exécution${NC}"
        echo "   Erreur:"
        cat /tmp/wkhtmltopdf_test.log | sed 's/^/     /'

        # Analyser l'erreur
        if grep -q "libwkhtmltox.so.0" /tmp/wkhtmltopdf_test.log; then
            echo -e "${RED}   ⚠⚠⚠ PROBLÈME IDENTIFIÉ: libwkhtmltox.so.0 introuvable${NC}"
        fi
        if grep -q "version" /tmp/wkhtmltopdf_test.log; then
            echo -e "${YELLOW}   ⚠ Possible conflit de version de bibliothèque${NC}"
        fi
    fi
    rm -f /tmp/wkhtmltopdf_test.log
fi
echo ""

# Résumé et recommandations
echo "=========================================="
echo -e "${BLUE}📋 RÉSUMÉ ET RECOMMANDATIONS${NC}"
echo "=========================================="
echo ""

ISSUES=0

# Vérifier le problème principal
if [ ${#INSTALLED_PACKAGES[@]} -gt 0 ]; then
    for pkg in "${INSTALLED_PACKAGES[@]}"; do
        VERSION=$(dpkg -l | grep "^ii  $pkg " | awk '{print $3}')
        if echo "$VERSION" | grep -q "ubuntu24.04"; then
            echo -e "${RED}🔴 PROBLÈME MAJEUR:${NC}"
            echo "   Package $pkg version $VERSION est pour Ubuntu 24.04"
            echo "   mais vous êtes sur Ubuntu $UBUNTU_VERSION"
            echo ""
            echo -e "${YELLOW}SOLUTION 1 - Désinstaller et recompiler pour Ubuntu 22.04:${NC}"
            echo "   sudo dpkg -r $pkg"
            echo "   cd /path/to/wkhtmltopdf"
            echo "   ./build-deb.sh  # Auto-détecte Ubuntu 22.04 et compile Qt5 WebEngine"
            echo "   sudo apt install ./wkhtmltopdf-qt5-webengine_0.13.0-22.04_*.deb"
            echo ""
            ISSUES=1
        fi
    done
fi

# Vérifier les dépendances manquantes
if [ ${#MISSING_QT5[@]} -gt 0 ]; then
    echo -e "${RED}🔴 Dépendances Qt5 manquantes:${NC}"
    echo "   ${MISSING_QT5[@]}"
    echo ""
    echo -e "${YELLOW}SOLUTION 2 - Installer les dépendances manquantes:${NC}"
    echo "   sudo apt-get update"
    echo "   sudo apt-get install ${MISSING_QT5[@]}"
    echo ""
    ISSUES=1
fi

# Vérifier le cache ldconfig
if ! ldconfig -p | grep -q "libwkhtmltox"; then
    echo -e "${YELLOW}⚠ libwkhtmltox n'est pas dans le cache ldconfig${NC}"
    echo ""
    echo -e "${YELLOW}SOLUTION 3 - Régénérer le cache ldconfig:${NC}"
    echo "   sudo ldconfig"
    echo ""
    ISSUES=1
fi

if [ $ISSUES -eq 0 ]; then
    echo -e "${GREEN}✅ Aucun problème détecté!${NC}"
    echo ""
else
    echo -e "${BLUE}Pour plus d'aide, consultez:${NC}"
    echo "   - README.md"
    echo "   - DEPENDENCIES.md"
    echo "   - https://github.com/YOUR_USERNAME/wkhtmltopdf/issues"
fi

echo ""
echo "=========================================="
echo "Diagnostic terminé"
echo "=========================================="
