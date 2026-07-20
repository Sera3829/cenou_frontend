import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cenou_mobile/config/theme.dart';
import 'package:cenou_mobile/l10n/app_localizations.dart';

/// Grille des indicateurs de performance du tableau de bord.
class DashboardStatsGrid extends StatelessWidget {
  final Map<String, dynamic> stats;
  final AppLocalizations l10n;
  const DashboardStatsGrid({super.key, required this.stats, required this.l10n});

  String _fmt(double montant) => NumberFormat('#,##0', l10n.locale.languageCode).format(montant);

  @override
  Widget build(BuildContext context) {
    final general = stats['general'] as Map<String, dynamic>? ?? {};
    final paiements = stats['paiements'] as Map<String, dynamic>? ?? {};
    final signalements = stats['signalements'] as Map<String, dynamic>? ?? {};

    final screenWidth = MediaQuery.of(context).size.width;
    final sidebarWidth = screenWidth > 900 ? 280.0 : 0.0;
    final contentWidth = screenWidth - sidebarWidth;

    int crossAxisCount;
    double childAspectRatio;
    if (contentWidth >= 1000) {
      crossAxisCount = 4;
      childAspectRatio = 1.6;
    } else if (contentWidth >= 700) {
      crossAxisCount = 2;
      childAspectRatio = 1.8;
    } else if (contentWidth >= 400) {
      crossAxisCount = 2;
      childAspectRatio = 1.5;
    } else {
      crossAxisCount = 1;
      childAspectRatio = 2.5;
    }

    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: crossAxisCount,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      childAspectRatio: childAspectRatio,
      children: [
        _card(
          context,
          title: l10n.totalStudents,
          value: '${general['total_etudiants'] ?? '0'}',
          icon: Icons.people_rounded,
          color: const Color(0xFF3B82F6),
          change: l10n.occupancyRate(((int.tryParse(general['logements_occupes'] ?? '0') ?? 0) *
                  100 /
                  (int.tryParse(general['total_logements'] ?? '1') ?? 1))
              .toStringAsFixed(1)),
        ),
        _card(
          context,
          title: l10n.confirmedPayments,
          value: '${paiements['paiements_confirme'] ?? '0'}',
          icon: Icons.payment_rounded,
          color: const Color(0xFF10B981),
          change:
              '${((int.tryParse(paiements['paiements_confirme'] ?? '0') ?? 0) * 100 / (int.tryParse(paiements['total_paiements'] ?? '1') ?? 1)).toStringAsFixed(1)}%',
        ),
        _card(
          context,
          title: l10n.activeReports,
          value: '${signalements['signalements_en_attente'] ?? '0'}',
          icon: Icons.warning_rounded,
          color: const Color(0xFFF59E0B),
          change: l10n.resolvedCount(signalements['signalements_resolus'] ?? '0'),
        ),
        _card(
          context,
          title: l10n.revenue30Days,
          value:
              '${_fmt(double.tryParse(paiements['montant_30jours']?.toString() ?? '0') ?? 0)} F',
          icon: Icons.attach_money_rounded,
          color: const Color(0xFF8B5CF6),
          change: l10n.averageRevenue(
              _fmt(double.tryParse(paiements['montant_moyen']?.toString() ?? '0') ?? 0)),
        ),
      ],
    );
  }

  Widget _card(
    BuildContext context, {
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    required String change,
  }) {
    final isPositive = !change.contains('-') &&
        !change.contains(l10n.resolved) &&
        !change.contains(l10n.occupancy);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: EdgeInsets.all(MediaQuery.of(context).size.width > 900 ? 20 : 12),
      decoration: BoxDecoration(
        color: AppTheme.getCardBackground(context),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(isDark ? 0.1 : 0.05), blurRadius: 10),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withOpacity(isDark ? 0.2 : 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: isPositive
                      ? const Color(0xFF10B981).withOpacity(isDark ? 0.2 : 0.1)
                      : const Color(0xFFEF4444).withOpacity(isDark ? 0.2 : 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(isPositive ? Icons.arrow_upward : Icons.arrow_downward,
                        size: 12,
                        color: isPositive ? const Color(0xFF10B981) : const Color(0xFFEF4444)),
                    const SizedBox(width: 4),
                    Text(change,
                        style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color:
                                isPositive ? const Color(0xFF10B981) : const Color(0xFFEF4444))),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(value,
              style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.getTextPrimary(context))),
          const SizedBox(height: 4),
          Text(title, style: TextStyle(color: AppTheme.getTextSecondary(context), fontSize: 13)),
        ],
      ),
    );
  }
}
