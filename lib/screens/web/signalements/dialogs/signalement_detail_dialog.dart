import 'package:flutter/material.dart';
import 'package:cenou_mobile/config/theme.dart';
import 'package:cenou_mobile/config/app_config.dart';
import 'package:cenou_mobile/l10n/app_localizations.dart';
import 'package:cenou_mobile/models/signalement.dart';
import 'package:cenou_mobile/screens/web/signalements/utils/signalement_display.dart';

/// Fiche détaillée d'un signalement. [onTakeCharge] : action « prendre en charge »
/// (affichée seulement si le signalement est en attente).
void showSignalementDetailsDialog(
  BuildContext context,
  Signalement s,
  AppLocalizations l10n, {
  required VoidCallback onTakeCharge,
}) {
  final isDark = Theme.of(context).brightness == Brightness.dark;
  showDialog(
    context: context,
    builder: (context) => Dialog(
      backgroundColor: AppTheme.getCardBackground(context),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 40, vertical: 40),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 560,
          maxHeight: MediaQuery.of(context).size.height * 0.85,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: isDark ? Colors.grey.shade900.withOpacity(0.5) : const Color(0xFFF8FAFC),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(Icons.info_outline,
                        color: Theme.of(context).colorScheme.primary, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(l10n.reportDetails,
                            style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.getTextPrimary(context))),
                        const SizedBox(height: 2),
                        Text(s.numeroSuivi,
                            style: TextStyle(
                                fontSize: 12, color: AppTheme.getTextSecondary(context))),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: Icon(Icons.close, color: AppTheme.getTextSecondary(context)),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _section(context, l10n.student, Icons.person),
                    const SizedBox(height: 10),
                    _item(context, l10n.fullName, s.displayEtudiantNomComplet),
                    if (s.matricule != null) _item(context, l10n.matricule, s.matricule!),
                    if (s.telephone != null) _item(context, l10n.phone, s.telephone!),
                    if (s.email != null) _item(context, l10n.email, s.email!),
                    const SizedBox(height: 16),
                    _section(context, l10n.localization, Icons.location_on),
                    const SizedBox(height: 10),
                    _item(context, l10n.center,
                        '${s.nomCentre ?? "N/A"}${s.ville != null ? " (${s.ville})" : ""}'),
                    _item(context, l10n.room,
                        '${s.numeroChambre ?? "N/A"} (${s.typeChambre ?? "Type inconnu"})'),
                    const SizedBox(height: 16),
                    _section(context, l10n.problem, Icons.warning_amber),
                    const SizedBox(height: 10),
                    _item(context, l10n.type, signalementTypeLabel(s.typeProbleme, l10n)),
                    _item(context, l10n.descriptionLabel, s.description),
                    _item(context, l10n.statusLabel, signalementStatutLabel(s.statut, l10n)),
                    _item(context, l10n.creationDate, formatSignalementDate(s.createdAt, l10n)),
                    if (s.dateResolution != null)
                      _item(context, l10n.resolutionDate,
                          formatSignalementDate(s.dateResolution!, l10n)),
                    if (s.commentaireResolution != null)
                      _item(context, l10n.comment, s.commentaireResolution!),
                    if (s.photos.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      _section(context, 'Photos (${s.photos.length})', Icons.photo_library),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: s.photos.map((url) {
                          final full =
                              url.startsWith('http') ? url : '${AppConfig.staticBaseUrl}$url';
                          return ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.network(
                              full,
                              width: 100,
                              height: 100,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Container(
                                width: 100,
                                height: 100,
                                color: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
                                child: Icon(Icons.broken_image,
                                    size: 32, color: AppTheme.getTextTertiary(context)),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const Divider(height: 1),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? Colors.grey.shade900.withOpacity(0.5) : const Color(0xFFF8FAFC),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(16),
                  bottomRight: Radius.circular(16),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(l10n.close,
                        style: TextStyle(color: AppTheme.getTextSecondary(context))),
                  ),
                  if (s.isEnAttente) ...[
                    const SizedBox(width: 12),
                    ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        onTakeCharge();
                      },
                      icon: const Icon(Icons.build, size: 18, color: Colors.white),
                      label: Text(l10n.takeCharge, style: const TextStyle(color: Colors.white)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

Widget _section(BuildContext context, String title, IconData icon) {
  return Row(
    children: [
      Icon(icon, size: 16, color: Theme.of(context).colorScheme.primary),
      const SizedBox(width: 8),
      Text(title,
          style: TextStyle(
              fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.getTextPrimary(context))),
    ],
  );
}

Widget _item(BuildContext context, String label, String value) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: TextStyle(
                fontSize: 12,
                color: AppTheme.getTextSecondary(context),
                fontWeight: FontWeight.w500)),
        const SizedBox(height: 2),
        Text(value, style: TextStyle(fontSize: 14, color: AppTheme.getTextPrimary(context))),
      ],
    ),
  );
}
