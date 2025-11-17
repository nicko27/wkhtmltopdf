#!/bin/bash
# Script de test comparatif des sauts de page CSS
# WebKit vs WebEngine

set -e

echo "🧪 Test Comparatif des Sauts de Page CSS"
echo "========================================"
echo ""

# Couleurs pour le terminal
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Vérifier que le fichier HTML existe
if [ ! -f "test-page-breaks.html" ]; then
    echo -e "${RED}❌ Erreur: test-page-breaks.html n'existe pas${NC}"
    echo "Assurez-vous d'être dans le bon répertoire."
    exit 1
fi

# Vérifier que wkhtmltopdf est installé
if ! command -v wkhtmltopdf &> /dev/null; then
    echo -e "${RED}❌ Erreur: wkhtmltopdf n'est pas installé${NC}"
    echo "Installez-le d'abord avec: sudo make install"
    exit 1
fi

# Afficher la version
echo -e "${BLUE}Version installée:${NC}"
wkhtmltopdf --version
echo ""

# Créer un répertoire pour les résultats
RESULTS_DIR="test-results"
mkdir -p "$RESULTS_DIR"

echo -e "${YELLOW}📄 Génération des PDFs...${NC}"
echo ""

# Test avec WebKit
echo -e "${BLUE}1️⃣  Test avec WebKit (ancien moteur)...${NC}"
if wkhtmltopdf --render-backend webkit \
               --quiet \
               test-page-breaks.html \
               "$RESULTS_DIR/page-breaks-webkit.pdf" 2>&1 | grep -v "Qt WebKit"; then
    echo -e "${GREEN}   ✓ PDF WebKit généré avec succès${NC}"
    WEBKIT_PAGES=$(pdfinfo "$RESULTS_DIR/page-breaks-webkit.pdf" 2>/dev/null | grep "Pages:" | awk '{print $2}' || echo "?")
    echo -e "   📊 Nombre de pages: ${WEBKIT_PAGES}"
else
    echo -e "${RED}   ✗ Erreur lors de la génération du PDF WebKit${NC}"
    WEBKIT_PAGES="erreur"
fi
echo ""

# Test avec WebEngine
echo -e "${BLUE}2️⃣  Test avec WebEngine (Chromium)...${NC}"
if wkhtmltopdf --render-backend webengine \
               --quiet \
               test-page-breaks.html \
               "$RESULTS_DIR/page-breaks-webengine.pdf" 2>&1 | grep -v "Qt WebEngine"; then
    echo -e "${GREEN}   ✓ PDF WebEngine généré avec succès${NC}"
    WEBENGINE_PAGES=$(pdfinfo "$RESULTS_DIR/page-breaks-webengine.pdf" 2>/dev/null | grep "Pages:" | awk '{print $2}' || echo "?")
    echo -e "   📊 Nombre de pages: ${WEBENGINE_PAGES}"
else
    echo -e "${RED}   ✗ Erreur lors de la génération du PDF WebEngine${NC}"
    WEBENGINE_PAGES="erreur"
fi
echo ""

# Résumé comparatif
echo "=========================================="
echo -e "${YELLOW}📊 Résumé Comparatif${NC}"
echo "=========================================="
echo ""

echo "Backend       | Pages | Fichier"
echo "------------- | ----- | -------"
echo "WebKit        | $WEBKIT_PAGES     | $RESULTS_DIR/page-breaks-webkit.pdf"
echo "WebEngine     | $WEBENGINE_PAGES     | $RESULTS_DIR/page-breaks-webengine.pdf"
echo ""

