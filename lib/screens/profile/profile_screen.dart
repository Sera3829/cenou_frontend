import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../providers/auth_provider.dart';
import '../../models/user.dart';
import '../../providers/paiement_provider.dart';
import '../../providers/signalement_provider.dart';
import '../../utils/mobile_responsive.dart';

/// Écran de profil — responsive mobile/tablette.
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.user;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor:
      isDark ? const Color(0xFF121212) : AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('Mon Profil',
            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 19)),
        centerTitle: true,
        elevation: 1,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            onPressed: () => _showEditProfileDialog(context, user, isDark),
            tooltip: 'Modifier le profil',
          ),
        ],
      ),
      body: user == null
          ? const _ProfileLoadingState()
          : LayoutBuilder(
        builder: (context, constraints) {
          final config = ResponsiveConfig.fromConstraints(constraints);
          return CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                  child: _ProfileHeader(user: user, config: config)),
              SliverPadding(
                padding: EdgeInsets.symmetric(
                  horizontal: config.isSmall ? 12 : 16,
                  vertical: 8,
                ),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    SizedBox(height: config.isSmall ? 12 : 16),
                    config.isTablet
                        ? _buildTabletInfo(user, isDark, config)
                        : _buildInfoSection(user, isDark, config),
                    SizedBox(height: config.isSmall ? 20 : 28),
                    _buildActionsSection(
                        context, authProvider, isDark, config),
                    const SizedBox(height: 32),
                  ]),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  // ── Layout tablette : deux colonnes côte à côte ──────────────────────────
  Widget _buildTabletInfo(User user, bool isDark, ResponsiveConfig config) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start, // ✅ AJOUTÉ
      children: [
        Expanded(child: _buildInfoSection(user, isDark, config)),
        const SizedBox(width: 16),
        // Placeholder colonne droite (stats futures)
        Expanded(child: _buildStatsPlaceholder(isDark, config)),
      ],
    );
  }

  Widget _buildStatsPlaceholder(bool isDark, ResponsiveConfig config) {
    return Card(
      elevation: isDark ? 4 : 2,
      color: isDark ? const Color(0xFF1E1E1E) : null,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Activité',
                style: TextStyle(
                    fontSize: config.responsive(small: 15, medium: 17, large: 18),
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : Colors.black87)),
            const SizedBox(height: 16),
            _StatRow(
                icon: Icons.payment_rounded,
                label: 'Paiements effectués',
                color: AppTheme.successColor,
                isDark: isDark,
                config: config),
            const SizedBox(height: 12),
            _StatRow(
                icon: Icons.report_problem_rounded,
                label: 'Signalements créés',
                color: AppTheme.errorColor,
                isDark: isDark,
                config: config),
          ],
        ),
      ),
    );
  }

  // ── Section infos personnelles ───────────────────────────────────────────
  Widget _buildInfoSection(User user, bool isDark, ResponsiveConfig config) {
    return Card(
      elevation: isDark ? 4 : 2,
      color: isDark ? const Color(0xFF1E1E1E) : null,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(16, config.isSmall ? 14 : 18, 16, 10),
            child: Text('Informations personnelles',
                style: TextStyle(
                    fontSize: config.responsive(small: 15, medium: 17, large: 18),
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : Colors.black87)),
          ),
          Divider(
              height: 0,
              thickness: 1,
              color: isDark ? Colors.grey.shade800 : Colors.grey.shade300),
          _InfoTile(
              icon: Icons.badge_rounded,
              title: 'Matricule',
              value: user.matricule,
              color: AppTheme.primaryColor,
              isDark: isDark,
              config: config),
          _InfoTile(
              icon: Icons.email_rounded,
              title: 'Adresse email',
              value: user.email,
              color: Colors.blue,
              isDark: isDark,
              config: config),
          if (user.telephone != null && user.telephone!.isNotEmpty)
            _InfoTile(
                icon: Icons.phone_rounded,
                title: 'Téléphone',
                value: user.telephone!,
                color: Colors.green,
                isDark: isDark,
                config: config),
          _InfoTile(
              icon: _getRoleIcon(user.role),
              title: 'Rôle',
              value: _formatRole(user.role),
              color: AppTheme.secondaryColor,
              isDark: isDark,
              config: config),
        ],
      ),
    );
  }

  // ── Section actions ──────────────────────────────────────────────────────
  Widget _buildActionsSection(BuildContext context, AuthProvider authProvider,
      bool isDark, ResponsiveConfig config) {
    return Column(
      children: [
        _ActionTile(
          icon: Icons.settings_rounded,
          iconColor: Colors.blue,
          title: 'Paramètres',
          subtitle: 'Personnaliser votre application',
          bgColor: isDark ? Colors.blue.shade700 : Colors.blue.shade50,
          tileBgColor: (isDark
              ? Colors.blue.shade900
              : Colors.blue.shade50)
              .withOpacity(isDark ? 0.2 : 1),
          isDark: isDark,
          config: config,
          onTap: () => Navigator.pushNamed(context, '/settings'),
        ),
        SizedBox(height: config.isSmall ? 8 : 12),
        _ActionTile(
          icon: Icons.logout_rounded,
          iconColor: isDark ? Colors.red.shade300 : AppTheme.errorColor,
          title: 'Déconnexion',
          subtitle: null,
          bgColor: AppTheme.errorColor.withOpacity(isDark ? 0.2 : 0.1),
          tileBgColor: AppTheme.errorColor.withOpacity(isDark ? 0.1 : 0.05),
          isDark: isDark,
          config: config,
          onTap: () => _showLogoutDialog(context, authProvider, isDark),
        ),
      ],
    );
  }

  // ── Dialogues ────────────────────────────────────────────────────────────

  void _showEditProfileDialog(BuildContext context, User? user, bool isDark) {
    if (user == null) return;
    final emailCtrl = TextEditingController(text: user.email);
    final telephoneCtrl = TextEditingController(text: user.telephone ?? '');
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (dialogCtx) => Dialog(
        backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // En-tête
                Row(children: [
                  Icon(Icons.edit_rounded,
                      color: isDark ? Colors.blue.shade300 : AppTheme.primaryColor),
                  const SizedBox(width: 12),
                  Text('Modifier le profil',
                      style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : Colors.black87)),
                ]),
                const SizedBox(height: 20),
                // Info non modifiable
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50.withOpacity(isDark ? 0.1 : 0.5),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                        color: isDark ? Colors.blue.shade700 : Colors.blue.shade200),
                  ),
                  child: Row(children: [
                    Icon(Icons.info_outline, size: 18,
                        color: isDark ? Colors.blue.shade300 : Colors.blue.shade700),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Le nom et le matricule ne peuvent pas être modifiés',
                        style: TextStyle(
                            fontSize: 12,
                            color: isDark
                                ? Colors.blue.shade300
                                : Colors.blue.shade700),
                      ),
                    ),
                  ]),
                ),
                const SizedBox(height: 16),
                // Formulaire
                Form(
                  key: formKey,
                  child: Column(children: [
                    _buildDialogField(emailCtrl, 'Email', Icons.email_outlined,
                        isDark, TextInputType.emailAddress, (v) {
                          if (v == null || v.isEmpty) return 'L\'email est requis';
                          if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
                              .hasMatch(v)) return 'Email invalide';
                          return null;
                        }),
                    const SizedBox(height: 14),
                    _buildDialogField(telephoneCtrl, 'Téléphone (optionnel)',
                        Icons.phone_outlined, isDark, TextInputType.phone, (v) {
                          if (v != null && v.isNotEmpty && v.length < 8) {
                            return 'Au moins 8 chiffres';
                          }
                          return null;
                        }),
                  ]),
                ),
                const SizedBox(height: 20),
                // Boutons
                Row(mainAxisAlignment: MainAxisAlignment.end, children: [
                  TextButton(
                    onPressed: () {
                      emailCtrl.dispose();
                      telephoneCtrl.dispose();
                      Navigator.pop(dialogCtx);
                    },
                    child: Text('Annuler',
                        style: TextStyle(
                            color: isDark
                                ? Colors.grey.shade400
                                : Colors.grey.shade700)),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: () async {
                      if (!formKey.currentState!.validate()) return;
                      Navigator.pop(dialogCtx);
                      await _runWithLoader(context, isDark, () async {
                        final auth =
                        Provider.of<AuthProvider>(context, listen: false);
                        final ok = await auth.updateProfile(
                          email: emailCtrl.text.trim(),
                          telephone: telephoneCtrl.text.trim().isEmpty
                              ? null
                              : telephoneCtrl.text.trim(),
                        );
                        emailCtrl.dispose();
                        telephoneCtrl.dispose();
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                            content: Text(ok
                                ? 'Profil mis à jour avec succès'
                                : auth.errorMessage ?? 'Erreur'),
                            backgroundColor: ok ? Colors.green : Colors.red,
                            behavior: SnackBarBehavior.floating,
                          ));
                        }
                      });
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                      isDark ? Colors.blue.shade700 : AppTheme.primaryColor,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Enregistrer'),
                  ),
                ]),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDialogField(
      TextEditingController ctrl,
      String label,
      IconData icon,
      bool isDark,
      TextInputType keyboardType,
      String? Function(String?) validator) {
    return TextFormField(
      controller: ctrl,
      keyboardType: keyboardType,
      style: TextStyle(color: isDark ? Colors.white : Colors.black87),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(
            color: isDark ? Colors.grey.shade400 : Colors.grey.shade700),
        prefixIcon: Icon(icon,
            color: isDark ? Colors.grey.shade400 : Colors.grey.shade600),
        filled: true,
        fillColor: isDark ? const Color(0xFF2D2D2D) : Colors.grey.shade50,
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
                color: isDark ? Colors.grey.shade700 : Colors.grey.shade300)),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
                color: isDark ? Colors.grey.shade700 : Colors.grey.shade300)),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
                color: isDark ? Colors.blue.shade300 : AppTheme.primaryColor,
                width: 2)),
      ),
      validator: validator,
    );
  }

  Future<void> _runWithLoader(
      BuildContext context, bool isDark, Future<void> Function() task) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => PopScope(
        canPop: false,
        child: Center(
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                borderRadius: BorderRadius.circular(16)),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              CircularProgressIndicator(color: AppTheme.primaryColor),
              const SizedBox(height: 16),
              Text('Mise à jour en cours…',
                  style: TextStyle(
                      color: isDark ? Colors.white : Colors.black87)),
            ]),
          ),
        ),
      ),
    );
    try {
      await task();
    } finally {
      if (context.mounted) Navigator.pop(context);
    }
  }

  // ── Dialogue déconnexion (déplacé dans la classe) ───────────────────────
  Future<void> _showLogoutDialog(
      BuildContext context,
      AuthProvider authProvider,
      bool isDark,
      ) async {
    final result = await showDialog<bool>(
      context: context,
      useRootNavigator: true,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(children: [
          Icon(Icons.logout_rounded,
              color: isDark ? Colors.red.shade300 : Colors.red),
          const SizedBox(width: 12),
          Text('Déconnexion',
              style: TextStyle(color: isDark ? Colors.white : Colors.black87)),
        ]),
        content: Text(
          'Voulez-vous vraiment vous déconnecter ?',
          style: TextStyle(
              color: isDark ? Colors.grey.shade300 : Colors.grey.shade700),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Annuler')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
                backgroundColor: isDark ? Colors.red.shade700 : AppTheme.errorColor),
            child: const Text('Se déconnecter',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (result != true || !context.mounted) return;

    // Montrer loader AVEC rootNavigator
    showDialog(
      context: context,
      barrierDismissible: false,
      useRootNavigator: true,
      builder: (_) => PopScope(
        canPop: false,
        child: Center(
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                borderRadius: BorderRadius.circular(16)),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              CircularProgressIndicator(color: AppTheme.primaryColor),
              const SizedBox(height: 16),
              Text('Déconnexion en cours…',
                  style: TextStyle(
                      color: isDark ? Colors.white : Colors.black87)),
            ]),
          ),
        ),
      ),
    );

    if (result != true || !context.mounted) return;

