import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:local_auth/local_auth.dart';
import '../../config/theme.dart';
import '../../config/app_version.dart';
import '../../providers/auth_provider.dart';
import '../../services/preference_service.dart';
import '../../services/language_service.dart';
import '../../utils/mobile_responsive.dart';
import '../../l10n/app_localizations.dart';
import 'widgets/settings_widgets.dart';
import 'dialogs/choice_sheet.dart';
import 'dialogs/change_password_dialog.dart';
import 'dialogs/contact_dialog.dart';
import 'dialogs/report_dialog.dart';

/// Écran des paramètres — responsive mobile/tablette.
/// Le changement de langue est immédiat : plus de dialog de redémarrage.
class SettingsScreen extends StatefulWidget {
  final Function(String)? onThemeChanged;
  const SettingsScreen({super.key, this.onThemeChanged});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _notificationsEnabled = true;
  bool _biometricEnabled = false;
  String _selectedLanguage = 'fr';
  String _selectedTheme = 'system';
  bool _isBiometricAvailable = false;
  bool _isLoading = true;

  final _localAuth = LocalAuthentication();
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
      _selectedLanguage = await _prefService.getPreferredLanguage();
      _selectedTheme = await _prefService.getPreferredTheme();
      _biometricEnabled = await _prefService.getBiometricEnabled();
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

