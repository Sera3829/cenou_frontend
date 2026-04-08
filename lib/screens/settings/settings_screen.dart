import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:local_auth/local_auth.dart';
import '../../config/theme.dart';
import '../../providers/auth_provider.dart';
import '../../services/preference_service.dart';
import '../../services/language_service.dart';
import '../../utils/mobile_responsive.dart';
import '../../l10n/app_localizations.dart';

/// Écran des paramètres — responsive mobile/tablette.
/// Le changement de langue est immédiat : plus de dialog de redémarrage.
class SettingsScreen extends StatefulWidget {
  final Function(String)? onThemeChanged;
  const SettingsScreen({Key? key, this.onThemeChanged}) : super(key: key);

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _notificationsEnabled = true;
  bool _biometricEnabled     = false;
  String _selectedLanguage   = 'fr';
  String _selectedTheme      = 'system';
  bool _isBiometricAvailable = false;
  bool _isLoading            = true;

  final _localAuth   = LocalAuthentication();
  final _prefService = PreferenceService();

  @override
  void initState() {
    super.initState();
    _loadPreferences();
    _checkBiometric();
  }

  Future<void> _loadPreferences() async {
    try {
      _notificationsEnabled = await _prefService.getNotificationsEnabled();
      _selectedLanguage     = await _prefService.getPreferredLanguage();
      _selectedTheme        = await _prefService.getPreferredTheme();
      _biometricEnabled     = await _prefService.getBiometricEnabled();
      if (mounted) {
        final auth = context.read<AuthProvider>();
        auth.updateNotificationPref(_notificationsEnabled);
        auth.updateLanguage(_selectedLanguage);
        auth.updateTheme(_selectedTheme);
      }
    } catch (e) {
      debugPrint('Erreur préférences: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _checkBiometric() async {
    try {
      _isBiometricAvailable = await _localAuth.canCheckBiometrics;
      if (mounted) setState(() {});
    } catch (_) {}
  }

  void _snack(String msg, {Color bg = Colors.orange}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: bg,
      behavior: SnackBarBehavior.floating,
    ));
  }

