import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../providers/auth_provider.dart';
import '../../utils/mobile_responsive.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  final _identifiantController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isPasswordVisible = false;
  bool _isLoading = false;
  String? _errorMessage;

  late final AnimationController _animCtrl;
  late final Animation<double> _fadeAnim;
  late final Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnim = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.08),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut));
    _animCtrl.forward();
  }

  @override
  void dispose() {
    _identifiantController.dispose();
    _passwordController.dispose();
    _animCtrl.dispose();
    super.dispose();
  }

  // ==================== LOGIQUE MÉTIER ====================

  Future<void> _handleLogin() async {
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

    FocusScope.of(context).unfocus();
    await Future.delayed(const Duration(milliseconds: 100));
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final success = await authProvider.login(identifiant, password);
      if (!mounted) return;

      if (success) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) Navigator.pushReplacementNamed(context, '/home');
        });
      } else {
        final error = authProvider.errorMessage ?? 'Erreur de connexion';
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          setState(() => _errorMessage = error);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.error_outline, color: Colors.white, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      error,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 13),
                    ),
                  ),
                ],
              ),
              backgroundColor: Colors.red.shade600,
              duration: const Duration(seconds: 5),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
              margin: const EdgeInsets.all(12),
            ),
          );
          if (error.contains('désactivé') || error.contains('suspendu')) {
            Future.delayed(const Duration(milliseconds: 300), () {
              if (mounted) _showAccountDisabledDialog();
            });
          }
        });
      }
    } catch (e) {
      if (mounted) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) setState(() => _errorMessage = 'Erreur inattendue');
        });
      }
    } finally {
      if (mounted) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) setState(() => _isLoading = false);
        });
      }
    }
  }

  void _showAccountDisabledDialog() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(isDark ? 0.2 : 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(Icons.block,
                  color: isDark ? Colors.orange.shade300 : Colors.orange,
                  size: 26),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Compte désactivé',
                style: TextStyle(
                  fontSize: 17,
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
                  fontSize: 15,
                  color: isDark ? Colors.grey.shade300 : Colors.black87),
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(isDark ? 0.2 : 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                    color: Colors.orange.withOpacity(isDark ? 0.4 : 0.3)),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline,
                      color: isDark ? Colors.orange.shade300 : Colors.orange,
                      size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Contactez l\'administration pour réactiver votre compte.',
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark
                            ? Colors.orange.shade300
                            : Colors.orange.shade700,
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
                  color: isDark ? Colors.blue.shade300 : AppTheme.primaryColor),
            ),
          ),
        ],
      ),
    );
  }

  // ==================== BUILD ====================

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121212) : Colors.white,
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnim,
          child: SlideTransition(
            position: _slideAnim,
            child: Center(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final config = ResponsiveConfig.fromConstraints(constraints);
                  final maxContentWidth = config.isTablet ? 500.0 : double.infinity;

                  return SingleChildScrollView(
                    padding: config.horizontalPadding.copyWith(
                      top: config.verticalSpacing,
                      bottom: config.verticalSpacing,
                    ),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(maxWidth: maxContentWidth),
                      child: config.isTablet
                          ? _buildTabletLayout(isDark, config)
                          : _buildMobileLayout(isDark, config),
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ==================== LAYOUTS ====================

  Widget _buildMobileLayout(bool isDark, ResponsiveConfig config) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildLogo(isDark, config),
        SizedBox(height: config.verticalSpacing),
        _buildTitle(isDark, config),
        const SizedBox(height: 16),
        if (_errorMessage != null) ...[
          _buildErrorBanner(isDark, config),
          const SizedBox(height: 16),
        ],
        _buildForm(isDark, config),
        const SizedBox(height: 20),
        _buildRegisterLink(isDark, config),
      ],
    );
  }

  Widget _buildTabletLayout(bool isDark, ResponsiveConfig config) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildLogo(isDark, config),
              const SizedBox(height: 20),
              _buildTitle(isDark, config),
            ],
          ),
        ),
        Expanded(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (_errorMessage != null) ...[
                _buildErrorBanner(isDark, config),
                const SizedBox(height: 16),
              ],
              _buildForm(isDark, config),
              const SizedBox(height: 20),
              _buildRegisterLink(isDark, config),
            ],
          ),
        ),
      ],
    );
  }

  // ==================== WIDGETS PRIVÉS ====================

  Widget _buildLogo(bool isDark, ResponsiveConfig config) {
    final circleSize = config.responsive(small: 90, medium: 110, large: 140);
    final logoSize = config.responsive(small: 82, medium: 100, large: 130);
    final logoHeight = config.responsive(small: 105, medium: 130, large: 160);
    final iconSize = config.responsive(small: 50, medium: 65, large: 80);

    return Stack(
      alignment: Alignment.center,
      clipBehavior: Clip.none,
      children: [
        Container(
          width: circleSize,
          height: circleSize,
          decoration: BoxDecoration(
            color: (isDark ? Colors.blue.shade700 : AppTheme.primaryColor)
                .withOpacity(0.1),
            shape: BoxShape.circle,
          ),
        ),
        Image.asset(
          'assets/images/logo_cenou.png',
          width: logoSize,
          height: logoHeight,
          fit: BoxFit.contain,
          errorBuilder: (_, __, ___) => Icon(
            Icons.school_rounded,
            size: iconSize,
            color: isDark ? Colors.blue.shade300 : AppTheme.primaryColor,
          ),
        ),
      ],
    );
  }

  Widget _buildTitle(bool isDark, ResponsiveConfig config) {
    final titleSize = config.responsive(small: 22, medium: 28, large: 34);
    final subtitleSize = config.responsive(small: 13, medium: 15, large: 17);

    return Column(
      children: [
        Text(
          'Bienvenue',
          style: TextStyle(
            fontSize: titleSize,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : AppTheme.primaryColor,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Veuillez vous connecter',
          style: TextStyle(
            fontSize: subtitleSize,
            color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
          ),
        ),
      ],
    );
  }

  Widget _buildErrorBanner(bool isDark, ResponsiveConfig config) {
    final fontSize = config.responsive(small: 12, medium: 13, large: 14);
    final iconSize = config.responsive(small: 16, medium: 18, large: 20);
    final horizontalPad = config.isSmall ? 12.0 : 16.0;
    final verticalPad = config.isSmall ? 10.0 : 12.0;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: horizontalPad, vertical: verticalPad),
      decoration: BoxDecoration(
        color: Colors.red.shade50.withOpacity(isDark ? 0.08 : 1),
        border: Border.all(color: Colors.red.withOpacity(isDark ? 0.4 : 0.3)),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.error_outline, color: Colors.red.shade400, size: iconSize),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _errorMessage!,
              style: TextStyle(
                color: isDark ? Colors.red.shade300 : Colors.red.shade700,
                fontSize: fontSize,
                height: 1.4,
              ),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          GestureDetector(
            onTap: () => setState(() => _errorMessage = null),
            child: Icon(Icons.close, color: Colors.red.shade400, size: iconSize),
          ),
        ],
      ),
    );
  }

  Widget _buildForm(bool isDark, ResponsiveConfig config) {
    final labelIdentifiant = config.isSmall ? 'Matricule / Email' : 'Matricule ou Email';
    final hintIdentifiant = config.isSmall ? 'Votre matricule' : 'Entrez votre matricule';
    final hintPassword = config.isSmall ? 'Votre mot de passe' : 'Entrez votre mot de passe';
    final iconSize = config.responsive(small: 20, medium: 22, large: 24);
    final fieldSpacing = config.responsive(small: 12.0, medium: 14.0, large: 16.0);

    return Column(
      children: [
        CustomTextField(
          controller: _identifiantController,
          label: labelIdentifiant,
          hint: hintIdentifiant,
          prefixIcon: Icons.person_outline,
          enabled: !_isLoading,
          onChanged: (_) {
            if (_errorMessage != null) setState(() => _errorMessage = null);
          },
        ),
        SizedBox(height: fieldSpacing),
        CustomTextField(
          controller: _passwordController,
          label: 'Mot de passe',
          hint: hintPassword,
          prefixIcon: Icons.lock_outline,
          obscureText: !_isPasswordVisible,
          enabled: !_isLoading,
          onChanged: (_) {
            if (_errorMessage != null) setState(() => _errorMessage = null);
          },
          suffixIcon: IconButton(
            icon: Icon(
              _isPasswordVisible ? Icons.visibility : Icons.visibility_off,
              color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
              size: iconSize,
            ),
            onPressed: () => setState(() => _isPasswordVisible = !_isPasswordVisible),
          ),
        ),
        const SizedBox(height: 20),
        SizedBox(
          width: double.infinity,
          child: CustomButton(
            text: config.isSmall ? 'CONNEXION' : 'SE CONNECTER',
            onPressed: _isLoading ? null : _handleLogin,
            isLoading: _isLoading,
          ),
        ),
      ],
    );
  }

  Widget _buildRegisterLink(bool isDark, ResponsiveConfig config) {
    final fontSize = config.responsive(small: 12, medium: 14, large: 16);
    return Wrap(
      alignment: WrapAlignment.center,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 2,
      children: [
        Text(
          'Pas encore de compte ?',
          style: TextStyle(
            color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
            fontSize: fontSize,
          ),
        ),
        TextButton(
          onPressed: _isLoading
              ? null
              : () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const RegisterScreen()),
          ),
          style: TextButton.styleFrom(
            padding: EdgeInsets.symmetric(horizontal: config.isSmall ? 6 : 8, vertical: 0),
            minimumSize: Size.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          child: Text(
            'Créer un compte',
            style: TextStyle(
              color: isDark ? Colors.blue.shade300 : AppTheme.primaryColor,
              fontWeight: FontWeight.bold,
              fontSize: fontSize,
            ),
          ),
        ),
      ],
    );
  }
}