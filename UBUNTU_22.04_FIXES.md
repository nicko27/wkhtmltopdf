# Ubuntu 22.04 - Correctifs libwkhtmltox

## 🔴 Problème principal

Sur Ubuntu 22.04, wkhtmltopdf peut échouer avec l'erreur:
```
error while loading shared libraries: libwkhtmltox.so.0: cannot open shared object file: No such file or directory
```

## 🔍 Causes identifiées

1. **Cache ldconfig non configuré**
   - `/usr/local/lib` n'est pas dans le cache de ldconfig
   - libwkhtmltox.so.0 n'est pas trouvée au runtime

2. **Conflits de versions**
   - Packages compilés pour Ubuntu 24.04 installés sur 22.04
   - Incompatibilité entre Qt5 (22.04) et Qt6 (24.04)

3. **Dépendances Qt5 WebEngine manquantes**
   - libqt5webenginecore5
   - libqt5webenginewidgets5
   - libqt5positioning5

## ✅ Solutions implémentées dans build-deb.sh

### 1. Inclusion de la bibliothèque partagée dans le .deb

Le script empaquette maintenant libwkhtmltox.so dans `/usr/local/lib`:

```
/usr/local/lib/
├── libwkhtmltox.so.0.13.0  (bibliothèque réelle)
├── libwkhtmltox.so.0       → libwkhtmltox.so.0.13.0
└── libwkhtmltox.so         → libwkhtmltox.so.0
```

**Ligne du script**: 194-204
```bash
if [ $HAS_SHARED_LIB -eq 1 ]; then
    cp "$LIB_PATH" "$DEB_DIR/usr/local/lib/libwkhtmltox.so.0.13.0"
    cd "$DEB_DIR/usr/local/lib"
    ln -sf libwkhtmltox.so.0.13.0 libwkhtmltox.so.0
    ln -sf libwkhtmltox.so.0 libwkhtmltox.so
fi
```

### 2. Configuration automatique de ldconfig (postinst)

Le script postinst du package .deb configure automatiquement ldconfig:

**Ligne du script**: 275-292
```bash
# Create ldconfig configuration file
echo "/usr/local/lib" > /etc/ld.so.conf.d/wkhtmltopdf.conf

# Update ldconfig cache
ldconfig

# Verify
if ldconfig -p | grep -q "libwkhtmltox"; then
    echo "✓ libwkhtmltox.so.0 successfully registered"
fi
```

### 3. Détection et suppression des packages incompatibles

**Ligne du script**: 86-105
```bash
check_conflicts() {
    CONFLICTING_PKGS=$(dpkg -l | grep "^ii  wkhtmltopdf" | grep -v "ubuntu${UBUNTU_VERSION}")
    # Propose de supprimer les packages pour autres versions Ubuntu
}
```

### 4. Dépendances Qt5 complètes

Dépendances explicites dans le control file:

**Ligne du script**: 224-228
```
Depends: libqt5core5a, libqt5gui5, libqt5network5, libqt5svg5,
         libqt5xmlpatterns5, libqt5webenginecore5,
         libqt5webenginewidgets5, libqt5printsupport5,
         libqt5positioning5, libssl3 | libssl1.1, ...
```

### 5. Vérification post-installation

Le postinst teste que wkhtmltopdf fonctionne:

**Ligne du script**: 299-304
```bash
wkhtmltopdf --version 2>&1 || {
    echo "⚠ Error running wkhtmltopdf"
    echo "Run diagnostics: ./diagnose-ubuntu2204.sh"
    exit 1
}
```

## 📋 Comparaison: Avant vs Après

### AVANT (problématique)
```
❌ libwkhtmltox.so.0 non empaquetée
❌ Pas de configuration ldconfig
❌ Conflits non détectés
❌ Dépendances incomplètes
❌ Pas de vérification post-install
```

### APRÈS (corrigé)
```
✅ libwkhtmltox.so.0 incluse dans le .deb
✅ ldconfig configuré automatiquement
✅ Détection des packages incompatibles
✅ Toutes les dépendances Qt5 WebEngine
✅ Test automatique après installation
```

## 🧪 Test des correctifs

### Test 1: Vérifier le contenu du package
```bash
./build-deb.sh
dpkg-deb -c wkhtmltopdf-qt5-webengine_0.13.0-22.04_*.deb | grep libwkhtmltox
```

