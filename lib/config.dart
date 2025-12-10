// Configuration simple pour l'app
// Définir ici l'URL publique de ton service de scraping (Edge Function / Cloudflare / Supabase)
// Exemple: const scraperApiUrl = 'https://<ton-service>.example.com/events';

/// URL publique du scraper. Laisser `null` pour utiliser le parsing client/mock.
const String? scraperApiUrl = null;

/// Drapeau de débogage : si `true`, on désactive temporairement
/// toutes les tentatives d'authentification Google Calendar au démarrage.
/// Utilise ceci pour tester l'UI / popup sans lancer la flow OAuth.
const bool disableCalendarAuthForDev = false;
