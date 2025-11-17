# 🧪 Tests des Sauts de Page CSS

Ce répertoire contient des tests comparatifs pour démontrer les différences de support des sauts de page CSS entre les backends WebKit et WebEngine.

## 📁 Fichiers

- **`test-page-breaks.html`** - Document HTML de test avec 10 scénarios de sauts de page
- **`test-page-breaks.sh`** - Script automatisé pour générer et comparer les PDFs
- **`test-results/`** - Répertoire de sortie pour les PDFs générés

## 🚀 Utilisation Rapide

```bash
# Lancer les tests automatiquement
./test-page-breaks.sh
```

Le script va :
1. ✅ Générer `page-breaks-webkit.pdf` avec le backend WebKit
2. ✅ Générer `page-breaks-webengine.pdf` avec le backend WebEngine
3. 📊 Comparer le nombre de pages
4. 💡 Afficher les points à vérifier manuellement
5. 🔍 Ouvrir les PDFs pour comparaison visuelle

## 🎯 Tests Inclus

### ✅ Tests qui RÉUSSISSENT avec WebEngine

| Test | Propriété CSS | Comportement Attendu |
|------|---------------|----------------------|
| **TEST 1** | `break-before: page` | Commence sur une nouvelle page |
| **TEST 2** | `break-after: page` | Force un saut après la section |
| **TEST 3** | `break-inside: avoid` | Empêche la coupure du bloc |
| **TEST 5** | `break-inside: avoid-page` | Évite les sauts de page seulement |
| **TEST 6** | `break-before: left` | Commence sur une page de gauche |
| **TEST 8** | Images + `break-inside: avoid` | Garde image et légende ensemble |
| **TEST 9** | `orphans: 3; widows: 3` | Contrôle les lignes orphelines |
| **TEST 10** | `break-before: column` | Saut de colonne |

### ❌ Tests qui ÉCHOUENT avec WebKit

Tous les tests ci-dessus utilisant les propriétés modernes (`break-*`) échoueront avec WebKit.

WebKit ne supporte que :
- ⚠️ `page-break-inside: avoid` (avec Qt patché v0.12.1+)
- ⚠️ `page-break-before: always` (support limité)
- ⚠️ `page-break-after: always` (support limité)

### 🚫 Limitations CONNUES (tous backends)

| Test | Problème | Raison |
|------|----------|--------|
| **TEST 4** | `display: flex` + `break-inside` | Chromium ne supporte pas page-break sur flex |
| **TEST 7** | Tableaux `<td>` + `break-inside` | Chrome ignore page-break dans les cellules |

## 📊 Résultats Attendus

### Nombre de Pages

- **WebKit** : ~8-10 pages (selon la disposition naturelle)
- **WebEngine** : ~12-15 pages (avec sauts forcés par CSS)

**Si WebEngine a plus de pages, c'est NORMAL et CORRECT** - cela prouve que les sauts de page CSS fonctionnent !

### Différences Visuelles Clés

| Section | WebKit | WebEngine |
|---------|--------|-----------|
| **TEST 1 (bloc bleu)** | Continue sur la même page | **Nouvelle page** ✓ |
| **TEST 2 (bloc violet)** | Contenu suivant sur même page | **Saut après** ✓ |
| **TEST 3 (bloc vert 500px)** | Ne devrait pas être coupé | Ne devrait pas être coupé |
| **Résumé final (noir)** | Peut être sur la même page | **Nouvelle page** ✓ |

## 🔧 Tests Manuels

### Option 1 : Script Automatisé (Recommandé)

```bash
./test-page-breaks.sh
```

### Option 2 : Commandes Manuelles

