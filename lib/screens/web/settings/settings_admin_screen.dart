import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/auth_provider.dart';
import '../../../services/language_service.dart';
import '../../../services/preference_service.dart';
import '../dashboard/dashboard_screen.dart';
import '../../../config/theme.dart';
import '../../../l10n/app_localizations.dart';

/// Écran des paramètres pour l'administration.
class SettingsAdminScreen extends StatefulWidget {
  final Function(String)? onThemeChanged;
  const SettingsAdminScreen({Key? key, this.onThemeChanged}) : super(key: key);

  @override
  State<SettingsAdminScreen> createState() => _SettingsAdminScreenState();
}

class _SettingsAdminScreenState extends State<SettingsAdminScreen> {
  String _selectedTheme    = 'system';
  String _selectedLanguage = 'fr';
  bool   _notificationsEnabled = true;
  bool   _isLoading = true;

  final PreferenceService _preferenceService = PreferenceService();

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    try {
      _selectedTheme       = await _preferenceService.getPreferredTheme();
      _selectedLanguage    = await _preferenceService.getPreferredLanguage();
      _notificationsEnabled = await _preferenceService.getNotificationsEnabled();
    } catch (e) {
      debugPrint('Erreur chargement préférences: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _snack(String msg, {Color bg = Colors.orange}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: bg,
      behavior: SnackBarBehavior.floating,
    ));
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
            LayoutBuilder(builder: (context, constraints) {
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
            }),
          ],
        ),
      ),
    );
  }

  // ── Carte Préférences ──────────────────────────────────────────────────────

  Widget _buildPreferencesCard(AppLocalizations l10n) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return _Card(
      isDark: isDark,
      icon: Icons.settings_rounded,
      iconColor: const Color(0xFF1E3A8A),
      title: l10n.preferences,
      children: [
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
    );
  }

  // ── Carte Notifications ────────────────────────────────────────────────────

  Widget _buildNotificationsCard(AppLocalizations l10n) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return _Card(
      isDark: isDark,
      icon: Icons.notifications_rounded,
      iconColor: const Color(0xFF3B82F6),
      title: l10n.notifications,
      children: [
        SwitchListTile(
          value: _notificationsEnabled,
          onChanged: (value) async {
            setState(() => _notificationsEnabled = value);
            await _preferenceService.setNotificationsEnabled(value);
          },
          title: Text(l10n.pushNotif,
              style: TextStyle(
                  fontWeight: FontWeight.w500,
                  color: AppTheme.getTextPrimary(context))),
          subtitle: Text(l10n.receiveImportantAlerts,
              style: TextStyle(color: AppTheme.getTextSecondary(context))),
          activeColor: Theme.of(context).colorScheme.primary,
          contentPadding: EdgeInsets.zero,
        ),
      ],
    );
  }

  // ── Carte Compte & Sécurité ────────────────────────────────────────────────

  Widget _buildAccountCard(AppLocalizations l10n) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return _Card(
      isDark: isDark,
      icon: Icons.person_rounded,
      iconColor: const Color(0xFF10B981),
      title: l10n.accountSecurity,
      children: [
        _buildSettingRow(
          icon: Icons.lock_reset_rounded,
          title: l10n.changePassword,
          subtitle: l10n.lastChangeDaysAgo(30),
          onTap: () => _showChangePasswordDialog(l10n),
        ),
      ],
    );
  }

  // ── Carte Info Application ─────────────────────────────────────────────────

  Widget _buildAppInfoCard(AppLocalizations l10n) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return _Card(
      isDark: isDark,
      icon: Icons.info_rounded,
      iconColor: const Color(0xFF8B5CF6),
      title: l10n.information,
      children: [
        _buildInfoRow(l10n.version,    '1.0.0'),
        const SizedBox(height: 12),
        _buildInfoRow(l10n.lastUpdate, '07/01/2026'),
        const SizedBox(height: 12),
        _buildInfoRow(l10n.mode,       l10n.web),
        const SizedBox(height: 12),
        _buildInfoRow(l10n.copyright,  'CENOU'),
      ],
    );
  }

  // ── Widgets helpers ────────────────────────────────────────────────────────

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
          color: isDark
              ? Colors.grey.shade800.withOpacity(0.3)
              : Colors.grey.shade50,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(children: [
          Icon(icon, size: 20, color: AppTheme.getTextSecondary(context)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title,
                  style: TextStyle(
                      fontWeight: FontWeight.w500,
                      color: AppTheme.getTextPrimary(context))),
              const SizedBox(height: 2),
              Text(subtitle,
                  style: TextStyle(
                      fontSize: 13,
                      color: AppTheme.getTextSecondary(context))),
            ]),
          ),
          Icon(Icons.chevron_right_rounded,
              color: AppTheme.getTextTertiary(context)),
        ]),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Text(label,
          style: TextStyle(color: AppTheme.getTextSecondary(context))),
      Text(value,
          style: TextStyle(
              fontWeight: FontWeight.w500,
              color: AppTheme.getTextPrimary(context))),
    ]);
  }

  String _getThemeName(String theme, AppLocalizations l10n) => switch (theme) {
    'light'  => l10n.themeLight,
    'dark'   => l10n.themeDark,
    _        => l10n.themeSystem,
  };

  // ── Dialog Thème ───────────────────────────────────────────────────────────

  void _showThemeDialog(AppLocalizations l10n) {
    final themes = [
      {'code': 'system', 'name': l10n.themeSystem, 'icon': Icons.brightness_auto_rounded},
      {'code': 'light',  'name': l10n.themeLight,  'icon': Icons.light_mode_rounded},
      {'code': 'dark',   'name': l10n.themeDark,   'icon': Icons.dark_mode_rounded},
    ];
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        backgroundColor: AppTheme.getCardBackground(context),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 400),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              _dialogTitle(l10n.chooseTheme, l10n.selectInterfaceTheme),
              const SizedBox(height: 16),
              ...themes.map((t) => RadioListTile<String>(
                title: Row(children: [
                  Icon(t['icon'] as IconData,
                      size: 20,
                      color: AppTheme.getTextSecondary(context)),
                  const SizedBox(width: 12),
                  Text(t['name'] as String,
                      style: TextStyle(
                          color: AppTheme.getTextPrimary(context))),
                ]),
                value: t['code'] as String,
                groupValue: _selectedTheme,
                activeColor: Theme.of(context).colorScheme.primary,
                onChanged: (v) async {
                  if (v == null) return;
                  setState(() => _selectedTheme = v);
                  await _preferenceService.setPreferredTheme(v);
                  widget.onThemeChanged?.call(v);
                  if (ctx.mounted) Navigator.pop(ctx);
                  _snack(l10n.themeChanged(t['name'] as String),
                      bg: Theme.of(context).colorScheme.primary);
                },
              )),
            ]),
          ),
        ),
      ),
    );
  }

  // ── Dialog Langue ──────────────────────────────────────────────────────────

  void _showLanguageDialog(AppLocalizations l10n) {
    final langs = [
      {'code': 'fr', 'name': l10n.french,  'flag': '🇫🇷'},
      {'code': 'en', 'name': l10n.english, 'flag': '🇺🇸'},
    ];
    final langSvc = Provider.of<LanguageService>(context, listen: false);

    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        backgroundColor: AppTheme.getCardBackground(context),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 400),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              _dialogTitle(l10n.chooseLanguage, l10n.selectInterfaceLanguage),
              const SizedBox(height: 16),
              ...langs.map((lang) => RadioListTile<String>(
                title: Row(children: [
                  Text(lang['flag'] as String),
                  const SizedBox(width: 12),
                  Text(lang['name'] as String,
                      style: TextStyle(
                          color: AppTheme.getTextPrimary(context))),
                ]),
                value: lang['code'] as String,
                groupValue: _selectedLanguage,
                activeColor: Theme.of(context).colorScheme.primary,
                onChanged: (v) async {
                  if (v == null) return;
                  setState(() => _selectedLanguage = v);
                  await _preferenceService.setPreferredLanguage(v);
                  final countryCode = v == 'en' ? 'US' : 'FR';
                  await langSvc.setLocale(Locale(v, countryCode));
                  if (ctx.mounted) Navigator.pop(ctx);
                  _snack(l10n.languageChanged(lang['name'] as String),
                      bg: Theme.of(context).colorScheme.primary);
                },
              )),
            ]),
          ),
        ),
      ),
    );
  }

  // ── Dialog Changement Mot de Passe ─────────────────────────────────────────
  // Identique au mobile — utilise le même endpoint PUT /api/users/change-password
  // via AuthProvider.changePassword()

  void _showChangePasswordDialog(AppLocalizations l10n) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final oldCtrl  = TextEditingController();
    final newCtrl  = TextEditingController();
    final confCtrl = TextEditingController();
    final formKey  = GlobalKey<FormState>();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (ctx, setSt) {
          bool oldVis = false, newVis = false, confVis = false;
          bool isSaving = false;

          return Dialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            backgroundColor: AppTheme.getCardBackground(context),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(28),
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ── En-tête ──
                      Row(children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Theme.of(context)
                                .colorScheme
                                .primary
                                .withOpacity(0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(Icons.lock_reset_rounded,
                              color: Theme.of(context).colorScheme.primary,
                              size: 22),
                        ),
                        const SizedBox(width: 14),
                        Text(l10n.changePassword,
                            style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.getTextPrimary(context))),
                        const Spacer(),
                        IconButton(
                          onPressed: isSaving
                              ? null
                              : () {
                            _disposeControllers(
                                [oldCtrl, newCtrl, confCtrl]);
                            Navigator.pop(dialogCtx);
                          },
                          icon: Icon(Icons.close,
                              color: AppTheme.getTextSecondary(context)),
                        ),
                      ]),
                      const SizedBox(height: 20),

                      // ── Encart exigences ──
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: isDark
                              ? Colors.blue.shade900.withOpacity(0.2)
                              : Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                              color: isDark
                                  ? Colors.blue.shade700
                                  : Colors.blue.shade200),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(children: [
                              Icon(Icons.info_outline,
                                  size: 15,
                                  color: isDark
                                      ? Colors.blue.shade300
                                      : Colors.blue.shade700),
                              const SizedBox(width: 6),
                              Text(l10n.passwordReqs,
                                  style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                      color: isDark
                                          ? Colors.blue.shade300
                                          : Colors.blue.shade700)),
                            ]),
                            const SizedBox(height: 8),
                            for (final r in [
                              l10n.pwdMin6,
                              l10n.pwdUppercase,
                              l10n.pwdDigit
                            ])
                              Padding(
                                padding:
                                const EdgeInsets.only(left: 6, top: 4),
                                child: Row(children: [
                                  Icon(Icons.check_circle_outline,
                                      size: 13,
                                      color: isDark
                                          ? Colors.blue.shade300
                                          : Colors.blue.shade700),
                                  const SizedBox(width: 6),
                                  Text(r,
                                      style: TextStyle(
                                          fontSize: 12,
                                          color: isDark
                                              ? Colors.blue.shade300
                                              : Colors.blue.shade700)),
                                ]),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      // ── Champs ──
                      _pwdField(
                        ctrl: oldCtrl,
                        label: l10n.oldPassword,
                        visible: oldVis,
                        isDark: isDark,
                        onToggle: () => setSt(() => oldVis = !oldVis),
                        validator: (v) =>
                        (v == null || v.isEmpty) ? l10n.required_ : null,
                      ),
                      const SizedBox(height: 14),
                      _pwdField(
                        ctrl: newCtrl,
                        label: l10n.newPassword,
                        visible: newVis,
                        isDark: isDark,
                        onToggle: () => setSt(() => newVis = !newVis),
                        validator: (v) {
                          if (v == null || v.isEmpty) return l10n.required_;
                          if (v.length < 6) return l10n.pwdMin6err;
                          if (!RegExp(r'[A-Z]').hasMatch(v))
                            return l10n.pwdUppercaseErr;
                          if (!RegExp(r'[0-9]').hasMatch(v))
                            return l10n.pwdDigitErr;
                          return null;
                        },
                      ),
                      const SizedBox(height: 14),
                      _pwdField(
                        ctrl: confCtrl,
                        label: l10n.confirmPassword,
                        visible: confVis,
                        isDark: isDark,
                        onToggle: () => setSt(() => confVis = !confVis),
                        validator: (v) =>
                        v != newCtrl.text ? l10n.pwdMismatch : null,
                      ),
                      const SizedBox(height: 24),

                      // ── Boutons ──
                      Row(mainAxisAlignment: MainAxisAlignment.end, children: [
                        TextButton(
                          onPressed: isSaving
                              ? null
                              : () {
                            _disposeControllers(
                                [oldCtrl, newCtrl, confCtrl]);
                            Navigator.pop(dialogCtx);
                          },
                          child: Text(l10n.cancel,
                              style: TextStyle(
                                  color: AppTheme.getTextSecondary(context))),
                        ),
                        const SizedBox(width: 12),
                        ElevatedButton.icon(
                          onPressed: isSaving
                              ? null
                              : () async {
                            if (!formKey.currentState!.validate()) return;

                            setSt(() => isSaving = true);
                            try {
                              final auth = Provider.of<AuthProvider>(
                                  context,
                                  listen: false);
                              final ok = await auth.changePassword(
                                ancienMotDePasse: oldCtrl.text.trim(),
                                nouveauMotDePasse: newCtrl.text.trim(),
                                confirmationNouveauMotDePasse:
                                confCtrl.text.trim(),
                              );
                              if (context.mounted) {
                                Navigator.pop(dialogCtx);
                                _snack(
                                  ok
                                      ? l10n.passwordChanged
                                      : auth.errorMessage ?? l10n.error,
                                  bg: ok ? Colors.green : Colors.red,
                                );
                              }
                            } catch (e) {
                              if (context.mounted) {
                                Navigator.pop(dialogCtx);
                                _snack('${l10n.error}: $e',
                                    bg: Colors.red);
                              }
                            } finally {
                              _disposeControllers(
                                  [oldCtrl, newCtrl, confCtrl]);
                            }
                          },
                          icon: isSaving
                              ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white))
                              : const Icon(Icons.check_rounded,
                              size: 18, color: Colors.white),
                          label: Text(
                              isSaving ? l10n.saving : l10n.change,
                              style: const TextStyle(color: Colors.white)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                            Theme.of(context).colorScheme.primary,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 24, vertical: 14),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10)),
                          ),
                        ),
                      ]),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // ── Champ mot de passe réutilisable ────────────────────────────────────────

  Widget _pwdField({
    required TextEditingController ctrl,
    required String label,
    required bool visible,
    required bool isDark,
    required VoidCallback onToggle,
    required String? Function(String?) validator,
  }) {
    return TextFormField(
      controller: ctrl,
      obscureText: !visible,
      style: TextStyle(
          color: isDark ? Colors.white : AppTheme.getTextPrimary(context)),
      decoration: InputDecoration(
        labelText: label,
        labelStyle:
        TextStyle(color: AppTheme.getTextSecondary(context), fontSize: 14),
        prefixIcon: Icon(Icons.lock_outline,
            size: 20, color: AppTheme.getTextSecondary(context)),
        suffixIcon: IconButton(
          icon: Icon(visible ? Icons.visibility : Icons.visibility_off,
              size: 20, color: AppTheme.getTextSecondary(context)),
          onPressed: onToggle,
        ),
        filled: true,
        fillColor: isDark
            ? Colors.grey.shade900.withOpacity(0.3)
            : Colors.grey.shade50,
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide:
            BorderSide(color: AppTheme.getBorderColor(context))),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide:
            BorderSide(color: AppTheme.getBorderColor(context))),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(
                color: Theme.of(context).colorScheme.primary, width: 2)),
        errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide:
            const BorderSide(color: Color(0xFFEF4444), width: 1.5)),
      ),
      validator: validator,
    );
  }

  // ── Helper titre de dialog ─────────────────────────────────────────────────

  Widget _dialogTitle(String title, String subtitle) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(title,
          style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppTheme.getTextPrimary(context))),
      const SizedBox(height: 6),
      Text(subtitle,
          style: TextStyle(color: AppTheme.getTextSecondary(context))),
    ]);
  }

  void _disposeControllers(List<TextEditingController> ctrls) {
    for (final c in ctrls) {
      c.dispose();
    }
  }
}

// ══════════════════════════════════════════════════════════════
// Widget carte interne
// ══════════════════════════════════════════════════════════════

class _Card extends StatelessWidget {
  final bool isDark;
  final IconData icon;
  final Color iconColor;
  final String title;
  final List<Widget> children;

  const _Card({
    required this.isDark,
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: isDark ? 4 : 2,
      color: AppTheme.getCardBackground(context),
      child: Container(
        padding: const EdgeInsets.all(20),
        constraints: const BoxConstraints(minHeight: 200),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isDark
                      ? iconColor.withOpacity(0.25)
                      : iconColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon,
                    color: isDark
                        ? iconColor.withOpacity(0.9)
                        : iconColor,
                    size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(title,
                    style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.getTextPrimary(context))),
              ),
            ]),
            const SizedBox(height: 24),
            ...children,
          ],
        ),
      ),
    );
  }
}