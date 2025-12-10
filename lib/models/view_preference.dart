/// Énumération des vues disponibles pour afficher les tâches
enum ViewPreference {
  kanban, // Vue Kanban (colonnes par statut)
  list, // Vue Liste (liste linéaire avec filtres)
  compact, // Vue Compacte (cartes denses)
  timeline, // Vue Timeline (chronologique)
}

/// Extension pour convertir ViewPreference en String et inversement
extension ViewPreferenceExtension on ViewPreference {
  /// Obtenir le libellé français
  String get label {
    switch (this) {
      case ViewPreference.kanban:
        return 'Kanban';
      case ViewPreference.list:
        return 'Liste';
      case ViewPreference.compact:
        return 'Compacte';
      case ViewPreference.timeline:
        return 'Timeline';
    }
  }

  /// Obtenir une description courte
  String get description {
    switch (this) {
      case ViewPreference.kanban:
        return 'Colonnes par statut';
      case ViewPreference.list:
        return 'Liste linéaire avec filtres';
      case ViewPreference.compact:
        return 'Cartes denses et minimalistes';
      case ViewPreference.timeline:
        return 'Chronologie des tâches';
    }
  }

  /// Obtenir l'icône (emoji ou IconData name)
  String get emoji {
    switch (this) {
      case ViewPreference.kanban:
        return '📋';
      case ViewPreference.list:
        return '📝';
      case ViewPreference.compact:
        return '🎯';
      case ViewPreference.timeline:
        return '📅';
    }
  }

  /// Convertir en String pour persistance
  String toStorageString() => name;

  /// Parser depuis String
  static ViewPreference fromStorageString(String? value) {
    if (value == null) return ViewPreference.kanban; // Défaut
    try {
      return ViewPreference.values.firstWhere((v) => v.name == value);
    } catch (e) {
      return ViewPreference.kanban; // Défaut en cas d'erreur
    }
  }
}
