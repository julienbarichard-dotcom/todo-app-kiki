import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:googleapis/calendar/v3.dart' as calendar;
import 'package:google_sign_in/google_sign_in.dart';
import 'package:extension_google_sign_in_as_googleapis_auth/extension_google_sign_in_as_googleapis_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/google_calendar_config.dart';
import '../models/todo_task.dart';

/// Service pour gérer Google Calendar avec google_sign_in
/// Persistance de session via signInSilently
class GoogleCalendarService {
  static final GoogleCalendarService _instance =
      GoogleCalendarService._internal();
  factory GoogleCalendarService() => _instance;
  GoogleCalendarService._internal();

  calendar.CalendarApi? _calendarApi;
  // _isInitialized was removed: assignments were present but the field was never read.

  final GoogleSignIn _googleSignIn = GoogleSignIn(
    clientId: GoogleCalendarConfig.clientId,
    scopes: GoogleCalendarConfig.scopes,
  );

  /// Vérifier si l'utilisateur est déjà connecté
  bool checkExistingToken() {
    return _googleSignIn.currentUser != null && _calendarApi != null;
  }

  /// Vérifier si déjà authentifié
  bool get isAuthenticated => _calendarApi != null;

  /// Tenter de restaurer la session silencieusement (après reload)
  Future<bool> tryRestoreSession() async {
    try {
      debugPrint('🔄 Tentative de restauration de session Google...');

      // Vérifier si une session existe dans le storage
      final prefs = await SharedPreferences.getInstance();
      final wasLoggedIn = prefs.getBool('google_calendar_logged_in') ?? false;

      if (!wasLoggedIn) {
        debugPrint('ℹ️ Aucune session précédente trouvée');
        return false;
      }

      debugPrint(
          '📱 Session précédente détectée, tentative de reconnexion silencieuse...');

      // Tenter de se reconnecter silencieusement (sans popup)
      // suppressErrors: true permet d'éviter les erreurs fatales si la session a expiré
      final account = await _googleSignIn.signInSilently(suppressErrors: true);

      if (account == null) {
        debugPrint(
            '⚠️ Session Google expirée ou révoquée - reconnexion manuelle nécessaire');
        debugPrint(
            '💡 Note: Sur web, les cookies doivent être autorisés pour accounts.google.com');
        await prefs.setBool('google_calendar_logged_in', false);
        return false;
      }

      debugPrint('✅ Session Google restaurée: ${account.email}');

      // Attendre que la session soit complètement prête (important sur mobile/web)
      await Future.delayed(const Duration(milliseconds: 800));

      // Utiliser l'extension pour obtenir le client authentifié
      var authClient = await _googleSignIn.authenticatedClient();

      // Retry si null la première fois (timing issue sur mobile)
      if (authClient == null) {
        debugPrint('⏳ Premier essai null, attente supplémentaire...');
        await Future.delayed(const Duration(milliseconds: 500));
        authClient = await _googleSignIn.authenticatedClient();
      }

      if (authClient == null) {
        debugPrint('❌ Client authentifié null - tokens peut-être expirés');
        debugPrint('💡 Une reconnexion manuelle sera nécessaire');
        await prefs.setBool('google_calendar_logged_in', false);
        return false;
      }

      // Initialiser l'API Calendar
      _calendarApi = calendar.CalendarApi(authClient);

      debugPrint('✅ API Calendar restaurée et prête');

      // Initialiser la db des fuseaux si nécessaire (idempotent)
      try {
        tz.initializeTimeZones();
      } catch (_) {}

      return true;
    } catch (e) {
      debugPrint('❌ Erreur restauration session Google: $e');
      debugPrint('💡 L\'utilisateur devra se reconnecter manuellement');

      // Effacer le flag pour forcer une nouvelle connexion
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('google_calendar_logged_in', false);
      } catch (_) {}

      return false;
    }
  }

  /// Initialiser et authentifier avec Google
  Future<bool> authenticate() async {
    try {
      debugPrint('🔐 Début authentification Google Calendar...');

      // Connexion interactive avec popup
      final account = await _googleSignIn.signIn();

      if (account == null) {
        debugPrint('❌ Connexion annulée par l\'utilisateur');
        return false;
      }

      debugPrint('✅ Utilisateur connecté: ${account.email}');

      // Sur web, attendre que la session soit prête
      await Future.delayed(const Duration(milliseconds: 500));

      // Utiliser l'extension pour obtenir le client authentifié
      var authClient = await _googleSignIn.authenticatedClient();

      // Retry une seule fois si null
      if (authClient == null) {
        debugPrint('⏳ Client null, nouvelle tentative...');
        await Future.delayed(const Duration(milliseconds: 300));
        authClient = await _googleSignIn.authenticatedClient();
      }

      if (authClient == null) {
        debugPrint(
            '❌ Impossible d\'obtenir le client authentifié après 2 tentatives');
        debugPrint('💡 Tokens peut-être invalides, réessayer plus tard');
        // Déconnecter pour nettoyer l'état
        await _googleSignIn.signOut();
        return false;
      }

      debugPrint('✅ Client authentifié obtenu');

      // Initialiser l'API Calendar
      _calendarApi = calendar.CalendarApi(authClient);
      debugPrint('✅ API Calendar initialisée');

      // Sauvegarder l'état de connexion
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('google_calendar_logged_in', true);

      return true;
    } catch (e, stackTrace) {
      debugPrint('❌ Erreur authentification Google Calendar: $e');
      debugPrint('Stack trace: $stackTrace');
      return false;
    }
  }

  /// Déconnecter et révoquer l'accès Google Calendar
  Future<void> disconnect() async {
    try {
      debugPrint('🔌 Déconnexion Google Calendar...');

      // Déconnecter Google Sign In (révoque les tokens)
      await _googleSignIn.disconnect();

      // Effacer l'état de connexion
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('google_calendar_logged_in', false);

      // Réinitialiser l'API
      _calendarApi = null;

      debugPrint('✅ Déconnexion Google Calendar réussie');
    } catch (e) {
      debugPrint('⚠️ Erreur lors de la déconnexion Google: $e');
      // Forcer le nettoyage même en cas d'erreur
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('google_calendar_logged_in', false);
        _calendarApi = null;
      } catch (_) {}
    }
  }

  /// Récupérer les événements du calendrier
  Future<List<calendar.Event>> getEvents({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    if (_calendarApi == null) {
      final success = await authenticate();
      if (!success) return [];
    }

    try {
      // Utiliser le fuseau Europe/Paris pour définir timeMin/timeMax
      tz.initializeTimeZones();
      final paris = tz.getLocation('Europe/Paris');
      final nowParis = tz.TZDateTime.now(paris);
      final timeMin = (startDate != null)
          ? tz.TZDateTime(paris, startDate.year, startDate.month, startDate.day,
                  startDate.hour, startDate.minute)
              .toUtc()
          : nowParis.subtract(const Duration(days: 30)).toUtc();
      final timeMax = (endDate != null)
          ? tz.TZDateTime(paris, endDate.year, endDate.month, endDate.day,
                  endDate.hour, endDate.minute)
              .toUtc()
          : nowParis.add(const Duration(days: 90)).toUtc();

      final events = await _calendarApi!.events.list(
        GoogleCalendarConfig.calendarId,
        timeMin: timeMin,
        timeMax: timeMax,
        singleEvents: true,
        orderBy: 'startTime',
      );

      return events.items ?? [];
    } catch (e) {
      debugPrint('Erreur récupération événements: $e');
      return [];
    }
  }

  /// Créer un événement depuis une tâche
  Future<void> createEventFromTask(TodoTask tache) async {
    if (tache.dateEcheance == null) return;
    if (_calendarApi == null) {
      final success = await authenticate();
      if (!success) return;
    }

    try {
      // Déterminer la couleur selon les personnes assignées
      String colorId = _getColorIdForTask(tache);

      // Construire la description avec sous-tâches
      String description =
          tache.description.isNotEmpty ? '${tache.description}\n\n' : '';

      if (tache.subTasks.isNotEmpty) {
        description += 'Sous-tâches:\n';
        for (var subTask in tache.subTasks) {
          description +=
              '${subTask.estComplete ? '✓' : '☐'} ${subTask.titre}\n';
        }
        description += '\n';
      }

      description += 'Assigné à: ${tache.assignedTo.join(", ")}';

      // Interpréter la date de la tâche comme étant en Europe/Paris
      tz.initializeTimeZones();
      final paris = tz.getLocation('Europe/Paris');
      final dt = tache.dateEcheance!;
      final tzStart = tz.TZDateTime(
          paris, dt.year, dt.month, dt.day, dt.hour, dt.minute, dt.second);
      final tzEnd = tzStart.add(const Duration(hours: 1));

      final event = calendar.Event()
        ..summary = tache.titre
        ..description = description
        ..start = calendar.EventDateTime(
          // Envoyer l'instant en UTC (Google utilisera timeZone pour l'affichage)
          dateTime: tzStart.toUtc(),
          timeZone: 'Europe/Paris',
        )
        ..end = calendar.EventDateTime(
          dateTime: tzEnd.toUtc(),
          timeZone: 'Europe/Paris',
        )
        ..colorId = colorId
        ..extendedProperties = calendar.EventExtendedProperties()
        ..extendedProperties!.private = {
          'taskId': tache.id,
          'urgence': tache.urgence.toString(),
        };

      await _calendarApi!.events.insert(event, GoogleCalendarConfig.calendarId);
      debugPrint('Événement créé: ${tache.titre}');
    } catch (e) {
      debugPrint('Erreur création événement: $e');
    }
  }

  /// Mettre à jour un événement existant
  Future<void> updateEventFromTask(TodoTask tache) async {
    if (tache.dateEcheance == null) return;
    if (_calendarApi == null) return;

    try {
      // Chercher l'événement existant avec le taskId
      final events = await _calendarApi!.events.list(
        GoogleCalendarConfig.calendarId,
        privateExtendedProperty: ['taskId=${tache.id}'],
      );

      if (events.items == null || events.items!.isEmpty) {
        // L'événement n'existe pas, le créer
        await createEventFromTask(tache);
        return;
      }

      final existingEvent = events.items!.first;
      String colorId = _getColorIdForTask(tache);

      // Construire la description avec sous-tâches
      String description =
          tache.description.isNotEmpty ? '${tache.description}\n\n' : '';

      if (tache.subTasks.isNotEmpty) {
        description += 'Sous-tâches:\n';
        for (var subTask in tache.subTasks) {
          description +=
              '${subTask.estComplete ? '✓' : '☐'} ${subTask.titre}\n';
        }
        description += '\n';
      }

      description += 'Assigné à: ${tache.assignedTo.join(", ")}';

      existingEvent.summary = tache.titre;
      existingEvent.description = description;
      // Interpréter la date comme Europe/Paris et convertir en UTC instant
      tz.initializeTimeZones();
      final paris = tz.getLocation('Europe/Paris');
      final dt = tache.dateEcheance!;
      final tzStart = tz.TZDateTime(
          paris, dt.year, dt.month, dt.day, dt.hour, dt.minute, dt.second);
      final tzEnd = tzStart.add(const Duration(hours: 1));

      existingEvent.start = calendar.EventDateTime(
        dateTime: tzStart.toUtc(),
        timeZone: 'Europe/Paris',
      );
      existingEvent.end = calendar.EventDateTime(
        dateTime: tzEnd.toUtc(),
        timeZone: 'Europe/Paris',
      );
      existingEvent.colorId = colorId;

      await _calendarApi!.events.update(
        existingEvent,
        GoogleCalendarConfig.calendarId,
        existingEvent.id!,
      );
      debugPrint('Événement mis à jour: ${tache.titre}');
    } catch (e) {
      debugPrint('Erreur mise à jour événement: $e');
    }
  }

  /// Supprimer un événement
  Future<void> deleteEventFromTask(String taskId) async {
    if (_calendarApi == null) return;

    try {
      final events = await _calendarApi!.events.list(
        GoogleCalendarConfig.calendarId,
        privateExtendedProperty: ['taskId=$taskId'],
      );

      if (events.items != null && events.items!.isNotEmpty) {
        for (var event in events.items!) {
          await _calendarApi!.events.delete(
            GoogleCalendarConfig.calendarId,
            event.id!,
          );
        }
        debugPrint('Événement supprimé pour taskId: $taskId');
      }
    } catch (e) {
      debugPrint('Erreur suppression événement: $e');
    }
  }

  /// Déterminer la couleur selon les personnes assignées
  String _getColorIdForTask(TodoTask tache) {
    // Google Calendar Color IDs:
    // "10" = Vert (Lou)
    // "4" = Rose/Flamingo (Julien)
    // "6" = Orange (Multiple personnes)

    final hasLou = tache.assignedTo.any((p) => p.toLowerCase() == 'lou');
    final hasJulien = tache.assignedTo.any((p) => p.toLowerCase() == 'julien');

    if (hasLou && hasJulien) {
      return '6'; // Orange - plusieurs personnes
    } else if (hasLou) {
      return '10'; // Vert - Lou uniquement
    } else if (hasJulien) {
      return '4'; // Rose - Julien uniquement
    } else {
      return '8'; // Gris - autres
    }
  }

  /// Récupérer tous les taskIds des événements Calendar actuels
  Future<Set<String>> getAllCalendarTaskIds() async {
    if (_calendarApi == null) return {};

    try {
      final events = await getEvents(
        startDate: DateTime.now().subtract(const Duration(days: 365)),
        endDate: DateTime.now().add(const Duration(days: 365)),
      );

      final taskIds = <String>{};
      for (var event in events) {
        final taskId = event.extendedProperties?.private?['taskId'];
        if (taskId != null) {
          taskIds.add(taskId);
        }
      }

      return taskIds;
    } catch (e) {
      debugPrint('Erreur récupération taskIds depuis Calendar: $e');
      return {};
    }
  }

  /// Se déconnecter
  Future<void> logout() async {
    await _googleSignIn.signOut();
    _calendarApi = null;

    // Effacer l'état de connexion
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('google_calendar_logged_in', false);
  }
}

final googleCalendarService = GoogleCalendarService();
