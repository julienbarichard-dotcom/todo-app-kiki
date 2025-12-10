/// Fichier "aiguilleur" qui exporte la bonne implémentation du service
/// en fonction de la plateforme (mobile ou web).
library;

export 'notification_service_mobile.dart'
    if (dart.library.html) 'notification_service_web.dart';
