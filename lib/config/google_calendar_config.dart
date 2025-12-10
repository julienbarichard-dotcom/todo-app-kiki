/// Configuration Google Calendar API
class GoogleCalendarConfig {
  // Client ID OAuth2 Google
  static const String clientId =
      '678172026114-1epb9v2qqin086v44kkk5kop0p97at9b.apps.googleusercontent.com';

  // Scopes nécessaires
  static const List<String> scopes = [
    'https://www.googleapis.com/auth/calendar.readonly',
    'https://www.googleapis.com/auth/calendar.events',
  ];

  // ID du calendrier (primary = calendrier principal)
  static const String calendarId = 'primary';
}
