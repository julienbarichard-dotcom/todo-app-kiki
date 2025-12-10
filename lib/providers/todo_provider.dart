import 'package:flutter/material.dart';
import 'dart:async';
import '../models/todo_task.dart';
import '../services/supabase_service.dart';
import '../services/google_calendar_service.dart';

/// Provider pour gérer les tâches avec Supabase
class TodoProvider extends ChangeNotifier {
  List<TodoTask> _tasks = [];
  Timer? _pollTimer;

  List<TodoTask> get tasks => _tasks;
  List<TodoTask> get sortedTasks => _tasks;

  /// Charger les tâches depuis Supabase
  Future<void> loadTasks() async {
    try {
      debugPrint('🔄 LOAD TASKS: Loading started...');
      final response = await supabaseService.tasksTable.select();
      _tasks =
          (response as List).map((json) => TodoTask.fromMap(json)).toList();
      debugPrint(
          '🔄 LOAD TASKS: ${_tasks.length} tasks loaded from Supabase');

      // Reporter automatiquement les tâches passées
      debugPrint('🔄 LOAD TASKS: Starting automatic overdue task reporting...');
      await _reportOverdueTasks();
      debugPrint('🔄 LOAD TASKS: Automatic reporting completed');

      _sortTasksByUrgencyAndDate();
      notifyListeners();

      // Synchroniser avec Calendar si connecté
      await syncWithCalendar();
    } catch (e) {
      debugPrint('Error loading tasks: $e');
    }
  }

  /// Reporter automatiquement les tâches dont la date est passée
  /// Les tâches non accomplies avec date AVANT aujourd'hui sont reportées à AUJOURD'HUI
  /// avec le triangle 🔺. Si l'heure existe, elle est conservée.
  Future<void> _reportOverdueTasks() async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    debugPrint(
        '🔍 REPORT AUTO: Checking for overdue tasks (today = $today)');
    debugPrint('🔍 REPORT AUTO: Total tasks: ${_tasks.length}');

    int reportCount = 0;
    for (var task in _tasks) {
      if (task.dateEcheance != null && !task.estComplete) {
        // Comparer uniquement les DATES (sans l'heure)
        final echeanceDate = DateTime(
          task.dateEcheance!.year,
          task.dateEcheance!.month,
          task.dateEcheance!.day,
        );

        debugPrint(
            '🔍 Task "${task.titre}": due=$echeanceDate, complete=${task.estComplete}, isReported=${task.isReported}');

        // SEULEMENT si la date est STRICTEMENT AVANT aujourd'hui
        if (echeanceDate.isBefore(today)) {
          reportCount++;

          // Conserver l'heure si elle existe (pas 00:00:00)
          DateTime newDate;
          if (task.dateEcheance!.hour != 0 ||
              task.dateEcheance!.minute != 0 ||
              task.dateEcheance!.second != 0) {
            // Il y a une heure : reporter avec la même heure
            newDate = DateTime(
              today.year,
              today.month,
              today.day,
              task.dateEcheance!.hour,
              task.dateEcheance!.minute,
              task.dateEcheance!.second,
            );
            debugPrint(
                '⏰ Task "${task.titre}" rescheduled with time: ${task.dateEcheance!.hour}:${task.dateEcheance!.minute}');
          } else {
            // Pas d'heure : juste la date
            newDate = today;
          }

          final updatedTask = task.copyWith(
            dateEcheance: newDate,
            isReported: true, // 🔺 Triangle visible car reportée
          );

          try {
            await supabaseService.tasksTable
                .update(updatedTask.toMap())
                .eq('id', task.id);

            // Mettre à jour localement
            final index = _tasks.indexWhere((t) => t.id == task.id);
            if (index != -1) {
              _tasks[index] = updatedTask;
            }

            // 📅 Synchroniser avec Google Calendar : mettre à jour la date de l'événement
            if (googleCalendarService.isAuthenticated) {
              try {
                await googleCalendarService.updateEventFromTask(updatedTask);
                debugPrint(
                    '📅 Google Calendar updated for "${task.titre}"');
              } catch (e) {
                debugPrint('⚠️ Calendar sync error for "${task.titre}": $e');
              }
            }

            debugPrint(
                '✅ Task "${task.titre}" rescheduled from $echeanceDate to $newDate (🔺 triangle active)');
          } catch (e) {
            debugPrint('❌ Error rescheduling task ${task.id}: $e');
          }
        } else if (echeanceDate.isAtSameMomentAs(today)) {
          // La tâche est déjà à aujourd'hui : PAS de report, PAS de triangle
          debugPrint(
              '📅 Task "${task.titre}" already today (no rescheduling)');
        }
      }
    }

