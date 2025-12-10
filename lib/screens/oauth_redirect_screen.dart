import 'package:flutter/material.dart';
import 'calendar_screen.dart';

/// Écran de redirection après OAuth
class OAuthRedirectScreen extends StatefulWidget {
  const OAuthRedirectScreen({super.key});

  @override
  State<OAuthRedirectScreen> createState() => _OAuthRedirectScreenState();
}

class _OAuthRedirectScreenState extends State<OAuthRedirectScreen> {
  @override
  void initState() {
    super.initState();
    _handleOAuthCallback();
  }

  Future<void> _handleOAuthCallback() async {
    // Attendre un peu pour que le widget soit monté
    await Future.delayed(const Duration(milliseconds: 500));

    if (!mounted) return;

    // Ne PAS appeler checkExistingToken ici, laisser CalendarScreen le faire
    // Naviguer directement vers le calendrier
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const CalendarScreen()),
      (route) => false, // Supprimer toutes les routes précédentes
    );
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Color(0xFF121212),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              color: Color(0xFF1DB679),
            ),
            SizedBox(height: 24),
            Text(
              'Authentification...',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
