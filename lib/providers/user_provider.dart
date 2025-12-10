import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart';
import '../models/view_preference.dart';
import '../services/supabase_service.dart';

/// Provider pour gérer les utilisateurs avec Supabase
class UserProvider extends ChangeNotifier {
  /// Liste de tous les utilisateurs
  List<User> _users = [];

  /// Utilisateur actuellement connecté
  User? _currentUser;

  /// Utilisateur admin
  User? _adminUser;

  /// Préférence de vue utilisateur
  ViewPreference _viewPreference = ViewPreference.kanban;

  List<User> get users => _users;
  User? get currentUser => _currentUser;
  User? get adminUser => _adminUser;
  ViewPreference get viewPreference => _viewPreference;
  bool get isLoggedIn => _currentUser != null;
  bool get isCurrentUserAdmin =>
      _currentUser?.isAdmin ?? false; // Use camelCase property

  /// Charger tous les utilisateurs depuis Supabase
  Future<void> loadUsers() async {
    try {
      final response = await supabaseService.usersTable.select();
      _users = (response as List).map((json) => User.fromMap(json)).toList();

      // Trouver l'admin de manière sécurisée
      // _adminUser est nullable, donc on peut lui assigner null si aucun admin n'est trouvé.
      final adminUsers = _users.where((u) => u.isAdmin).toList();
      _adminUser = adminUsers.isNotEmpty ? adminUsers.first : null;

      notifyListeners();
    } catch (e) {
      debugPrint('Erreur lors du chargement des utilisateurs: $e');
    }
  }

  /// Créer un nouvel utilisateur
  Future<void> createUser(String prenom, String password, String? email,
      {bool isAdmin = false}) async {
    try {
      // Vérifier que le prénom n'existe pas
      if (_users.any((u) => u.prenom == prenom)) {
        throw Exception('Ce profil existe déjà');
      }

      // Le premier utilisateur créé est toujours un admin
      final bool isFirstUser = _users.isEmpty;

      final newUser = User(
        id: const Uuid().v4(),
        prenom: prenom,
        email: email,
        dateCreation: DateTime.now(), // Use camelCase property
        passwordHash: User.hashPassword(password), // Use camelCase property
        isAdmin: isFirstUser || isAdmin,
      );

      // Insérer dans Supabase
      await supabaseService.usersTable.insert(newUser.toMap());
      _users.add(newUser); // Mettre à jour l'état local
      notifyListeners(); // Notifier les widgets
    } catch (e) {
      debugPrint('Erreur création user: $e');
      // Propage l'exception pour que l'appelant sache qu'il y a eu une erreur
      throw Exception(e.toString().replaceAll('Exception: ', ''));
    }
  }

  /// Se connecter avec un utilisateur existant
  Future<void> login(User user, String password) async {
    try {
      if (!user.verifyPassword(password)) {
        throw Exception('Mot de passe incorrect');
      }
      _currentUser = user;

      // Sauvegarder la session automatiquement
      await _saveSession(user.id);

      notifyListeners();
    } catch (e) {
      debugPrint('Erreur login: $e');
      // Propage l'exception pour que l'UI puisse l'attraper
      // Utiliser e.toString() pour obtenir le message de n'importe quelle exception.
      throw Exception(e.toString().replaceAll('Exception: ', ''));
    }
  }

  /// Se connecter par ID
  Future<void> loginById(String userId, String password) async {
    try {
      final user = _users.firstWhere((u) => u.id == userId);
      await login(user, password);
    } catch (e) {
      // Si l'utilisateur n'est pas trouvé ou si le login échoue, on propage.
      throw Exception(e.toString().replaceAll('Exception: ', ''));
    }
  }

  /// Se déconnecter
  Future<void> logout() async {
    _currentUser = null;

    // Effacer la session sauvegardée
    await _clearSession();

    notifyListeners();
  }

  /// Changer le mot de passe
  Future<void> changePassword(String oldPassword, String newPassword) async {
    try {
      if (_currentUser == null) {
        throw Exception('Aucun utilisateur n\'est connecté.');
      }
      if (!_currentUser!.verifyPassword(oldPassword)) {
        throw Exception('L\'ancien mot de passe est incorrect.');
      }

      final updatedUser = _currentUser!.copyWith(
        passwordHash: User.hashPassword(newPassword), // Use camelCase property
      );

      // Mettre à jour dans Supabase
      await supabaseService.usersTable
          .update(updatedUser.toMap())
          .eq('id', _currentUser!.id);

      final index = _users.indexWhere((u) => u.id == _currentUser!.id);
      if (index == -1) {
        // Cas peu probable, mais gérons-le
        throw Exception(
            'L\'utilisateur n\'a pas été trouvé dans la liste locale.');
      }
      _users[index] = updatedUser;
      _currentUser = updatedUser;
      if (_adminUser?.id == _currentUser!.id) {
        _adminUser = updatedUser;
      }
      notifyListeners();
    } catch (e) {
      debugPrint('Erreur changement mdp: $e');
      throw Exception(e.toString().replaceAll('Exception: ', ''));
    }
  }

