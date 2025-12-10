import 'package:flutter/material.dart';
import '../models/todo_task.dart';

/// Provider qui gère l'état global des tâches
/// Utilise ChangeNotifier pour notifier les widgets des changements
class TodoProvider extends ChangeNotifier {
  /// Liste locale des tâches
  List<TodoTask> _taches = [];

  TodoProvider() {
    // Charger les données de test au démarrage
    _initializerTestData();
  }

  /// Initialiser avec des données de test
  void _initializerTestData() {
    _taches = [
      TodoTask(
        id: '1',
        titre: 'Faire les courses',
        description: 'Lait, pain, œufs',
        urgence: Urgence.haute,
        dateEcheance: DateTime.now().add(const Duration(days: 1)),
        assignedTo: ['Lou'], // Assigné à Lou (sera remplacé par l'ID)
        dateCreation: DateTime.now(),
        notificationEnabled: true,
        notificationMinutesBefore: 30,
      ),
      TodoTask(
        id: '2',
        titre: 'Appeler le plombier',
        description: 'Fuite robinet cuisine',
        urgence: Urgence.moyenne,
        dateEcheance: DateTime.now().add(const Duration(days: 3)),
        assignedTo: ['Julien'],
        dateCreation: DateTime.now(),
        notificationEnabled: false,
      ),
      TodoTask(
        id: '3',
        titre: 'Tondre la pelouse',
        description: 'Tondeuse dans le garage',
        urgence: Urgence.basse,
        dateEcheance: DateTime.now().add(const Duration(days: 7)),
        assignedTo: ['Lou', 'Julien'], // Les deux
        dateCreation: DateTime.now(),
        notificationEnabled: true,
        notificationMinutesBefore: 60,
      ),
      TodoTask(
        id: '4',
        titre: 'Réunion importante',
        description: 'Préparer les slides',
        urgence: Urgence.haute,
        dateEcheance: DateTime.now().add(const Duration(hours: 2)),
        assignedTo: ['Lou'],
        dateCreation: DateTime.now(),
        notificationEnabled: true,
        notificationMinutesBefore: 15,
      ),
    ];
  }

  /// Getter pour accéder aux tâches
  List<TodoTask> get taches => _taches;

  /// Obtenir les tâches triées par urgence (haute -> basse) puis par date
  List<TodoTask> get tachesTriees {
    final tachesNonTerminees = _taches.where((t) => !t.estComplete).toList();

    // Trier par urgence d'abord (haute = 0, moyenne = 1, basse = 2)
    // Puis par date d'échéance
    tachesNonTerminees.sort((a, b) {
      final urgenceCompare = a.urgence.index.compareTo(b.urgence.index);
      if (urgenceCompare != 0) return urgenceCompare;

      // Si même urgence, trier par date
      if (a.dateEcheance != null && b.dateEcheance != null) {
        return a.dateEcheance!.compareTo(b.dateEcheance!);
      }
      return 0;
    });

    return tachesNonTerminees;
  }

  /// Obtenir les tâches complétées
  List<TodoTask> get tachesCompletes {
    return _taches.where((t) => t.estComplete).toList();
  }

  /// Ajouter une nouvelle tâche
  void ajouterTache(TodoTask tache) {
    _taches.add(tache);
    notifyListeners(); // Notifier les widgets
  }

  /// Supprimer une tâche par ID
  void supprimerTache(String id) {
    _taches.removeWhere((t) => t.id == id);
    notifyListeners();
  }

  /// Modifier une tâche
  void modifierTache(TodoTask tacheModifiee) {
    final index = _taches.indexWhere((t) => t.id == tacheModifiee.id);
    if (index != -1) {
      _taches[index] = tacheModifiee;
      notifyListeners();
    }
  }

  /// Cocher/décocher une tâche
  void toggleTacheComplete(String id) {
    final tache = _taches.firstWhere(
      (t) => t.id == id,
      orElse: () => throw Exception('Tâche non trouvée'),
    );
    tache.estComplete = !tache.estComplete;
    notifyListeners();
  }

  /// Charger les tâches depuis la base de données (Firebase/Hive)
  Future<void> chargerTaches(List<TodoTask> tachesChargees) async {
    _taches = tachesChargees;
    notifyListeners();
  }

  /// Filtrer les tâches par personne (celles assignées à cet utilisateur)
  List<TodoTask> getTachesPourPersonne(String userPrenom) {
    return tachesTriees
        .where((t) => t.assignedTo.contains(userPrenom))
        .toList();
  }

  /// Filtrer les tâches par urgence
  List<TodoTask> getTachesParUrgence(Urgence urgence) {
    return tachesTriees.where((t) => t.urgence == urgence).toList();
  }

  /// Obtenir les tâches avec date d'échéance proche
  List<TodoTask> getTachesUrgentes({int joursRestants = 3}) {
    final maintenant = DateTime.now();
    final dateLimit = maintenant.add(Duration(days: joursRestants));

    return tachesTriees
        .where((t) =>
            t.dateEcheance != null &&
            t.dateEcheance!.isAfter(maintenant) &&
            t.dateEcheance!.isBefore(dateLimit))
        .toList();
  }
}
