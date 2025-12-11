import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import '../providers/outings_provider.dart';

class PreferencesScreen extends StatefulWidget {
  const PreferencesScreen({super.key});

  @override
  State<PreferencesScreen> createState() => _PreferencesScreenState();
}

class _PreferencesScreenState extends State<PreferencesScreen> {
  // Genres musicaux de Shotgun regroupés par catégorie
  final Map<String, Map<String, bool>> _categoriesGroupees = {
    '🎵 Électro & Techno': {
      'techno': true,
      'house': true,
      'deep house': false,
      'tech house': false,
      'melodic house & techno': false,
      'afro house': false,
      'trance': false,
      'hardtek': false,
      'hardcore': false,
      'acidcore': false,
    },
    '🎸 Hip-Hop & Urban': {
      'hip hop': false,
      'afrobeat': false,
      'reggaeton': false,
      'dancehall': false,
      'jersey club': false,
      'bass': false,
    },
    '🎶 Indie & Alternative': {
      'indie dance': false,
      'disco house': false,
      'experimental': false,
    },
    '🌍 World & Latin': {
      'latin': false,
      'tribe': false,
    },
    '🎭 Autres': {
      'concert': false,
      'festival': false,
      'expo': false,
      'art': false,
      'culture': false,
    },
  };

  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      // Charger les préférences sauvegardées
      for (var categorie in _categoriesGroupees.values) {
        for (var key in categorie.keys) {
          categorie[key] = prefs.getBool('pref_$key') ?? categorie[key]!;
        }
      }
      _isLoading = false;
    });
  }

  Future<void> _savePreferences() async {
    // 1. Sauvegarde locale (SharedPreferences)
    final prefs = await SharedPreferences.getInstance();
    for (var categorie in _categoriesGroupees.values) {
      for (var entry in categorie.entries) {
        await prefs.setBool('pref_${entry.key}', entry.value);
      }
    }

    // Forcer le rafraîchissement des événements avec nouvelles préférences
    // 2. Synchronisation automatique vers Supabase user_preferences
    try {
      final List<String> activeCategories = [];
      for (var categorie in _categoriesGroupees.values) {
        for (var entry in categorie.entries) {
          if (entry.value) activeCategories.add(entry.key);
        }
      }

      // Upsert vers user_preferences (user_id = 'kiki')
      final supabaseUrl = 'https://qmpzycqvmgwwhwviqvla.supabase.co';
      final supabaseKey =
          'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InFtcHp5Y3F2bWd3d2h3dmlxdmxhIiwicm9sZSI6ImFub24iLCJpYXQiOjE3MzQ2NzQ1MTYsImV4cCI6MjA1MDI1MDUxNn0.QZzT4T9Zg6HQJvHxpYZh8V0EKQXnHZDzJZKzCjdHk_g';

      final body = {
        'user_id': 'kiki',
        'categories': activeCategories,
        'keywords': [],
        'max_price': null,
      };

      final response = await http.post(
        Uri.parse('$supabaseUrl/rest/v1/user_preferences'),
        headers: {
          'Content-Type': 'application/json',
          'apikey': supabaseKey,
          'Authorization': 'Bearer $supabaseKey',
          'Prefer': 'resolution=merge-duplicates',
        },
        body: jsonEncode(body),
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        debugPrint('✅ Préférences synchronisées avec Supabase');
      } else {
        debugPrint(
            '⚠️ Erreur sync Supabase: ${response.statusCode} ${response.body}');
      }
    } catch (e) {
      debugPrint('⚠️ Erreur synchronisation Supabase: $e');
    }

    // 3. Rafraîchir les événements filtrés avec nouvelles préférences
    try {
      // ignore: use_build_context_synchronously
      final outingsProv = Provider.of<OutingsProvider>(context, listen: false);

      final List<String> newPrefs = [];
      for (var categorie in _categoriesGroupees.values) {
        for (var entry in categorie.entries) {
          if (entry.value) newPrefs.add(entry.key);
        }
      }

      // Recharger événements filtrés depuis /filter-outings (lit user_preferences)
      await outingsProv.getFilteredOutings();
      debugPrint('✅ Événements filtrés rechargés depuis Supabase');
    } catch (e) {
      debugPrint('⚠️ Erreur rafraîchissement événements: $e');
    }

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('✅ Préférences sauvegardées et événements mis à jour'),
        backgroundColor: Color(0xFF1DB679),
        duration: Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Préférences de sorties'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _savePreferences,
            tooltip: 'Sauvegarder',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                const Text(
                  'Choisis tes genres musicaux préférés pour recevoir des suggestions personnalisées :',
                  style: TextStyle(fontSize: 16, color: Colors.white70),
                ),
                const SizedBox(height: 20),
                ..._categoriesGroupees.entries.expand((categoryEntry) {
                  return [
                    // En-tête de catégorie
                    Padding(
                      padding: const EdgeInsets.only(top: 12, bottom: 8),
                      child: Text(
                        categoryEntry.key,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1DB679),
                        ),
                      ),
                    ),
                    // Genres de la catégorie
                    ...categoryEntry.value.entries.map((genreEntry) {
                      return Card(
                        margin: const EdgeInsets.only(bottom: 6),
                        color: Colors.black26,
                        child: SwitchListTile(
                          title: Text(
                            genreEntry.key,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                          value: genreEntry.value,
                          activeThumbColor: const Color(0xFF1DB679),
                          onChanged: (bool value) {
                            setState(() {
                              categoryEntry.value[genreEntry.key] = value;
                            });
                          },
                        ),
                      );
                    }),
                  ];
                }),
                const SizedBox(height: 20),
                ElevatedButton.icon(
                  onPressed: () async {
                    await _savePreferences();
                  },
                  icon: const Icon(Icons.save),
                  label: const Text('Sauvegarder mes préférences'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1DB679),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: () {
                    setState(() {
                      // Réinitialiser aux valeurs par défaut
                      for (var categorie in _categoriesGroupees.values) {
                        categorie.updateAll((key, value) => false);
                      }
                      _categoriesGroupees['🎵 Électro & Techno']!['techno'] =
                          true;
                      _categoriesGroupees['🎵 Électro & Techno']!['house'] =
                          true;
                    });
                    _savePreferences();
                  },
                  child: const Text(
                    'Réinitialiser aux valeurs par défaut',
                    style: TextStyle(color: Colors.white54),
                  ),
                ),
              ],
            ),
    );
  }
}