// ← PAS de dialog loader (PopScope bloquait pushNamedAndRemoveUntil)
    try {
      await authProvider.logout();
    } catch (_) {}

    if (!context.mounted) return;

    Navigator.of(context, rootNavigator: true)
        .pushNamedAndRemoveUntil('/login', (route) => false);
  }
}

// ════════════════════════════════════════════════════════════════
// Widgets internes (inchangés, sauf si besoin)
// ════════════════════════════════════════════════════════════════

class _ProfileHeader extends StatelessWidget {
  final User user;
  final ResponsiveConfig config;
  const _ProfileHeader({required this.user, required this.config});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final avatarRadius = config.responsive(small: 40, medium: 48, large: 56);
    final nameSize = config.responsive(small: 20, medium: 23, large: 26);
    final matSize = config.responsive(small: 13, medium: 14, large: 15);
    final vPad = config.responsive(small: 28, medium: 36, large: 44);

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: isDark
              ? [AppTheme.primaryColor.withOpacity(0.7),
            AppTheme.primaryColor.withOpacity(0.5)]
              : [AppTheme.primaryColor.withOpacity(0.9),
            AppTheme.primaryColor.withOpacity(0.7)],
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
      ),
      padding: EdgeInsets.fromLTRB(24, vPad, 24, vPad - 4),
      child: Column(children: [
        Stack(alignment: Alignment.bottomRight, children: [
          Container(
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white.withOpacity(0.3), width: 3),
            ),
            child: CircleAvatar(
              radius: avatarRadius,
              backgroundColor: Colors.white,
              child: Text(user.initiales,
                  style: TextStyle(
                      fontSize: avatarRadius * 0.7,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.primaryColor)),
            ),
          ),
          Container(
            padding: const EdgeInsets.all(5),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              border: Border.all(color: AppTheme.primaryColor, width: 2),
            ),
            child: Icon(_getStatusIcon(user.statut),
                size: 14, color: _getStatusColor(user.statut)),
          ),
        ]),
        SizedBox(height: config.isSmall ? 14 : 18),
        Text(user.nomComplet,
            style: TextStyle(fontSize: nameSize, fontWeight: FontWeight.w700,
                color: Colors.white),
            textAlign: TextAlign.center,
            maxLines: 2, overflow: TextOverflow.ellipsis),
        const SizedBox(height: 4),
        Text(user.matricule,
            style: TextStyle(
                fontSize: matSize, color: Colors.white.withOpacity(0.9))),
        Container(
          margin: EdgeInsets.only(top: config.isSmall ? 8 : 12),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(_formatStatus(user.statut),
              style: TextStyle(
                  fontSize: config.responsive(small: 11, medium: 12, large: 13),
                  fontWeight: FontWeight.w600,
                  color: Colors.white)),
        ),
      ]),
    );
  }

  IconData _getStatusIcon(String s) {
    switch (s.toUpperCase()) {
      case 'ACTIF':    return Icons.check_circle_rounded;
      case 'INACTIF':  return Icons.pause_circle_rounded;
      case 'SUSPENDU': return Icons.block_rounded;
      default:         return Icons.person_rounded;
    }
  }

  Color _getStatusColor(String s) {
    switch (s.toUpperCase()) {
      case 'ACTIF':    return Colors.green;
      case 'INACTIF':  return Colors.orange;
      case 'SUSPENDU': return Colors.red;
      default:         return Colors.grey;
    }
  }

  String _formatStatus(String s) {
    switch (s.toUpperCase()) {
      case 'ACTIF':    return 'Compte actif';
      case 'INACTIF':  return 'Compte inactif';
      case 'SUSPENDU': return 'Compte suspendu';
      default:         return s;
    }
  }
}