  // ── Build ────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final l10n   = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.settings,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 19)),
        centerTitle: true,
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        elevation: 1,
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: AppTheme.primaryColor))
          : LayoutBuilder(
        builder: (context, constraints) {
          final config = ResponsiveConfig.fromConstraints(constraints);
          final hPad = config.isSmall ? 12.0 : 16.0;

          return ListView(
            padding: EdgeInsets.fromLTRB(
                hPad, config.isSmall ? 12 : 16, hPad, 32),
            children: config.isTablet
                ? _buildTabletLayout(authProvider, isDark, config, l10n)
                : _buildMobileLayout(authProvider, isDark, config, l10n),
          );
        },
      ),
    );
  }

  List<Widget> _buildMobileLayout(AuthProvider auth, bool isDark,
      ResponsiveConfig config, AppLocalizations l10n) {
    return [
      _SectionTitle(text: l10n.preferences, isDark: isDark, config: config),
      _buildPreferencesCard(auth, isDark, config, l10n),
      SizedBox(height: config.isSmall ? 18 : 24),
      _SectionTitle(text: l10n.security, isDark: isDark, config: config),
      _buildSecurityCard(isDark, config, l10n),
      SizedBox(height: config.isSmall ? 18 : 24),
      _SectionTitle(text: l10n.helpSupport, isDark: isDark, config: config),
      _buildHelpCard(isDark, config, l10n),
      SizedBox(height: config.isSmall ? 18 : 24),
      _buildAppInfo(auth, isDark, config, l10n),
    ];
  }

  List<Widget> _buildTabletLayout(AuthProvider auth, bool isDark,
      ResponsiveConfig config, AppLocalizations l10n) {
    return [
      Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Expanded(child: Column(children: [
          _SectionTitle(text: l10n.preferences, isDark: isDark, config: config),
          _buildPreferencesCard(auth, isDark, config, l10n),
        ])),
        const SizedBox(width: 16),
        Expanded(child: Column(children: [
          _SectionTitle(text: l10n.security, isDark: isDark, config: config),
          _buildSecurityCard(isDark, config, l10n),
        ])),
      ]),
      const SizedBox(height: 24),
      _SectionTitle(text: l10n.helpSupport, isDark: isDark, config: config),
      _buildHelpCard(isDark, config, l10n),
      const SizedBox(height: 24),
      _buildAppInfo(auth, isDark, config, l10n),
    ];
  }

  // ── Carte Préférences ─────────────────────────────────────────────────────

  Widget _buildPreferencesCard(AuthProvider auth, bool isDark,
      ResponsiveConfig config, AppLocalizations l10n) {
    return _SettingsCard(isDark: isDark, children: [
      SwitchListTile(
        value: _notificationsEnabled,
        onChanged: (v) async {
          setState(() => _notificationsEnabled = v);
          await _prefService.setNotificationsEnabled(v);
          auth.updateNotificationPref(v);
        },
        title: _tileTitle(l10n.pushNotif, isDark, config),
        subtitle: _tileSub(l10n.pushNotifSub, isDark, config),
        secondary: Icon(Icons.notifications_rounded,
            color: isDark ? Colors.blue.shade300 : Colors.blue,
            size: config.responsive(small: 22, medium: 24, large: 26)),
        activeColor: AppTheme.primaryColor,
      ),
      _divider(isDark),
      if (_isBiometricAvailable) ...[
        SwitchListTile(
          value: _biometricEnabled,
          onChanged: (v) async {
            if (v) {
              final ok = await _authenticateBiometric(l10n);
              if (!ok) return;
            }
            setState(() => _biometricEnabled = v);
            await _prefService.setBiometricEnabled(v);
          },
          title: _tileTitle(l10n.biometric, isDark, config),
          subtitle: _tileSub(l10n.biometricSub, isDark, config),
          secondary: Icon(Icons.fingerprint_rounded,
              color: isDark ? Colors.green.shade300 : Colors.green,
              size: config.responsive(small: 22, medium: 24, large: 26)),
          activeColor: AppTheme.primaryColor,
        ),
        _divider(isDark),
      ],
      _SettingTile(
        icon: Icons.language_rounded,
        title: l10n.language,
        subtitle: _getLanguageName(_selectedLanguage),
        onTap: () => _showLanguageDialog(l10n),
        isDark: isDark,
        config: config,
      ),
      _divider(isDark),
      _SettingTile(
        icon: Icons.palette_rounded,
        title: l10n.theme,
        subtitle: _getThemeName(_selectedTheme, l10n),
        onTap: () => _showThemeDialog(auth, l10n),
        isDark: isDark,
        config: config,
      ),
    ]);
  }

  // ── Carte Sécurité ─────────────────────────────────────────────────────────

  Widget _buildSecurityCard(bool isDark, ResponsiveConfig config,
      AppLocalizations l10n) {
    return _SettingsCard(isDark: isDark, children: [
      _SettingTile(
          icon: Icons.lock_reset_rounded,
          title: l10n.changePassword,
          subtitle: l10n.changePasswordSub,
          onTap: () => _showChangePasswordDialog(l10n),
          isDark: isDark, config: config),
      _divider(isDark),
      _SettingTile(
          icon: Icons.devices_rounded,
          title: l10n.activeSessions,
          subtitle: l10n.activeSessionsSub,
          onTap: () => _snack('${l10n.activeSessions} — ${l10n.comingSoon}',
              bg: AppTheme.primaryColor),
          isDark: isDark, config: config),
      _divider(isDark),
      _SettingTile(
          icon: Icons.history_rounded,
          title: l10n.loginHistory,
          subtitle: l10n.loginHistorySub,
          onTap: () => _snack('${l10n.loginHistory} — ${l10n.comingSoon}',
              bg: AppTheme.primaryColor),
          isDark: isDark, config: config),
    ]);
  }

  // ── Carte Aide ────────────────────────────────────────────────────────────

  Widget _buildHelpCard(bool isDark, ResponsiveConfig config,
      AppLocalizations l10n) {
    return _SettingsCard(isDark: isDark, children: [
      _SettingTile(
          icon: Icons.help_center_rounded,
          title: l10n.helpCenter,
          subtitle: l10n.helpCenterSub,
          onTap: () => _snack('${l10n.helpCenter} — ${l10n.comingSoon}',
              bg: AppTheme.primaryColor),
          isDark: isDark, config: config),
      _divider(isDark),
      _SettingTile(
          icon: Icons.support_agent_rounded,
          title: l10n.contactUs,
          subtitle: l10n.contactUsSub,
          onTap: () => _showContactDialog(l10n),
          isDark: isDark, config: config),
      _divider(isDark),
      _SettingTile(
          icon: Icons.report_problem_rounded,
          title: l10n.reportBug,
          subtitle: l10n.reportBugSub,
          onTap: () => _showReportDialog(l10n),
          isDark: isDark, config: config),
      _divider(isDark),
      _SettingTile(
          icon: Icons.privacy_tip_rounded,
          title: l10n.privacy,
          subtitle: l10n.privacySub,
          onTap: () => _snack('${l10n.privacy} — ${l10n.comingSoon}',
              bg: AppTheme.primaryColor),
          isDark: isDark, config: config),
    ]);
  }

  // ── App info ──────────────────────────────────────────────────────────────

  Widget _buildAppInfo(AuthProvider auth, bool isDark,
      ResponsiveConfig config, AppLocalizations l10n) {
    if (auth.sessionId == null) {
      WidgetsBinding.instance
          .addPostFrameCallback((_) => auth.generateSessionId());
    }
    final labelSize = config.responsive(small: 11, medium: 12, large: 13);

    return Container(
      padding: EdgeInsets.all(
          config.responsive(small: 14, medium: 16, large: 18)),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: isDark ? Colors.grey.shade800 : Colors.grey[300]!),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(l10n.appInfo,
            style: TextStyle(
                fontSize: labelSize + 2, fontWeight: FontWeight.w600,
                color: isDark ? Colors.white : Colors.black87)),
        const SizedBox(height: 12),
        _infoRow(l10n.version,     '1.0.0',       isDark, labelSize),
        const SizedBox(height: 5),
        _infoRow(l10n.lastUpdate,  '25/03/2026',  isDark, labelSize),
        const SizedBox(height: 5),
        _infoRow(l10n.build,       '2026.1.8.001', isDark, labelSize),
        const SizedBox(height: 5),
        _infoRow(l10n.session,
            auth.sessionId?.substring(0, 8) ?? '---', isDark, labelSize),
        const SizedBox(height: 5),
        _infoRow(l10n.mode,
            auth.isAdmin ? l10n.modeAdmin : l10n.modeMobile,
            isDark, labelSize),
        const SizedBox(height: 5),
        _infoRow(l10n.copyright, l10n.copyrightVal, isDark, labelSize),
      ]),
    );
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  Widget _infoRow(String label, String value, bool isDark, double size) {
    return Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Text(label,
          style: TextStyle(
              fontSize: size,
              color: isDark ? Colors.grey.shade400 : Colors.grey[600])),
      Flexible(
        child: Text(value,
            textAlign: TextAlign.right,
            style: TextStyle(
                fontSize: size, fontWeight: FontWeight.w500,
                color: isDark ? Colors.white : Colors.black87)),
      ),
    ]);
  }

  Widget _divider(bool isDark) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16),
    child: Divider(
        height: 0, thickness: 1,
        color: isDark ? Colors.grey.shade800 : Colors.grey[300]),
  );

  Text _tileTitle(String t, bool isDark, ResponsiveConfig config) => Text(t,
      style: TextStyle(
          fontWeight: FontWeight.w500,
          fontSize: config.responsive(small: 13, medium: 14, large: 15),
          color: isDark ? Colors.white : Colors.black87));

  Text _tileSub(String t, bool isDark, ResponsiveConfig config) => Text(t,
      style: TextStyle(
          fontSize: config.responsive(small: 10, medium: 11, large: 12),
          color: isDark ? Colors.grey.shade400 : Colors.grey[600]));

  String _getLanguageName(String code) =>
      code == 'en' ? 'English' : 'Français';

  String _getThemeName(String t, AppLocalizations l10n) {
    switch (t) {
      case 'light':  return l10n.themeLight;
      case 'dark':   return l10n.themeDark;
      default:       return l10n.themeSystem;
    }
  }

  // ── Dialogue langue ────────────────────────────────────────────────────────
  // ✅ Changement IMMÉDIAT — plus de dialog de redémarrage

  void _showLanguageDialog(AppLocalizations l10n) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final langs = [
      {'code': 'fr', 'name': 'Français', 'flag': '🇫🇷'},
      {'code': 'en', 'name': 'English',  'flag': '🇺🇸'},
    ];
    final langSvc = Provider.of<LanguageService>(context, listen: false);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.45,
        minChildSize: 0.35,
        maxChildSize: 0.7,
        builder: (_, scrollController) => Container(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
            borderRadius:
            const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(children: [
            // Handle
            Container(
              margin: const EdgeInsets.only(top: 10, bottom: 6),
              width: 36, height: 4,
              decoration: BoxDecoration(
                  color: isDark ? Colors.grey.shade600 : Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2)),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Text(l10n.chooseLanguage,
                  style: TextStyle(
                      fontSize: 17, fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white : Colors.black87)),
            ),
            _divider(isDark),
            Expanded(
              child: ListView.separated(
                controller: scrollController,
                padding: EdgeInsets.zero,
                itemCount: langs.length,
                separatorBuilder: (_, __) => _divider(isDark),
                itemBuilder: (_, i) {
                  final l = langs[i];
                  final isSelected = _selectedLanguage == l['code'];
                  return ListTile(
                    onTap: () async {
                      final code = l['code']!;
                      if (code == _selectedLanguage) {
                        Navigator.pop(ctx);
                        return;
                      }

                      // ① Mettre à jour le state local immédiatement
                      setState(() => _selectedLanguage = code);

                      // ② Sauvegarder la préférence
                      await _prefService.setPreferredLanguage(code);

                      // ③ Changer la locale → LanguageService notifie
                      //    → CenouApp.build se reconstruit avec la nouvelle locale
                      //    → MaterialApp reçoit la nouvelle locale
                      //    → AppLocalizations.of(context) retourne les bonnes traductions
                      final countryCode = code == 'en' ? 'US' : 'FR';
                      await langSvc.setLocale(Locale(code, countryCode));

                      // ④ Mettre à jour AuthProvider
                      if (context.mounted) {
                        Provider.of<AuthProvider>(context, listen: false)
                            .updateLanguage(code);
                      }

                      // ⑤ Fermer le bottomSheet
                      if (ctx.mounted) Navigator.pop(ctx);

                      // ⑥ Snack de confirmation (optionnel)
                      if (context.mounted) {
                        _snack(
                          code == 'en'
                              ? '🇺🇸 Language changed to English'
                              : '🇫🇷 Langue changée en Français',
                          bg: AppTheme.primaryColor,
                        );
                      }
                    },
                    leading: Text(l['flag']!, style: const TextStyle(fontSize: 24)),
                    title: Text(l['name']!,
                        style: TextStyle(
                            fontSize: 15,
                            fontWeight: isSelected
                                ? FontWeight.w600
                                : FontWeight.normal,
                            color: isDark ? Colors.white : Colors.black87)),
                    trailing: isSelected
                        ? Icon(Icons.check_rounded,
                        color: AppTheme.primaryColor, size: 22)
                        : null,
                  );
                },
              ),
            ),
          ]),
        ),
      ),
    );
  }

  // ── Dialogue thème ────────────────────────────────────────────────────────

  void _showThemeDialog(AuthProvider auth, AppLocalizations l10n) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final themes = [
      {'code': 'system', 'name': l10n.themeSystem, 'icon': Icons.brightness_auto_rounded},
      {'code': 'light',  'name': l10n.themeLight,  'icon': Icons.light_mode_rounded},
      {'code': 'dark',   'name': l10n.themeDark,   'icon': Icons.dark_mode_rounded},
    ];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.45,
        minChildSize: 0.35,
        maxChildSize: 0.7,
        builder: (_, scrollController) => Container(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
            borderRadius:
            const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(children: [
            Container(
              margin: const EdgeInsets.only(top: 10, bottom: 6),
              width: 36, height: 4,
              decoration: BoxDecoration(
                  color: isDark ? Colors.grey.shade600 : Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2)),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Text(l10n.chooseTheme,
                  style: TextStyle(
                      fontSize: 17, fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white : Colors.black87)),
            ),
            _divider(isDark),
            Expanded(
              child: ListView.separated(
                controller: scrollController,
                padding: EdgeInsets.zero,
                itemCount: themes.length,
                separatorBuilder: (_, __) => _divider(isDark),
                itemBuilder: (_, i) {
                  final t     = themes[i];
                  final code  = t['code'] as String;
                  final name  = t['name'] as String;
                  final icon  = t['icon'] as IconData;
                  final isSel = _selectedTheme == code;
                  return ListTile(
                    onTap: () async {
                      if (code == _selectedTheme) {
                        Navigator.pop(ctx);
                        return;
                      }
                      setState(() => _selectedTheme = code);
                      await _prefService.setPreferredTheme(code);
                      widget.onThemeChanged?.call(code);
                      if (ctx.mounted) Navigator.pop(ctx);
                      _snack(l10n.themeChanged(name), bg: AppTheme.primaryColor);
                    },
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(icon, size: 20,
                          color: isDark ? Colors.blue.shade300 : AppTheme.primaryColor),
                    ),
                    title: Text(name,
                        style: TextStyle(
                            fontSize: 15,
                            fontWeight: isSel ? FontWeight.w600 : FontWeight.normal,
                            color: isDark ? Colors.white : Colors.black87)),
                    trailing: isSel
                        ? Icon(Icons.check_rounded,
                        color: AppTheme.primaryColor, size: 22)
                        : null,
                  );
                },
              ),
            ),
          ]),
        ),
      ),
    );
  }

  // ── Dialogue changement mot de passe ──────────────────────────────────────

  void _showChangePasswordDialog(AppLocalizations l10n) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final oldCtrl  = TextEditingController();
    final newCtrl  = TextEditingController();
    final confCtrl = TextEditingController();
    final formKey  = GlobalKey<FormState>();
    bool oldVis = false, newVis = false, confVis = false;

    showDialog(
      context: context,
      builder: (dialogCtx) => LayoutBuilder(
        builder: (ctx, constraints) {
          final fs = constraints.maxWidth < 360 ? 12.0 : 13.0;
          final sp = constraints.maxWidth < 360 ? 12.0 : 14.0;
          return Dialog(
            backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: StatefulBuilder(
                  builder: (sbCtx, setSt) => Form(
                    key: formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(children: [
                          Icon(Icons.lock_reset_rounded,
                              color: isDark ? Colors.blue.shade300 : AppTheme.primaryColor),
                          const SizedBox(width: 12),
                          Text(l10n.changePassword,
                              style: TextStyle(
                                  fontSize: fs + 4, fontWeight: FontWeight.bold,
                                  color: isDark ? Colors.white : Colors.black87)),
                        ]),
                        const SizedBox(height: 16),
                        // Exigences
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade50.withOpacity(isDark ? 0.1 : 0.5),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                                color: isDark ? Colors.blue.shade700 : Colors.blue.shade200),
                          ),
                          child: Column(crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(children: [
                                  Icon(Icons.info_outline, size: 15,
                                      color: isDark ? Colors.blue.shade300 : Colors.blue.shade700),
                                  const SizedBox(width: 6),
                                  Text(l10n.passwordReqs,
                                      style: TextStyle(
                                          fontSize: fs, fontWeight: FontWeight.bold,
                                          color: isDark ? Colors.blue.shade300 : Colors.blue.shade700)),
                                ]),
                                const SizedBox(height: 6),
                                for (final r in [l10n.pwdMin6, l10n.pwdUppercase, l10n.pwdDigit])
                                  Padding(
                                    padding: const EdgeInsets.only(left: 6, top: 3),
                                    child: Row(children: [
                                      Icon(Icons.check_circle_outline, size: fs,
                                          color: isDark ? Colors.blue.shade300 : Colors.blue.shade700),
                                      const SizedBox(width: 6),
                                      Text(r,
                                          style: TextStyle(
                                              fontSize: fs - 1,
                                              color: isDark ? Colors.blue.shade300 : Colors.blue.shade700)),
                                    ]),
                                  ),
                              ]),
                        ),
                        const SizedBox(height: 16),
                        _pwdField(oldCtrl, l10n.oldPassword, oldVis, isDark,
                                () => setSt(() => oldVis = !oldVis),
                                (v) => (v == null || v.isEmpty) ? l10n.required_ : null, fs),
                        SizedBox(height: sp),
                        _pwdField(newCtrl, l10n.newPassword, newVis, isDark,
                                () => setSt(() => newVis = !newVis),
                                (v) {
                              if (v == null || v.isEmpty) return l10n.required_;
                              if (v.length < 6) return l10n.pwdMin6err;
                              if (!RegExp(r'[A-Z]').hasMatch(v)) return l10n.pwdUppercaseErr;
                              if (!RegExp(r'[0-9]').hasMatch(v)) return l10n.pwdDigitErr;
                              return null;
                            }, fs),
                        SizedBox(height: sp),
                        _pwdField(confCtrl, l10n.confirmPassword, confVis, isDark,
                                () => setSt(() => confVis = !confVis),
                                (v) => v != newCtrl.text ? l10n.pwdMismatch : null, fs),
                        const SizedBox(height: 20),
                        Row(mainAxisAlignment: MainAxisAlignment.end, children: [
                          TextButton(
                            onPressed: () {
                              for (final c in [oldCtrl, newCtrl, confCtrl]) c.dispose();
                              Navigator.pop(dialogCtx);
                            },
                            child: Text(l10n.cancel,
                                style: TextStyle(
                                    fontSize: fs,
                                    color: isDark ? Colors.grey.shade400 : Colors.grey.shade700)),
                          ),
                          const SizedBox(width: 12),
                          ElevatedButton(
                            onPressed: () async {
                              if (!formKey.currentState!.validate()) return;
                              Navigator.pop(dialogCtx);
                              showDialog(
                                context: this.context,
                                barrierDismissible: false,
                                builder: (_) => const Center(
                                    child: CircularProgressIndicator(
                                        color: Colors.green, strokeWidth: 3)),
                              );
                              try {
                                final auth = Provider.of<AuthProvider>(
                                    this.context, listen: false);
                                final ok = await auth.changePassword(
                                  ancienMotDePasse: oldCtrl.text,
                                  nouveauMotDePasse: newCtrl.text,
                                  confirmationNouveauMotDePasse: confCtrl.text,
                                );
                                if (this.context.mounted) Navigator.pop(this.context);
                                _snack(ok ? l10n.passwordChanged
                                    : auth.errorMessage ?? l10n.error,
                                    bg: ok ? Colors.green : Colors.red);
                              } catch (e) {
                                if (this.context.mounted) Navigator.pop(this.context);
                                _snack('${l10n.error}: $e', bg: Colors.red);
                              } finally {
                                for (final c in [oldCtrl, newCtrl, confCtrl]) c.dispose();
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor:
                              isDark ? Colors.blue.shade700 : AppTheme.primaryColor,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12)),
                            ),
                            child: Text(l10n.change),
                          ),
                        ]),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _pwdField(
      TextEditingController ctrl, String label, bool visible, bool isDark,
      VoidCallback onToggle, String? Function(String?) validator, double fs) {
    return TextFormField(
      controller: ctrl,
      obscureText: !visible,
      style: TextStyle(fontSize: fs, color: isDark ? Colors.white : Colors.black87),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(
            fontSize: fs, color: isDark ? Colors.grey.shade400 : Colors.grey.shade700),
        prefixIcon: Icon(Icons.lock_outline, size: fs + 2,
            color: isDark ? Colors.grey.shade400 : Colors.grey.shade600),
        suffixIcon: IconButton(
          icon: Icon(visible ? Icons.visibility : Icons.visibility_off,
              size: fs + 2,
              color: isDark ? Colors.grey.shade400 : Colors.grey.shade600),
          onPressed: onToggle,
        ),
        filled: true,
        fillColor: isDark ? const Color(0xFF2D2D2D) : Colors.grey.shade50,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
                color: isDark ? Colors.grey.shade700 : Colors.grey.shade300)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
                color: isDark ? Colors.grey.shade700 : Colors.grey.shade300)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
                color: isDark ? Colors.blue.shade300 : AppTheme.primaryColor,
                width: 2)),
      ),
      validator: validator,
    );
  }

  // ── Dialogue contact ──────────────────────────────────────────────────────

  void _showContactDialog(AppLocalizations l10n) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(l10n.supportTitle,
            style: TextStyle(color: isDark ? Colors.white : Colors.black87)),
        content: Column(mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(l10n.supportContact,
                  style: TextStyle(
                      color: isDark ? Colors.grey.shade300 : Colors.black87)),
              const SizedBox(height: 12),
              _contactRow(Icons.email_rounded,        '70382983b@gmail.com',    isDark),
              const SizedBox(height: 8),
              _contactRow(Icons.phone_rounded,        '+226 70 38 29 83',       isDark),
              const SizedBox(height: 8),
              _contactRow(Icons.access_time_rounded,  l10n.supportHours,        isDark),
              const SizedBox(height: 8),
              _contactRow(Icons.location_on_rounded,  'Bobo Dioulasso, Belle Ville', isDark),
            ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx),
              child: Text(l10n.close,
                  style: TextStyle(
                      color: isDark ? Colors.grey.shade400 : null))),
          ElevatedButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(l10n.sendEmail)),
        ],
      ),
    );
  }

  Widget _contactRow(IconData icon, String text, bool isDark) {
    return Row(children: [
      Icon(icon, size: 17, color: AppTheme.primaryColor),
      const SizedBox(width: 10),
      Flexible(child: Text(text,
          style: TextStyle(
              color: isDark ? Colors.white : Colors.black87))),
    ]);
  }

  // ── Dialogue signalement bug ──────────────────────────────────────────────

  void _showReportDialog(AppLocalizations l10n) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(l10n.reportTitle,
            style: TextStyle(color: isDark ? Colors.white : Colors.black87)),
        content: Text(l10n.reportContent,
            style: TextStyle(
                color: isDark ? Colors.grey.shade300 : Colors.black87)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx),
              child: Text(l10n.cancel,
                  style: TextStyle(
                      color: isDark ? Colors.grey.shade400 : null))),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.pushNamed(context, '/signalements');
            },
            child: Text(l10n.report),
          ),
        ],
      ),
    );
  }

  // ── Biométrie ─────────────────────────────────────────────────────────────

  Future<bool> _authenticateBiometric(AppLocalizations l10n) async {
    try {
      final ok = await _localAuth.authenticate(
          localizedReason: l10n.biometricSub);
      _snack(ok ? l10n.biometricEnabled : l10n.biometricCancelled,
          bg: ok ? Colors.green : Colors.orange);
      return ok;
    } on PlatformException catch (e) {
      _snack('${l10n.error}: ${e.message}', bg: Colors.red);
      return false;
    }
  }
}

