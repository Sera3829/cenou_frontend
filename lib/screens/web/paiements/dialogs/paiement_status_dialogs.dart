import 'package:flutter/material.dart';
import 'package:cenou_mobile/config/theme.dart';
import 'package:cenou_mobile/l10n/app_localizations.dart';
import 'package:cenou_mobile/providers/web/paiement_admin_provider.dart';

/// Confirme un paiement (commentaire optionnel) → CONFIRME.
Future<void> confirmPaiementDialog(BuildContext context, String paiementId,
    PaiementAdminProvider provider, AppLocalizations l10n) async {
  final commentaireController = TextEditingController();
  final isDark = Theme.of(context).brightness == Brightness.dark;
  try {
    final commentaire = await showDialog<String>(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: AppTheme.getCardBackground(context),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Text(l10n.confirmPaymentTitle,
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.getTextPrimary(context))),
            const SizedBox(height: 16),
            Text(l10n.confirmPaymentQuestion,
                style: TextStyle(color: AppTheme.getTextSecondary(context))),
            const SizedBox(height: 16),
            TextField(
              controller: commentaireController,
              decoration: InputDecoration(
                labelText: l10n.optionalComment,
                labelStyle: TextStyle(color: AppTheme.getTextSecondary(context)),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: AppTheme.getBorderColor(context))),
                enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: AppTheme.getBorderColor(context))),
                focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide:
                        BorderSide(color: Theme.of(context).colorScheme.primary, width: 2)),
                filled: true,
                fillColor: isDark ? Colors.grey.shade900.withOpacity(0.3) : Colors.grey.shade50,
              ),
              maxLines: 3,
              style: TextStyle(color: AppTheme.getTextPrimary(context)),
            ),
            const SizedBox(height: 24),
            Row(mainAxisAlignment: MainAxisAlignment.end, children: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text(l10n.cancel,
                    style: TextStyle(color: AppTheme.getTextSecondary(context))),
              ),
              const SizedBox(width: 12),
              ElevatedButton(
                onPressed: () => Navigator.pop(ctx, commentaireController.text),
                style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    foregroundColor: Colors.white),
                child: Text(l10n.confirm),
              ),
            ]),
          ]),
        ),
      ),
    );
    if (commentaire == null) return;
    await provider.updateStatutPaiement(
        paiementId: paiementId,
        nouveauStatut: 'CONFIRME',
        raison: commentaire.isNotEmpty ? commentaire : null);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(l10n.paymentConfirmedSuccess),
          backgroundColor: const Color(0xFF10B981),
          behavior: SnackBarBehavior.floating));
    }
  } catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('${l10n.error}: $e'),
          backgroundColor: const Color(0xFFEF4444),
          behavior: SnackBarBehavior.floating));
    }
  } finally {
    commentaireController.dispose();
  }
}

/// Rejette un paiement (motif obligatoire du champ) → ECHEC.
Future<void> rejectPaiementDialog(BuildContext context, String paiementId,
    PaiementAdminProvider provider, AppLocalizations l10n) async {
  final raisonController = TextEditingController();
  final isDark = Theme.of(context).brightness == Brightness.dark;
  try {
    final raison = await showDialog<String>(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: AppTheme.getCardBackground(context),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Text(l10n.markAsFailedTitle,
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.getTextPrimary(context))),
            const SizedBox(height: 16),
            Text(l10n.indicateFailureReason,
                style: TextStyle(color: AppTheme.getTextSecondary(context))),
            const SizedBox(height: 16),
            TextField(
              controller: raisonController,
              decoration: InputDecoration(
                labelText: l10n.reason,
                labelStyle: TextStyle(color: AppTheme.getTextSecondary(context)),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: AppTheme.getBorderColor(context))),
                enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: AppTheme.getBorderColor(context))),
                focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide:
                        BorderSide(color: Theme.of(context).colorScheme.primary, width: 2)),
                hintText: l10n.failureReasonHint,
                hintStyle: TextStyle(color: AppTheme.getTextTertiary(context)),
                filled: true,
                fillColor: isDark ? Colors.grey.shade900.withOpacity(0.3) : Colors.grey.shade50,
              ),
              maxLines: 3,
              style: TextStyle(color: AppTheme.getTextPrimary(context)),
            ),
            const SizedBox(height: 24),
            Row(mainAxisAlignment: MainAxisAlignment.end, children: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text(l10n.cancel,
                    style: TextStyle(color: AppTheme.getTextSecondary(context))),
              ),
              const SizedBox(width: 12),
              ElevatedButton(
                onPressed: () => Navigator.pop(ctx, raisonController.text),
                style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    foregroundColor: Colors.white),
                child: Text(l10n.validate),
              ),
            ]),
          ]),
        ),
      ),
    );
    if (raison == null) return;
    await provider.updateStatutPaiement(
        paiementId: paiementId,
        nouveauStatut: 'ECHEC',
        raison: raison.isNotEmpty ? raison : null);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(l10n.paymentMarkedAsFailed),
          backgroundColor: const Color(0xFFEF4444),
          behavior: SnackBarBehavior.floating));
    }
  } catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('${l10n.error}: $e'),
          backgroundColor: const Color(0xFFEF4444),
          behavior: SnackBarBehavior.floating));
    }
  } finally {
    raisonController.dispose();
  }
}
