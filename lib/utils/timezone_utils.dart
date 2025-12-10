import 'package:timezone/timezone.dart' as tz;

/// Fonctions utilitaires pour les calculs de fuseau horaire
/// Extrait pour éviter la duplication entre les services de notification
///
/// Note: Actuellement codé en dur pour le fuseau horaire Europe/Paris
/// Cela correspond à la base d'utilisateurs cible de l'application
class TimezoneUtils {
  /// Le fuseau horaire utilisé dans toute l'application
  static const String defaultTimezone = 'Europe/Paris';

  /// Convertir un DateTime en fuseau horaire Europe/Paris
  static tz.TZDateTime toParisTime(DateTime dateTime) {
    final paris = tz.getLocation(defaultTimezone);
    return tz.TZDateTime(
      paris,
      dateTime.year,
      dateTime.month,
      dateTime.day,
      dateTime.hour,
      dateTime.minute,
      dateTime.second,
    );
  }

  /// Calculer l'heure de planification pour la notification basée sur l'échéance et les minutes avant
  static DateTime calculateScheduleTime(
    DateTime deadline,
    int minutesBefore,
  ) {
    return deadline.subtract(Duration(minutes: minutesBefore));
  }

  /// Vérifier si une heure de planification est dans le passé
  static bool isScheduleTimeInPast(DateTime scheduleTime) {
    return scheduleTime.isBefore(DateTime.now());
  }
}
