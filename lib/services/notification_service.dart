import '../models/todo_task.dart';
import 'notification_service_interface.dart';
import 'notification_service_noop.dart';

/// Wrapper qui neutralise le service de notification (no-op).
class NotificationServiceWrapper implements NotificationServiceInterface {
  NotificationServiceWrapper._internal();
  static final NotificationServiceWrapper _instance =
      NotificationServiceWrapper._internal();
  factory NotificationServiceWrapper() => _instance;

  final NotificationServiceInterface _impl = NotificationServiceNoop();

  @override
  Future<void> init() async => _impl.init();

  /// Backwards-compatible name used in `main.dart`.
  Future<void> initialize() async => init();

  @override
  Future<void> scheduleNotificationForTask(TodoTask task) async =>
      _impl.scheduleNotificationForTask(task);

  @override
  Future<void> cancelNotification(int notificationId) async =>
      _impl.cancelNotification(notificationId);

  /// Compatibilité: replanifie la notification d'une tâche (annule puis schedule)
  Future<void> rescheduleForTask(TodoTask task) async {
    await cancelNotification(task.id.hashCode);
    await scheduleNotificationForTask(task);
  }

  @override
  Future<void> scheduleOneOffNotification({
    required int id,
    required String title,
    String? body,
    required DateTime when,
    String? payload,
  }) async {
    await _impl.scheduleOneOffNotification(
        id: id, title: title, body: body, when: when, payload: payload);
  }

  /// Compatibilité: annule toutes les notifications pour un taskId
  Future<void> cancelAllForTask(String taskId,
      [List<Map<String, dynamic>>? _]) async {
    await cancelNotification(taskId.hashCode);
  }
}

final notificationService = NotificationServiceWrapper();
