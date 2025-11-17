#!/bin/bash
# Script de réparation pour wkhtmltopdf Qt5 sur Ubuntu 22.04

set -e

echo "=========================================="
echo "🔧 Réparation wkhtmltopdf Qt5 - Ubuntu 22.04"
echo "=========================================="
echo ""

# Couleurs
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Vérifier qu'on est bien sur Ubuntu 22.04
UBUNTU_VERSION=$(lsb_release -rs 2>/dev/null || echo "unknown")
if [ "$UBUNTU_VERSION" != "22.04" ]; then
    echo -e "${YELLOW}⚠ Ce script est conçu pour Ubuntu 22.04${NC}"
    echo "Version détectée: $UBUNTU_VERSION"
    read -p "Voulez-vous continuer quand même? (y/N) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 1
    fi
fi

# Vérifier les droits root pour certaines opérations
if [ "$EUID" -eq 0 ]; then
    SUDO=""
else
    SUDO="sudo"
    echo -e "${YELLOW}ℹ Certaines opérations nécessitent sudo${NC}"
    echo ""
fi

# Menu de choix
echo "Choisissez une option:"
echo ""
echo "1) Installer les dépendances Qt5 pour Ubuntu 22.04"
echo "2) Désinstaller les packages incompatibles (Ubuntu 24.04)"
echo "3) Recompiler wkhtmltopdf pour Ubuntu 22.04 (Qt5 WebKit)"
echo "4) Recompiler wkhtmltopdf pour Ubuntu 22.04 (Qt5 WebEngine)"
echo "5) Tout faire (recommandé pour première installation)"
echo "6) Juste régénérer le cache ldconfig"
echo "7) Quitter"
echo ""
read -p "Votre choix (1-7): " CHOICE

