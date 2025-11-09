# 🚀 COMMENCER ICI - wkhtmltopdf Multi-Backend

## ⚡ Démarrage Ultra-Rapide

### Une seule commande pour tout faire:

```bash
./build-all-variants.sh
```

Choisissez l'option **1** (Compiler et tester TOUTES les variantes)

**Résultat après 30-60 minutes:**
- ✅ 3 binaires compilés (Qt5 WebKit, Qt5 WebEngine, Qt6 WebEngine)
- ✅ 3 paquets .deb prêts à installer
- ✅ 3 PDFs de test pour comparaison visuelle

---

## 📋 Menu du Script

```
1) Compiler et tester TOUTES les variantes (recommandé) ⭐
2) Compiler uniquement (sans .deb ni tests)
3) Compiler + créer les .deb (sans tests)
4) Compiler + tests (sans .deb)
5) Choisir variantes spécifiques
```

---

## 🎯 Que fait le script ?

### Automatiquement:
1. Vérifie que Qt5/Qt6 sont installés
2. Compile Qt5 WebKit → Sauvegarde binaires
3. Compile Qt5 WebEngine → Sauvegarde binaires
4. Compile Qt6 WebEngine (si disponible) → Sauvegarde binaires
5. Crée wkhtmltopdf-webkit_*.deb
6. Crée wkhtmltopdf-webengine_*.deb
7. Crée wkhtmltopdf-qt6_*.deb
8. Génère test-webkit.pdf
9. Génère test-webengine-qt5.pdf
10. Génère test-webengine-qt6.pdf

### Vous obtenez:
```
📦 3 paquets .deb:
   wkhtmltopdf-webkit_0.13.0-ubuntu22.04_amd64.deb        (~40MB)
   wkhtmltopdf-webengine_0.13.0-ubuntu22.04_amd64.deb    (~200MB)
   wkhtmltopdf-qt6_1.0.0-ubuntu24.04_amd64.deb           (~220MB)

📄 3 PDFs de test:
   test-results/test-webkit.pdf                          (~200KB)
   test-results/test-webengine-qt5.pdf                   (~500KB)
   test-results/test-webengine-qt6.pdf                   (~500KB)

💾 Binaires sauvegardés:
   build-variants-backup/qt5-webkit/
   build-variants-backup/qt5-webengine/
   build-variants-backup/qt6-webengine/
```

---

## 🔧 Installation des Dépendances

Si vous n'avez pas encore Qt installé:

### Qt5 (Ubuntu 18.04+)
```bash
./install-ubuntu.sh
```

### Qt6 (Ubuntu 24.04+ uniquement)
```bash
./install-qt6-ubuntu.sh
```

---

## 📊 Comparaison Rapide

| Variante | Taille | CSS moderne | Use case |
|----------|--------|-------------|----------|
| **WebKit** | ~40MB | ❌ | HTML simple, léger |
| **WebEngine Qt5** | ~200MB | ✅ | CSS moderne (Flexbox, Grid) |
| **WebEngine Qt6** | ~220MB | ✅✅ | Dernier cri (Chromium 108+) |

---

## 🧪 Test Rapide

Après build, comparez les PDFs:

```bash
# Ouvrir les 3 PDFs côte à côte
open test-results/test-webkit.pdf
open test-results/test-webengine-qt5.pdf
open test-results/test-webengine-qt6.pdf
```

**Vous verrez:**
- WebKit: Layout cassé, pas de Grid/Flexbox
- WebEngine Qt5: Excellent rendu CSS moderne
- WebEngine Qt6: Parfait, tous les effets CSS

---

## 📦 Installation d'un Paquet

```bash
# Choisir selon vos besoins:

# Léger et rapide
sudo dpkg -i wkhtmltopdf-webkit_*.deb

# CSS moderne
sudo dpkg -i wkhtmltopdf-webengine_*.deb

# Dernier cri (Ubuntu 24.04+)
sudo dpkg -i wkhtmltopdf-qt6_*.deb
```

---

## ❓ Problèmes ?

### "qmake: command not found"
```bash
./install-ubuntu.sh
```

### "qmake6: command not found"
```bash
./install-qt6-ubuntu.sh
# Ou skip Qt6 (optionnel)
```

### Erreur de compilation
```bash
# Vérifier les dépendances
./check-dependencies.sh

# Réinstaller
./install-ubuntu.sh
```

---

## 📚 Documentation Complète

- **FINAL_SUMMARY.md** - Résumé complet du projet
- **BUILD_VERIFICATION.md** - Vérification étape par étape
- **GUIDE_VERSIONS.md** - Guide détaillé des 3 variantes
- **TEST_README.md** - Guide de test complet
- **QUICK_INSTALL.md** - Installation en 3 étapes

---

## ⚡ TL;DR

```bash
# 1. Installer dépendances
./install-ubuntu.sh

# 2. Tout compiler
./build-all-variants.sh
# → Choisir option 1

# 3. Attendre 30-60 minutes ☕

# 4. Comparer les PDFs
ls -lh test-results/

# 5. Installer un paquet
sudo dpkg -i wkhtmltopdf-webengine_*.deb

# 6. Tester
wkhtmltopdf test-full-css.html mon-test.pdf
```

---

## 🎉 C'est Parti !

```bash
./build-all-variants.sh
```

**Bonne compilation !** 🚀

---

**Version:** 0.13.0 (Qt5) / 1.0.0 (Qt6)
**Date:** 9 Novembre 2024
**Script:** build-all-variants.sh (600 lignes)
