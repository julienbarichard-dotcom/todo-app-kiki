import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../utils/color_extensions.dart';
import '../providers/user_provider.dart';

/// Écran de connexion/inscription avec authentification par mot de passe
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  static const Color mintGreen = Color(0xFF1DB679);

  final _passwordController = TextEditingController();
  final _prenomController = TextEditingController();
  final _emailController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  String? _selectedUserId;
  bool _obscurePassword = true;
  bool _obscureNewPassword = true;
  bool _obscureConfirmPassword = true;
  String? _errorMessage;
  bool _isCreatingNewUser = false;

  @override
  void dispose() {
    _passwordController.dispose();
    _prenomController.dispose();
    _emailController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _login() async {
    if (_selectedUserId == null || _passwordController.text.isEmpty) {
      setState(() => _errorMessage = 'Veuillez remplir tous les champs');
      return;
    }

    final userProvider = context.read<UserProvider>();
    final user = userProvider.getUserById(_selectedUserId!);

    if (user == null) {
      setState(() => _errorMessage = 'Utilisateur non trouvé');
      return;
    }

    try {
      await userProvider.login(user, _passwordController.text);
      _passwordController.clear();
      if (mounted) {
        setState(() => _errorMessage = null);
        Navigator.of(context).pushReplacementNamed('/home');
      }
    } on Exception catch (e) {
      setState(
          () => _errorMessage = e.toString().replaceAll('Exception: ', ''));
    }
  }

  void _createNewUser() async {
    if (_prenomController.text.isEmpty || _newPasswordController.text.isEmpty) {
      setState(() => _errorMessage = 'Veuillez remplir tous les champs');
      return;
    }

    if (_newPasswordController.text != _confirmPasswordController.text) {
      setState(() => _errorMessage = 'Les mots de passe ne correspondent pas');
      return;
    }

    if (_newPasswordController.text.length < 4) {
      setState(() => _errorMessage =
          'Le mot de passe doit contenir au moins 4 caractères');
      return;
    }

    try {
      final userProvider = context.read<UserProvider>();
      await userProvider.createUser(
        _prenomController.text,
        _newPasswordController.text,
        _emailController.text.isEmpty ? null : _emailController.text,
      );

      // La création a réussi, on peut rafraîchir l'interface
      // Le provider a déjà notifié les listeners, donc le Consumer reconstruira.
      // On peut juste fermer le mode création.

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content:
                  Text('Profil "${_prenomController.text}" créé avec succès')),
        );

        _prenomController.clear();
        _emailController.clear();
        _newPasswordController.clear();
        _confirmPasswordController.clear();
        setState(() {
          _isCreatingNewUser = false;
          _errorMessage = null;
        });
      }
    } catch (e) {
      setState(
          () => _errorMessage = e.toString().replaceAll('Exception: ', ''));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Todo App - Authentification'),
      ),
      body: Consumer<UserProvider>(
        builder: (context, userProvider, child) {
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              const SizedBox(height: 32),

              // Titre
              Center(
                child: Text(
                  'Todo des Kiki\'s',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        color: mintGreen,
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ),
              const SizedBox(height: 48),

              if (!_isCreatingNewUser) ...[
                // Écran de connexion
                Text(
                  'Connexion',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 16),

                if (userProvider.users.isEmpty)
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Center(
                      child: Text(
                        'Aucun profil existant.\nVeuillez créer un nouveau profil.',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                    ),
                  )
                else ...[
                  // Sélection de l'utilisateur
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Sélectionnez votre profil',
                            style: Theme.of(context).textTheme.labelLarge,
                          ),
                          const SizedBox(height: 8),
                          DropdownButton<String>(
                            value: _selectedUserId,
                            isExpanded: true,
                            hint: const Text('Choisir un profil'),
                            items: userProvider.users.map((user) {
                              return DropdownMenuItem(
                                value: user.id,
                                child: Row(
                                  children: [
                                    const Icon(Icons.account_circle),
                                    const SizedBox(width: 8),
                                    Text(user.prenom),
                                    if (user.isAdmin) // Use user.isAdmin
                                      Padding(
                                        padding: const EdgeInsets.only(left: 8),
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: mintGreen,
                                            borderRadius:
                                                BorderRadius.circular(4),
                                          ),
                                          child: const Text(
                                            'Admin',
                                            style: TextStyle(
                                                color: Colors.white,
                                                fontSize: 10),
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              );
                            }).toList(),
                            onChanged: (value) {
                              setState(() => _selectedUserId = value);
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Champ mot de passe
                  TextFormField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    decoration: InputDecoration(
                      labelText: 'Mot de passe',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      prefixIcon: const Icon(Icons.lock),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility_off
                              : Icons.visibility,
                        ),
                        onPressed: () {
                          setState(() => _obscurePassword = !_obscurePassword);
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Message d'erreur
                  if (_errorMessage != null)
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacitySafe(0.2),
                        border: Border.all(color: Colors.red),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        _errorMessage!,
                        style: const TextStyle(color: Colors.red),
                      ),
                    ),
                  const SizedBox(height: 16),

                  // Bouton connexion
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: mintGreen,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    onPressed: _login,
                    child: const Text(
                      'Connexion',
                      style: TextStyle(fontSize: 16, color: Colors.white),
                    ),
                  ),
                ],
                const SizedBox(height: 24),

                // Bouton créer nouveau profil
                TextButton.icon(
                  icon: const Icon(Icons.person_add),
                  label: const Text('Créer un nouveau profil'),
                  onPressed: () {
                    setState(() {
                      _isCreatingNewUser = true;
                      _errorMessage = null;
                    });
                  },
                ),
              ] else ...[
                // Écran de création de profil
                Text(
                  'Créer un nouveau profil',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 16),

                // Prénom
                TextFormField(
                  controller: _prenomController,
                  decoration: InputDecoration(
                    labelText: 'Prénom',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    prefixIcon: const Icon(Icons.person),
                  ),
                ),
                const SizedBox(height: 16),

                // Email (optionnel)
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    labelText: 'Email (optionnel)',
                    hintText: 'Pour recevoir les emails de récap',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    prefixIcon: const Icon(Icons.email),
                  ),
                ),
                const SizedBox(height: 16),

                // Mot de passe
                TextFormField(
                  controller: _newPasswordController,
                  obscureText: _obscureNewPassword,
                  decoration: InputDecoration(
                    labelText: 'Mot de passe',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    prefixIcon: const Icon(Icons.lock),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscureNewPassword
                            ? Icons.visibility_off
                            : Icons.visibility,
                      ),
                      onPressed: () {
                        setState(
                            () => _obscureNewPassword = !_obscureNewPassword);
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Confirmer mot de passe
                TextFormField(
                  controller: _confirmPasswordController,
                  obscureText: _obscureConfirmPassword,
                  decoration: InputDecoration(
                    labelText: 'Confirmer le mot de passe',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscureConfirmPassword
                            ? Icons.visibility_off
                            : Icons.visibility,
                      ),
                      onPressed: () {
                        setState(() =>
                            _obscureConfirmPassword = !_obscureConfirmPassword);
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Message d'erreur
                if (_errorMessage != null)
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacitySafe(0.2),
                      border: Border.all(color: Colors.red),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      _errorMessage!,
                      style: const TextStyle(color: Colors.red),
                    ),
                  ),
                const SizedBox(height: 16),

                // Boutons
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.grey,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        onPressed: () {
                          setState(() {
                            _isCreatingNewUser = false;
                            _prenomController.clear();
                            _emailController.clear();
                            _newPasswordController.clear();
                            _confirmPasswordController.clear();
                            _errorMessage = null;
                          });
                        },
                        child: const Text(
                          'Annuler',
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: mintGreen,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        onPressed: _createNewUser,
                        child: const Text(
                          'Créer',
                          style: TextStyle(fontSize: 16, color: Colors.white),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}