  /// Admin : réinitialiser mot de passe
  Future<void> adminResetPassword(
      String targetUserId, String newPassword) async {
    try {
      if (!isCurrentUserAdmin) {
        throw Exception(
            'Action non autorisée. Seul un admin peut réinitialiser un mot de passe.');
      }

      final index = _users.indexWhere((u) => u.id == targetUserId);
      if (index == -1) {
        throw Exception('Utilisateur cible non trouvé.');
      }

      final updatedUser = _users[index].copyWith(
        passwordHash: User.hashPassword(newPassword), // Use camelCase property
      );

      // Mettre à jour dans Supabase
      await supabaseService.usersTable
          .update(updatedUser.toMap())
          .eq('id', targetUserId);

      _users[index] = updatedUser;
      notifyListeners();
    } catch (e) {
      debugPrint('Erreur reset mdp admin: $e');
      throw Exception(e.toString().replaceAll('Exception: ', ''));
    }
  }

  /// Admin : débloquer un utilisateur
  Future<void> adminUnlockUser(String targetUserId) async {
    // Le mot de passe par défaut lors du déblocage est '1234'
    await adminResetPassword(targetUserId, '1234');
  }

  /// Obtenir un utilisateur par ID
  User? getUserById(String id) {
    try {
      return _users.firstWhere((u) => u.id == id);
    } catch (_) {
      return null;
    }
  }

  /// Sauvegarder la session dans SharedPreferences
  Future<void> _saveSession(String userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('logged_user_id', userId);
      debugPrint('✅ Session utilisateur sauvegardée: $userId');
    } catch (e) {
      debugPrint('⚠️ Erreur sauvegarde session: $e');
    }
  }

  /// Effacer la session sauvegardée
  Future<void> _clearSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('logged_user_id');
      debugPrint('✅ Session utilisateur effacée');
    } catch (e) {
      debugPrint('⚠️ Erreur effacement session: $e');
    }
  }

  /// Tenter de restaurer la session automatiquement
  Future<bool> tryRestoreSession() async {
    try {
      debugPrint('🔄 Tentative de restauration de session utilisateur...');

      final prefs = await SharedPreferences.getInstance();
      final savedUserId = prefs.getString('logged_user_id');

      if (savedUserId == null) {
        debugPrint('ℹ️ Aucune session utilisateur sauvegardée');
        return false;
      }

      // Chercher l'utilisateur dans la liste chargée
      final user = getUserById(savedUserId);

      if (user == null) {
        debugPrint('⚠️ Utilisateur sauvegardé introuvable: $savedUserId');
        await _clearSession();
        return false;
      }

      // Restaurer la session sans demander le mot de passe
      _currentUser = user;
      await _loadViewPreference(); // Charger la préférence de vue persistée
      notifyListeners();

      debugPrint('✅ Session utilisateur restaurée: ${user.prenom}');
      return true;
    } catch (e) {
      debugPrint('❌ Erreur restauration session utilisateur: $e');
      return false;
    }
  }

  /// Charger la préférence de vue sauvegardée
  Future<void> _loadViewPreference() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final viewString = prefs.getString('user_view_preference');
      _viewPreference = ViewPreferenceExtension.fromStorageString(viewString);
      debugPrint('📺 Vue chargée: ${_viewPreference.label}');
    } catch (e) {
      debugPrint('⚠️ Erreur chargement préférence de vue: $e');
      _viewPreference = ViewPreference.kanban; // Défaut
    }
  }

  /// Sauvegarder la préférence de vue
  Future<void> setViewPreference(ViewPreference view) async {
    try {
      _viewPreference = view;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user_view_preference', view.toStorageString());
      debugPrint('💾 Vue sauvegardée: ${view.label}');
      notifyListeners();
    } catch (e) {
      debugPrint('❌ Erreur sauvegarde préférence de vue: $e');
    }
  }

  /// Réinitialiser la vue à la valeur par défaut
  Future<void> resetViewPreference() async {
    await setViewPreference(ViewPreference.kanban);
  }
}
