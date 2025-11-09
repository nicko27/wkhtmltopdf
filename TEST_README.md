# Guide de Test - wkhtmltopdf

## 📋 Fichiers de Test Créés

### 1. **test-full-css.html**
Fichier HTML complexe pour tester toutes les fonctionnalités CSS modernes.

**Fonctionnalités testées:**
- ✅ CSS Variables (custom properties)
- ✅ Flexbox
- ✅ CSS Grid
- ✅ Gradients (linear, radial, conic)
- ✅ Transforms 3D
- ✅ calc() function
- ✅ Animations
- ✅ Modern effects (backdrop-filter, clip-path, mix-blend-mode)
- ✅ Tableau comparatif des 3 backends

### 2. **test-all-backends.sh**
Script automatique pour tester les 3 backends et comparer les résultats.

### 3. **check-dependencies.sh**
Script pour vérifier que toutes les dépendances réelles sont dans les .deb.

---

## 🚀 Utilisation

### Test Manuel

#### Qt5 WebKit
```bash
wkhtmltopdf --render-backend webkit test-full-css.html test-webkit.pdf
```

#### Qt5 WebEngine
```bash
wkhtmltopdf --render-backend webengine test-full-css.html test-webengine-qt5.pdf
```

#### Qt6 WebEngine
```bash
# Après avoir compilé avec qmake6
wkhtmltopdf test-full-css.html test-webengine-qt6.pdf
```

---

### Test Automatique

```bash
./test-all-backends.sh
```

**Menu:**
```
1) Vérifier les dépendances du binaire actuel
2) Tester Qt5 WebKit
3) Tester Qt5 WebEngine
4) Tester Qt6 WebEngine
5) Tester TOUS les backends
```

**Résultats:** Les PDFs sont générés dans `test-results/`

---

### Vérification des Dépendances

```bash
./check-dependencies.sh
```

Ce script:
1. Analyse les dépendances réelles du binaire avec `ldd`
2. Liste les dépendances Qt
3. Liste les dépendances système
4. Compare avec les dépendances déclarées dans les .deb

---

## 📊 Résultats Attendus

### Qt5 WebKit (~40MB)
**Attendu:**
- ❌ Layout cassé (pas de Grid)
- ❌ Flexbox non fonctionnel
- ❌ Variables CSS ignorées
- ❌ calc() ne fonctionne pas
- ⚠️  Gradients basiques seulement
- ⚠️  Transforms basiques

**Apparence:**
- Les cartes empilées verticalement (pas de grille)
- Les couleurs peuvent être différentes (variables CSS ignorées)
- Spacing incorrect
- Effets modernes absents

### Qt5 WebEngine (~200MB)
**Attendu:**
- ✅ Layout correct avec Grid
- ✅ Flexbox parfait
- ✅ Variables CSS fonctionnent
- ✅ calc() fonctionne
- ✅ Tous les gradients (sauf conic parfois)
- ✅ Transforms 3D
- ⚠️  Quelques effets modernes limités

**Apparence:**
- Rendu professionnel
- Grille 3 colonnes
- Couleurs correctes
- Spacing correct
- La plupart des effets visibles

### Qt6 WebEngine (~220MB)
**Attendu:**
- ✅ Tout fonctionne parfaitement
- ✅ Tous les gradients (y compris conic)
- ✅ Tous les effets modernes
- ✅ Meilleure qualité de rendu

**Apparence:**
- Rendu parfait
- Tous les effets CSS visibles
- Qualité maximale

---

## 📸 Comparaison Visuelle

### Page 1: Header et Features

| Backend | Grid | Flexbox | Variables | Gradients |
|---------|------|---------|-----------|-----------|
| WebKit | ❌ | ❌ | ❌ | ⚠️ |
| WebEngine Qt5 | ✅ | ✅ | ✅ | ✅ |
| WebEngine Qt6 | ✅ | ✅ | ✅ | ✅✅ |

### Page 2: Effects et Tableau

| Backend | Transforms | calc() | Backdrop | Clip-path |
|---------|------------|--------|----------|-----------|
| WebKit | ⚠️ | ❌ | ❌ | ❌ |
| WebEngine Qt5 | ✅ | ✅ | ⚠️ | ✅ |
| WebEngine Qt6 | ✅ | ✅ | ✅ | ✅ |

---

## 🔍 Vérifier les Dépendances