```bash
# Créer le répertoire de résultats
mkdir -p test-results

# Test WebKit
wkhtmltopdf --render-backend webkit \
            test-page-breaks.html \
            test-results/page-breaks-webkit.pdf

# Test WebEngine
wkhtmltopdf --render-backend webengine \
            test-page-breaks.html \
            test-results/page-breaks-webengine.pdf

# Comparer le nombre de pages
pdfinfo test-results/page-breaks-webkit.pdf | grep Pages
pdfinfo test-results/page-breaks-webengine.pdf | grep Pages
```

### Option 3 : Comparaison Pixel par Pixel

```bash
# Installer diffpdf (Ubuntu/Debian)
sudo apt-get install diffpdf

# Comparer visuellement
diffpdf test-results/page-breaks-webkit.pdf \
         test-results/page-breaks-webengine.pdf
```

## 📖 Interprétation des Résultats

### ✅ Test Réussi

**Critères de succès pour WebEngine :**

1. ✓ Le **TEST 1** (bloc bleu) commence sur une nouvelle page
2. ✓ Le **TEST 2** (bloc violet) est suivi d'un saut de page
3. ✓ Le **TEST 3** (bloc vert) n'est PAS coupé en deux
4. ✓ Le **résumé final** (fond noir) commence sur une nouvelle page
5. ✓ Le PDF a **plus de pages** que la version WebKit

**Critères pour WebKit :**

1. ⚠️ Le **TEST 1** et **TEST 2** ne créent PAS de sauts de page
2. ✓ Le **TEST 3** n'est pas coupé (si Qt patché v0.12.1+)
3. ⚠️ Le PDF a **moins de pages** (pas de sauts forcés)

### ❌ Test Échoué

Si vous voyez dans le PDF WebEngine :
- Le TEST 1 ne commence PAS sur une nouvelle page
- Le TEST 3 est coupé en deux
- Le même nombre de pages que WebKit

→ Il y a un problème avec le support CSS ou la génération PDF

## 🐛 Dépannage

### Problème : "wkhtmltopdf: command not found"

```bash
# Compiler et installer d'abord
cd /home/user/wkhtmltopdf
RENDER_BACKEND=both qmake
make -j$(nproc)
sudo make install
```

### Problème : "WebEngine backend not available"

```bash
# Vérifier les backends disponibles
wkhtmltopdf --version

# Si WebEngine n'apparaît pas, recompiler avec WebEngine
RENDER_BACKEND=webengine qmake
make -j$(nproc)
sudo make install
```

### Problème : Les sauts de page ne fonctionnent pas avec WebEngine

**Causes possibles :**

1. **Parent avec `overflow: hidden`** - Empêche les sauts de page
2. **Parent avec `display: flex`** - Limitation connue de Chromium
3. **Élément dans `<td>`** - Chrome ignore page-break dans les cellules
4. **Élément avec `position: absolute`** - Sorti du flux normal

**Solutions :**

```css
/* ❌ Ne fonctionne PAS */
.container {
    display: flex;
}
.item {
    break-inside: avoid; /* Ignoré ! */
}

/* ✅ Fonctionne */
.container {
    display: block; /* Changé de flex à block */
}
.item {
    break-inside: avoid; /* Respecté ! */
}
```

## 📚 Propriétés CSS Supportées

### WebEngine (Chromium) - Support Complet ✅

```css
/* Propriétés modernes (préférer) */
.element {
    break-before: auto | avoid | always | left | right | page | column;
    break-after: auto | avoid | always | left | right | page | column;
    break-inside: auto | avoid | avoid-page | avoid-column;

    /* Contrôle des lignes orphelines */
    orphans: 3;
    widows: 3;
}
```

### WebKit Patché - Support Limité ⚠️

```css
/* Anciennes propriétés (support partiel) */
.element {
    page-break-inside: avoid;        /* ✓ v0.12.1+ pour blocs */
    page-break-before: always;       /* ⚠️ support limité */
    page-break-after: always;        /* ⚠️ support limité */

    /* Lignes orphelines */
    orphans: 3;                      /* ✓ v0.12.1+ */
    widows: 3;                       /* ✓ v0.12.1+ */
}
```

