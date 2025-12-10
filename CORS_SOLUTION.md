# Problème CORS avec Shotgun API

## Cause
L'API Shotgun (`https://shotgun.live/api/graphql`) bloque les requêtes CORS depuis les applications web (politique de sécurité).

## Erreur rencontrée
```
ClientException: Failed to fetch, uri=https://shotgun.live/api/graphql
```

## Solutions possibles

### Option 1 : Tester sur mobile/desktop (RECOMMANDÉ)
Les plateformes natives (Android, iOS, Windows, macOS, Linux) ne sont pas soumises aux restrictions CORS.

**Commandes :**
```bash
# Android
flutter run -d android

# iOS
flutter run -d ios

# Windows
flutter run -d windows

# Desktop Linux/macOS
flutter run -d linux
flutter run -d macos
```

### Option 2 : Créer un proxy backend simple
Créer une Cloud Function Firebase qui fait l'appel côté serveur :

**Fichier `functions/index.js` :**
```javascript
const functions = require('firebase-functions');
const fetch = require('node-fetch');

exports.shotgunProxy = functions.https.onRequest(async (req, res) => {
  res.set('Access-Control-Allow-Origin', '*');
  
  const query = `
    query SearchEvents {
      search(input: {query: "Marseille", types: [EVENT], limit: 50}) {
        events {
          id title slug startDate description
          location { name city }
          categories
          image { url }
        }
      }
    }
  `;

  try {
    const response = await fetch('https://shotgun.live/api/graphql', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'User-Agent': 'Mozilla/5.0',
      },
      body: JSON.stringify({ query }),
    });

    const data = await response.json();
    res.json(data);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});
```

**Puis dans `outings_provider.dart` :**
```dart
// Remplacer l'URL
final response = await http.post(
  Uri.parse('https://YOUR-PROJECT.cloudfunctions.net/shotgunProxy'),
  // ... rest of code
);
```

### Option 3 : Désactiver CORS en dev (temporaire)
Lancer Chrome avec CORS désactivé (UNIQUEMENT pour tests locaux) :

**Windows :**
```bash
"C:\Program Files\Google\Chrome\Application\chrome.exe" --disable-web-security --user-data-dir="C:\temp\chrome_dev"
```

Puis lancer l'app :
```bash
flutter run -d chrome --web-port=8080
```

⚠️ **NE JAMAIS utiliser en production !**

### Option 4 : Utiliser mock data en web
Garder l'API Shotgun pour mobile, utiliser des données fictives pour web :

```dart
Future<void> loadEvents() async {
  if (kIsWeb) {
    // Mode web : mock data
    _loadMockData();
  } else {
    // Mode natif : vraie API
    await _loadFromShotgun();
  }
}
```

## Recommandation finale
**Utiliser Option 1** : Tester sur Android/iOS pour validation complète, déployer le web avec Option 2 (proxy Firebase) pour la production.
