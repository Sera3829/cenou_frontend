import 'package:flutter/material.dart';
import 'package:cenou_mobile/config/theme.dart';
import 'package:cenou_mobile/l10n/app_localizations.dart';
import 'package:cenou_mobile/models/paiement.dart';
import 'package:cenou_mobile/providers/web/paiement_admin_provider.dart';
import '../export_preview_screen.dart';

/// Reçu d'un paiement (indicatif).
void exportReceipt(BuildContext context, Paiement paiement, AppLocalizations l10n) {
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(l10n.exportReceiptFor(paiement.referenceTransaction ?? '')),
      behavior: SnackBarBehavior.floating));
}

/// Export global des paiements filtrés : choix du format puis aperçu.
Future<void> exportPaiements(
    BuildContext context, PaiementAdminProvider provider, AppLocalizations l10n) async {
  if (provider.paiements.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(l10n.noPaymentsToExport),
        backgroundColor: const Color(0xFFF59E0B),
        behavior: SnackBarBehavior.floating));
    return;
  }
  final format = await showDialog<String>(
    context: context,
    builder: (ctx) => Dialog(
      backgroundColor: AppTheme.getCardBackground(context),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Text(l10n.exportPayments,
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.getTextPrimary(context))),
          const SizedBox(height: 16),
          Text(l10n.chooseExportFormat,
              style: TextStyle(color: AppTheme.getTextSecondary(context))),
          const SizedBox(height: 24),
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            TextButton(
                onPressed: () => Navigator.pop(ctx, 'pdf'),
                child: const Row(children: [
                  Icon(Icons.picture_as_pdf, color: Colors.red),
                  SizedBox(width: 8),
                  Text('PDF')
                ])),
            const SizedBox(width: 16),
            TextButton(
                onPressed: () => Navigator.pop(ctx, 'excel'),
                child: const Row(children: [
                  Icon(Icons.table_chart, color: Colors.green),
                  SizedBox(width: 8),
                  Text('Excel')
                ])),
            const SizedBox(width: 16),
            TextButton(
                onPressed: () => Navigator.pop(ctx, 'word'),
                child: const Row(children: [
                  Icon(Icons.description, color: Colors.blue),
                  SizedBox(width: 8),
                  Text('Word')
                ])),
          ]),
          const SizedBox(height: 24),
          Row(mainAxisAlignment: MainAxisAlignment.end, children: [
            TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text(l10n.cancel,
                    style: TextStyle(color: AppTheme.getTextSecondary(context)))),
          ]),
        ]),
      ),
    ),
  );
  if (format != null) {
    try {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(l10n.generatingFormat(format.toUpperCase())),
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating));
      await Navigator.push(
          context,
          MaterialPageRoute(
              builder: (context) => ExportPreviewScreen(
                  format: format, paiements: provider.paiements, filters: provider.filters)));
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('${l10n.exportError}: $e'),
            backgroundColor: const Color(0xFFEF4444),
            behavior: SnackBarBehavior.floating));
      }
    }
  }
}