    debugPrint('🔍 REPORT AUTO: Total rescheduled: $reportCount tasks');
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
      for (var task in _tasks) {
        if (task.dateEcheance != null && !calendarTaskIds.contains(task.id)) {
          // L'événement Calendar a été supprimé manuellement
          tasksToClean.add(task);
        }
      }

      // Option 1: Supprimer ces tâches (sync strict)
      // for (var task in tasksToClean) {
      //   await deleteTask(task.id);
      // }

      // Option 2: Juste retirer la date (sync doux - préféré)
      for (var task in tasksToClean) {
        final updated = task.copyWith(dateEcheance: null);
        await updateTask(updated);
        debugPrint(
            '🔄 Sync: Date removed for "${task.titre}" (Calendar event deleted)');
      }

      if (tasksToClean.isNotEmpty) {
        debugPrint(
            '✅ Bidirectional sync: ${tasksToClean.length} task(s) updated');
      }
    } catch (e) {
      debugPrint('Erreur synchronisation Calendar: $e');
    }
  }

  /// Fonction simplifiée pour compatibilité
  void subscribeToTaskUpdates() {
    // Polling fallback: refresh tâches toutes les 8 secondes.
    if (_pollTimer != null) return;
    // Réduire la fréquence de polling pour éviter des appels répétés
    // lors du développement / en cas de réseau lent.
    debugPrint('Subscription polling enabled (refresh every 30s)');
    _pollTimer = Timer.periodic(const Duration(seconds: 30), (t) async {
      try {
        await loadTasks();
      } catch (e) {
        debugPrint('Error polling loadTasks: $e');
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
      debugPrint('Error disposing realtime subscription: $e');
    }
    super.dispose();
  }

  /// Ajouter une tâche
  Future<void> addTask(TodoTask task) async {
    try {
      await supabaseService.tasksTable.insert(task.toMap());
      _tasks.add(task);
      _sortTasksByUrgencyAndDate();
      notifyListeners();

      // Synchroniser avec Google Calendar si la tâche a une date
      if (task.dateEcheance != null) {
        await googleCalendarService.createEventFromTask(task);
      }
    } catch (e) {
      debugPrint('Error adding task: $e');
    }
  }

  /// Supprimer une tâche
  Future<void> deleteTask(String id) async {
    try {
      await supabaseService.tasksTable.delete().eq('id', id);
      _tasks.removeWhere((t) => t.id == id);
      notifyListeners();

      // Supprimer de Google Calendar
      await googleCalendarService.deleteEventFromTask(id);
    } catch (e) {
      debugPrint('Error deleting task: $e');
    }
  }

  /// Modifier une tâche
  Future<void> updateTask(TodoTask task) async {
    try {
      await supabaseService.tasksTable.update(task.toMap()).eq('id', task.id);

      final index = _tasks.indexWhere((t) => t.id == task.id);
      if (index != -1) {
        // Récupérer l'ancienne tâche pour comparer l'état de complétion
        final oldTask = _tasks[index];

        _tasks[index] = task;

        // Si la tâche vient d'être marquée comme terminée, supprimer l'événement Calendar
        if (!oldTask.estComplete && task.estComplete) {
          debugPrint(
              'Task "${task.titre}" marked complete - deleting Calendar event');
          await googleCalendarService.deleteEventFromTask(task.id);
        }
        // Si la tâche est réouverte (estComplete false) et a une date, recréer l'événement
        else if (oldTask.estComplete &&
            !task.estComplete &&
            task.dateEcheance != null) {
          debugPrint(
              'Task "${task.titre}" reopened - recreating Calendar event');
          await googleCalendarService.updateEventFromTask(task);
        }
        // Sinon mise à jour normale
        else {
          await googleCalendarService.updateEventFromTask(task);
        }
      }
      _sortTasksByUrgencyAndDate();
      notifyListeners();
    } catch (e) {
      debugPrint('Error updating task: $e');
    }
  }

  /// Basculer complétude d'une tâche
  Future<void> toggleTaskComplete(String id) async {
    try {
      final task = _tasks.firstWhere((t) => t.id == id);
      final updated = task.copyWith(estComplete: !task.estComplete);
      await updateTask(updated);
    } catch (e) {
      debugPrint('Error toggling task: $e');
    }
  }

  /// Obtenir les tâches assignées à une personne
  List<TodoTask> getTasksForPerson(String prenom) {
    return _tasks.where((t) => t.assignedTo.contains(prenom)).toList();
  }

  /// Obtenir les tâches urgentes
  List<TodoTask> getUrgentTasks() {
    return _tasks
        .where((t) => t.urgence == Urgence.haute && !t.estComplete)
        .toList();
  }

  /// Obtenir les tâches complètes
  List<TodoTask> getCompletedTasks() {
    return _tasks.where((t) => t.estComplete).toList();
  }

  /// Obtenir les tâches à faire
  List<TodoTask> getPendingTasks() {
    return _tasks.where((t) => !t.estComplete).toList();
  }

  /// Nombre de tâches pour aujourd'hui pour une personne
  int countTasksTodayFor(String prenom) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return _tasks.where((t) {
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
    return _tasks.where((t) {
      if (t.dateEcheance == null) return false;
      final d = DateTime(
          t.dateEcheance!.year, t.dateEcheance!.month, t.dateEcheance!.day);
      return d == today && !t.estComplete;
    }).length;
  }

  /// Nombre de tâches reportées (isReported true) (tous utilisateurs)
  int countReportedAll() {
    return _tasks.where((t) => t.isReported).length;
  }

  /// Nombre de tâches dans la colonne 'A faire' (tous utilisateurs)
  int countEnAttenteAll() {
    return _tasks
        .where((t) => !t.estComplete && t.statut == Statut.enAttente)
        .length;
  }

  /// Nombre de tâches dans la colonne 'En cours' (tous utilisateurs)
  int countEnCoursAll() {
    return _tasks
        .where((t) => !t.estComplete && t.statut == Statut.enCours)
        .length;
  }

  /// Nombre de tâches dans la colonne 'Terminé' (tous utilisateurs)
  int countTermineAll() {
    return _tasks
        .where((t) => t.estComplete || t.statut == Statut.termine)
        .length;
  }

  /// Nombre de tâches en retard pour une personne
  int countOverdueFor(String prenom) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return _tasks.where((t) {
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
        _tasks.where((t) => t.assignedTo.contains(prenom)).toList();
    if (userTasks.isEmpty) return 0.0;
    final completed = userTasks.where((t) => t.estComplete).length;
    return (completed / userTasks.length) * 100.0;
  }

  /// Trier par urgence + date
  void _sortTasksByUrgencyAndDate() {
    _tasks.sort((a, b) {
      final urgenceOrder = {'haute': 0, 'moyenne': 1, 'basse': 2};
      final aOrder = urgenceOrder[a.urgence.label] ?? 2;
      final bOrder = urgenceOrder[b.urgence.label] ?? 2;
      if (aOrder != bOrder) return aOrder.compareTo(bOrder);
      return (b.dateEcheance ?? DateTime(9999))
          .compareTo(a.dateEcheance ?? DateTime(9999));
    });
  }
}
