# 🔧 Fix pour Ubuntu 22.04 - Erreur libwkhtmltox.so.0

## 🚨 Problème

Vous essayez d'installer wkhtmltopdf Qt5 sur Ubuntu 22.04 et vous obtenez une erreur :

```
error while loading shared libraries: libwkhtmltox.so.0: cannot open shared object file
```

**ou**

```
wkhtmltopdf: error while loading shared libraries: libwkhtmltox.so.0:
  wrong ELF class: ELFCLASS64
```

**ou**

Des erreurs de dépendances Qt5 non satisfaites.

## 🔍 Cause du Problème

Vous avez probablement installé un package `.deb` qui a été compilé pour **Ubuntu 24.04** et vous essayez de l'utiliser sur **Ubuntu 22.04**.

### Différences entre Ubuntu 22.04 et 24.04

| Bibliothèque | Ubuntu 22.04 (Jammy) | Ubuntu 24.04 (Noble) |
|--------------|----------------------|----------------------|
| Qt 5 | 5.15.3 | 5.15.13 |
| libssl | libssl3 (3.0.2) | libssl3 (3.0.13) |
| glibc | 2.35 | 2.39 |
| ABI | Incompatible → | ← Incompatible |

**Les packages binaires ne sont PAS compatibles entre ces versions.**

## ✅ Solutions

### Solution 1️⃣ : Script Automatique (RECOMMANDÉ)

```bash
cd /home/user/wkhtmltopdf

# Lancer le script de diagnostic
chmod +x diagnose-ubuntu2204.sh
./diagnose-ubuntu2204.sh

# Lancer le script de réparation
chmod +x fix-ubuntu2204-qt5.sh
./fix-ubuntu2204-qt5.sh

# Choisir l'option 5 (Installation complète)
```

Le script va :
1. ✅ Désinstaller les packages incompatibles
2. ✅ Installer les bonnes dépendances Qt5 pour Ubuntu 22.04
3. ✅ Recompiler wkhtmltopdf pour votre version
4. ✅ Créer un package .deb compatible Ubuntu 22.04
5. ✅ Installer et configurer correctement

### Solution 2️⃣ : Compilation Manuelle

#### Étape 1 : Désinstaller les packages incompatibles

```bash
sudo dpkg -r wkhtmltopdf wkhtmltopdf-webkit wkhtmltopdf-webengine
sudo dpkg -r wkhtmltopdf-qt5-webkit wkhtmltopdf-qt5-webengine
```

#### Étape 2 : Installer les dépendances pour Ubuntu 22.04

**Pour Qt5 WebKit (petit, rapide) :**

```bash
sudo apt-get update
sudo apt-get install -y \
    build-essential cmake qt5-qmake qtbase5-dev \
    libqt5core5a libqt5gui5 libqt5network5 libqt5svg5 \
    libqt5xmlpatterns5 libqt5webkit5 libqt5webkit5-dev \
    libssl3 libssl-dev libfontconfig1 libfreetype6 \
    libx11-6 libxrender1 libxext6
```

**Pour Qt5 WebEngine (CSS moderne) :**

```bash
sudo apt-get update
sudo apt-get install -y \
    build-essential cmake qt5-qmake qtbase5-dev \
    libqt5core5a libqt5gui5 libqt5network5 libqt5svg5 \
    libqt5xmlpatterns5 qtwebengine5-dev \
    libqt5webenginecore5 libqt5webenginewidgets5 \
    libqt5printsupport5 libqt5positioning5 \
    libssl3 libssl-dev libfontconfig1 libfreetype6 \
    libx11-6 libxrender1 libxext6 libnss3 \
    libxcomposite1 libxcursor1 libxdamage1 libxi6 libxtst6
```

#### Étape 3 : Compiler pour Ubuntu 22.04

