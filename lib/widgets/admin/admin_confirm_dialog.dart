import 'package:flutter/material.dart';
import 'package:cenou_mobile/config/theme.dart';
import 'package:cenou_mobile/l10n/app_localizations.dart';

/// Dialogue de confirmation générique pour les écrans d'administration.
/// Retourne true si l'utilisateur confirme, false/null sinon.
/// [isCritical] colore le bouton de confirmation en rouge (action destructive).
Future<bool?> showAdminConfirmDialog(
  BuildContext context, {
  required String title,
  required String message,
  bool isCritical = false,
  required AppLocalizations l10n,
}) {
  return showDialog<bool>(
    context: context,
    builder: (context) => Dialog(
      backgroundColor: AppTheme.getCardBackground(context),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title,
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.getTextPrimary(context))),
            const SizedBox(height: 16),
            Text(message, style: TextStyle(color: AppTheme.getTextSecondary(context))),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: Text(l10n.cancel,
                      style: TextStyle(color: AppTheme.getTextSecondary(context))),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context, true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        isCritical ? const Color(0xFFEF4444) : Theme.of(context).colorScheme.primary,
                    foregroundColor: Colors.white,
                  ),
                  child: Text(isCritical ? l10n.deleteAction : l10n.confirmAction),
                ),
              ],
            ),
          ],
        ),
      ),
    ),
  );
}
