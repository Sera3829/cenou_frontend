import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';
import 'register_screen.dart';

/// Écran de connexion permettant à l'utilisateur de s'authentifier.
class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _identifiantController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isPasswordVisible = false;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _identifiantController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  /// Gère la tentative de connexion.
  Future<void> _handleLogin() async {
    print('=== DEBUT _handleLogin ===');
    print('mounted au debut: $mounted');

    final identifiant = _identifiantController.text.trim();
    final password = _passwordController.text;

    if (identifiant.isEmpty) {
      setState(() => _errorMessage = 'Veuillez entrer votre identifiant');
      return;
    }

    if (password.isEmpty) {
      setState(() => _errorMessage = 'Veuillez entrer votre mot de passe');
      return;
    }

    // Fermer le clavier avant l'appel API
    FocusScope.of(context).unfocus();

    // Attendre que le clavier se ferme
    await Future.delayed(const Duration(milliseconds: 100));

    print('mounted apres fermeture clavier: $mounted');

    if (!mounted) {
      print('Widget deja demonte avant setState');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    print('setState isLoading=true fait');

    try {
      print('Recuperation AuthProvider...');
      final authProvider = Provider.of<AuthProvider>(context, listen: false);

      print('Appel authProvider.login()...');
      final success = await authProvider.login(identifiant, password);

      print('Login termine avec success=$success');
      print('mounted apres login: $mounted');

      if (!mounted) {
        print('Widget demonte apres login');
        return;
      }

      if (success) {
        print('SUCCESS - Navigation');
        // Utiliser pushReplacement de manière plus sûre
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            Navigator.pushReplacementNamed(context, '/home');
          }
        });
      } else {
        print('ECHEC - Traitement erreur');
        final error = authProvider.errorMessage ?? 'Erreur de connexion';

        print('ErrorMessage du provider: $error');

        // setState dans un addPostFrameCallback
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            setState(() {
              _errorMessage = error;
            });
            print('setState errorMessage fait: $_errorMessage');

            // SnackBar
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Row(
                  children: [
                    const Icon(Icons.error_outline, color: Colors.white),
                    const SizedBox(width: 12),
                    Expanded(child: Text(error)),
                  ],
                ),
                backgroundColor: Colors.red,
                duration: const Duration(seconds: 5),
                behavior: SnackBarBehavior.floating,
              ),
            );
            print('SnackBar affiche');

            // Dialog si compte désactivé
            if (error.contains('désactivé') || error.contains('suspendu')) {
              print('Affichage dialog compte desactive');
              Future.delayed(const Duration(milliseconds: 300), () {
                if (mounted) {
                  _showAccountDisabledDialog();
                }
              });
            }
          }
        });
      }
    } catch (e, stack) {
      print('EXCEPTION dans _handleLogin: $e');
      print('Stack trace: $stack');

      if (mounted) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            setState(() {
              _errorMessage = 'Erreur: $e';
            });
          }
        });
      }
    } finally {
      print('Finally block');
      print('mounted dans finally: $mounted');

      if (mounted) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            setState(() => _isLoading = false);
            print('setState isLoading=false fait');
          }
        });
      }
    }

    print('=== FIN _handleLogin ===');
  }

  /// Affiche une boîte de dialogue informant que le compte est désactivé.
  void _showAccountDisabledDialog() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? Color(0xFF1E1E1E) : Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(isDark ? 0.2 : 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.block,
                color: isDark ? Colors.orange.shade300 : Colors.orange,
                size: 28,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Compte désactivé',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.orange.shade300 : Colors.orange,
                ),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Votre compte a été désactivé ou suspendu.',
              style: TextStyle(
                fontSize: 16,
                color: isDark ? Colors.grey.shade300 : Colors.black87,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(isDark ? 0.2 : 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Colors.orange.withOpacity(isDark ? 0.4 : 0.3),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: isDark ? Colors.orange.shade300 : Colors.orange,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Contactez l\'administration pour réactiver votre compte.',
                      style: TextStyle(
                        fontSize: 13,
                        color: isDark ? Colors.orange.shade300 : Colors.orange.shade700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'J\'ai compris',
              style: TextStyle(
                color: isDark ? Colors.blue.shade300 : AppTheme.primaryColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    print('BUILD - errorMessage: $_errorMessage, isLoading: $_isLoading');

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? Color(0xFF121212) : Colors.white,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Logo CENOU avec débordement
                Stack(
                  alignment: Alignment.center,
                  clipBehavior: Clip.none,
                  children: [
                    // Cercle de fond
                    Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        color: (isDark ? Colors.blue.shade700 : AppTheme.primaryColor)
                            .withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                    ),
                    // Image qui déborde
                    Positioned(
                      child: Image.asset(
                        'assets/images/logo_cenou.png',
                        width: 110,
                        height: 140,
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) {
                          return Icon(
                            Icons.school_rounded,
                            size: 70,
                            color: isDark ? Colors.blue.shade300 : AppTheme.primaryColor,
                          );
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Text(
                  'Bienvenue',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : AppTheme.primaryColor,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Veuillez vous connecter',
                  style: TextStyle(
                    fontSize: 16,
                    color: isDark ? Colors.grey.shade400 : Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 40),

                // Champ Identifiant
                CustomTextField(
                  controller: _identifiantController,
                  label: 'Matricule ou Email',
                  hint: 'Entrez votre matricule',
                  prefixIcon: Icons.person_outline,
                  enabled: !_isLoading,
                  onChanged: (_) {
                    if (_errorMessage != null) {
                      setState(() => _errorMessage = null);
                    }
                  },
                ),
                const SizedBox(height: 16),

                // Champ Mot de passe
                CustomTextField(
                  controller: _passwordController,
                  label: 'Mot de passe',
                  hint: 'Entrez votre mot de passe',
                  prefixIcon: Icons.lock_outline,
                  obscureText: !_isPasswordVisible,
                  enabled: !_isLoading,
                  onChanged: (_) {
                    if (_errorMessage != null) {
                      setState(() => _errorMessage = null);
                    }
                  },
                  suffixIcon: IconButton(
                    icon: Icon(
                      _isPasswordVisible
                          ? Icons.visibility
                          : Icons.visibility_off,
                      color: isDark ? Colors.grey.shade400 : null,
                    ),
                    onPressed: () {
                      setState(() => _isPasswordVisible = !_isPasswordVisible);
                    },
                  ),
                ),
                const SizedBox(height: 24),

                // Bouton
                CustomButton(
                  text: 'SE CONNECTER',
                  onPressed: _isLoading ? null : _handleLogin,
                  isLoading: _isLoading,
                ),
                const SizedBox(height: 24),

                // Lien inscription
                Wrap(
                  alignment: WrapAlignment.center,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 4,
                  children: [
                    Text(
                      'Pas encore de compte ?',
                      style: TextStyle(
                        color: isDark ? Colors.grey.shade400 : Colors.grey[600],
                        fontSize: 14,
                      ),
                    ),
                    TextButton(
                      onPressed: _isLoading
                          ? null
                          : () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const RegisterScreen(),
                          ),
                        );
                      },
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: Text(
                        'Créer un compte',
                        style: TextStyle(
                          color: isDark ? Colors.blue.shade300 : AppTheme.primaryColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}