import 'dart:async';
import 'package:flutter/foundation.dart';
import 'dart:html' as html; // Importation pour l'API web
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import '../models/todo_task.dart';
import 'notification_service_interface.dart';

/// Implémentation "factice" du service de notification pour le web.
/// Les notifications locales ne sont pas supportées sur le web de cette manière.
class NotificationService implements NotificationServiceInterface {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  // Map pour garder une trace des minuteurs afin de pouvoir les annuler.
  final Map<int, Timer> _scheduledTimers = {};

  @override
  Future<void> init() async {
    // Demander la permission à l'utilisateur pour afficher des notifications.
    // Cela ne fonctionne que dans un contexte sécurisé (HTTPS).
    if (html.Notification.supported) {
      final permission = await html.Notification.requestPermission();
      if (permission == 'granted') {
        debugPrint('Permission pour les notifications web accordée.');
      } else {
        debugPrint('Permission pour les notifications web refusée.');
      }
    } else {
      debugPrint(
          'Les notifications web ne sont pas supportées par ce navigateur.');
    }
  }

  @override
  Future<void> scheduleNotificationForTask(TodoTask task) async {
    // Annuler toute notification précédemment planifiée pour cette tâche.
    await cancelNotification(task.id.hashCode);

    // Vérifier si les notifications sont supportées et autorisées.
    if (!html.Notification.supported ||
        html.Notification.permission != 'granted') {
      return;
    }

    // Vérifier si la notification est activée pour la tâche et si une date est définie.
    if (!task.notificationEnabled || task.dateEcheance == null) {
      return;
    }

    final scheduleTime = task.dateEcheance!
        .subtract(Duration(minutes: task.notificationMinutesBefore ?? 30));
    // Interpréter la date comme Europe/Paris et calculer le délai en UTC
    tz.initializeTimeZones();
    final paris = tz.getLocation('Europe/Paris');
    final tzSchedule = tz.TZDateTime(
        paris,
        scheduleTime.year,
        scheduleTime.month,
        scheduleTime.day,
        scheduleTime.hour,
        scheduleTime.minute,
        scheduleTime.second);
    final delay = tzSchedule.toUtc().difference(DateTime.now().toUtc());

    // Ne rien faire si l'heure est déjà passée.
    if (delay.isNegative) return;

    // Planifier l'affichage de la notification après le délai calculé.
    _scheduledTimers[task.id.hashCode] = Timer(delay, () {
      html.Notification('Tâche imminente : ${task.titre}',
          body:
              'N\'oubliez pas votre tâche prévue pour ${task.dateEcheance!.hour}h${task.dateEcheance!.minute.toString().padLeft(2, '0')}');
      _scheduledTimers.remove(task.id.hashCode);
    });
  }

  @override
  Future<void> cancelNotification(int notificationId) async {
    // Annuler le minuteur s'il existe.
    _scheduledTimers[notificationId]?.cancel();
    _scheduledTimers.remove(notificationId);
  }
}
