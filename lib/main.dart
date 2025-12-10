import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:intl/date_symbol_data_local.dart';
import 'providers/todo_provider.dart';
import 'providers/user_provider.dart';
import 'providers/outings_provider.dart';
import 'screens/splash_screen_clean.dart';
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';
import 'services/supabase_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialiser les locales pour les dates en français
  await initializeDateFormatting('fr_FR', null);

  // Initialiser la base de données des timezones
  tz.initializeTimeZones();
  // Définir Europe/Paris comme timezone locale
  tz.setLocalLocation(tz.getLocation('Europe/Paris'));

  // Initialiser Supabase
  await supabaseService.initialize();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Couleur vert mint personnalisée
    const Color mintGreen = Color(0xFF1DB679);

    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => UserProvider()),
        ChangeNotifierProvider(create: (_) => TodoProvider()),
        ChangeNotifierProvider(create: (_) => OutingsProvider()),
      ],
      child: MaterialApp(
        title: 'Todo des Kiki\'s',
        theme: ThemeData(
          useMaterial3: true,
          brightness: Brightness.light,
          primarySwatch: Colors.green,
          colorScheme: ColorScheme.fromSeed(
            seedColor: mintGreen,
            brightness: Brightness.light,
          ),
        ),
        darkTheme: ThemeData(
          useMaterial3: true,
          brightness: Brightness.dark,
          primarySwatch: Colors.green,
          colorScheme: ColorScheme.fromSeed(
            seedColor: mintGreen,
            brightness: Brightness.dark,
          ),
          scaffoldBackgroundColor: const Color(0xFF121212),
          appBarTheme: const AppBarTheme(
            backgroundColor: Color(0xFF1E1E1E),
            elevation: 4,
          ),
          cardTheme: const CardThemeData(
            color: Color(0xFF1E1E1E),
          ),
        ),
        themeMode: ThemeMode.dark, // Force dark mode
        home: const SplashScreen(),
        routes: {
          '/login': (context) => const AuthWrapper(),
          '/home': (context) => const HomeScreen(),
        },
      ),
    );
  }
}

/// Widget qui gère l'initialisation des données et la redirection
class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  late Future<void> _initializationFuture;

  @override
  void initState() {
    super.initState();
    // Charger les utilisateurs ET tenter de restaurer la session
    _initializationFuture = _initializeApp();
  }

  Future<void> _initializeApp() async {
    final userProvider = context.read<UserProvider>();

    // 1. Charger tous les utilisateurs depuis Supabase
    await userProvider.loadUsers();

    // 2. Tenter de restaurer la session automatiquement
    final restored = await userProvider.tryRestoreSession();

    if (restored) {
      // Si session restaurée, rediriger vers Home
      if (mounted) {
        Navigator.of(context).pushReplacementNamed('/home');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: _initializationFuture,
      builder: (context, snapshot) {
        // Si les données sont chargées, on affiche le LoginScreen
        if (snapshot.connectionState == ConnectionState.done) {
          return const LoginScreen();
        }
        // Sinon, on affiche un indicateur de chargement
        return const Scaffold(
          body: Center(child: CircularProgressIndicator()),
        );
      },
    );
  }
}
