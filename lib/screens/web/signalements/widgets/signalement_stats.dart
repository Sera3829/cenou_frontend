import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cenou_mobile/config/theme.dart';
import 'package:cenou_mobile/l10n/app_localizations.dart';
import 'package:cenou_mobile/providers/web/signalement_admin_provider.dart';

/// Bandeau de statistiques des signalements (total, en attente, en cours, taux).
class SignalementStats extends StatelessWidget {
  final AppLocalizations l10n;
  const SignalementStats({super.key, required this.l10n});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Consumer<SignalementAdminProvider>(
      builder: (context, provider, child) {
        final stats = provider.statistiques ?? {};
        final screenWidth = MediaQuery.of(context).size.width;
        final sidebarWidth = screenWidth > 900 ? 280.0 : 0.0;
        final isWide = (screenWidth - sidebarWidth) > 700;

        return Container(
          padding: const EdgeInsets.all(24),
          color: isDark ? Colors.grey.shade900.withOpacity(0.5) : const Color(0xFFF1F5F9),
          child: isWide
              ? Row(
                  children: [
                    Expanded(child: _card(context, l10n.totalReports, '${stats['total'] ?? 0}', const Color(0xFF3B82F6), Icons.warning, isDark)),
                    const SizedBox(width: 16),
                    Expanded(child: _card(context, l10n.pending, '${stats['en_attente'] ?? 0}', const Color(0xFFF59E0B), Icons.hourglass_empty, isDark)),
                    const SizedBox(width: 16),
                    Expanded(child: _card(context, l10n.inProgress, '${stats['en_cours'] ?? 0}', const Color(0xFF3B82F6), Icons.build, isDark)),
                    const SizedBox(width: 16),
                    Expanded(child: _card(context, l10n.resolutionRate, '${(stats['taux_resolution'] ?? 0).toStringAsFixed(1)}%', const Color(0xFF10B981), Icons.check_circle, isDark)),
                  ],
                )
              : Column(
                  children: [
                    Row(
                      children: [
                        Expanded(child: _card(context, l10n.total, '${stats['total'] ?? 0}', const Color(0xFF3B82F6), Icons.warning, isDark)),
                        const SizedBox(width: 12),
                        Expanded(child: _card(context, l10n.pending, '${stats['en_attente'] ?? 0}', const Color(0xFFF59E0B), Icons.hourglass_empty, isDark)),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(child: _card(context, l10n.inProgress, '${stats['en_cours'] ?? 0}', const Color(0xFF3B82F6), Icons.build, isDark)),
                        const SizedBox(width: 12),
                        Expanded(child: _card(context, l10n.rate, '${(stats['taux_resolution'] ?? 0).toStringAsFixed(1)}%', const Color(0xFF10B981), Icons.check_circle, isDark)),
                      ],
                    ),
                  ],
                ),
        );
      },
    );
  }

  Widget _card(BuildContext context, String label, String value, Color color, IconData icon, bool isDark) {
    return Container(
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
    );
  }
}