# Analyse des différences
if [ "$WEBKIT_PAGES" != "erreur" ] && [ "$WEBENGINE_PAGES" != "erreur" ] && [ "$WEBKIT_PAGES" != "?" ] && [ "$WEBENGINE_PAGES" != "?" ]; then
    if [ "$WEBENGINE_PAGES" -gt "$WEBKIT_PAGES" ]; then
        DIFF=$((WEBENGINE_PAGES - WEBKIT_PAGES))
        echo -e "${GREEN}✓ Résultat attendu:${NC} WebEngine a créé $DIFF page(s) de plus"
        echo "  Cela indique que les sauts de page CSS (break-before, break-after) fonctionnent!"
        echo ""
    elif [ "$WEBENGINE_PAGES" -eq "$WEBKIT_PAGES" ]; then
        echo -e "${YELLOW}⚠ Résultat inattendu:${NC} Même nombre de pages"
        echo "  Les sauts de page CSS ne semblent pas avoir été appliqués."
        echo "  Vérifiez manuellement les PDFs pour voir les différences de disposition."
        echo ""
    else
        echo -e "${YELLOW}ℹ Information:${NC} WebKit a créé plus de pages"
        echo "  Cela peut arriver selon la disposition du contenu."
        echo ""
    fi
fi

# Tests spécifiques à vérifier manuellement
echo -e "${YELLOW}🔍 Points à vérifier manuellement dans les PDFs:${NC}"
echo ""
echo "1. TEST 1 (break-before: page)"
echo "   → La section bleue devrait commencer sur une NOUVELLE page avec WebEngine"
echo ""
echo "2. TEST 2 (break-after: page)"
echo "   → La section violette devrait être suivie d'un saut de page avec WebEngine"
echo ""
echo "3. TEST 3 (break-inside: avoid)"
echo "   → Le bloc vert (500px) ne devrait PAS être coupé (les deux backends)"
echo ""
echo "4. TEST 4 (flex + break-inside)"
echo "   → Le bloc rouge sera probablement coupé (limitation connue)"
echo ""
echo "5. TEST 7 (tableaux)"
echo "   → Les en-têtes devraient se répéter sur chaque page avec WebKit patché"
echo ""
echo "6. Résumé final"
echo "   → La section noire devrait commencer sur une nouvelle page avec WebEngine"
echo ""

# Ouvrir les PDFs automatiquement si possible
echo "=========================================="
echo -e "${BLUE}💡 Ouverture des PDFs...${NC}"
echo ""

if command -v xdg-open &> /dev/null; then
    echo "Ouverture des PDFs avec le lecteur par défaut..."
    xdg-open "$RESULTS_DIR/page-breaks-webkit.pdf" 2>/dev/null &
    sleep 1
    xdg-open "$RESULTS_DIR/page-breaks-webengine.pdf" 2>/dev/null &
    echo -e "${GREEN}✓ PDFs ouverts${NC}"
elif command -v open &> /dev/null; then
    # macOS
    echo "Ouverture des PDFs avec le lecteur par défaut..."
    open "$RESULTS_DIR/page-breaks-webkit.pdf" &
    sleep 1
    open "$RESULTS_DIR/page-breaks-webengine.pdf" &
    echo -e "${GREEN}✓ PDFs ouverts${NC}"
else
    echo -e "${YELLOW}ℹ Ouvrez manuellement les PDFs pour comparer:${NC}"
    echo "  - $RESULTS_DIR/page-breaks-webkit.pdf"
    echo "  - $RESULTS_DIR/page-breaks-webengine.pdf"
fi

echo ""
echo "=========================================="
echo -e "${GREEN}✅ Tests terminés!${NC}"
echo "=========================================="
echo ""
echo "Les PDFs sont disponibles dans le répertoire: $RESULTS_DIR/"
echo ""
echo -e "${BLUE}Prochaines étapes:${NC}"
echo "1. Comparez visuellement les deux PDFs côte à côte"
echo "2. Vérifiez les 10 tests listés ci-dessus"
echo "3. Notez les différences de pagination et de disposition"
echo ""
echo -e "${YELLOW}💡 Conseil:${NC} Utilisez un outil de comparaison PDF comme diffpdf ou compare-pdf"
echo "            pour voir les différences pixel par pixel."
echo ""
