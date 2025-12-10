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
      debugPrint('🔄 LOAD TACHES: Début du chargement...');
      final response = await supabaseService.tasksTable.select();
      _taches =
          (response as List).map((json) => TodoTask.fromMap(json)).toList();
      debugPrint(
          '🔄 LOAD TACHES: ${_taches.length} tâches chargées depuis Supabase');
      // Report and reminders disabled: dates/reminders removed from model
      _triageParUrgenceDate();
      notifyListeners();

      // Synchronisation Calendar désactivée (plus de date d'échéance)
      await syncWithCalendar();
    } catch (e) {
      debugPrint('Erreur chargement tâches: $e');
    }
  }

  /// Reporter automatiquement les tâches dont la date est passée
  /// Les tâches non accomplies avec date AVANT aujourd'hui sont reportées à AUJOURD'HUI
  /// avec le triangle 🔺. Si l'heure existe, elle est conservée.
  Future<void> _reportOverdueTasks() async {
    // Report automatique désactivé : la gestion des dates/rapels a été supprimée
    debugPrint('🔍 REPORT AUTO: Désactivé (dateEcheance supprimée)');
  }

  /// Forcer le report des tâches en retard (pour test manuel)
  Future<void> forceReportOverdueTasks() async {
    await _reportOverdueTasks();
    notifyListeners();
  }

  /// Synchroniser les tâches avec Google Calendar (bidirectionnel)
  Future<void> syncWithCalendar() async {
    // Synchronisation Calendar désactivée : plus de date d'échéance à gérer
    debugPrint('🔄 Sync Calendar: désactivée (dateEcheance supprimée)');
  }

  /// Fonction simplifiée pour compatibilité
  void subscribeToTaskUpdates() {
    // Polling fallback: refresh tâches toutes les 8 secondes.
    if (_pollTimer != null) return;
    // Réduire la fréquence de polling pour éviter des appels répétés
    // lors du développement / en cas de réseau lent.
    debugPrint('Subscription polling activée (refresh toutes les 30s)');
    _pollTimer = Timer.periodic(const Duration(seconds: 30), (t) async {
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
      // Date/reminders removed: no calendar event creation or reminders
    } catch (e) {
      debugPrint('Erreur ajout tâche: $e');
    }
  }

  /// Supprimer une tâche
  Future<void> supprimerTache(String id) async {
    try {
      // Récupérer la tâche localement (pour annuler ses rappels)
      final index = _taches.indexWhere((t) => t.id == id);
      final TodoTask? task = index != -1 ? _taches[index] : null;

      await supabaseService.tasksTable.delete().eq('id', id);

      if (index != -1) {
        _taches.removeAt(index);
      }
      notifyListeners();

      // Supprimer de Google Calendar
      await googleCalendarService.deleteEventFromTask(id);
      // Reminders canceled client-side removed
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
              'Tâche "${tache.titre}" marquée terminée - suppression événement Calendar (si existant)');
          await googleCalendarService.deleteEventFromTask(tache.id);
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
    // Date-based counts disabled: due dates removed
    return 0;
  }

  /// Nombre de tâches pour aujourd'hui (tous utilisateurs)
  int countTasksTodayAll() {
    // Date-based counts disabled: due dates removed
    return 0;
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
    // Overdue counts disabled: due dates removed
    return 0;
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
    // Trier par urgence, puis par date de création pour stabilité
    _taches.sort((a, b) {
      final urgenceOrder = {'haute': 0, 'moyenne': 1, 'basse': 2};
      final aOrder = urgenceOrder[a.urgence.label] ?? 2;
      final bOrder = urgenceOrder[b.urgence.label] ?? 2;
      if (aOrder != bOrder) return aOrder.compareTo(bOrder);
      return b.dateCreation.compareTo(a.dateCreation);
    });
  }
}
