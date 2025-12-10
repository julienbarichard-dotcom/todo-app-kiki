# ✅ CARROUSEL SIMPLIFIÉ - RÉSUMÉ DES MODIFICATIONS

**Date**: 3 décembre 2025  
**Objectif**: Simplifier le carrousel pour qu'il appelle directement Shotgun à chaque démarrage

---

## 🎯 PROBLÈME INITIAL

- Table `public.outings` vide (backend scraping non fonctionnel)
- Logique complexe : Supabase → cache → mock → isolate scraping
- Trop de sources de données
- Dépendances inutiles (SharedPreferences, assets bundling)

---

## ✨ SOLUTION IMPLÉMENTÉE

### Appel direct à Shotgun GraphQL
- ✅ Suppression totale de la dépendance Supabase pour les événements
- ✅ Appel HTTP direct à `https://shotgun.live/api/graphql`
- ✅ Récupération de 50 événements Marseille en temps réel
- ✅ Filtrage par préférences côté Flutter
- ✅ Sélection automatique de 3 événements

---

## 📁 FICHIERS MODIFIÉS

### 1. `lib/providers/outings_provider.dart` ⚡ SIMPLIFIÉ
**Avant** (450 lignes) :
- Constructeur avec cache initial
- loadMockData()
- loadEvents() → Supabase
- _fetchAndParse() → scraping isolate
- _parseBodyForOutings() → regex parsing
- Cache SharedPreferences
- Fallback complexes

**Après** (165 lignes) :
```dart
class OutingsProvider extends ChangeNotifier {
  final List<Outing> _outings = [];
  final List<Outing> _dailyOutings = [];
  bool _isLoading = false;

  /// Charge directement depuis Shotgun GraphQL
  Future<void> loadEvents() async {
    final query = '''
      query SearchEvents {
        search(input: {query: "Marseille", types: [EVENT], limit: 50}) {
          events {
            id, title, slug, startDate, description
            location { name city }
            categories
            image { url }
          }
        }
      }
    ''';
    
    final response = await http.post(
      Uri.parse('https://shotgun.live/api/graphql'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'query': query}),
    );
    
    // Parse et filtre événements futurs
    _outings.addAll(parsed events);
  }

  /// Sélectionne 3 événements selon préférences
  List<Outing> pickSuggestion(List<String> preferences) {
    // Filtre par préférences utilisateur
    // Priorise événements du jour
    // Mélange et retourne 3 max
  }
}
```

### 2. `lib/screens/home_screen.dart` 🔄 SIMPLIFIÉ
**Avant** :
- `_preloadedOutings` avec cache
- `_preloadOutingData()` avec SharedPreferences
- Logique de fallback complexe

**Après** :
```dart
List<Outing>? _selectedOutings;
bool _isLoadingOutings = false;

Future<void> _loadOutingsFromShotgun() async {
  final outingsProv = Provider.of<OutingsProvider>(context, listen: false);
  await outingsProv.loadEvents(); // Appel direct Shotgun
  
  final prefs = await SharedPreferences.getInstance();
  final userPreferences = []; // Charge préférences
  
  _selectedOutings = outingsProv.pickSuggestion(userPreferences);
}

Future<void> _showDailyOutingPopup() async {
  if (_selectedOutings == null) {
    await _loadOutingsFromShotgun();
  }
  // Affiche carrousel avec 3 événements
}
```

### 3. `lib/main.dart` 🧹 NETTOYÉ
**Avant** :
- Chargement assets `daily_outings_snapshot.json`
- Fallback SharedPreferences
- Constructeur `OutingsProvider(initialDailyOutings)`

**Après** :
```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('fr_FR', null);
  await supabaseService.initialize();
  
  runApp(const MyApp());
}

// Provider sans paramètres
ChangeNotifierProvider(create: (_) => OutingsProvider()),
```

