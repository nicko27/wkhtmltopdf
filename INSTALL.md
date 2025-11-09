# Installation Guide

wkhtmltopdf avec support multi-backend pour CSS moderne (flex, grid, etc.)

## 🚀 Installation rapide

### Ubuntu/Debian

```bash
chmod +x install-ubuntu.sh
./install-ubuntu.sh
```

### macOS (avec Homebrew)

```bash
chmod +x install-macos.sh
./install-macos.sh
```

### Script universel (auto-détection)

```bash
chmod +x install.sh
./install.sh
```

## 📋 Prérequis

### Ubuntu/Debian

- Ubuntu 18.04+ ou Debian 10+
- `sudo` access
- Connection internet

Le script installera automatiquement :
- Build essentials (gcc, g++, make)
- Qt 5 avec WebKit et/ou WebEngine
- Toutes les dépendances nécessaires

### macOS

- macOS 10.13 (High Sierra) ou supérieur
- Homebrew installé ([https://brew.sh](https://brew.sh))
- Xcode Command Line Tools

Installation de Homebrew si nécessaire :

```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
```

## 🎯 Options d'installation

### Sélection du backend de rendu

Trois options disponibles :

1. **WebKit** (legacy) - Plus petit, CSS limité
2. **WebEngine** (moderne) - Plus gros, CSS3 complet
3. **Both** (les deux) - Choix au runtime (recommandé)

#### Installer avec WebEngine uniquement (modern CSS)

```bash
# Ubuntu
RENDER_BACKEND=webengine ./install-ubuntu.sh

# macOS
RENDER_BACKEND=webengine ./install-macos.sh

# Script universel
./install.sh --backend webengine
```

#### Installer avec les deux backends (recommandé)

```bash
# Ubuntu
RENDER_BACKEND=both ./install-ubuntu.sh

# macOS (WebKit non supporté, sera webengine)
./install-macos.sh

# Script universel
./install.sh --backend both
```

#### Installer avec WebKit uniquement (legacy)

```bash
# Ubuntu seulement (WebKit est déprécié sur macOS)
RENDER_BACKEND=webkit ./install-ubuntu.sh

# Script universel
./install.sh --backend webkit
```

### Préfixe d'installation personnalisé

Par défaut, l'installation se fait dans `/usr/local`. Pour changer :

```bash
# Installation dans /opt/wkhtmltopdf
INSTALL_PREFIX=/opt/wkhtmltopdf ./install.sh

# Ou avec l'option --prefix
./install.sh --prefix /opt/wkhtmltopdf
```

### Options avancées

```bash
# Voir toutes les options
./install.sh --help

# Compiler sans installer
./install.sh --no-install

# Nettoyer avant de compiler
./install.sh --clean

# Test uniquement (ne compile pas)
./install.sh --test-only
```

## 📦 Installation des dépendances seulement

### Ubuntu/Debian

```bash
# Mettre à jour les paquets
sudo apt-get update

# Dépendances de base
sudo apt-get install -y build-essential git pkg-config

# Pour WebKit
sudo apt-get install -y \
    qt5-qmake \
    qtbase5-dev \
    libqt5webkit5-dev \
    libqt5svg5-dev \
    libqt5xmlpatterns5-dev

# Pour WebEngine (CSS moderne)
sudo apt-get install -y \
    qt5-qmake \
    qtbase5-dev \
    qtwebengine5-dev \
    libqt5webenginewidgets5 \
    libqt5svg5-dev \
    libqt5xmlpatterns5-dev \
    libqt5printsupport5
```

### macOS

```bash
# Installer Homebrew si nécessaire
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# Installer Qt 5
brew install qt@5

# Configurer l'environnement Qt
export PATH="/usr/local/opt/qt@5/bin:$PATH"
export LDFLAGS="-L/usr/local/opt/qt@5/lib"
export CPPFLAGS="-I/usr/local/opt/qt@5/include"

# Pour Apple Silicon (M1/M2/M3)
export PATH="/opt/homebrew/opt/qt@5/bin:$PATH"
export LDFLAGS="-L/opt/homebrew/opt/qt@5/lib"
export CPPFLAGS="-I/opt/homebrew/opt/qt@5/include"
```

## 🔧 Compilation manuelle

Si vous préférez compiler manuellement :

```bash
# 1. Installer les dépendances (voir ci-dessus)

# 2. Configurer le backend
export RENDER_BACKEND=both  # ou webkit, ou webengine

# 3. Exécuter qmake
qmake INSTALLBASE=/usr/local

# 4. Compiler
make -j$(nproc)  # Linux
make -j$(sysctl -n hw.ncpu)  # macOS

# 5. Installer
sudo make install
```

### Compilation avec Qt personnalisé

```bash
# Si Qt est installé dans un chemin personnalisé
/path/to/qt/bin/qmake INSTALLBASE=/usr/local
make -j4
sudo make install
```

## ✅ Vérification de l'installation

### Test de base

```bash
# Vérifier la version
wkhtmltopdf --version

# Test simple
echo "<html><body><h1>Test</h1></body></html>" > test.html
wkhtmltopdf test.html test.pdf
```

### Test des backends

```bash
# Si compilé avec plusieurs backends
wkhtmltopdf --render-backend webkit test.html test-webkit.pdf
wkhtmltopdf --render-backend webengine test.html test-webengine.pdf
```

### Test du CSS moderne

```bash
# Tester avec la démo complète
cd examples
wkhtmltopdf --render-backend webengine modern_css_demo.html output.pdf

# Ouvrir le PDF
xdg-open output.pdf  # Linux
open output.pdf      # macOS
```

## 🐛 Dépannage

### Ubuntu/Debian

#### "Package qtwebengine5-dev not found"

```bash
# Activer le dépôt universe
sudo add-apt-repository universe
sudo apt-get update
sudo apt-get install qtwebengine5-dev
```

#### "Qt version too old"

```bash
# Vérifier la version de Qt
qmake --version

# Sur Ubuntu 18.04, vous devrez peut-être utiliser un PPA
sudo add-apt-repository ppa:beineri/opt-qt-5.15.2-bionic
sudo apt-get update
```

#### Erreurs de compilation

```bash
# Nettoyer et recompiler
make clean
rm -rf bin
RENDER_BACKEND=webkit ./install-ubuntu.sh  # Essayer avec WebKit seulement
```

### macOS

#### "Homebrew not found"

```bash
# Installer Homebrew
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# Suivre les instructions post-installation
# Pour Apple Silicon, ajouter à ~/.zshrc :
echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> ~/.zshrc
source ~/.zshrc
```

#### "Qt not found" ou "qmake: command not found"

```bash
# Réinstaller Qt
brew reinstall qt@5

# Vérifier le chemin (Intel Mac)
export PATH="/usr/local/opt/qt@5/bin:$PATH"

# Vérifier le chemin (Apple Silicon)
export PATH="/opt/homebrew/opt/qt@5/bin:$PATH"

# Vérifier qmake
which qmake
qmake --version
```

#### "Permission denied" lors de l'installation

```bash
# Vérifier les permissions sudo
sudo -v

# Si problème persiste, installer dans le home
./install-macos.sh --prefix "$HOME/.local"
```

#### Erreur "GPU process crashed" au runtime

```bash
# Désactiver l'accélération GPU
export QTWEBENGINE_CHROMIUM_FLAGS="--disable-gpu"
wkhtmltopdf input.html output.pdf
```

### Problèmes communs

#### "wkhtmltopdf: command not found" après installation

```bash
# Vérifier si installé
which wkhtmltopdf

# Si vide, ajouter au PATH
echo 'export PATH="/usr/local/bin:$PATH"' >> ~/.bashrc  # Linux
echo 'export PATH="/usr/local/bin:$PATH"' >> ~/.zshrc   # macOS
source ~/.bashrc  # ou source ~/.zshrc
```

#### Bibliothèques manquantes au runtime

```bash
# Linux : vérifier les dépendances
ldd /usr/local/bin/wkhtmltopdf

# Si des bibliothèques manquent
sudo ldconfig

# macOS : vérifier les dylibs
otool -L /usr/local/bin/wkhtmltopdf
```

## 📊 Comparaison des backends

| Critère | WebKit | WebEngine |
|---------|--------|-----------|
| **Taille binaire** | ~20-30 MB | ~100-200 MB |
| **Flexbox CSS** | ❌ Non | ✅ Oui |
| **Grid CSS** | ❌ Non | ✅ Oui |
| **CSS3 moderne** | ⚠️ Partiel | ✅ Complet |
| **JavaScript ES6+** | ❌ Non | ✅ Oui |
| **Vitesse** | Plus rapide | Légèrement plus lent |
| **Mémoire** | Moins | Plus |
| **Support macOS** | Déprécié | ✅ Supporté |

## 🔄 Mise à jour

Pour mettre à jour vers une nouvelle version :

```bash
# 1. Récupérer les dernières modifications
git pull

# 2. Nettoyer le build précédent
make clean
rm -rf bin

# 3. Réinstaller
./install.sh  # ou install-ubuntu.sh, install-macos.sh
```

## 🗑️ Désinstallation

```bash
# Depuis le répertoire source
sudo make uninstall

# Ou manuellement
sudo rm -f /usr/local/bin/wkhtmltopdf
sudo rm -f /usr/local/bin/wkhtmltoimage
sudo rm -rf /usr/local/lib/libwkhtmltox*
sudo rm -rf /usr/local/include/wkhtmltox
```

## 📚 Prochaines étapes

Après l'installation :

1. **Lire la documentation**
   ```bash
   cat MULTI_BACKEND.md
   ```

2. **Essayer les exemples**
   ```bash
   cd examples
   make demo
   ```

3. **Tester avec vos fichiers HTML**
   ```bash
   wkhtmltopdf --render-backend webengine myfile.html output.pdf
   ```

## 💡 Aide supplémentaire

- **Documentation complète** : `MULTI_BACKEND.md`
- **Issues GitHub** : [https://github.com/wkhtmltopdf/wkhtmltopdf/issues](https://github.com/wkhtmltopdf/wkhtmltopdf/issues)
- **Options CLI** : `wkhtmltopdf --help`
- **API C** : Voir `examples/backend_selector.c`

## 📝 Licence

LGPL v3 - Voir le fichier LICENSE pour plus de détails.
