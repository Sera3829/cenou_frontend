import 'package:flutter/material.dart';
import 'package:cenou_mobile/config/theme.dart';
import 'package:cenou_mobile/l10n/app_localizations.dart';
import 'package:cenou_mobile/providers/web/user_admin_provider.dart';

/// Bandeau de statistiques rapides (total, actifs, étudiants, gestionnaires, admins).
class UserStats extends StatelessWidget {
  final UserAdminProvider provider;
  final AppLocalizations l10n;
  const UserStats({super.key, required this.provider, required this.l10n});

  Map<String, int> _calculateStats() {
    return {
      'total': provider.users.length,
      'actifs': provider.users.where((u) => u.isActive).length,
      'etudiants': provider.users.where((u) => u.isStudent).length,
      'gestionnaires': provider.users.where((u) => u.isGestionnaire).length,
      'admins': provider.users.where((u) => u.isAdmin).length,
    };
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final screenWidth = MediaQuery.of(context).size.width;
    final sidebarWidth = screenWidth > 900 ? 280.0 : 0.0;
    final isWide = (screenWidth - sidebarWidth) > 700;
    final stats = _calculateStats();

    return Container(
      padding: const EdgeInsets.all(24),
      color: isDark ? Colors.grey.shade900.withOpacity(0.5) : const Color(0xFFF1F5F9),
      child: isWide
          ? Row(
              children: [
                _statCard(context, label: l10n.total, value: '${stats['total']}', color: const Color(0xFF3B82F6), icon: Icons.people, isDark: isDark),
                const SizedBox(width: 16),
                _statCard(context, label: l10n.active, value: '${stats['actifs']}', color: const Color(0xFF10B981), icon: Icons.check_circle, isDark: isDark),
                const SizedBox(width: 16),
                _statCard(context, label: l10n.students, value: '${stats['etudiants']}', color: const Color(0xFF8B5CF6), icon: Icons.school, isDark: isDark),
                const SizedBox(width: 16),
                _statCard(context, label: l10n.managers, value: '${stats['gestionnaires']}', color: const Color(0xFFF59E0B), icon: Icons.manage_accounts, isDark: isDark),
                const SizedBox(width: 16),
                _statCard(context, label: l10n.admins, value: '${stats['admins']}', color: const Color(0xFFEC4899), icon: Icons.admin_panel_settings, isDark: isDark),
              ],
            )
          : Column(
              children: [
                Row(
                  children: [
                    _statCard(context, label: l10n.total, value: '${stats['total']}', color: const Color(0xFF3B82F6), icon: Icons.people, isDark: isDark),
                    const SizedBox(width: 12),
                    _statCard(context, label: l10n.active, value: '${stats['actifs']}', color: const Color(0xFF10B981), icon: Icons.check_circle, isDark: isDark),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    _statCard(context, label: l10n.students, value: '${stats['etudiants']}', color: const Color(0xFF8B5CF6), icon: Icons.school, isDark: isDark),
                    const SizedBox(width: 12),
                    _statCard(context, label: l10n.managers, value: '${stats['gestionnaires']}', color: const Color(0xFFF59E0B), icon: Icons.manage_accounts, isDark: isDark),
                  ],
                ),
                const SizedBox(height: 12),
                _statCard(context, label: l10n.admins, value: '${stats['admins']}', color: const Color(0xFFEC4899), icon: Icons.admin_panel_settings, isDark: isDark),
              ],
            ),
    );
  }

  Widget _statCard(
    BuildContext context, {
    required String label,
    required String value,
    required Color color,
    required IconData icon,
    required bool isDark,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppTheme.getCardBackground(context),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(isDark ? 0.1 : 0.05), blurRadius: 10),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(isDark ? 0.2 : 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(value,
                      style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: color)),
                  const SizedBox(height: 4),
                  Text(label,
                      style: TextStyle(fontSize: 13, color: AppTheme.getTextSecondary(context))),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