class _InfoTile extends StatelessWidget {
  final IconData icon;
  final String title, value;
  final Color color;
  final bool isDark;
  final ResponsiveConfig config;
  const _InfoTile(
      {required this.icon, required this.title, required this.value,
        required this.color, required this.isDark, required this.config});

  @override
  Widget build(BuildContext context) {
    final iconSize  = config.responsive(small: 18, medium: 20, large: 22);
    final iconPad   = config.responsive(small: 8,  medium: 10, large: 11);
    final labelSize = config.responsive(small: 11, medium: 12, large: 13);
    final valueSize = config.responsive(small: 14, medium: 15, large: 16);

    return Padding(
      padding: EdgeInsets.symmetric(
          vertical: config.isSmall ? 10 : 12, horizontal: 16),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          padding: EdgeInsets.all(iconPad),
          decoration: BoxDecoration(
            color: color.withOpacity(isDark ? 0.2 : 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, size: iconSize,
              color: isDark ? color.withOpacity(0.7) : color),
        ),
        const SizedBox(width: 14),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: TextStyle(fontSize: labelSize,
                      color: isDark ? Colors.grey.shade400 : Colors.grey[600],
                      fontWeight: FontWeight.w500)),
              const SizedBox(height: 3),
              Text(value,
                  style: TextStyle(fontSize: valueSize, fontWeight: FontWeight.w500,
                      color: isDark ? Colors.white : Colors.black87),
                  maxLines: 2, overflow: TextOverflow.ellipsis),
            ])),
      ]),
    );
  }
}

