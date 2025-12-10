import 'notification_service_interface.dart';
import '../models/todo_task.dart';

class NotificationServiceNoop implements NotificationServiceInterface {
  @override
  Future<void> init() async {
    // no-op
  }

  @override
  Future<void> scheduleNotificationForTask(TodoTask task) async {
    // no-op
  }

  @override
  Future<void> cancelNotification(int notificationId) async {
    // no-op
  }

  @override
  Future<void> scheduleOneOffNotification({
    required int id,
    required String title,
    String? body,
    required DateTime when,
    String? payload,
  }) async {
    // no-op
  }
}
