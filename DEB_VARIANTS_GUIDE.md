# Guide des Variantes .deb - wkhtmltopdf 0.13.0

## 🎯 Deux variantes disponibles

### 1. wkhtmltopdf-**webengine** (Gros moteur - CSS moderne)

**Moteur:** Qt WebEngine (Chromium)

**Taille:** ~10-20 MB (.deb) → ~200 MB installé

**Fonctionnalités:**
- ✅ **CSS Flexbox** complet
- ✅ **CSS Grid Layout** complet
- ✅ **CSS Transforms & Animations**
- ✅ **Gradients, shadows, modern CSS3**
- ✅ **JavaScript moderne (ES6+)**

**Pour qui:**
- Sites web modernes
- Applications avec CSS complexe
- Designs avec Flexbox/Grid
- Contenu avec animations

**Dépendances:** ~200 MB (Chromium + Qt WebEngine)

---

### 2. wkhtmltopdf-**webkit** (Petit moteur - Legacy)

**Moteur:** Qt WebKit (Legacy)

**Taille:** ~2-5 MB (.deb) → ~40 MB installé

**Fonctionnalités:**
- ✅ HTML basique
- ✅ CSS simple (tableaux, float)
- ⚠️ CSS3 limité (~2012)
- ❌ Pas de Flexbox moderne
- ❌ Pas de Grid Layout

**Pour qui:**
- HTML simple
- Factures, rapports basiques
- Installations limitées en espace
- Serveurs légers

**Dépendances:** ~40 MB (Qt WebKit uniquement)

---

## 📊 Comparaison

| Aspect | WebEngine | WebKit |
|--------|-----------|--------|
| **Taille .deb** | 10-20 MB | 2-5 MB |
| **Taille installée** | ~200 MB | ~40 MB |
| **CSS Flexbox** | ✅ Complet | ❌ Non |
| **CSS Grid** | ✅ Complet | ❌ Non |
| **CSS Transforms** | ✅ Oui | ⚠️ Limité |
| **Gradients** | ✅ Oui | ⚠️ Basique |
| **JavaScript** | ✅ ES6+ | ⚠️ ES5 |
| **Mémoire** | ~200-500 MB | ~100-200 MB |
| **Vitesse** | Moyen | Rapide |
| **Maintenance** | ✅ Active | ⚠️ Legacy |

---

## 🚀 Construction des paquets

### Méthode simple (script interactif)

```bash
./build-deb-variants.sh
```

**Menu:**
```
1) WebEngine uniquement (gros, CSS moderne)
2) WebKit uniquement (petit, legacy)
3) Les deux
```

### Méthode manuelle

#### WebEngine

```bash
# 1. Compiler
make clean
RENDER_BACKEND=webengine qmake
make -j$(nproc)

# 2. Générer le paquet
./build-deb-variants.sh
# Choisir option 1
```

**Résultat:**
- `wkhtmltopdf-webengine_0.13.0-ubuntu22.04_amd64.deb`

#### WebKit

```bash
# 1. Compiler
make clean
RENDER_BACKEND=webkit qmake
make -j$(nproc)

# 2. Générer le paquet
./build-deb-variants.sh
# Choisir option 2
```

**Résultat:**
- `wkhtmltopdf-webkit_0.13.0-ubuntu22.04_amd64.deb`

#### Les deux (automatique)

```bash
./build-deb-variants.sh
# Choisir option 3

# Le script va:
# 1. Compiler avec WebEngine
# 2. Générer le .deb WebEngine
# 3. Recompiler avec WebKit
# 4. Générer le .deb WebKit
```

---

## 📦 Installation

### WebEngine

```bash
sudo dpkg -i wkhtmltopdf-webengine_0.13.0-ubuntu22.04_amd64.deb
sudo apt-get install -f  # Installer les dépendances
```

### WebKit

```bash
sudo dpkg -i wkhtmltopdf-webkit_0.13.0-ubuntu22.04_amd64.deb
sudo apt-get install -f
```

### ⚠️ Important: Conflict

Les deux variantes **ne peuvent PAS** être installées en même temps:
```
Conflicts: wkhtmltopdf-webkit, wkhtmltopdf-webengine
```

Pour changer de variante:
```bash
# Désinstaller l'ancienne
sudo dpkg -r wkhtmltopdf-webkit

# Installer la nouvelle
sudo dpkg -i wkhtmltopdf-webengine_0.13.0-ubuntu22.04_amd64.deb
```

---

## 🔄 Compatibilité Ubuntu

### Règle importante

```
Compilé sur 22.04 → Fonctionne sur 24.04 ✅
Compilé sur 24.04 → NE fonctionne PAS sur 22.04 ❌
```

### Votre cas (VM Ubuntu 22.04)

**Paquets compilés sur votre VM:**
- ✅ Fonctionneront sur Ubuntu 22.04
- ✅ Fonctionneront sur Ubuntu 24.04
- ⚠️ Pourraient ne PAS fonctionner sur Ubuntu 20.04

### Pour maximum de compatibilité

