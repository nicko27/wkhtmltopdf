# 🔧 Fix: ld cannot find -lwkhtmltox

## 🚨 Symptômes

Lors de la compilation sur Ubuntu 22.04, vous obtenez une erreur :

```
/usr/bin/ld: cannot find -lwkhtmltox
collect2: error: ld returned 1 exit status
```

**ou similaire:**

```
ld: cannot find -lwkhtmltox: No such file or directory
```

## 🔍 Explication du Problème

### Qu'est-ce que -lwkhtmltox ?

Le flag `-lwkhtmltox` demande au linker de lier votre programme contre `libwkhtmltox.so` (ou `.a` pour statique).

### Pourquoi cette erreur se produit ?

**Ordre de compilation :**

1. ✅ `src/lib/` devrait compiler **EN PREMIER** et créer `bin/libwkhtmltox.so`
2. ❌ `src/pdf/` et `src/image/` essaient de lier contre cette bibliothèque

**Le problème :** Si la compilation de `src/lib/` échoue (même silencieusement), la bibliothèque n'est pas créée, et les étapes suivantes échouent avec "cannot find -lwkhtmltox".

### Causes Courantes

| Cause | Symptôme | Solution |
|-------|----------|----------|
| **Dépendances Qt manquantes** | Erreurs pendant `make` dans src/lib | Installer les packages Qt5/Qt6 |
| **Version Qt incompatible** | Erreurs de compilation C++ | Utiliser Qt 5.4+ pour WebEngine |
| **WebKit manquant** | `QtWebKit/QWebView: No such file` | Installer libqt5webkit5-dev |
| **Répertoire bin/ non créé** | La lib compile mais n'est pas trouvée | Créer `mkdir -p bin lib` avant |
| **Build partiellement corrompu** | Erreurs aléatoires | Faire `make distclean` |

## ✅ Solution Rapide (Script Automatique)

```bash
cd /path/to/wkhtmltopdf

# Rendre le script exécutable
chmod +x fix-linkage-error.sh

# Lancer le fix
./fix-linkage-error.sh

# Le script va:
# 1. Vérifier les dépendances Qt
# 2. Nettoyer complètement le build
# 3. Compiler SEULEMENT la bibliothèque d'abord
# 4. Puis compiler les exécutables
```

Le script est **interactif** et vous demandera :
- Quel backend utiliser (webkit ou webengine)
- S'il faut installer les dépendances manquantes

## 🛠️ Solution Manuelle (Étape par Étape)

### Étape 1 : Vérifier les Dépendances

**Pour Qt5 WebKit :**

```bash
sudo apt-get update
sudo apt-get install -y \
    build-essential \
    qt5-qmake \
    qtbase5-dev \
    libqt5webkit5 \
    libqt5webkit5-dev \
    libqt5core5a \
    libqt5gui5 \
    libqt5network5 \
    libqt5svg5 \
    libqt5xmlpatterns5 \
    libssl-dev \
    libfontconfig1-dev \
    libfreetype6-dev \
    libx11-dev \
    libxrender-dev \
    libxext-dev
```

**Pour Qt5 WebEngine :**

```bash
sudo apt-get update
sudo apt-get install -y \
    build-essential \
    qt5-qmake \
    qtbase5-dev \
    qtwebengine5-dev \
    libqt5webenginecore5 \
    libqt5webenginewidgets5 \
    libqt5core5a \
    libqt5gui5 \
    libqt5network5 \
    libqt5svg5 \
    libqt5xmlpatterns5 \
    libqt5printsupport5 \
    libqt5positioning5 \
    libssl-dev \
    libfontconfig1-dev \
    libfreetype6-dev \
    libx11-dev \
    libxrender-dev \
    libxext-dev \
    libnss3 \
    libxcomposite1 \
    libxcursor1 \
    libxdamage1 \
    libxi6 \
    libxtst6
```

### Étape 2 : Nettoyage Complet

```bash
cd /path/to/wkhtmltopdf

# Nettoyer tous les fichiers de build
make distclean 2>/dev/null || true

# Supprimer tous les artefacts
rm -rf bin/ lib/ build/ .qmake.stash
rm -f Makefile */Makefile */*/Makefile
rm -rf moc_* ui_* qrc_* *.o */*.o */*/*.o
rm -rf debian-build-*/
```

### Étape 3 : Créer les Répertoires de Sortie

```bash
# Créer les répertoires à l'avance
mkdir -p bin lib
```

### Étape 4 : Configuration avec qmake

```bash
# Pour WebKit
RENDER_BACKEND=webkit qmake

# OU pour WebEngine
RENDER_BACKEND=webengine qmake
```

**Vérifier qu'il n'y a pas d'erreurs !** Si qmake affiche des erreurs, résolvez-les avant de continuer.

### Étape 5 : Compiler UNIQUEMENT la Bibliothèque

**C'est l'étape critique :**

```bash
# Aller dans le répertoire de la bibliothèque
cd src/lib

# Compiler SEULEMENT la bibliothèque
make -j$(nproc)

# Vérifier le résultat
ls -lh ../../bin/libwkhtmltox.*
```

**Si cette étape échoue :**

1. Lisez attentivement les erreurs
2. Installez les dépendances manquantes
3. Réessayez

**Erreurs communes :**

