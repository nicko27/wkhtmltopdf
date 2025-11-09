# Vérification Complète de la Compilation

## ✅ Configuration Vérifiée

### Fichiers de Configuration

#### 1. **common.pri**
Configuration principale des backends Qt.

**Variables importantes:**
- `RENDER_BACKEND` - Sélection du backend (webkit, webengine, both)
- Par défaut: `webkit` si non spécifié
- Support Qt5 et Qt6

**Backends supportés:**

```qmake
# Qt5 WebKit
contains(RENDER_BACKEND, webkit) {
    DEFINES += WKHTMLTOPDF_USE_WEBKIT
    QT += webkit webkitwidgets network xmlpatterns svg printsupport
}

# Qt5 WebEngine
contains(RENDER_BACKEND, webengine) {
    DEFINES += WKHTMLTOPDF_USE_WEBENGINE
    QT += webenginewidgets network xmlpatterns svg printsupport
}

# Qt6 (WebEngine uniquement, détecté automatiquement)
greaterThan(QT_MAJOR_VERSION, 5) {
    # Pas de xmlpatterns en Qt6
    QT += webenginewidgets network svg printsupport
}
```

#### 2. **VERSION**
Version actuelle: **0.13.0**

Pour Qt6, utiliser **1.0.0** (nouvelle major version).

---

## 🔧 Scripts de Build

### Script Principal: **build-all-variants.sh**

Ce script compile TOUTES les variantes automatiquement.

**Fonctionnalités:**
- ✅ Compilation Qt5 WebKit
- ✅ Compilation Qt5 WebEngine
- ✅ Compilation Qt6 WebEngine
- ✅ Création des .deb pour chaque variante
- ✅ Tests PDF automatiques
- ✅ Backup des binaires
- ✅ Vérification des dépendances
- ✅ Menu interactif

**Modes disponibles:**
1. **Mode complet** (compilation + .deb + tests)
2. **Compilation uniquement**
3. **Compilation + .deb**
4. **Compilation + tests**
5. **Variantes spécifiques**

### Utilisation

```bash
./build-all-variants.sh
```

**Menu:**
```
1) Compiler et tester TOUTES les variantes (recommandé)
2) Compiler uniquement (sans .deb ni tests)
3) Compiler + créer les .deb (sans tests)
4) Compiler + tests (sans .deb)
5) Choisir variantes spécifiques
```

---

## 📋 Checklist de Vérification

### Avant Compilation

- [ ] **Dépendances Qt5 installées**
  ```bash
  sudo apt-get install qt5-qmake qtbase5-dev libqt5webkit5-dev qtwebengine5-dev
  ```

- [ ] **Dépendances Qt6 installées (optionnel)**
  ```bash
  sudo apt-get install qt6-base-dev qt6-webengine-dev qmake6
  ```

- [ ] **Build essentials installés**
  ```bash
  sudo apt-get install build-essential git pkg-config
  ```

- [ ] **Vérifier qmake**
  ```bash
  qmake --version   # Qt5
  qmake6 --version  # Qt6
  ```

### Pendant Compilation

- [ ] **Configuration réussie**
  - `qmake` doit se terminer sans erreur
  - Vérifier que le bon backend est sélectionné

- [ ] **Compilation réussie**
  - `make` doit se terminer sans erreur
  - Aucun warning critique

- [ ] **Binaires créés**
  - `bin/wkhtmltopdf` existe
  - `bin/wkhtmltoimage` existe
  - `bin/libwkhtmltox.so.*` existe

### Après Compilation

- [ ] **Version correcte**
  ```bash
  ./bin/wkhtmltopdf --version
  # Doit afficher 0.13.0 pour Qt5, 1.0.0 pour Qt6
  ```

- [ ] **Backend correct**
  ```bash
  ./bin/wkhtmltopdf --help | grep render-backend
  # Doit lister les backends disponibles
  ```

