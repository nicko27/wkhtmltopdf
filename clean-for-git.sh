#!/bin/bash
# Script de nettoyage pour préparer le dépôt Git
# Supprime tous les fichiers générés/compilés et garde uniquement les sources

set -e

echo "========================================="
echo " Nettoyage pour Git"
echo "========================================="
echo ""

# Fichiers et dossiers à supprimer
TO_DELETE=(
    # Builds et binaires
    "bin/"
    "build/"
    "debian-build/"
    "*.o"
    "*.so"
    "*.so.*"
    "*.a"
    "*.dylib"
    "moc_*.cpp"
    "moc_*.cc"
    "qrc_*.cpp"

    # Makefiles générés
    "Makefile"
    "src/lib/Makefile"
    "src/pdf/Makefile"
    "src/image/Makefile"
    ".qmake.stash"

    # Fichiers temporaires Qt
    "*.pro.user"
    "*.pro.user.*"
    ".DS_Store"

    # Paquets générés
    "*.deb"
    "*.rpm"
    "*.tar.gz"
    "*.zip"

    # Dossier install (temporaire)
    "install/"

    # Node modules (playwright wrapper - très gros)
    "playwright-wrapper/node_modules/"
    "playwright-wrapper/*.pdf"
    "playwright-wrapper/package-lock.json"

    # Fichiers de test temporaires
    "test*.pdf"
    "test*.html"
    "modern*.pdf"
    "*.log"

    # Dossiers IDE
    ".vscode/"
    ".idea/"
    "*.swp"
    "*.swo"
    "*~"

    # Dossier debian temporaire de build
    "debian/usr/"
    "debian/etc/"
)

# Compter les suppressions
DELETED=0

echo "Suppression des fichiers générés..."
echo ""

for pattern in "${TO_DELETE[@]}"; do
    # Utiliser find pour supprimer de manière récursive
    if [[ "$pattern" == *"/"* ]]; then
        # C'est un dossier
        dir_name="${pattern%/}"
        if [ -d "$dir_name" ]; then
            echo "  Suppression du dossier: $dir_name"
            rm -rf "$dir_name"
            ((DELETED++))
        fi
    else
        # C'est un fichier ou pattern
        found=$(find . -name "$pattern" -type f 2>/dev/null || true)
        if [ -n "$found" ]; then
            echo "  Suppression des fichiers: $pattern"
            find . -name "$pattern" -type f -delete 2>/dev/null || true
            ((DELETED++))
        fi
    fi
done

echo ""
echo "========================================="
echo " ✓ Nettoyage terminé"
echo "========================================="
echo ""
echo "Fichiers/dossiers supprimés: $DELETED"
echo ""

# Afficher ce qui reste (fichiers importants)
echo "Fichiers conservés pour Git:"
echo ""

echo "📁 Sources C/C++:"
find src -name "*.cc" -o -name "*.hh" -o -name "*.h" -o -name "*.cpp" -o -name "*.hpp" 2>/dev/null | head -20
echo "  ... (voir src/ pour la liste complète)"
echo ""

echo "📁 Configuration Qt:"
ls -1 *.pro *.pri 2>/dev/null || echo "  (aucun)"
echo ""

echo "📁 Scripts:"
ls -1 *.sh 2>/dev/null || echo "  (aucun)"
echo ""

echo "📁 Documentation:"
ls -1 *.md 2>/dev/null || echo "  (aucun)"
echo ""

echo "📁 Packaging Debian (métadonnées seulement):"
find debian -type f 2>/dev/null || echo "  (aucun)"
echo ""

echo "========================================="
echo " Prêt pour Git !"
echo "========================================="
echo ""
echo "Prochaines étapes:"
echo ""
echo "1. Vérifier les fichiers à ajouter:"
echo "   git status"
echo ""
echo "2. Ajouter les nouveaux fichiers:"
echo "   git add -A"
echo ""
echo "3. Voir ce qui sera commité:"
echo "   git status"
echo ""
echo "4. Créer un commit:"
echo "   git commit -m \"Release 0.13.0: Automatic backend detection\""
echo ""
echo "5. Voir l'historique:"
echo "   git log --oneline"
echo ""
