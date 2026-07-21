import 'package:flutter/material.dart';
import '../../../utils/mobile_responsive.dart';
import '../../../l10n/app_localizations.dart';

/// Une ligne du récapitulatif à confirmer.
class LigneRecap {
  final String label;
  final String valeur;

  /// Met la valeur en gras : réservé au total.
  final bool accentue;

  /// Vrai pour un simple trait de séparation, sans texte.
  final bool estSeparateur;

  const LigneRecap(this.label, this.valeur, {this.accentue = false})
      : estSeparateur = false;

  const LigneRecap.separateur()
      : label = '',
        valeur = '',
        accentue = false,
        estSeparateur = true;
}

/// Récapitulatif avant validation d'un paiement.
///
/// Le dialogue ne connaît rien du paiement : l'appelant lui fournit des lignes
/// déjà formatées. Renvoie `false` si l'utilisateur annule ou ferme.
Future<bool> showConfirmPaiementDialog(
  BuildContext context, {
  required List<LigneRecap> lignes,
  required bool isDark,
  required ResponsiveConfig config,
  required AppLocalizations l10n,
}) async {
  final confirme = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text(l10n.confirmPayment,
          style: TextStyle(
              fontSize: config.responsive(small: 15, medium: 17, large: 18),
              color: isDark ? Colors.white : Colors.black87)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final ligne in lignes)
            if (ligne.estSeparateur)
              const Divider(height: 20)
            else
              _LigneRecapTuile(ligne: ligne, isDark: isDark, config: config),
        ],
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.cancel)),
        ElevatedButton(
          onPressed: () => Navigator.pop(context, true),
          style: ElevatedButton.styleFrom(
            backgroundColor: Theme.of(context).colorScheme.primary,
            foregroundColor: Colors.white,
          ),
          child: Text(l10n.confirm),
        ),
      ],
    ),
  );

  return confirme ?? false;
}

class _LigneRecapTuile extends StatelessWidget {
  final LigneRecap ligne;
  final bool isDark;
  final ResponsiveConfig config;

  const _LigneRecapTuile({
    required this.ligne,
    required this.isDark,
    required this.config,
  });

  @override
  Widget build(BuildContext context) {
    final sz = config.responsive(small: 12, medium: 13, large: 14);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Flexible(
            child: Text(ligne.label,
                style: TextStyle(
                    fontSize: sz,
                    color: isDark ? Colors.grey.shade400 : Colors.grey[600])),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(ligne.valeur,
                textAlign: TextAlign.right,
                style: TextStyle(
                    fontWeight:
                        ligne.accentue ? FontWeight.bold : FontWeight.normal,
                    fontSize: sz,
                    color: isDark ? Colors.white : Colors.black87),
                maxLines: 1,
                overflow: TextOverflow.ellipsis),
          ),
        ],
      ),
    );
  }
}
