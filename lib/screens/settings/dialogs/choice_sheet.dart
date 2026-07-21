import 'package:flutter/material.dart';
import '../../../config/theme.dart';
import '../widgets/settings_widgets.dart';

/// Une option proposée dans une feuille de choix.
class ChoixSheetOption {
  /// Valeur retournée à la sélection (ex. `'fr'`, `'dark'`).
  final String code;

  final String libelle;

  /// Vignette affichée à gauche : drapeau, icône…
  final Widget vignette;

  const ChoixSheetOption({
    required this.code,
    required this.libelle,
    required this.vignette,
  });
}

/// Feuille de choix des réglages (langue, thème…).
///
/// La feuille se ferme avant d'exécuter [onSelect] : l'appelant travaille donc
/// toujours avec un contexte valide, et l'utilisateur voit la fermeture sans
/// attendre la fin du traitement. Toucher l'option déjà active ne fait que
/// refermer la feuille.
Future<void> showChoixSheet(
  BuildContext context, {
  required String titre,
  required List<ChoixSheetOption> options,
  required String codeSelectionne,
  required Future<void> Function(String code) onSelect,
}) {
  final isDark = Theme.of(context).brightness == Brightness.dark;

  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => DraggableScrollableSheet(
      initialChildSize: 0.45,
      minChildSize: 0.35,
      maxChildSize: 0.7,
      builder: (_, scrollController) => Container(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(children: [
          // Poignée
          Container(
            margin: const EdgeInsets.only(top: 10, bottom: 6),
            width: 36,
            height: 4,
            decoration: BoxDecoration(
                color: isDark ? Colors.grey.shade600 : Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2)),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Text(titre,
                style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : Colors.black87)),
          ),
          settingsDivider(isDark),
          Expanded(
            child: ListView.separated(
              controller: scrollController,
              padding: EdgeInsets.zero,
              itemCount: options.length,
              separatorBuilder: (_, __) => settingsDivider(isDark),
              itemBuilder: (_, i) {
                final option = options[i];
                final estSelectionnee = option.code == codeSelectionne;

                return ListTile(
                  onTap: () async {
                    Navigator.pop(ctx);
                    if (estSelectionnee) return;
                    await onSelect(option.code);
                  },
                  leading: option.vignette,
                  title: Text(option.libelle,
                      style: TextStyle(
                          fontSize: 15,
                          fontWeight: estSelectionnee
                              ? FontWeight.w600
                              : FontWeight.normal,
                          color: isDark ? Colors.white : Colors.black87)),
                  trailing: estSelectionnee
                      ? Icon(Icons.check_rounded,
                          color: AppTheme.primaryColor, size: 22)
                      : null,
                );
              },
            ),
          ),
        ]),
      ),
    ),
  );
}
