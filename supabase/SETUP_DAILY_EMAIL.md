# Configuration Supabase Edge Function - Email quotidien
# =======================================================

## 1. Déployer la fonction

Installer Supabase CLI si pas déjà fait:
```bash
npm install -g supabase
```

Se connecter à Supabase:
```bash
supabase login
```

Lier le projet:
```bash
cd "E:\App todo\todo_app_kiki"
supabase link --project-ref joupiybyhoytfuncqmyv
```

Déployer la fonction:
```bash
supabase functions deploy daily-email
```

## 2. Configurer les secrets

Ajouter la clé API Resend (https://resend.com - gratuit jusqu'à 100 emails/jour):
```bash
supabase secrets set RESEND_API_KEY=re_xxxxxxxxxx
```

## 3. Configurer le Cron Job

Dans Supabase Dashboard > Database > Extensions, activer `pg_cron`.

Puis dans SQL Editor, exécuter:

```sql
-- Créer le cron job pour 8h00 chaque matin (heure de Paris = 7h UTC en hiver, 6h UTC en été)
SELECT cron.schedule(
  'daily-email-recap',
  '0 7 * * *',  -- 7h UTC = 8h Paris (heure d'hiver)
  $$
  SELECT
    net.http_post(
      url := 'https://joupiybyhoytfuncqmyv.supabase.co/functions/v1/daily-email',
      headers := jsonb_build_object(
        'Content-Type', 'application/json',
        'Authorization', 'Bearer ' || current_setting('supabase.service_role_key')
      ),
      body := '{}'
    );
  $$
);
```

Pour vérifier les jobs actifs:
```sql
SELECT * FROM cron.job;
```

## 4. Configurer les adresses email

Modifier les adresses dans `supabase/functions/daily-email/index.ts`:

```typescript
const USERS_CONFIG = {
  Lou: {
    email: "lou@vraie-adresse.com",  // Remplacer par l'adresse de Lou
    name: "Lou",
  },
  Julien: {
    email: "julien@vraie-adresse.com",  // Remplacer par l'adresse de Julien
    name: "Julien",
  },
};
```

## 5. Tester manuellement

```bash
supabase functions invoke daily-email
```

Ou via curl:
```bash
curl -X POST https://joupiybyhoytfuncqmyv.supabase.co/functions/v1/daily-email \
  -H "Authorization: Bearer YOUR_ANON_KEY" \
  -H "Content-Type: application/json"
```
