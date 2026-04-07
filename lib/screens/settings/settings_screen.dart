import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:local_auth/local_auth.dart';
import '../../config/theme.dart';
import '../../providers/auth_provider.dart';
import '../../services/preference_service.dart';
import '../../services/language_service.dart';
import '../../utils/mobile_responsive.dart';

/// Écran des paramètres — responsive mobile/tablette.
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

    return Scaffold(
      appBar: AppBar(
        title: const Text('Paramètres',
            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 19)),
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
                ? _buildTabletLayout(authProvider, isDark, config)
                : _buildMobileLayout(authProvider, isDark, config),
          );
        },
      ),
    );
  }

  // ── Layout mobile : sections empilées ───────────────────────────────────
  List<Widget> _buildMobileLayout(
      AuthProvider authProvider, bool isDark, ResponsiveConfig config) {
    return [
      _SectionTitle(text: 'Préférences', isDark: isDark, config: config),
      _buildPreferencesCard(authProvider, isDark, config),
      SizedBox(height: config.isSmall ? 18 : 24),
      _SectionTitle(text: 'Sécurité', isDark: isDark, config: config),
      _buildSecurityCard(isDark, config),
      SizedBox(height: config.isSmall ? 18 : 24),
      _SectionTitle(text: 'Aide & Support', isDark: isDark, config: config),
      _buildHelpCard(isDark, config),
      SizedBox(height: config.isSmall ? 18 : 24),
      _buildAppInfo(authProvider, isDark, config),
    ];
  }

  // ── Layout tablette : préférences + sécurité côte à côte ────────────────
  List<Widget> _buildTabletLayout(
      AuthProvider authProvider, bool isDark, ResponsiveConfig config) {
    return [
      Row(
        crossAxisAlignment: CrossAxisAlignment.start, // ✅ AJOUTÉ
        children: [
          Expanded(child: Column(children: [
            _SectionTitle(text: 'Préférences', isDark: isDark, config: config),
            _buildPreferencesCard(authProvider, isDark, config),
          ])),
          const SizedBox(width: 16),
          Expanded(child: Column(children: [
            _SectionTitle(text: 'Sécurité', isDark: isDark, config: config),
            _buildSecurityCard(isDark, config),
          ])),
        ],
      ),
      const SizedBox(height: 24),
      _SectionTitle(text: 'Aide & Support', isDark: isDark, config: config),
      _buildHelpCard(isDark, config),
      const SizedBox(height: 24),
      _buildAppInfo(authProvider, isDark, config),
    ];
  }

  // ── Cartes ───────────────────────────────────────────────────────────────

  Widget _buildPreferencesCard(
      AuthProvider authProvider, bool isDark, ResponsiveConfig config) {
    return _SettingsCard(isDark: isDark, children: [
      SwitchListTile(
        value: _notificationsEnabled,
        onChanged: (v) async {
          setState(() => _notificationsEnabled = v);
          await _prefService.setNotificationsEnabled(v);
          authProvider.updateNotificationPref(v);
        },
        title: _tileTitle('Notifications push', isDark, config),
        subtitle: _tileSub('Recevoir les notifications importantes', isDark, config),
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
              final ok = await _authenticateBiometric();
              if (!ok) return;
            }
            setState(() => _biometricEnabled = v);
            await _prefService.setBiometricEnabled(v);
          },
          title: _tileTitle('Authentification biométrique', isDark, config),
          subtitle: _tileSub('Utiliser l\'empreinte digitale', isDark, config),
          secondary: Icon(Icons.fingerprint_rounded,
              color: isDark ? Colors.green.shade300 : Colors.green,
              size: config.responsive(small: 22, medium: 24, large: 26)),
          activeColor: AppTheme.primaryColor,
        ),
        _divider(isDark),
      ],
      _SettingTile(
        icon: Icons.language_rounded,
        title: 'Langue',
        subtitle: _getLanguageName(_selectedLanguage),
        onTap: _showLanguageDialog,
        isDark: isDark,
        config: config,
      ),
      _divider(isDark),
      _SettingTile(
        icon: Icons.palette_rounded,
        title: 'Thème',
        subtitle: _getThemeName(_selectedTheme),
        onTap: () => _showThemeDialog(authProvider),
        isDark: isDark,
        config: config,
      ),
    ]);
  }

  Widget _buildSecurityCard(bool isDark, ResponsiveConfig config) {
    return _SettingsCard(isDark: isDark, children: [
      _SettingTile(
          icon: Icons.lock_reset_rounded, title: 'Changer le mot de passe',
          subtitle: 'Mettre à jour votre mot de passe',
          onTap: _showChangePasswordDialog, isDark: isDark, config: config),
      _divider(isDark),
      _SettingTile(
          icon: Icons.devices_rounded, title: 'Sessions actives',
          subtitle: 'Gérer les appareils connectés',
          onTap: () =>
              _snack('Sessions — Bientôt disponible !',
                  bg: AppTheme.primaryColor),
          isDark: isDark, config: config),
      _divider(isDark),
      _SettingTile(
          icon: Icons.history_rounded, title: 'Historique de connexion',
          subtitle: 'Voir les connexions récentes',
          onTap: () =>
              _snack('Historique — Bientôt disponible !', bg: AppTheme.primaryColor),
          isDark: isDark, config: config),
    ]);
  }

  Widget _buildHelpCard(bool isDark, ResponsiveConfig config) {
    return _SettingsCard(isDark: isDark, children: [
      _SettingTile(
          icon: Icons.help_center_rounded, title: 'Centre d\'aide',
          subtitle: 'FAQ et guides',
          onTap: () =>
              _snack('Centre d\'aide — Bientôt disponible !', bg: AppTheme.primaryColor),
          isDark: isDark, config: config),
      _divider(isDark),
      _SettingTile(
          icon: Icons.support_agent_rounded, title: 'Nous contacter',
          subtitle: 'Support technique CENOU',
          onTap: _showContactDialog, isDark: isDark, config: config),
      _divider(isDark),
      _SettingTile(
          icon: Icons.report_problem_rounded, title: 'Signaler un problème',
          subtitle: 'Faire remonter un bug',
          onTap: _showReportDialog, isDark: isDark, config: config),
      _divider(isDark),
      _SettingTile(
          icon: Icons.privacy_tip_rounded, title: 'Confidentialité',
          subtitle: 'Politique de confidentialité',
          onTap: () =>
              _snack('Confidentialité — Bientôt disponible !', bg: AppTheme.primaryColor),
          isDark: isDark, config: config),
    ]);
  }

  Widget _buildAppInfo(
      AuthProvider authProvider, bool isDark, ResponsiveConfig config) {
    if (authProvider.sessionId == null) {
      WidgetsBinding.instance
          .addPostFrameCallback((_) => authProvider.generateSessionId());
    }
    final labelSize = config.responsive(small: 11, medium: 12, large: 13);

    return Container(
      padding: EdgeInsets.all(config.responsive(small: 14, medium: 16, large: 18)),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: isDark ? Colors.grey.shade800 : Colors.grey[300]!),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Informations de l\'application',
            style: TextStyle(fontSize: labelSize + 2, fontWeight: FontWeight.w600,
                color: isDark ? Colors.white : Colors.black87)),
        const SizedBox(height: 12),
        _infoRow('Version', '1.0.0', isDark, labelSize),
        const SizedBox(height: 5),
        _infoRow('Dernière mise à jour', '25/03/2026', isDark, labelSize),
        const SizedBox(height: 5),
        _infoRow('Build', '2026.1.8.001', isDark, labelSize),
        const SizedBox(height: 5),
        _infoRow('Session',
            authProvider.sessionId?.substring(0, 8) ?? '---', isDark, labelSize),
        const SizedBox(height: 5),
        _infoRow('Mode', authProvider.isAdmin ? 'Admin' : 'Mobile', isDark, labelSize),
        const SizedBox(height: 5),
        _infoRow('© 2026', 'CENOU - Tous droits réservés', isDark, labelSize),
      ]),
    );
  }

  Widget _infoRow(String label, String value, bool isDark, double size) {
    return Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Text(label,
          style: TextStyle(
              fontSize: size, color: isDark ? Colors.grey.shade400 : Colors.grey[600])),
      Text(value,
          style: TextStyle(
              fontSize: size, fontWeight: FontWeight.w500,
              color: isDark ? Colors.white : Colors.black87)),
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

  // ── Utilitaires ───────────────────────────────────────────────────────────

  String _getLanguageName(String code) =>
      code == 'en' ? 'English' : 'Français';

  String _getThemeName(String t) {
    switch (t) {
      case 'light': return 'Clair';
      case 'dark':  return 'Sombre';
      default:      return 'Système';
    }
  }

  // ── Dialogues ─────────────────────────────────────────────────────────────

  void _showLanguageDialog() {
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
        initialChildSize: 0.5,
        minChildSize: 0.4,
        maxChildSize: 0.8,
        builder: (_, scrollController) => Container(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text('Choisir la langue',
                    style: TextStyle(
                        fontSize: 17, fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white : Colors.black87)),
              ),
              Expanded(
                child: ListView.separated(
                  controller: scrollController,
                  itemCount: langs.length,
                  separatorBuilder: (_, __) => _divider(isDark),
                  itemBuilder: (_, i) {
                    final l = langs[i];
                    return RadioListTile<String>(
                      value: l['code']!,
                      groupValue: _selectedLanguage,
                      activeColor: AppTheme.primaryColor,
                      title: Row(children: [
                        Text(l['flag']!),
                        const SizedBox(width: 12),
                        Text(l['name']!,
                            style: TextStyle(
                                color: isDark ? Colors.white : Colors.black87)),
                      ]),
                      onChanged: (v) async {
                        if (v == null) return;
                        setState(() => _selectedLanguage = v);
                        final locale = Locale(v, v == 'en' ? 'US' : 'FR');
                        await langSvc.setLocale(locale);
                        await _prefService.setPreferredLanguage(v);
                        Provider.of<AuthProvider>(context, listen: false)
                            .updateLanguage(v);
                        Navigator.pop(ctx);
                        if (context.mounted) {
                          showDialog(
                            context: context,
                            barrierDismissible: false,
                            builder: (d) => AlertDialog(
                              backgroundColor:
                              isDark ? const Color(0xFF1E1E1E) : Colors.white,
                              title: Row(children: [
                                Icon(Icons.language_rounded,
                                    color: AppTheme.primaryColor),
                                const SizedBox(width: 12),
                                Text('Langue modifiée',
                                    style: TextStyle(
                                        color:
                                        isDark ? Colors.white : Colors.black87)),
                              ]),
                              content: Text(
                                  'Pour appliquer la nouvelle langue, '
                                      'l\'application va redémarrer.',
                                  style: TextStyle(
                                      color: isDark
                                          ? Colors.grey.shade300
                                          : Colors.grey.shade700)),
                              actions: [
                                ElevatedButton(
                                  onPressed: () {
                                    Navigator.of(d).pop();
                                    Navigator.of(context)
                                        .pushNamedAndRemoveUntil('/', (r) => false);
                                  },
                                  style: ElevatedButton.styleFrom(
                                      backgroundColor: AppTheme.primaryColor),
                                  child: const Text('Redémarrer maintenant',
                                      style: TextStyle(color: Colors.white)),
                                ),
                              ],
                            ),
                          );
                        }
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showThemeDialog(AuthProvider authProvider) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final themes = [
      {'code': 'system', 'name': 'Système', 'icon': Icons.brightness_auto_rounded},
      {'code': 'light',  'name': 'Clair',   'icon': Icons.light_mode_rounded},
      {'code': 'dark',   'name': 'Sombre',  'icon': Icons.dark_mode_rounded},
    ];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.5,
        minChildSize: 0.4,
        maxChildSize: 0.7,
        builder: (_, scrollController) => Container(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text('Choisir le thème',
                    style: TextStyle(
                        fontSize: 17, fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white : Colors.black87)),
              ),
              Expanded(
                child: ListView.separated(
                  controller: scrollController,
                  itemCount: themes.length,
                  separatorBuilder: (_, __) => _divider(isDark),
                  itemBuilder: (_, i) {
                    final t = themes[i];
                    final code = t['code'] as String;
                    final name = t['name'] as String;
                    final icon = t['icon'] as IconData;
                    return RadioListTile<String>(
                      value: code,
                      groupValue: _selectedTheme,
                      activeColor: AppTheme.primaryColor,
                      title: Row(children: [
                        Icon(icon, size: 20,
                            color: isDark ? Colors.grey.shade300 : Colors.grey.shade700),
                        const SizedBox(width: 12),
                        Text(name,
                            style: TextStyle(
                                color: isDark ? Colors.white : Colors.black87)),
                      ]),
                      onChanged: (v) async {
                        if (v == null) return;
                        setState(() => _selectedTheme = v);
                        await _prefService.setPreferredTheme(v);
                        widget.onThemeChanged?.call(v);
                        Navigator.pop(ctx);
                        _snack('Thème changé en $name', bg: AppTheme.primaryColor);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showChangePasswordDialog() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final oldCtrl  = TextEditingController();
    final newCtrl  = TextEditingController();
    final confCtrl = TextEditingController();
    final formKey  = GlobalKey<FormState>();
    bool oldVis = false, newVis = false, confVis = false;

    showDialog(
      context: context,
      builder: (dialogCtx) => LayoutBuilder(
        builder: (context, constraints) {
          final fontSize = constraints.maxWidth < 360 ? 12.0 : 13.0;
          final spacing = constraints.maxWidth < 360 ? 12.0 : 14.0;

          return Dialog(
            backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [
                        Icon(Icons.lock_reset_rounded,
                            color: isDark ? Colors.blue.shade300 : AppTheme.primaryColor),
                        const SizedBox(width: 12),
                        Text('Changer le mot de passe',
                            style: TextStyle(
                                fontSize: fontSize + 4, fontWeight: FontWeight.bold,
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
                                Text('Exigences :',
                                    style: TextStyle(fontSize: fontSize, fontWeight: FontWeight.bold,
                                        color: isDark ? Colors.blue.shade300 : Colors.blue.shade700)),
                              ]),
                              const SizedBox(height: 6),
                              for (final r in ['Au moins 6 caractères', 'Une lettre majuscule', 'Un chiffre'])
                                Padding(
                                  padding: const EdgeInsets.only(left: 6, top: 3),
                                  child: Row(children: [
                                    Icon(Icons.check_circle_outline, size: fontSize,
                                        color: isDark ? Colors.blue.shade300 : Colors.blue.shade700),
                                    const SizedBox(width: 6),
                                    Text(r, style: TextStyle(fontSize: fontSize - 1,
                                        color: isDark ? Colors.blue.shade300 : Colors.blue.shade700)),
                                  ]),
                                ),
                            ]),
                      ),
                      const SizedBox(height: 16),
                      // À l'intérieur de _showChangePasswordDialog, après le bloc des exigences :

                      _pwdField(oldCtrl, 'Ancien mot de passe', oldVis, isDark,
                              () => setState(() => oldVis = !oldVis),
                              (v) => v == null || v.isEmpty ? 'Requis' : null,
                          fontSize),
                      SizedBox(height: spacing),

                      _pwdField(newCtrl, 'Nouveau mot de passe', newVis, isDark,
                              () => setState(() => newVis = !newVis),
                              (v) {
                            if (v == null || v.isEmpty) return 'Requis';
                            if (v.length < 6) return 'Min 6 caractères';
                            if (!RegExp(r'[A-Z]').hasMatch(v)) return 'Une majuscule requise';
                            if (!RegExp(r'[0-9]').hasMatch(v)) return 'Un chiffre requis';
                            return null;
                          },
                          fontSize),
                      SizedBox(height: spacing),

                      _pwdField(confCtrl, 'Confirmation', confVis, isDark,
                              () => setState(() => confVis = !confVis),
                              (v) => v != newCtrl.text ? 'Ne correspond pas' : null,
                          fontSize),
                      const SizedBox(height: 20),
                      Row(mainAxisAlignment: MainAxisAlignment.end, children: [
                        TextButton(
                          onPressed: () {
                            for (final c in [oldCtrl, newCtrl, confCtrl]) c.dispose();
                            Navigator.pop(dialogCtx);
                          },
                          child: Text('Annuler',
                              style: TextStyle(
                                  fontSize: fontSize,
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
                              final auth = Provider.of<AuthProvider>(this.context, listen: false);
                              final ok = await auth.changePassword(
                                ancienMotDePasse: oldCtrl.text,
                                nouveauMotDePasse: newCtrl.text,
                                confirmationNouveauMotDePasse: confCtrl.text,
                              );
                              if (this.context.mounted) Navigator.pop(this.context);
                              _snack(
                                ok ? 'Mot de passe changé avec succès'
                                    : auth.errorMessage ?? 'Erreur',
                                bg: ok ? Colors.green : Colors.red,
                              );
                            } catch (e) {
                              if (this.context.mounted) Navigator.pop(this.context);
                              _snack('Erreur: $e', bg: Colors.red);
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
                          child: const Text('Changer'),
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

  Widget _pwdField(
      TextEditingController ctrl,
      String label,
      bool visible,
      bool isDark,
      VoidCallback onToggle,
      String? Function(String?) validator,
      double fontSize,
      ) {
    return TextFormField(
      controller: ctrl,
      obscureText: !visible,
      style: TextStyle(fontSize: fontSize, color: isDark ? Colors.white : Colors.black87),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(
            fontSize: fontSize, color: isDark ? Colors.grey.shade400 : Colors.grey.shade700),
        prefixIcon: Icon(Icons.lock_outline,
            size: fontSize + 2,
            color: isDark ? Colors.grey.shade400 : Colors.grey.shade600),
        suffixIcon: IconButton(
          icon: Icon(visible ? Icons.visibility : Icons.visibility_off,
              size: fontSize + 2,
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

  void _showContactDialog() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Support CENOU',
            style: TextStyle(color: isDark ? Colors.white : Colors.black87)),
        content: Column(mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Pour toute assistance technique :',
                  style: TextStyle(
                      color: isDark ? Colors.grey.shade300 : Colors.black87)),
              const SizedBox(height: 12),
              _contactRow(Icons.email_rounded, '70382983b@gmail.com', isDark),
              const SizedBox(height: 8),
              _contactRow(Icons.phone_rounded, '+226 70 38 29 83', isDark),
              const SizedBox(height: 8),
              _contactRow(Icons.access_time_rounded, 'Lun-Dim : 8h-18h', isDark),
              const SizedBox(height: 8),
              _contactRow(Icons.location_on_rounded, 'Bobo Dioulasso, Belle Ville', isDark),
            ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx),
              child: Text('Fermer',
                  style: TextStyle(
                      color: isDark ? Colors.grey.shade400 : null))),
          ElevatedButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Envoyer un email')),
        ],
      ),
    );
  }

  Widget _contactRow(IconData icon, String text, bool isDark) {
    return Row(children: [
      Icon(icon, size: 17, color: AppTheme.primaryColor),
      const SizedBox(width: 10),
      Flexible(
          child: Text(text,
              style: TextStyle(
                  color: isDark ? Colors.white : Colors.black87))),
    ]);
  }

  void _showReportDialog() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Signaler un problème',
            style: TextStyle(color: isDark ? Colors.white : Colors.black87)),
        content: Text(
            'Décrivez le problème que vous rencontrez. '
                'Notre équipe technique examinera votre rapport.',
            style: TextStyle(
                color: isDark ? Colors.grey.shade300 : Colors.black87)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx),
              child: Text('Annuler',
                  style: TextStyle(
                      color: isDark ? Colors.grey.shade400 : null))),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.pushNamed(context, '/signalements');
            },
            child: const Text('Signaler'),
          ),
        ],
      ),
    );
  }

  Future<bool> _authenticateBiometric() async {
    try {
      final ok = await _localAuth.authenticate(
          localizedReason: 'Authentifiez-vous pour activer la biométrie');
      if (ok) _snack('Authentification biométrique activée', bg: Colors.green);
      else     _snack('Authentification annulée');
      return ok;
    } on PlatformException catch (e) {
      _snack('Erreur biométrique: ${e.message}', bg: Colors.red);
      return false;
    }
  }
}

// ════════════════════════════════════════════════════════════════
// Widgets internes
// ════════════════════════════════════════════════════════════════

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
    final iconPad   = config.responsive(small: 8, medium: 10, large: 11);

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