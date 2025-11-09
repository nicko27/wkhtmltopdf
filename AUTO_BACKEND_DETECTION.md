# Détection Automatique du Backend de Rendu

## 🎯 Fonctionnalité

wkhtmltopdf détecte désormais **automatiquement** le meilleur backend de rendu disponible sur votre système et l'utilise par défaut.

## ✨ Avantages

### Avant (comportement ancien)
- Backend déterminé à la compilation
- Utilisateur devait spécifier `--render-backend webengine` manuellement
- Pas de fallback automatique

### Maintenant (nouveau comportement)
- ✅ **Détection automatique au démarrage**
- ✅ **WebEngine (Chromium) utilisé en priorité** si disponible
- ✅ **Fallback automatique sur WebKit** si WebEngine n'est pas disponible
- ✅ **Affichage du backend utilisé** dans `--help`
- ✅ **Pas de configuration requise** - ça fonctionne directement

## 🔍 Comment ça fonctionne

### Ordre de priorité

1. **WebEngine (Qt WebEngine/Chromium)** - Préféré
   - Support CSS3 complet (flexbox, grid, animations)
   - Moteur moderne basé sur Chromium
   - Meilleur rendu des pages web modernes

2. **WebKit (Qt WebKit)** - Fallback
   - Support CSS limité (~2012)
   - Utilisé si WebEngine n'est pas disponible
   - Compatible avec les anciens systèmes

### Détection au runtime

```cpp
// Le code détecte automatiquement le meilleur backend
RenderBackend backend = RenderEngineFactory::defaultBackend();

// Ordre de priorité:
// 1. WebEngine si disponible ✅
// 2. WebKit sinon
```

## 📖 Utilisation

### Mode automatique (recommandé)

```bash
# Le meilleur backend est utilisé automatiquement
wkhtmltopdf input.html output.pdf
```

### Mode manuel (toujours possible)

```bash
# Forcer WebEngine
wkhtmltopdf --render-backend webengine input.html output.pdf

# Forcer WebKit
wkhtmltopdf --render-backend webkit input.html output.pdf
```

### Voir quel backend est utilisé

```bash
# Affiche les informations sur le backend
wkhtmltopdf --help | grep -A 3 "Rendering backend"

# Ou simplement
wkhtmltopdf --version
```

## 🔧 API pour les développeurs

### C++ API

```cpp
#include <renderengine.hh>

using namespace wkhtmltopdf;

// Obtenir le meilleur backend disponible
RenderBackend best = RenderEngineFactory::getBestAvailableBackend();

// Vérifier si un backend est disponible
if (RenderEngineFactory::isBackendAvailable(RenderBackend::WebEngine)) {
    std::cout << "WebEngine est disponible!" << std::endl;
}

// Lister tous les backends disponibles
QList<RenderBackend> backends = RenderEngineFactory::availableBackends();
for (RenderBackend backend : backends) {
    std::cout << "Disponible: "
              << RenderEngineFactory::backendName(backend).toStdString()
              << std::endl;
}

// Obtenir le backend par défaut (auto-détecté)
RenderBackend defaultBackend = RenderEngineFactory::defaultBackend();

// Forcer un backend spécifique (si disponible)
RenderEngineFactory::setDefaultBackend(RenderBackend::WebEngine);
```

### C API

```c
#include <wkhtmltox/renderengine.h>

// Vérifier disponibilité
if (wkhtmltopdf_is_backend_available(BACKEND_WEBENGINE)) {
    printf("WebEngine disponible\n");
}

// Obtenir le meilleur backend
int best = wkhtmltopdf_get_best_available_backend();

// Définir le backend par défaut
wkhtmltopdf_set_default_backend(BACKEND_WEBENGINE);
```

## 🛠️ Recompilation

Pour activer cette fonctionnalité, recompilez wkhtmltopdf :

```bash
# Sur Ubuntu
./rebuild.sh

# Ou manuellement
make clean
RENDER_BACKEND=both qmake INSTALLBASE=/usr/local
make -j$(nproc)
sudo make install
sudo ldconfig
```