- [ ] **Dépendances vérifiées**
  ```bash
  ldd bin/wkhtmltopdf | grep -i qt
  # Doit lister toutes les libs Qt nécessaires
  ```

- [ ] **Test fonctionnel**
  ```bash
  echo "<html><body><h1>Test</h1></body></html>" > test.html
  ./bin/wkhtmltopdf test.html test.pdf
  # Doit créer test.pdf sans erreur
  ```

---

## 🚦 Étapes de Validation

### Étape 1: Compilation Qt5 WebKit

```bash
# Nettoyer
make clean
rm -rf bin/

# Configurer
RENDER_BACKEND=webkit qmake

# Compiler
make -j$(nproc)

# Vérifier
./bin/wkhtmltopdf --version
./bin/wkhtmltopdf --help | grep webkit
```

**Attendu:**
- Version: 0.13.0
- Backend: webkit disponible
- Taille binaire: ~5-10 MB

### Étape 2: Compilation Qt5 WebEngine

```bash
# Nettoyer
make clean
rm -rf bin/

# Configurer
RENDER_BACKEND=webengine qmake

# Compiler
make -j$(nproc)

# Vérifier
./bin/wkhtmltopdf --version
./bin/wkhtmltopdf --help | grep webengine
```

**Attendu:**
- Version: 0.13.0
- Backend: webengine disponible
- Taille binaire: ~10-15 MB (+ dépendances Chromium)

### Étape 3: Compilation Qt6 WebEngine

```bash
# Vérifier Qt6
qmake6 --version

# Nettoyer
make clean
rm -rf bin/

# Configurer
qmake6

# Compiler
make -j$(nproc)

# Vérifier
./bin/wkhtmltopdf --version
```

**Attendu:**
- Version: 1.0.0
- Backend: webengine (uniquement, pas de webkit)
- Taille binaire: ~10-15 MB

---

## 🔍 Vérification des Dépendances

### Qt5 WebKit

```bash
ldd bin/wkhtmltopdf | grep -i libqt
```

**Attendu:**
```
libQt5WebKit.so.5
libQt5WebKitWidgets.so.5
libQt5Svg.so.5
libQt5XmlPatterns.so.5
libQt5Network.so.5
libQt5Gui.so.5
libQt5Core.so.5
```

### Qt5 WebEngine

```bash
ldd bin/wkhtmltopdf | grep -i libqt
```

**Attendu:**
```
libQt5WebEngineCore.so.5
libQt5WebEngineWidgets.so.5
libQt5PrintSupport.so.5
libQt5Svg.so.5
libQt5XmlPatterns.so.5
libQt5Network.so.5
libQt5Gui.so.5
libQt5Core.so.5
```

### Qt6 WebEngine

```bash
ldd bin/wkhtmltopdf | grep -i libqt
```

**Attendu:**
```
libQt6WebEngineCore.so.6
libQt6WebEngineWidgets.so.6
libQt6PrintSupport.so.6
libQt6Svg.so.6
libQt6Network.so.6
libQt6Gui.so.6
libQt6Core.so.6
```

**Note:** Pas de `libQt6XmlPatterns` (supprimé en Qt6)

---

## 📦 Création des .deb

### Validation du Paquet

Après création du .deb:

```bash
# Vérifier le contenu
dpkg-deb --info wkhtmltopdf-webengine_*.deb

# Vérifier les fichiers
dpkg-deb --contents wkhtmltopdf-webengine_*.deb | grep bin

# Vérifier les dépendances
dpkg-deb --field wkhtmltopdf-webengine_*.deb Depends
```

**Attendu:**
- Binaires dans `/usr/local/bin/`
- Bibliothèques dans `/usr/local/lib/`
- Toutes les dépendances Qt listées

---

## 🧪 Tests

### Test Basique

```bash
./bin/wkhtmltopdf test-full-css.html test.pdf
```

**Attendu:**
- PDF créé sans erreur
- Taille: 400-600 KB
- Rendu correct selon le backend

### Test des 3 Backends

```bash
./test-all-backends.sh
```

