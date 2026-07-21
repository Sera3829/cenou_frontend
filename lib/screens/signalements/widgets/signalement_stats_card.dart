import 'package:flutter/material.dart';
import '../../../config/theme.dart';
import '../../../providers/signalement_provider.dart';
import '../../../utils/mobile_responsive.dart';
import '../../../l10n/app_localizations.dart';

class SignalementStatsCard extends StatelessWidget {
  final SignalementProvider provider;
  final bool isDark;
  final ResponsiveConfig config;
  final AppLocalizations l10n;

  const SignalementStatsCard({
    super.key,
    required this.provider,
    required this.isDark,
    required this.config,
    required this.l10n,
  });

  @override
  Widget build(BuildContext context) {
    final margin = config.isSmall ? 12.0 : 16.0;
    final pad = config.responsive(small: 14, medium: 18, large: 22);
    final titleSize = config.responsive(small: 12, medium: 13, large: 14);

    return Container(
      margin: EdgeInsets.fromLTRB(margin, margin, margin, 6),
      padding: EdgeInsets.all(pad),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppTheme.errorColor, AppTheme.errorColor.withOpacity(0.85)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppTheme.errorColor.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(children: [
            Icon(Icons.bar_chart_rounded,
                color: Colors.white.withOpacity(0.9), size: 18),
            const SizedBox(width: 8),
            Text(l10n.reportOverview,
                style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: titleSize,
                    fontWeight: FontWeight.w500)),
          ]),
          SizedBox(height: config.isShortScreen ? 10 : 14),
          config.isTablet
              ? Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _StatTuile(
                        label: l10n.total,
                        value: provider.totalSignalements.toString(),
                        icon: Icons.report_problem_rounded,
                        iconColor: Colors.white.withOpacity(0.9),
                        config: config),
                    _StatTuile(
                        label: l10n.pending,
                        value: provider.signalementsEnAttente.toString(),
                        icon: Icons.pending_actions_rounded,
                        iconColor: Colors.amber[300]!,
                        config: config),
                    _StatTuile(
                        label: l10n.inProgress,
                        value: provider.signalementsEnCours.toString(),
                        icon: Icons.build_rounded,
                        iconColor: Colors.blue[300]!,
                        config: config),
                    _StatTuile(
                        label: l10n.resolved,
                        value: provider.signalementsResolus.toString(),
                        icon: Icons.check_circle_rounded,
                        iconColor: Colors.green[300]!,
                        config: config),
                  ],
                )
              : GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 4,
                  childAspectRatio: config.isSmall ? 0.85 : 1.0,
                  crossAxisSpacing: config.isSmall ? 6 : 10,
                  mainAxisSpacing: 0,
                  children: [
                    _StatTuile(
                        label: l10n.total,
                        value: provider.totalSignalements.toString(),
                        icon: Icons.report_problem_rounded,
                        iconColor: Colors.white.withOpacity(0.9),
                        config: config),
                    _StatTuile(
                        label: l10n.pending,
                        value: provider.signalementsEnAttente.toString(),
                        icon: Icons.pending_actions_rounded,
                        iconColor: Colors.amber[300]!,
                        config: config),
                    _StatTuile(
                        label: l10n.inProgress,
                        value: provider.signalementsEnCours.toString(),
                        icon: Icons.build_rounded,
                        iconColor: Colors.blue[300]!,
                        config: config),
                    _StatTuile(
                        label: l10n.resolved,
                        value: provider.signalementsResolus.toString(),
                        icon: Icons.check_circle_rounded,
                        iconColor: Colors.green[300]!,
                        config: config),
                  ],
                ),
        ],
      ),
    );
  }
}

class _StatTuile extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color iconColor;
  final ResponsiveConfig config;

  const _StatTuile({
    required this.label,
    required this.value,
    required this.icon,
    required this.iconColor,
    required this.config,
  });

  @override
  Widget build(BuildContext context) {
    final iconPad = config.responsive(small: 5, medium: 7, large: 9);
    final iconSize = config.responsive(small: 15, medium: 18, large: 21);
    final valueSize = config.responsive(small: 13, medium: 16, large: 18);
    final labelSize = config.responsive(small: 8, medium: 10, large: 11);

    return FittedBox(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: EdgeInsets.all(iconPad),
            decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15), shape: BoxShape.circle),
            child: Icon(icon, color: iconColor, size: iconSize),
          ),
          SizedBox(height: config.isSmall ? 4 : 6),
          Text(value,
              style: TextStyle(
                  color: Colors.white,
                  fontSize: valueSize,
                  fontWeight: FontWeight.w700)),
          const SizedBox(height: 2),
          Text(label,
              style: TextStyle(
                  color: Colors.white.withOpacity(0.8),
                  fontSize: labelSize,
                  fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════
// En-tête de liste
// ════════════════════════════════════════════════════════════════

class SignalementListHeader extends StatelessWidget {
  final SignalementProvider provider;
  final bool isDark;
  final ResponsiveConfig config;
  final AppLocalizations l10n;

  const SignalementListHeader({
    super.key,
    required this.provider,
    required this.isDark,
    required this.config,
    required this.l10n,
  });

  @override
  Widget build(BuildContext context) {
    final titleSize = config.responsive(small: 13, medium: 15, large: 16);
    final badgeSize = config.responsive(small: 10, medium: 12, large: 12);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          l10n.historyCount(provider.totalSignalements),
          style: TextStyle(
              fontSize: titleSize,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.grey.shade300 : Colors.grey[700]),
        ),
        Container(
          padding: EdgeInsets.symmetric(
              horizontal: config.isSmall ? 8 : 12,
              vertical: config.isSmall ? 3 : 4),
          decoration: BoxDecoration(
            color: Theme.of(context)
                .colorScheme
                .primary
                .withOpacity(isDark ? 0.2 : 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            l10n.reportCount(provider.totalSignalements),
            style: TextStyle(
                fontSize: badgeSize,
                fontWeight: FontWeight.w500,
                color: Theme.of(context).colorScheme.primary),
          ),
        ),
      ],
    );
  }
}
