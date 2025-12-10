import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

void main() {
  // Initialiser les fuseaux horaires
  tz.initializeTimeZones();
  final paris = tz.getLocation('Europe/Paris');

  print('=== Test de conversion timezone Europe/Paris ===\n');

  // Exemple 1: Date/heure actuelle
  final now = DateTime.now();
  final nowParis = tz.TZDateTime.now(paris);
  print('DateTime.now() (local): $now');
  print('TZDateTime.now(Paris): $nowParis');
  print('UTC equivalent: ${nowParis.toUtc()}');
  print('ISO 8601: ${nowParis.toUtc().toIso8601String()}\n');

  // Exemple 2: Date spécifique (28 nov 2025 15:00 Paris)
  final exampleDate = DateTime(2025, 11, 28, 15, 0);
  final exampleParis = tz.TZDateTime(paris, 2025, 11, 28, 15, 0);
  print('Date exemple: 28 nov 2025 15:00');
  print('TZDateTime Paris: $exampleParis');
  print('UTC equivalent: ${exampleParis.toUtc()}');
  print('ISO 8601: ${exampleParis.toUtc().toIso8601String()}');
  print('Offset Paris: ${exampleParis.timeZoneOffset}\n');

  // Exemple 3: Date en été (heure d'été CEST = UTC+2)
  final summerDate = tz.TZDateTime(paris, 2025, 7, 15, 15, 0);
  print('Date été (15 juillet 2025 15:00 Paris):');
  print('TZDateTime Paris: $summerDate');
  print('UTC equivalent: ${summerDate.toUtc()}');
  print('ISO 8601: ${summerDate.toUtc().toIso8601String()}');
  print('Offset été (CEST): ${summerDate.timeZoneOffset}\n');

  // Exemple 4: Conversion inverse (UTC -> Paris)
  final utcTime = DateTime.utc(2025, 11, 28, 14, 0); // 14h UTC
  final parisFromUtc = tz.TZDateTime.from(utcTime, paris);
  print('UTC: ${utcTime.toIso8601String()}');
  print('Converti en Paris: $parisFromUtc');
  print('Heure locale Paris: ${parisFromUtc.hour}h${parisFromUtc.minute}\n');

  print('=== Résumé ===');
  print('• Novembre 2025: Paris = UTC+1 (heure d\'hiver CET)');
  print('• Juillet 2025: Paris = UTC+2 (heure d\'été CEST)');
  print('• Google Calendar API attend: dateTime en UTC + timeZone séparé');
  print('• Format ISO envoyé: ${exampleParis.toUtc().toIso8601String()}');
}
