# 🎉 Système de Scraping Événements - Configuration Complète

## ✅ Actuellement Configuré

### 1️⃣ Scraping Automatique
- **Edge Function**: `update-outings`
- **Fréquence**: À la demande (POST) + **À configurer**: Cron quotidien 06:00 UTC
- **Sources**: 
  - tarpin-bien.com (188 événements)
  - sortiramarseille.fr (0 - JS-rendered)
  - marseille-tourisme.com (14 événements)
- **Total**: 201 événements scrappés et insérés dans `outings`

### 2️⃣ Filtrage par Préférences
- **Edge Function**: `filter-outings`  
- **Endpoint**: `GET /filter-outings?user_id=<uuid>`
- **Retour**: 5 événements filtrés selon :
  - ✅ Catégories (concert, soiree, electro, expo, etc.)
  - ✅ Exclusion de mots-clés (enfant, jeune public, famille)
  - ✅ Budget (min/max price)
  - ✅ Horaires (preferred_start_time, preferred_end_time)

### 3️⃣ Base de Données
- **Table `outings`** : 201 lignes
  - Colonnes: id, url, title, source, categories, date, last_seen, location, organizer, price, etc.
- **Table `user_preferences`** : À créer (migration SQL fournie)
  - Stocke les préférences de chaque utilisateur

### 4️⃣ Services Flutter
- **OutingsService**: Classe pour accéder aux endpoints
  - `getOutingsByPreferences(userId)` → retourne 5 événements
  - `updateUserPreferences(...)` → sauvegarde les préfs
  - `getUserPreferences(userId)` → récupère les préfs

- **OutingsPreferencesScreen**: UI pour éditer les préférences
  - Sélection des catégories
  - Filtres de budget
  - Exclusion de mots-clés

- **OutingsListWidget**: Affichage des 5 événements du jour
  - Refresh automatique
  - Bouton paramètres (lien vers PreferencesScreen)

## 🔧 TODO - À Terminer

### Priorité HAUTE

1. **Exécuter la migration SQL** (user_preferences table)
   ```sql
   -- Exécute dans Supabase Dashboard → SQL Editor
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
   
   ALTER TABLE public.user_preferences ENABLE ROW LEVEL SECURITY;
   CREATE POLICY "Users can view own preferences" ON public.user_preferences
     FOR SELECT USING (auth.uid() = user_id);
   CREATE POLICY "Users can update own preferences" ON public.user_preferences
     FOR UPDATE USING (auth.uid() = user_id);
   CREATE POLICY "Users can insert own preferences" ON public.user_preferences
     FOR INSERT WITH CHECK (auth.uid() = user_id);
   ```

2. **Configurer le Cron quotidien** (06:00 UTC)
   - Dashboard → Functions → update-outings → Schedules
   - Ajouter: `0 6 * * * POST /update-outings`

### Priorité MOYENNE

3. **Intégrer OutingsService dans l'app Flutter**
   - Importer dans `lib/main.dart` ou créer un provider
   - Ajouter OutingsListWidget à la HomeScreen

4. **Intégrer OutingsPreferencesScreen**
   - Ajouter route dans le navigateur
   - Bouton settings dans OutingsListWidget

### Priorité BASSE

5. **Améliorer le parsing tarpin-bien.com**
   - Actuellement: 188 liens (dates toutes NULL, fallback à demain)
   - Objectif: Extraire vraies dates depuis chaque page d'événement

6. **Ajouter sortiramarseille.fr avec headless browser**
   - Site JS-rendu → peut nécessiter Playwright/Puppeteer
   - Alternative: Utiliser une API si disponible

## 📊 Endpoints Disponibles

### `update-outings` (POST)
```bash
curl -X POST \
  https://joupiybyhoytfuncqmyv.functions.supabase.co/update-outings \
  -H "apikey: <SERVICE_ROLE_KEY>" \
  -H "Authorization: Bearer <SERVICE_ROLE_KEY>" \
  -H "Content-Type: application/json" \
  -d '{}'
```
**Réponse**: `{success, inserted_count, total_events, events_preview, elapsed_ms}`

### `filter-outings` (GET)
```bash
curl -X GET \
  "https://joupiybyhoytfuncqmyv.functions.supabase.co/filter-outings?user_id=<uuid>" \
  -H "apikey: <SERVICE_ROLE_KEY>" \
  -H "Authorization: Bearer <SERVICE_ROLE_KEY>"
```
**Réponse**: `{success, user_id, count, events: [5 events], preferences_applied, total_candidates}`

## 🚀 Prochaines Étapes (En Ordre)

1. ✅ Créer edge functions pour scraping + filtering
2. ✅ Scraper 3 sources → 201 événements en base
3. ✅ Endpoint /filter-outings retourne 5 events
4. ⏳ Exécuter migration user_preferences
5. ⏳ Configurer cron 06:00 UTC
6. ⏳ Intégrer dans Flutter App
7. ⏳ Améliorer parsing et ajouter + de sources

## 📝 Fichiers Créés/Modifiés

- `supabase/functions/update-outings/index.ts` - Scraping + upsert
- `supabase/functions/filter-outings/index.ts` - Filtering par préfs
- `supabase/migrations/add_user_preferences.sql` - Migration (non exécutée)
- `lib/services/outings_service.dart` - Client API
- `lib/screens/outings_preferences_screen.dart` - UI préfs
- `lib/widgets/outings_list_widget.dart` - Affichage 5 events

## 💡 Notes

- Toutes les dates manquantes utilisent "demain" comme fallback
- Le filtrage est côté serveur (Edge Function)
- Les préférences sont stockées par utilisateur (auth.uid)
- RLS activé sur user_preferences (chacun ne voit que ses prefs)
