# wkhtmltopdf Playwright Wrapper pour macOS

**Solution de remplacement** pour wkhtmltopdf sur macOS avec support CSS moderne complet.

## 🎯 Pourquoi ce wrapper ?

Le wkhtmltopdf original ne supporte pas les CSS modernes (flexbox, grid, etc.) et est difficile à compiler sur macOS. Ce wrapper utilise **Playwright + Chromium** pour fournir :

- ✅ **CSS3 complet** : Flexbox, Grid, Transforms, Animations
- ✅ **JavaScript moderne** : ES6+
- ✅ **Même interface CLI** que wkhtmltopdf
- ✅ **Facile à installer** : `npm install`
- ✅ **Compatible macOS, Linux, Windows**

## 🚀 Installation rapide

### Prérequis
- Node.js 14+ (installé via `brew install node` sur macOS)

### Installation

```bash
cd playwright-wrapper
npm install
```

Cela installe Playwright et télécharge Chromium (~300 MB la première fois).

## 📖 Utilisation

### Méthode 1 : Utilisation directe

```bash
node wkhtmltopdf.js input.html output.pdf
```

### Méthode 2 : Installation globale

```bash
npm install -g .

# Maintenant utilisable comme wkhtmltopdf
wkhtmltopdf input.html output.pdf
```

### Méthode 3 : Lien symbolique

```bash
chmod +x wkhtmltopdf.js
ln -s $(pwd)/wkhtmltopdf.js /usr/local/bin/wkhtmltopdf

# Maintenant wkhtmltopdf pointe vers ce wrapper
wkhtmltopdf input.html output.pdf
```

## 🎨 Exemples

### Basique
```bash
node wkhtmltopdf.js input.html output.pdf
```

### Avec options
```bash
node wkhtmltopdf.js \
  --page-size A4 \
  --orientation Landscape \
  --margin-top 20mm \
  --margin-bottom 20mm \
  input.html output.pdf
```

### Test avec la démo CSS moderne
```bash
node wkhtmltopdf.js ../examples/modern_css_demo.html modern.pdf
open modern.pdf  # macOS
```

## ⚙️ Options supportées

```
--page-size <size>          Taille du papier (A4, Letter, Legal, etc.)
--orientation <orientation> Portrait ou Landscape
--margin-top <margin>       Marge haut (ex: 10mm, 0.5in)
--margin-right <margin>     Marge droite
--margin-bottom <margin>    Marge bas
--margin-left <margin>      Marge gauche
--no-background             Ne pas imprimer les images de fond
--help, -h                  Afficher l'aide
--version                   Afficher la version
```

## 🆚 Comparaison avec wkhtmltopdf original

| Fonctionnalité | wkhtmltopdf original | Ce wrapper |
|----------------|---------------------|------------|
| **CSS Flexbox** | ❌ Non | ✅ Oui |
| **CSS Grid** | ❌ Non | ✅ Oui |
| **Animations CSS** | ⚠️ Limité | ✅ Oui |
| **JavaScript ES6+** | ❌ Non | ✅ Oui |
| **Taille installation** | ~20 MB | ~300 MB |
| **Vitesse** | Rapide | Légèrement plus lent |
| **Dépendances** | Qt | Node.js + Chromium |
| **macOS** | Difficile | ✅ Facile |

## 🔧 Intégration dans vos projets

### Node.js

```javascript
const { exec } = require('child_process');

function htmlToPdf(input, output) {
  return new Promise((resolve, reject) => {
    exec(`node wkhtmltopdf.js ${input} ${output}`, (error, stdout) => {
      if (error) reject(error);
      else resolve(stdout);
    });
  });
}

// Usage
htmlToPdf('report.html', 'report.pdf')
  .then(() => console.log('PDF créé !'))
  .catch(console.error);
```

### Python

```python
import subprocess

def html_to_pdf(input_file, output_file):
    subprocess.run([
        'node', 'wkhtmltopdf.js',
        input_file, output_file
    ], check=True)

# Usage
html_to_pdf('report.html', 'report.pdf')
```

### Shell Script

```bash
#!/bin/bash
for file in *.html; do
    node wkhtmltopdf.js "$file" "${file%.html}.pdf"
done
```

## 🐛 Dépannage

### "playwright: command not found"
```bash
cd playwright-wrapper
npm install
```

### "Cannot find module 'playwright'"
```bash
npm install playwright
```

### "Error: Failed to launch browser"
Playwright télécharge Chromium automatiquement. Si ça échoue :
```bash
npx playwright install chromium
```

### PDF vide ou erreur de chargement
Vérifiez que le fichier HTML existe et est accessible :
```bash
ls -la input.html
```

## 📊 Performance

**Temps de génération** (fichier HTML de 100 KB) :
- Premier lancement : ~3-5 secondes (démarrage Chromium)
- Lancements suivants : ~1-2 secondes
- wkhtmltopdf original : ~0.5-1 seconde

**Utilisation mémoire** :
- Ce wrapper : ~200-300 MB (Chromium)
- wkhtmltopdf original : ~50-100 MB

**Recommandation** : Pour des conversions en masse, garder le process Node.js en vie et réutiliser les instances Playwright.

## 🔄 Migration depuis wkhtmltopdf

La plupart des options CLI de base sont compatibles :

```bash
# Avant (wkhtmltopdf original)
wkhtmltopdf --page-size A4 input.html output.pdf

# Après (ce wrapper)
node wkhtmltopdf.js --page-size A4 input.html output.pdf
```

**Options non supportées** (pour l'instant) :
- `--enable-javascript` (toujours activé)
- `--javascript-delay` (utiliser waitUntil à la place)
- Headers/footers personnalisés (à implémenter)
- Table des matières (à implémenter)

## 🚀 Améliorations futures

- [ ] Support headers/footers
- [ ] Table des matières
- [ ] Plus d'options CLI
- [ ] Mode serveur (daemon)
- [ ] API REST
- [ ] Optimisation performances (pool de browsers)

## 🤝 Contribuer

Les Pull Requests sont bienvenues ! Pour ajouter des fonctionnalités :

1. Fork le projet
2. Créer une branche (`git checkout -b feature/ma-fonctionnalite`)
3. Commit (`git commit -am 'Ajout fonctionnalité'`)
4. Push (`git push origin feature/ma-fonctionnalite`)
5. Créer une Pull Request

## 📄 Licence

MIT - Libre d'utilisation pour tout usage

## 🙏 Crédits

- **wkhtmltopdf original** : https://wkhtmltopdf.org
- **Playwright** : https://playwright.dev
- **Chromium** : https://www.chromium.org

---

**Alternative recommandée pour macOS avec CSS moderne** 💚
