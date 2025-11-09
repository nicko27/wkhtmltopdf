#!/bin/bash
# Script de recompilation rapide de wkhtmltopdf

set -e

echo "========================================="
echo " Recompilation de wkhtmltopdf"
echo "========================================="
echo ""

# Nettoyer les anciens builds
echo "[1/4] Nettoyage des anciens builds..."
make clean 2>/dev/null || true
rm -rf bin/

echo ""
echo "[2/4] Configuration avec qmake..."
# Déterminer le backend à utiliser
BACKEND="${RENDER_BACKEND:-both}"
echo "   Backend sélectionné: $BACKEND"

export RENDER_BACKEND=$BACKEND
qmake INSTALLBASE=/usr/local

echo ""
echo "[3/4] Compilation..."
JOBS=$(nproc 2>/dev/null || echo 4)
echo "   Utilisation de $JOBS jobs parallèles"
make -j$JOBS

echo ""
echo "[4/4] Installation..."
sudo make install
sudo ldconfig

echo ""
echo "========================================="
echo " ✓ Recompilation terminée !"
echo "========================================="
echo ""
echo "Test de l'installation:"
if command -v wkhtmltopdf >/dev/null 2>&1; then
    wkhtmltopdf --version
    echo ""
    echo "Pour voir le backend utilisé:"
    echo "  wkhtmltopdf --help | grep -A 3 'Rendering backend'"
else
    echo "Erreur: wkhtmltopdf n'est pas accessible"
fi

echo ""
echo "Nouvelles fonctionnalités:"
echo "  • Détection automatique du meilleur backend disponible"
echo "  • WebEngine (Chromium) utilisé en priorité si disponible"
echo "  • Fallback sur WebKit si WebEngine n'est pas disponible"
echo "  • Affichage du backend utilisé dans --help"
