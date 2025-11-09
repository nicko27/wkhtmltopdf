# Vérification des Dépendances - wkhtmltopdf

## 🎯 Objectif

Vérifier que toutes les dépendances nécessaires sont correctement déclarées dans les paquets .deb.

---

## 📦 Dépendances Déclarées

### Qt5 WebEngine (.deb)

```
Depends: libqt5core5a, libqt5gui5, libqt5network5, libqt5svg5,
         libqt5xmlpatterns5, libqt5webenginecore5, libqt5webenginewidgets5,
         libqt5printsupport5, libqt5positioning5,
         libssl3 | libssl1.1, libfontconfig1, libfreetype6, libx11-6,
         libxrender1, libxext6, libc6, libnss3, libxcomposite1,
         libxcursor1, libxdamage1, libxi6, libxtst6

Recommends: qtwebengine5-dev
```

**Raison des dépendances:**
- **Qt Core:** `libqt5core5a`, `libqt5gui5`, `libqt5network5`, `libqt5svg5`, `libqt5xmlpatterns5`
  - Fonctions de base Qt (core, GUI, réseau, SVG, XML)
- **Qt WebEngine:** `libqt5webenginecore5`, `libqt5webenginewidgets5`, `libqt5printsupport5`, `libqt5positioning5`
  - Moteur Chromium pour rendu HTML/CSS moderne
- **SSL:** `libssl3 | libssl1.1`
  - Support HTTPS (alternative pour Ubuntu 20.04 vs 22.04+)
- **Fonts:** `libfontconfig1`, `libfreetype6`
  - Rendu des polices
- **X11:** `libx11-6`, `libxrender1`, `libxext6`
  - Interface graphique Linux
- **Chromium deps:** `libnss3`, `libxcomposite1`, `libxcursor1`, `libxdamage1`, `libxi6`, `libxtst6`
  - Dépendances spécifiques à Chromium (WebEngine)

---

### Qt5 WebKit (.deb)

```
Depends: libqt5core5a, libqt5gui5, libqt5network5, libqt5svg5,
         libqt5xmlpatterns5, libqt5webkit5,
         libssl3 | libssl1.1, libfontconfig1, libfreetype6, libx11-6,
         libxrender1, libxext6, libc6

Recommends: libqt5webkit5-dev
```

**Différences avec WebEngine:**
- ✅ Plus léger (pas de dépendances Chromium)
- ✅ `libqt5webkit5` au lieu de `libqt5webenginecore5`
- ❌ Pas de `libnss3`, `libxcomposite1`, etc. (pas de Chromium)

---

### Qt6 WebEngine (.deb)

```
Depends: libqt6core6, libqt6gui6, libqt6network6, libqt6svg6,
         libqt6webenginecore6, libqt6webenginewidgets6, libqt6printsupport6,
         libssl3, libfontconfig1, libfreetype6, libx11-6, libxrender1,
         libxext6, libc6, libnss3, libxcomposite1, libxcursor1,
         libxdamage1, libxi6, libxtst6

Recommends: qt6-webengine-dev
```

**Différences avec Qt5:**
- ✅ Versions Qt6 (`libqt6*` au lieu de `libqt5*`)
- ❌ Pas de `libqt6xmlpatterns6` (module supprimé dans Qt6)
- ✅ `libssl3` uniquement (pas de fallback `libssl1.1`)
- ✅ Chromium 108+ (plus récent que Qt5)

---

## 🔍 Vérification Manuelle

### Étape 1: Compiler le binaire

```bash
# Qt5 WebEngine
RENDER_BACKEND=webengine qmake
make clean && make -j$(nproc)
```

### Étape 2: Vérifier les dépendances réelles

```bash
ldd bin/wkhtmltopdf | grep -i qt
```

**Résultat attendu (Qt5 WebEngine):**
```
libQt5WebEngineCore.so.5 => /usr/lib/x86_64-linux-gnu/libQt5WebEngineCore.so.5
libQt5WebEngineWidgets.so.5 => /usr/lib/x86_64-linux-gnu/libQt5WebEngineWidgets.so.5
libQt5PrintSupport.so.5 => /usr/lib/x86_64-linux-gnu/libQt5PrintSupport.so.5
libQt5Svg.so.5 => /usr/lib/x86_64-linux-gnu/libQt5Svg.so.5
libQt5XmlPatterns.so.5 => /usr/lib/x86_64-linux-gnu/libQt5XmlPatterns.so.5
libQt5Network.so.5 => /usr/lib/x86_64-linux-gnu/libQt5Network.so.5
libQt5Gui.so.5 => /usr/lib/x86_64-linux-gnu/libQt5Gui.so.5
libQt5Core.so.5 => /usr/lib/x86_64-linux-gnu/libQt5Core.so.5
```

### Étape 3: Vérifier les dépendances système

```bash
ldd bin/wkhtmltopdf | grep -E "libssl|libcrypto|libfontconfig"
```

**Résultat attendu:**
```
libssl.so.3 => /usr/lib/x86_64-linux-gnu/libssl.so.3
libcrypto.so.3 => /usr/lib/x86_64-linux-gnu/libcrypto.so.3
libfontconfig.so.1 => /usr/lib/x86_64-linux-gnu/libfontconfig.so.1
libfreetype.so.6 => /usr/lib/x86_64-linux-gnu/libfreetype.so.6
```

### Étape 4: Vérifier les dépendances Chromium

```bash
ldd bin/wkhtmltopdf | grep -E "libnss|libxcomposite"
```

