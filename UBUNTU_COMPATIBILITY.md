# Compatibilité entre versions Ubuntu - wkhtmltopdf

## 🔄 Règle générale de compatibilité

### ⚠️ IMPORTANT: Compatibilité ascendante uniquement

```
Ubuntu 22.04 → 24.04 ✅ (compilé sur ancienne, fonctionne sur nouvelle)
Ubuntu 24.04 → 22.04 ❌ (compilé sur nouvelle, NE fonctionne PAS sur ancienne)
```

### Pourquoi ?

Un binaire compilé sur une version **plus récente** dépend souvent de:
- **Versions plus récentes de bibliothèques** (libstdc++, glibc, Qt5)
- **Nouvelles fonctionnalités** du système
- **Nouveaux symboles** dans les bibliothèques

Ces dépendances ne sont **pas disponibles** sur les versions plus anciennes.

## 📊 Matrice de compatibilité wkhtmltopdf

| Compilé sur → Exécuté sur | Ubuntu 20.04 | Ubuntu 22.04 | Ubuntu 24.04 |
|---------------------------|--------------|--------------|--------------|
| **Ubuntu 20.04**          | ✅           | ✅           | ✅           |
| **Ubuntu 22.04**          | ❌           | ✅           | ✅           |
| **Ubuntu 24.04**          | ❌           | ❌           | ✅           |

### Légende
- ✅ = Fonctionne
- ❌ = Ne fonctionne PAS (dépendances manquantes)

## 🎯 Stratégie de packaging

### Option 1: Compiler sur la version la plus ancienne (RECOMMANDÉ)

```bash
# Compiler sur Ubuntu 20.04 LTS
# → Fonctionnera sur 20.04, 22.04, 24.04

./build-deb-variants.sh
# Génère: wkhtmltopdf-*_0.13.0-ubuntu20.04_amd64.deb
```

**Avantages:**
- ✅ Compatible avec toutes les versions Ubuntu récentes
- ✅ Un seul paquet à maintenir
- ✅ Maximum de compatibilité

**Inconvénients:**
- ❌ Utilise des bibliothèques plus anciennes
- ❌ Possibles optimisations manquées

### Option 2: Paquets spécifiques par version Ubuntu

```bash
# Sur Ubuntu 20.04
./build-deb-variants.sh
# → wkhtmltopdf-*_0.13.0-ubuntu20.04_amd64.deb

# Sur Ubuntu 22.04
./build-deb-variants.sh
# → wkhtmltopdf-*_0.13.0-ubuntu22.04_amd64.deb

# Sur Ubuntu 24.04
./build-deb-variants.sh
# → wkhtmltopdf-*_0.13.0-ubuntu24.04_amd64.deb
```

**Avantages:**
- ✅ Optimisé pour chaque version
- ✅ Utilise les dernières bibliothèques disponibles
- ✅ Meilleure performance potentielle

**Inconvénients:**
- ❌ Trois paquets à maintenir
- ❌ Plus de travail de build/test
- ❌ Risque d'erreur de choix pour l'utilisateur

## 📦 Versions de dépendances par Ubuntu

### Ubuntu 20.04 LTS (Focal)

```
Qt5: 5.12.8
libssl: libssl1.1
glibc: 2.31
gcc/g++: 9.4.0
```

### Ubuntu 22.04 LTS (Jammy)

```
Qt5: 5.15.3
libssl: libssl3
glibc: 2.35
gcc/g++: 11.4.0
```

### Ubuntu 24.04 LTS (Noble)

```
Qt5: 5.15.10
libssl: libssl3
glibc: 2.39
gcc/g++: 13.2.0
```

## 🔍 Vérifier la compatibilité d'un paquet

### Sur la machine cible