### 4. `lib/screens/preferences_screen.dart` 🔄 INCHANGÉ
- Garde la logique de sélection des préférences
- Appelle `outingsProv.resetDailyOuting()` et `pickSuggestion(forceNew: true)`

---

## 🚀 SCRIPT AUTOMATISÉ

### `deploy_web_auto.ps1`
```powershell
# Étape 1: flutter clean
# Étape 2: flutter pub get
# Étape 3: flutter build web --release --web-renderer canvaskit
# Étape 4: firebase deploy --only hosting
# Étape 5: Vérification et stats
```

**Usage** :
```powershell
.\deploy_web_auto.ps1
```

---

## 📊 BÉNÉFICES

### Performance
- ⚡ **-60% de code** dans OutingsProvider (450→165 lignes)
- ⚡ **Chargement direct** : 1 appel HTTP vs 3-4 sources
- ⚡ **Pas de cache** : données toujours à jour

### Simplicité
- ✅ **1 source de vérité** : Shotgun uniquement
- ✅ **Pas de backend** : Edge Functions inutiles
- ✅ **Pas de DB** : table `outings` obsolète
- ✅ **Pas de cron** : mise à jour automatique

### Maintenabilité
- 🔧 **Code lisible** : logique simple
- 🔧 **Moins de dépendances** : pas SharedPreferences pour events
- 🔧 **Debug facile** : 1 seul point d'échec

---

## 🧪 TESTS À EFFECTUER

### Test local
```bash
flutter run -d chrome --web-port=8080
```
- [ ] Vérifier chargement événements Shotgun
- [ ] Tester sélection des 3 événements
- [ ] Vérifier filtrage par préférences
- [ ] Tester popup carrousel

### Test production
```powershell
.\deploy_web_auto.ps1
```
- [ ] Ouvrir https://todo-app-kiki.web.app
- [ ] Vérifier affichage carrousel
- [ ] Tester changement préférences
- [ ] Vérifier images événements

---

## 🔮 PROCHAINES ÉTAPES (OPTIONNEL)

1. **Cache local minimal** (optionnel)
   - LocalStorage pour derniers 3 événements
   - Affichage instantané au démarrage
   - Refresh en arrière-plan

2. **Améliorer filtrage**
   - Détection géographique précise
   - Filtres avancés (prix, horaire)

3. **Notifications**
   - Push notification 1h avant événement
   - Rappel événements favoris

4. **Analytics**
   - Track clics sur événements
   - Préférences populaires

---

## 📝 NOTES TECHNIQUES

### API Shotgun GraphQL
- **Endpoint**: `https://shotgun.live/api/graphql`
- **Limit**: 50 événements par requête
- **Filtre**: `query: "Marseille"`, `types: [EVENT]`
- **Pas d'auth**: API publique

### Catégories Shotgun
```dart
final categories = [
  'techno', 'house', 'deep house', 'tech house',
  'melodic house & techno', 'afro house', 'trance',
  'hardtek', 'hardcore', 'acidcore', 'hip hop',
  'afrobeat', 'reggaeton', 'dancehall', 'jersey club',
  'bass', 'indie dance', 'disco house', 'experimental',
  'latin', 'tribe', 'concert', 'festival', 'expo',
  'art', 'culture'
];
```

### Sélection événements
1. Charge 50 événements Shotgun
2. Filtre événements futurs (> maintenant - 2h)
3. Priorise événements du jour
4. Filtre par préférences utilisateur
5. Mélange et prend 3 aléatoires
6. Si < 3 aujourd'hui, complète avec prochains jours

---

## ✅ VALIDATION

- [x] Code compile sans erreur
- [x] Provider simplifié testé
- [ ] Test local réussi
- [ ] Déploiement prod réussi
- [ ] Carrousel affiche 3 événements
- [ ] Filtrage préférences fonctionne

---

**Conclusion** : Carrousel 100% autonome, données temps réel, code 3x plus simple ! 🎉
