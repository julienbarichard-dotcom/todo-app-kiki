import 'package:crypto/crypto.dart';
import 'dart:convert';

/// Modèle pour un utilisateur avec authentification par mot de passe
class User {
  final String id;
  final String prenom;
  final String? email; // Email pour les notifications
  final DateTime dateCreation;
  final String passwordHash; // Hash du mot de passe (sha256)
  final bool isAdmin; // Flag pour l'accès admin

  User({
    required this.id,
    required this.prenom,
    this.email,
    required this.dateCreation,
    required this.passwordHash,
    this.isAdmin = false,
  });

  /// Créer un hash du mot de passe
  static String hashPassword(String password) {
    return sha256.convert(utf8.encode(password)).toString();
  }

  /// Vérifier si le mot de passe fourni correspond
  bool verifyPassword(String password) {
    return passwordHash == hashPassword(password);
  }

  /// Convertir en dictionnaire (pour Supabase)
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'prenom': prenom,
      'email': email,
      'date_creation': dateCreation.toIso8601String(),
      'password_hash': passwordHash,
      'is_admin': isAdmin,
    };
  }

  /// Créer un utilisateur depuis un dictionnaire
  factory User.fromMap(Map<String, dynamic> map) {
    return User(
      id: map['id'] ?? '',
      prenom: map['prenom'] ?? '',
      email: map['email'],
      dateCreation: map['date_creation'] != null
          ? DateTime.parse(map['date_creation'])
          : DateTime.now(),
      passwordHash: map['password_hash'] ?? '',
      isAdmin: map['is_admin'] ?? false,
    );
  }

  /// Copier avec modifications
  User copyWith({
    String? id,
    String? prenom,
    String? email,
    DateTime? dateCreation,
    String? passwordHash,
    bool? isAdmin,
  }) {
    return User(
      id: id ?? this.id,
      prenom: prenom ?? this.prenom,
      email: email ?? this.email,
      dateCreation: dateCreation ?? this.dateCreation,
      passwordHash: passwordHash ?? this.passwordHash,
      isAdmin: isAdmin ?? this.isAdmin,
    );
  }

  @override
  String toString() => 'User(id: $id, prenom: , isAdmin: )';
}
