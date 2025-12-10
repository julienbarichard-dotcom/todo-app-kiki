import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
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
    final prefs = await SharedPreferences.getInstance();
    for (var categorie in _categoriesGroupees.values) {
      for (var entry in categorie.entries) {
        await prefs.setBool('pref_${entry.key}', entry.value);
      }
    }

    // Forcer le rafraîchissement des événements avec nouvelles préférences
    try {
      final outingsProv = Provider.of<OutingsProvider>(context, listen: false);
      outingsProv.resetDailyOuting(); // Vide le cache
      await outingsProv.loadEvents(); // Recharge

      // Récupérer nouvelles préférences actives
      final List<String> newPrefs = [];
      for (var categorie in _categoriesGroupees.values) {
        for (var entry in categorie.entries) {
          if (entry.value) newPrefs.add(entry.key);
        }
      }

      // Recalculer avec forceNew
      outingsProv.pickSuggestion(newPrefs, forceNew: true);
      debugPrint('✅ Événements rafraîchis avec nouvelles préférences');
    } catch (e) {
      debugPrint('⚠️ Erreur rafraîchissement événements: $e');
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Préférences sauvegardées ✓'),
          backgroundColor: Color(0xFF1DB679),
          duration: Duration(seconds: 2),
        ),
      );
    }
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
                    // Forcer nouveau calcul avec nouvelles préférences
                    if (mounted) {
                      final outingsProv =
                          Provider.of<OutingsProvider>(context, listen: false);
                      final prefs = await SharedPreferences.getInstance();
                      final userPreferences =
                          prefs.getStringList('user_music_preferences') ?? [];
                      outingsProv.pickSuggestion(userPreferences,
                          forceNew: true);
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                                '✅ Préférences sauvegardées et événements mis à jour'),
                            duration: Duration(seconds: 2),
                          ),
                        );
                      }
                    }
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
