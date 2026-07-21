import 'package:flutter/material.dart';
import '../../../config/theme.dart';
import '../../../l10n/app_localizations.dart';

/// Confirmation affichée après l'initiation réussie d'un paiement.
Future<void> showPaiementSuccessDialog(
    BuildContext context, Map<String, dynamic> result) async {
  final l10n = AppLocalizations.of(context);
  final isDark = Theme.of(context).brightness == Brightness.dark;
  final paiement = result['paiement'];
  await showDialog(
    context: context,
    barrierDismissible: false,
    builder: (context) => AlertDialog(
      backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Row(children: [
        Icon(Icons.check_circle, color: AppTheme.successColor, size: 28),
        const SizedBox(width: 10),
        Expanded(
          child: Text(l10n.paymentInitiated,
              style: TextStyle(
                  color: isDark ? Colors.white : Colors.black87, fontSize: 17)),
        ),
      ]),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.paymentRequestRecorded,
              style: TextStyle(
                  color: isDark ? Colors.grey.shade300 : Colors.black87)),
          const SizedBox(height: 10),
          if (paiement != null) ...[
            Text(l10n.referenceLabel(paiement['reference']),
                style: TextStyle(
                    fontSize: 12,
                    color: isDark ? Colors.grey.shade400 : Colors.grey[600])),
            const SizedBox(height: 4),
            Text(l10n.periodRange(paiement['date_debut'], paiement['date_fin']),
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black87)),
          ],
          const SizedBox(height: 8),
          Text(l10n.willReceiveNotification,
              style: TextStyle(
                  fontSize: 13,
                  color: isDark ? Colors.grey.shade300 : Colors.black87)),
        ],
      ),
      actions: [
        ElevatedButton(
          onPressed: () => Navigator.pop(context),
          style: ElevatedButton.styleFrom(
            backgroundColor: Theme.of(context).colorScheme.primary,
            foregroundColor: Colors.white,
          ),
          child: Text(l10n.ok),
        ),
      ],
    ),
  );
}
