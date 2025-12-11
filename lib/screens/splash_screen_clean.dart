import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:todo_app_kiki/providers/todo_provider.dart';
import 'package:todo_app_kiki/providers/outings_provider.dart';
import 'package:todo_app_kiki/models/outing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:todo_app_kiki/widgets/weather_widget.dart';
import 'package:url_launcher/url_launcher.dart';

// Minimal, safe SplashScreen implementation with green gradient background.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  bool _showButton = false;
  bool _isLoadingStats = true;
  bool _statsReady = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _scaleAnimation = Tween<double>(begin: 0.9, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutBack),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeIn),
    );
    // start a small animation and request provider subscription after first frame
    _controller.forward();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final todoProv = Provider.of<TodoProvider>(context, listen: false);
      _warmupData(todoProv);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  double _safePct(int count, int denom) {
    if (denom <= 0) return 0.0;
    final v = count / denom;
    if (v.isNaN || v.isInfinite) return 0.0;
    return v.clamp(0.0, 1.0);
  }

  Future<void> _warmupData(TodoProvider todoProv) async {
    var finished = false;

    void markReady() {
      if (!mounted || _statsReady) return;
      setState(() {
        _isLoadingStats = false;
        _statsReady = true;
        _showButton = true;
      });
    }

    // Fallback: si le réseau est lent, on affiche quand même après 600ms
    Timer(const Duration(milliseconds: 600), () {
      if (!finished) {
        markReady();
      }
    });

    try {
      await todoProv.loadTaches();
    } catch (_) {}

    try {
      todoProv.subscribeToTaskUpdates();
    } catch (_) {}

    finished = true;
    markReady();
  }

  Widget _statCircle(double circleSize, String label, int count,
      double progress, Color color) {
    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 520),
      curve: Curves.easeOutCubic,
      tween: Tween<double>(begin: 0, end: _statsReady ? 1.0 : 0.0),
      builder: (context, value, child) {
        final displayCount = (count * value).round();
        final displayProgress = (progress * value).clamp(0.0, 1.0);

        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: circleSize,
              height: circleSize,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: circleSize,
                    height: circleSize,
                    child: CircularProgressIndicator(
                      value: displayProgress,
                      strokeWidth: circleSize * 0.12,
                      backgroundColor: Colors.white10,
                      valueColor: AlwaysStoppedAnimation<Color>(color),
                    ),
                  ),
                  Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '$displayCount',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: circleSize * 0.28,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${(displayProgress * 100).round()}%',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: circleSize * 0.14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 6),
            SizedBox(
              width: circleSize + 10,
              child: Text(
                label,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white70, fontSize: 12),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final todoProv = Provider.of<TodoProvider>(context);

    final todayCount = todoProv.countTasksTodayAll();
    final overdueCount = todoProv.countReportedAll();
    final enAttente = todoProv.countEnAttenteAll();
    final enCours = todoProv.countEnCoursAll();
    final termine = todoProv.countTermineAll();

    final kanbanTotal = enAttente + enCours + termine;
    final totalTasks = todoProv.taches.length;

    final mq = MediaQuery.of(context);
    final isNarrow = mq.size.width < 480;
    final circleSize = isNarrow ? 64.0 : 84.0;

    final widgets = [
      _statCircle(circleSize, 'A faire', enAttente,
          _safePct(enAttente, kanbanTotal), Colors.white),
      _statCircle(circleSize, 'En cours', enCours,
          _safePct(enCours, kanbanTotal), Colors.blueAccent),
      _statCircle(circleSize, 'Terminé', termine,
          _safePct(termine, kanbanTotal), Colors.greenAccent),
      _statCircle(circleSize, "Aujourd'hui", todayCount,
          _safePct(todayCount, totalTasks), Colors.tealAccent),
      _statCircle(circleSize, 'Reporté', overdueCount,
          _safePct(overdueCount, totalTasks), Colors.orangeAccent),
    ];

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF0D9F6D), // Vert vif clair
              Color(0xFF0B5D47), // Vert foncé
            ],
          ),
        ),
        child: SafeArea(
          child: Stack(
            children: [
              // Weather widget in top right
              const Positioned(
                top: 8,
                right: 8,
                child: WeatherWidget(),
              ),
              // Main content
              AnimatedOpacity(
                opacity: _statsReady ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 280),
                curve: Curves.easeOutCubic,
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.max,
                    children: [
                      const SizedBox(height: 28),
                      // Animated logo
                      AnimatedBuilder(
                        animation: _controller,
                        builder: (context, child) {
                          return Transform.scale(
                            scale: _scaleAnimation.value,
                            child: Opacity(
                              opacity: _fadeAnimation.value,
                              child: SizedBox(
                                height: 160,
                                child: Image.asset(
                                  'assets/images/logo todo.png',
                                  fit: BoxFit.contain,
                                  errorBuilder: (_, __, ___) =>
                                      const SizedBox.shrink(),
                                ),
                              ),
                            ),
                          );
                        },
                      ),

                      const SizedBox(height: 20),

                      // The five stat circles
                      Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        child: LayoutBuilder(builder: (context, constraints) {
                          final available = constraints.maxWidth;
                          // If not enough width, use Wrap
                          if (available < circleSize * 5 + 40) {
                            return Wrap(
                              alignment: WrapAlignment.center,
                              spacing: 12,
                              runSpacing: 12,
                              children: widgets,
                            );
                          }
                          return Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: widgets
                                .map((w) => Flexible(child: Center(child: w)))
                                .toList(),
                          );
                        }),
                      ),

                      // Stats total et terminé
                      Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.1),
                              width: 1,
                            ),
                          ),
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceAround,
                                children: [
                                  Column(
                                    children: [
                                      TweenAnimationBuilder<double>(
                                        duration:
                                            const Duration(milliseconds: 500),
                                        curve: Curves.easeOutCubic,
                                        tween: Tween<double>(
                                          begin: 0,
                                          end: _statsReady
                                              ? totalTasks.toDouble()
                                              : 0,
                                        ),
                                        builder: (context, value, _) {
                                          return Text(
                                            '${value.round()}',
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 20,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          );
                                        },
                                      ),
                                      const Text(
                                        'Tâches totales',
                                        style: TextStyle(
                                          color: Colors.white70,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                  Container(
                                    width: 1,
                                    height: 40,
                                    color: Colors.white.withValues(alpha: 0.2),
                                  ),
                                  Column(
                                    children: [
                                      TweenAnimationBuilder<double>(
                                        duration:
                                            const Duration(milliseconds: 500),
                                        curve: Curves.easeOutCubic,
                                        tween: Tween<double>(
                                          begin: 0,
                                          end: _statsReady
                                              ? termine.toDouble()
                                              : 0,
                                        ),
                                        builder: (context, value, _) {
                                          return Text(
                                            '${value.round()}',
                                            style: const TextStyle(
                                              color: Color(0xFF4CAF50),
                                              fontSize: 20,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          );
                                        },
                                      ),
                                      const Text(
                                        'Terminées',
                                        style: TextStyle(
                                          color: Colors.white70,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              // Barre de progression avec pourcentage
                              Column(
                                children: [
                                  TweenAnimationBuilder<double>(
                                    duration: const Duration(milliseconds: 520),
                                    curve: Curves.easeOutCubic,
                                    tween: Tween<double>(
                                      begin: 0,
                                      end: _statsReady && totalTasks > 0
                                          ? (termine / totalTasks) * 100
                                          : 0,
                                    ),
                                    builder: (context, value, _) {
                                      return Text(
                                        '${value.toStringAsFixed(0)}% complété',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 14,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      );
                                    },
                                  ),
                                  const SizedBox(height: 6),
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: TweenAnimationBuilder<double>(
                                      duration:
                                          const Duration(milliseconds: 520),
                                      curve: Curves.easeOutCubic,
                                      tween: Tween<double>(
                                        begin: 0,
                                        end: _statsReady && totalTasks > 0
                                            ? termine / totalTasks
                                            : 0,
                                      ),
                                      builder: (context, value, _) {
                                        return LinearProgressIndicator(
                                          value: value.clamp(0.0, 1.0),
                                          minHeight: 8,
                                          backgroundColor: Colors.white
                                              .withValues(alpha: 0.1),
                                          valueColor:
                                              const AlwaysStoppedAnimation<
                                                  Color>(
                                            Color(0xFF4CAF50),
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),

                      const Spacer(),
                      AnimatedOpacity(
                        opacity: _showButton ? 1.0 : 0.0,
                        duration: const Duration(milliseconds: 600),
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: 36.0),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              OutlinedButton.icon(
                                onPressed: _showEventsPopup,
                                icon: const Icon(Icons.event,
                                    color: Colors.white),
                                label: const Text('Événements du jour',
                                    style: TextStyle(color: Colors.white)),
                                style: OutlinedButton.styleFrom(
                                  side: const BorderSide(
                                      color: Colors.white, width: 2),
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 28, vertical: 12),
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(30)),
                                ),
                              ),
                              const SizedBox(height: 12),
                              OutlinedButton.icon(
                                onPressed: _showScratchPadDialog,
                                icon: const Icon(Icons.note_add,
                                    color: Colors.white),
                                label: const Text('Bloc-note',
                                    style: TextStyle(color: Colors.white)),
                                style: OutlinedButton.styleFrom(
                                  side: const BorderSide(
                                      color: Colors.white, width: 2),
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 28, vertical: 12),
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(30)),
                                ),
                              ),
                              const SizedBox(height: 12),
                              OutlinedButton(
                                onPressed: () => Navigator.of(context)
                                    .pushReplacementNamed('/login'),
                                style: OutlinedButton.styleFrom(
                                  side: const BorderSide(
                                      color: Colors.white, width: 2),
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 48, vertical: 14),
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(30)),
                                ),
                                child: const Text('Entrer',
                                    style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold)),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (_isLoadingStats)
                Positioned.fill(
                  child: Container(
                    color: Colors.black26,
                    child: const Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(
                          Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showEventsPopup() async {
    try {
      final outingsProv = Provider.of<OutingsProvider>(context, listen: false);

      // Récupérer 5 événements filtrés selon les préférences
      final filteredEvents =
          await outingsProv.getFilteredOutings(userId: 'kiki');

      if (!mounted) return;

      if (filteredEvents.isEmpty) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            backgroundColor: const Color(0xFF121212),
            title: const Text('Événements du jour',
                style: TextStyle(color: Colors.white)),
            content: const Text('Aucun événement trouvé pour aujourd\'hui.',
                style: TextStyle(color: Colors.white70)),
            actions: [
              TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Fermer',
                      style: TextStyle(color: Color(0xFF1DB679)))),
            ],
          ),
        );
        return;
      }

      // PageView pour carousel horizontal
      int currentIndex = 0;
      final pageController = PageController();

      showDialog(
        context: context,
        builder: (context) {
          return Dialog(
            backgroundColor: const Color(0xFF121212),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // En-tête
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Événements recommandés',
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold)),
                        IconButton(
                          icon: const Icon(Icons.close, color: Colors.white70),
                          onPressed: () => Navigator.of(context).pop(),
                        )
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Carousel PageView
                    SizedBox(
                      height: 320,
                      child: StatefulBuilder(builder: (ctx, setState) {
                        return Column(
                          children: [
                            Expanded(
                              child: PageView.builder(
                                controller: pageController,
                                onPageChanged: (index) {
                                  setState(() {
                                    currentIndex = index;
                                  });
                                },
                                itemCount: filteredEvents.length,
                                itemBuilder: (context, index) {
                                  final event = filteredEvents[index];
                                  return _buildEventCard(event);
                                },
                              ),
                            ),
                            const SizedBox(height: 12),

                            // Indicateurs de page (dots)
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: List.generate(
                                filteredEvents.length,
                                (index) => Container(
                                  margin:
                                      const EdgeInsets.symmetric(horizontal: 4),
                                  width: currentIndex == index ? 12 : 8,
                                  height: 8,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: currentIndex == index
                                        ? const Color(0xFF1DB679)
                                        : Colors.white30,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        );
                      }),
                    ),

                    const SizedBox(height: 16),

                    // Boutons d'action
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        Flexible(
                          child: ElevatedButton.icon(
                            onPressed: () => pageController.previousPage(
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeInOut,
                            ),
                            icon: const Icon(Icons.arrow_back_ios,
                                size: 16, color: Colors.white),
                            label: const Text('Préc.',
                                style: TextStyle(
                                    color: Colors.white, fontSize: 13)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white12,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 10),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Flexible(
                          child: ElevatedButton.icon(
                            onPressed: () {
                              final event = filteredEvents[currentIndex];
                              Navigator.of(context).pop();
                              _launchEventUrl(event.url);
                            },
                            icon: const Icon(Icons.open_in_browser,
                                size: 16, color: Colors.white),
                            label: const Text('Ouvrir',
                                style: TextStyle(
                                    color: Colors.white, fontSize: 13)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF1DB679),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 10),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Flexible(
                          child: ElevatedButton.icon(
                            onPressed: () => pageController.nextPage(
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeInOut,
                            ),
                            icon: const Icon(Icons.arrow_forward_ios,
                                size: 16, color: Colors.white),
                            label: const Text('Suiv.',
                                style: TextStyle(
                                    color: Colors.white, fontSize: 13)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white12,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 10),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      );
    } catch (e) {
      debugPrint('Erreur chargement événements: $e');
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

  /// Construire une carte d'événement pour le carousel
  Widget _buildEventCard(Outing event) {
    return Card(
      color: Colors.white.withValues(alpha: 0.08),
      margin: const EdgeInsets.symmetric(horizontal: 8),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Titre
            Text(
              event.title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),

            // Date et heure
            Row(
              children: [
                const Icon(Icons.calendar_today,
                    size: 14, color: Colors.white70),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    '${event.date.day}/${event.date.month}/${event.date.year} à ${event.date.hour}:${event.date.minute.toString().padLeft(2, '0')}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 11,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),

            // Lieu
            Row(
              children: [
                const Icon(Icons.location_on, size: 14, color: Colors.white70),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    event.location,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 11,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Catégories
            if (event.categories.isNotEmpty)
              Wrap(
                spacing: 4,
                children: event.categories.take(2).map((cat) {
                  return Chip(
                    label: Text(
                      cat,
                      style: const TextStyle(fontSize: 9),
                    ),
                    backgroundColor:
                        const Color(0xFF1DB679).withValues(alpha: 0.3),
                    labelStyle: const TextStyle(
                      color: Color(0xFF1DB679),
                      fontSize: 9,
                    ),
                    padding: EdgeInsets.zero,
                  );
                }).toList(),
              ),
            const SizedBox(height: 6),

            // Description
            if (event.description != null && event.description!.isNotEmpty)
              Text(
                event.description!,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white60,
                  fontSize: 10,
                ),
              ),

            const SizedBox(height: 6),

            // Source
            Text(
              'Source: ${event.source}',
              style: const TextStyle(
                color: Colors.white38,
                fontSize: 9,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Lancer l'URL d'un événement
  Future<void> _launchEventUrl(String? url) async {
    if (url == null || url.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('URL non disponible pour cet événement'),
            backgroundColor: Colors.orange,
          ),
        );
      }
      return;
    }

    try {
      // Utiliser launch_url si disponible, sinon afficher l'URL
      if (await canLaunchUrl(Uri.parse(url))) {
        await launchUrl(
          Uri.parse(url),
          mode: LaunchMode.externalApplication,
        );
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Impossible d\'ouvrir: $url'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('Erreur ouverture URL: $e');
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
                    fillColor: Colors.white.withValues(alpha: 0.05),
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
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF1DB679),
                          ),
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
                              }
                            } catch (e) {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Erreur: $e'),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                              }
                            }
                          },
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
