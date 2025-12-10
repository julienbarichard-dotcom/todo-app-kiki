import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'notification_service_interface.dart';
import '../models/todo_task.dart';

/// Service pour gérer les notifications locales
/// Implémentation pour MOBILE (Android/iOS)
class NotificationService implements NotificationServiceInterface {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  /// Initialiser le service
  @override
  Future<void> init() async {
    // Paramètres pour Android
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    // Paramètres pour iOS
    const DarwinInitializationSettings iosSettings =
        DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const InitializationSettings initializationSettings =
        InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    // Initialiser la base de données des fuseaux horaires
    tz.initializeTimeZones();

    await _notificationsPlugin.initialize(initializationSettings);
    await _requestPermissions();
  }

  /// Demander les permissions
  Future<void> _requestPermissions() async {
    // Pour Android 13+
    await _notificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();

    // Pour iOS
    await _notificationsPlugin
        .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(alert: true, badge: true, sound: true);
  }

  /// Planifier une notification pour une tâche
  @override
  Future<void> scheduleNotificationForTask(TodoTask task) async {
    // Annuler toute notification existante pour cette tâche pour éviter les doublons
    await cancelNotification(task.id.hashCode);

    // Vérifier si la notification doit être planifiée
    if (!task.notificationEnabled || task.dateEcheance == null) {
      return;
    }

    final scheduleTime = task.dateEcheance!.subtract(
      Duration(minutes: task.notificationMinutesBefore ?? 30),
    );

    // Ne pas planifier de notification si l'heure est déjà passée
    if (scheduleTime.isBefore(DateTime.now())) {
      return;
    }

    const androidDetails = AndroidNotificationDetails(
      'todo_channel_id',
      'Todo Notifications',
      channelDescription: 'Notifications pour les tâches à faire',
      importance: Importance.max,
      priority: Priority.high,
    );
    const notificationDetails = NotificationDetails(android: androidDetails);

    // Construire la TZDateTime en Europe/Paris pour forcer l'heure de Paris
    final paris = tz.getLocation('Europe/Paris');
    final tzSchedule = tz.TZDateTime(
        paris,
        scheduleTime.year,
        scheduleTime.month,
        scheduleTime.day,
        scheduleTime.hour,
        scheduleTime.minute,
        scheduleTime.second);

    await _notificationsPlugin.zonedSchedule(
      task.id.hashCode,
      'Tâche imminente : ${task.titre}',
      'N\'oubliez pas votre tâche prévue pour ${task.dateEcheance!.hour}h${task.dateEcheance!.minute.toString().padLeft(2, '0')}',
      tzSchedule,
      notificationDetails,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
    );
  }

  /// Planifier une notification ponctuelle (one-off) à une date donnée
  @override
  Future<void> scheduleOneOffNotification({
    required int id,
    required String title,
    String? body,
    required DateTime when,
    String? payload,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'todo_channel_id',
      'Todo Notifications',
      channelDescription: 'Notifications pour les tâches à faire',
      importance: Importance.max,
      priority: Priority.high,
    );
    const notificationDetails = NotificationDetails(android: androidDetails);

    final paris = tz.getLocation('Europe/Paris');
    final tzSchedule = tz.TZDateTime(paris, when.year, when.month, when.day,
        when.hour, when.minute, when.second);

    await _notificationsPlugin.zonedSchedule(
      id,
      title,
      body,
      tzSchedule,
      notificationDetails,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      payload: payload,
    );
  }

  /// Annuler une notification
  @override
  Future<void> cancelNotification(int notificationId) async {
    await _notificationsPlugin.cancel(notificationId);
  }
}
