#!/bin/bash
# Script de fix pour l'erreur "ld: cannot find -lwkhtmltox" sur Ubuntu 22.04

set -e

echo "=========================================="
echo "🔧 Fix: ld cannot find -lwkhtmltox"
echo "=========================================="
echo ""

# Couleurs
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Vérifier qu'on est dans le bon répertoire
if [ ! -f "wkhtmltopdf.pro" ]; then
    echo -e "${RED}❌ Erreur: wkhtmltopdf.pro introuvable${NC}"
    echo "Assurez-vous d'être dans le répertoire racine de wkhtmltopdf"
    exit 1
fi

echo -e "${BLUE}🔍 Diagnostic du problème...${NC}"
echo ""

# Problème identifié
echo -e "${YELLOW}📋 Problème identifié:${NC}"
echo "L'erreur 'ld: cannot find -lwkhtmltox' signifie que le linker"
echo "cherche la bibliothèque libwkhtmltox.so qui devrait être dans bin/"
echo "mais qui n'existe pas encore ou n'a pas été compilée correctement."
echo ""

# Causes possibles
echo -e "${YELLOW}🔍 Causes possibles:${NC}"
echo "1. La compilation de src/lib/ a échoué silencieusement"
echo "2. Les dépendances Qt5/Qt6 sont manquantes ou incompatibles"
echo "3. Le répertoire bin/ n'a pas été créé"
echo "4. Problème de configuration qmake"
echo ""

# Vérifier les dépendances
echo -e "${BLUE}[1/6] Vérification des dépendances Qt...${NC}"

# Détecter qmake
QMAKE=""
if command -v qmake &> /dev/null; then
    QMAKE="qmake"
elif command -v qmake-qt5 &> /dev/null; then
    QMAKE="qmake-qt5"
elif command -v qmake6 &> /dev/null; then
    QMAKE="qmake6"
else
    echo -e "${RED}❌ qmake introuvable!${NC}"
    echo ""
    echo "Installez Qt5 ou Qt6:"
    echo "  sudo apt-get install qt5-qmake qtbase5-dev"
    echo "  # OU"
    echo "  sudo apt-get install qt6-base-dev"
    exit 1
fi

echo "✓ qmake trouvé: $QMAKE"

# Vérifier la version Qt
QT_VERSION=$($QMAKE -query QT_VERSION)
echo "✓ Version Qt: $QT_VERSION"

# Demander le backend
echo ""
echo -e "${BLUE}[2/6] Sélection du backend de rendu...${NC}"
echo ""
echo "Quel backend voulez-vous compiler?"
echo "1) webkit   - Petit, rapide, CSS limité (Qt5 uniquement)"
echo "2) webengine - Chromium, CSS moderne (Qt5 ou Qt6)"
echo ""
read -p "Votre choix (1 ou 2): " BACKEND_CHOICE

if [ "$BACKEND_CHOICE" = "1" ]; then
    BACKEND="webkit"

    # Vérifier que Qt WebKit est disponible
    if ! $QMAKE -query QT_INSTALL_HEADERS | xargs -I {} test -d {}/QtWebKit 2>/dev/null; then
        echo -e "${YELLOW}⚠ Qt WebKit semble manquant${NC}"
        echo ""
        read -p "Installer Qt5 WebKit? (y/N) " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            sudo apt-get update
            sudo apt-get install -y libqt5webkit5 libqt5webkit5-dev
        else
            echo -e "${RED}Impossible de continuer sans Qt WebKit${NC}"
            exit 1
        fi
    fi
else
    BACKEND="webengine"

    # Vérifier Qt version pour WebEngine
    QT_MAJOR=$(echo $QT_VERSION | cut -d. -f1)
    if [ "$QT_MAJOR" -lt 5 ]; then
        echo -e "${RED}❌ Qt WebEngine nécessite Qt 5.4+${NC}"
        exit 1
    fi

    # Installer les dépendances WebEngine si manquantes
    if [ "$QT_MAJOR" = "5" ]; then
        if ! dpkg -l | grep -q libqt5webenginecore5; then
            echo -e "${YELLOW}⚠ Qt5 WebEngine semble manquant${NC}"
            echo ""
            read -p "Installer Qt5 WebEngine? (y/N) " -n 1 -r
            echo
            if [[ $REPLY =~ ^[Yy]$ ]]; then
                sudo apt-get update
                sudo apt-get install -y qtwebengine5-dev libqt5webenginecore5 libqt5webenginewidgets5
            fi
        fi
    fi
fi

echo ""
echo -e "${BLUE}[3/6] Nettoyage complet du build précédent...${NC}"

