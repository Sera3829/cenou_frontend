import 'package:flutter/material.dart';
import 'package:cenou_mobile/config/theme.dart';
import 'package:cenou_mobile/l10n/app_localizations.dart';
import 'package:cenou_mobile/models/admin/admin_user.dart';
import 'package:cenou_mobile/screens/web/utilisateurs/utils/user_display.dart';

/// Fiche détaillée d'un utilisateur (lecture seule + bouton « Modifier »).
/// [onEdit] : ouvre l'édition avec un contexte valide (le contexte du dialogue
/// est invalide après sa fermeture).
void showUserDetailsDialog(
    BuildContext context, AdminUser user, AppLocalizations l10n,
    {required VoidCallback onEdit}) {
  final isDark = Theme.of(context).brightness == Brightness.dark;
  showDialog(
    context: context,
    builder: (context) => Dialog(
      backgroundColor: AppTheme.getCardBackground(context),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 600,
          maxHeight: MediaQuery.of(context).size.height * 0.85,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(24),
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
                    child: Icon(Icons.person,
                        color: Theme.of(context).colorScheme.primary, size: 24),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(l10n.userDetails,
                            style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.getTextPrimary(context))),
                        const SizedBox(height: 4),
                        Text(user.matricule,
                            style: TextStyle(
                                fontSize: 13, color: AppTheme.getTextSecondary(context))),
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
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _sectionHeader(context, l10n.personalInformation, Icons.person),
                    const SizedBox(height: 12),
                    _infoGrid(context, [
                      (l10n.fullName, '${user.prenom} ${user.nom}'),
                      (l10n.matricule, user.matricule),
                      (l10n.email, user.email),
                      (l10n.phone, user.telephone),
                    ]),
                    const SizedBox(height: 24),
                    _sectionHeader(context, l10n.account, Icons.admin_panel_settings),
                    const SizedBox(height: 12),
                    _infoGrid(context, [
                      (l10n.role, userRoleLabel(user.role, l10n)),
                      (l10n.status, userStatutLabel(user.statut, l10n)),
                      (l10n.dateCreation, formatUserDate(user.createdAt, l10n)),
                      if (user.updatedAt != null)
                        (l10n.lastModification, formatUserDate(user.updatedAt!, l10n)),
                    ]),
                    if (user.centreNom != null || user.numeroChambre != null) ...[
                      const SizedBox(height: 24),
                      _sectionHeader(context, l10n.housing, Icons.home),
                      const SizedBox(height: 12),
                      _infoGrid(context, [
                        if (user.centreNom != null) (l10n.center, user.centreNom!),
                        if (user.numeroChambre != null) (l10n.roomNumber, user.numeroChambre!),
                      ]),
                    ],
                  ],
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: isDark ? Colors.grey.shade900.withOpacity(0.5) : const Color(0xFFF8FAFC),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(16),
                  bottomRight: Radius.circular(16),
                ),
                border: Border(top: BorderSide(color: AppTheme.getBorderColor(context))),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(l10n.close,
                        style: TextStyle(color: AppTheme.getTextSecondary(context))),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      onEdit();
                    },
                    icon: const Icon(Icons.edit, size: 18, color: Colors.white),
                    label: Text(l10n.edit, style: const TextStyle(color: Colors.white)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

Widget _sectionHeader(BuildContext context, String title, IconData icon) {
  return Row(
    children: [
      Icon(icon, size: 18, color: Theme.of(context).colorScheme.primary),
      const SizedBox(width: 8),
      Text(title,
          style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: AppTheme.getTextPrimary(context))),
    ],
  );
}

Widget _infoGrid(BuildContext context, List<(String, String)> items) {
  return Wrap(
    spacing: 16,
    runSpacing: 12,
    children: items
        .map((item) => SizedBox(width: 250, child: _detailItem(context, item.$1, item.$2)))
        .toList(),
  );
}

Widget _detailItem(BuildContext context, String label, String value) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: TextStyle(
                fontSize: 12,
                color: AppTheme.getTextSecondary(context),
                fontWeight: FontWeight.w500)),
        const SizedBox(height: 4),
        Text(value, style: TextStyle(fontSize: 16, color: AppTheme.getTextPrimary(context))),
      ],
    ),
  );
}
