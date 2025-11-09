# Changelog - Multi-Backend Support

## Version 0.12.7-dev (Multi-Backend)

**Date:** 2025-01-09

### 🎉 Nouvelles fonctionnalités majeures

#### Support Multi-Backend
- **Architecture de rendu multi-backend** permettant de choisir entre Qt WebKit (legacy) et Qt WebEngine (moderne)
- **Support CSS3 complet** via Qt WebEngine (Chromium):
  - ✅ CSS Flexbox (`display: flex`)
  - ✅ CSS Grid (`display: grid`)
  - ✅ CSS Transforms, Transitions, Animations
  - ✅ Gradients linéaires et radiaux
  - ✅ Border radius, box-shadow
  - ✅ Modern CSS selectors (`:has()`, `:is()`, etc.)
  - ✅ Media queries avancées
- **Support JavaScript moderne** (ES6+) avec WebEngine
- **Sélection du backend au runtime** via l'option `--render-backend`
- **Compatibilité backward** complète avec l'API existante

### 🏗️ Architecture

#### Nouveaux fichiers
- `src/lib/renderengine.hh` - Interface abstraite commune pour les backends
- `src/lib/renderengine.cc` - Factory et implémentation de base
- `src/lib/renderengine_webkit.hh` - Interface backend WebKit
- `src/lib/renderengine_webkit.cc` - Implémentation WebKit (wrapper)
- `src/lib/renderengine_webengine.hh` - Interface backend WebEngine
- `src/lib/renderengine_webengine.cc` - Implémentation WebEngine (Chromium)

#### Build system
- Modification de `common.pri` pour supporter la sélection de backend via `RENDER_BACKEND`
- Modification de `src/lib/lib.pri` pour inclure les nouveaux modules
- Support pour trois modes: `webkit`, `webengine`, ou `both`

### 📦 Scripts d'installation

#### Nouveaux scripts
- `install.sh` - Script d'installation universel (auto-détecte l'OS)
- `install-ubuntu.sh` - Script optimisé pour Ubuntu/Debian
- `install-macos.sh` - Script optimisé pour macOS avec Homebrew
- `test-install.sh` - Suite de tests pour valider l'installation

#### Fonctionnalités des scripts
- Installation automatique de toutes les dépendances
- Détection de l'OS et de la version
- Configuration automatique de Qt
- Compilation et installation en une seule commande
- Tests de validation post-installation

### 📚 Documentation

#### Nouveaux documents
- `MULTI_BACKEND.md` - Documentation complète du système multi-backend
- `INSTALL.md` - Guide d'installation détaillé
- `QUICKSTART.md` - Guide de démarrage rapide
- `CHANGELOG_MULTIBACKEND.md` - Ce fichier
- README.md mis à jour avec les nouvelles fonctionnalités

### 🎨 Exemples

#### Nouveaux exemples
- `examples/backend_selector.c` - Exemple C de sélection de backend
- `examples/modern_css_demo.html` - Démo complète des fonctionnalités CSS modernes
- `examples/Makefile` mis à jour avec cible `demo`

#### Fonctionnalités de la démo
- Exemples de Flexbox avec alignement et distribution
- Exemples de Grid avec colonnes auto-responsives
- Grid avancé avec spanning de lignes/colonnes
- Transforms CSS (rotate, scale, skew)
- Gradients et effets modernes
- Layout complexe avec grid-template-areas

### 🔧 Modifications techniques

#### API C
- Nouvelles fonctions (à implémenter):
  - `wkhtmltopdf_set_default_backend()`
  - `wkhtmltopdf_get_default_backend()`
  - `wkhtmltopdf_is_backend_available()`

#### API C++
- Nouvelle classe `RenderEngine` avec pattern Factory
- Classes `RenderPage` et `RenderFrame` pour abstraction
- Enum `RenderBackend` pour sélection du moteur
- Classe `RenderEngineFactory` pour gestion des backends

#### Build system
- Variable d'environnement `RENDER_BACKEND` pour configuration
- Defines conditionnels: `WKHTMLTOPDF_USE_WEBKIT`, `WKHTMLTOPDF_USE_WEBENGINE`
- Support de compilation avec un seul backend ou les deux

### 🐛 Compatibilité

#### Rétrocompatibilité
- ✅ API C existante 100% compatible
- ✅ API C++ existante 100% compatible
- ✅ Options CLI existantes fonctionnent sans changement
- ✅ Comportement par défaut inchangé (WebKit si disponible)

#### Plateformes supportées
- ✅ Ubuntu 18.04+ / Debian 10+
- ✅ macOS 10.13+ (High Sierra et supérieur)
- ✅ Windows (à tester, support théorique via Qt WebEngine)

#### Versions Qt supportées
- Qt 4.8.x - WebKit uniquement
- Qt 5.4+ - WebKit et/ou WebEngine
- Qt 5.15+ - Recommandé pour WebEngine

### ⚙️ Configuration

#### Variables d'environnement
- `RENDER_BACKEND` - Sélection du backend au build (`webkit`, `webengine`, `both`)
- `INSTALL_PREFIX` - Préfixe d'installation (défaut: `/usr/local`)
- `QTWEBENGINE_CHROMIUM_FLAGS` - Flags Chromium pour WebEngine

#### Options CLI
- `--render-backend <backend>` - Sélection du backend au runtime
  - Valeurs: `webkit`, `webengine`, `auto`

### 📊 Métriques

#### Taille des binaires
- **WebKit seul**: ~20-30 MB
- **WebEngine seul**: ~100-200 MB
- **Les deux**: ~120-230 MB

#### Performance
- **WebKit**: Démarrage rapide, utilisation mémoire faible
- **WebEngine**: Démarrage plus lent, utilisation mémoire plus élevée, rendu CSS moderne

### 🔒 Sécurité

#### Considérations
- WebEngine utilise Chromium récent avec patches de sécurité
- Sandboxing Chromium disponible via WebEngine
- Même avertissement pour HTML non fiable (voir documentation)
- Recommandé: Utiliser WebEngine pour HTML non fiable (plus récent)

### 🚀 Migration

#### Pour les utilisateurs existants
1. Aucun changement nécessaire pour continuer avec WebKit
2. Recompiler avec `RENDER_BACKEND=webengine` pour CSS moderne
3. Ou compiler avec `RENDER_BACKEND=both` pour flexibilité maximale

#### Pour les développeurs
1. L'API existante continue de fonctionner
2. Utiliser `RenderEngineFactory` pour sélection programmatique
3. Consulter `examples/backend_selector.c` pour exemples

### 📝 Notes

#### Limitations connues
- WebKit: Pas de support flex/grid
- WebEngine: Binaire plus volumineux
- WebEngine sur macOS: Nécessite OpenGL
- WebKit sur macOS: Déprécié, utiliser WebEngine

#### Améliorations futures possibles
- [ ] API C pour sélection de backend
- [ ] Support de plugins de rendu tiers
- [ ] Cache de rendu pour performances
- [ ] Support WebAssembly via WebEngine
- [ ] Intégration de Puppeteer comme backend alternatif

### 🙏 Remerciements

- Équipe Qt pour Qt WebKit et Qt WebEngine
- Projet Chromium pour le moteur Blink
- Mainteneurs originaux de wkhtmltopdf
- Contributeurs de la communauté

### 📄 Licence

LGPL v3 - Identique à la version originale

Les composants Qt WebEngine incluent Chromium (BSD et autres licences permissives)

---

## Versions précédentes

Voir [CHANGELOG.md](CHANGELOG.md) pour l'historique complet du projet original.
