import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../models/outing.dart';
import '../config/supabase_config.dart';

/// Provider simplifié : appel direct à Shotgun GraphQL à chaque démarrage
class OutingsProvider extends ChangeNotifier {
  final List<Outing> _outings = [];
  final List<Outing> _dailyOutings = [];
  bool _isLoading = false;
  DateTime? _lastLoadTime;

  List<Outing> get outings => List.unmodifiable(_outings);
  List<Outing> get dailyOutings => List.unmodifiable(_dailyOutings);
  bool get isLoading => _isLoading;

  /// Charge les événements directement depuis Shotgun GraphQL API
  Future<void> loadEvents({bool forceRefresh = false}) async {
    // Cache : ne recharger que si plus de 30 minutes ou forceRefresh
    if (!forceRefresh && _lastLoadTime != null && _outings.isNotEmpty) {
      final elapsed = DateTime.now().difference(_lastLoadTime!);
      if (elapsed.inMinutes < 30) {
        debugPrint(
            '⏰ Cache valide (chargé il y a ${elapsed.inMinutes}min), skip reload');
        return;
      }
    }

    if (_isLoading) return;
    _isLoading = true;
    notifyListeners();

    _outings.clear();

    try {
      // Sur web : proxy Supabase Edge Function (contourner CORS)
      // Sur mobile/desktop : appel direct Shotgun
      const isWebPlatform = kIsWeb;
      const apiUrl = isWebPlatform
          ? 'https://joupiybyhoytfuncqmyv.supabase.co/functions/v1/update-outings/shotgun-proxy'
          : 'https://shotgun.live/api/graphql';

      // Appel à l'API GraphQL de Shotgun (direct ou via proxy)
      const query = '''
        query SearchEvents {
          search(input: {query: "Marseille", types: [EVENT], limit: 50}) {
            events {
              id
              title
              slug
              startDate
              description
              location { name city }
              categories
              image { url }
            }
          }
        }
      ''';

      debugPrint(
          '📡 Appel API: $apiUrl ${isWebPlatform ? "(proxy)" : "(direct)"}');

      final headers = {
        'Content-Type': 'application/json',
        'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64)',
        'Accept': 'application/json',
      };

      // Ajouter l'API key Supabase pour le proxy (format Edge Functions)
      if (isWebPlatform) {
        headers['Authorization'] = 'Bearer ${SupabaseConfig.supabaseAnonKey}';
        headers['apikey'] = SupabaseConfig.supabaseAnonKey;
      }

      final response = await http
          .post(
            Uri.parse(apiUrl),
            headers: headers,
            body: jsonEncode({'query': query}),
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final events = data['data']?['search']?['events'] as List? ?? [];

        debugPrint('✅ ${events.length} événements reçus de Shotgun');

        final now = DateTime.now();
        int skipped = 0;
        for (final event in events) {
          try {
            final startDate = event['startDate'] as String?;
            if (startDate == null) continue;

            final date = DateTime.parse(startDate);

            // Ignorer les événements passés de plus de 2h
            if (date.isBefore(now.subtract(const Duration(hours: 2)))) {
              skipped++;
              continue;
            }

            final categories = (event['categories'] as List?)
                    ?.map((c) => c.toString().toLowerCase())
                    .toList() ??
                [];

            _outings.add(Outing(
              id: 'shotgun_${event['id']}',
              title: event['title'] ?? '(Sans titre)',
              date: date,
              location: event['location']?['name'] ??
                  event['location']?['city'] ??
                  'Marseille',
              url: 'https://shotgun.live/fr/events/${event['slug']}',
              source: 'shotgun',
              categories: categories,
              description: event['description'],
              imageUrl: event['image']?['url'],
            ));
          } catch (e) {
            debugPrint('⚠️ Erreur parsing événement: $e');
          }
        }

        debugPrint(
            '✅ ${_outings.length} événements valides chargés ($skipped passés ignorés)');
        _lastLoadTime = DateTime.now(); // Marquer le temps de chargement
      } else if (response.statusCode == 429) {
        debugPrint('⚠️ Rate limit atteint (429), cache étendu à 1h');
        _lastLoadTime = DateTime.now(); // Marquer pour éviter de spammer
      } else {
        debugPrint('⚠️ Erreur API Shotgun: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('❌ Erreur chargement Shotgun: $e');
      // En cas d'erreur, marquer le cache pour éviter de réessayer immédiatement
      _lastLoadTime = DateTime.now();
    }

    _isLoading = false;
    notifyListeners();
  }

  /// Sélectionne 3 événements selon les préférences utilisateur
  List<Outing> pickSuggestion(List<String> preferences,
      {bool forceNew = false}) {
    if (_outings.isEmpty) {
      debugPrint('⚠️ Aucun événement chargé');
      return [];
    }

    // Si forceNew = true, on reset et on recalcule
    if (forceNew) {
      _dailyOutings.clear();
    } else if (_dailyOutings.isNotEmpty) {
      // Retourner la sélection existante
      return List.unmodifiable(_dailyOutings);
    }

    final prefs = preferences.map((e) => e.toLowerCase()).toSet();
    final now = DateTime.now();

    // Événements d'aujourd'hui uniquement
    final today = _outings
        .where((o) =>
            o.date.year == now.year &&
            o.date.month == now.month &&
            o.date.day == now.day)
        .toList();

    if (today.isEmpty) {
      // Pas d'événements aujourd'hui : prendre les 3 prochains
      final upcoming = _outings.where((o) => o.date.isAfter(now)).toList()
        ..sort((a, b) => a.date.compareTo(b.date));

      if (upcoming.isEmpty) {
        return [];
      }

      // Prendre les 3 prochains
      final selected = upcoming.take(3).toList();
      _dailyOutings
        ..clear()
        ..addAll(selected);
      return List.unmodifiable(_dailyOutings);
    }

    // Filtrer par préférences
    final matches = today.where((o) {
      final cats = o.categories.map((c) => c.toLowerCase()).toSet();
      return prefs.intersection(cats).isNotEmpty;
    }).toList();

    // Pool de sélection : préférer les matches, sinon tous les événements du jour
    List<Outing> pool = matches.isNotEmpty ? matches : today;

    // Mélanger et prendre 3 événements
    pool.shuffle(Random());
    final List<Outing> selected = pool.take(3).toList();

    // Si moins de 3, compléter avec n'importe quel événement futur
    if (selected.length < 3) {
      final remaining = _outings
          .where((o) => !selected.contains(o) && o.date.isAfter(now))
          .toList();
      remaining.shuffle(Random());
      selected.addAll(remaining.take(3 - selected.length));
    }

    _dailyOutings
      ..clear()
      ..addAll(selected.take(3));

    return List.unmodifiable(_dailyOutings);
  }

  /// Réinitialiser la sélection du jour
  void resetDailyOuting() {
    _dailyOutings.clear();
    notifyListeners();
  }
}