```bash
# 1. Vérifier les dépendances du paquet
dpkg-deb --info wkhtmltopdf-webengine_0.13.0-ubuntu24.04_amd64.deb

# 2. Extraire et vérifier les dépendances binaires
dpkg-deb -x wkhtmltopdf-webengine_0.13.0-ubuntu24.04_amd64.deb /tmp/test
ldd /tmp/test/usr/local/bin/wkhtmltopdf

# 3. Vérifier les symboles requis
readelf -V /tmp/test/usr/local/bin/wkhtmltopdf | grep GLIBC
```

### Exemple de sortie incompatible

```bash
$ ldd /tmp/test/usr/local/bin/wkhtmltopdf
libQt5WebEngineCore.so.5 => not found  # ← Problème !
libssl.so.3 => not found               # ← Problème sur 20.04
```

### Exemple de sortie compatible

```bash
$ ldd /usr/local/bin/wkhtmltopdf
libQt5WebEngineCore.so.5 => /usr/lib/x86_64-linux-gnu/libQt5WebEngineCore.so.5
libssl.so.3 => /usr/lib/x86_64-linux-gnu/libssl.so.3
# Toutes les bibliothèques trouvées ✅
```

## 🛠️ Solutions pour incompatibilité

### Problème: Paquet 24.04 sur 22.04

**Erreur:**
```
dpkg: dependency problems prevent installation of wkhtmltopdf-webengine:
 wkhtmltopdf-webengine depends on libssl3 (>= 3.0.9); however:
  Version of libssl3 on system is 3.0.2.
```

**Solutions:**

#### Solution 1: Recompiler sur 22.04 (RECOMMANDÉ)

```bash
# Sur une machine Ubuntu 22.04
git clone ...
cd wkhtmltopdf
./build-deb-variants.sh
# Choisir option 1 ou 2
```

#### Solution 2: Utiliser un conteneur Docker

```bash
# Créer un conteneur Ubuntu 22.04
docker run -it --rm -v $(pwd):/workspace ubuntu:22.04 bash

# Dans le conteneur
cd /workspace
apt-get update
apt-get install -y build-essential qt5-qmake qtbase5-dev ...
./build-deb-variants.sh
```

#### Solution 3: Backporter les dépendances (DÉCONSEILLÉ)

```bash
# Installer des versions plus récentes de bibliothèques
# ⚠️ Peut casser le système !
# NE PAS FAIRE sauf si vous savez ce que vous faites
```

## 📋 Recommandations par cas d'usage

### Cas 1: Distribution publique

```bash
# Compiler sur Ubuntu 20.04 LTS
# → Maximum de compatibilité
```

**Nom de paquet:**
- `wkhtmltopdf-webengine_0.13.0-ubuntu20.04_amd64.deb`
- `wkhtmltopdf-webkit_0.13.0-ubuntu20.04_amd64.deb`

**Compatible avec:**
- ✅ Ubuntu 20.04, 22.04, 24.04
- ✅ Debian 11, 12

### Cas 2: Usage interne (une version Ubuntu connue)

```bash
# Compiler sur la version utilisée en production
# → Optimisé pour cette version
```

**Exemple (production en 22.04):**
- Compiler sur Ubuntu 22.04
- Utiliser uniquement sur 22.04+

### Cas 3: Support multi-versions

```bash
# Créer 3 paquets
# → Un par version LTS
```

**Structure:**
```
releases/
├── ubuntu20.04/
│   ├── wkhtmltopdf-webengine_0.13.0-ubuntu20.04_amd64.deb
│   └── wkhtmltopdf-webkit_0.13.0-ubuntu20.04_amd64.deb
├── ubuntu22.04/
│   ├── wkhtmltopdf-webengine_0.13.0-ubuntu22.04_amd64.deb
│   └── wkhtmltopdf-webkit_0.13.0-ubuntu22.04_amd64.deb
└── ubuntu24.04/
    ├── wkhtmltopdf-webengine_0.13.0-ubuntu24.04_amd64.deb
    └── wkhtmltopdf-webkit_0.13.0-ubuntu24.04_amd64.deb
```

