# Déploiement Google Calendar Integration

## ✅ Test Local (OBLIGATOIRE AVANT DÉPLOIEMENT)

1. L'app tourne sur http://localhost:8080
2. Clique sur l'icône Calendrier
3. Clique sur "Se connecter"
4. **Regarde la console** pour les logs :
   - `🔐 Début authentification Google Calendar...`
   - `✅ Utilisateur connecté: [email]`
   - `✅ API Calendar initialisée`

## 🚀 Déploiement si test local OK

```powershell
cd "e:\App todo\todo_app_kiki"
flutter build web --release
firebase deploy --only hosting
```

## 📝 Configuration Google Cloud

**URIs autorisés** (déjà configurés) :
- ✅ http://localhost:8080
- ✅ https://app-des-kiki-s.web.app

**Scopes** :
- calendar.readonly
- calendar.events

## 🎯 Fonctionnement

### Package utilisé
- `google_sign_in`: Gère l'OAuth avec popup
- `extension_google_sign_in_as_googleapis_auth`: Convertit en client googleapis
- **Avantage** : Pas de redirect, pas de token dans l'URL, pas de boucles

### Ce qui se passe
1. Popup Google s'ouvre (pas de redirect page entière)
2. Utilisateur se connecte
3. Token géré automatiquement par google_sign_in
4. Extension le convertit en client HTTP authentifié
5. GoogleCalendarService l'utilise directement

### Différences avec l'ancien code
- ❌ Avant : Redirect manuel, token dans URL hash, boucles infinies
- ✅ Maintenant : Popup, token géré en interne, navigation propre

## 🔍 Debug si problèmes

### Erreur "MissingPluginException"
→ Normal, google_sign_in ne marche QUE sur web, pas en dev mode Flutter

### Popup bloquée
→ Vérifie que le navigateur n'a pas bloqué les popups

### "Accès refusé"
→ Vérifie que les URIs sont bien dans Google Cloud Console

### Pas de logs dans console
→ Ouvre DevTools (F12) et active "Preserve log"

## 📦 Prochaines étapes (après déploiement)

1. ✅ Tester création automatique d'événements depuis tâches
2. ✅ Vérifier couleurs : Lou (vert), Julien (rose), Both (orange)
3. ✅ Tester sync bidirectionnelle (optionnel)