class _ActionTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor, bgColor, tileBgColor;
  final String title;
  final String? subtitle;
  final bool isDark;
  final ResponsiveConfig config;
  final VoidCallback onTap;
  const _ActionTile(
      {required this.icon, required this.iconColor, required this.title,
        required this.subtitle, required this.bgColor, required this.tileBgColor,
        required this.isDark, required this.config, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final titleSize = config.responsive(small: 13, medium: 14, large: 15);
    final subSize   = config.responsive(small: 10, medium: 11, large: 12);
    final iconPad   = config.responsive(small: 8, medium: 10, large: 11);

    return ListTile(
      onTap: onTap,
      contentPadding:
      EdgeInsets.symmetric(horizontal: 16, vertical: config.isSmall ? 2 : 4),
      leading: Container(
        padding: EdgeInsets.all(iconPad),
        decoration:
        BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(12)),
        child: Icon(icon, color: iconColor,
            size: config.responsive(small: 18, medium: 21, large: 23)),
      ),
      title: Text(title,
          style: TextStyle(
              fontWeight: FontWeight.w500, fontSize: titleSize,
              color: isDark ? Colors.white : Colors.black87)),
      subtitle: subtitle != null
          ? Text(subtitle!,
          style: TextStyle(
              fontSize: subSize,
              color: isDark ? Colors.grey.shade400 : Colors.grey.shade600))
          : null,
      trailing: Icon(Icons.chevron_right_rounded,
          color: isDark ? Colors.grey.shade600 : Colors.grey),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      tileColor: tileBgColor,
    );
  }
}