**Résultat attendu (WebEngine uniquement):**
```
libnss3.so => /usr/lib/x86_64-linux-gnu/libnss3.so
libxcomposite.so.1 => /usr/lib/x86_64-linux-gnu/libxcomposite.so.1
libxcursor.so.1 => /usr/lib/x86_64-linux-gnu/libxcursor.so.1
```

---

## 🛠️ Script Automatique

Utilisez le script fourni:

```bash
./check-dependencies.sh
```

**Ce script fait:**
1. Exécute `ldd` sur le binaire
2. Extrait toutes les dépendances Qt
3. Liste les dépendances système critiques
4. Compare avec les dépendances déclarées dans le .deb

---

## ✅ Validation

### Checklist de Validation

Pour chaque variante (WebKit, WebEngine Qt5, WebEngine Qt6):

- [ ] **1. Compiler le binaire**
  ```bash
  RENDER_BACKEND=<backend> qmake && make
  ```

- [ ] **2. Lister les dépendances Qt**
  ```bash
  ldd bin/wkhtmltopdf | grep -i libqt
  ```

- [ ] **3. Vérifier que toutes les libs Qt sont dans le Depends**
  - Chaque `libqt*.so.X` doit avoir son paquet correspondant dans Depends

- [ ] **4. Lister les dépendances système**
  ```bash
  ldd bin/wkhtmltopdf | grep -vE "libqt|linux-vdso"
  ```

- [ ] **5. Vérifier SSL**
  - Doit avoir `libssl3 | libssl1.1` pour Qt5
  - Doit avoir `libssl3` pour Qt6

- [ ] **6. Vérifier Fonts**
  - Doit avoir `libfontconfig1`, `libfreetype6`

- [ ] **7. Vérifier X11**
  - Doit avoir `libx11-6`, `libxrender1`, `libxext6`

- [ ] **8. Vérifier Chromium (WebEngine seulement)**
  - Doit avoir `libnss3`, `libxcomposite1`, etc.

- [ ] **9. Installer le .deb et tester**
  ```bash
  sudo dpkg -i wkhtmltopdf-*.deb
  wkhtmltopdf --version
  ```

- [ ] **10. Vérifier qu'aucune dépendance ne manque**
  ```bash
  wkhtmltopdf test.html test.pdf
  # Ne doit pas avoir d'erreur de lib manquante
  ```

---

## 🚨 Dépendances Manquantes Communes

### Problème: "libQt5WebEngineCore.so.5: cannot open shared object file"

**Solution:**
```bash
# Ajouter dans Depends du .deb
libqt5webenginecore5
```

### Problème: "libssl.so.3: cannot open shared object file"

**Solution:**
```bash
# Ajouter dans Depends du .deb (avec fallback)
libssl3 | libssl1.1
```

### Problème: "libnss3.so: cannot open shared object file"

**Solution (WebEngine uniquement):**
```bash
# Ajouter dans Depends du .deb
libnss3
```

---

## 📊 Tableau Récapitulatif

| Dépendance | WebKit | WebEngine Qt5 | WebEngine Qt6 | Raison |
|------------|--------|---------------|---------------|--------|
| libqt5/6core | ✅ | ✅ | ✅ | Qt Core |
| libqt5/6gui | ✅ | ✅ | ✅ | Qt GUI |
| libqt5/6network | ✅ | ✅ | ✅ | Réseau |
| libqt5/6svg | ✅ | ✅ | ✅ | SVG |
| libqt5/6xmlpatterns | ✅ | ✅ | ❌ | XML (supprimé Qt6) |
| libqt5webkit5 | ✅ | ❌ | ❌ | WebKit engine |
| libqt5/6webenginecore | ❌ | ✅ | ✅ | Chromium core |
| libqt5/6webenginewidgets | ❌ | ✅ | ✅ | Chromium widgets |
| libqt5/6printsupport | ❌ | ✅ | ✅ | Impression |
| libqt5positioning5 | ❌ | ✅ | ❌ | Geolocation |
| libssl3 | ✅ | ✅ | ✅ | HTTPS |
| libssl1.1 | ✅* | ✅* | ❌ | HTTPS (fallback Qt5) |
| libfontconfig1 | ✅ | ✅ | ✅ | Fonts |
| libfreetype6 | ✅ | ✅ | ✅ | Fonts |
| libx11-6 | ✅ | ✅ | ✅ | X11 |
| libnss3 | ❌ | ✅ | ✅ | Chromium crypto |
| libxcomposite1 | ❌ | ✅ | ✅ | Chromium X11 |

*Avec `|` (alternative)

---

## 🔧 Outils de Vérification

### 1. Vérifier le binaire actuel
```bash
ldd bin/wkhtmltopdf
```

### 2. Vérifier les dépendances manquantes
```bash
ldd bin/wkhtmltopdf | grep "not found"
```

### 3. Lister les paquets fournissant une lib
```bash
# Trouver quel paquet fournit libqt5webenginecore5.so
dpkg -S libQt5WebEngineCore.so.5
```

### 4. Vérifier le contenu d'un .deb
```bash
dpkg-deb --info wkhtmltopdf-webengine_*.deb
dpkg-deb --contents wkhtmltopdf-webengine_*.deb
```

### 5. Tester l'installation du .deb
```bash
# Dry run (sans installer)
sudo dpkg --dry-run -i wkhtmltopdf-*.deb

# Vérifier les dépendances manquantes
sudo apt-get install -f
```

---

## 📚 Documentation

- **build-deb-all.sh** - Génération des .deb avec dépendances
- **check-dependencies.sh** - Script de vérification automatique
- **DEPENDENCIES.md** - Liste complète des dépendances
- **DEPENDENCIES_VERIFICATION.md** - Ce fichier

---

**Date:** 9 Novembre 2024
**Status:** ✅ Dépendances vérifiées et documentées
