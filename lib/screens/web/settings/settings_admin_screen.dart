import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../services/preference_service.dart';
import '../dashboard/dashboard_screen.dart';
import '../../../config/theme.dart';
import '../../../l10n/app_localizations.dart';

/// Écran des paramètres pour l'administration.
///
/// Permet de modifier le thème, la langue, les notifications et d'accéder
/// aux informations du compte.
class SettingsAdminScreen extends StatefulWidget {
  final Function(String)? onThemeChanged;

  const SettingsAdminScreen({Key? key, this.onThemeChanged}) : super(key: key);

  @override
  State<SettingsAdminScreen> createState() => _SettingsAdminScreenState();
}

class _SettingsAdminScreenState extends State<SettingsAdminScreen> {
  String _selectedTheme = 'system';
  String _selectedLanguage = 'fr';
  bool _notificationsEnabled = true;
  bool _isLoading = true;

  final PreferenceService _preferenceService = PreferenceService();

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  /// Charge les préférences utilisateur depuis le stockage.
  Future<void> _loadPreferences() async {
    try {
      _selectedTheme = await _preferenceService.getPreferredTheme();
      _selectedLanguage = await _preferenceService.getPreferredLanguage();
      _notificationsEnabled = await _preferenceService.getNotificationsEnabled();
    } catch (e) {
      print('Erreur chargement préférences: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return DashboardLayout(
      selectedIndex: 6,
      child: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 16),

            LayoutBuilder(
              builder: (context, constraints) {
                final isWide = constraints.maxWidth > 800;
                return GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: isWide ? 2 : 1,
                  crossAxisSpacing: 20,
                  mainAxisSpacing: 20,
                  childAspectRatio: constraints.maxWidth > 1200 ? 1.8 : 1.5,
                  children: [
                    _buildPreferencesCard(l10n),
                    _buildNotificationsCard(l10n),
                    _buildAccountCard(l10n),
                    _buildAppInfoCard(l10n),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  /// Construit la carte des préférences (thème, langue).
  Widget _buildPreferencesCard(AppLocalizations l10n) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Card(
      elevation: isDark ? 4 : 2,
      color: AppTheme.getCardBackground(context),
      child: Container(
        padding: const EdgeInsets.all(20),
        constraints: const BoxConstraints(minHeight: 200),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xFF1E3A8A).withOpacity(0.3)
                        : const Color(0xFF1E3A8A).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.settings_rounded,
                    color: isDark ? Colors.blue.shade300 : const Color(0xFF1E3A8A),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    l10n.preferences,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.getTextPrimary(context),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            _buildSettingRow(
              icon: Icons.palette_rounded,
              title: l10n.interfaceTheme,
              subtitle: _getThemeName(_selectedTheme, l10n),
              onTap: () => _showThemeDialog(l10n),
            ),

            const SizedBox(height: 16),

            _buildSettingRow(
              icon: Icons.language_rounded,
              title: l10n.language,
              subtitle: _selectedLanguage == 'fr' ? l10n.french : l10n.english,
              onTap: () => _showLanguageDialog(l10n),
            ),
          ],
        ),
      ),
    );
  }

  /// Construit la carte des notifications.
  Widget _buildNotificationsCard(AppLocalizations l10n) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Card(
      elevation: isDark ? 4 : 2,
      color: AppTheme.getCardBackground(context),
      child: Container(
        padding: const EdgeInsets.all(20),
        constraints: const BoxConstraints(minHeight: 200),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xFF3B82F6).withOpacity(0.3)
                        : const Color(0xFF3B82F6).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.notifications_rounded,
                    color: isDark ? Colors.blue.shade300 : const Color(0xFF3B82F6),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    l10n.notifications,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.getTextPrimary(context),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            SwitchListTile(
              value: _notificationsEnabled,
              onChanged: (value) async {
                setState(() => _notificationsEnabled = value);
                await _preferenceService.setNotificationsEnabled(value);
              },
              title: Text(
                l10n.pushNotif,
                style: TextStyle(
                  fontWeight: FontWeight.w500,
                  color: AppTheme.getTextPrimary(context),
                ),
              ),
              subtitle: Text(
                l10n.receiveImportantAlerts,
                style: TextStyle(
                  color: AppTheme.getTextSecondary(context),
                ),
              ),
              activeColor: Theme.of(context).colorScheme.primary,
              contentPadding: EdgeInsets.zero,
            ),
          ],
        ),
      ),
    );
  }

  /// Construit la carte du compte et de la sécurité.
  Widget _buildAccountCard(AppLocalizations l10n) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Card(
      elevation: isDark ? 4 : 2,
      color: AppTheme.getCardBackground(context),
      child: Container(
        padding: const EdgeInsets.all(20),
        constraints: const BoxConstraints(minHeight: 200),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xFF10B981).withOpacity(0.3)
                        : const Color(0xFF10B981).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.person_rounded,
                    color: isDark ? Colors.green.shade300 : const Color(0xFF10B981),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    l10n.accountSecurity,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.getTextPrimary(context),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            _buildSettingRow(
              icon: Icons.lock_reset_rounded,
              title: l10n.changePassword,
              subtitle: l10n.lastChangeDaysAgo(30),
              onTap: () => _showChangePasswordDialog(l10n),
            ),
          ],
        ),
      ),
    );
  }

  /// Construit la carte des informations sur l'application.
  Widget _buildAppInfoCard(AppLocalizations l10n) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Card(
      elevation: isDark ? 4 : 2,
      color: AppTheme.getCardBackground(context),
      child: Container(
        padding: const EdgeInsets.all(20),
        constraints: const BoxConstraints(minHeight: 200),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xFF8B5CF6).withOpacity(0.3)
                        : const Color(0xFF8B5CF6).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.info_rounded,
                    color: isDark ? Colors.purple.shade300 : const Color(0xFF8B5CF6),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    l10n.information,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.getTextPrimary(context),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildInfoRow(l10n.version, '1.0.0'),
                const SizedBox(height: 12),
                _buildInfoRow(l10n.lastUpdate, '07/01/2026'),
                const SizedBox(height: 12),
                _buildInfoRow(l10n.mode, l10n.web),
                const SizedBox(height: 12),
                _buildInfoRow(l10n.copyright, 'CENOU'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Construit une ligne de paramètre (titre, sous‑titre, icône).
  Widget _buildSettingRow({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isDark ? Colors.grey.shade800.withOpacity(0.3) : Colors.grey.shade50,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 20,
              color: AppTheme.getTextSecondary(context),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.w500,
                      color: AppTheme.getTextPrimary(context),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 13,
                      color: AppTheme.getTextSecondary(context),
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: AppTheme.getTextTertiary(context),
            ),
          ],
        ),
      ),
    );
  }

  /// Construit une ligne d'information (label / valeur).
  Widget _buildInfoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            color: AppTheme.getTextSecondary(context),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.w500,
            color: AppTheme.getTextPrimary(context),
          ),
        ),
      ],
    );
  }

  /// Retourne le libellé du thème à partir du code.
  String _getThemeName(String theme, AppLocalizations l10n) {
    return switch (theme) {
      'light' => l10n.themeLight,
      'dark' => l10n.themeDark,
      'system' => l10n.themeSystem,
      _ => l10n.themeSystem,
    };
  }

  /// Affiche la boîte de dialogue de sélection du thème.
  void _showThemeDialog(AppLocalizations l10n) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final themes = [
      {'code': 'system', 'name': l10n.themeSystem, 'icon': Icons.brightness_auto_rounded},
      {'code': 'light', 'name': l10n.themeLight, 'icon': Icons.light_mode_rounded},
      {'code': 'dark', 'name': l10n.themeDark, 'icon': Icons.dark_mode_rounded},
    ];

    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          backgroundColor: AppTheme.getCardBackground(context),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: Container(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.chooseTheme,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.getTextPrimary(context),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    l10n.selectInterfaceTheme,
                    style: TextStyle(
                      color: AppTheme.getTextSecondary(context),
                    ),
                  ),
                  const SizedBox(height: 24),

                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: themes.map<Widget>((theme) {
                      return RadioListTile<String>(
                        title: Row(
                          children: [
                            Icon(
                              theme['icon'] as IconData,
                              size: 20,
                              color: AppTheme.getTextSecondary(context),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              theme['name'] as String,
                              style: TextStyle(
                                color: AppTheme.getTextPrimary(context),
                              ),
                            ),
                          ],
                        ),
                        value: theme['code'] as String,
                        groupValue: _selectedTheme,
                        onChanged: (String? value) async {
                          if (value != null) {
                            setState(() => _selectedTheme = value);
                            await _preferenceService.setPreferredTheme(value);
                            widget.onThemeChanged?.call(value);
                            Navigator.pop(context);

                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(l10n.themeChanged(theme['name'] as String)),
                                backgroundColor: Theme.of(context).colorScheme.primary,
                              ),
                            );
                          }
                        },
                        activeColor: Theme.of(context).colorScheme.primary,
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  /// Affiche la boîte de dialogue de sélection de la langue.
  void _showLanguageDialog(AppLocalizations l10n) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final languages = [
      {'code': 'fr', 'name': l10n.french, 'flag': '🇫🇷'},
      {'code': 'en', 'name': l10n.english, 'flag': '🇺🇸'},
    ];

    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          backgroundColor: AppTheme.getCardBackground(context),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: Container(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.chooseLanguage,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.getTextPrimary(context),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    l10n.selectInterfaceLanguage,
                    style: TextStyle(
                      color: AppTheme.getTextSecondary(context),
                    ),
                  ),
                  const SizedBox(height: 24),

                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: languages.map<Widget>((lang) {
                      return RadioListTile<String>(
                        title: Row(
                          children: [
                            Text(lang['flag'] as String),
                            const SizedBox(width: 12),
                            Text(
                              lang['name'] as String,
                              style: TextStyle(
                                color: AppTheme.getTextPrimary(context),
                              ),
                            ),
                          ],
                        ),
                        value: lang['code'] as String,
                        groupValue: _selectedLanguage,
                        onChanged: (String? value) async {
                          if (value != null) {
                            setState(() => _selectedLanguage = value);
                            await _preferenceService.setPreferredLanguage(value);
                            Navigator.pop(context);

                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(l10n.languageChanged(lang['name'] as String)),
                                backgroundColor: Theme.of(context).colorScheme.primary,
                              ),
                            );
                          }
                        },
                        activeColor: Theme.of(context).colorScheme.primary,
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  /// Affiche la boîte de dialogue de changement de mot de passe (à venir).
  void _showChangePasswordDialog(AppLocalizations l10n) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          backgroundColor: AppTheme.getCardBackground(context),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 500),
            child: Container(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.changePassword,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.getTextPrimary(context),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    l10n.featureComingSoon,
                    style: TextStyle(
                      color: AppTheme.getTextSecondary(context),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text(
                        l10n.ok,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}