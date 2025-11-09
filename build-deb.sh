#!/bin/bash
# Script de génération de paquet .deb pour wkhtmltopdf 0.13.0

set -e

VERSION="0.13.0"
ARCH=$(dpkg --print-architecture 2>/dev/null || echo "amd64")
PKG_NAME="wkhtmltopdf_${VERSION}_${ARCH}"
BUILD_DIR="debian-build"

echo "========================================="
echo " Build paquet .deb wkhtmltopdf ${VERSION}"
echo "========================================="
echo ""

# Vérifier que les binaires sont compilés
if [ ! -f "bin/wkhtmltopdf" ] || [ ! -f "bin/libwkhtmltox.so.0.12.7" ]; then
    echo "❌ Erreur: Les binaires n'existent pas dans bin/"
    echo ""
    echo "Veuillez d'abord compiler le projet:"
    echo "  ./rebuild.sh"
    echo ""
    exit 1
fi

# Nettoyer l'ancien build
echo "[1/6] Nettoyage des anciens builds..."
rm -rf "${BUILD_DIR}"
rm -f wkhtmltopdf_*.deb

# Créer la structure du paquet
echo "[2/6] Création de la structure du paquet..."
mkdir -p "${BUILD_DIR}/DEBIAN"
mkdir -p "${BUILD_DIR}/usr/local/bin"
mkdir -p "${BUILD_DIR}/usr/local/lib"
mkdir -p "${BUILD_DIR}/usr/local/include/wkhtmltox"
mkdir -p "${BUILD_DIR}/usr/share/doc/wkhtmltopdf"
mkdir -p "${BUILD_DIR}/etc/ld.so.conf.d"

# Copier les fichiers de contrôle Debian
echo "[3/6] Copie des métadonnées du paquet..."
cp debian/DEBIAN/control "${BUILD_DIR}/DEBIAN/"
cp debian/DEBIAN/postinst "${BUILD_DIR}/DEBIAN/"
cp debian/DEBIAN/postrm "${BUILD_DIR}/DEBIAN/"
chmod 755 "${BUILD_DIR}/DEBIAN/postinst" "${BUILD_DIR}/DEBIAN/postrm"

# Mettre à jour l'architecture dans le fichier control
sed -i "s/^Architecture:.*/Architecture: ${ARCH}/" "${BUILD_DIR}/DEBIAN/control"

# Copier la documentation
cp debian/usr/share/doc/wkhtmltopdf/copyright "${BUILD_DIR}/usr/share/doc/wkhtmltopdf/"
cp debian/usr/share/doc/wkhtmltopdf/changelog.Debian.gz "${BUILD_DIR}/usr/share/doc/wkhtmltopdf/"

# Copier les fichiers README
cp README.md "${BUILD_DIR}/usr/share/doc/wkhtmltopdf/README"
cp MULTI_BACKEND.md "${BUILD_DIR}/usr/share/doc/wkhtmltopdf/" 2>/dev/null || true
cp AUTO_BACKEND_DETECTION.md "${BUILD_DIR}/usr/share/doc/wkhtmltopdf/" 2>/dev/null || true
cp DEPENDENCIES.md "${BUILD_DIR}/usr/share/doc/wkhtmltopdf/" 2>/dev/null || true

# Installer les binaires
echo "[4/6] Installation des binaires..."
install -m 755 bin/wkhtmltopdf "${BUILD_DIR}/usr/local/bin/"
install -m 755 bin/wkhtmltoimage "${BUILD_DIR}/usr/local/bin/"

# Installer les bibliothèques
echo "[5/6] Installation des bibliothèques..."
install -m 644 bin/libwkhtmltox.so.0.12.7 "${BUILD_DIR}/usr/local/lib/"
ln -s libwkhtmltox.so.0.12.7 "${BUILD_DIR}/usr/local/lib/libwkhtmltox.so.0.12"
ln -s libwkhtmltox.so.0.12.7 "${BUILD_DIR}/usr/local/lib/libwkhtmltox.so.0"
ln -s libwkhtmltox.so.0.12.7 "${BUILD_DIR}/usr/local/lib/libwkhtmltox.so"

# Installer les headers
if [ -d "src/lib" ]; then
    install -m 644 src/lib/pdf.h "${BUILD_DIR}/usr/local/include/wkhtmltox/" 2>/dev/null || true
    install -m 644 src/lib/image.h "${BUILD_DIR}/usr/local/include/wkhtmltox/" 2>/dev/null || true
    install -m 644 src/lib/dllbegin.inc "${BUILD_DIR}/usr/local/include/wkhtmltox/" 2>/dev/null || true
    install -m 644 src/lib/dllend.inc "${BUILD_DIR}/usr/local/include/wkhtmltox/" 2>/dev/null || true
fi

# Configurer ldconfig
echo "/usr/local/lib" > "${BUILD_DIR}/etc/ld.so.conf.d/wkhtmltopdf.conf"

# Calculer la taille installée
INSTALLED_SIZE=$(du -sk "${BUILD_DIR}/usr" | cut -f1)
echo "Installed-Size: ${INSTALLED_SIZE}" >> "${BUILD_DIR}/DEBIAN/control"

# Afficher les informations du paquet
echo ""
echo "Informations du paquet:"
echo "  Nom:         wkhtmltopdf"
echo "  Version:     ${VERSION}"
echo "  Architecture: ${ARCH}"
echo "  Taille:      ${INSTALLED_SIZE} KB"
echo ""

# Construire le paquet
echo "[6/6] Construction du paquet .deb..."
dpkg-deb --build "${BUILD_DIR}" "${PKG_NAME}.deb"

# Vérifier le paquet
echo ""
echo "========================================="
echo " ✓ Paquet créé avec succès!"
echo "========================================="
echo ""
echo "Fichier: ${PKG_NAME}.deb"
echo ""

# Afficher les informations du paquet
echo "Informations du paquet:"
dpkg-deb --info "${PKG_NAME}.deb"

echo ""
echo "Contenu du paquet (premiers fichiers):"
dpkg-deb --contents "${PKG_NAME}.deb" 2>/dev/null | head -20 || true

echo ""
echo "Pour installer:"
echo "  sudo dpkg -i ${PKG_NAME}.deb"
echo "  sudo apt-get install -f  # Installer les dépendances manquantes"
echo ""
echo "Pour vérifier:"
echo "  dpkg -L wkhtmltopdf      # Lister les fichiers installés"
echo "  wkhtmltopdf --version    # Tester l'installation"
echo ""