```
QtWebKit/QWebView: No such file or directory
→ Solution: sudo apt-get install libqt5webkit5-dev

QtWebEngineWidgets/QWebEngineView: No such file or directory
→ Solution: sudo apt-get install qtwebengine5-dev

openssl/ssl.h: No such file or directory
→ Solution: sudo apt-get install libssl-dev
```

### Étape 6 : Vérifier que la Bibliothèque Existe

```bash
cd ../..  # Retour à la racine

# Vérifier
if [ -f "bin/libwkhtmltox.so" ] || [ -f "bin/libwkhtmltox.so.0" ]; then
    echo "✅ Bibliothèque créée avec succès!"
    ls -lh bin/libwkhtmltox.*
else
    echo "❌ La bibliothèque n'a pas été créée"
    exit 1
fi
```

### Étape 7 : Compiler les Exécutables

Maintenant que la bibliothèque existe, compilez les exécutables :

```bash
# Compiler wkhtmltopdf
cd src/pdf
make -j$(nproc)
cd ../..

# Compiler wkhtmltoimage
cd src/image
make -j$(nproc)
cd ../..
```

**Ces étapes ne devraient PLUS échouer avec "cannot find -lwkhtmltox"**

### Étape 8 : Vérifier les Binaires

```bash
# Lister les fichiers créés
ls -lh bin/

# Devrait afficher:
# - libwkhtmltox.so (ou .so.0.13.0)
# - wkhtmltopdf
# - wkhtmltoimage

# Tester l'exécutable
LD_LIBRARY_PATH=./bin ./bin/wkhtmltopdf --version
```

### Étape 9 : Installation

```bash
# Option A: Installation système
sudo make install
sudo ldconfig

# Option B: Créer un package Debian
./build-deb-variants.sh
sudo dpkg -i debian-build-qt5-webkit/*.deb  # ou webengine
```

## 🐛 Dépannage Avancé

### Problème : qmake ne trouve pas Qt

```bash
# Vérifier qmake disponible
which qmake || which qmake-qt5 || which qmake6

# Si aucun n'est trouvé
sudo apt-get install qt5-qmake

# Ou spécifier le chemin complet
/usr/lib/qt5/bin/qmake
```

### Problème : La compilation de src/lib échoue avec des erreurs C++

```bash
# Afficher la version de Qt
qmake -query QT_VERSION

# Si < 5.4 pour WebEngine
echo "Qt WebEngine nécessite Qt 5.4+"
echo "Utilisez webkit ou mettez à jour Qt"
```

### Problème : Bibliothèque créée mais non trouvée par le linker

```bash
# Vérifier que la bibliothèque existe
ls -l bin/libwkhtmltox*

# Vérifier le chemin du linker dans les Makefiles
grep "LIBS.*wkhtmltox" src/pdf/Makefile

# Devrait contenir: -L../../bin -lwkhtmltox

# Vérifier le rpath
readelf -d bin/wkhtmltopdf | grep RPATH
```

### Problème : Version Ubuntu 24.04 vs 22.04

Si vous compilez sur Ubuntu 24.04 pour l'utiliser sur 22.04, vous aurez des problèmes.

**Solution :** Compilez sur la même version d'Ubuntu que celle où vous allez l'installer.

Voir aussi : [UBUNTU_2204_FIX.md](UBUNTU_2204_FIX.md)

## 📋 Checklist de Vérification

Avant de rapporter un problème, vérifiez :

- [ ] `qmake --version` fonctionne
- [ ] Les dépendances Qt5/Qt6 sont installées
- [ ] `make distclean` a été exécuté
- [ ] Les répertoires `bin/` et `lib/` existent
- [ ] La compilation de `src/lib/` réussit **SANS ERREURS**
- [ ] `bin/libwkhtmltox.so` existe après la compilation de src/lib
- [ ] La version d'Ubuntu est la même que celle de destination

## 🎯 Résumé

**Le problème** : Le linker cherche `libwkhtmltox.so` qui n'existe pas encore.

**La cause** : La compilation de `src/lib/` a échoué ou n'a pas été faite.

**La solution** :
1. Installer les dépendances Qt correctes
2. Nettoyer complètement le build
3. Compiler `src/lib/` **EN PREMIER**
4. Vérifier que `bin/libwkhtmltox.so` existe
5. Ensuite compiler `src/pdf/` et `src/image/`

## 🔗 Ressources

- [Script de fix automatique](fix-linkage-error.sh)
- [Fix Ubuntu 22.04](UBUNTU_2204_FIX.md)
- [Script de diagnostic](diagnose-ubuntu2204.sh)
- [Guide de build](build-deb-variants.sh)
- [README principal](README.md)

## 💬 Besoin d'Aide ?

Si le problème persiste :

1. Lancez le script de diagnostic :
   ```bash
   ./diagnose-ubuntu2204.sh > diagnostic.txt
   ```

2. Essayez la compilation étape par étape (Étape 5 ci-dessus)

3. Capturez les erreurs exactes :
   ```bash
   cd src/lib
   make -j$(nproc) 2>&1 | tee compile-errors.txt
   ```

4. Ouvrez une issue sur GitHub avec :
   - Le fichier `diagnostic.txt`
   - Le fichier `compile-errors.txt`
   - Votre version d'Ubuntu (`lsb_release -a`)
   - Votre version de Qt (`qmake -query QT_VERSION`)

---

**Document créé le :** 2025-01-17
**Dernière mise à jour :** 2025-01-17
**Version :** 1.0
**Testé sur :** Ubuntu 22.04 LTS, Ubuntu 24.04 LTS
