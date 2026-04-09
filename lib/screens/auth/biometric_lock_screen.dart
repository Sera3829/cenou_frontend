import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../l10n/app_localizations.dart';
import '../../providers/auth_provider.dart';
import 'package:local_auth_android/local_auth_android.dart';

class BiometricLockScreen extends StatefulWidget {
  /// Callback appelé quand la biométrie réussit.
  final VoidCallback onSuccess;

  /// Callback appelé quand l'utilisateur choisit le fallback mdp.
  final VoidCallback onFallback;

  const BiometricLockScreen({
    Key? key,
    required this.onSuccess,
    required this.onFallback,
  }) : super(key: key);

  @override
  State<BiometricLockScreen> createState() => _BiometricLockScreenState();
}

class _BiometricLockScreenState extends State<BiometricLockScreen>
    with WidgetsBindingObserver {
  final LocalAuthentication _auth = LocalAuthentication();
  bool _isAuthenticating = false;
  String? _errorMsg;
  int _attempts = 0;
  static const int _maxAttempts = 3;

  @override
  void initState() {
    super.initState();
    // Lancer la biométrie dès l'affichage
    WidgetsBinding.instance.addPostFrameCallback((_) => _authenticate());
  }

  @override
  void dispose() {
    _auth.stopAuthentication();
    super.dispose();
  }

  // ── Authentification ────────────────────────────────────────────────────

  Future<void> _authenticate() async {
    if (_isAuthenticating) return;

    setState(() {
      _isAuthenticating = true;
      _errorMsg = null;
    });

    try {
      final l10n = AppLocalizations.of(context);

      // Vérifier que la biométrie est toujours disponible
      final canCheck = await _auth.canCheckBiometrics;
      final isSupported = await _auth.isDeviceSupported();

      if (!canCheck || !isSupported) {
        // Plus de biométrie disponible → fallback immédiat
        if (mounted) widget.onFallback();
        return;
      }

      final ok = await _auth.authenticate(
        localizedReason: l10n.biometricSub,
        authMessages: const <AuthMessages>[
          AndroidAuthMessages(
            signInTitle: 'Authentification requise',
            cancelButton: 'Annuler',
          ),
        ],
      );

      if (!mounted) return;

      if (ok) {
        widget.onSuccess();
      } else {
        // L'utilisateur a annulé (sans erreur explicite)
        _attempts++;
        setState(() {
          _errorMsg = l10n.biometricCancelled;
          _isAuthenticating = false;
        });
        if (_attempts >= _maxAttempts) _fallbackToPassword();
      }
    } on PlatformException catch (e) {
      if (!mounted) return;
      final l10n = AppLocalizations.of(context);

      String msg;
      bool forceFallback = false;

      switch (e.code) {
        case 'NotEnrolled':
          msg = l10n.biometricNotEnrolled;
          forceFallback = true;
          break;
        case 'LockedOut':
        case 'PermanentlyLockedOut':
          msg = l10n.biometricLockedOut;
          forceFallback = true;
          break;
        case 'NotAvailable':
          msg = l10n.biometricNotAvailable;
          forceFallback = true;
          break;
        default:
          msg = e.message ?? l10n.error;
          _attempts++;
      }

      setState(() {
        _errorMsg = msg;
        _isAuthenticating = false;
      });

      if (forceFallback || _attempts >= _maxAttempts) {
        await Future.delayed(const Duration(milliseconds: 800));
        if (mounted) _fallbackToPassword();
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMsg = AppLocalizations.of(context).error;
        _isAuthenticating = false;
        _attempts++;
      });
      if (_attempts >= _maxAttempts) _fallbackToPassword();
    }
  }

  void _fallbackToPassword() {
    // Déconnecter la session et renvoyer vers LoginScreen
    Provider.of<AuthProvider>(context, listen: false).logout();
    widget.onFallback();
  }

  // ── UI ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final user = Provider.of<AuthProvider>(context).user;
    final prenom = user?.prenom ?? '';

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121212) : Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Logo
              Container(
                width: 90,
                height: 90,
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Image.asset(
                  'assets/images/logo_cenou.png',
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => Icon(
                    Icons.school_rounded,
                    size: 50,
                    color: AppTheme.primaryColor,
                  ),
                ),
              ),

              const SizedBox(height: 32),

              // Titre
              Text(
                prenom.isNotEmpty ? l10n.welcomeBack(prenom) : l10n.welcomeBackGeneric,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : AppTheme.primaryColor,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 8),

              Text(
                l10n.biometricPrompt,
                style: TextStyle(
                  fontSize: 14,
                  color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 48),

              // Icône biométrie / spinner
              GestureDetector(
                onTap: _isAuthenticating ? null : _authenticate,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withOpacity(
                        _isAuthenticating ? 0.15 : 0.1),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppTheme.primaryColor.withOpacity(
                          _isAuthenticating ? 0.3 : 0.5),
                      width: 2,
                    ),
                  ),
                  child: _isAuthenticating
                      ? Padding(
                    padding: const EdgeInsets.all(22),
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: AppTheme.primaryColor,
                    ),
                  )
                      : Icon(
                    Icons.fingerprint_rounded,
                    size: 44,
                    color: AppTheme.primaryColor,
                  ),
                ),
              ),

              const SizedBox(height: 20),

              Text(
                _isAuthenticating
                    ? l10n.biometricVerifying
                    : l10n.biometricTapToRetry,
                style: TextStyle(
                  fontSize: 13,
                  color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                ),
                textAlign: TextAlign.center,
              ),

              // Message d'erreur
              if (_errorMsg != null) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50.withOpacity(isDark ? 0.08 : 1),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                        color: Colors.red.withOpacity(isDark ? 0.3 : 0.2)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.error_outline,
                          size: 16, color: Colors.red.shade400),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          _errorMsg!,
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark
                                ? Colors.red.shade300
                                : Colors.red.shade700,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 48),

              // Fallback : mot de passe
              TextButton.icon(
                onPressed: _fallbackToPassword,
                icon: Icon(Icons.lock_outline,
                    size: 18,
                    color: isDark ? Colors.grey.shade400 : Colors.grey.shade600),
                label: Text(
                  l10n.usePassword,
                  style: TextStyle(
                    fontSize: 14,
                    color: isDark
                        ? Colors.grey.shade400
                        : Colors.grey.shade600,
                  ),
                ),
              ),

              // Tentatives restantes
              if (_attempts > 0 && _attempts < _maxAttempts)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    l10n.attemptsRemaining(_maxAttempts - _attempts),
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.orange.shade400,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}