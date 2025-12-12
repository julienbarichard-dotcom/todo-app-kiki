import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../models/user.dart';

/// Provider pour gérer les utilisateurs et la session actuelle avec authentification
class UserProvider extends ChangeNotifier {
  /// Liste de tous les utilisateurs créés
  List<User> _users = [];

  /// Utilisateur actuellement connecté
  User? _currentUser;

  /// Utilisateur admin (premier créé ou marqué comme admin)
  User? _adminUser;

  List<User> get users => _users;
  User? get currentUser => _currentUser;
  User? get adminUser => _adminUser;
  bool get isLoggedIn => _currentUser != null;
  bool get isCurrentUserAdmin => _currentUser?.isAdmin ?? false;

  /// Créer un nouvel utilisateur avec mot de passe
  void createUser(String prenom, String password, {bool isAdmin = false}) {
    // Vérifier que le prénom n'existe pas déjà
    if (_users.any((u) => u.prenom == prenom)) {
      throw Exception('Ce profil existe déjà');
    }

    final newUser = User(
      id: const Uuid().v4(),
      prenom: prenom,
      dateCreation: DateTime.now(),
      passwordHash: User.hashPassword(password),
      isAdmin: isAdmin,
    );
    _users.add(newUser);

    // Le premier utilisateur créé devient admin
    if (_adminUser == null && _users.length == 1) {
      _adminUser = newUser;
      _users[0] = newUser.copyWith(isAdmin: true);
      _adminUser = _users[0];
    }

    notifyListeners();
  }

  /// Se connecter avec un utilisateur existant
  bool login(User user, String password) {
    if (!user.verifyPassword(password)) {
      return false; // Mot de passe incorrect
    }
    _currentUser = user;
    notifyListeners();
    return true;
  }

  /// Se connecter par ID (après vérification du mot de passe)
  bool loginById(String userId, String password) {
    try {
      final user = _users.firstWhere((u) => u.id == userId);
      return login(user, password);
    } catch (e) {
      return false;
    }
  }

  /// Se déconnecter
  void logout() {
    _currentUser = null;
    notifyListeners();
  }

  /// Changer le mot de passe de l'utilisateur actuel
  bool changePassword(String oldPassword, String newPassword) {
    if (_currentUser == null) return false;

    if (!_currentUser!.verifyPassword(oldPassword)) {
      return false; // Ancien mot de passe incorrect
    }

    final updatedUser = _currentUser!.copyWith(
      passwordHash: User.hashPassword(newPassword),
    );

    final index = _users.indexWhere((u) => u.id == _currentUser!.id);
    if (index != -1) {
      _users[index] = updatedUser;
      _currentUser = updatedUser;

      // Mettre à jour adminUser si c'est l'admin
      if (_adminUser?.id == _currentUser!.id) {
        _adminUser = updatedUser;
      }

      notifyListeners();
      return true;
    }
    return false;
  }

  /// Admin : réinitialiser le mot de passe d'un utilisateur
  bool adminResetPassword(String targetUserId, String newPassword) {
    if (_currentUser == null || !_currentUser!.isAdmin) {
      return false; // Pas admin
    }

    final index = _users.indexWhere((u) => u.id == targetUserId);
    if (index == -1) return false;

    _users[index] = _users[index].copyWith(
      passwordHash: User.hashPassword(newPassword),
    );

    notifyListeners();
    return true;
  }

  /// Admin : débloquer un utilisateur (réinitialiser à un mot de passe par défaut)
  bool adminUnlockUser(String targetUserId) {
    return adminResetPassword(targetUserId, '1234'); // Mot de passe temporaire
  }

  /// Charger les utilisateurs (depuis Firebase/Hive)
  void loadUsers(List<User> users) {
    _users = users;
    _adminUser = null;
    for (var user in _users) {
      if (user.isAdmin) {
        _adminUser = user;
        break;
      }
    }
    if (_adminUser == null && _users.isNotEmpty) {
      _adminUser = _users.first;
    }
    notifyListeners();
  }

  /// Obtenir un utilisateur par ID
  User? getUserById(String id) {
    try {
      return _users.firstWhere((u) => u.id == id);
    } catch (e) {
      return null;
    }
  }

  /// Initialiser avec des données de test (Lou et Julien avec mdp 2008)
  void initializeTestData() {
    if (_users.isEmpty) {
      createUser('Lou', '2008', isAdmin: true); // Premier = admin
      createUser('Julien', '2008');
    }
  }
}
