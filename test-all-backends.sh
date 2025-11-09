#!/bin/bash
# Script pour tester le fichier HTML avec les 3 backends
# et vérifier les dépendances

set -e

echo "========================================"
echo " Test des 3 backends wkhtmltopdf"
echo "========================================"
echo ""

HTML_FILE="test-full-css.html"

# Vérifier que le fichier HTML existe
if [ ! -f "$HTML_FILE" ]; then
    echo "❌ Erreur: $HTML_FILE n'existe pas"
    exit 1
fi

echo "✓ Fichier HTML trouvé: $HTML_FILE"
echo ""

# Créer un dossier pour les résultats
mkdir -p test-results

# Fonction pour vérifier les dépendances d'un binaire
check_dependencies() {
    local BINARY=$1
    local LABEL=$2

    echo ""
    echo "========================================="
    echo " Dépendances $LABEL"
    echo "========================================="

    if [ -f "$BINARY" ]; then
        echo "Binaire: $BINARY"
        echo ""

        # Dépendances Qt
        echo "📦 Dépendances Qt:"
        ldd "$BINARY" 2>/dev/null | grep -i qt || echo "  (aucune dépendance Qt détectée)"

        echo ""
        echo "📦 Dépendances système critiques:"
        ldd "$BINARY" 2>/dev/null | grep -E "libssl|libcrypto|libfontconfig|libfreetype|libc\." | head -10 || true

        echo ""
        echo "📦 Dépendances X11:"
        ldd "$BINARY" 2>/dev/null | grep -i "libx" | head -5 || echo "  (aucune dépendance X11 détectée)"

        # Compter le total
        TOTAL=$(ldd "$BINARY" 2>/dev/null | wc -l)
        echo ""
        echo "Total de dépendances: $TOTAL"
    else
        echo "❌ Binaire non trouvé: $BINARY"
        echo "   Compilez d'abord le projet"
    fi

    echo ""
}

# Fonction pour tester un backend
test_backend() {
    local BACKEND=$1
    local OUTPUT_FILE=$2
    local QT_VERSION=$3
    local BINARY=$4

    echo ""
    echo "========================================="
    echo " Test: $BACKEND ($QT_VERSION)"
    echo "========================================="

    if [ ! -f "$BINARY" ]; then
        echo "❌ Binaire non trouvé: $BINARY"
        echo "   Compilez d'abord avec:"
        if [ "$QT_VERSION" = "Qt6" ]; then
            echo "   qmake6 && make clean && make -j\$(nproc)"
        else
            echo "   RENDER_BACKEND=${BACKEND} qmake && make clean && make -j\$(nproc)"
        fi
        return 1
    fi

    echo "✓ Binaire trouvé: $BINARY"

    # Version
    echo ""
    echo "Version:"
    "$BINARY" --version | head -3

    # Test de conversion
    echo ""
    echo "Conversion HTML → PDF..."

    if [ "$BACKEND" = "webkit" ] || [ "$BACKEND" = "webengine" ]; then
        # Qt5 avec backend spécifique
        "$BINARY" --render-backend "$BACKEND" \
            --enable-local-file-access \
            --page-size A4 \
            --margin-top 10mm \
            --margin-bottom 10mm \
            --margin-left 10mm \
            --margin-right 10mm \
            "$HTML_FILE" "test-results/$OUTPUT_FILE" 2>&1 | tail -5
    else
        # Qt6 (WebEngine uniquement)
        "$BINARY" \
            --enable-local-file-access \
            --page-size A4 \
            --margin-top 10mm \
            --margin-bottom 10mm \
            --margin-left 10mm \
            --margin-right 10mm \
            "$HTML_FILE" "test-results/$OUTPUT_FILE" 2>&1 | tail -5
    fi

    if [ -f "test-results/$OUTPUT_FILE" ]; then
        SIZE=$(du -h "test-results/$OUTPUT_FILE" | cut -f1)
        echo ""
        echo "✅ PDF généré: test-results/$OUTPUT_FILE"
        echo "   Taille: $SIZE"
    else
        echo ""
        echo "❌ Erreur lors de la génération du PDF"
        return 1
    fi
}

# Menu principal
echo "Que voulez-vous faire ?"
echo ""
echo "1) Vérifier les dépendances du binaire actuel"
echo "2) Tester Qt5 WebKit"
echo "3) Tester Qt5 WebEngine"
echo "4) Tester Qt6 WebEngine"
echo "5) Tester TOUS les backends (si compilés)"
echo ""
read -p "Choix [1-5]: " CHOICE

case $CHOICE in
    1)
        # Vérifier les dépendances
        if [ -f "bin/wkhtmltopdf" ]; then
            check_dependencies "bin/wkhtmltopdf" "binaire actuel (bin/wkhtmltopdf)"
        else
            echo "❌ Aucun binaire trouvé dans bin/"
            echo "   Compilez d'abord le projet"
        fi
        ;;
    2)
        # Test Qt5 WebKit
        test_backend "webkit" "test-webkit.pdf" "Qt5" "bin/wkhtmltopdf"
        ;;
    3)
        # Test Qt5 WebEngine
        test_backend "webengine" "test-webengine-qt5.pdf" "Qt5" "bin/wkhtmltopdf"
        ;;
    4)
        # Test Qt6 WebEngine
        test_backend "qt6" "test-webengine-qt6.pdf" "Qt6" "bin/wkhtmltopdf"
        ;;
    5)
        # Tester tous
        echo ""
        echo "Test de tous les backends disponibles..."
        echo ""

        # Qt5 WebKit
        if [ -f "bin/wkhtmltopdf" ]; then
            test_backend "webkit" "test-webkit.pdf" "Qt5" "bin/wkhtmltopdf" || true
            sleep 2
        fi

        # Qt5 WebEngine
        if [ -f "bin/wkhtmltopdf" ]; then
            test_backend "webengine" "test-webengine-qt5.pdf" "Qt5" "bin/wkhtmltopdf" || true
            sleep 2
        fi

        # Qt6 WebEngine (nécessite recompilation)
        echo ""
        echo "⚠️  Note: Pour tester Qt6, vous devez recompiler avec qmake6"
        echo "   Les tests Qt5 ci-dessus sont basés sur le binaire actuel"
        ;;
    *)
        echo "Choix invalide"
        exit 1
        ;;
esac

echo ""
echo "========================================="
echo " Résultats"
echo "========================================="
echo ""
echo "Fichiers générés dans: test-results/"
ls -lh test-results/*.pdf 2>/dev/null || echo "  (aucun PDF généré)"
echo ""
echo "Pour comparer visuellement:"
echo "  1. Ouvrez test-results/test-webkit.pdf (Qt5 WebKit)"
echo "  2. Ouvrez test-results/test-webengine-qt5.pdf (Qt5 WebEngine)"
echo "  3. Ouvrez test-results/test-webengine-qt6.pdf (Qt6 WebEngine)"
echo ""
echo "Différences attendues:"
echo "  • WebKit: Layout cassé, pas de Grid/Flexbox, variables CSS ignorées"
echo "  • WebEngine Qt5: Bon rendu, CSS moderne supporté"
echo "  • WebEngine Qt6: Meilleur rendu, tous les effets CSS"
echo ""