## 📋 Modifications techniques

### Fichiers modifiés

1. **src/lib/renderengine.hh**
   - Ajout de `getBestAvailableBackend()`
   - Ajout de `availableBackends()`

2. **src/lib/renderengine.cc**
   - Détection automatique au runtime
   - Priorité à WebEngine sur WebKit
   - Initialisation lazy du backend par défaut

3. **src/pdf/pdfdocparts.cc**
   - Affichage du backend dans `--help`
   - Affichage des capacités CSS du backend

### Comportement de détection

```cpp
RenderBackend RenderEngineFactory::getBestAvailableBackend() {
    // Priorité 1: WebEngine (moderne)
    if (isBackendAvailable(RenderBackend::WebEngine)) {
        return RenderBackend::WebEngine;
    }
    // Priorité 2: WebKit (legacy)
    if (isBackendAvailable(RenderBackend::WebKit)) {
        return RenderBackend::WebKit;
    }
    // Fallback
    return RenderBackend::WebKit;
}
```

## ✅ Avantages pour l'utilisateur

1. **Expérience transparente**
   - Pas besoin de savoir quel backend est disponible
   - Le meilleur choix est fait automatiquement

2. **CSS moderne par défaut**
   - Si WebEngine est disponible, il est utilisé
   - Flexbox, Grid, animations fonctionnent directement

3. **Compatibilité**
   - Fallback automatique sur les anciens systèmes
   - Pas de rupture de compatibilité

4. **Simplicité**
   - Une seule commande : `wkhtmltopdf input.html output.pdf`
   - Pas de flags compliqués à retenir

## 🎓 Exemples

### Test automatique

```bash
# Créer un fichier HTML avec CSS moderne
cat > modern.html <<'EOF'
<!DOCTYPE html>
<html>
<head>
<style>
.container {
    display: grid;
    grid-template-columns: 1fr 1fr;
    gap: 20px;
}
.box {
    background: linear-gradient(45deg, #667eea, #764ba2);
    padding: 20px;
    color: white;
}
</style>
</head>
<body>
<div class="container">
    <div class="box">Grid Layout ✅</div>
    <div class="box">CSS Gradients ✅</div>
</div>
</body>
</html>
EOF

# Convertir (utilise automatiquement WebEngine si disponible)
wkhtmltopdf modern.html modern.pdf

# Vérifier le backend utilisé
wkhtmltopdf --help | head -20
```

## 🐛 Dépannage

### Le mauvais backend est utilisé

```bash
# Vérifier quel backend est compilé
wkhtmltopdf --help | grep -A 5 "Rendering backend"

# Forcer un backend spécifique
wkhtmltopdf --render-backend webengine input.html output.pdf
```

### Recompiler avec les deux backends

```bash
# S'assurer que les deux backends sont compilés
RENDER_BACKEND=both qmake INSTALLBASE=/usr/local
make clean && make -j$(nproc)
sudo make install
```

## 📊 Tableau comparatif

| Aspect | Ancien comportement | Nouveau comportement |
|--------|-------------------|---------------------|
| **Détection** | Compilation uniquement | ✅ Runtime automatique |
| **Priorité** | Aléatoire | ✅ WebEngine > WebKit |
| **Fallback** | Aucun | ✅ Automatique |
| **Visibilité** | Cachée | ✅ Affiché dans --help |
| **Configuration** | Requise | ✅ Aucune |

## 🎉 Résumé

Cette fonctionnalité rend wkhtmltopdf **plus intelligent** et **plus facile à utiliser** :

- 🚀 **Automatique** - Détection au démarrage
- 🎯 **Intelligent** - Choisit le meilleur backend
- 🔄 **Robuste** - Fallback automatique
- 📖 **Transparent** - Affiche le backend utilisé
- 🛠️ **Flexible** - Override possible si nécessaire

**Vous n'avez rien à faire, ça fonctionne tout seul !** ✨