## 🔧 Build pour multiple versions avec Docker

### Script de build multi-versions

```bash
#!/bin/bash
# build-all-ubuntu-versions.sh

for VERSION in 20.04 22.04 24.04; do
    echo "=== Building for Ubuntu $VERSION ==="

    docker run --rm \
        -v $(pwd):/workspace \
        -w /workspace \
        ubuntu:$VERSION \
        bash -c "
            apt-get update
            apt-get install -y build-essential git pkg-config \
                qt5-qmake qtbase5-dev qtbase5-dev-tools \
                libqt5svg5-dev libqt5xmlpatterns5-dev libqt5network5 \
                libssl-dev libfontconfig1-dev libfreetype6-dev \
                libx11-dev libxext-dev libxrender-dev \
                qtwebengine5-dev libqt5webenginewidgets5 \
                libqt5webenginecore5 libqt5printsupport5 \
                libqt5webkit5-dev lsb-release

            # Build both variants
            ./build-deb-variants.sh
        "
done
```

## 🎯 Choix rapide

### Pour vous (utilisateur)

**Vous avez Ubuntu 22.04, paquet compilé sur 24.04:**
- ❌ **NE FONCTIONNERA PAS**
- ✅ **Recompilez sur 22.04** avec `./build-deb-variants.sh`

**Vous avez Ubuntu 24.04, paquet compilé sur 22.04:**
- ✅ **FONCTIONNERA** sans problème

### Pour distribution

**Pour maximiser compatibilité:**
```bash
# Sur Ubuntu 20.04 LTS
./build-deb-variants.sh
```

**Pour optimiser performance:**
```bash
# Créer 3 versions
# 20.04, 22.04, 24.04
```

## 📊 Tableau récapitulatif

| Besoin | Version de build | Compatibilité | Recommandation |
|--------|------------------|---------------|----------------|
| **Max compatibilité** | Ubuntu 20.04 | 20.04 → 24.04 | ⭐ Recommandé pour distribution publique |
| **Balance** | Ubuntu 22.04 | 22.04 → 24.04 | ⭐ Bon choix général |
| **Dernières features** | Ubuntu 24.04 | 24.04 uniquement | ⚠️ Usage spécifique |
| **Production (22.04)** | Ubuntu 22.04 | 22.04+ | ⭐ Optimisé pour votre cas |

## ✅ Résumé

### Question: "Ubuntu 24.04 → 22.04 ?"
**Réponse: ❌ NON, ne fonctionnera pas**

### Question: "Ubuntu 22.04 → 24.04 ?"
**Réponse: ✅ OUI, fonctionnera**

### Règle d'or
> **Toujours compiler sur la version la plus ancienne que vous voulez supporter**

## 🚀 Actions recommandées

### Pour votre VM Ubuntu 22.04

```bash
# 1. Compiler les deux variantes sur votre VM 22.04
cd /chemin/vers/wkhtmltopdf
./build-deb-variants.sh

# Choisir option 3 (les deux)

# 2. Vous obtiendrez:
# wkhtmltopdf-webengine_0.13.0-ubuntu22.04_amd64.deb (~10-20 MB)
# wkhtmltopdf-webkit_0.13.0-ubuntu22.04_amd64.deb (~2-5 MB)

# 3. Ces paquets fonctionneront sur:
# ✅ Ubuntu 22.04
# ✅ Ubuntu 24.04
# ❌ Ubuntu 20.04 (possibles problèmes)
```

### Pour distribution large

```bash
# Utiliser Docker pour build sur 20.04
docker run -it --rm -v $(pwd):/workspace ubuntu:20.04
# ... installer dépendances ...
./build-deb-variants.sh
```

---

**Date:** 9 novembre 2024
**Version:** 0.13.0
**Compatibilité testée:** Ubuntu 20.04, 22.04, 24.04
