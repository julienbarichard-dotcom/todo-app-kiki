import 'package:flutter/material.dart';

/// Task form constants
/// Extracted to avoid duplication across form screens
class TaskFormConstants {
  /// Available task labels/categories
  static const List<String> labels = [
    'Perso',
    'B2B',
    'Cuisine',
    'Administratif',
    'Loisir',
    'Autre',
  ];

  /// Notification minutes before options
  static const List<int> notificationMinutes = [5, 15, 30, 60, 120, 1440];

  /// Minutes in a full day (24 hours)
  static const int minutesPerDay = 1440;

  /// Get display text for notification minutes
  static String getNotificationMinutesLabel(int minutes) {
    if (minutes == minutesPerDay) {
      return '1 jour';
    } else if (minutes >= 60) {
      return '${minutes ~/ 60}h';
    } else {
      return '$minutes min';
    }
  }

  /// Primary accent color used throughout forms
  static const mintGreen = Color(0xFF1DB679);
}