**Attendu:**
- 3 PDFs générés dans `test-results/`
- WebKit: layout cassé (normal)
- WebEngine Qt5: rendu excellent
- WebEngine Qt6: rendu parfait

---

## ⚠️ Problèmes Courants

### Erreur: "No rendering backend selected"

**Cause:** `RENDER_BACKEND` non défini

**Solution:**
```bash
RENDER_BACKEND=webengine qmake
```

### Erreur: "Qt WebEngine requires Qt 5.4+"

**Cause:** Qt trop ancien

**Solution:**
```bash
sudo apt-get update
sudo apt-get install qtwebengine5-dev
```

### Erreur: "qmake6: command not found"

**Cause:** Qt6 non installé

**Solution:**
```bash
./install-qt6-ubuntu.sh
# Ou
sudo apt-get install qt6-base-dev qmake6
```

### Erreur de compilation: "undefined reference to..."

**Cause:** Dépendances Qt manquantes

**Solution:**
```bash
# Qt5
sudo apt-get install libqt5webkit5-dev qtwebengine5-dev

# Qt6
sudo apt-get install qt6-webengine-dev
```

### Binaire créé mais crash au lancement

**Cause:** Dépendances manquantes

**Solution:**
```bash
ldd bin/wkhtmltopdf | grep "not found"
# Installer les libs manquantes
```

---

## 📊 Résultats Attendus

### Tailles des Binaires

| Variante | Binaire | Lib .so | .deb |
|----------|---------|---------|------|
| Qt5 WebKit | ~6 MB | ~20 MB | ~40 MB |
| Qt5 WebEngine | ~12 MB | ~25 MB | ~200 MB* |
| Qt6 WebEngine | ~12 MB | ~25 MB | ~220 MB* |

*Avec dépendances Chromium

### Tailles des PDFs de Test

| Backend | PDF | Qualité |
|---------|-----|---------|
| WebKit | ~200 KB | Basique |
| WebEngine Qt5 | ~500 KB | Excellent |
| WebEngine Qt6 | ~500 KB | Parfait |

---

## 🚀 Workflow Complet

### Commande Unique

Pour tout compiler et tester en une seule fois:

```bash
./build-all-variants.sh
# Choisir option 1: "Compiler et tester TOUTES les variantes"
```

**Ce script va:**
1. Vérifier les dépendances Qt5/Qt6
2. Compiler Qt5 WebKit
3. Créer wkhtmltopdf-webkit_*.deb
4. Tester et générer test-webkit.pdf
5. Compiler Qt5 WebEngine
6. Créer wkhtmltopdf-webengine_*.deb
7. Tester et générer test-webengine-qt5.pdf
8. Compiler Qt6 WebEngine (si disponible)
9. Créer wkhtmltopdf-qt6_*.deb
10. Tester et générer test-webengine-qt6.pdf

**Durée totale:** ~30-60 minutes

---

## ✅ Validation Finale

Après le build complet, vérifier:

- [ ] 3 binaires compilés et sauvegardés
- [ ] 3 paquets .deb créés
- [ ] 3 PDFs de test générés
- [ ] Aucune dépendance manquante
- [ ] Tous les tests passent

```bash
# Vérifier les fichiers générés
ls -lh wkhtmltopdf-*.deb
ls -lh test-results/*.pdf
ls -R build-variants-backup/

# Tester un .deb
sudo dpkg -i wkhtmltopdf-webengine_*.deb
wkhtmltopdf --version
wkhtmltopdf test-full-css.html final-test.pdf
```

---

## 📚 Documentation

- **common.pri** - Configuration des backends
- **build-all-variants.sh** - Script de build complet
- **test-all-backends.sh** - Tests automatiques
- **check-dependencies.sh** - Vérification dépendances
- **BUILD_VERIFICATION.md** - Ce fichier

---

**Status:** ✅ Configuration vérifiée et validée
**Date:** 9 Novembre 2024
**Script:** build-all-variants.sh (complet)
