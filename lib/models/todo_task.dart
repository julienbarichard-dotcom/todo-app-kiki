import 'package:flutter/material.dart';

/// Classe pour une sous-tâche
class SubTask {
  final String id;
  final String titre;
  bool estComplete;

  SubTask({
    required this.id,
    required this.titre,
    this.estComplete = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'titre': titre,
      'est_complete': estComplete,
    };
  }

  factory SubTask.fromMap(Map<String, dynamic> map) {
    return SubTask(
      id: map['id'] ?? '',
      titre: map['titre'] ?? '',
      estComplete: map['est_complete'] ?? false,
    );
  }
}

/// Classe pour un commentaire collaboratif
class TaskComment {
  final String id;
  final String author;
  final String text;
  final DateTime timestamp;

  TaskComment({
    required this.id,
    required this.author,
    required this.text,
    required this.timestamp,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'author': author,
      'text': text,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  factory TaskComment.fromMap(Map<String, dynamic> map) {
    return TaskComment(
      id: map['id'] ?? '',
      author: map['author'] ?? '',
      text: map['text'] ?? '',
      timestamp: map['timestamp'] != null
          ? DateTime.parse(map['timestamp'])
          : DateTime.now(),
    );
  }
}

/// Énumération pour les niveaux d'urgence
enum Urgence {
  basse,
  moyenne,
  haute,
}

/// Énumération pour le statut d'une tâche
enum Statut {
  enAttente,
  enCours,
  aValider,
  termine,
}

/// Extension pour convertir Urgence en String et couleur
extension UrgenceExtension on Urgence {
  String get label {
    switch (this) {
      case Urgence.basse:
        return 'Basse';
      case Urgence.moyenne:
        return 'Moyenne';
      case Urgence.haute:
        return 'Haute';
    }
  }

  Color get color {
    switch (this) {
      case Urgence.basse:
        return Colors.green;
      case Urgence.moyenne:
        return Colors.orange;
      case Urgence.haute:
        return Colors.red;
    }
  }
}

/// Extension pour convertir Statut en String et couleur
extension StatutExtension on Statut {
  String get label {
    switch (this) {
      case Statut.enAttente:
        return 'A faire';
      case Statut.enCours:
        return 'En cours';
      case Statut.aValider:
        return 'A valider';
      case Statut.termine:
        return 'Terminé';
    }
  }

  Color get color {
    switch (this) {
      case Statut.enAttente:
        return Colors.grey;
      case Statut.enCours:
        return Colors.blue;
      case Statut.aValider:
        return Colors.orange;
      case Statut.termine:
        return Colors.green;
    }
  }
}

/// Modèle pour une tâche Todo
class TodoTask {
  final String id;
  final String titre;
  final String description;
  final Urgence urgence;
  final DateTime?
      dateEcheance; // Optionnelle - Keep camelCase for Dart property
  bool estComplete; // Keep camelCase for Dart property
  final List<String>
      assignedTo; // Liste des prénoms assignés (IDs des users) - Keep camelCase for Dart property
  final DateTime dateCreation; // Keep camelCase for Dart property
  final List<SubTask> subTasks; // Sous-tâches optionnelles
  final String? label; // Catégorie/Label de la tâche
  final Statut statut; // Statut de la tâche (A faire, En cours, Terminé)
  final bool isReported; // Tâche reportée automatiquement au lendemain

  // Paramètres de notifications
  final bool notificationEnabled; // Keep camelCase for Dart property
  final int?
      notificationMinutesBefore; // Minutes avant la date d'échéance - Keep camelCase for Dart property

  // Paramètres de multi-validation collaborative
  final bool isMultiValidation; // Active le mode multi-validation
  final Map<String, bool> validations; // {"Julien": true, "Lou": false, ...}
  final List<TaskComment> comments; // Liste des commentaires collaboratifs
  final bool isRejected; // Card rouge si au moins un rejet
  final DateTime? lastUpdatedValidation; // Timestamp dernière validation/rejet

  TodoTask({
    required this.id,
    required this.titre,
    required this.description,
    required this.urgence,
    this.dateEcheance,
    this.estComplete = false,
    this.assignedTo = const [],
    required this.dateCreation,
    this.subTasks = const [],
    this.label,
    this.statut = Statut.enAttente,
    this.isReported = false,
    this.notificationEnabled = false,
    this.notificationMinutesBefore,
    this.isMultiValidation = false,
    this.validations = const {},
    this.comments = const [],
    this.isRejected = false,
    this.lastUpdatedValidation,
  });

  /// Convertir une tâche en dictionnaire (pour Firebase/Hive)
  Map<String, dynamic> toMap() {
    // Convert to snake_case for Supabase
    return {
      'id': id,
      'titre': titre,
      'description': description,
      'urgence': urgence.name,
      'date_echeance':
          dateEcheance?.toIso8601String(), // Use snake_case for map key
      'est_complete': estComplete, // Use snake_case for map key
      'assigned_to': assignedTo, // Use snake_case for map key
      'date_creation':
          dateCreation.toIso8601String(), // Use snake_case for map key
      'sub_tasks': subTasks.map((st) => st.toMap()).toList(),
      'label': label,
      'statut': statut.name,
      'is_reported': isReported,
      'notification_enabled': notificationEnabled, // Use snake_case for map key
      'notification_minutes_before':
          notificationMinutesBefore, // Use snake_case for map key
      'is_multi_validation': isMultiValidation,
      'validations': validations,
      'comments': comments.map((c) => c.toMap()).toList(),
      'is_rejected': isRejected,
      'last_updated_validation': lastUpdatedValidation?.toIso8601String(),
    };
  }

  /// Créer une tâche à partir d'un dictionnaire (depuis Firebase/Hive)
  factory TodoTask.fromMap(Map<String, dynamic> map) {
    // Read from snake_case from Supabase
    return TodoTask(
      id: map['id'] ?? '',
      titre: map['titre'] ?? '',
      description: map['description'] ?? '',
      urgence: Urgence.values.firstWhere(
        (e) => e.name == map['urgence'],
        orElse: () => Urgence.moyenne,
      ),
      dateEcheance: map['date_echeance'] != null // Read from snake_case map key
          ? DateTime.parse(map['date_echeance']) // Read from snake_case map key
          : null,
      estComplete: map['est_complete'] ?? false, // Read from snake_case map key
      assignedTo: List<String>.from(
          map['assigned_to'] ?? []), // Read from snake_case map key
      dateCreation: map['date_creation'] != null // Read from snake_case map key
          ? DateTime.parse(map['date_creation']) // Read from snake_case map key
          : DateTime.now(),
      subTasks: map['sub_tasks'] != null
          ? (map['sub_tasks'] as List?)
                  ?.map((st) {
                    try {
                      return SubTask.fromMap(st as Map<String, dynamic>);
                    } catch (e) {
                      return null;
                    }
                  })
                  .whereType<SubTask>()
                  .toList() ??
              []
          : [],
      label: map['label'],
      statut: Statut.values.firstWhere(
        (e) => e.name == map['statut'],
        orElse: () => Statut.enAttente,
      ),
      isReported: map['is_reported'] ?? false,
      notificationEnabled:
          map['notification_enabled'] ?? false, // Read from snake_case map key
      notificationMinutesBefore:
          map['notification_minutes_before'], // Read from snake_case map key
      isMultiValidation: map['is_multi_validation'] ?? false,
      validations: Map<String, bool>.from(map['validations'] ?? {}),
      comments: map['comments'] != null
          ? (map['comments'] as List)
              .map((c) => TaskComment.fromMap(c as Map<String, dynamic>))
              .toList()
          : [],
      isRejected: map['is_rejected'] ?? false,
      lastUpdatedValidation: map['last_updated_validation'] != null
          ? DateTime.parse(map['last_updated_validation'])
          : null,
    );
  }

  /// Copier une tâche avec certains champs modifiés
  TodoTask copyWith({
    String? id,
    String? titre,
    String? description,
    Urgence? urgence,
    DateTime? dateEcheance,
    bool? estComplete,
    List<String>? assignedTo,
    DateTime? dateCreation,
    List<SubTask>? subTasks,
    String? label,
    Statut? statut,
    bool? isReported,
    bool? notificationEnabled,
    int? notificationMinutesBefore,
    bool? isMultiValidation,
    Map<String, bool>? validations,
    List<TaskComment>? comments,
    bool? isRejected,
    DateTime? lastUpdatedValidation,
  }) {
    return TodoTask(
      id: id ?? this.id,
      titre: titre ?? this.titre,
      description: description ?? this.description,
      urgence: urgence ?? this.urgence,
      dateEcheance: dateEcheance ?? this.dateEcheance,
      estComplete: estComplete ?? this.estComplete,
      assignedTo: assignedTo ?? this.assignedTo,
      dateCreation: dateCreation ?? this.dateCreation,
      subTasks: subTasks ?? this.subTasks,
      label: label ?? this.label,
      statut: statut ?? this.statut,
      isReported: isReported ?? this.isReported,
      notificationEnabled: notificationEnabled ?? this.notificationEnabled,
      notificationMinutesBefore:
          notificationMinutesBefore ?? this.notificationMinutesBefore,
      isMultiValidation: isMultiValidation ?? this.isMultiValidation,
      validations: validations ?? this.validations,
      comments: comments ?? this.comments,
      isRejected: isRejected ?? this.isRejected,
      lastUpdatedValidation:
          lastUpdatedValidation ?? this.lastUpdatedValidation,
    );
  }

  /// Calcule le pourcentage d'avancement basé sur les sous-tâches
  double get pourcentageAvancement {
    if (subTasks.isEmpty) {
      // Si pas de sous-tâches, se baser sur estComplete
      return estComplete ? 100.0 : 0.0;
    }
    final completees = subTasks.where((st) => st.estComplete).length;
    return (completees / subTasks.length) * 100;
  }

  // ======= GETTERS MULTI-VALIDATION =======

  /// Nombre total de personnes qui doivent valider
  int get totalValidators => assignedTo.length;

  /// Nombre de validations positives (true)
  int get approvedCount => validations.values.where((v) => v == true).length;

  /// Nombre de rejets (false)
  int get rejectedCount => validations.values.where((v) => v == false).length;

  /// Nombre de personnes qui n'ont pas encore validé
  int get pendingValidatorsCount => totalValidators - validations.length;

  /// Liste des prénoms qui ont validé
  List<String> get approvedBy => validations.entries
      .where((e) => e.value == true)
      .map((e) => e.key)
      .toList();

  /// Liste des prénoms qui ont rejeté
  List<String> get rejectedBy => validations.entries
      .where((e) => e.value == false)
      .map((e) => e.key)
      .toList();

  /// Liste des prénoms en attente de validation
  List<String> get pendingValidators =>
      assignedTo.where((name) => !validations.containsKey(name)).toList();

  /// Vérifie si tous ont validé (true)
  bool get allApproved =>
      isMultiValidation &&
      validations.length == totalValidators &&
      rejectedCount == 0;

  /// Vérifie si au moins un a validé
  bool get hasAnyApproval => approvedCount > 0;

  /// Vérifie si au moins un a rejeté
  bool get hasAnyRejection => rejectedCount > 0;
}