case $CHOICE in
    1)
        echo ""
        echo -e "${BLUE}📦 Installation des dépendances Qt5...${NC}"
        echo ""

        # Mise à jour des paquets
        echo "Mise à jour de la liste des paquets..."
        $SUDO apt-get update

        # Dépendances de base
        echo ""
        echo "Installation des dépendances Qt5 de base..."
        $SUDO apt-get install -y \
            build-essential \
            cmake \
            qt5-qmake \
            qtbase5-dev \
            qtbase5-dev-tools \
            libqt5core5a \
            libqt5gui5 \
            libqt5network5 \
            libqt5svg5 \
            libqt5xmlpatterns5 \
            libqt5printsupport5

        # Demander si WebKit ou WebEngine
        echo ""
        read -p "Installer Qt5 WebKit? (y/N) " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            echo "Installation de Qt5 WebKit..."
            $SUDO apt-get install -y \
                libqt5webkit5 \
                libqt5webkit5-dev
        fi

        echo ""
        read -p "Installer Qt5 WebEngine? (y/N) " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            echo "Installation de Qt5 WebEngine..."
            $SUDO apt-get install -y \
                qtwebengine5-dev \
                libqt5webenginecore5 \
                libqt5webenginewidgets5 \
                libqt5positioning5
        fi

        # Dépendances système
        echo ""
        echo "Installation des dépendances système..."
        $SUDO apt-get install -y \
            libssl3 \
            libssl-dev \
            libfontconfig1 \
            libfreetype6 \
            libx11-6 \
            libxrender1 \
            libxext6 \
            libnss3 \
            libxcomposite1 \
            libxcursor1 \
            libxdamage1 \
            libxi6 \
            libxtst6

        echo ""
        echo -e "${GREEN}✅ Dépendances installées avec succès!${NC}"
        ;;

    2)
        echo ""
        echo -e "${BLUE}🗑️  Désinstallation des packages incompatibles...${NC}"
        echo ""

        # Lister les packages installés
        INSTALLED_PACKAGES=($(dpkg -l | grep "^ii  wkhtmltopdf" | awk '{print $2}'))

        if [ ${#INSTALLED_PACKAGES[@]} -eq 0 ]; then
            echo "Aucun package wkhtmltopdf trouvé."
        else
            echo "Packages trouvés:"
            for pkg in "${INSTALLED_PACKAGES[@]}"; do
                VERSION=$(dpkg -l | grep "^ii  $pkg " | awk '{print $3}')
                echo "  - $pkg ($VERSION)"

                if echo "$VERSION" | grep -q "ubuntu24.04"; then
                    echo -e "    ${RED}⚠ Version Ubuntu 24.04 détectée - sera désinstallée${NC}"
                fi
            done

            echo ""
            read -p "Désinstaller ces packages? (y/N) " -n 1 -r
            echo
            if [[ $REPLY =~ ^[Yy]$ ]]; then
                for pkg in "${INSTALLED_PACKAGES[@]}"; do
                    echo "Désinstallation de $pkg..."
                    $SUDO dpkg -r "$pkg" || true
                done
                echo -e "${GREEN}✅ Packages désinstallés${NC}"
            fi
        fi
        ;;

    3|4)
        BACKEND="webkit"
        if [ "$CHOICE" = "4" ]; then
            BACKEND="webengine"
        fi

        echo ""
        echo -e "${BLUE}🔨 Compilation de wkhtmltopdf Qt5 $BACKEND pour Ubuntu 22.04...${NC}"
        echo ""

        # Vérifier qu'on est dans le bon répertoire
        if [ ! -f "wkhtmltopdf.pro" ]; then
            echo -e "${RED}❌ Erreur: wkhtmltopdf.pro introuvable${NC}"
            echo "Assurez-vous d'être dans le répertoire wkhtmltopdf/"
            exit 1
        fi

        # Nettoyer les anciens builds
        echo "Nettoyage des anciens builds..."
        make distclean 2>/dev/null || true
        rm -rf bin/ lib/ debian-build-*/ moc_* ui_* *.o 2>/dev/null || true

        # Configuration
        echo ""
        echo "Configuration pour Qt5 $BACKEND..."
        RENDER_BACKEND=$BACKEND qmake

        # Compilation
        echo ""
        echo "Compilation (cela peut prendre plusieurs minutes)..."
        make clean
        make -j$(nproc)

        # Vérifier que la compilation a réussi
        if [ ! -f "bin/wkhtmltopdf" ]; then
            echo -e "${RED}❌ Erreur: La compilation a échoué${NC}"
            exit 1
        fi

        echo ""
        echo -e "${GREEN}✅ Compilation réussie!${NC}"
        echo ""
        echo "Binaire créé: bin/wkhtmltopdf"

        # Créer le package Debian
        echo ""
        read -p "Créer un package .deb pour Ubuntu 22.04? (y/N) " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            echo ""
            echo "Création du package Debian..."

            if [ -f "./build-deb-variants.sh" ]; then
                ./build-deb-variants.sh
            else
                echo -e "${YELLOW}⚠ Script build-deb-variants.sh introuvable${NC}"
                echo "Installation directe avec make install..."
                $SUDO make install
                $SUDO ldconfig
            fi
        fi

        # Installer le package ou les binaires
        echo ""
        read -p "Installer maintenant? (y/N) " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            if [ -f "debian-build-qt5-$BACKEND"/*.deb ]; then
                echo "Installation du package .deb..."
                $SUDO dpkg -i debian-build-qt5-$BACKEND/*.deb
                $SUDO apt-get install -f -y  # Résoudre les dépendances
                $SUDO ldconfig
            else
                echo "Installation avec make install..."
                $SUDO make install
                $SUDO ldconfig
            fi

            echo ""
            echo -e "${GREEN}✅ Installation terminée!${NC}"
            echo ""
            echo "Test de la version:"
            wkhtmltopdf --version
        fi
        ;;

    5)
        echo ""
        echo -e "${BLUE}🚀 Installation complète pour Ubuntu 22.04${NC}"
        echo ""

        # Demander quel backend
        echo "Quel backend voulez-vous?"
        echo "1) WebKit (petit, rapide, CSS limité)"
        echo "2) WebEngine (gros, CSS moderne)"
        read -p "Votre choix (1 ou 2): " BACKEND_CHOICE

        if [ "$BACKEND_CHOICE" = "1" ]; then
            BACKEND="webkit"
        else
            BACKEND="webengine"
        fi

        # Étape 1: Désinstaller les anciens packages
        echo ""
        echo -e "${YELLOW}[1/5] Nettoyage des anciens packages...${NC}"
        $SUDO dpkg -r wkhtmltopdf wkhtmltopdf-webkit wkhtmltopdf-webengine 2>/dev/null || true

        # Étape 2: Installer les dépendances
        echo ""
        echo -e "${YELLOW}[2/5] Installation des dépendances...${NC}"
        $SUDO apt-get update
        $SUDO apt-get install -y \
            build-essential cmake qt5-qmake qtbase5-dev \
            libqt5core5a libqt5gui5 libqt5network5 libqt5svg5 \
            libqt5xmlpatterns5 libqt5printsupport5 \
            libssl3 libssl-dev libfontconfig1 libfreetype6 \
            libx11-6 libxrender1 libxext6 libnss3

        if [ "$BACKEND" = "webkit" ]; then
            $SUDO apt-get install -y libqt5webkit5 libqt5webkit5-dev
        else
            $SUDO apt-get install -y qtwebengine5-dev libqt5webenginecore5 \
                libqt5webenginewidgets5 libqt5positioning5 \
                libxcomposite1 libxcursor1 libxdamage1 libxi6 libxtst6
        fi

        # Étape 3: Compilation
        echo ""
        echo -e "${YELLOW}[3/5] Compilation de wkhtmltopdf...${NC}"
        make distclean 2>/dev/null || true
        RENDER_BACKEND=$BACKEND qmake
        make clean
        make -j$(nproc)

        # Étape 4: Création du package
        echo ""
        echo -e "${YELLOW}[4/5] Création du package Debian...${NC}"
        if [ -f "./build-deb-variants.sh" ]; then
            ./build-deb-variants.sh
        fi

        # Étape 5: Installation
        echo ""
        echo -e "${YELLOW}[5/5] Installation...${NC}"
        if [ -f "debian-build-qt5-$BACKEND"/*.deb ]; then
            $SUDO dpkg -i debian-build-qt5-$BACKEND/*.deb
            $SUDO apt-get install -f -y
        else
            $SUDO make install
        fi
        $SUDO ldconfig

        echo ""
        echo -e "${GREEN}✅ Installation complète terminée!${NC}"
        echo ""
        echo "Vérification:"
        wkhtmltopdf --version
        ;;

    6)
        echo ""
        echo -e "${BLUE}🔄 Régénération du cache ldconfig...${NC}"
        echo ""

        # Créer le fichier de configuration si nécessaire
        if [ ! -f /etc/ld.so.conf.d/wkhtmltopdf.conf ]; then
            echo "Création de /etc/ld.so.conf.d/wkhtmltopdf.conf..."
            echo "/usr/local/lib" | $SUDO tee /etc/ld.so.conf.d/wkhtmltopdf.conf
        fi

        echo "Régénération du cache..."
        $SUDO ldconfig

        echo ""
        echo "Vérification:"
        if ldconfig -p | grep -q "libwkhtmltox"; then
            echo -e "${GREEN}✅ libwkhtmltox trouvée dans le cache${NC}"
            ldconfig -p | grep "libwkhtmltox"
        else
            echo -e "${RED}❌ libwkhtmltox toujours introuvable${NC}"
        fi
        ;;

    7)
        echo "Au revoir!"
        exit 0
        ;;

    *)
        echo -e "${RED}Choix invalide${NC}"
        exit 1
        ;;
esac

echo ""
echo "=========================================="
echo -e "${GREEN}✅ Opération terminée!${NC}"
echo "=========================================="
echo ""
echo -e "${BLUE}Prochaines étapes:${NC}"
echo "1. Testez wkhtmltopdf: wkhtmltopdf --version"
echo "2. Si des erreurs persistent, lancez: ./diagnose-ubuntu2204.sh"
echo "3. Consultez la documentation: README.md"
echo ""