class _StatRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final bool isDark;
  final ResponsiveConfig config;
  const _StatRow(
      {required this.icon, required this.label, required this.color,
        required this.isDark, required this.config});

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Icon(icon, color: color, size: config.responsive(small: 18, medium: 20, large: 22)),
      const SizedBox(width: 10),
      Expanded(
        child: Text(label,
            style: TextStyle(
                fontSize: config.responsive(small: 12, medium: 13, large: 14),
                color: isDark ? Colors.grey.shade300 : Colors.black87)),
      ),
    ]);
  }
}

class _ProfileLoadingState extends StatelessWidget {
  const _ProfileLoadingState();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryColor)),
          const SizedBox(height: 20),
          Text('Chargement du profil…',
              style: TextStyle(fontSize: 15,
                  color: isDark ? Colors.grey.shade400 : Colors.grey[600])),
        ]));
  }
}

// ── Helpers libres ────────────────────────────────────────────────────────────

IconData _getRoleIcon(String role) {
  switch (role.toUpperCase()) {
    case 'ETUDIANT':     return Icons.school_rounded;
    case 'GESTIONNAIRE': return Icons.business_center_rounded;
    case 'ADMIN':        return Icons.admin_panel_settings_rounded;
    default:             return Icons.person_rounded;
  }
}

String _formatRole(String role) {
  switch (role.toUpperCase()) {
    case 'ETUDIANT':     return 'Étudiant';
    case 'GESTIONNAIRE': return 'Gestionnaire';
    case 'ADMIN':        return 'Administrateur';
    default:             return role;
  }
}