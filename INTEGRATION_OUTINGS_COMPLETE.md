# 🎯 Intégration Événements Soirée - Guide Complet

## État actuel

✅ **Complété:**
- Edge Function `/update-outings`: Scrape 3 sources (tarpin-bien, sortiramarseille, marseille-tourisme), 201 événements insérés
- Edge Function `/filter-outings`: Retourne 5 événements filtrés par préférences utilisateur
- `OutingsProvider`: Méthode `getFilteredOutings()` pour appeler l'endpoint
- Splash Screen: Popup carousel avec 5 événements, pagination, lien direct (cliquable)
- Préférences existantes: Onglet "Préférences Soirée" avec SharedPreferences (local)

⏳ **À finaliser:**
1. Exécuter migration SQL pour créer la table `user_preferences` dans Supabase
2. Tester l'intégration complète

---

## ✅ Étape 1: Exécuter la migration `user_preferences`

### Option A: Via Supabase Dashboard (recommandé)

1. **Allez à**: https://supabase.com/dashboard/project/joupiybyhoytfuncqmyv/sql
2. **Créez une nouvelle requête** (bouton "+ New Query" en bas)
3. **Copiez le SQL suivant**:

```sql
-- Migration: Add user_preferences table for evening/soirée filtering
CREATE TABLE IF NOT EXISTS public.user_preferences (
  user_id uuid PRIMARY KEY DEFAULT auth.uid(),
  preferred_categories text[] DEFAULT '{"concert", "soiree", "electro", "expo"}',
  preferred_start_time time DEFAULT '19:00',
  preferred_end_time time DEFAULT '03:00',
  min_price numeric DEFAULT 0,
  max_price numeric DEFAULT 1000,
  exclude_keywords text[] DEFAULT '{"enfant", "jeune public", "famille", "kids"}',
  enable_notifications boolean DEFAULT true,
  created_at timestamp DEFAULT now(),
  updated_at timestamp DEFAULT now()
);

-- RLS: Users can only see/edit their own preferences
ALTER TABLE public.user_preferences ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view own preferences" ON public.user_preferences
  FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can update own preferences" ON public.user_preferences
  FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own preferences" ON public.user_preferences
  FOR INSERT WITH CHECK (auth.uid() = user_id);

-- Index for faster lookups
CREATE INDEX IF NOT EXISTS idx_user_preferences_user_id ON public.user_preferences(user_id);
```

4. **Exécutez** (Ctrl+Entrée ou bouton "▶ RUN")
5. ✅ **Résultat attendu**: "0 rows affected" (création de table réussie)

### Option B: Via Supabase CLI

```powershell
supabase db push --project-ref joupiybyhoytfuncqmyv
```

---

## 📱 Architecture d'intégration

### Flux d'événements:

```
SharedPreferences (local)              Supabase
   ↓                                      ↓
PreferencesScreen (existant)      /filter-outings (Edge Function)
   ↓ (sauvegarder)                      ↓
   ├─→ user_preferences table       Filtrer outings par:
   ├─→ notifier OutingsProvider        • categories
   │                                    • keywords exclus
   ↓                                    • plage horaire
OutingsProvider.pickSuggestion()       • fourchette prix
   ↓                                    ↓
   └─→ notifier SplashScreen      Retourner 5 événements
       (affiche popup carousel)
```

### Flux détaillé:

1. **Utilisateur clique "Événements du jour"** sur SplashScreen
2. **SplashScreen appelle** `OutingsProvider.getFilteredOutings(userId: 'kiki')`
3. **OutingsProvider appelle** `/filter-outings?user_id=kiki` (Edge Function)
4. **Edge Function**:
   - Lit les préférences de `user_preferences.kiki`
   - Filtre les 200+ événements de la table `outings` par:
     - Catégories préférées
     - Exclusions de mots-clés
     - Plage horaire
     - Fourchette de prix
   - Retourne 5 événements les plus pertinents (JSON)