### Dépendances Qt5 WebEngine attendues:
```
libqt5core5a
libqt5gui5
libqt5network5
libqt5svg5
libqt5xmlpatterns5
libqt5webenginecore5
libqt5webenginewidgets5
libqt5printsupport5
libqt5positioning5
```

### Dépendances Qt5 WebKit attendues:
```
libqt5core5a
libqt5gui5
libqt5network5
libqt5svg5
libqt5xmlpatterns5
libqt5webkit5
```

### Dépendances Qt6 WebEngine attendues:
```
libqt6core6
libqt6gui6
libqt6network6
libqt6svg6
libqt6webenginecore6
libqt6webenginewidgets6
libqt6printsupport6
```

**Note:** Qt6 n'a PAS `libqt6xmlpatterns6` (module supprimé)

---

## 🐛 Dépannage

### Le binaire n'existe pas
```bash
# Compiler d'abord
RENDER_BACKEND=webengine qmake
make clean && make -j$(nproc)
```

### "Backend not available"
```bash
# Vérifier les backends disponibles
bin/wkhtmltopdf --help | grep -A5 "render-backend"
```

### Dépendances manquantes
```bash
# Vérifier avec ldd
ldd bin/wkhtmltopdf | grep "not found"

# Installer les dépendances manquantes
sudo apt-get install libqt5webenginecore5
```

### PDF vide ou erreur
```bash
# Vérifier les permissions
chmod 644 test-full-css.html

# Tester avec verbose
wkhtmltopdf --verbose --render-backend webengine test-full-css.html test.pdf
```

---

## 📋 Checklist de Test

Avant de distribuer les .deb, vérifiez:

- [ ] Compiler avec Qt5 WebKit → Tester
- [ ] Compiler avec Qt5 WebEngine → Tester
- [ ] Compiler avec Qt6 WebEngine → Tester
- [ ] Vérifier les dépendances avec `ldd`
- [ ] Comparer les dépendances avec les .deb
- [ ] Générer les 3 PDFs de test
- [ ] Comparer visuellement les PDFs
- [ ] Vérifier la taille des PDFs
- [ ] Vérifier qu'aucune dépendance ne manque

---

## 📦 Workflow Complet

### 1. Compiler Qt5 WebKit
```bash
make clean
RENDER_BACKEND=webkit qmake
make -j$(nproc)
./test-all-backends.sh  # Choisir option 2
```

### 2. Compiler Qt5 WebEngine
```bash
make clean
RENDER_BACKEND=webengine qmake
make -j$(nproc)
./test-all-backends.sh  # Choisir option 3
```

### 3. Compiler Qt6 WebEngine
```bash
make clean
qmake6
make -j$(nproc)
./test-all-backends.sh  # Choisir option 4
```

### 4. Comparer les PDFs
```bash
ls -lh test-results/
# Ouvrir chaque PDF et comparer visuellement
```

### 5. Vérifier les dépendances
```bash
./check-dependencies.sh
```

### 6. Générer les .deb
```bash
./build-deb-all.sh
# Option 5: Construire TOUTES les variantes
```

---

## 📚 Fichiers Générés

Après les tests, vous aurez:

```
test-results/
├── test-webkit.pdf              # Qt5 WebKit
├── test-webengine-qt5.pdf       # Qt5 WebEngine
└── test-webengine-qt6.pdf       # Qt6 WebEngine
```

**Tailles attendues:**
- WebKit: ~200-300 KB (rendu simple)
- WebEngine Qt5: ~400-600 KB (rendu complet)
- WebEngine Qt6: ~400-600 KB (rendu optimal)

---

## ✅ Validation

Le test est réussi si:

1. **WebKit:** PDF généré mais layout cassé (attendu)
2. **WebEngine Qt5:** PDF parfait avec CSS moderne
3. **WebEngine Qt6:** PDF parfait avec tous les effets
4. **Dépendances:** Toutes les libs détectées par `ldd` sont dans le .deb
5. **Taille:** PDF raisonnable (~500KB max)

---

## 📖 Documentation

- `test-full-css.html` - Fichier HTML de test
- `test-all-backends.sh` - Script de test automatique
- `check-dependencies.sh` - Vérification des dépendances
- `TEST_README.md` - Ce fichier

Pour plus d'infos:
- `GUIDE_VERSIONS.md` - Guide des variantes
- `DEPENDENCIES.md` - Liste des dépendances
- `MULTI_BACKEND.md` - Différences backends

---

**Date:** 9 Novembre 2024
**Version:** 0.13.0 (Qt5) / 1.0.0 (Qt6)
