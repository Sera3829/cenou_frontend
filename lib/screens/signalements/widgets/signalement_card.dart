import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../models/signalement.dart';
import '../../../utils/mobile_responsive.dart';
import '../../../l10n/app_localizations.dart';
import '../../../widgets/mobile/meta_chip.dart';

class SignalementCard extends StatelessWidget {
  final Signalement signalement;
  final bool isDark;
  final ResponsiveConfig config;
  final StatusInfo statusInfo;
  final IconData problemIcon;
  final VoidCallback onTap;
  final AppLocalizations l10n;

  const SignalementCard({
    super.key,
    required this.signalement,
    required this.isDark,
    required this.config,
    required this.statusInfo,
    required this.problemIcon,
    required this.onTap,
    required this.l10n,
  });

  @override
  Widget build(BuildContext context) {
    final cardPad = config.responsive(small: 12, medium: 16, large: 18);
    final typeSize = config.responsive(small: 14, medium: 16, large: 17);
    final descSize = config.responsive(small: 12, medium: 13, large: 14);
    final metaSize = config.responsive(small: 10, medium: 11, large: 12);
    final iconSize = config.responsive(small: 18, medium: 21, large: 23);
    final iconPad = config.responsive(small: 7, medium: 9, large: 10);
    final statusFont = config.responsive(small: 10, medium: 11, large: 12);

    // Numéro tronqué
    final num = signalement.numeroSuivi;
    final displayNum = num.length > (config.isSmall ? 10 : 16)
        ? '${num.substring(0, config.isSmall ? 9 : 15)}…'
        : num;

    // Date formatée
    final dateStr = config.isSmall
        ? DateFormat('dd/MM/yy', l10n.locale.languageCode)
            .format(signalement.createdAt)
        : DateFormat('dd MMM yyyy · HH:mm', l10n.locale.languageCode)
            .format(signalement.createdAt);

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
                // ── Ligne 1 : statut + numéro suivi ──
                Row(children: [
                  Container(
                    padding: EdgeInsets.symmetric(
                        horizontal: config.isSmall ? 8 : 10,
                        vertical: config.isSmall ? 4 : 5),
                    decoration: BoxDecoration(
                      color: statusInfo.color.withOpacity(isDark ? 0.2 : 0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      Icon(statusInfo.icon, color: statusInfo.color, size: 12),
                      const SizedBox(width: 4),
                      Text(
                        _statLabel(signalement.statut, l10n),
                        style: TextStyle(
                            color: statusInfo.color,
                            fontSize: statusFont,
                            fontWeight: FontWeight.w600),
                      ),
                    ]),
                  ),
                  const Spacer(),
                  if (displayNum.isNotEmpty)
                    Text(displayNum,
                        style: TextStyle(
                            fontSize: metaSize,
                            color: isDark
                                ? Colors.grey.shade400
                                : Colors.grey[500],
                            fontWeight: FontWeight.w500)),
                ]),

                SizedBox(height: config.isSmall ? 10 : 14),

                // ── Ligne 2 : icône + type problème ──
                Row(children: [
                  Container(
                    padding: EdgeInsets.all(iconPad),
                    decoration: BoxDecoration(
                      color: Theme.of(context)
                          .colorScheme
                          .primary
                          .withOpacity(isDark ? 0.2 : 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(problemIcon,
                        color: Theme.of(context).colorScheme.primary,
                        size: iconSize),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      signalement.typeProbleme.replaceAll('_', ' '),
                      style: TextStyle(
                          fontSize: typeSize, // ← typeSize
                          fontWeight: FontWeight.w600,
                          color: isDark
                              ? Colors.white
                              : Colors.black87), // ← couleur neutre
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Icon(Icons.arrow_forward_ios_rounded,
                      size: 13,
                      color: isDark ? Colors.grey.shade600 : Colors.grey[400]),
                ]),

                SizedBox(height: config.isSmall ? 8 : 10),

                // ── Description tronquée ──
                Text(
                  signalement.description,
                  style: TextStyle(
                      fontSize: descSize,
                      color: isDark ? Colors.grey.shade300 : Colors.grey[700],
                      height: 1.4),
                  maxLines: config.isSmall ? 1 : 2,
                  overflow: TextOverflow.ellipsis,
                ),

                SizedBox(height: config.isSmall ? 8 : 12),

                // ── Méta : date | photos | chambre ──
                Wrap(
                  spacing: config.isSmall ? 8 : 12,
                  runSpacing: 4,
                  children: [
                    MetaChip(
                        icon: Icons.calendar_today_rounded,
                        text: dateStr,
                        isDark: isDark,
                        fontSize: metaSize),
                    if (signalement.photos.isNotEmpty)
                      MetaChip(
                          icon: Icons.photo_library_rounded,
                          text: '${signalement.photos.length}',
                          isDark: isDark,
                          fontSize: metaSize),
                    if ((signalement.numeroChambre ?? '').isNotEmpty)
                      MetaChip(
                          icon: Icons.room_rounded,
                          text: l10n.roomAbbr(signalement.numeroChambre!),
                          isDark: isDark,
                          fontSize: metaSize),
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
        return l10n.pendingProcessing; // "En attente de traitement"
      case 'EN_COURS':
        return l10n.inProgressStatus; // "En cours de traitement"
      case 'RESOLU':
        return l10n.problemResolved; // "Problème résolu"
      case 'ANNULE':
        return l10n.reportCancelled; // "Signalement annulé"
      default:
        return s.replaceAll('_', ' ');
    }
  }
}
