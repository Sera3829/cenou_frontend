import 'package:flutter/material.dart';
import '../../../config/theme.dart';
import '../../../utils/mobile_responsive.dart';
import '../../../l10n/app_localizations.dart';
import '../../paiements/paiements_list_screen.dart';
import '../../signalements/signalements_list_screen.dart';

// ──────────────────────────────────────────────────────────────
// Actions rapides
// ──────────────────────────────────────────────────────────────

class QuickActions extends StatelessWidget {
  final BuildContext context;
  final bool isDark;
  final ResponsiveConfig config;
  final AppLocalizations l10n;

  const QuickActions({
    super.key,
    required this.context,
    required this.isDark,
    required this.config,
    required this.l10n,
  });

  @override
  Widget build(BuildContext _) {
    // Sur tablette : 2 boutons côte à côte
    if (config.isTablet) {
      return Row(
        children: [
          Expanded(
            child: _ActionButton(
              title: l10n.makePayment,
              description: l10n.makePaymentShort,
              icon: Icons.payment_rounded,
              color: Theme.of(context).colorScheme.primary,
              isDark: isDark,
              config: config,
              onTap: () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const PaiementsListScreen())),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _ActionButton(
              title: l10n.reportIssue,
              description: l10n.reportIssueShort,
              icon: Icons.report_problem_rounded,
              color: AppTheme.errorColor,
              isDark: isDark,
              config: config,
              onTap: () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const SignalementsListScreen())),
            ),
          ),
        ],
      );
    }

    // Mobile : empilés verticalement
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _ActionButton(
          title: l10n.makePayment,
          description: config.isSmall
              ? l10n.makePaymentShort
              : l10n.makePaymentDesc,
          icon: Icons.payment_rounded,
          color: Theme.of(context).colorScheme.primary,
          isDark: isDark,
          config: config,
          onTap: () => Navigator.push(context,
              MaterialPageRoute(builder: (_) => const PaiementsListScreen())),
        ),
        SizedBox(height: config.isSmall ? 8 : 12),
        _ActionButton(
          title: l10n.reportIssue,
          description: config.isSmall
              ? l10n.reportIssueShort
              : l10n.reportIssueDesc,
          icon: Icons.report_problem_rounded,
          color: AppTheme.errorColor,
          isDark: isDark,
          config: config,
          onTap: () => Navigator.push(context,
              MaterialPageRoute(builder: (_) => const SignalementsListScreen())),
        ),
      ],
    );
  }
}

class _ActionButton extends StatelessWidget {
  final String title;
  final String description;
  final IconData icon;
  final Color color;
  final bool isDark;
  final ResponsiveConfig config;
  final VoidCallback onTap;

  const _ActionButton({
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
    required this.isDark,
    required this.config,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final iconSize = config.responsive(small: 22, medium: 25, large: 28);
    final iconPad = config.responsive(small: 10, medium: 12, large: 14);
    final titleSize = config.responsive(small: 13, medium: 15, large: 16);
    final descSize = config.responsive(small: 11, medium: 13, large: 13);
    final cardPad = config.responsive(small: 12, medium: 15, large: 16);

    return Card(
      elevation: isDark ? 4 : 2,
      color: isDark ? const Color(0xFF1E1E1E) : null,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: EdgeInsets.all(cardPad),
          child: Row(
            children: [
              Container(
                padding: EdgeInsets.all(iconPad),
                decoration: BoxDecoration(
                  color: color.withOpacity(isDark ? 0.2 : 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: iconSize),
              ),
              SizedBox(width: config.isSmall ? 10 : 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: titleSize,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 3),
                    Text(
                      description,
                      style: TextStyle(
                        fontSize: descSize,
                        color: isDark
                            ? Colors.grey.shade400
                            : Colors.grey[600],
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios_rounded,
                size: 14,
                color: isDark ? Colors.grey.shade600 : Colors.grey[400],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

