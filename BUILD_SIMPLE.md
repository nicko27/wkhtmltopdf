# 🚀 Build Simple - Un Seul Script

## Utilisation

```bash
chmod +x build-deb.sh
./build-deb.sh
```

C'est tout ! Le script détecte automatiquement votre version d'Ubuntu et compile le bon package.

## Ce qui se passe automatiquement

### Sur Ubuntu 22.04 (Jammy)
Le script vous demande :
```
Quel backend Qt5 voulez-vous ?
1) webkit    - Petit (~40MB), rapide, CSS limité
2) webengine - Gros (~200MB), CSS moderne (Flexbox, Grid)
```

**Résultat :**
- `wkhtmltopdf-qt5-webkit_0.13.0-ubuntu22.04_amd64.deb` (option 1)
- `wkhtmltopdf-qt5-webengine_0.13.0-ubuntu22.04_amd64.deb` (option 2)

### Sur Ubuntu 24.04 (Noble)
Aucune question, compile automatiquement :
- `wkhtmltopdf-qt6-webengine_0.13.0-ubuntu24.04_amd64.deb`

## Installation

```bash
sudo dpkg -i wkhtmltopdf-*.deb
sudo apt-get install -f
```

## Test

```bash
wkhtmltopdf --version
echo '<h1>Test</h1>' > test.html
wkhtmltopdf test.html test.pdf
```

## Dépendances

Le script installe automatiquement les dépendances manquantes après confirmation.

**Qt5 WebKit :** ~100 MB
**Qt5 WebEngine :** ~300 MB
**Qt6 WebEngine :** ~250 MB
