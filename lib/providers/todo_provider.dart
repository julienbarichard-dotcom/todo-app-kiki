import 'package:flutter/material.dart';
import 'dart:async';
import '../models/todo_task.dart';
import '../services/supabase_service.dart';
import '../services/google_calendar_service.dart';

/// Provider pour gérer les tâches avec Supabase
class TodoProvider extends ChangeNotifier {
  List<TodoTask> _taches = [];
  Timer? _pollTimer;

  List<TodoTask> get taches => _taches;
  List<TodoTask> get tachesTriees => _taches;

  /// Charger les tâches depuis Supabase
  Future<void> loadTaches() async {
    try {
      final response = await supabaseService.tasksTable.select();
      _taches =
          (response as List).map((json) => TodoTask.fromMap(json)).toList();

      // Reporter automatiquement les tâches passées
      await _reportOverdueTasks();

      _triageParUrgenceDate();
      notifyListeners();

      // Synchroniser avec Calendar si connecté
      await syncWithCalendar();
    } catch (e) {
      debugPrint('Erreur chargement tâches: $e');
    }
  }

  /// Reporter automatiquement les tâches dont la date est passée
  /// Les tâches non accomplies avec date AVANT aujourd'hui sont reportées à AUJOURD'HUI
  /// avec le triangle 🔺. Si l'heure existe, elle est conservée.
  Future<void> _reportOverdueTasks() async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    int reportCount = 0;
    for (var tache in _taches) {
      if (tache.dateEcheance != null && !tache.estComplete) {
        // Comparer uniquement les DATES (sans l'heure)
        final echeanceDate = DateTime(
          tache.dateEcheance!.year,
          tache.dateEcheance!.month,
          tache.dateEcheance!.day,
        );

        // SEULEMENT si la date est STRICTEMENT AVANT aujourd'hui
        if (echeanceDate.isBefore(today)) {
          reportCount++;

          // Conserver l'heure si elle existe (pas 00:00:00)
          DateTime newDate;
          if (tache.dateEcheance!.hour != 0 ||
              tache.dateEcheance!.minute != 0 ||
              tache.dateEcheance!.second != 0) {
            // Il y a une heure : reporter avec la même heure
            newDate = DateTime(
              today.year,
              today.month,
              today.day,
              tache.dateEcheance!.hour,
              tache.dateEcheance!.minute,
              tache.dateEcheance!.second,
            );
          } else {
            // Pas d'heure : juste la date
            newDate = today;
          }

          final updatedTask = tache.copyWith(
            dateEcheance: newDate,
            isReported: true, // 🔺 Triangle visible car reportée
          );

          try {
            await supabaseService.tasksTable
                .update(updatedTask.toMap())
                .eq('id', tache.id);

            // Mettre à jour localement
            final index = _taches.indexWhere((t) => t.id == tache.id);
            if (index != -1) {
              _taches[index] = updatedTask;
            }

            // 📅 Synchroniser avec Google Calendar : mettre à jour la date de l'événement
            if (googleCalendarService.isAuthenticated) {
              try {
                await googleCalendarService.updateEventFromTask(updatedTask);
              } catch (e) {
                debugPrint('⚠️ Erreur sync Calendar pour "${tache.titre}": $e');
              }
            }
          } catch (e) {
            debugPrint('❌ Erreur report tâche ${tache.id}: $e');
          }
        }
      }
    }

