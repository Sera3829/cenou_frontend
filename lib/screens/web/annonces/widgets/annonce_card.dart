import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cenou_mobile/config/theme.dart';
import 'package:cenou_mobile/l10n/app_localizations.dart';
import 'package:cenou_mobile/models/admin/annonce.dart';

/// Carte d'une annonce (badge type, date, titre, contenu, portée, suppression).
class AnnonceCard extends StatelessWidget {
  final Annonce annonce;
  final AppLocalizations l10n;
  final VoidCallback onDelete;
  const AnnonceCard(
      {super.key, required this.annonce, required this.l10n, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Card(
      elevation: isDark ? 4 : 2,
      color: AppTheme.getCardBackground(context),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: annonce.typeColor.withOpacity(isDark ? 0.2 : 0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: annonce.typeColor.withOpacity(isDark ? 0.4 : 0.3)),
                  ),
                  child: Text(annonce.typeLabel,
                      style: TextStyle(
                          color: annonce.typeColor,
                          fontWeight: FontWeight.w600,
                          fontSize: 12)),
                ),
                const Spacer(),
                Text(
                  DateFormat('dd/MM/yyyy HH:mm', l10n.locale.languageCode)
                      .format(annonce.createdAt),
                  style: TextStyle(color: AppTheme.getTextTertiary(context), fontSize: 12),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(annonce.titre,
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.getTextPrimary(context))),
            const SizedBox(height: 8),
            Text(annonce.contenu,
                style: TextStyle(
                    color: AppTheme.getTextSecondary(context), fontSize: 14, height: 1.5)),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.group, size: 16, color: AppTheme.getTextTertiary(context)),
                const SizedBox(width: 6),
                Text(annonce.summary,
                    style: TextStyle(color: AppTheme.getTextTertiary(context), fontSize: 13)),
                const SizedBox(width: 8),
                Icon(Icons.person, size: 16, color: AppTheme.getTextTertiary(context)),
                const SizedBox(width: 4),
                Text(l10n.destinatairesCount(annonce.totalDestinataires),
                    style: TextStyle(color: AppTheme.getTextTertiary(context), fontSize: 13)),
                const Spacer(),
                IconButton(
                  onPressed: onDelete,
                  icon: const Icon(Icons.delete_outline, size: 20),
                  color: Colors.red.shade400,
                  tooltip: l10n.delete,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
