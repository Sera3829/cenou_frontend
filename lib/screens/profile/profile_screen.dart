import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../providers/auth_provider.dart';
import '../../models/user.dart';
import '../../utils/mobile_responsive.dart';
import '../../l10n/app_localizations.dart';
import 'widgets/profile_widgets.dart';
import 'dialogs/profile_dialogs.dart';

/// Écran de profil — responsive mobile/tablette.
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.user;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor:
          isDark ? const Color(0xFF121212) : AppTheme.backgroundColor,
      appBar: AppBar(
        title: Text(l10n.myProfile,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 19)),
        centerTitle: true,
        elevation: 1,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            onPressed: () => showEditProfileDialog(context, user, isDark, l10n),
            tooltip: l10n.editProfile,
          ),
        ],
      ),
      body: user == null
          ? ProfileLoadingState(l10n: l10n)
          : LayoutBuilder(
              builder: (context, constraints) {
                final config = ResponsiveConfig.fromConstraints(constraints);
                return CustomScrollView(
                  slivers: [
                    SliverToBoxAdapter(
                        child: ProfileHeader(
                            user: user, config: config, l10n: l10n)),
                    SliverPadding(
                      padding: EdgeInsets.symmetric(
                        horizontal: config.isSmall ? 12 : 16,
                        vertical: 8,
                      ),
                      sliver: SliverList(
                        delegate: SliverChildListDelegate([
                          SizedBox(height: config.isSmall ? 12 : 16),
                          config.isTablet
                              ? _buildTabletInfo(user, isDark, config, l10n)
                              : _buildInfoSection(user, isDark, config, l10n),
                          SizedBox(height: config.isSmall ? 20 : 28),
                          _buildActionsSection(
                              context, authProvider, isDark, config, l10n),
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
  Widget _buildTabletInfo(
      User user, bool isDark, ResponsiveConfig config, AppLocalizations l10n) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: _buildInfoSection(user, isDark, config, l10n)),
        const SizedBox(width: 16),
        Expanded(child: _buildStatsPlaceholder(isDark, config, l10n)),
      ],
    );
  }

  Widget _buildStatsPlaceholder(
      bool isDark, ResponsiveConfig config, AppLocalizations l10n) {
    return Card(
      elevation: isDark ? 4 : 2,
      color: isDark ? const Color(0xFF1E1E1E) : null,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.activity,
                style: TextStyle(
                    fontSize:
                        config.responsive(small: 15, medium: 17, large: 18),
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : Colors.black87)),
            const SizedBox(height: 16),
            StatRow(
                icon: Icons.payment_rounded,
                label: l10n.paymentsMade,
                color: AppTheme.successColor,
                isDark: isDark,
                config: config),
            const SizedBox(height: 12),
            StatRow(
                icon: Icons.report_problem_rounded,
                label: l10n.reportsCreated,
                color: AppTheme.errorColor,
                isDark: isDark,
                config: config),
          ],
        ),
      ),
    );
  }

  // ── Section infos personnelles ───────────────────────────────────────────
  Widget _buildInfoSection(
      User user, bool isDark, ResponsiveConfig config, AppLocalizations l10n) {
    return Card(
      elevation: isDark ? 4 : 2,
      color: isDark ? const Color(0xFF1E1E1E) : null,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(16, config.isSmall ? 14 : 18, 16, 10),
            child: Text(l10n.personalInfo,
                style: TextStyle(
                    fontSize:
                        config.responsive(small: 15, medium: 17, large: 18),
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : Colors.black87)),
          ),
          Divider(
              height: 0,
              thickness: 1,
              color: isDark ? Colors.grey.shade800 : Colors.grey.shade300),
          InfoTile(
              icon: Icons.badge_rounded,
              title: l10n.matricule,
              value: user.matricule,
              color: AppTheme.primaryColor,
              isDark: isDark,
              config: config),
          InfoTile(
              icon: Icons.email_rounded,
              title: l10n.email,
              value: user.email,
              color: Colors.blue,
              isDark: isDark,
              config: config),
          if (user.telephone != null && user.telephone!.isNotEmpty)
            InfoTile(
                icon: Icons.phone_rounded,
                title: l10n.phone,
                value: user.telephone!,
                color: Colors.green,
                isDark: isDark,
                config: config),
          InfoTile(
              icon: _getRoleIcon(user.role),
              title: l10n.role,
              value: _formatRole(user.role, l10n),
              color: AppTheme.secondaryColor,
              isDark: isDark,
              config: config),
        ],
      ),
    );
  }

  // ── Section actions ──────────────────────────────────────────────────────
  Widget _buildActionsSection(BuildContext context, AuthProvider authProvider,
      bool isDark, ResponsiveConfig config, AppLocalizations l10n) {
    return Column(
      children: [
        ActionTile(
          icon: Icons.settings_rounded,
          iconColor: Colors.blue,
          title: l10n.settings,
          subtitle: l10n.settingsSub,
          bgColor: isDark ? Colors.blue.shade700 : Colors.blue.shade50,
          tileBgColor: (isDark ? Colors.blue.shade900 : Colors.blue.shade50)
              .withOpacity(isDark ? 0.2 : 1),
          isDark: isDark,
          config: config,
          onTap: () => Navigator.pushNamed(context, '/settings'),
        ),
        SizedBox(height: config.isSmall ? 8 : 12),
        ActionTile(
          icon: Icons.logout_rounded,
          iconColor: isDark ? Colors.red.shade300 : AppTheme.errorColor,
          title: l10n.logout,
          subtitle: null,
          bgColor: AppTheme.errorColor.withOpacity(isDark ? 0.2 : 0.1),
          tileBgColor: AppTheme.errorColor.withOpacity(isDark ? 0.1 : 0.05),
          isDark: isDark,
          config: config,
          onTap: () => showLogoutDialog(context, authProvider, isDark, l10n),
        ),
      ],
    );
  }

  IconData _getRoleIcon(String role) {
    switch (role.toUpperCase()) {
      case 'ETUDIANT':
        return Icons.school_rounded;
      case 'GESTIONNAIRE':
        return Icons.business_center_rounded;
      case 'ADMIN':
        return Icons.admin_panel_settings_rounded;
      default:
        return Icons.person_rounded;
    }
  }

  String _formatRole(String role, AppLocalizations l10n) {
    switch (role.toUpperCase()) {
      case 'ETUDIANT':
        return l10n.roleStudent;
      case 'GESTIONNAIRE':
        return l10n.roleManager;
      case 'ADMIN':
        return l10n.roleAdmin;
      default:
        return role;
    }
  }
}
