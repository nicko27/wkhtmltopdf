# Guide de Build - wkhtmltopdf WebEngine

## Configuration automatique

Le script `build-deb.sh` détecte automatiquement votre version Ubuntu et configure le build approprié:

- **Ubuntu 22.04** → Qt5 WebEngine
- **Ubuntu 24.04** → Qt6 WebEngine

## Prérequis

### Ubuntu 22.04 (Jammy) - Qt5 WebEngine
```bash
sudo apt-get update
sudo apt-get install -y \
    qt5-default \
    qtwebengine5-dev \
    libqt5webenginewidgets5 \
    libqt5webenginecore5 \
    libqt5svg5-dev \
    libqt5xmlpatterns5-dev \
    libqt5network5 \
    libqt5printsupport5 \
    build-essential
```

### Ubuntu 24.04 (Noble) - Qt6 WebEngine
```bash
sudo apt-get update
sudo apt-get install -y \
    qt6-webengine-dev \
    qt6-base-dev \
    libqt6webenginewidgets6 \
    libqt6webenginecore6 \
    libqt6svg6-dev \
    libqt6network6 \
    libqt6printsupport6 \
    build-essential
```

## Utilisation

### Build automatique avec .deb
```bash
./build-deb.sh
```

Le script va:
1. Détecter votre version Ubuntu
2. Proposer d'installer les dépendances
3. Compiler avec WebEngine (Qt5 ou Qt6 selon la version)
4. Créer un package .deb

### Installation du package
```bash
# Après la création du .deb
sudo apt install ./wkhtmltopdf-*.deb
```

## Packages générés

### Ubuntu 22.04
- **Nom**: `wkhtmltopdf-webengine_0.13.0-22.04_<arch>.deb`
- **Backend**: Qt5 WebEngine
- **Moteur**: Chromium 87+

### Ubuntu 24.04
- **Nom**: `wkhtmltopdf-qt6_0.13.0-24.04_<arch>.deb`
- **Backend**: Qt6 WebEngine
- **Moteur**: Chromium 108+

## Test du package

Après installation:
```bash
# Vérifier la version
wkhtmltopdf --version

# Test simple
echo "<h1>Test</h1>" | wkhtmltopdf - test.pdf

# Test avec URL
wkhtmltopdf https://example.com example.pdf
```

## Désinstallation

```bash
sudo apt remove wkhtmltopdf-webengine  # Pour Qt5 (22.04)
# ou
sudo apt remove wkhtmltopdf-qt6         # Pour Qt6 (24.04)
```

## Résolution de problèmes

### Erreur: "Cannot detect Ubuntu version"
- Vérifiez que `/etc/lsb-release` existe
- Exécutez: `lsb_release -a`

### Erreur: "qmake not found"
- Ubuntu 22.04: Installez `qt5-default`
- Ubuntu 24.04: Installez `qt6-base-dev`

### Erreur de compilation
- Assurez-vous que toutes les dépendances sont installées
- Nettoyez: `make clean && rm -rf build-temp`
- Relancez le script

### Le binaire ne démarre pas
```bash
# Vérifier les dépendances manquantes
ldd /usr/local/bin/wkhtmltopdf

# Installer les dépendances Qt manquantes
sudo apt install --fix-broken
```

## Architecture du build

```
wkhtmltopdf/
├── build-deb.sh          # Script de build automatique
├── wkhtmltopdf.pro       # Projet Qt principal
├── common.pri            # Configuration commune
└── src/
    ├── lib/              # Bibliothèque wkhtmltox
    ├── pdf/              # Binaire wkhtmltopdf
    └── image/            # Binaire wkhtmltoimage
```

## Notes importantes

- **WebKit abandonné**: Seul WebEngine est supporté (meilleur support CSS3/HTML5)
- **Pas d'installation directe**: Seul le format .deb est supporté pour une installation propre
- **Alternatives**: Le script configure automatiquement les alternatives system