```bash
cd /home/user/wkhtmltopdf

# Nettoyer les anciens builds
make distclean 2>/dev/null || true
rm -rf bin/ lib/ debian-build-*/

# Configurer pour WebKit OU WebEngine
RENDER_BACKEND=webkit qmake      # Pour WebKit
# OU
RENDER_BACKEND=webengine qmake   # Pour WebEngine

# Compiler
make clean
make -j$(nproc)
```

#### Étape 4 : Créer le package Debian pour Ubuntu 22.04

```bash
# Le script détecte automatiquement Ubuntu 22.04
./build-deb-variants.sh

# Les packages seront dans:
# - debian-build-qt5-webkit/*.deb
# - debian-build-qt5-webengine/*.deb
```

#### Étape 5 : Installer

```bash
# Pour WebKit
sudo dpkg -i debian-build-qt5-webkit/*.deb
sudo apt-get install -f -y

# OU pour WebEngine
sudo dpkg -i debian-build-qt5-webengine/*.deb
sudo apt-get install -f -y

# Régénérer le cache des bibliothèques
sudo ldconfig
```

#### Étape 6 : Vérifier

```bash
wkhtmltopdf --version

# Devrait afficher:
# wkhtmltopdf 0.13.0-ubuntu22.04 (with patched qt)
#                     ^^^^^^^^^^^
#                     Vérifiez que c'est bien 22.04 !
```

### Solution 3️⃣ : Utiliser Qt6 (si disponible)

Si Qt6 fonctionne sur votre système, utilisez-le à la place :

```bash
sudo apt-get install -y \
    qt6-base-dev qt6-webengine-dev \
    libqt6core6 libqt6gui6 libqt6webenginecore6

RENDER_BACKEND=webengine QT_SELECT=qt6 qmake
make clean && make -j$(nproc)
sudo make install
```

## 🐛 Diagnostic

Avant de commencer, diagnostiquez le problème exact :

```bash
./diagnose-ubuntu2204.sh
```

Ce script va vérifier :
- ✅ Version d'Ubuntu
- ✅ Présence de libwkhtmltox.so
- ✅ Dépendances Qt5 installées
- ✅ Version des packages installés (22.04 vs 24.04)
- ✅ Configuration ldconfig
- ✅ Test d'exécution

### Interpréter les résultats

**🔴 Problème typique :**

```
7. Vérification des packages wkhtmltopdf Debian
   ✓ wkhtmltopdf-webkit (0.13.0-ubuntu24.04)
     ⚠⚠⚠ PROBLÈME: Package pour Ubuntu 24.04 sur système 22.04!
```

**Solution :** Recompiler pour Ubuntu 22.04

**🔴 Autre problème :**

```
4. Vérification des dépendances Qt5
   ✗ libqt5webkit5 - MANQUANT
   ✗ libqt5webenginecore5 - MANQUANT
```

**Solution :** Installer les dépendances manquantes

## 📦 Versions des Packages

### Packages Corrects pour Ubuntu 22.04

```bash
# Version du package
wkhtmltopdf-webkit: 0.13.0-ubuntu22.04
wkhtmltopdf-webengine: 0.13.0-ubuntu22.04

# Dépendances Qt5 (Ubuntu 22.04)
libqt5core5a: 5.15.3
libqt5gui5: 5.15.3
libqt5webkit5: 5.212.0~alpha4
libqt5webenginecore5: 5.15.3
```

### Packages INCOMPATIBLES (à éviter)

```bash
# ❌ NE PAS utiliser sur Ubuntu 22.04
wkhtmltopdf-webkit: 0.13.0-ubuntu24.04
wkhtmltopdf-webengine: 0.13.0-ubuntu24.04
```

## 🎯 Recommandations par Cas d'Usage

### Pour un Serveur Ubuntu 22.04 (Production)

**Recommandation : Qt5 WebKit**

✅ **Avantages :**
- Petit package (~40 MB)
- Moins de dépendances
- Plus rapide
- Plus stable sur 22.04

