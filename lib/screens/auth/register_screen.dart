import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../providers/auth_provider.dart';
import '../../services/api_service.dart';
import '../../utils/mobile_responsive.dart';
import '../../utils/validators.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';
import '../../l10n/app_localizations.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({Key? key}) : super(key: key);

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();

  // Contrôleurs
  final _matriculeController = TextEditingController();
  final _nomController = TextEditingController();
  final _prenomController = TextEditingController();
  final _emailController = TextEditingController();
  final _telephoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  // Focus nodes pour la navigation clavier
  final _matriculeFocus = FocusNode();
  final _nomFocus = FocusNode();
  final _prenomFocus = FocusNode();
  final _emailFocus = FocusNode();
  final _telephoneFocus = FocusNode();
  final _passwordFocus = FocusNode();
  final _confirmPasswordFocus = FocusNode();

  // État UI
  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;
  bool _isLoading = false;

  // Force du mot de passe (indicateurs)
  bool _hasMinLength = false;
  bool _hasUppercase = false;
  bool _hasLowercase = false;
  bool _hasDigit = false;

  // Erreurs retournées par le backend (express-validator)
  Map<String, String> _backendErrors = {};

  @override
  void initState() {
    super.initState();
    _passwordController.addListener(_updatePasswordStrength);
  }

  @override
  void dispose() {
    _matriculeController.dispose();
    _nomController.dispose();
    _prenomController.dispose();
    _emailController.dispose();
    _telephoneController.dispose();
    _passwordController.removeListener(_updatePasswordStrength);
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _matriculeFocus.dispose();
    _nomFocus.dispose();
    _prenomFocus.dispose();
    _emailFocus.dispose();
    _telephoneFocus.dispose();
    _passwordFocus.dispose();
    _confirmPasswordFocus.dispose();
    super.dispose();
  }

  // Mise à jour optimisée des indicateurs de force du mot de passe
  void _updatePasswordStrength() {
    final pwd = _passwordController.text;
    final newMin = pwd.length >= 6;
    final newUpper = RegExp(r'[A-Z]').hasMatch(pwd);
    final newLower = RegExp(r'[a-z]').hasMatch(pwd);
    final newDigit = RegExp(r'[0-9]').hasMatch(pwd);

    if (newMin != _hasMinLength ||
        newUpper != _hasUppercase ||
        newLower != _hasLowercase ||
        newDigit != _hasDigit) {
      setState(() {
        _hasMinLength = newMin;
        _hasUppercase = newUpper;
        _hasLowercase = newLower;
        _hasDigit = newDigit;
      });
    }
  }

  // Soumission du formulaire
  Future<void> _handleRegister() async {
    final l10n = AppLocalizations.of(context);
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _backendErrors.clear();
    });

    try {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      await auth.register(
        matricule: _matriculeController.text.trim(),
        nom: _nomController.text.trim(),
        prenom: _prenomController.text.trim(),
        email: _emailController.text.trim(),
        telephone: _telephoneController.text.trim().isEmpty
            ? null
            : _telephoneController.text.trim(),
        motDePasse: _passwordController.text,
        confirmationMotDePasse: _confirmPasswordController.text,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.accountCreatedSuccess),
            backgroundColor: const Color(0xFF10B981),
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 2),
          ),
        );
        Navigator.pushReplacementNamed(context, '/home');
      }
    } catch (e) {
      if (mounted) {
        if (e is ApiException && e.details != null) {
          final Map<String, String> errors = {};
          for (final err in e.details!) {
            final param = err['param'] as String?;
            final msg = err['msg'] as String?;
            if (param != null && msg != null) {
              errors[param] = msg;
            }
          }
          setState(() => _backendErrors = errors);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(l10n.correctFormErrors),
              backgroundColor: Colors.orange,
              behavior: SnackBarBehavior.floating,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(e.toString()),
              backgroundColor: AppTheme.errorColor,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // Helper pour construire un champ avec navigation, autofill et gestion d'erreurs backend
  Widget _buildField({
    required String fieldKey,
    required TextEditingController controller,
    required FocusNode focusNode,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    bool obscure = false,
    Widget? suffix,
    String? Function(String?)? validator,
    FocusNode? nextFocus,
    List<String>? autofillHints,
    TextCapitalization textCapitalization = TextCapitalization.none,
  }) {
    return CustomTextField(
      controller: controller,
      focusNode: focusNode,
      label: label,
      hint: hint,
      prefixIcon: icon,
      keyboardType: keyboardType,
      obscureText: obscure,
      suffixIcon: suffix,
      validator: validator,
      enabled: !_isLoading,
      textInputAction: nextFocus != null ? TextInputAction.next : TextInputAction.done,
      onFieldSubmitted: (_) {
        if (nextFocus != null) {
          FocusScope.of(context).requestFocus(nextFocus);
        } else {
          FocusScope.of(context).unfocus();
        }
      },
      autofillHints: autofillHints,
      textCapitalization: textCapitalization,
      errorText: _backendErrors[fieldKey],
      onChanged: (_) {
        if (_backendErrors.containsKey(fieldKey)) {
          setState(() => _backendErrors.remove(fieldKey));
        }
      },
    );
  }

  // Widget d'indicateur de règle (force mot de passe)
  Widget _buildRule(String text, bool valid) {
    return Row(
      children: [
        Icon(
          valid ? Icons.check_circle : Icons.cancel,
          size: 14,
          color: valid ? Colors.green : Colors.red.shade400,
        ),
        const SizedBox(width: 6),
        Text(
          text,
          style: TextStyle(
            fontSize: 11,
            color: valid ? Colors.green : Colors.grey.shade600,
          ),
        ),
      ],
    );
  }

  // ==================== HEADER ====================

  Widget _buildHeader(bool isDark, ResponsiveConfig config, AppLocalizations l10n) {
    final titleSize = config.responsive(small: 24, medium: 28, large: 32);
    final subtitleSize = config.responsive(small: 14, medium: 15, large: 16);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.createAccountTitle,
          style: TextStyle(
            fontSize: titleSize,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.primary,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 8),
        Text(
          l10n.fillInfoToRegister,
          style: TextStyle(
            fontSize: subtitleSize,
            color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  // ==================== FORMULAIRE MOBILE ====================

  Widget _buildMobileForm(bool isDark, ResponsiveConfig config, AppLocalizations l10n) {
    final fieldSpacing = config.responsive(small: 12, medium: 14, large: 16);
    final sectionSpacing = config.responsive(small: 24, medium: 28, large: 32);

    return Column(
      children: [
        _buildField(
          fieldKey: 'matricule',
          controller: _matriculeController,
          focusNode: _matriculeFocus,
          label: l10n.matricule,
          hint: l10n.enterMatricule,
          icon: Icons.badge_outlined,
          validator: Validators.validateMatricule,
          nextFocus: _nomFocus,
          autofillHints: const [AutofillHints.username],
          textCapitalization: TextCapitalization.characters,
        ),
        SizedBox(height: fieldSpacing),

        _buildField(
          fieldKey: 'nom',
          controller: _nomController,
          focusNode: _nomFocus,
          label: l10n.lastName,
          hint: l10n.lastNameHint,
          icon: Icons.person_outline,
          validator: Validators.validateNom,
          nextFocus: _prenomFocus,
          autofillHints: const [AutofillHints.familyName],
        ),
        SizedBox(height: fieldSpacing),

        _buildField(
          fieldKey: 'prenom',
          controller: _prenomController,
          focusNode: _prenomFocus,
          label: l10n.firstName,
          hint: l10n.firstNameHint,
          icon: Icons.person_outline,
          validator: Validators.validateNom,
          nextFocus: _emailFocus,
          autofillHints: const [AutofillHints.givenName],
        ),
        SizedBox(height: fieldSpacing),

        _buildField(
          fieldKey: 'email',
          controller: _emailController,
          focusNode: _emailFocus,
          label: l10n.email,
          hint: l10n.emailHint,
          icon: Icons.email_outlined,
          keyboardType: TextInputType.emailAddress,
          validator: Validators.validateEmail,
          nextFocus: _telephoneFocus,
          autofillHints: const [AutofillHints.email],
        ),
        SizedBox(height: fieldSpacing),

        _buildField(
          fieldKey: 'telephone',
          controller: _telephoneController,
          focusNode: _telephoneFocus,
          label: l10n.phoneOptional,
          hint: l10n.phoneHint,
          icon: Icons.phone_outlined,
          keyboardType: TextInputType.phone,
          validator: Validators.validatePhone,
          nextFocus: _passwordFocus,
          autofillHints: const [AutofillHints.telephoneNumber],
        ),
        SizedBox(height: fieldSpacing),

        // Mot de passe avec indicateurs de force
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildField(
              fieldKey: 'mot_de_passe',
              controller: _passwordController,
              focusNode: _passwordFocus,
              label: l10n.password,
              hint: l10n.passwordHint,
              icon: Icons.lock_outline,
              obscure: !_isPasswordVisible,
              suffix: IconButton(
                icon: Icon(
                  _isPasswordVisible ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                  color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                ),
                onPressed: () => setState(() => _isPasswordVisible = !_isPasswordVisible),
              ),
              validator: Validators.validatePassword,
              nextFocus: _confirmPasswordFocus,
              autofillHints: const [AutofillHints.newPassword],
            ),
            const SizedBox(height: 6),
            Wrap(
              spacing: 12,
              runSpacing: 4,
              children: [
                _buildRule(l10n.pwdMin6, _hasMinLength),
                _buildRule(l10n.pwdUppercase, _hasUppercase),
                _buildRule(l10n.pwdLowercase, _hasLowercase),
                _buildRule(l10n.pwdDigit, _hasDigit),
              ],
            ),
          ],
        ),
        SizedBox(height: fieldSpacing),

        _buildField(
          fieldKey: 'confirmation_mot_de_passe',
          controller: _confirmPasswordController,
          focusNode: _confirmPasswordFocus,
          label: l10n.confirmPassword,
          hint: l10n.confirmPasswordHint,
          icon: Icons.lock_outline,
          obscure: !_isConfirmPasswordVisible,
          suffix: IconButton(
            icon: Icon(
              _isConfirmPasswordVisible ? Icons.visibility_outlined : Icons.visibility_off_outlined,
              color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
            ),
            onPressed: () => setState(() => _isConfirmPasswordVisible = !_isConfirmPasswordVisible),
          ),
          validator: (value) => Validators.validateConfirmPassword(value, _passwordController.text),
          nextFocus: null,
          autofillHints: const [AutofillHints.newPassword],
        ),
        SizedBox(height: sectionSpacing),
      ],
    );
  }

  // ==================== FORMULAIRE TABLETTE (2 colonnes) ====================

  Widget _buildTabletForm(bool isDark, ResponsiveConfig config, AppLocalizations l10n) {
    final fieldSpacing = config.responsive(small: 12, medium: 14, large: 16);
    final sectionSpacing = config.responsive(small: 24, medium: 28, large: 32);
    final rowGap = config.responsive(small: 12, medium: 16, large: 20);

    return Column(
      children: [
        // Ligne 1 : Matricule + Email
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _buildField(
                fieldKey: 'matricule',
                controller: _matriculeController,
                focusNode: _matriculeFocus,
                label: l10n.matricule,
                hint: l10n.enterMatricule,
                icon: Icons.badge_outlined,
                validator: Validators.validateMatricule,
                nextFocus: _nomFocus,
                autofillHints: const [AutofillHints.username],
                textCapitalization: TextCapitalization.characters,
              ),
            ),
            SizedBox(width: rowGap),
            Expanded(
              child: _buildField(
                fieldKey: 'email',
                controller: _emailController,
                focusNode: _emailFocus,
                label: l10n.email,
                hint: l10n.emailHint,
                icon: Icons.email_outlined,
                keyboardType: TextInputType.emailAddress,
                validator: Validators.validateEmail,
                nextFocus: _nomFocus,
                autofillHints: const [AutofillHints.email],
              ),
            ),
          ],
        ),
        SizedBox(height: fieldSpacing),

        // Ligne 2 : Nom + Prénom
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _buildField(
                fieldKey: 'nom',
                controller: _nomController,
                focusNode: _nomFocus,
                label: l10n.lastName,
                hint: l10n.lastNameHint,
                icon: Icons.person_outline,
                validator: Validators.validateNom,
                nextFocus: _prenomFocus,
                autofillHints: const [AutofillHints.familyName],
              ),
            ),
            SizedBox(width: rowGap),
            Expanded(
              child: _buildField(
                fieldKey: 'prenom',
                controller: _prenomController,
                focusNode: _prenomFocus,
                label: l10n.firstName,
                hint: l10n.firstNameHint,
                icon: Icons.person_outline,
                validator: Validators.validateNom,
                nextFocus: _telephoneFocus,
                autofillHints: const [AutofillHints.givenName],
              ),
            ),
          ],
        ),
        SizedBox(height: fieldSpacing),

        // Ligne 3 : Téléphone + Mot de passe
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _buildField(
                fieldKey: 'telephone',
                controller: _telephoneController,
                focusNode: _telephoneFocus,
                label: l10n.phoneOptional,
                hint: l10n.phoneHint,
                icon: Icons.phone_outlined,
                keyboardType: TextInputType.phone,
                validator: Validators.validatePhone,
                nextFocus: _passwordFocus,
                autofillHints: const [AutofillHints.telephoneNumber],
              ),
            ),
            SizedBox(width: rowGap),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildField(
                    fieldKey: 'mot_de_passe',
                    controller: _passwordController,
                    focusNode: _passwordFocus,
                    label: l10n.password,
                    hint: l10n.passwordHint,
                    icon: Icons.lock_outline,
                    obscure: !_isPasswordVisible,
                    suffix: IconButton(
                      icon: Icon(
                        _isPasswordVisible ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                        color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                      ),
                      onPressed: () => setState(() => _isPasswordVisible = !_isPasswordVisible),
                    ),
                    validator: Validators.validatePassword,
                    nextFocus: _confirmPasswordFocus,
                    autofillHints: const [AutofillHints.newPassword],
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 12,
                    runSpacing: 4,
                    children: [
                      _buildRule(l10n.pwdMin6, _hasMinLength),
                      _buildRule(l10n.pwdUppercase, _hasUppercase),
                      _buildRule(l10n.pwdLowercase, _hasLowercase),
                      _buildRule(l10n.pwdDigit, _hasDigit),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
        SizedBox(height: fieldSpacing),

        // Ligne 4 : Confirmation mot de passe (pleine largeur)
        _buildField(
          fieldKey: 'confirmation_mot_de_passe',
          controller: _confirmPasswordController,
          focusNode: _confirmPasswordFocus,
          label: l10n.confirmPassword,
          hint: l10n.confirmPasswordHint,
          icon: Icons.lock_outline,
          obscure: !_isConfirmPasswordVisible,
          suffix: IconButton(
            icon: Icon(
              _isConfirmPasswordVisible ? Icons.visibility_outlined : Icons.visibility_off_outlined,
              color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
            ),
            onPressed: () => setState(() => _isConfirmPasswordVisible = !_isConfirmPasswordVisible),
          ),
          validator: (value) => Validators.validateConfirmPassword(value, _passwordController.text),
          nextFocus: null,
          autofillHints: const [AutofillHints.newPassword],
        ),
        SizedBox(height: sectionSpacing),
      ],
    );
  }

  // ==================== FOOTER ====================

  Widget _buildFooter(bool isDark, ResponsiveConfig config, AppLocalizations l10n) {
    return Column(
      children: [
        CustomButton(
          text: l10n.registerButton,
          onPressed: _isLoading ? null : _handleRegister,
          isLoading: _isLoading,
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              l10n.alreadyHaveAccount,
              style: TextStyle(
                color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
              ),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                l10n.loginHere,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ==================== BUILD PRINCIPAL ====================

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121212) : Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: isDark ? Colors.white : Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final config = ResponsiveConfig.fromConstraints(constraints);
          final maxWidth = config.isTablet ? 500.0 : double.infinity;

          return SingleChildScrollView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            padding: config.horizontalPadding.copyWith(
              top: config.verticalSpacing,
              bottom: MediaQuery.of(context).viewInsets.bottom + config.verticalSpacing,
            ),
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: maxWidth),
              child: Form(
                key: _formKey,
                autovalidateMode: AutovalidateMode.onUserInteraction,
                child: config.isTablet
                    ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeader(isDark, config, l10n),
                    const SizedBox(height: 8),
                    _buildTabletForm(isDark, config, l10n),
                    const SizedBox(height: 24),
                    _buildFooter(isDark, config, l10n),
                  ],
                )
                    : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeader(isDark, config, l10n),
                    const SizedBox(height: 8),
                    _buildMobileForm(isDark, config, l10n),
                    const SizedBox(height: 24),
                    _buildFooter(isDark, config, l10n),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}