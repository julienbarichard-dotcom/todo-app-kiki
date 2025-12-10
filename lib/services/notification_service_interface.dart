import '../models/todo_task.dart';

/// Définit le contrat pour un service de notification.
/// Toutes les implémentations (mobile, web, test) doivent respecter cette interface.
abstract class NotificationServiceInterface {
  /// Initialiser le service.
  Future<void> init();

  /// Planifier une notification pour une tâche.
  Future<void> scheduleNotificationForTask(TodoTask task);

  /// Annuler une notification via son ID.
  Future<void> cancelNotification(int notificationId);
}