  // ── Build ────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context);

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
          ? Center(
              child: CircularProgressIndicator(color: AppTheme.primaryColor))
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
      SettingsSectionTitle(
          text: l10n.preferences, isDark: isDark, config: config),
      _buildPreferencesCard(auth, isDark, config, l10n),
      SizedBox(height: config.isSmall ? 18 : 24),
      SettingsSectionTitle(text: l10n.security, isDark: isDark, config: config),
      _buildSecurityCard(isDark, config, l10n),
      SizedBox(height: config.isSmall ? 18 : 24),
      SettingsSectionTitle(
          text: l10n.helpSupport, isDark: isDark, config: config),
      _buildHelpCard(isDark, config, l10n),
      SizedBox(height: config.isSmall ? 18 : 24),
      _buildAppInfo(auth, isDark, config, l10n),
    ];
  }

  List<Widget> _buildTabletLayout(AuthProvider auth, bool isDark,
      ResponsiveConfig config, AppLocalizations l10n) {
    return [
      Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Expanded(
            child: Column(children: [
          SettingsSectionTitle(
              text: l10n.preferences, isDark: isDark, config: config),
          _buildPreferencesCard(auth, isDark, config, l10n),
        ])),
        const SizedBox(width: 16),
        Expanded(
            child: Column(children: [
          SettingsSectionTitle(
              text: l10n.security, isDark: isDark, config: config),
          _buildSecurityCard(isDark, config, l10n),
        ])),
      ]),
      const SizedBox(height: 24),
      SettingsSectionTitle(
          text: l10n.helpSupport, isDark: isDark, config: config),
      _buildHelpCard(isDark, config, l10n),
      const SizedBox(height: 24),
      _buildAppInfo(auth, isDark, config, l10n),
    ];
  }

  // ── Carte Préférences ─────────────────────────────────────────────────────

  Widget _buildPreferencesCard(AuthProvider auth, bool isDark,
      ResponsiveConfig config, AppLocalizations l10n) {
    return SettingsCard(isDark: isDark, children: [
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
      settingsDivider(isDark),
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
        settingsDivider(isDark),
      ],
      SettingTile(
        icon: Icons.language_rounded,
        title: l10n.language,
        subtitle: _getLanguageName(_selectedLanguage),
        onTap: () => _showLanguageDialog(l10n),
        isDark: isDark,
        config: config,
      ),
      settingsDivider(isDark),
      SettingTile(
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

  Widget _buildSecurityCard(
      bool isDark, ResponsiveConfig config, AppLocalizations l10n) {
    return SettingsCard(isDark: isDark, children: [
      SettingTile(
          icon: Icons.lock_reset_rounded,
          title: l10n.changePassword,
          subtitle: l10n.changePasswordSub,
          onTap: () => showChangePasswordDialog(context, l10n),
          isDark: isDark,
          config: config),
      settingsDivider(isDark),
      SettingTile(
          icon: Icons.devices_rounded,
          title: l10n.activeSessions,
          subtitle: l10n.activeSessionsSub,
          onTap: () => afficherSnack(
              context, '${l10n.activeSessions} — ${l10n.comingSoon}',
              bg: AppTheme.primaryColor),
          isDark: isDark,
          config: config),
      settingsDivider(isDark),
      SettingTile(
          icon: Icons.history_rounded,
          title: l10n.loginHistory,
          subtitle: l10n.loginHistorySub,
          onTap: () => afficherSnack(
              context, '${l10n.loginHistory} — ${l10n.comingSoon}',
              bg: AppTheme.primaryColor),
          isDark: isDark,
          config: config),
    ]);
  }

  // ── Carte Aide ────────────────────────────────────────────────────────────

  Widget _buildHelpCard(
      bool isDark, ResponsiveConfig config, AppLocalizations l10n) {
    return SettingsCard(isDark: isDark, children: [
      SettingTile(
          icon: Icons.help_center_rounded,
          title: l10n.helpCenter,
          subtitle: l10n.helpCenterSub,
          onTap: () => afficherSnack(
              context, '${l10n.helpCenter} — ${l10n.comingSoon}',
              bg: AppTheme.primaryColor),
          isDark: isDark,
          config: config),
      settingsDivider(isDark),
      SettingTile(
          icon: Icons.support_agent_rounded,
          title: l10n.contactUs,
          subtitle: l10n.contactUsSub,
          onTap: () => showContactDialog(context, l10n),
          isDark: isDark,
          config: config),
      settingsDivider(isDark),
      SettingTile(
          icon: Icons.report_problem_rounded,
          title: l10n.reportBug,
          subtitle: l10n.reportBugSub,
          onTap: () => showReportDialog(context, l10n),
          isDark: isDark,
          config: config),
      settingsDivider(isDark),
      SettingTile(
          icon: Icons.privacy_tip_rounded,
          title: l10n.privacy,
          subtitle: l10n.privacySub,
          onTap: () => afficherSnack(
              context, '${l10n.privacy} — ${l10n.comingSoon}',
              bg: AppTheme.primaryColor),
          isDark: isDark,
          config: config),
    ]);
  }

  // ── App info ──────────────────────────────────────────────────────────────

  Widget _buildAppInfo(AuthProvider auth, bool isDark, ResponsiveConfig config,
      AppLocalizations l10n) {
    final labelSize = config.responsive(small: 11, medium: 12, large: 13);

    // Version affichée : « 1.1.0 (a1b2c3d) » si le commit est injecté au build.
    final versionLabel = AppVersion.commit.isNotEmpty
        ? '${AppVersion.version} (${AppVersion.commit})'
        : AppVersion.version;

    return Container(
      padding:
          EdgeInsets.all(config.responsive(small: 14, medium: 16, large: 18)),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: isDark ? Colors.grey.shade800 : Colors.grey[300]!),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(l10n.appInfo,
            style: TextStyle(
                fontSize: labelSize + 2,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white : Colors.black87)),
        const SizedBox(height: 12),
        _infoRow(l10n.version, versionLabel, isDark, labelSize),
        // La date de mise à jour n'apparaît que si elle est réelle
        // (injectée au build) — jamais de valeur codée en dur.
        if (AppVersion.lastUpdate != null) ...[
          const SizedBox(height: 5),
          _infoRow(l10n.lastUpdate, AppVersion.lastUpdate!, isDark, labelSize),
        ],
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
                fontSize: size,
                fontWeight: FontWeight.w500,
                color: isDark ? Colors.white : Colors.black87)),
      ),
    ]);
  }

  Text _tileTitle(String t, bool isDark, ResponsiveConfig config) => Text(t,
      style: TextStyle(
          fontWeight: FontWeight.w500,
          fontSize: config.responsive(small: 13, medium: 14, large: 15),
          color: isDark ? Colors.white : Colors.black87));

  Text _tileSub(String t, bool isDark, ResponsiveConfig config) => Text(t,
      style: TextStyle(
          fontSize: config.responsive(small: 10, medium: 11, large: 12),
          color: isDark ? Colors.grey.shade400 : Colors.grey[600]));

  String _getLanguageName(String code) => code == 'en' ? 'English' : 'Français';

  String _getThemeName(String t, AppLocalizations l10n) {
    switch (t) {
      case 'light':
        return l10n.themeLight;
      case 'dark':
        return l10n.themeDark;
      default:
        return l10n.themeSystem;
    }
  }

  // ── Choix de la langue ────────────────────────────────────────────────────
  // Changement IMMÉDIAT — plus de dialogue de redémarrage.

  void _showLanguageDialog(AppLocalizations l10n) {
    final langSvc = Provider.of<LanguageService>(context, listen: false);

    showChoixSheet(
      context,
      titre: l10n.chooseLanguage,
      codeSelectionne: _selectedLanguage,
      options: const [
        ChoixSheetOption(
            code: 'fr',
            libelle: 'Français',
            vignette: Text('🇫🇷', style: TextStyle(fontSize: 24))),
        ChoixSheetOption(
            code: 'en',
            libelle: 'English',
            vignette: Text('🇺🇸', style: TextStyle(fontSize: 24))),
      ],
      onSelect: (code) async {
        setState(() => _selectedLanguage = code);
        await _prefService.setPreferredLanguage(code);

        // LanguageService notifie → MaterialApp reçoit la nouvelle locale
        // → AppLocalizations.of(context) renvoie les bonnes traductions.
        await langSvc.setLocale(Locale(code, code == 'en' ? 'US' : 'FR'));

        if (!mounted) return;
        Provider.of<AuthProvider>(context, listen: false).updateLanguage(code);
        afficherSnack(
          context,
          code == 'en'
              ? '🇺🇸 Language changed to English'
              : '🇫🇷 Langue changée en Français',
          bg: AppTheme.primaryColor,
        );
      },
    );
  }

  // ── Choix du thème ────────────────────────────────────────────────────────

  void _showThemeDialog(AuthProvider auth, AppLocalizations l10n) {
    final themes = <String, (String, IconData)>{
      'system': (l10n.themeSystem, Icons.brightness_auto_rounded),
      'light': (l10n.themeLight, Icons.light_mode_rounded),
      'dark': (l10n.themeDark, Icons.dark_mode_rounded),
    };
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showChoixSheet(
      context,
      titre: l10n.chooseTheme,
      codeSelectionne: _selectedTheme,
      options: [
        for (final entree in themes.entries)
          ChoixSheetOption(
            code: entree.key,
            libelle: entree.value.$1,
            vignette: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(entree.value.$2,
                  size: 20,
                  color: isDark ? Colors.blue.shade300 : AppTheme.primaryColor),
            ),
          ),
      ],
      onSelect: (code) async {
        setState(() => _selectedTheme = code);
        await _prefService.setPreferredTheme(code);
        widget.onThemeChanged?.call(code);

        if (!mounted) return;
        afficherSnack(context, l10n.themeChanged(themes[code]!.$1),
            bg: AppTheme.primaryColor);
      },
    );
  }

  // ── Biométrie ─────────────────────────────────────────────────────────────

  Future<bool> _authenticateBiometric(AppLocalizations l10n) async {
    try {
      final ok =
          await _localAuth.authenticate(localizedReason: l10n.biometricSub);

      // L'invite biométrique est bloquante : l'écran peut avoir été quitté
      // entre-temps, auquel cas il n'y a plus de contexte pour le message.
      if (!mounted) return ok;

      afficherSnack(
          context, ok ? l10n.biometricEnabled : l10n.biometricCancelled,
          bg: ok ? Colors.green : Colors.orange);
      return ok;
    } on PlatformException catch (e) {
      if (!mounted) return false;

      afficherSnack(context, '${l10n.error}: ${e.message}', bg: Colors.red);
      return false;
    }
  }
}
