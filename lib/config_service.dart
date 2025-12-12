import 'package:flutter/services.dart' show rootBundle;

import 'config.dart';

/// Service minimal pour récupérer l'URL du scraper.
///
/// Priorité:
/// 1. valeur compilée dans `lib/config.dart` (si définie)
/// 2. contenu de l'asset `assets/scraper_url.txt` (pratique pour déployer sans recompiler)
class ConfigService {
  static Future<String?> getScraperApiUrl() async {
    // valeur compilée (si fournie)
    if (scraperApiUrl != null && scraperApiUrl!.isNotEmpty) {
      return scraperApiUrl;
    }

    // sinon, tenter de lire un asset `assets/scraper_url.txt` si présent
    try {
      final raw = await rootBundle.loadString('assets/scraper_url.txt');
      final trimmed = raw.trim();
      if (trimmed.isEmpty) return null;
      return trimmed;
    } catch (e) {
      return null;
    }
  }
}
