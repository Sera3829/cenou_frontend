import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../providers/paiement_provider.dart';
import '../../../utils/mobile_responsive.dart';
import '../../../l10n/app_localizations.dart';

class PaiementStatsCard extends StatelessWidget {
  final PaiementProvider provider;
  final bool isDark;
  final ResponsiveConfig config;
  final VoidCallback onPay;
  final AppLocalizations l10n;

  const PaiementStatsCard({
    super.key,
    required this.provider,
    required this.isDark,
    required this.config,
    required this.onPay,
    required this.l10n,
  });

  @override
  Widget build(BuildContext context) {
    final margin = config.isSmall ? 12.0 : 16.0;
    final pad = config.responsive(small: 14, medium: 18, large: 22);
    final titleSize = config.responsive(small: 12, medium: 13, large: 14);
    final amountSize = config.responsive(small: 13, medium: 15, large: 16);

    return Container(
      margin: EdgeInsets.fromLTRB(margin, margin, margin, 6),
      padding: EdgeInsets.all(pad),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Theme.of(context).colorScheme.primary,
            const Color(0xFF1565C0),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // En-tête
          Row(
            children: [
              Icon(Icons.bar_chart_rounded,
                  color: Colors.white.withOpacity(0.9), size: 18),
              const SizedBox(width: 8),
              Text(
                l10n.financialSummary,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.9),
                  fontSize: titleSize,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          SizedBox(height: config.isShortScreen ? 10 : 14),

          // 3 stats : Total | Confirmés | En cours
          // Sur tablette → Row directe, sur mobile → GridView
          config.isTablet
              ? Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _StatTuile(
                      label: l10n.totalPayments,
                      value: provider.totalPaiements.toString(),
                      icon: Icons.receipt_long_rounded,
                      iconColor: Colors.white.withOpacity(0.9),
                      config: config,
                    ),
                    _StatTuile(
                      label: l10n.confirmedPayments,
                      value: provider.paiementsConfirmes.toString(),
                      icon: Icons.check_circle_rounded,
                      iconColor: Colors.green[300]!,
                      config: config,
                    ),
                    _StatTuile(
                      label: l10n.pendingPayments,
                      value: provider.pendingPaiementsCount.toString(),
                      icon: Icons.pending_actions_rounded,
                      iconColor: Colors.amber[300]!,
                      config: config,
                    ),
                  ],
                )
              : GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 3,
                  childAspectRatio: config.isSmall ? 1.0 : 1.2,
                  crossAxisSpacing: config.isSmall ? 6 : 10,
                  mainAxisSpacing: 0,
                  children: [
                    _StatTuile(
                      label: l10n.totalPayments,
                      value: provider.totalPaiements.toString(),
                      icon: Icons.receipt_long_rounded,
                      iconColor: Colors.white.withOpacity(0.9),
                      config: config,
                    ),
                    _StatTuile(
                      label: l10n.confirmedPayments,
                      value: provider.paiementsConfirmes.toString(),
                      icon: Icons.check_circle_rounded,
                      iconColor: Colors.green[300]!,
                      config: config,
                    ),
                    _StatTuile(
                      label: l10n.pendingPayments,
                      value: provider.pendingPaiementsCount.toString(),
                      icon: Icons.pending_actions_rounded,
                      iconColor: Colors.amber[300]!,
                      config: config,
                    ),
                  ],
                ),

          SizedBox(height: config.isShortScreen ? 10 : 14),

          // Montant total payé
          _LigneMontant(
            icon: Icons.attach_money_rounded,
            iconColor: Colors.white.withOpacity(0.9),
            bgColor: Colors.white.withOpacity(0.1),
            text: l10n.totalPaidAmount(
                NumberFormat('#,###').format(provider.montantTotal)),
            textColor: Colors.white,
            fontSize: amountSize,
            config: config,
          ),
          const SizedBox(height: 8),

          // Montant à régler
          _LigneMontant(
            icon: Icons.warning_amber_rounded,
            iconColor: Colors.orange[300]!,
            bgColor: Colors.orange.withOpacity(0.2),
            text: l10n.amountDue(
                NumberFormat('#,###').format(provider.montantTotalAttendu)),
            textColor: Colors.orange[300]!,
            fontSize: config.responsive(small: 11, medium: 13, large: 14),
            config: config,
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
    final iconPad = config.responsive(small: 6, medium: 8, large: 10);
    final iconSize = config.responsive(small: 16, medium: 19, large: 22);
    final valueSize = config.responsive(small: 14, medium: 17, large: 19);
    final labelSize = config.responsive(small: 9, medium: 10, large: 11);

    return FittedBox(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: EdgeInsets.all(iconPad),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: iconColor, size: iconSize),
          ),
          SizedBox(height: config.isSmall ? 5 : 7),
          Text(
            value,
            style: TextStyle(
              color: Colors.white,
              fontSize: valueSize,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withOpacity(0.8),
              fontSize: labelSize,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _LigneMontant extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final Color bgColor;
  final String text;
  final Color textColor;
  final double fontSize;
  final ResponsiveConfig config;

  const _LigneMontant({
    required this.icon,
    required this.iconColor,
    required this.bgColor,
    required this.text,
    required this.textColor,
    required this.fontSize,
    required this.config,
  });

  @override
  Widget build(BuildContext context) {
    final iconSize = config.responsive(small: 16, medium: 20, large: 22);
    final pad = config.isSmall ? 10.0 : 14.0;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: pad, vertical: 10),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: iconColor, size: iconSize),
          const SizedBox(width: 10),
          Flexible(
            child: Text(
              text,
              style: TextStyle(
                color: textColor,
                fontSize: fontSize,
                fontWeight: FontWeight.w700,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
