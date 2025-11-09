# Dépendances wkhtmltopdf 0.13.0

## 📋 Dépendances pour compilation

### Dépendances essentielles (toujours requises)

```bash
# Outils de build
build-essential       # gcc, g++, make, etc.
git                   # Contrôle de version
pkg-config            # Configuration des bibliothèques

# Qt Base (requis pour tous les backends)
qt5-qmake             # Système de build Qt
qtbase5-dev           # Développement Qt5 de base
qtbase5-dev-tools     # Outils de développement Qt5

# Qt Modules supplémentaires
libqt5svg5-dev        # Support SVG
libqt5xmlpatterns5-dev # Support XML patterns
libqt5network5        # Support réseau

# Bibliothèques système
libssl-dev            # Support SSL/TLS
libfontconfig1-dev    # Configuration des polices
libfreetype6-dev      # Rendu des polices
libx11-dev            # X11 (interface graphique)
libxext-dev           # Extensions X11
libxrender-dev        # Rendu X11
```

### Backend WebKit (Legacy - CSS limité)

```bash
libqt5webkit5-dev     # Qt WebKit (~2012 CSS support)
```

**Capacités:**
- ❌ Pas de flexbox moderne
- ❌ Pas de CSS Grid
- ❌ CSS3 limité
- ✅ Plus petit binaire (~20-30 MB)
- ✅ Moins de dépendances

### Backend WebEngine (Moderne - CSS complet) - RECOMMANDÉ

```bash
qtwebengine5-dev          # Qt WebEngine (basé sur Chromium)
libqt5webenginewidgets5   # Widgets WebEngine
libqt5webenginecore5      # Core WebEngine
libqt5printsupport5       # Support d'impression
```

**Capacités:**
- ✅ **CSS Flexbox complet**
- ✅ **CSS Grid Layout**
- ✅ **CSS Transforms & Animations**
- ✅ **Modern JavaScript (ES6+)**
- ✅ **Gradients, shadows, etc.**
- ❌ Plus gros binaire (~100-200 MB)

### Backend Both (Les deux disponibles)

Pour compiler avec les deux backends (détection automatique au runtime):

```bash
# Installer toutes les dépendances ci-dessus
apt-get install -y \
    build-essential git pkg-config \
    qt5-qmake qtbase5-dev qtbase5-dev-tools \
    libqt5svg5-dev libqt5xmlpatterns5-dev libqt5network5 \
    libssl-dev libfontconfig1-dev libfreetype6-dev \
    libx11-dev libxext-dev libxrender-dev \
    libqt5webkit5-dev \
    qtwebengine5-dev libqt5webenginewidgets5 \
    libqt5webenginecore5 libqt5printsupport5
```

## 📦 Dépendances pour exécution (Runtime)

### Pour binaire WebKit

```bash
libqt5core5a          # Qt Core
libqt5gui5            # Qt GUI
libqt5network5        # Qt Network
libqt5webkit5         # Qt WebKit
libqt5svg5            # Qt SVG
libqt5xmlpatterns5    # Qt XML Patterns
libssl1.1 | libssl3   # OpenSSL (version selon distribution)
libfontconfig1        # FontConfig
libfreetype6          # FreeType
libx11-6              # X11
libxrender1           # X Render
libxext6              # X Extensions
```

### Pour binaire WebEngine

```bash
# Toutes les dépendances WebKit, plus:
libqt5webengine5          # Qt WebEngine runtime
libqt5webenginecore5      # WebEngine core
libqt5webenginewidgets5   # WebEngine widgets
libqt5printsupport5       # Print support
libqt5positioning5        # Positioning (requis par WebEngine)

# Dépendances Chromium (WebEngine est basé sur Chromium)
libnss3                   # Network Security Services
libxcomposite1            # X Composite extension
libxcursor1               # X Cursor
libxdamage1               # X Damage extension
libxi6                    # X Input extension
libxtst6                  # X Test extension
libasound2                # ALSA sound library
libatk1.0-0               # Accessibility toolkit
libatk-bridge2.0-0        # Accessibility bridge
libcups2                  # Common UNIX Printing System
libdrm2                   # Direct Rendering Manager
libgbm1                   # Generic Buffer Management
```

## 🐧 Par distribution Linux

### Ubuntu 20.04 LTS (Focal)

```bash
# Build
sudo apt-get install -y \
    build-essential git pkg-config \
    qt5-qmake qtbase5-dev qtbase5-dev-tools \
    libqt5svg5-dev libqt5xmlpatterns5-dev libqt5network5 \
    libssl-dev libfontconfig1-dev libfreetype6-dev \
    libx11-dev libxext-dev libxrender-dev \
    qtwebengine5-dev libqt5webenginewidgets5 \
    libqt5webenginecore5 libqt5printsupport5

# Runtime (installé automatiquement avec les dépendances de build)
```

### Ubuntu 22.04 LTS (Jammy)