5. **SplashScreen affiche** un Dialog avec:
   - Carousel PageView (swipable)
   - Indicateurs de page (dots)
   - Boutons Précédent/Suivant/Ouvrir
   - Détails de chaque événement (titre, lieu, date, catégories, description)
   - Lien direct vers la page de l'événement (cliquable)

---

## 🧪 Test d'intégration

### Test 1: Appel direct /filter-outings

```powershell
$url = "https://joupiybyhoytfuncqmyv.supabase.co/functions/v1/filter-outings?user_id=kiki"
$headers = @{
    "Authorization" = "Bearer votre_anon_key"
    "apikey" = "votre_anon_key"
}
$response = Invoke-RestMethod -Uri $url -Headers $headers
$response | ConvertTo-Json | Write-Host
```

**Résultat attendu:**
```json
{
  "success": true,
  "data": [
    {
      "id": "uuid...",
      "title": "Soirée Techno @ Marseille",
      "url": "https://...",
      "location": "Marseille",
      "date": "2025-01-15T21:00:00Z",
      "categories": ["electro", "techno"],
      "source": "tarpin-bien"
    },
    ...4 autres événements...
  ]
}
```

### Test 2: Flutter App

1. **Lancez l'app**: `flutter run`
2. **Naviguez à SplashScreen**
3. **Cliquez "Événements du jour"** (le bouton avec l'icône calendrier)
4. **Vérifiez**:
   - ✅ Un popup Dialog s'affiche
   - ✅ 5 événements apparaissent en carousel
   - ✅ Pagination (dots) fonctionne
   - ✅ Boutons Précédent/Suivant changent l'événement
   - ✅ Cliquer "Ouvrir" lance le navigateur vers l'URL de l'événement

---

## 🔗 Synchronisation SharedPreferences ↔ user_preferences (optionnel)

Pour persister les préférences dans Supabase au lieu de seulement local:

### Modification de PreferencesScreen:

```dart
// Dans _savePreferences():
// 1. Sauvegarder en local (SharedPreferences) - existant ✅
// 2. Ajouter: Sauvegarder aussi dans Supabase
if (user != null) {
  await supabase
    .from('user_preferences')
    .upsert({
      'user_id': user.id,
      'preferred_categories': selectedCategories.toList(),
      'updated_at': DateTime.now().toIso8601String(),
    });
}
```

Ceci synchroniserait les préférences locales vers le cloud. **Pas obligatoire** pour que l'app fonctionne (déjà utilise SharedPreferences local).

---

## 📊 Vérification des données

### Vérifier table `user_preferences`:

```sql
-- SQL à exécuter dans Supabase Dashboard
SELECT * FROM public.user_preferences;
```

**Résultat attendu**: Table vide ou avec quelques entrées utilisateurs

### Vérifier table `outings`:

```sql
SELECT COUNT(*), 
       ARRAY_AGG(DISTINCT source) as sources,
       ARRAY_AGG(DISTINCT date::date) as dates
FROM public.outings;
```

**Résultat attendu**:
- `count`: 201 (ou plus après scrapes quotidiens)
- `sources`: `["tarpin-bien", "sortiramarseille", "marseille-tourisme"]`
- `dates`: Multiple dates dans le futur

---

## 🚀 Prochaines étapes

1. ✅ Exécuter migration SQL `user_preferences`
2. ✅ Tester popup carousel sur SplashScreen
3. ✅ Vérifier liens directs (URLs cliquables)
4. ⏳ (Optionnel) Configurer Cron quotidien 6h du matin pour `/update-outings`
5. ⏳ (Optionnel) Synchroniser SharedPreferences vers `user_preferences` Supabase

---

## 📝 Notes

- **`user_preferences` table**: Optionnelle pour la v1 (app fonctionne avec SharedPreferences local)
- **`/filter-outings`**: Actuellement accepte `user_id=anonymous` si pas de table user_preferences
- **Mise à jour quotidienne**: Via Edge Function Cron, non implémentée dans cette intégration (déjà en place mais peut être configurée)
- **Carousel UI**: Entièrement custom dans `splash_screen_clean.dart`, utilise PageView + StatefulBuilder

