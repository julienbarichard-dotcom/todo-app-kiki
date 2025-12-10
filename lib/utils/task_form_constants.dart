import 'package:flutter/material.dart';

/// Constantes pour les formulaires de tâches
/// Extrait pour éviter la duplication entre les écrans de formulaire
class TaskFormConstants {
  /// Étiquettes/catégories de tâches disponibles
  static const List<String> labels = [
    'Perso',
    'B2B',
    'Cuisine',
    'Administratif',
    'Loisir',
    'Autre',
  ];

  /// Options de minutes avant pour les notifications
  static const List<int> notificationMinutes = [5, 15, 30, 60, 120, 1440];

  /// Minutes dans une journée complète (24 heures)
  static const int minutesPerDay = 1440;

  /// Obtenir le texte d'affichage pour les minutes de notification
  static String getNotificationMinutesLabel(int minutes) {
    if (minutes == minutesPerDay) {
      return '1 jour';
    } else if (minutes >= 60) {
      return '${minutes ~/ 60}h';
    } else {
      return '$minutes min';
    }
  }

  /// Couleur d'accentuation principale utilisée dans tous les formulaires
  static const mintGreen = Color(0xFF1DB679);
}
