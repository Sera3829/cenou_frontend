import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/auth_provider.dart';

/// Écran de connexion pour l'administration web.
class AdminLoginScreen extends StatefulWidget {
  const AdminLoginScreen({super.key});

  @override
  State<AdminLoginScreen> createState() => _AdminLoginScreenState();
}

class _AdminLoginScreenState extends State<AdminLoginScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _identifiantController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _rememberMe = false;

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.2),
      end: Offset.zero,
    ).animate(
        CurvedAnimation(parent: _animationController, curve: Curves.easeOutCubic));

    _animationController.forward();
  }

  @override
  void dispose() {
    _identifiantController.dispose();
    _passwordController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final size = MediaQuery.of(context).size;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: Container(
        width: size.width,
        height: size.height,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDark
                ? [
              const Color(0xFF0D1117), // Noir bleuté
              const Color(0xFF161B22), // Gris très foncé
              const Color(0xFF1C2128), // Gris foncé
            ]
                : [
              const Color(0xFF1a237e), // Indigo foncé
              const Color(0xFF283593), // Indigo
              const Color(0xFF3949ab), // Indigo clair
            ],
          ),
        ),
        child: Stack(
          children: [
            /// Effets de fond subtils.
            _buildBackgroundEffects(isDark),

            /// Contenu principal centré.
            Center(
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: SlideTransition(
                  position: _slideAnimation,
                  child: _buildLoginCard(authProvider, size, isDark),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Construit les éléments graphiques de fond.
  Widget _buildBackgroundEffects(bool isDark) {
    return Stack(
      children: [
        /// Cercle lumineux en haut à droite.
        Positioned(
          top: -100,
          right: -100,
          child: Container(
            width: 300,
            height: 300,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  Colors.white.withOpacity(isDark ? 0.05 : 0.1),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),

        /// Cercle lumineux en bas à gauche.
        Positioned(
          bottom: -150,
          left: -150,
          child: Container(
            width: 400,
            height: 400,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  Colors.white.withOpacity(isDark ? 0.03 : 0.08),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// Construit la carte de connexion.
  Widget _buildLoginCard(AuthProvider authProvider, Size size, bool isDark) {
    final isMobile = size.width < 600;
    final cardWidth = isMobile ? size.width * 0.9 : 450.0;

    return Container(
      width: cardWidth,
      padding: EdgeInsets.all(isMobile ? 32 : 48),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.5 : 0.3),
            blurRadius: 40,
            offset: const Offset(0, 20),
          ),
        ],
      ),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              /// Logo CENOU
              Center(
                child: SizedBox(
                  width: 120,
                  height: 120,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      /// Cercle de fond.
                      Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          color: (isDark
                              ? const Color(0xFF3949ab)
                              : const Color(0xFF1a237e))
                              .withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                      ),

                      /// Logo qui déborde légèrement.
                      Positioned(
                        child: Image.asset(
                          'assets/images/logo_cenou.png',
                          width: 110,
                          height: 140,
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) {
                            return Icon(
                              Icons.admin_panel_settings_rounded,
                              size: 70,
                              color: isDark
                                  ? Colors.blue.shade300
                                  : const Color(0xFF1a237e),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 32),

              /// Titre
              Text(
                'Connexion Administrateur',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : const Color(0xFF1a237e),
                ),
              ),

              const SizedBox(height: 8),

              Text(
                'Accédez au tableau de bord',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: isDark ? Colors.grey.shade400 : Colors.grey[600],
                ),
              ),

              const SizedBox(height: 32),

              /// Message d'erreur
              if (authProvider.errorMessage != null) ...[
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: isDark
                        ? Colors.red[900]!.withOpacity(0.3)
                        : Colors.red[50],
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isDark ? Colors.red[700]! : Colors.red[200]!,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.error_outline,
                        color: isDark ? Colors.red[300] : Colors.red[700],
                        size: 20,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          authProvider.errorMessage!,
                          style: TextStyle(
                            color: isDark ? Colors.red[300] : Colors.red[700],
                            fontSize: 13,
                          ),
                        ),
                      ),
                      GestureDetector(
                        onTap: () => authProvider.clearError(),
                        child: Icon(
                          Icons.close,
                          color: isDark ? Colors.red[300] : Colors.red[700],
                          size: 18,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
              ],

              /// Champ identifiant.
              TextFormField(
                controller: _identifiantController,
                style: TextStyle(
                  fontSize: 15,
                  color: isDark ? Colors.white : Colors.black87,
                ),
                decoration: InputDecoration(
                  labelText: 'Identifiant ou Email',
                  labelStyle: TextStyle(
                    color: isDark ? Colors.grey.shade400 : Colors.grey.shade700,
                  ),
                  prefixIcon: Icon(
                    Icons.person_rounded,
                    color: isDark ? Colors.blue.shade300 : const Color(0xFF1a237e),
                  ),
                  filled: true,
                  fillColor: isDark ? const Color(0xFF2D2D2D) : Colors.grey[50],
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: isDark ? Colors.grey[700]! : Colors.grey[300]!,
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: isDark ? Colors.grey[700]! : Colors.grey[300]!,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: isDark ? Colors.blue.shade300 : const Color(0xFF1a237e),
                      width: 2,
                    ),
                  ),
                  errorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: isDark ? Colors.red[400]! : Colors.red[400]!,
                    ),
                  ),
                  focusedErrorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: isDark ? Colors.red[400]! : Colors.red[400]!,
                      width: 2,
                    ),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Identifiant requis';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 20),

              /// Champ mot de passe.
              TextFormField(
                controller: _passwordController,
                obscureText: _obscurePassword,
                style: TextStyle(
                  fontSize: 15,
                  color: isDark ? Colors.white : Colors.black87,
                ),
                decoration: InputDecoration(
                  labelText: 'Mot de passe',
                  labelStyle: TextStyle(
                    color: isDark ? Colors.grey.shade400 : Colors.grey.shade700,
                  ),
                  prefixIcon: Icon(
                    Icons.lock_rounded,
                    color: isDark ? Colors.blue.shade300 : const Color(0xFF1a237e),
                  ),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility_off_rounded
                          : Icons.visibility_rounded,
                      color: isDark ? Colors.grey.shade400 : Colors.grey[600],
                    ),
                    onPressed: () =>
                        setState(() => _obscurePassword = !_obscurePassword),
                  ),
                  filled: true,
                  fillColor: isDark ? const Color(0xFF2D2D2D) : Colors.grey[50],
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: isDark ? Colors.grey[700]! : Colors.grey[300]!,
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: isDark ? Colors.grey[700]! : Colors.grey[300]!,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: isDark ? Colors.blue.shade300 : const Color(0xFF1a237e),
                      width: 2,
                    ),
                  ),
                  errorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: isDark ? Colors.red[400]! : Colors.red[400]!,
                    ),
                  ),
                  focusedErrorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: isDark ? Colors.red[400]! : Colors.red[400]!,
                      width: 2,
                    ),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Mot de passe requis';
                  }
                  if (value.length < 6) {
                    return 'Minimum 6 caractères';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 16),

              /// Se souvenir + Mot de passe oublié.
              Row(
                children: [
                  SizedBox(
                    height: 20,
                    width: 20,
                    child: Checkbox(
                      value: _rememberMe,
                      onChanged: (value) =>
                          setState(() => _rememberMe = value ?? false),
                      activeColor:
                      isDark ? Colors.blue.shade300 : const Color(0xFF1a237e),
                      checkColor: isDark ? Colors.black : Colors.white,
                      side: BorderSide(
                        color: isDark ? Colors.grey.shade600 : Colors.grey.shade400,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Se souvenir de moi',
                    style: TextStyle(
                      fontSize: 13,
                      color: isDark ? Colors.grey.shade300 : Colors.grey[700],
                    ),
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: _showForgotPasswordDialog,
                    style: TextButton.styleFrom(
                      padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    ),
                    child: Text(
                      'Mot de passe oublié ?',
                      style: TextStyle(
                        fontSize: 13,
                        color:
                        isDark ? Colors.blue.shade300 : const Color(0xFF1a237e),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 28),

              /// Bouton connexion.
              SizedBox(
                height: 50,
                child: ElevatedButton(
                  onPressed: authProvider.isLoading
                      ? null
                      : () async {
                    if (_formKey.currentState!.validate()) {
                      final success = await authProvider.loginAdmin(
                        identifiant: _identifiantController.text.trim(),
                        motDePasse: _passwordController.text,
                      );

                      if (success && context.mounted) {
                        Navigator.pushReplacementNamed(
                            context, '/admin/dashboard');
                      }
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isDark
                        ? Colors.blue.shade700
                        : const Color(0xFF1a237e),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    disabledBackgroundColor: Colors.grey[400],
                  ),
                  child: authProvider.isLoading
                      ? SizedBox(
                    height: 22,
                    width: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      valueColor:
                      const AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                      : Text(
                    'SE CONNECTER',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 24),

              /// Copyright.
              Text(
                '© ${DateTime.now().year} CENOU - Tous droits réservés',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: isDark ? Colors.grey.shade600 : Colors.grey[500],
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Affiche une boîte de dialogue pour le mot de passe oublié.
  void _showForgotPasswordDialog() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(
              Icons.lock_reset_rounded,
              color: isDark ? Colors.blue.shade300 : const Color(0xFF1a237e),
              size: 24,
            ),
            const SizedBox(width: 12),
            Text(
              'Mot de passe oublié',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Contactez le support technique :',
              style: TextStyle(
                color: isDark ? Colors.grey.shade400 : Colors.grey[700],
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Icon(
                  Icons.email_rounded,
                  color: isDark ? Colors.blue.shade300 : const Color(0xFF1a237e),
                  size: 20,
                ),
                const SizedBox(width: 12),
                Text(
                  '70382983b@gmail.com',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(
                  Icons.phone_rounded,
                  color: isDark ? Colors.blue.shade300 : const Color(0xFF1a237e),
                  size: 20,
                ),
                const SizedBox(width: 12),
                Text(
                  '+226 70 38 29 83',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Fermer',
              style: TextStyle(
                color: isDark ? Colors.blue.shade300 : const Color(0xFF1a237e),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}