# Nettoyage en profondeur
echo "Suppression des fichiers de build..."
make distclean 2>/dev/null || true
rm -rf bin/ lib/ build/ .qmake.stash 2>/dev/null || true
rm -f Makefile */Makefile */*/Makefile 2>/dev/null || true
rm -rf moc_* ui_* qrc_* *.o */*.o */*/*.o 2>/dev/null || true
rm -rf debian-build-*/ 2>/dev/null || true

echo "✓ Nettoyage terminé"

echo ""
echo -e "${BLUE}[4/6] Configuration avec qmake...${NC}"

# Créer les répertoires de sortie à l'avance
mkdir -p bin lib

# Configurer avec le backend choisi
echo "Configuration: RENDER_BACKEND=$BACKEND"
export RENDER_BACKEND=$BACKEND

if ! $QMAKE; then
    echo -e "${RED}❌ qmake a échoué!${NC}"
    echo ""
    echo "Détails de l'erreur ci-dessus."
    exit 1
fi

echo "✓ Configuration réussie"

echo ""
echo -e "${BLUE}[5/6] Compilation de la bibliothèque libwkhtmltox...${NC}"
echo ""
echo "Cette étape peut prendre plusieurs minutes..."
echo ""

# Compiler d'abord UNIQUEMENT la bibliothèque
cd src/lib
if ! make -j$(nproc); then
    echo ""
    echo -e "${RED}❌ Compilation de libwkhtmltox a échoué!${NC}"
    echo ""
    echo -e "${YELLOW}Erreurs possibles:${NC}"
    echo "1. Dépendances Qt manquantes"
    echo "2. Version Qt incompatible"
    echo "3. Erreurs de compilation C++"
    echo ""
    echo "Vérifiez les erreurs ci-dessus et installez les dépendances manquantes."
    echo ""
    echo "Pour Qt5 WebKit:"
    echo "  sudo apt-get install qtbase5-dev libqt5webkit5-dev"
    echo ""
    echo "Pour Qt5 WebEngine:"
    echo "  sudo apt-get install qtbase5-dev qtwebengine5-dev"
    echo ""
    exit 1
fi
cd ../..

# Vérifier que la bibliothèque a été créée
if [ ! -f "bin/libwkhtmltox.so" ] && [ ! -f "bin/libwkhtmltox.so.0" ] && [ ! -f "bin/libwkhtmltox.dylib" ]; then
    echo -e "${RED}❌ libwkhtmltox n'a pas été créée dans bin/${NC}"
    echo ""
    echo "Fichiers dans bin/:"
    ls -la bin/
    exit 1
fi

echo ""
echo -e "${GREEN}✅ libwkhtmltox compilée avec succès!${NC}"
echo ""
ls -lh bin/libwkhtmltox.*
echo ""

echo -e "${BLUE}[6/6] Compilation des exécutables (wkhtmltopdf, wkhtmltoimage)...${NC}"
echo ""

# Maintenant compiler les exécutables
cd src/pdf
if ! make -j$(nproc); then
    echo -e "${RED}❌ Compilation de wkhtmltopdf a échoué${NC}"
    exit 1
fi
cd ../..

cd src/image
if ! make -j$(nproc); then
    echo -e "${RED}❌ Compilation de wkhtmltoimage a échoué${NC}"
    exit 1
fi
cd ../..

echo ""
echo "=========================================="
echo -e "${GREEN}✅ COMPILATION RÉUSSIE!${NC}"
echo "=========================================="
echo ""

# Vérifier les fichiers créés
echo "Fichiers créés:"
echo ""
ls -lh bin/
echo ""

# Test rapide
if [ -f "bin/wkhtmltopdf" ]; then
    echo "Test de l'exécutable:"
    if LD_LIBRARY_PATH=./bin ./bin/wkhtmltopdf --version 2>&1 | head -3; then
        echo ""
        echo -e "${GREEN}✅ wkhtmltopdf fonctionne!${NC}"
    else
        echo ""
        echo -e "${YELLOW}⚠ L'exécutable ne fonctionne pas encore${NC}"
        echo "Vous devrez peut-être installer avec 'sudo make install'"
    fi
fi

echo ""
echo -e "${BLUE}Prochaines étapes:${NC}"
echo ""
echo "1. Installer le logiciel:"
echo "   sudo make install"
echo "   sudo ldconfig"
echo ""
echo "2. OU créer un package Debian:"
echo "   ./build-deb-variants.sh"
echo "   sudo dpkg -i debian-build-qt5-$BACKEND/*.deb"
echo ""
echo "3. Tester l'installation:"
echo "   wkhtmltopdf --version"
echo "   echo '<h1>Test</h1>' > test.html"
echo "   wkhtmltopdf test.html test.pdf"
echo ""

# Nettoyer les variables d'environnement
unset RENDER_BACKEND

echo "=========================================="
echo -e "${GREEN}Script terminé avec succès!${NC}"
echo "=========================================="