// ══════════════════════════════════════════════════════════════
// Widgets internes
// ══════════════════════════════════════════════════════════════

class _SectionTitle extends StatelessWidget {
  final String text;
  final bool isDark;
  final ResponsiveConfig config;
  const _SectionTitle(
      {required this.text, required this.isDark, required this.config});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(text,
          style: TextStyle(
              fontSize: config.responsive(small: 13, medium: 15, large: 16),
              fontWeight: FontWeight.w600,
              color: isDark
                  ? Colors.blue.shade300
                  : Theme.of(context).colorScheme.primary)),
    );
  }
}

class _SettingsCard extends StatelessWidget {
  final bool isDark;
  final List<Widget> children;
  const _SettingsCard({required this.isDark, required this.children});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: isDark ? 4 : 2,
      color: isDark ? const Color(0xFF1E1E1E) : null,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Column(children: children),
    );
  }
}

class _SettingTile extends StatelessWidget {
  final IconData icon;
  final String title, subtitle;
  final VoidCallback onTap;
  final bool isDark;
  final ResponsiveConfig config;
  const _SettingTile(
      {required this.icon, required this.title, required this.subtitle,
        required this.onTap, required this.isDark, required this.config});

  @override
  Widget build(BuildContext context) {
    final iconSize  = config.responsive(small: 20, medium: 22, large: 24);
    final titleSize = config.responsive(small: 13, medium: 14, large: 15);
    final subSize   = config.responsive(small: 10, medium: 11, large: 12);
    final iconPad   = config.responsive(small: 8,  medium: 10, large: 11);

    return ListTile(
      onTap: onTap,
      leading: Container(
        padding: EdgeInsets.all(iconPad),
        decoration: BoxDecoration(
          color: isDark
              ? AppTheme.primaryColor.withOpacity(0.2)
              : AppTheme.primaryColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, size: iconSize,
            color: isDark ? Colors.blue.shade300 : AppTheme.primaryColor),
      ),
      title: Text(title,
          style: TextStyle(
              fontWeight: FontWeight.w500, fontSize: titleSize,
              color: isDark ? Colors.white : Colors.black87)),
      subtitle: Text(subtitle,
          style: TextStyle(
              fontSize: subSize,
              color: isDark ? Colors.grey.shade400 : Colors.grey[600])),
      trailing: Icon(Icons.chevron_right_rounded,
          color: isDark ? Colors.grey.shade600 : Colors.grey,
          size: config.responsive(small: 18, medium: 20, large: 22)),
    );
  }
}