```bash
# Identique à Ubuntu 20.04, avec libssl3 au lieu de libssl1.1
sudo apt-get install -y \
    build-essential git pkg-config \
    qt5-qmake qtbase5-dev qtbase5-dev-tools \
    libqt5svg5-dev libqt5xmlpatterns5-dev libqt5network5 \
    libssl-dev libfontconfig1-dev libfreetype6-dev \
    libx11-dev libxext-dev libxrender-dev \
    qtwebengine5-dev libqt5webenginewidgets5 \
    libqt5webenginecore5 libqt5printsupport5
```

### Debian 11 (Bullseye)

```bash
sudo apt-get install -y \
    build-essential git pkg-config \
    qt5-qmake qtbase5-dev qtbase5-dev-tools \
    libqt5svg5-dev libqt5xmlpatterns5-dev libqt5network5 \
    libssl-dev libfontconfig1-dev libfreetype6-dev \
    libx11-dev libxext-dev libxrender-dev \
    qtwebengine5-dev libqt5webenginewidgets5 \
    libqt5webenginecore5 libqt5printsupport5
```

### Debian 12 (Bookworm)

```bash
# Identique à Debian 11
sudo apt-get install -y \
    build-essential git pkg-config \
    qt5-qmake qtbase5-dev qtbase5-dev-tools \
    libqt5svg5-dev libqt5xmlpatterns5-dev libqt5network5 \
    libssl-dev libfontconfig1-dev libfreetype6-dev \
    libx11-dev libxext-dev libxrender-dev \
    qtwebengine5-dev libqt5webenginewidgets5 \
    libqt5webenginecore5 libqt5printsupport5
```

## 📊 Résumé des dépendances

| Catégorie | Nombre de paquets | Taille approximative |
|-----------|-------------------|---------------------|
| **Build essentiels** | ~10 | ~50 MB |
| **Qt Base** | ~5 | ~30 MB |
| **WebKit** | ~1 | ~20 MB |
| **WebEngine** | ~4 | ~150 MB |
| **Runtime WebKit** | ~15 | ~40 MB |
| **Runtime WebEngine** | ~25 | ~200 MB |

## 🔍 Vérifier les dépendances installées

```bash
# Vérifier si Qt5 est installé
qmake --version

# Vérifier les bibliothèques Qt disponibles
pkg-config --list-all | grep -i qt5

# Vérifier une bibliothèque spécifique
dpkg -l | grep libqt5webkit5-dev
dpkg -l | grep qtwebengine5-dev

# Vérifier les dépendances runtime d'un binaire
ldd /usr/local/bin/wkhtmltopdf

# Vérifier les bibliothèques partagées
ldconfig -p | grep wkhtmltox
```

## 🛠️ Installation minimale (WebKit uniquement)

Si vous voulez juste WebKit (plus petit):

```bash
sudo apt-get install -y \
    build-essential git pkg-config \
    qt5-qmake qtbase5-dev qtbase5-dev-tools \
    libqt5svg5-dev libqt5xmlpatterns5-dev libqt5network5 \
    libssl-dev libfontconfig1-dev libfreetype6-dev \
    libx11-dev libxext-dev libxrender-dev \
    libqt5webkit5-dev

# Build
RENDER_BACKEND=webkit qmake
make
```

**Taille totale:** ~150 MB de dépendances

## 🚀 Installation complète (WebEngine - Recommandé)

Pour le support CSS moderne complet:

```bash
sudo apt-get install -y \
    build-essential git pkg-config \
    qt5-qmake qtbase5-dev qtbase5-dev-tools \
    libqt5svg5-dev libqt5xmlpatterns5-dev libqt5network5 \
    libssl-dev libfontconfig1-dev libfreetype6-dev \
    libx11-dev libxext-dev libxrender-dev \
    qtwebengine5-dev libqt5webenginewidgets5 \
    libqt5webenginecore5 libqt5printsupport5

# Build
RENDER_BACKEND=webengine qmake
make
```

**Taille totale:** ~400 MB de dépendances

## 📝 Notes

1. **OpenSSL**: La version varie selon la distribution
   - Ubuntu 20.04: `libssl1.1`
   - Ubuntu 22.04+: `libssl3`

2. **WebEngine non disponible**: Sur certains anciens systèmes, WebEngine peut ne pas être disponible
   ```bash
   apt-cache show qtwebengine5-dev
   # Si erreur: utiliser WebKit uniquement
   ```

3. **Espace disque requis**:
   - Build WebKit: ~500 MB
   - Build WebEngine: ~2 GB
   - Installation: ~100-300 MB

4. **Mémoire requise pour compilation**:
   - WebKit: ~2 GB RAM
   - WebEngine: ~4 GB RAM

## 🆘 Résolution de problèmes

### Erreur: qtwebengine5-dev not found

```bash
# Ajouter universe repository
sudo add-apt-repository universe
sudo apt-get update
sudo apt-get install qtwebengine5-dev
```

### Erreur: cannot find -lQt5WebEngine

```bash
# Vérifier que WebEngine est bien installé
dpkg -l | grep qtwebengine

# Réinstaller si nécessaire
sudo apt-get install --reinstall qtwebengine5-dev
```

### Erreur de linking

```bash
# Mettre à jour le cache des bibliothèques
sudo ldconfig

# Vérifier le chemin
echo $LD_LIBRARY_PATH
```