    if (reportCount > 0) {
      debugPrint('✅ $reportCount tâche(s) reportée(s) automatiquement');
    }
  }

  /// Forcer le report des tâches en retard (pour test manuel)
  Future<void> forceReportOverdueTasks() async {
    await _reportOverdueTasks();
    notifyListeners();
  }

  /// Synchroniser les tâches avec Google Calendar (bidirectionnel)
  Future<void> syncWithCalendar() async {
    if (!googleCalendarService.isAuthenticated) return;

    try {
      // Récupérer les taskIds présents dans Calendar
      final calendarTaskIds =
          await googleCalendarService.getAllCalendarTaskIds();

      // Trouver les tâches locales qui ont un événement Calendar supprimé
      final tasksToClean = <TodoTask>[];
      for (var tache in _taches) {
        if (tache.dateEcheance != null && !calendarTaskIds.contains(tache.id)) {
          // L'événement Calendar a été supprimé manuellement
          tasksToClean.add(tache);
        }
      }

      // Option 1: Supprimer ces tâches (sync strict)
      // for (var tache in tasksToClean) {
      //   await supprimerTache(tache.id);
      // }

      // Option 2: Juste retirer la date (sync doux - préféré)
      for (var tache in tasksToClean) {
        final updated = tache.copyWith(dateEcheance: null);
        await modifierTache(updated);
        debugPrint(
            '🔄 Sync: Date retirée pour "${tache.titre}" (événement Calendar supprimé)');
      }

      if (tasksToClean.isNotEmpty) {
        debugPrint(
            '✅ Synchronisation bidirectionnelle: ${tasksToClean.length} tâche(s) mise(s) à jour');
      }
    } catch (e) {
      debugPrint('Erreur synchronisation Calendar: $e');
    }
  }

  /// Fonction simplifiée pour compatibilité
  /// 
  /// Polling interval optimization:
  /// - Changed from 30s to 120s (2 minutes) to reduce server load
  /// - Trade-offs:
  ///   * Pro: 75% reduction in API calls (120/hour → 30/hour)
  ///   * Pro: Lower battery consumption and network usage
  ///   * Pro: Reduced risk of rate limiting
  ///   * Con: Task updates may take up to 2 minutes to appear
  /// - Rationale: Most task updates are user-initiated and trigger immediate
  ///   refreshes. Background polling is primarily for multi-device sync, which
  ///   doesn't require sub-minute precision.
  void subscribeToTaskUpdates() {
    if (_pollTimer != null) return;
    _pollTimer = Timer.periodic(const Duration(seconds: 120), (t) async {
      try {
        await loadTaches();
      } catch (e) {
        debugPrint('Erreur polling loadTaches: $e');
      }
    });
  }

  @override
  void dispose() {
    try {
      if (_pollTimer != null) {
        _pollTimer!.cancel();
        _pollTimer = null;
      }
    } catch (e) {
      debugPrint('Erreur lors de la désinscription realtime: $e');
    }
    super.dispose();
  }

  /// Ajouter une tâche
  Future<void> ajouterTache(TodoTask tache) async {
    try {
      await supabaseService.tasksTable.insert(tache.toMap());
      _taches.add(tache);
      _triageParUrgenceDate();
      notifyListeners();

      // Synchroniser avec Google Calendar si la tâche a une date
      if (tache.dateEcheance != null) {
        await googleCalendarService.createEventFromTask(tache);
      }
    } catch (e) {
      debugPrint('Erreur ajout tâche: $e');
    }
  }

  /// Supprimer une tâche
  Future<void> supprimerTache(String id) async {
    try {
      await supabaseService.tasksTable.delete().eq('id', id);
      _taches.removeWhere((t) => t.id == id);
      notifyListeners();

      // Supprimer de Google Calendar
      await googleCalendarService.deleteEventFromTask(id);
    } catch (e) {
      debugPrint('Erreur suppression tâche: $e');
    }
  }

  /// Modifier une tâche
  Future<void> modifierTache(TodoTask tache) async {
    try {
      await supabaseService.tasksTable.update(tache.toMap()).eq('id', tache.id);

      final index = _taches.indexWhere((t) => t.id == tache.id);
      if (index != -1) {
        // Récupérer l'ancienne tâche pour comparer l'état de complétion
        final oldTache = _taches[index];

        _taches[index] = tache;

        // Si la tâche vient d'être marquée comme terminée, supprimer l'événement Calendar
        if (!oldTache.estComplete && tache.estComplete) {
          debugPrint(
              'Tâche "${tache.titre}" marquée terminée - suppression événement Calendar');
          await googleCalendarService.deleteEventFromTask(tache.id);
        }
        // Si la tâche est réouverte (estComplete false) et a une date, recréer l'événement
        else if (oldTache.estComplete &&
            !tache.estComplete &&
            tache.dateEcheance != null) {
          debugPrint(
              'Tâche "${tache.titre}" réouverte - recréation événement Calendar');
          await googleCalendarService.updateEventFromTask(tache);
        }
        // Sinon mise à jour normale
        else {
          await googleCalendarService.updateEventFromTask(tache);
        }
      }
      _triageParUrgenceDate();
      notifyListeners();
    } catch (e) {
      debugPrint('Erreur modification tâche: $e');
    }
  }

  /// Basculer complétude d'une tâche
  Future<void> toggleTacheComplete(String id) async {
    try {
      final tache = _taches.firstWhere((t) => t.id == id);
      final updated = tache.copyWith(estComplete: !tache.estComplete);
      await modifierTache(updated);
    } catch (e) {
      debugPrint('Erreur toggle tâche: $e');
    }
  }

  /// Obtenir les tâches assignées à une personne
  List<TodoTask> getTachesPourPersonne(String prenom) {
    return _taches.where((t) => t.assignedTo.contains(prenom)).toList();
  }

  /// Obtenir les tâches urgentes
  List<TodoTask> getTachesUrgentes() {
    return _taches
        .where((t) => t.urgence == Urgence.haute && !t.estComplete)
        .toList();
  }

  /// Obtenir les tâches complètes
  List<TodoTask> getTachesCompletes() {
    return _taches.where((t) => t.estComplete).toList();
  }

  /// Obtenir les tâches à faire
  List<TodoTask> getTachesEnAttente() {
    return _taches.where((t) => !t.estComplete).toList();
  }

  /// Nombre de tâches pour aujourd'hui pour une personne
  int countTasksTodayFor(String prenom) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return _taches.where((t) {
      if (!t.assignedTo.contains(prenom)) return false;
      if (t.dateEcheance == null) return false;
      final d = DateTime(
          t.dateEcheance!.year, t.dateEcheance!.month, t.dateEcheance!.day);
      return d == today && !t.estComplete;
    }).length;
  }

  /// Nombre de tâches pour aujourd'hui (tous utilisateurs)
  int countTasksTodayAll() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return _taches.where((t) {
      if (t.dateEcheance == null) return false;
      final d = DateTime(
          t.dateEcheance!.year, t.dateEcheance!.month, t.dateEcheance!.day);
      return d == today && !t.estComplete;
    }).length;
  }

  /// Nombre de tâches reportées (isReported true) (tous utilisateurs)
  int countReportedAll() {
    return _taches.where((t) => t.isReported).length;
  }

  /// Nombre de tâches dans la colonne 'A faire' (tous utilisateurs)
  int countEnAttenteAll() {
    return _taches
        .where((t) => !t.estComplete && t.statut == Statut.enAttente)
        .length;
  }

  /// Nombre de tâches dans la colonne 'En cours' (tous utilisateurs)
  int countEnCoursAll() {
    return _taches
        .where((t) => !t.estComplete && t.statut == Statut.enCours)
        .length;
  }

  /// Nombre de tâches dans la colonne 'Terminé' (tous utilisateurs)
  int countTermineAll() {
    return _taches
        .where((t) => t.estComplete || t.statut == Statut.termine)
        .length;
  }

  /// Nombre de tâches en retard pour une personne
  int countOverdueFor(String prenom) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return _taches.where((t) {
      if (!t.assignedTo.contains(prenom)) return false;
      if (t.dateEcheance == null) return false;
      final d = DateTime(
          t.dateEcheance!.year, t.dateEcheance!.month, t.dateEcheance!.day);
      return d.isBefore(today) && !t.estComplete;
    }).length;
  }

  /// Pourcentage de tâches complétées pour une personne (0.0 - 100.0)
  double completionPercentFor(String prenom) {
    final userTasks =
        _taches.where((t) => t.assignedTo.contains(prenom)).toList();
    if (userTasks.isEmpty) return 0.0;
    final completed = userTasks.where((t) => t.estComplete).length;
    return (completed / userTasks.length) * 100.0;
  }

  /// Trier par urgence + date
  void _triageParUrgenceDate() {
    _taches.sort((a, b) {
      final urgenceOrder = {'haute': 0, 'moyenne': 1, 'basse': 2};
      final aOrder = urgenceOrder[a.urgence.label] ?? 2;
      final bOrder = urgenceOrder[b.urgence.label] ?? 2;
      if (aOrder != bOrder) return aOrder.compareTo(bOrder);
      return (b.dateEcheance ?? DateTime(9999))
          .compareTo(a.dateEcheance ?? DateTime(9999));
    });
  }
}