❌ **Inconvénients :**
- CSS limité (pas de Grid, Flexbox)

```bash
./fix-ubuntu2204-qt5.sh
# Choisir option 3 (WebKit)
```

### Pour du Développement / CSS Moderne

**Recommandation : Qt5 WebEngine**

✅ **Avantages :**
- CSS moderne complet
- Flexbox, Grid, etc.

❌ **Inconvénients :**
- Package plus gros (~200 MB)
- Plus de dépendances

```bash
./fix-ubuntu2204-qt5.sh
# Choisir option 4 (WebEngine)
```

### Pour Maximum Compatibilité

**Recommandation : Qt6 WebEngine**

Si Qt6 est disponible sur votre système :

✅ **Avantages :**
- Version la plus récente
- Meilleur support CSS
- Moins de problèmes de dépendances

```bash
sudo apt-get install qt6-base-dev qt6-webengine-dev
RENDER_BACKEND=webengine QT_SELECT=qt6 qmake
make && sudo make install
```

## ❓ FAQ

### Q : Pourquoi Qt6 fonctionne mais pas Qt5 ?

**R :** Qt6 a probablement été installé depuis des sources plus récentes ou des PPA avec des packages binaires compatibles. Qt5 système d'Ubuntu 22.04 est figé à la version 5.15.3.

### Q : Puis-je forcer l'installation d'un package Ubuntu 24.04 ?

**R :** Non recommandé. Vous aurez des erreurs ABI et des crashes aléatoires. Recompilez à la place.

### Q : Combien de temps prend la compilation ?

**R :**
- WebKit : 5-15 minutes (selon CPU)
- WebEngine : 15-30 minutes (plus de code)

### Q : Puis-je utiliser les deux (WebKit ET WebEngine) ?

**R :** Oui, mais ils ne peuvent pas être installés simultanément via dpkg. Utilisez :
- `RENDER_BACKEND=both` lors de la compilation
- Puis sélectionnez avec `--render-backend webkit|webengine`

### Q : L'erreur persiste après recompilation

**R :** Vérifiez :

```bash
# 1. Cache ldconfig
sudo ldconfig
ldconfig -p | grep libwkhtmltox

# 2. Fichier de configuration
cat /etc/ld.so.conf.d/wkhtmltopdf.conf

# 3. Permissions
ls -l /usr/local/lib/libwkhtmltox.*

# 4. Lien symbolique
ls -l /usr/local/bin/wkhtmltopdf
```

## 🔗 Ressources

- [Script de diagnostic](diagnose-ubuntu2204.sh)
- [Script de réparation](fix-ubuntu2204-qt5.sh)
- [Guide de build](build-deb-variants.sh)
- [Documentation dépendances](DEPENDENCIES.md)
- [README principal](README.md)

## 📞 Support

Si le problème persiste après avoir suivi ce guide :

1. Lancez le diagnostic complet :
   ```bash
   ./diagnose-ubuntu2204.sh > diagnostic.txt
   ```

2. Ouvrez une issue sur GitHub avec :
   - Le fichier `diagnostic.txt`
   - Les erreurs exactes
   - Votre configuration système

## ✅ Vérification Finale

Après installation, vérifiez que tout fonctionne :

```bash
# 1. Version correcte
wkhtmltopdf --version | grep "ubuntu22.04"

# 2. Test basique
echo "<h1>Test</h1>" > /tmp/test.html
wkhtmltopdf /tmp/test.html /tmp/test.pdf

# 3. Backend disponible
wkhtmltopdf --version | grep -i "webkit\|webengine"

# 4. Bibliothèque partagée
ldd $(which wkhtmltopdf) | grep libwkhtmltox
```

**Si tous les tests passent : ✅ Vous êtes prêt !**

---

**Document créé le :** 2025-01-17
**Dernière mise à jour :** 2025-01-17
**Version :** 1.0
**Testé sur :** Ubuntu 22.04 LTS (Jammy Jellyfish)
