import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cenou_mobile/config/theme.dart';
import 'package:cenou_mobile/l10n/app_localizations.dart';
import 'package:cenou_mobile/models/paiement.dart';
import 'package:cenou_mobile/screens/web/paiements/utils/paiement_display.dart';

/// Fiche détaillée d'un paiement. [onConfirm] : bouton « confirmer »
/// (affiché seulement si le paiement est en attente).
void showPaiementDetailsDialog(
  BuildContext context,
  Paiement paiement,
  AppLocalizations l10n, {
  required VoidCallback onConfirm,
}) {
  showDialog(
    context: context,
    builder: (context) => Dialog(
      backgroundColor: AppTheme.getCardBackground(context),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 40, vertical: 40),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l10n.paymentDetails,
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.getTextPrimary(context))),
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 8),
              SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _item(context, l10n.reference, paiement.referenceTransaction ?? 'N/A'),
                    _item(context, l10n.student, paiement.etudiantNomComplet),
                    if (paiement.matricule != null) _item(context, l10n.matricule, paiement.matricule!),
                    _item(context, l10n.center, paiement.centreNom ?? 'N/A'),
                    _item(context, l10n.room, paiement.numeroChambre ?? 'N/A'),
                    _item(context, l10n.amount, '${formatMontant(paiement.montant, l10n)} FCFA'),
                    _item(context, l10n.status, paiementStatutLabel(paiement.statut, l10n)),
                    _item(context, l10n.mode, paiementModeLabel(paiement.modePaiement, l10n)),
                    _item(
                        context,
                        l10n.paymentDate,
                        paiement.datePaiement != null
                            ? DateFormat('dd/MM/yyyy HH:mm', l10n.locale.languageCode)
                                .format(paiement.datePaiement!)
                            : l10n.notDefined),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 8),
              Row(mainAxisAlignment: MainAxisAlignment.end, children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(l10n.close,
                      style: TextStyle(color: AppTheme.getTextSecondary(context))),
                ),
                if (paiement.statut == 'EN_ATTENTE') ...[
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      onConfirm();
                    },
                    style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        foregroundColor: Colors.white),
                    child: Text(l10n.confirm),
                  ),
                ],
              ]),
            ],
          ),
        ),
      ),
    ),
  );
}

Widget _item(BuildContext context, String label, String value) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label,
          style: TextStyle(
              fontSize: 12,
              color: AppTheme.getTextSecondary(context),
              fontWeight: FontWeight.w500)),
      const SizedBox(height: 4),
      Text(value, style: TextStyle(fontSize: 16, color: AppTheme.getTextPrimary(context))),
    ]),
  );
}
