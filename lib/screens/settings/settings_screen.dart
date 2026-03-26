import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:local_auth/local_auth.dart';
import 'dart:convert';
import '../../models/user.dart';

import '../../../config/theme.dart';
import '../../../providers/auth_provider.dart';
import '../../../services/preference_service.dart';
import '../../services/language_service.dart';

/// Écran des paramètres de l'application.
///
/// Permet de configurer les notifications, la biométrie, la langue, le thème,
/// et d'accéder aux fonctionnalités de sécurité et d'assistance.
class SettingsScreen extends StatefulWidget {
  final Function(String)? onThemeChanged;

  const SettingsScreen({Key? key, this.onThemeChanged}) : super(key: key);

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _notificationsEnabled = true;
  bool _biometricEnabled = false;
  String _selectedLanguage = 'fr';
  String _selectedTheme = 'system';
  final LocalAuthentication _localAuth = LocalAuthentication();
  bool _isBiometricAvailable = false;
  final PreferenceService _preferenceService = PreferenceService();
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPreferences();
    _checkBiometricAvailability();
  }

  /// Charge les préférences utilisateur depuis le stockage.
  Future<void> _loadPreferences() async {
    try {
      _notificationsEnabled = await _preferenceService.getNotificationsEnabled();
      _selectedLanguage = await _preferenceService.getPreferredLanguage();
      _selectedTheme = await _preferenceService.getPreferredTheme();
      _biometricEnabled = await _preferenceService.getBiometricEnabled();

      // Synchronise avec le provider d'authentification
      if (mounted) {
        final authProvider = context.read<AuthProvider>();
        authProvider.updateNotificationPref(_notificationsEnabled);
        authProvider.updateLanguage(_selectedLanguage);
        authProvider.updateTheme(_selectedTheme);
      }
    } catch (e) {
      print('Erreur lors du chargement des preferences: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  /// Vérifie si la biométrie est disponible sur l'appareil.
  Future<void> _checkBiometricAvailability() async {
    try {
      _isBiometricAvailable = await _localAuth.canCheckBiometrics;
      setState(() {});
    } catch (e) {
      print('Erreur lors de la verification de la biometrie: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.user;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Paramètres',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
        elevation: 1,
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? Center(
        child: CircularProgressIndicator(
          color: AppTheme.primaryColor,
        ),
      )
          : Container(
        color: Theme.of(context).scaffoldBackgroundColor,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Section Préférences
            _buildSectionTitle('Préférences', isDark),
            _buildPreferencesCard(authProvider, isDark),
            const SizedBox(height: 24),

            // Section Sécurité
            _buildSectionTitle('Sécurité', isDark),
            _buildSecurityCard(isDark),
            const SizedBox(height: 24),

            // Section Aide
            _buildSectionTitle('Aide & Support', isDark),
            _buildHelpCard(isDark),
            const SizedBox(height: 24),

            // Informations
            _buildAppInfo(authProvider, isDark),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  /// Construit le titre d'une section.
  Widget _buildSectionTitle(String title, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: isDark ? Colors.blue.shade300 : Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }

  /// Construit la carte des préférences utilisateur.
  Widget _buildPreferencesCard(AuthProvider authProvider, bool isDark) {
    return Card(
      elevation: isDark ? 4 : 2,
      color: isDark ? const Color(0xFF1E1E1E) : null,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
      ),
      child: Column(
        children: [
          SwitchListTile(
            value: _notificationsEnabled,
            onChanged: (value) async {
              setState(() => _notificationsEnabled = value);
              await _preferenceService.setNotificationsEnabled(value);
              authProvider.updateNotificationPref(value);
            },
            title: Text(
              'Notifications push',
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
            subtitle: Text(
              'Recevoir les notifications importantes',
              style: TextStyle(
                color: isDark ? Colors.grey.shade400 : Colors.grey[600],
              ),
            ),
            secondary: Icon(
              Icons.notifications_rounded,
              color: isDark ? Colors.blue.shade300 : Colors.blue,
            ),
            activeColor: AppTheme.primaryColor,
          ),
          _buildDivider(isDark),
          if (_isBiometricAvailable)
            SwitchListTile(
              value: _biometricEnabled,
              onChanged: (value) async {
                if (value) {
                  final authenticated = await _authenticateBiometric();
                  if (authenticated) {
                    setState(() => _biometricEnabled = value);
                    await _preferenceService.setBiometricEnabled(value);
                  }
                } else {
                  setState(() => _biometricEnabled = value);
                  await _preferenceService.setBiometricEnabled(value);
                }
              },
              title: Text(
                'Authentification biométrique',
                style: TextStyle(
                  fontWeight: FontWeight.w500,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
              subtitle: Text(
                'Utiliser l\'empreinte digitale',
                style: TextStyle(
                  color: isDark ? Colors.grey.shade400 : Colors.grey[600],
                ),
              ),
              secondary: Icon(
                Icons.fingerprint_rounded,
                color: isDark ? Colors.green.shade300 : Colors.green,
              ),
              activeColor: AppTheme.primaryColor,
            ),
          if (_isBiometricAvailable) _buildDivider(isDark),
          _buildSettingTile(
            icon: Icons.language_rounded,
            title: 'Langue de l\'application',
            subtitle: _getLanguageName(_selectedLanguage),
            onTap: _showLanguageDialog,
            isDark: isDark,
          ),
          _buildDivider(isDark),
          _buildSettingTile(
            icon: Icons.palette_rounded,
            title: 'Thème de l\'application',
            subtitle: _getThemeName(_selectedTheme),
            onTap: () => _showThemeDialog(authProvider),
            isDark: isDark,
          ),
        ],
      ),
    );
  }

  /// Construit la carte de sécurité.
  Widget _buildSecurityCard(bool isDark) {
    return Card(
      elevation: isDark ? 4 : 2,
      color: isDark ? const Color(0xFF1E1E1E) : null,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
      ),
      child: Column(
        children: [
          _buildSettingTile(
            icon: Icons.lock_reset_rounded,
            title: 'Changer le mot de passe',
            subtitle: 'Mettre à jour votre mot de passe',
            onTap: _showChangePasswordDialog,
            isDark: isDark,
          ),
          _buildDivider(isDark),
          _buildSettingTile(
            icon: Icons.devices_rounded,
            title: 'Sessions actives',
            subtitle: 'Gérer les appareils connectés',
            onTap: () => _showComingSoon('Gestion des sessions'),
            isDark: isDark,
          ),
          _buildDivider(isDark),
          _buildSettingTile(
            icon: Icons.history_rounded,
            title: 'Historique de connexion',
            subtitle: 'Voir les connexions récentes',
            onTap: () => _showComingSoon('Historique'),
            isDark: isDark,
          ),
        ],
      ),
    );
  }

  /// Construit la carte d'aide et support.
  Widget _buildHelpCard(bool isDark) {
    return Card(
      elevation: isDark ? 4 : 2,
      color: isDark ? const Color(0xFF1E1E1E) : null,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
      ),
      child: Column(
        children: [
          _buildSettingTile(
            icon: Icons.help_center_rounded,
            title: 'Centre d\'aide',
            subtitle: 'FAQ et guides',
            onTap: () => _showComingSoon('Centre d\'aide'),
            isDark: isDark,
          ),
          _buildDivider(isDark),
          _buildSettingTile(
            icon: Icons.support_agent_rounded,
            title: 'Nous contacter',
            subtitle: 'Support technique CENOU',
            onTap: _showContactDialog,
            isDark: isDark,
          ),
          _buildDivider(isDark),
          _buildSettingTile(
            icon: Icons.report_problem_rounded,
            title: 'Signaler un problème',
            subtitle: 'Faire remonter un bug',
            onTap: _showReportDialog,
            isDark: isDark,
          ),
          _buildDivider(isDark),
          _buildSettingTile(
            icon: Icons.privacy_tip_rounded,
            title: 'Confidentialité',
            subtitle: 'Politique de confidentialité',
            onTap: () => _showComingSoon('Confidentialité'),
            isDark: isDark,
          ),
        ],
      ),
    );
  }

  /// Construit la carte d'informations sur l'application.
  Widget _buildAppInfo(AuthProvider authProvider, bool isDark) {
    if (authProvider.sessionId == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        authProvider.generateSessionId();
      });
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
        border: Border.all(
          color: isDark ? Colors.grey.shade800 : Colors.grey[300]!,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Informations de l\'application',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
          const SizedBox(height: 12),
          _buildInfoRow('Version', '1.0.0', isDark),
          const SizedBox(height: 6),
          _buildInfoRow('Dernière mise à jour', '25/03/2026', isDark),
          const SizedBox(height: 6),
          _buildInfoRow('Build', '2026.1.8.001', isDark),
          const SizedBox(height: 6),
          _buildInfoRow('Session', authProvider.sessionId?.substring(0, 8) ?? '---', isDark),
          const SizedBox(height: 6),
          _buildInfoRow('Mode', authProvider.isAdmin ? 'Admin' : 'Mobile', isDark),
          const SizedBox(height: 6),
          _buildInfoRow('© 2026', 'CENOU - Tous droits réservés', isDark),
        ],
      ),
    );
  }

  /// Construit une tuile de paramètre.
  Widget _buildSettingTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    return ListTile(
      onTap: onTap,
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: (isDark ? AppTheme.primaryColor.withOpacity(0.2) : AppTheme.primaryColor.withOpacity(0.1)),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(
          icon,
          size: 22,
          color: isDark ? Colors.blue.shade300 : AppTheme.primaryColor,
        ),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.w500,
          color: isDark ? Colors.white : Colors.black87,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          color: isDark ? Colors.grey.shade400 : Colors.grey[600],
        ),
      ),
      trailing: Icon(
        Icons.chevron_right_rounded,
        color: isDark ? Colors.grey.shade600 : Colors.grey,
      ),
    );
  }

  /// Construit une ligne de séparation.
  Widget _buildDivider(bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Divider(
        height: 0,
        thickness: 1,
        color: isDark ? Colors.grey.shade800 : Colors.grey[300],
      ),
    );
  }

  /// Construit une ligne d'information (label + valeur).
  Widget _buildInfoRow(String label, String value, bool isDark) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            color: isDark ? Colors.grey.shade400 : Colors.grey[600],
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 13,
            color: isDark ? Colors.white : Colors.black87,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  // Méthodes utilitaires

  String _getLanguageName(String code) {
    return switch (code) {
      'fr' => 'Français',
      'en' => 'English',
      _ => 'Français',
    };
  }

  String _getThemeName(String theme) {
    return switch (theme) {
      'light' => 'Clair',
      'dark' => 'Sombre',
      'system' => 'Système',
      _ => 'Système',
    };
  }

  /// Affiche une notification pour une fonctionnalité à venir.
  void _showComingSoon(String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$feature - Bientôt disponible !'),
        backgroundColor: AppTheme.primaryColor,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  /// Affiche la boîte de dialogue de choix de langue.
  void _showLanguageDialog() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final languageService = Provider.of<LanguageService>(context, listen: false);

    final languages = [
      {'code': 'fr', 'name': 'Français', 'flag': '🇫🇷'},
      {'code': 'en', 'name': 'English', 'flag': '🇺🇸'},
    ];

    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (bottomSheetContext) {
        return SizedBox(
          height: 250,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  'Choisir la langue',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
              ),
              Expanded(
                child: ListView(
                  children: languages.map((lang) {
                    return RadioListTile(
                      title: Row(
                        children: [
                          Text(lang['flag']!),
                          const SizedBox(width: 12),
                          Text(
                            lang['name']!,
                            style: TextStyle(
                              color: isDark ? Colors.white : Colors.black87,
                            ),
                          ),
                        ],
                      ),
                      value: lang['code'],
                      groupValue: _selectedLanguage,
                      onChanged: (value) async {
                        if (value == null) return;

                        setState(() => _selectedLanguage = value.toString());

                        final countryCode = value == 'en' ? 'US' : 'FR';
                        final newLocale = Locale(value.toString(), countryCode);

                        await languageService.setLocale(newLocale);
                        await _preferenceService.setPreferredLanguage(value.toString());

                        final authProvider = Provider.of<AuthProvider>(
                          context,
                          listen: false,
                        );
                        authProvider.updateLanguage(value.toString());

                        Navigator.pop(bottomSheetContext);

                        if (context.mounted) {
                          showDialog(
                            context: context,
                            barrierDismissible: false,
                            builder: (dialogContext) => AlertDialog(
                              backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                              title: Row(
                                children: [
                                  Icon(
                                    Icons.language_rounded,
                                    color: AppTheme.primaryColor,
                                  ),
                                  const SizedBox(width: 12),
                                  Text(
                                    'Langue modifiée',
                                    style: TextStyle(
                                      color: isDark ? Colors.white : Colors.black87,
                                    ),
                                  ),
                                ],
                              ),
                              content: Text(
                                'Pour appliquer la nouvelle langue, '
                                    'l\'application va redémarrer.',
                                style: TextStyle(
                                  color: isDark ? Colors.grey.shade300 : Colors.grey.shade700,
                                ),
                              ),
                              actions: [
                                ElevatedButton(
                                  onPressed: () {
                                    Navigator.of(dialogContext).pop();
                                    Navigator.of(context).pushNamedAndRemoveUntil(
                                      '/',
                                          (route) => false,
                                    );
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppTheme.primaryColor,
                                  ),
                                  child: const Text('Redémarrer maintenant'),
                                ),
                              ],
                            ),
                          );
                        }
                      },
                      activeColor: AppTheme.primaryColor,
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  /// Affiche la boîte de dialogue de choix du thème.
  void _showThemeDialog(AuthProvider authProvider) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final themes = [
      {'code': 'system', 'name': 'Système', 'icon': Icons.brightness_auto_rounded},
      {'code': 'light', 'name': 'Clair', 'icon': Icons.light_mode_rounded},
      {'code': 'dark', 'name': 'Sombre', 'icon': Icons.dark_mode_rounded},
    ];

    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (bottomSheetContext) {
        return SizedBox(
          height: 250,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  'Choisir le thème',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
              ),
              Expanded(
                child: ListView(
                  children: themes.map((theme) {
                    final themeCode = theme['code'] as String? ?? '';
                    final themeName = theme['name'] as String? ?? '';
                    final themeIcon = theme['icon'] as IconData? ?? Icons.circle;

                    return RadioListTile<String>(
                      title: Row(
                        children: [
                          Icon(
                            themeIcon,
                            size: 20,
                            color: isDark ? Colors.grey.shade300 : Colors.grey.shade700,
                          ),
                          const SizedBox(width: 12),
                          Text(
                            themeName,
                            style: TextStyle(
                              color: isDark ? Colors.white : Colors.black87,
                            ),
                          ),
                        ],
                      ),
                      value: themeCode,
                      groupValue: _selectedTheme,
                      onChanged: (String? value) async {
                        if (value != null) {
                          setState(() => _selectedTheme = value);
                          await _preferenceService.setPreferredTheme(value);

                          widget.onThemeChanged?.call(value);

                          Navigator.pop(bottomSheetContext);

                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Thème changé en $themeName'),
                              backgroundColor: AppTheme.primaryColor,
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        }
                      },
                      activeColor: AppTheme.primaryColor,
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  /// Affiche la boîte de dialogue de changement de mot de passe.
  void _showChangePasswordDialog() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final oldPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    bool _oldPasswordVisible = false;
    bool _newPasswordVisible = false;
    bool _confirmPasswordVisible = false;

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Icon(
                Icons.lock_reset_rounded,
                color: isDark ? Colors.blue.shade300 : AppTheme.primaryColor,
              ),
              const SizedBox(width: 12),
              Text(
                'Changer le mot de passe',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Information sur les contraintes du mot de passe
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: (isDark ? Colors.blue.shade900 : Colors.blue.shade50).withOpacity(0.3),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isDark ? Colors.blue.shade700 : Colors.blue.shade200,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.info_outline,
                              size: 16,
                              color: isDark ? Colors.blue.shade300 : Colors.blue.shade700,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Exigences du mot de passe :',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: isDark ? Colors.blue.shade300 : Colors.blue.shade700,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        _buildPasswordRequirement('Au moins 6 caractères', isDark),
                        _buildPasswordRequirement('Une lettre majuscule', isDark),
                        _buildPasswordRequirement('Un chiffre', isDark),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Ancien mot de passe
                  TextFormField(
                    controller: oldPasswordController,
                    obscureText: !_oldPasswordVisible,
                    style: TextStyle(
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                    decoration: InputDecoration(
                      labelText: 'Ancien mot de passe',
                      labelStyle: TextStyle(
                        color: isDark ? Colors.grey.shade400 : Colors.grey.shade700,
                      ),
                      prefixIcon: Icon(
                        Icons.lock_outline,
                        color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                      ),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _oldPasswordVisible ? Icons.visibility : Icons.visibility_off,
                          color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                        ),
                        onPressed: () {
                          setState(() {
                            _oldPasswordVisible = !_oldPasswordVisible;
                          });
                        },
                      ),
                      filled: true,
                      fillColor: isDark ? const Color(0xFF2D2D2D) : Colors.grey.shade50,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: isDark ? Colors.grey.shade700 : Colors.grey.shade300,
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: isDark ? Colors.grey.shade700 : Colors.grey.shade300,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: isDark ? Colors.blue.shade300 : AppTheme.primaryColor,
                          width: 2,
                        ),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'L\'ancien mot de passe est requis';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Nouveau mot de passe
                  TextFormField(
                    controller: newPasswordController,
                    obscureText: !_newPasswordVisible,
                    style: TextStyle(
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                    decoration: InputDecoration(
                      labelText: 'Nouveau mot de passe',
                      labelStyle: TextStyle(
                        color: isDark ? Colors.grey.shade400 : Colors.grey.shade700,
                      ),
                      prefixIcon: Icon(
                        Icons.lock_reset,
                        color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                      ),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _newPasswordVisible ? Icons.visibility : Icons.visibility_off,
                          color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                        ),
                        onPressed: () {
                          setState(() {
                            _newPasswordVisible = !_newPasswordVisible;
                          });
                        },
                      ),
                      filled: true,
                      fillColor: isDark ? const Color(0xFF2D2D2D) : Colors.grey.shade50,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: isDark ? Colors.grey.shade700 : Colors.grey.shade300,
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: isDark ? Colors.grey.shade700 : Colors.grey.shade300,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: isDark ? Colors.blue.shade300 : AppTheme.primaryColor,
                          width: 2,
                        ),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Le nouveau mot de passe est requis';
                      }
                      if (value.length < 6) {
                        return 'Au moins 6 caractères requis';
                      }
                      if (!RegExp(r'[A-Z]').hasMatch(value)) {
                        return 'Une lettre majuscule requise';
                      }
                      if (!RegExp(r'[0-9]').hasMatch(value)) {
                        return 'Un chiffre requis';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Confirmation du nouveau mot de passe
                  TextFormField(
                    controller: confirmPasswordController,
                    obscureText: !_confirmPasswordVisible,
                    style: TextStyle(
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                    decoration: InputDecoration(
                      labelText: 'Confirmation',
                      hintText: 'Retapez le nouveau mot de passe',
                      labelStyle: TextStyle(
                        color: isDark ? Colors.grey.shade400 : Colors.grey.shade700,
                      ),
                      prefixIcon: Icon(
                        Icons.lock_reset,
                        color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                      ),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _confirmPasswordVisible ? Icons.visibility : Icons.visibility_off,
                          color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                        ),
                        onPressed: () {
                          setState(() {
                            _confirmPasswordVisible = !_confirmPasswordVisible;
                          });
                        },
                      ),
                      filled: true,
                      fillColor: isDark ? const Color(0xFF2D2D2D) : Colors.grey.shade50,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: isDark ? Colors.grey.shade700 : Colors.grey.shade300,
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: isDark ? Colors.grey.shade700 : Colors.grey.shade300,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: isDark ? Colors.blue.shade300 : AppTheme.primaryColor,
                          width: 2,
                        ),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'La confirmation est requise';
                      }
                      if (value != newPasswordController.text) {
                        return 'Les mots de passe ne correspondent pas';
                      }
                      return null;
                    },
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                oldPasswordController.dispose();
                newPasswordController.dispose();
                confirmPasswordController.dispose();
                Navigator.pop(dialogContext);
              },
              child: Text(
                'Annuler',
                style: TextStyle(
                  color: isDark ? Colors.grey.shade400 : Colors.grey.shade700,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                if (!formKey.currentState!.validate()) return;

                // Fermer le dialogue
                Navigator.pop(dialogContext);

                // Afficher un indicateur de chargement
                showDialog(
                  context: this.context,
                  barrierDismissible: false,
                  builder: (loadingContext) => PopScope(
                    canPop: false,
                    child: Center(
                      child: CircularProgressIndicator(
                        color: Colors.green,
                        strokeWidth: 3,
                      ),
                    ),
                  ),
                );

                try {
                  final authProvider = Provider.of<AuthProvider>(this.context, listen: false);

                  final success = await authProvider.changePassword(
                    ancienMotDePasse: oldPasswordController.text,
                    nouveauMotDePasse: newPasswordController.text,
                    confirmationNouveauMotDePasse: confirmPasswordController.text,
                  );

                  // Fermer l'overlay
                  if (this.context.mounted) {
                    Navigator.pop(this.context);
                  }

                  if (success) {
                    if (this.context.mounted) {
                      ScaffoldMessenger.of(this.context).showSnackBar(
                        SnackBar(
                          content: Row(
                            children: [
                              const Icon(Icons.check_circle, color: Colors.white),
                              const SizedBox(width: 12),
                              const Text('Mot de passe changé avec succès'),
                            ],
                          ),
                          backgroundColor: Colors.green,
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    }
                  } else {
                    if (this.context.mounted) {
                      ScaffoldMessenger.of(this.context).showSnackBar(
                        SnackBar(
                          content: Row(
                            children: [
                              const Icon(Icons.error_outline, color: Colors.white),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  authProvider.errorMessage ?? 'Erreur lors du changement',
                                ),
                              ),
                            ],
                          ),
                          backgroundColor: Colors.red,
                          behavior: SnackBarBehavior.floating,
                          duration: const Duration(seconds: 5),
                        ),
                      );
                    }
                  }
                } catch (e) {
                  if (this.context.mounted) {
                    Navigator.pop(this.context);

                    ScaffoldMessenger.of(this.context).showSnackBar(
                      SnackBar(
                        content: Text('Erreur: $e'),
                        backgroundColor: Colors.red,
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  }
                } finally {
                  oldPasswordController.dispose();
                  newPasswordController.dispose();
                  confirmPasswordController.dispose();
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: isDark ? Colors.blue.shade700 : AppTheme.primaryColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('Changer'),
            ),
          ],
        ),
      ),
    );
  }

  /// Construit un élément d'exigence de mot de passe.
  Widget _buildPasswordRequirement(String text, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(left: 8, top: 4),
      child: Row(
        children: [
          Icon(
            Icons.check_circle_outline,
            size: 14,
            color: isDark ? Colors.blue.shade300 : Colors.blue.shade700,
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 11,
                color: isDark ? Colors.blue.shade300 : Colors.blue.shade700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Affiche la boîte de dialogue de contact.
  void _showContactDialog() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        title: Text(
          'Support CENOU',
          style: TextStyle(
            color: isDark ? Colors.white : Colors.black87,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Pour toute assistance technique :',
              style: TextStyle(
                color: isDark ? Colors.grey.shade300 : Colors.black87,
              ),
            ),
            const SizedBox(height: 12),
            _buildContactItem(Icons.email_rounded, '70382983b@gmail.com', isDark),
            const SizedBox(height: 8),
            _buildContactItem(Icons.phone_rounded, '+226 70 38 29 83', isDark),
            const SizedBox(height: 8),
            _buildContactItem(Icons.access_time_rounded, 'Lun-Dim: 8h-18h', isDark),
            const SizedBox(height: 8),
            _buildContactItem(Icons.location_on_rounded, 'Bobo Dioulasso, Belle Ville', isDark),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Fermer',
              style: TextStyle(
                color: isDark ? Colors.grey.shade400 : null,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Text('Envoyer un email'),
          ),
        ],
      ),
    );
  }

  /// Construit une ligne de contact.
  Widget _buildContactItem(IconData icon, String text, bool isDark) {
    return Row(
      children: [
        Icon(
          icon,
          size: 18,
          color: AppTheme.primaryColor,
        ),
        const SizedBox(width: 12),
        Flexible(
          child: Text(
            text,
            style: TextStyle(
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
        ),
      ],
    );
  }

  /// Affiche la boîte de dialogue de signalement de problème.
  void _showReportDialog() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        title: Text(
          'Signaler un problème',
          style: TextStyle(
            color: isDark ? Colors.white : Colors.black87,
          ),
        ),
        content: Text(
          'Décrivez le problème que vous rencontrez. '
              'Notre équipe technique examinera votre rapport.',
          style: TextStyle(
            color: isDark ? Colors.grey.shade300 : Colors.black87,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Annuler',
              style: TextStyle(
                color: isDark ? Colors.grey.shade400 : null,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/signalements');
            },
            child: const Text('Signaler'),
          ),
        ],
      ),
    );
  }

  /// Authentifie l'utilisateur par biométrie.
  Future<bool> _authenticateBiometric() async {
    try {
      final canCheckBiometrics = await _localAuth.canCheckBiometrics;
      final isDeviceSupported = await _localAuth.isDeviceSupported();

      if (!canCheckBiometrics || !isDeviceSupported) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('La biométrie n\'est pas disponible sur cet appareil'),
            backgroundColor: Colors.orange,
            behavior: SnackBarBehavior.floating,
          ),
        );
        return false;
      }

      final availableBiometrics = await _localAuth.getAvailableBiometrics();
      print('Biometries disponibles: $availableBiometrics');

      if (availableBiometrics.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Aucune biométrie configurée sur l\'appareil'),
            backgroundColor: Colors.orange,
            behavior: SnackBarBehavior.floating,
          ),
        );
        return false;
      }

      final authenticated = await _localAuth.authenticate(
        localizedReason: 'Authentifiez-vous pour activer la biométrie',
      );

      if (authenticated) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Authentification biométrique activée'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Authentification annulée'),
            backgroundColor: Colors.orange,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }

      return authenticated;
    } on PlatformException catch (e) {
      print('Erreur PlatformException biometrique: ${e.code} - ${e.message}');

      String errorMessage = 'Erreur d\'authentification biométrique';

      switch (e.code) {
        case 'NotAvailable':
          errorMessage = 'La biométrie n\'est pas disponible sur cet appareil';
          break;
        case 'NotEnrolled':
          errorMessage = 'Aucune empreinte digitale enregistrée';
          break;
        case 'LockedOut':
          errorMessage = 'Trop de tentatives. Réessayez plus tard';
          break;
        case 'PermanentlyLockedOut':
          errorMessage = 'Biométrie bloquée. Utilisez le code de l\'appareil';
          break;
        case 'no_fragment_activity':
          errorMessage = 'Erreur de configuration. Veuillez redémarrer l\'application';
          break;
        default:
          errorMessage = 'Erreur: ${e.message}';
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 4),
        ),
      );

      return false;
    } catch (e) {
      print('Erreur generale biometrique: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur inattendue: $e'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return false;
    }
  }
}