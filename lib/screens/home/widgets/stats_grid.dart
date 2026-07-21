import 'package:flutter/material.dart';
import '../../../config/theme.dart';
import '../../../providers/paiement_provider.dart';
import '../../../providers/signalement_provider.dart';
import '../../../utils/mobile_responsive.dart';
import '../../../l10n/app_localizations.dart';

// ──────────────────────────────────────────────────────────────
// Grille des statistiques
// ──────────────────────────────────────────────────────────────

class StatsGrid extends StatelessWidget {
  final PaiementProvider paiementProvider;
  final SignalementProvider signalementProvider;
  final bool isDark;
  final ResponsiveConfig config;
  final AppLocalizations l10n;

  const StatsGrid({
    super.key,
    required this.paiementProvider,
    required this.signalementProvider,
    required this.isDark,
    required this.config,
    required this.l10n,
  });

  @override
  Widget build(BuildContext context) {
    // Toujours 2 colonnes sur toutes les tailles (mobile/tablette)
    const crossAxis = 2;

    // Ratio : plus haut sur mobile (0.9), plus large sur tablette (1.2, 1.4)
    final ratio = config.responsive(
      small: 0.9,
      medium: 1.2,
      large: 1.4,
    );

    final items = [
      _StatItem(
        title: l10n.confirmed,
        value: paiementProvider.paiementsConfirmes.toString(),
        icon: Icons.check_circle_rounded,
        color: AppTheme.successColor,
        subtitle: l10n.payments,
      ),
      _StatItem(
        title: l10n.pending,
        value: paiementProvider.pendingPaiementsCount.toString(),
        icon: Icons.schedule_rounded,
        color: AppTheme.warningColor,
        subtitle: l10n.payments,
      ),
      _StatItem(
        title: l10n.total,
        value: signalementProvider.totalSignalements.toString(),
        icon: Icons.report_rounded,
        color: AppTheme.errorColor,
        subtitle: l10n.reports,
      ),
      _StatItem(
        title: l10n.pending,
        value: signalementProvider.signalementsEnAttente.toString(),
        icon: Icons.pending_actions_rounded,
        color: AppTheme.infoColor,
        subtitle: l10n.reports,
      ),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxis,
        mainAxisSpacing: config.isSmall ? 8 : 12,
        crossAxisSpacing: config.isSmall ? 8 : 12,
        childAspectRatio: ratio,
      ),
      itemCount: items.length,
      itemBuilder: (_, i) => _StatCard(item: items[i], isDark: isDark, config: config),
    );
  }
}

class _StatItem {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final String subtitle;

  const _StatItem({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    required this.subtitle,
  });
}

class _StatCard extends StatelessWidget {
  final _StatItem item;
  final bool isDark;
  final ResponsiveConfig config;

  const _StatCard({
    required this.item,
    required this.isDark,
    required this.config,
  });

  @override
  Widget build(BuildContext context) {
    final valueSize = config.responsive(small: 22, medium: 26, large: 28);
    final titleSize = config.responsive(small: 11, medium: 13, large: 14);
    final subtitleSize = config.responsive(small: 10, medium: 11, large: 12);
    final iconSize = config.responsive(small: 18, medium: 22, large: 24);

    return Card(
      elevation: isDark ? 4 : 2,
      color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Ligne du haut (label + icône)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  item.subtitle,
                  style: TextStyle(
                    fontSize: subtitleSize,
                    color: isDark ? Colors.grey.shade400 : Colors.grey[600],
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Icon(item.icon, color: item.color, size: iconSize),
              ],
            ),
            // Valeur principale
            Text(
              item.value,
              style: TextStyle(
                fontSize: valueSize,
                fontWeight: FontWeight.bold,
                color: item.color,
              ),
            ),
            // Titre
            Text(
              item.title,
              style: TextStyle(
                fontSize: titleSize,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white : Colors.grey[800],
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

