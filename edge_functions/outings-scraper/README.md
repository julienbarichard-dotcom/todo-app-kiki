Outings Scraper (MVP)

Squelette d'un microservice pour agréger des événements depuis plusieurs sites.

Local (dev):

1. Installer dépendances:

   npm install

2. Lancer en local:

   npm start

L'API expose un endpoint HTTP `GET /events` qui retourne un JSON des événements trouvés.

Déployer:

- Option A — Google Cloud Run / AWS Fargate / Heroku:
  - Construire une image Docker et déployer sur Cloud Run (ou autre). Cloud Run contourne les problèmes CORS pour la webapp.

- Option B — Supabase Edge Functions:
  - Les Edge Functions Supabase utilisent Deno/TypeScript par défaut. Pour utiliser ce script Node, vous pouvez déployer derrière un service (Cloud Run) et appeler ce service depuis Supabase ou depuis le client.

Notes:
- Pour fiabilité et contournement CORS, il est recommandé de scraper côté serveur (Cloud Run / Edge Function) puis d'exposer un endpoint REST que l'app web appelle.
- Remplacer la logique heuristique par des parsers dédiés (RSS/API) quand les sources les proposent.
