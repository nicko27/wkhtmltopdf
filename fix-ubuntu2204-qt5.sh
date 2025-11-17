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
        BACKEND="webengine"
        if [ "$CHOICE" = "3" ]; then
            echo ""
            echo -e "${YELLOW}⚠ WebKit est abandonné. Utilisation de WebEngine.${NC}"
        fi

        echo ""
        echo -e "${BLUE}🔨 Compilation de wkhtmltopdf Qt5 WebEngine pour Ubuntu 22.04...${NC}"
        echo ""

        # Vérifier qu'on est dans le bon répertoire
        if [ ! -f "wkhtmltopdf.pro" ]; then
            echo -e "${RED}❌ Erreur: wkhtmltopdf.pro introuvable${NC}"
            echo "Assurez-vous d'être dans le répertoire wkhtmltopdf/"
            exit 1
        fi

        if [ ! -f "build-deb.sh" ]; then
            echo -e "${RED}❌ Erreur: build-deb.sh introuvable${NC}"
            echo "Ce script nécessite le nouveau build-deb.sh"
            exit 1
        fi

        # Utiliser le nouveau script build-deb.sh
        echo ""
        echo -e "${GREEN}Utilisation du script build-deb.sh (applique tous les correctifs Ubuntu 22.04)${NC}"
        echo ""

        ./build-deb.sh

        echo ""
        echo -e "${GREEN}✅ Build terminé!${NC}"
        echo ""

        # Proposer l'installation
        DEB_FILE=$(ls wkhtmltopdf-qt5-webengine_0.13.0-22.04_*.deb 2>/dev/null | head -1)
        if [ -n "$DEB_FILE" ]; then
            echo "Package créé: $DEB_FILE"
            echo ""
            read -p "Installer maintenant? (y/N) " -n 1 -r
            echo
            if [[ $REPLY =~ ^[Yy]$ ]]; then
                echo "Installation du package .deb..."
                $SUDO apt install "./$DEB_FILE"

                echo ""
                echo -e "${GREEN}✅ Installation terminée!${NC}"
                echo ""
                echo "Vérification:"
                wkhtmltopdf --version
                echo ""
                ldconfig -p | grep libwkhtmltox
            fi
        else
            echo -e "${RED}❌ Package .deb non trouvé${NC}"
        fi
        ;;

    5)
        echo ""
        echo -e "${BLUE}🚀 Installation complète pour Ubuntu 22.04 (WebEngine uniquement)${NC}"
        echo ""

        # Vérifier qu'on a le nouveau script
        if [ ! -f "build-deb.sh" ]; then
            echo -e "${RED}❌ Erreur: build-deb.sh introuvable${NC}"
            echo "Ce script nécessite le nouveau build-deb.sh"
            exit 1
        fi

        # Étape 1: Désinstaller les anciens packages
        echo ""
        echo -e "${YELLOW}[1/3] Nettoyage des anciens packages...${NC}"
        $SUDO dpkg -r wkhtmltopdf wkhtmltopdf-webkit wkhtmltopdf-webengine wkhtmltopdf-qt5-webkit wkhtmltopdf-qt5-webengine wkhtmltopdf-qt6 2>/dev/null || true

        # Étape 2: Build avec le nouveau script (qui installe les dépendances)
        echo ""
        echo -e "${YELLOW}[2/3] Build avec tous les correctifs Ubuntu 22.04...${NC}"
        ./build-deb.sh

        # Étape 3: Installation
        echo ""
        echo -e "${YELLOW}[3/3] Installation...${NC}"
        DEB_FILE=$(ls wkhtmltopdf-qt5-webengine_0.13.0-22.04_*.deb 2>/dev/null | head -1)
        if [ -n "$DEB_FILE" ]; then
            $SUDO apt install "./$DEB_FILE"
        else
            echo -e "${RED}❌ Package .deb non trouvé${NC}"
            exit 1
        fi

        echo ""
        echo -e "${GREEN}✅ Installation complète terminée!${NC}"
        echo ""
        echo "Vérification:"
        wkhtmltopdf --version
        echo ""
        ldconfig -p | grep libwkhtmltox
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