### WebKit Standard (non patché) - Presque Rien ❌

```css
/* Pratiquement aucune propriété de saut de page ne fonctionne */
.element {
    /* Toutes ignorées */
    page-break-inside: avoid;   /* ❌ */
    break-inside: avoid;        /* ❌ */
}
```

## 🎓 Exemples Pratiques

### Exemple 1 : Chapitres de Livre

```html
<style>
@media print {
    .chapter {
        break-before: page;      /* Nouveau chapitre = nouvelle page */
        break-after: avoid;      /* Éviter saut juste après le titre */
    }

    .chapter h1 {
        break-after: avoid;      /* Titre reste avec le contenu */
    }
}
</style>

<section class="chapter">
    <h1>Chapitre 1 : Introduction</h1>
    <p>Contenu du chapitre...</p>
</section>
```

### Exemple 2 : Images avec Légendes

```html
<style>
@media print {
    .figure {
        break-inside: avoid;     /* Image + légende ensemble */
        display: block;          /* Important : pas flex ! */
    }
}
</style>

<div class="figure">
    <img src="diagram.png" alt="Diagramme">
    <p class="caption">Figure 1 : Description</p>
</div>
```

### Exemple 3 : Sections Important

```html
<style>
@media print {
    .important {
        break-inside: avoid;     /* Garde ensemble */
        padding: 20px;
        background: #fffacd;
        border: 2px solid #ffd700;
    }
}
</style>

<div class="important">
    <h3>⚠️ Important</h3>
    <p>Cette information ne doit pas être coupée entre deux pages.</p>
</div>
```

## 📝 Recommandations

### Pour les Nouveaux Projets

✅ **Utilisez WebEngine avec les propriétés CSS modernes**

```css
@media print {
    .chapter { break-before: page; }
    .section { break-inside: avoid; }
    h1, h2, h3 { break-after: avoid; }
    img, table, pre { break-inside: avoid; }
}
```

### Pour la Compatibilité Avec WebKit

⚠️ **Utilisez les deux syntaxes (fallback)**

```css
@media print {
    .section {
        /* Moderne (WebEngine) */
        break-inside: avoid;

        /* Ancien (WebKit patché) */
        page-break-inside: avoid;
    }
}
```

### À Éviter

❌ **N'utilisez PAS ces combinaisons**

```css
/* NE FONCTIONNE PAS */
.container {
    display: flex;              /* ← Problème */
    break-inside: avoid;        /* Ignoré ! */
}

/* NE FONCTIONNE PAS */
td {
    break-inside: avoid;        /* Ignoré dans les cellules ! */
}

/* NE FONCTIONNE PAS */
.element {
    overflow: hidden;           /* ← Bloque les sauts */
    break-inside: avoid;
}
```

## 🔗 Ressources

- [MDN: break-inside](https://developer.mozilla.org/en-US/docs/Web/CSS/break-inside)
- [MDN: break-before](https://developer.mozilla.org/en-US/docs/Web/CSS/break-before)
- [MDN: break-after](https://developer.mozilla.org/en-US/docs/Web/CSS/break-after)
- [CSS Paged Media Module](https://www.w3.org/TR/css-page-3/)
- [wkhtmltopdf CHANGELOG](CHANGELOG.md) - Historique des patches Qt

## 💬 Support

Si les tests échouent de manière inattendue :

1. Vérifiez la version installée : `wkhtmltopdf --version`
2. Confirmez que WebEngine est disponible
3. Examinez les logs de génération PDF
4. Ouvrez une issue sur GitHub avec les PDFs générés

## 📄 Licence

Ces tests font partie du projet wkhtmltopdf Multi-Backend Edition.
Licence: LGPL v3

---

**Créé le :** 2025-01-17
**Dernière mise à jour :** 2025-01-17
**Version :** 1.0