**Attendu**:
```
./usr/local/lib/libwkhtmltox.so.0.13.0
./usr/local/lib/libwkhtmltox.so.0 -> libwkhtmltox.so.0.13.0
./usr/local/lib/libwkhtmltox.so -> libwkhtmltox.so.0
```

### Test 2: Installation et vérification
```bash
sudo apt install ./wkhtmltopdf-qt5-webengine_0.13.0-22.04_*.deb

# Vérifier ldconfig
ldconfig -p | grep libwkhtmltox
# Doit afficher: libwkhtmltox.so.0 => /usr/local/lib/libwkhtmltox.so.0

# Vérifier le fichier de config
cat /etc/ld.so.conf.d/wkhtmltopdf.conf
# Doit afficher: /usr/local/lib

# Tester l'exécution
wkhtmltopdf --version
# Doit afficher la version sans erreur
```

### Test 3: Dépendances du binaire
```bash
ldd /usr/local/bin/wkhtmltopdf | grep "not found"
# Ne doit rien afficher (toutes les dépendances sont satisfaites)
```

## 🔧 Outils de diagnostic disponibles

### diagnose-ubuntu2204.sh
Analyse complète du système et détecte les problèmes:
- Version Ubuntu
- Packages installés
- Dépendances Qt5
- Configuration ldconfig
- Test d'exécution

```bash
./diagnose-ubuntu2204.sh
```

### fix-ubuntu2204-qt5.sh
Assistant interactif de réparation:
1. Installer les dépendances
2. Désinstaller packages incompatibles
3. Recompiler pour Ubuntu 22.04
4. Créer le package .deb
5. Régénérer le cache ldconfig

```bash
./fix-ubuntu2204-qt5.sh
```

## 📊 Statistiques

### Fichiers modifiés
- `build-deb.sh` - 389 lignes (avec tous les correctifs)
- `TEST_BUILD.md` - Documentation complète
- `UBUNTU_22.04_FIXES.md` - Ce fichier

### Correctifs appliqués
- ✅ 5 correctifs majeurs
- ✅ 3 vérifications automatiques
- ✅ 2 outils de diagnostic

### Tests requis
- ⏳ Compilation sur Ubuntu 22.04 réel
- ⏳ Installation du .deb
- ⏳ Vérification ldconfig
- ⏳ Exécution wkhtmltopdf

## 🚀 Utilisation recommandée

Sur Ubuntu 22.04, la procédure recommandée est:

```bash
# 1. Cloner le repo
git clone <repo>
cd wkhtmltopdf
git checkout claude/cleanup-makefiles-01K5LT6yHBco1ZgSLiz3ytS6

# 2. Vérifier la configuration (optionnel)
./check-build-config.sh

# 3. Build avec tous les correctifs
./build-deb.sh
# Répondre 'y' pour installer les dépendances
# Le script détecte Ubuntu 22.04 et applique tous les correctifs

# 4. Installer
sudo apt install ./wkhtmltopdf-qt5-webengine_0.13.0-22.04_*.deb

# 5. Vérifier
wkhtmltopdf --version
ldconfig -p | grep libwkhtmltox

# 6. Tester
echo "<h1>Test Ubuntu 22.04</h1>" | wkhtmltopdf - test.pdf
```

## ❓ FAQ

### Q: Pourquoi qt5-default n'est plus utilisé?
**R**: `qt5-default` est deprecated dans Ubuntu 22.04. On utilise maintenant `qtbase5-dev` + `qt5-qmake`.

### Q: WebKit vs WebEngine sur 22.04?
**R**: WebEngine uniquement. WebKit est abandonné (moins bon support CSS3/HTML5).

### Q: Compatibilité avec les anciens packages?
**R**: Les packages sont marqués comme `Conflicts: wkhtmltopdf-webkit, wkhtmltopdf` pour éviter les conflits.

### Q: Que faire si l'erreur persiste?
**R**:
1. Désinstaller: `sudo dpkg -r wkhtmltopdf-qt5-webengine`
2. Nettoyer ldconfig: `sudo rm /etc/ld.so.conf.d/wkhtmltopdf.conf && sudo ldconfig`
3. Recompiler: `./build-deb.sh`
4. Réinstaller: `sudo apt install ./wkhtmltopdf-qt5-webengine_0.13.0-22.04_*.deb`

## 📚 Références

- Issue: libwkhtmltox.so.0 not found on Ubuntu 22.04
- Solution: Package shared library + configure ldconfig
- Scripts: build-deb.sh, diagnose-ubuntu2204.sh, fix-ubuntu2204-qt5.sh
- Docs: TEST_BUILD.md
