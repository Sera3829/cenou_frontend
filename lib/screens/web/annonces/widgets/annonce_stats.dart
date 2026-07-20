import 'package:flutter/material.dart';
import 'package:cenou_mobile/config/theme.dart';
import 'package:cenou_mobile/l10n/app_localizations.dart';
import 'package:cenou_mobile/models/admin/annonce.dart';

/// Bandeau de statistiques des annonces (total, générale, par centre, étudiants).
class AnnonceStats extends StatelessWidget {
  final List<Annonce> annonces;
  final AppLocalizations l10n;
  const AnnonceStats({super.key, required this.annonces, required this.l10n});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final total = annonces.length;
    final generale = annonces.where((a) => a.cible == 'TOUS').length;
    final centre = annonces.where((a) => a.cible == 'CENTRE_SPECIFIQUE').length;
    final etudiants = annonces.where((a) => a.cible == 'ETUDIANTS').length;

    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
      decoration: BoxDecoration(
        color: AppTheme.getCardBackground(context),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(isDark ? 0.1 : 0.05), blurRadius: 10),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _item(context, l10n.total, '$total', Colors.blue, isDark),
          _item(context, l10n.generalAnnouncement, '$generale', Colors.green, isDark),
          _item(context, l10n.byCenter, '$centre', Colors.orange, isDark),
          _item(context, l10n.students, '$etudiants', Colors.purple, isDark),
        ],
      ),
    );
  }

  Widget _item(BuildContext context, String label, String value, Color color, bool isDark) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withOpacity(isDark ? 0.2 : 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(value,
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: color)),
        ),
        const SizedBox(height: 8),
        Text(label, style: TextStyle(fontSize: 12, color: AppTheme.getTextSecondary(context))),
      ],
    );
  }
}
