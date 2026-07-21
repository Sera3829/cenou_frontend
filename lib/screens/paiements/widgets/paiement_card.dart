import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../models/paiement.dart';
import '../../../utils/mobile_responsive.dart';
import '../../../l10n/app_localizations.dart';
import '../../../widgets/mobile/meta_chip.dart';

class PaiementCard extends StatelessWidget {
  final Paiement paiement;
  final bool isDark;
  final ResponsiveConfig config;
  final StatusInfo statusInfo;
  final IconData modeIcon;
  final VoidCallback onTap;
  final AppLocalizations l10n;

  const PaiementCard({
    super.key,
    required this.paiement,
    required this.isDark,
    required this.config,
    required this.statusInfo,
    required this.modeIcon,
    required this.onTap,
    required this.l10n,
  });

  @override
  Widget build(BuildContext context) {
    final cardPad = config.responsive(small: 12, medium: 16, large: 18);
    final amountSize = config.responsive(small: 15, medium: 17, large: 19);
    final modeSize = config.responsive(small: 11, medium: 13, large: 14);
    final metaSize = config.responsive(small: 10, medium: 12, large: 12);
    final iconSize = config.responsive(small: 18, medium: 21, large: 23);
    final iconPad = config.responsive(small: 8, medium: 10, large: 11);
    final statusFontSize = config.responsive(small: 10, medium: 12, large: 12);

    // Référence tronquée
    final ref = paiement.referenceTransaction ?? '';
    final displayRef = ref.length > (config.isSmall ? 10 : 16)
        ? '${ref.substring(0, config.isSmall ? 9 : 15)}…'
        : ref;

    // Nom du centre tronqué
    final centre = paiement.nomCentre ?? '';
    final displayCentre = centre.length > (config.isSmall ? 12 : 18)
        ? '${centre.substring(0, config.isSmall ? 11 : 17)}…'
        : centre;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Card(
        elevation: isDark ? 4 : 1,
        color: isDark ? const Color(0xFF1E1E1E) : null,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: EdgeInsets.all(cardPad),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // ── Ligne 1 : statut + référence ──
                Row(
                  children: [
                    // Badge statut
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: config.isSmall ? 8 : 10,
                        vertical: config.isSmall ? 4 : 5,
                      ),
                      decoration: BoxDecoration(
                        color: statusInfo.color.withOpacity(isDark ? 0.2 : 0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(statusInfo.icon,
                              color: statusInfo.color, size: 12),
                          const SizedBox(width: 4),
                          Text(
                            _statLabel(paiement.statut, l10n),
                            style: TextStyle(
                              color: statusInfo.color,
                              fontSize: statusFontSize,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Spacer(),
                    // Référence
                    if (displayRef.isNotEmpty)
                      Text(
                        displayRef,
                        style: TextStyle(
                          fontSize: metaSize,
                          color:
                              isDark ? Colors.grey.shade400 : Colors.grey[500],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                  ],
                ),

                SizedBox(height: config.isSmall ? 10 : 14),

                // ── Ligne 2 : icône mode + montant ──
                Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(iconPad),
                      decoration: BoxDecoration(
                        color: Theme.of(context)
                            .colorScheme
                            .primary
                            .withOpacity(isDark ? 0.2 : 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        modeIcon,
                        color: Theme.of(context).colorScheme.primary,
                        size: iconSize,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '${NumberFormat('#,###').format(paiement.montant)} FCFA',
                            style: TextStyle(
                              fontSize: amountSize,
                              fontWeight: FontWeight.w700,
                              color: isDark ? Colors.white : Colors.black87,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 3),
                          Text(
                            paiement.modePaiement.replaceAll('_', ' '),
                            style: TextStyle(
                              fontSize: modeSize,
                              color: isDark
                                  ? Colors.grey.shade400
                                  : Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Flèche
                    Icon(
                      Icons.arrow_forward_ios_rounded,
                      size: 13,
                      color: isDark ? Colors.grey.shade600 : Colors.grey[400],
                    ),
                  ],
                ),

                SizedBox(height: config.isSmall ? 8 : 12),

                // ── Ligne 3 : méta (date | chambre | centre) ──
                Wrap(
                  spacing: config.isSmall ? 8 : 12,
                  runSpacing: 4,
                  children: [
                    MetaChip(
                      icon: Icons.calendar_today_rounded,
                      text: paiement.datePaiement != null
                          ? (config.isSmall
                              ? DateFormat('dd/MM/yy')
                                  .format(paiement.datePaiement!)
                              : DateFormat('dd MMM yyyy · HH:mm',
                                      l10n.locale.languageCode)
                                  .format(paiement.datePaiement!))
                          : l10n.pendingPayment,
                      isDark: isDark,
                      fontSize: metaSize,
                    ),
                    if ((paiement.numeroChambre ?? '').isNotEmpty)
                      MetaChip(
                        icon: Icons.room_rounded,
                        text: l10n.roomAbbr(paiement.numeroChambre!),
                        isDark: isDark,
                        fontSize: metaSize,
                      ),
                    if (displayCentre.isNotEmpty)
                      MetaChip(
                        icon: Icons.business_rounded,
                        text: displayCentre,
                        isDark: isDark,
                        fontSize: metaSize,
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _statLabel(String s, AppLocalizations l10n) {
    switch (s.toUpperCase()) {
      case 'EN_ATTENTE':
        return l10n.pendingStatus; // "En attente"
      case 'CONFIRME':
        return l10n.confirmedStatus; // "Confirmé"
      case 'ECHEC':
        return l10n.failedStatus; // "Échec"
      default:
        return s.replaceAll('_', ' ');
    }
  }
}
