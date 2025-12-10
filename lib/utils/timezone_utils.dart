import 'package:timezone/timezone.dart' as tz;

/// Utility functions for timezone calculations
/// Extracted to avoid duplication between notification services
///
/// Note: Currently hardcoded to Europe/Paris timezone
/// This matches the application's target user base
class TimezoneUtils {
  /// The timezone location used throughout the app
  static const String defaultTimezone = 'Europe/Paris';

  /// Convert a DateTime to Europe/Paris timezone
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

  /// Calculate schedule time for notification based on deadline and minutes before
  static DateTime calculateScheduleTime(
    DateTime deadline,
    int minutesBefore,
  ) {
    return deadline.subtract(Duration(minutes: minutesBefore));
  }

  /// Check if a schedule time is in the past
  static bool isScheduleTimeInPast(DateTime scheduleTime) {
    return scheduleTime.isBefore(DateTime.now());
  }
}
