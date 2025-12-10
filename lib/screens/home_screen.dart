import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../utils/color_extensions.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';
// Import conditionnel : 'dart:html' sur le web, stub sur les autres plateformes
import '../src/html_stub.dart' if (dart.library.html) 'dart:html' as html;
import '../models/todo_task.dart';
import '../models/view_preference.dart';
import '../providers/todo_provider.dart';
import '../providers/user_provider.dart';
import '../providers/outings_provider.dart';
import '../services/google_calendar_service.dart';
import '../config.dart';
import '../widgets/weather_widget.dart';
import '../widgets/daily_outing_carousel.dart';
import '../widgets/view_selector.dart';
import '../models/outing.dart';
import '../utils/open_link.dart';
import 'add_task_screen.dart';
import 'calendar_screen.dart';
import 'kanban_screen.dart';
import 'kanban_view_wrapper.dart';
import 'list_view_screen.dart';
import 'compact_view_screen.dart';
import 'timeline_view_screen.dart';
import 'stats_screen.dart';
import 'preferences_screen.dart';

/// Écran principal - Affiche les tâches
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String get utilisateurActuel {
    final userProvider = context.read<UserProvider>();
    return userProvider.currentUser?.prenom ?? 'Unknown';
  }

  static const Color mintGreen = Color(0xFF1DB679);

  // États des filtres
  String _triDate = 'proche'; // 'proche', 'lointain'
  String _filtrePeriode =
      'jour'; // 'jour', 'semaine', 'mois', 'continue', 'toutes'
  String? _filtreEtat; // null, 'en_cours', 'termine'
  String? _filtreLabel; // null ou nom du label
  bool? _filtreSousTaches; // null, true (avec), false (sans)
  String? _filtrePriorite; // null, 'haute', 'moyenne', 'basse'

  // Événements sélectionnés pour le carrousel
  List<Outing>? _selectedOutings;
  bool _isLoadingOutings = false;

  @override
  void initState() {
    super.initState();
    _chargerTaches(); // Charge et reporte automatiquement dans loadTaches()
    // Attendre que le widget soit monté avant d'afficher la popup
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _restaurerSessionCalendar();
      _loadOutingsFromShotgun(); // Charger directement depuis Shotgun
    });
  }

  Future<void> _chargerTaches() async {
    await context.read<TodoProvider>().loadTaches();
  }

  /// Tenter de restaurer automatiquement la session Google Calendar
  Future<void> _restaurerSessionCalendar() async {
    // Si on veut tester rapidement l'UI sans lancer le flow OAuth Google,
    // active temporairement `disableCalendarAuthForDev = true` dans `lib/config.dart`.
    if (disableCalendarAuthForDev) {
      debugPrint(
          '⚠️ Debug: skip Google Calendar restore (disableCalendarAuthForDev=true)');
      return;
    }

    try {
      // D'abord essayer de restaurer silencieusement
      final restored = await GoogleCalendarService().tryRestoreSession();
      if (!mounted) return;

      if (restored) {
        debugPrint('✅ Session Google Calendar restaurée automatiquement');
      } else {
        // Toujours demander la connexion Calendar car c'est essentiel
        debugPrint('🔄 Connexion Google Calendar requise...');
        if (mounted) {
          _afficherPopupConnexionCalendar();
        }
      }
    } catch (e) {
      debugPrint('⚠️ Erreur restauration Calendar au démarrage: $e');
      if (mounted) {
        _afficherPopupConnexionCalendar();
      }
    }
  }

  /// Charger les événements directement depuis Shotgun GraphQL
  Future<void> _loadOutingsFromShotgun() async {
    if (_isLoadingOutings) return;
    _isLoadingOutings = true;

    try {
      final outingsProv = Provider.of<OutingsProvider>(context, listen: false);

      // Appel direct à Shotgun
      await outingsProv.loadEvents();

      // Charger les préférences utilisateur
      final prefs = await SharedPreferences.getInstance();
      final List<String> userPreferences = [];

      // Liste des genres musicaux
      final categories = [
        'techno',
        'house',
        'deep house',
        'tech house',
        'melodic house & techno',
        'afro house',
        'trance',
        'hardtek',
        'hardcore',
        'acidcore',
        'hip hop',
        'afrobeat',
        'reggaeton',
        'dancehall',
        'jersey club',
        'bass',
        'indie dance',
        'disco house',
        'experimental',
        'latin',
        'tribe',
        'concert',
        'festival',
        'expo',
        'art',
        'culture',
      ];

      // Récupérer les catégories activées
      for (var cat in categories) {
        final isEnabled = prefs.getBool('pref_$cat');
        if (isEnabled == true) {
          userPreferences.add(cat);
        }
      }

      // Si aucune préférence, utiliser défaut
      if (userPreferences.isEmpty) {
        userPreferences.addAll(['techno', 'house']);
      }

      // Sélectionner les 3 événements
      _selectedOutings = outingsProv.pickSuggestion(userPreferences);
      debugPrint('✅ Événements sélectionnés: ${_selectedOutings?.length ?? 0}');
    } catch (e) {
      debugPrint('⚠️ Erreur chargement événements: $e');
    } finally {
      _isLoadingOutings = false;
    }
  }

  /// Afficher le popup d'événement du jour
  Future<void> _showDailyOutingPopup() async {
    if (!mounted) return;

    try {
      // Si pas encore chargé, charger maintenant
      if ((_selectedOutings == null || _selectedOutings!.isEmpty) &&
          !_isLoadingOutings) {
        await _loadOutingsFromShotgun();
      }

      // Utiliser la sélection
      final suggestions = _selectedOutings;
      if (suggestions != null && suggestions.isNotEmpty && mounted) {
        // Afficher le popup
        showDialog(
          context: context,
          barrierDismissible: true,
          builder: (context) {
            return Dialog(
              backgroundColor: const Color(0xFF121212),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: DailyOutingCarousel(
                  outings: suggestions,
                  onView: (o) async {
                    Navigator.of(context).pop();
                    await openLink(o.url);
                  },
                ),
              ),
            );
          },
        );
      } else if (mounted) {
        // Aucun événement trouvé
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Aucun événement disponible aujourd\'hui'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      debugPrint('Erreur affichage popup sortie: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Afficher le popup de notes rapides
  // NOTE: la boîte de dialogue de "note rapide" n'est actuellement pas utilisée.
  // Si besoin plus tard, réimplémenter `_showQuickNoteDialog`.

  /// Afficher popup demandant la connexion Google Calendar
  void _afficherPopupConnexionCalendar() {
    if (!mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.calendar_today, color: Colors.red),
            SizedBox(width: 12),
            Text('⚠️ Connexion Google Calendar requise'),
          ],
        ),
        content: const Text(
          '🔴 ATTENTION : Google Calendar est OBLIGATOIRE pour :\n\n'
          '✓ Synchroniser automatiquement vos tâches\n'
          '✓ Voir l\'agenda complet\n'
          '✓ Recevoir les notifications\n'
          '✓ Accéder à la vue calendrier\n\n'
          '❌ Sans connexion, l\'application ne fonctionnera pas correctement.\n\n'
          'Connectez-vous maintenant pour une expérience complète.',
          style: TextStyle(fontSize: 14),
        ),
        actions: [
          ElevatedButton.icon(
            onPressed: () async {
              final navigator = Navigator.of(context);
              final messenger = ScaffoldMessenger.of(context);
              navigator.pop();
              final success = await GoogleCalendarService().authenticate();
              if (!mounted) return;
              if (success) {
                messenger.showSnackBar(
                  const SnackBar(
                    content: Text('✅ Google Calendar connecté avec succès !'),
                    backgroundColor: Colors.green,
                    duration: Duration(seconds: 3),
                  ),
                );
              } else {
                // Réafficher le popup si échec
                messenger.showSnackBar(
                  const SnackBar(
                    content: Text('❌ Échec de la connexion, réessayez'),
                    backgroundColor: Colors.red,
                    duration: Duration(seconds: 2),
                  ),
                );
                // Attendre un peu puis réafficher
                Future.delayed(const Duration(seconds: 3), () {
                  if (mounted && !GoogleCalendarService().isAuthenticated) {
                    _afficherPopupConnexionCalendar();
                  }
                });
              }
            },
            icon: const Icon(Icons.check_circle, size: 20),
            label: const Text('Se connecter maintenant'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  /// Applique tous les filtres sur la liste de tâches
  List<TodoTask> _appliquerFiltres(List<TodoTask> taches) {
    var tachesFiltrees = List<TodoTask>.from(taches);

    // TOUJOURS filtrer les tâches complètes (elles vont dans Kanban)
    tachesFiltrees = tachesFiltrees.where((t) => !t.estComplete).toList();

    // Filtre par état
    if (_filtreEtat == 'en_attente') {
      tachesFiltrees =
          tachesFiltrees.where((t) => t.statut == Statut.enAttente).toList();
    } else if (_filtreEtat == 'en_cours') {
      tachesFiltrees =
          tachesFiltrees.where((t) => t.statut == Statut.enCours).toList();
    }

    // Filtre par label
    if (_filtreLabel != null) {
      tachesFiltrees =
          tachesFiltrees.where((t) => t.label == _filtreLabel).toList();
    }

    // Filtre par sous-tâches
    if (_filtreSousTaches != null) {
      if (_filtreSousTaches!) {
        tachesFiltrees =
            tachesFiltrees.where((t) => t.subTasks.isNotEmpty).toList();
      } else {
        tachesFiltrees =
            tachesFiltrees.where((t) => t.subTasks.isEmpty).toList();
      }
    }

    // Filtre par priorité
    if (_filtrePriorite != null) {
      final urgence = _filtrePriorite == 'haute'
          ? Urgence.haute
          : _filtrePriorite == 'moyenne'
              ? Urgence.moyenne
              : Urgence.basse;
      tachesFiltrees =
          tachesFiltrees.where((t) => t.urgence == urgence).toList();
    }

    // Filtre par période
    if (_filtrePeriode != 'toutes') {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);

      if (_filtrePeriode == 'jour') {
        // Tâches aujourd'hui
        tachesFiltrees = tachesFiltrees.where((t) {
          if (t.dateEcheance == null) return false;
          final taskDate = DateTime(
              t.dateEcheance!.year, t.dateEcheance!.month, t.dateEcheance!.day);
          return taskDate.isAtSameMomentAs(today);
        }).toList();
      } else if (_filtrePeriode == 'semaine') {
        // Tâches de la semaine (7 prochains jours)
        final weekEnd = today.add(const Duration(days: 7));
        tachesFiltrees = tachesFiltrees.where((t) {
          if (t.dateEcheance == null) return false;
          final taskDate = DateTime(
              t.dateEcheance!.year, t.dateEcheance!.month, t.dateEcheance!.day);
          return taskDate.isAfter(today.subtract(const Duration(days: 1))) &&
              taskDate.isBefore(weekEnd);
        }).toList();
      } else if (_filtrePeriode == 'mois') {
        // Tâches du mois (30 prochains jours)
        final monthEnd = today.add(const Duration(days: 30));
        tachesFiltrees = tachesFiltrees.where((t) {
          if (t.dateEcheance == null) return false;
          final taskDate = DateTime(
              t.dateEcheance!.year, t.dateEcheance!.month, t.dateEcheance!.day);
          return taskDate.isAfter(today.subtract(const Duration(days: 1))) &&
              taskDate.isBefore(monthEnd);
        }).toList();
      } else if (_filtrePeriode == 'continue') {
        // Tâches sans date (continues)
        tachesFiltrees =
            tachesFiltrees.where((t) => t.dateEcheance == null).toList();
      }
    }

    // Tri par date
    tachesFiltrees.sort((a, b) {
      final dateA = a.dateEcheance ?? DateTime(9999);
      final dateB = b.dateEcheance ?? DateTime(9999);
      return _triDate == 'proche'
          ? dateA.compareTo(dateB)
          : dateB.compareTo(dateA);
    });

    return tachesFiltrees;
  }

  Widget _buildFiltresSection() {
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 16, 8, 6),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            // Tri
            Container(
              width: 130,
              height: 42,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade400),
                borderRadius: BorderRadius.circular(8),
              ),
              child: DropdownButton<String>(
                value: _triDate,
                isExpanded: true,
                underline: const SizedBox(),
                dropdownColor: const Color(0xFF1E1E1E),
                style: const TextStyle(fontSize: 9, color: Colors.white),
                items: const [
                  DropdownMenuItem(
                      value: 'proche', child: Text('📅 Date proche')),
                  DropdownMenuItem(
                      value: 'lointain', child: Text('📅 Date lointaine')),
                ],
                onChanged: (value) {
                  if (value != null) setState(() => _triDate = value);
                },
              ),
            ),
            const SizedBox(width: 6),
            // Filtre par période
            Container(
              width: 130,
              height: 42,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade400),
                borderRadius: BorderRadius.circular(8),
              ),
              child: DropdownButton<String>(
                value: _filtrePeriode,
                isExpanded: true,
                underline: const SizedBox(),
                dropdownColor: const Color(0xFF1E1E1E),
                style: const TextStyle(fontSize: 9, color: Colors.white),
                items: const [
                  DropdownMenuItem(
                      value: 'toutes', child: Text('📅 Toutes périodes')),
                  DropdownMenuItem(
                      value: 'jour', child: Text('📅 Aujourd\'hui')),
                  DropdownMenuItem(
                      value: 'semaine', child: Text('📅 Cette semaine')),
                  DropdownMenuItem(value: 'mois', child: Text('📅 Ce mois')),
                  DropdownMenuItem(
                      value: 'continue', child: Text('♾️ Sans date')),
                ],
                onChanged: (value) {
                  if (value != null) setState(() => _filtrePeriode = value);
                },
              ),
            ),
            const SizedBox(width: 6),
            // État
            Container(
              width: 130,
              height: 42,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade400),
                borderRadius: BorderRadius.circular(8),
              ),
              child: DropdownButton<String?>(
                value: _filtreEtat,
                isExpanded: true,
                underline: const SizedBox(),
                dropdownColor: const Color(0xFF1E1E1E),
                style: const TextStyle(fontSize: 9, color: Colors.white),
                items: const [
                  DropdownMenuItem(value: null, child: Text('✅ Tous états')),
                  DropdownMenuItem(
                      value: 'en_attente', child: Text('⏸️ A faire')),
                  DropdownMenuItem(
                      value: 'en_cours', child: Text('▶️ En cours')),
                ],
                onChanged: (value) => setState(() => _filtreEtat = value),
              ),
            ),
            const SizedBox(width: 6),
            // Priorité
            Container(
              width: 130,
              height: 42,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade400),
                borderRadius: BorderRadius.circular(8),
              ),
              child: DropdownButton<String?>(
                value: _filtrePriorite,
                isExpanded: true,
                underline: const SizedBox(),
                dropdownColor: const Color(0xFF1E1E1E),
                style: const TextStyle(fontSize: 9, color: Colors.white),
                items: const [
                  DropdownMenuItem(
                      value: null, child: Text('🎯 Toutes priorités')),
                  DropdownMenuItem(value: 'haute', child: Text('🔴 Haute')),
                  DropdownMenuItem(value: 'moyenne', child: Text('🟠 Moyenne')),
                  DropdownMenuItem(value: 'basse', child: Text('🟢 Basse')),
                ],
                onChanged: (value) => setState(() => _filtrePriorite = value),
              ),
            ),
            const SizedBox(width: 6),
            // Sous-tâches
            Container(
              width: 130,
              height: 42,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade400),
                borderRadius: BorderRadius.circular(8),
              ),
              child: DropdownButton<bool?>(
                value: _filtreSousTaches,
                isExpanded: true,
                underline: const SizedBox(),
                dropdownColor: const Color(0xFF1E1E1E),
                style: const TextStyle(fontSize: 9, color: Colors.white),
                items: const [
                  DropdownMenuItem(
                      value: null, child: Text('📋 Toutes tâches')),
                  DropdownMenuItem(
                      value: true, child: Text('✅ Avec sous-tâches')),
                  DropdownMenuItem(
                      value: false, child: Text('❌ Sans sous-tâche')),
                ],
                onChanged: (value) => setState(() => _filtreSousTaches = value),
              ),
            ),
            const SizedBox(width: 6),
            // Catégorie
            Container(
              width: 130,
              height: 42,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade400),
                borderRadius: BorderRadius.circular(8),
              ),
              child: DropdownButton<String?>(
                value: _filtreLabel,
                isExpanded: true,
                underline: const SizedBox(),
                dropdownColor: const Color(0xFF1E1E1E),
                style: const TextStyle(fontSize: 10, color: Colors.white),
                items: const [
                  DropdownMenuItem(value: null, child: Text('📌 Toutes')),
                  DropdownMenuItem(value: 'Perso', child: Text('👤 Perso')),
                  DropdownMenuItem(value: 'B2B', child: Text('💼 B2B')),
                  DropdownMenuItem(value: 'Cuisine', child: Text('🍳 Cuisine')),
                  DropdownMenuItem(
                      value: 'Administratif', child: Text('Administratif')),
                  DropdownMenuItem(value: 'Loisir', child: Text('Loisir')),
                  DropdownMenuItem(value: 'Autre', child: Text('Autre')),
                ],
                onChanged: (value) => setState(() => _filtreLabel = value),
              ),
            ),
            // Bouton effacer
            if (_filtreEtat != null ||
                _filtreLabel != null ||
                _filtreSousTaches != null ||
                _filtrePriorite != null) ...[
              const SizedBox(width: 6),
              IconButton(
                icon: const Icon(Icons.clear, size: 18),
                tooltip: 'Effacer filtres',
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                onPressed: () {
                  setState(() {
                    _filtreEtat = null;
                    _filtreLabel = null;
                    _filtreSousTaches = null;
                    _filtrePriorite = null;
                  });
                },
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _showPasswordDialog(
      BuildContext context, UserProvider userProvider, String userId) {
    final user = userProvider.getUserById(userId);
    if (user == null || user.prenom == utilisateurActuel) return;

    final passwordController = TextEditingController();
    bool obscurePassword = true;
    String? errorMessage;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text('Connexion - ${user.prenom}'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: passwordController,
                obscureText: obscurePassword,
                decoration: InputDecoration(
                  labelText: 'Mot de passe',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  suffixIcon: IconButton(
                    icon: Icon(
                      obscurePassword ? Icons.visibility_off : Icons.visibility,
                    ),
                    onPressed: () {
                      setState(() => obscurePassword = !obscurePassword);
                    },
                  ),
                ),
              ),
              if (errorMessage != null) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacitySafe(0.2),
                    border: Border.all(color: Colors.red),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    errorMessage!,
                    style: const TextStyle(color: Colors.red, fontSize: 12),
                  ),
                ),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Annuler'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: mintGreen),
              onPressed: () async {
                try {
                  await userProvider.login(user, passwordController.text);
                  if (context.mounted) {
                    Navigator.pop(context);
                    this.setState(() {});
                  }
                } catch (e) {
                  setState(() => errorMessage = 'Mot de passe incorrect');
                }
              },
              child: const Text('Connexion',
                  style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 4,
        actions: [
          // Sélecteur de vue
          const ViewSelector(),
          // Icône Agenda
          IconButton(
            icon: const Icon(Icons.calendar_month),
            tooltip: 'Agenda',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const CalendarScreen()),
              );
            },
          ),
          // Icône Événements du jour
          // (Déplacé dans le menu pour alléger la barre sur PC)
          // Bloc-note rapide
          IconButton(
            icon: const Icon(Icons.note_add),
            tooltip: 'Bloc-note',
            onPressed: _showScratchPadDialog,
          ),
          const WeatherWidget(),
          PopupMenuButton<String>(
            onSelected: (value) async {
              if (value == 'logout') {
                // Déconnecter l'utilisateur et effacer toutes les sessions
                final navigator = Navigator.of(context);
                await context.read<UserProvider>().logout();

                // Déconnecter également Google Calendar si connecté
                try {
                  await GoogleCalendarService().disconnect();
                } catch (e) {
                  debugPrint('Erreur déconnexion Calendar lors du logout: $e');
                }

                if (!mounted) return;
                navigator.pushReplacementNamed('/');
              } else if (value == 'change_password') {
                _showChangePasswordDialog(context);
              } else if (value == 'delete_password') {
                _showDeletePasswordDialog(context);
              } else if (value == 'kanban') {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const KanbanScreen()),
                );
              } else if (value == 'stats') {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const StatsScreen()),
                );
              } else if (value == 'preferences') {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const PreferencesScreen()),
                );
              } else if (value == 'daily_events') {
                _showDailyOutingPopup();
              } else if (value == 'calendar') {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const CalendarScreen()),
                );
              } else if (value == 'change_profile') {
                final userProvider = context.read<UserProvider>();
                showDialog(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('Changer de profil'),
                    content: SingleChildScrollView(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: userProvider.users.map((user) {
                          final isCurrent = user.prenom == utilisateurActuel;
                          return ListTile(
                            leading: isCurrent
                                ? const Icon(Icons.check_circle,
                                    color: mintGreen)
                                : const Icon(Icons.account_circle),
                            title: Text(user.prenom),
                            onTap: () {
                              Navigator.pop(ctx);
                              _showPasswordDialog(
                                  context, userProvider, user.id);
                            },
                          );
                        }).toList(),
                      ),
                    ),
                    actions: [
                      TextButton(
                          onPressed: () => Navigator.pop(ctx),
                          child: const Text('Fermer'))
                    ],
                  ),
                );
              }
            },
            itemBuilder: (context) {
              return [
                const PopupMenuItem(
                  value: 'preferences',
                  child: Row(
                    children: [
                      Icon(Icons.tune, color: Color(0xFF1DB679)),
                      SizedBox(width: 8),
                      Text('Préférences sorties'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'daily_events',
                  child: Row(
                    children: [
                      Icon(Icons.event),
                      SizedBox(width: 8),
                      Text('Événements du jour'),
                    ],
                  ),
                ),
                const PopupMenuDivider(),
                const PopupMenuItem(
                  value: 'change_profile',
                  child: Row(
                    children: [
                      Icon(Icons.account_circle),
                      SizedBox(width: 8),
                      Text('Changer utilisateur'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'change_password',
                  child: Row(
                    children: [
                      Icon(Icons.lock_reset),
                      SizedBox(width: 8),
                      Text('Changer mot de passe'),
                    ],
                  ),
                ),
                const PopupMenuDivider(),
                const PopupMenuItem(
                  value: 'logout',
                  child: Row(
                    children: [
                      Icon(Icons.logout),
                      SizedBox(width: 8),
                      Text('Déconnexion'),
                    ],
                  ),
                ),
              ];
            },
            icon: const Icon(Icons.more_vert),
            tooltip: 'Options',
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: Consumer<UserProvider>(
        builder: (context, userProvider, child) {
          final viewPreference = userProvider.viewPreference;

          return Consumer<TodoProvider>(
            builder: (context, todoProvider, child) {
              // Render appropriate view based on user preference
              switch (viewPreference) {
                case ViewPreference.kanban:
                  return KanbanViewWrapper(utilisateur: utilisateurActuel);
                case ViewPreference.list:
                  return ListViewScreen(utilisateur: utilisateurActuel);
                case ViewPreference.compact:
                  return CompactViewScreen(utilisateur: utilisateurActuel);
                case ViewPreference.timeline:
                  return TimelineViewScreen(utilisateur: utilisateurActuel);
              }
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: mintGreen,
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
                builder: (_) => AddTaskScreen(utilisateur: utilisateurActuel)),
          ).then((value) {
            if (value != null) setState(() {});
          });
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  void _confirmDelete(
      BuildContext context, String id, TodoProvider todoProvider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer ?'),
        content: const Text('Cette action est irréversible.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Annuler')),
          TextButton(
            onPressed: () {
              todoProvider.supprimerTache(id);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Tâche supprimée')),
              );
            },
            child: const Text('Supprimer', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _showChangePasswordDialog(BuildContext context) {
    final oldPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();
    bool obscureOld = true;
    bool obscureNew = true;
    bool obscureConfirm = true;
    String? errorMessage;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Changer le mot de passe'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: oldPasswordController,
                  obscureText: obscureOld,
                  decoration: InputDecoration(
                    labelText: 'Ancien mot de passe',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    suffixIcon: IconButton(
                      icon: Icon(
                        obscureOld ? Icons.visibility_off : Icons.visibility,
                      ),
                      onPressed: () {
                        setState(() => obscureOld = !obscureOld);
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: newPasswordController,
                  obscureText: obscureNew,
                  decoration: InputDecoration(
                    labelText: 'Nouveau mot de passe',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    suffixIcon: IconButton(
                      icon: Icon(
                        obscureNew ? Icons.visibility_off : Icons.visibility,
                      ),
                      onPressed: () {
                        setState(() => obscureNew = !obscureNew);
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: confirmPasswordController,
                  obscureText: obscureConfirm,
                  decoration: InputDecoration(
                    labelText: 'Confirmer nouveau mot de passe',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    suffixIcon: IconButton(
                      icon: Icon(
                        obscureConfirm
                            ? Icons.visibility_off
                            : Icons.visibility,
                      ),
                      onPressed: () {
                        setState(() => obscureConfirm = !obscureConfirm);
                      },
                    ),
                  ),
                ),
                if (errorMessage != null) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacitySafe(0.2),
                      border: Border.all(color: Colors.red),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      errorMessage!,
                      style: const TextStyle(color: Colors.red, fontSize: 12),
                    ),
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Annuler'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: mintGreen),
              onPressed: () async {
                // Validation
                if (oldPasswordController.text.isEmpty ||
                    newPasswordController.text.isEmpty ||
                    confirmPasswordController.text.isEmpty) {
                  setState(() => errorMessage = 'Tous les champs sont requis');
                  return;
                }

                if (newPasswordController.text.length < 4) {
                  setState(() => errorMessage =
                      'Le mot de passe doit contenir au moins 4 caractères');
                  return;
                }

                if (newPasswordController.text !=
                    confirmPasswordController.text) {
                  setState(() =>
                      errorMessage = 'Les mots de passe ne correspondent pas');
                  return;
                }

                try {
                  await context.read<UserProvider>().changePassword(
                        oldPasswordController.text,
                        newPasswordController.text,
                      );
                  if (context.mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Mot de passe modifié avec succès'),
                        backgroundColor: mintGreen,
                      ),
                    );
                  }
                } catch (e) {
                  setState(() => errorMessage =
                      e.toString().replaceAll('Exception: ', ''));
                }
              },
              child:
                  const Text('Modifier', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  void _showDeletePasswordDialog(BuildContext context) {
    final passwordController = TextEditingController();
    bool obscurePassword = true;
    String? errorMessage;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Supprimer le mot de passe'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Votre mot de passe sera réinitialisé à "1234".\nConfirmez avec votre mot de passe actuel.',
                style: TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: passwordController,
                obscureText: obscurePassword,
                decoration: InputDecoration(
                  labelText: 'Mot de passe actuel',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  suffixIcon: IconButton(
                    icon: Icon(
                      obscurePassword ? Icons.visibility_off : Icons.visibility,
                    ),
                    onPressed: () {
                      setState(() => obscurePassword = !obscurePassword);
                    },
                  ),
                ),
              ),
              if (errorMessage != null) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacitySafe(0.2),
                    border: Border.all(color: Colors.red),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    errorMessage!,
                    style: const TextStyle(color: Colors.red, fontSize: 12),
                  ),
                ),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Annuler'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () async {
                if (passwordController.text.isEmpty) {
                  setState(() => errorMessage = 'Mot de passe requis');
                  return;
                }

                try {
                  // Vérifier le mot de passe actuel puis le réinitialiser à "1234"
                  await context.read<UserProvider>().changePassword(
                        passwordController.text,
                        '1234',
                      );
                  if (context.mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Mot de passe réinitialisé à "1234"'),
                        backgroundColor: Colors.orange,
                      ),
                    );
                  }
                } catch (e) {
                  setState(() => errorMessage =
                      e.toString().replaceAll('Exception: ', ''));
                }
              },
              child: const Text('Supprimer',
                  style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  /// Afficher le bloc-note persistant
  Future<void> _showScratchPadDialog() async {
    final prefs = await SharedPreferences.getInstance();
    final noteController = TextEditingController(
      text: prefs.getString('scratch_note') ?? '',
    );

    if (!mounted) return;

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) {
        return Dialog(
          backgroundColor: const Color(0xFF121212),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Bloc-note',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      icon: const Icon(Icons.close, color: Colors.white70),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: noteController,
                  maxLines: 12,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'Écris tes notes ici...',
                    hintStyle: const TextStyle(color: Colors.white54),
                    filled: true,
                    fillColor: Colors.white.withOpacitySafe(0.05),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide:
                          const BorderSide(color: Colors.white30, width: 1),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide:
                          const BorderSide(color: Colors.white30, width: 1),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide:
                          const BorderSide(color: Color(0xFF1DB679), width: 2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Bouton Effacer à gauche
                    TextButton.icon(
                      onPressed: () async {
                        noteController.clear();
                        await prefs.remove('scratch_note');
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Note effacée'),
                              backgroundColor: Colors.red,
                              duration: Duration(seconds: 1),
                            ),
                          );
                        }
                      },
                      icon: const Icon(Icons.delete_outline, color: Colors.red),
                      label: const Text('Effacer',
                          style: TextStyle(color: Colors.red)),
                    ),
                    // Boutons Fermer et Sauvegarder à droite
                    Row(
                      children: [
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(),
                          child: const Text('Fermer',
                              style: TextStyle(color: Colors.white70)),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: () async {
                            final note = noteController.text.trim();
                            try {
                              final ok =
                                  await prefs.setString('scratch_note', note);
                              final saved = prefs.getString('scratch_note');

                              if (ok && saved == note) {
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Note sauvegardée !'),
                                      backgroundColor: Color(0xFF1DB679),
                                      duration: Duration(seconds: 1),
                                    ),
                                  );
                                  Navigator.of(context).pop();
                                }
                              } else {
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                          'Erreur: impossible de sauvegarder la note'),
                                      backgroundColor: Colors.red,
                                      duration: Duration(seconds: 2),
                                    ),
                                  );
                                }

                                // Tentative de fallback sur localStorage (web)
                                if (kIsWeb) {
                                  try {
                                    html.window.localStorage['scratch_note'] =
                                        note;
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        const SnackBar(
                                          content: Text(
                                              'Note sauvegardée (localStorage fallback)'),
                                          backgroundColor: Color(0xFF1DB679),
                                          duration: Duration(seconds: 1),
                                        ),
                                      );
                                      Navigator.of(context).pop();
                                    }
                                  } catch (e) {
                                    debugPrint(
                                        'Fallback localStorage failed: $e');
                                  }
                                }
                              }
                            } catch (e) {
                              debugPrint('Erreur sauvegarde note: $e');
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Erreur: $e'),
                                    backgroundColor: Colors.red,
                                    duration: const Duration(seconds: 2),
                                  ),
                                );
                              }
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF1DB679),
                          ),
                          child: const Text('Sauvegarder',
                              style: TextStyle(color: Colors.white)),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
