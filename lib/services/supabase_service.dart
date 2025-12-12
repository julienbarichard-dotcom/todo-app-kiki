import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/supabase_config.dart';

/// Service Supabase - Initialisation et gestion de la connexion
class SupabaseService {
  static final SupabaseService _instance = SupabaseService._internal();
  late SupabaseClient _client;

  factory SupabaseService() {
    return _instance;
  }

  SupabaseService._internal();

  /// Initialiser Supabase
  Future<void> initialize() async {
    await Supabase.initialize(
      url: SupabaseConfig.supabaseUrl,
      anonKey: SupabaseConfig.supabaseAnonKey,
    );
    _client = Supabase.instance.client;
  }

  /// Accéder au client Supabase
  SupabaseClient get client => _client;

  /// Accéder aux tables
  PostgrestQueryBuilder get usersTable => _client.from('users');
  PostgrestQueryBuilder get tasksTable => _client.from('tasks');
}

/// Instance globale pour faciliter l'accès
final supabaseService = SupabaseService();
final supabase = supabaseService.client;
