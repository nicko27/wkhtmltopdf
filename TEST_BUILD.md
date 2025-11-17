# Guide de Build - wkhtmltopdf WebEngine

## ⚠️ Problèmes Ubuntu 22.04 avec libwkhtmltox

### Symptômes connus:
- ❌ `error while loading shared libraries: libwkhtmltox.so.0: cannot open shared object file`
- ❌ Package compilé pour Ubuntu 24.04 installé sur 22.04
- ❌ libwkhtmltox.so.0 introuvable dans le cache ldconfig

### Correctifs appliqués automatiquement:
Le nouveau script `build-deb.sh` inclut tous les correctifs pour Ubuntu 22.04:

✅ **Bibliothèque partagée incluse** - libwkhtmltox.so.0 empaquetée dans le .deb
✅ **Configuration ldconfig automatique** - Crée `/etc/ld.so.conf.d/wkhtmltopdf.conf`
✅ **Dépendances Qt5 complètes** - Toutes les libs Qt5 WebEngine requises
✅ **Détection de conflits** - Supprime les packages incompatibles
✅ **Vérification post-installation** - Test automatique après install

## Configuration automatique

Le script `build-deb.sh` détecte automatiquement votre version Ubuntu et configure le build approprié:

- **Ubuntu 22.04** → Qt5 WebEngine (avec correctifs libwkhtmltox)
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

### Compilation rapide (sans packaging)

Une fois les dépendances installées, vous pouvez vérifier que la compilation fonctionne sans générer de paquet :

#### Ubuntu 22.04 (Qt5)
```bash
qmake RENDER_BACKEND=webengine wkhtmltopdf.pro
make -j"$(nproc)"
./bin/wkhtmltopdf --version
```

#### Ubuntu 24.04 (Qt6)
```bash
qmake6 RENDER_BACKEND=webengine wkhtmltopdf.pro
make -j"$(nproc)"
./bin/wkhtmltopdf --version
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

### ❌ Ubuntu 22.04: "libwkhtmltox.so.0: cannot open shared object file"

**Cause**: La bibliothèque partagée n'est pas dans le cache ldconfig

**Solution 1** (Recommandé): Utiliser le nouveau build-deb.sh
```bash
./build-deb.sh  # Applique automatiquement tous les correctifs
sudo apt install ./wkhtmltopdf-qt5-webengine_0.13.0-22.04_*.deb
```

**Solution 2**: Correction manuelle si déjà installé
```bash
# Reconfigurer ldconfig
sudo bash -c 'echo "/usr/local/lib" > /etc/ld.so.conf.d/wkhtmltopdf.conf'
sudo ldconfig

# Vérifier
ldconfig -p | grep libwkhtmltox  # Doit afficher la bibliothèque
wkhtmltopdf --version  # Doit fonctionner maintenant
```

**Solution 3**: Diagnostic complet
```bash
./diagnose-ubuntu2204.sh  # Analyse détaillée du problème
./fix-ubuntu2204-qt5.sh   # Assistant de réparation interactif
```

### ❌ Package incompatible détecté

**Symptôme**: Package ubuntu24.04 installé sur système 22.04

**Solution**:
```bash
# Désinstaller les packages incompatibles
sudo dpkg -r wkhtmltopdf-qt6 wkhtmltopdf-webengine

# Recompiler pour Ubuntu 22.04
./build-deb.sh
sudo apt install ./wkhtmltopdf-qt5-webengine_0.13.0-22.04_*.deb
```

### Erreur: "Cannot detect Ubuntu version"
- Vérifiez que `/etc/lsb-release` existe
- Exécutez: `lsb_release -a`

### Erreur: "qmake not found"
- Ubuntu 22.04: Installez `qtbase5-dev qt5-qmake`
- Ubuntu 24.04: Installez `qt6-base-dev`

### Erreur de compilation
- Assurez-vous que toutes les dépendances sont installées
- Nettoyez: `make clean && rm -rf build-temp`
- Relancez le script

### Le binaire ne démarre pas
```bash
# Vérifier les dépendances manquantes
ldd /usr/local/bin/wkhtmltopdf

# Ubuntu 22.04: Vérifier libwkhtmltox
ldconfig -p | grep libwkhtmltox

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
