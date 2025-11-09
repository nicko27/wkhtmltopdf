#!/bin/bash
# Script d'installation corrigé pour wkhtmltopdf sur Ubuntu

set -e

echo "=== Installation de wkhtmltopdf ==="
echo ""

# Vérifier que nous sommes dans le bon répertoire
if [ ! -d "bin" ]; then
    echo "Erreur: Le dossier bin/ n'existe pas"
    echo "Veuillez exécuter ce script depuis la racine du projet wkhtmltopdf"
    exit 1
fi

# Vérifier que les binaires existent
if [ ! -f "bin/wkhtmltopdf" ]; then
    echo "Erreur: bin/wkhtmltopdf n'existe pas"
    echo "Veuillez d'abord compiler le projet avec: make"
    exit 1
fi

echo "1. Installation des binaires dans /usr/local/bin..."
sudo cp -v bin/wkhtmltopdf /usr/local/bin/
sudo cp -v bin/wkhtmltoimage /usr/local/bin/
sudo chmod 755 /usr/local/bin/wkhtmltopdf /usr/local/bin/wkhtmltoimage

echo ""
echo "2. Installation des bibliothèques dans /usr/local/lib..."
sudo cp -v bin/libwkhtmltox.so.0.12.7 /usr/local/lib/
sudo chmod 644 /usr/local/lib/libwkhtmltox.so.0.12.7

echo ""
echo "3. Création des liens symboliques..."
sudo ln -sf libwkhtmltox.so.0.12.7 /usr/local/lib/libwkhtmltox.so.0.12
sudo ln -sf libwkhtmltox.so.0.12.7 /usr/local/lib/libwkhtmltox.so.0
sudo ln -sf libwkhtmltox.so.0.12.7 /usr/local/lib/libwkhtmltox.so

echo ""
echo "4. Configuration du cache des bibliothèques..."
# Vérifier si /usr/local/lib est dans la configuration
if ! grep -q "^/usr/local/lib$" /etc/ld.so.conf.d/*.conf 2>/dev/null; then
    echo "/usr/local/lib" | sudo tee /etc/ld.so.conf.d/wkhtmltopdf.conf > /dev/null
    echo "   Ajout de /usr/local/lib à la configuration ldconfig"
fi

# Mettre à jour le cache
sudo ldconfig

echo ""
echo "5. Vérification de l'installation..."
if ldconfig -p | grep -q libwkhtmltox; then
    echo "   ✓ Bibliothèque libwkhtmltox trouvée dans le cache"
else
    echo "   ✗ Avertissement: Bibliothèque non trouvée dans le cache"
fi

echo ""
echo "=== Test de l'installation ==="
if command -v wkhtmltopdf >/dev/null 2>&1; then
    echo "✓ wkhtmltopdf est installé:"
    wkhtmltopdf --version
    echo ""
    echo "Installation réussie !"
else
    echo "✗ Erreur: wkhtmltopdf n'est pas dans le PATH"
    echo "   Ajoutez /usr/local/bin à votre PATH"
fi

echo ""
echo "Pour tester:"
echo "  wkhtmltopdf https://www.google.com test.pdf"
