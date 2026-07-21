import 'package:flutter/material.dart';
import '../../../config/theme.dart';
import '../../../models/user.dart';
import '../../../utils/mobile_responsive.dart';
import '../../../l10n/app_localizations.dart';

// ──────────────────────────────────────────────────────────────
// Carte logement
// ──────────────────────────────────────────────────────────────

class LogementCard extends StatelessWidget {
  final User? user;
  final bool isDark;
  final ResponsiveConfig config;
  final AppLocalizations l10n;

  const LogementCard({
    super.key,
    required this.user,
    required this.isDark,
    required this.config,
    required this.l10n,
  });

  @override
  Widget build(BuildContext context) {
    final padding = config.responsive(small: 14, medium: 18, large: 22);
    final iconSize = config.responsive(small: 22, medium: 26, large: 30);
    final titleSize = config.responsive(small: 15, medium: 18, large: 20);

    // Tronquer le nom du centre si trop long
    final nomCentre = user?.nomCentre ?? l10n.myHousing;
    final displayNom =
    nomCentre.length > 22 ? '${nomCentre.substring(0, 20)}…' : nomCentre;

    return Card(
      elevation: isDark ? 4 : 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.all(padding),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            colors: isDark
                ? [const Color(0xFF1565C0), const Color(0xFF0D47A1)]
                : [AppTheme.primaryColor, const Color(0xFF1565C0)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // En-tête : icône + nom centre
            Row(
              children: [
                Icon(Icons.home_rounded,
                    color: Colors.white.withOpacity(0.9), size: iconSize),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    displayNom,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: titleSize,
                      fontWeight: FontWeight.w700,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),

            SizedBox(height: config.isShortScreen ? 14 : 20),

            // Séparateur
            Container(
              height: 1,
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [
                  Colors.transparent,
                  Colors.white.withOpacity(0.3),
                  Colors.transparent,
                ]),
              ),
            ),

            SizedBox(height: config.isShortScreen ? 12 : 18),

            // 3 infos : Matricule | Chambre | Statut
            // Sur petit écran, espacement réduit + textes plus courts
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _InfoItem(
                  icon: Icons.badge_rounded,
                  label: l10n.matricule,
                  value: _truncate(user?.matricule ?? '--', config.isSmall ? 8 : 12),
                  config: config,
                ),
                _InfoItem(
                  icon: Icons.meeting_room_rounded,
                  label: config.isSmall ? l10n.chambreShort : l10n.chambre,
                  value: _truncate(
                      user?.numeroChambre ?? 'N/A', config.isSmall ? 6 : 10),
                  config: config,
                ),
                _InfoItem(
                  icon: Icons.verified_user_rounded,
                  label: l10n.status,
                  value: user?.statut == 'ACTIF' ? l10n.active : l10n.inactive,
                  config: config,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _truncate(String s, int max) =>
      s.length > max ? '${s.substring(0, max - 1)}…' : s;
}

class _InfoItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final ResponsiveConfig config;

  const _InfoItem({
    required this.icon,
    required this.label,
    required this.value,
    required this.config,
  });

  @override
  Widget build(BuildContext context) {
    final iconSize = config.responsive(small: 14, medium: 17, large: 20);
    final iconPad = config.responsive(small: 7, medium: 9, large: 11);
    final labelSize = config.responsive(small: 9, medium: 11, large: 12);
    final valueSize = config.responsive(small: 11, medium: 13, large: 14);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: EdgeInsets.all(iconPad),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.15),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: Colors.white.withOpacity(0.9), size: iconSize),
        ),
        SizedBox(height: config.isSmall ? 5 : 8),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withOpacity(0.7),
            fontSize: labelSize,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          value,
          style: TextStyle(
            color: Colors.white,
            fontSize: valueSize,
            fontWeight: FontWeight.w600,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}

