#!/bin/bash
# Script pour analyser les dépendances réelles vs déclarées

echo "========================================="
echo " Analyse des Dépendances"
echo "========================================="
echo ""

# Fonction pour extraire les dépendances d'un binaire
analyze_binary() {
    local BINARY=$1
    local LABEL=$2

    if [ ! -f "$BINARY" ]; then
        echo "❌ $LABEL: Binaire non trouvé"
        return 1
    fi

    echo "📦 $LABEL"
    echo "   Binaire: $BINARY"
    echo ""

    # Analyser avec ldd
    echo "Dépendances détectées par ldd:"
    echo ""

    # Qt libraries
    echo "🔷 Qt:"
    ldd "$BINARY" 2>/dev/null | grep -i "libqt" | awk '{print "   " $1}' | sort

    echo ""
    echo "🔷 SSL/Crypto:"
    ldd "$BINARY" 2>/dev/null | grep -E "libssl|libcrypto" | awk '{print "   " $1}' | sort

    echo ""
    echo "🔷 Fonts:"
    ldd "$BINARY" 2>/dev/null | grep -E "libfontconfig|libfreetype" | awk '{print "   " $1}' | sort

    echo ""
    echo "🔷 X11:"
    ldd "$BINARY" 2>/dev/null | grep -E "libX|libxcb" | awk '{print "   " $1}' | sort | head -10

    echo ""
    echo "🔷 Système:"
    ldd "$BINARY" 2>/dev/null | grep -E "libc\.|libstdc\+\+|libgcc|libm\." | awk '{print "   " $1}' | sort

    # Chromium deps (pour WebEngine)
    echo ""
    echo "🔷 Chromium/WebEngine:"
    ldd "$BINARY" 2>/dev/null | grep -E "libnss|libnspr|libdbus" | awk '{print "   " $1}' | sort

    echo ""
    echo "────────────────────────────────────────"
    echo ""
}

# Fonction pour comparer avec le control file
compare_with_control() {
    local QT_VERSION=$1
    local VARIANT=$2

    echo ""
    echo "========================================="
    echo " Comparaison: $QT_VERSION $VARIANT"
    echo "========================================="
    echo ""

    # Extraire les dépendances du script build-deb-all.sh
    if [ "$QT_VERSION" = "qt6" ]; then
        echo "📋 Dépendances déclarées dans le .deb Qt6:"
        grep -A1 "Package: wkhtmltopdf-qt6" build-deb-all.sh | grep "^Depends:" | sed 's/Depends: //' | tr ',' '\n' | sed 's/^ */   /'
    elif [ "$VARIANT" = "webengine" ]; then
        echo "📋 Dépendances déclarées dans le .deb Qt5 WebEngine:"
        grep -A1 "Package: wkhtmltopdf-webengine" build-deb-all.sh | grep "^Depends:" | sed 's/Depends: //' | tr ',' '\n' | sed 's/^ */   /'
    else
        echo "📋 Dépendances déclarées dans le .deb Qt5 WebKit:"
        grep -A1 "Package: wkhtmltopdf-webkit" build-deb-all.sh | grep "^Depends:" | sed 's/Depends: //' | tr ',' '\n' | sed 's/^ */   /'
    fi

    echo ""
}

# Analyser le binaire actuel
if [ -f "bin/wkhtmltopdf" ]; then
    analyze_binary "bin/wkhtmltopdf" "Binaire Actuel (bin/wkhtmltopdf)"

    echo ""
    echo "ℹ️  Pour savoir quel backend est compilé, lancez:"
    echo "   bin/wkhtmltopdf --version"
    echo ""
else
    echo "❌ Aucun binaire trouvé"
    echo ""
    echo "Compilez d'abord:"
    echo "   # Qt5 WebKit"
    echo "   RENDER_BACKEND=webkit qmake && make"
    echo ""
    echo "   # Qt5 WebEngine"
    echo "   RENDER_BACKEND=webengine qmake && make"
    echo ""
    echo "   # Qt6 WebEngine"
    echo "   qmake6 && make"
    echo ""
    exit 1
fi

# Menu pour choisir la comparaison
echo ""
echo "Voulez-vous comparer avec les dépendances déclarées ?"
echo ""
echo "1) Qt5 WebKit"
echo "2) Qt5 WebEngine"
echo "3) Qt6 WebEngine"
echo "4) Toutes"
echo "5) Non, juste l'analyse ci-dessus"
echo ""
read -p "Choix [1-5]: " CHOICE

case $CHOICE in
    1)
        compare_with_control "qt5" "webkit"
        ;;
    2)
        compare_with_control "qt5" "webengine"
        ;;
    3)
        compare_with_control "qt6" "webengine"
        ;;
    4)
        compare_with_control "qt5" "webkit"
        compare_with_control "qt5" "webengine"
        compare_with_control "qt6" "webengine"
        ;;
    5)
        echo "OK, analyse terminée"
        ;;
    *)
        echo "Choix invalide"
        ;;
esac

echo ""
echo "========================================="
echo " Résumé"
echo "========================================="
echo ""
echo "✅ Vérifications à faire:"
echo "   1. Toutes les dépendances Qt détectées par ldd sont dans le .deb"
echo "   2. Les dépendances système critiques sont présentes"
echo "   3. Les dépendances optionnelles sont en Recommends (pas Depends)"
echo ""
echo "📚 Documentation:"
echo "   Voir DEPENDENCIES.md pour la liste complète"
echo ""