Compiler sur Ubuntu 20.04 LTS:
```bash
# Via Docker
docker run -it --rm -v $(pwd):/workspace ubuntu:20.04 bash
# ... installer dépendances ...
./build-deb-variants.sh
```

Les paquets fonctionneront sur **toutes** les versions récentes.

Voir `UBUNTU_COMPATIBILITY.md` pour détails.

---

## 🎯 Quel paquet choisir ?

### Choisissez WebEngine si:

- ✅ Vous utilisez CSS moderne (Flexbox, Grid)
- ✅ Vous avez de l'espace disque (~200 MB)
- ✅ Vous voulez le meilleur rendu
- ✅ Vos pages utilisent des frameworks modernes (Bootstrap 5, Tailwind)
- ✅ Vous avez assez de RAM (4+ GB)

### Choisissez WebKit si:

- ✅ Vous générez des PDFs simples (factures, rapports)
- ✅ Vous avez peu d'espace disque
- ✅ Vous voulez une installation légère
- ✅ Vous utilisez du HTML/CSS simple
- ✅ Serveur avec ressources limitées

### Exemple de décision

**HTML à convertir:**
```html
<!DOCTYPE html>
<html>
<head>
<style>
.container {
    display: grid;           /* ← Grid Layout */
    grid-template-columns: repeat(3, 1fr);
    gap: 20px;
}
.box {
    background: linear-gradient(45deg, #667eea, #764ba2); /* ← Gradient */
    padding: 20px;
}
</style>
</head>
<body>
<div class="container">
    <div class="box">Box 1</div>
    <div class="box">Box 2</div>
    <div class="box">Box 3</div>
</div>
</body>
</html>
```

**Résultat:**
- **WebEngine:** ✅ Parfait (Grid + Gradient rendus correctement)
- **WebKit:** ❌ Mauvais (Grid ignoré, Gradient basique)

→ **Utilisez WebEngine pour cet exemple**

---

## 📝 Nommage des paquets

### Format

```
wkhtmltopdf-{variant}_{version}-ubuntu{ubuntu_version}_{arch}.deb
```

### Exemples

```
wkhtmltopdf-webengine_0.13.0-ubuntu22.04_amd64.deb
wkhtmltopdf-webkit_0.13.0-ubuntu22.04_amd64.deb
wkhtmltopdf-webengine_0.13.0-ubuntu20.04_arm64.deb
```

**Composants:**
- `variant`: webengine ou webkit
- `version`: 0.13.0
- `ubuntu_version`: 20.04, 22.04, ou 24.04
- `arch`: amd64, arm64, armhf

---

## 🔍 Vérification après installation

```bash
# Version
wkhtmltopdf --version

# Backend utilisé
wkhtmltopdf --help | grep "Rendering backend"

# Taille du paquet
dpkg -s wkhtmltopdf-webengine | grep "Installed-Size"

# Fichiers installés
dpkg -L wkhtmltopdf-webengine

# Dépendances
apt-cache depends wkhtmltopdf-webengine
```

---

## 💡 Cas d'usage réels

### Cas 1: Factures PDF simples

**Besoin:** Générer 1000 factures/jour
**HTML:** Tableaux simples, pas de CSS complexe
**Serveur:** VPS 2 GB RAM

**Choix:** ✅ **WebKit**
- Plus rapide
- Moins de mémoire
- Installation légère

### Cas 2: Site web moderne

**Besoin:** Export de pages web en PDF
**HTML:** Bootstrap 5, Flexbox, Grid
**Serveur:** Dédié 8 GB RAM

**Choix:** ✅ **WebEngine**
- Rendu parfait
- Support CSS moderne
- Ressources suffisantes

### Cas 3: Rapports dynamiques

**Besoin:** Graphiques, charts, dashboards
**HTML:** Chart.js, CSS Grid
**Serveur:** Cloud avec autoscaling

**Choix:** ✅ **WebEngine**
- JavaScript moderne requis
- CSS complexe
- Ressources élastiques

---

## 🚦 Quick Start

### Installation rapide WebEngine

```bash
# Sur Ubuntu 22.04
./build-deb-variants.sh
# Choisir option 1

sudo dpkg -i wkhtmltopdf-webengine_0.13.0-ubuntu22.04_amd64.deb
sudo apt-get install -f

wkhtmltopdf --version
```

### Installation rapide WebKit

```bash
# Sur Ubuntu 22.04
./build-deb-variants.sh
# Choisir option 2

sudo dpkg -i wkhtmltopdf-webkit_0.13.0-ubuntu22.04_amd64.deb
sudo apt-get install -f

wkhtmltopdf --version
```

---

## 📚 Documentation complète

- **`UBUNTU_COMPATIBILITY.md`** - Compatibilité entre versions Ubuntu
- **`PACKAGING.md`** - Guide complet du packaging
- **`DEPENDENCIES.md`** - Liste des dépendances
- **`AUTO_BACKEND_DETECTION.md`** - Détection automatique backend

---

**Date:** 9 novembre 2024
**Version:** 0.13.0
**Variantes:** WebEngine (gros) + WebKit (petit)
