import '../models/todo_task.dart';

/// Définit le contrat pour un service de notification.
/// Toutes les implémentations (mobile, web, test) doivent respecter cette interface.
abstract class NotificationServiceInterface {
  /// Initialiser le service.
  Future<void> init();

  /// Planifier une notification pour une tâche.
  Future<void> scheduleNotificationForTask(TodoTask task);

  /// Planifier une notification ponctuelle (one-off) à une date donnée.
  Future<void> scheduleOneOffNotification({
    required int id,
    required String title,
    String? body,
    required DateTime when,
    String? payload,
  });

  /// Annuler une notification via son ID.
  Future<void> cancelNotification(int notificationId);
}
