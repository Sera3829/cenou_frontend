import 'package:flutter/material.dart';
import '../../utils/mobile_responsive.dart';
import '../../l10n/app_localizations.dart';

// ════════════════════════════════════════════════════════════════
// États partagés des écrans de liste mobiles (paiements, signalements…).
//
// Ces trois états étaient dupliqués à l'identique d'un écran à l'autre, à
// l'icône et aux libellés près. Ils sont désormais paramétrés : un nouvel
// écran de liste les réutilise sans les recopier.
// ════════════════════════════════════════════════════════════════

/// Chargement initial d'une liste.
class MobileLoadingState extends StatelessWidget {
  final ResponsiveConfig config;

  /// Message affiché sous l'indicateur (ex. « Chargement des paiements… »).
  final String message;

  const MobileLoadingState({
    super.key,
    required this.config,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    final textSize = config.responsive(small: 13, medium: 15, large: 16);

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            strokeWidth: 2,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(height: 18),
          Text(
            message,
            style: TextStyle(fontSize: textSize, color: Colors.grey),
          ),
        ],
      ),
    );
  }
}

/// Liste vide : rien à afficher, sans que ce soit une erreur.
class MobileEmptyState extends StatelessWidget {
  final bool isDark;
  final ResponsiveConfig config;
  final IconData icon;
  final String titre;
  final String sousTitre;

  const MobileEmptyState({
    super.key,
    required this.isDark,
    required this.config,
    required this.icon,
    required this.titre,
    required this.sousTitre,
  });

  @override
  Widget build(BuildContext context) {
    final iconSize = config.responsive(small: 60, medium: 75, large: 85);
    final titleSize = config.responsive(small: 18, medium: 21, large: 23);
    final bodySize = config.responsive(small: 13, medium: 14, large: 15);
    final hPad = config.responsive(small: 20, medium: 32, large: 48);
    final vPad = config.responsive(small: 40, medium: 55, large: 65);

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: hPad, vertical: vPad),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: iconSize,
            color: isDark ? Colors.grey.shade700 : Colors.grey[300],
          ),
          const SizedBox(height: 20),
          Text(
            titre,
            style: TextStyle(
              fontSize: titleSize,
              fontWeight: FontWeight.w700,
              color: isDark ? Colors.grey.shade300 : Colors.grey[600],
            ),
          ),
          const SizedBox(height: 10),
          Text(
            sousTitre,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: bodySize,
              color: isDark ? Colors.grey.shade400 : Colors.grey[500],
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

/// Échec du chargement, avec proposition de réessayer.
class MobileErrorState extends StatelessWidget {
  final String error;
  final bool isDark;
  final ResponsiveConfig config;
  final VoidCallback onRetry;
  final AppLocalizations l10n;

  const MobileErrorState({
    super.key,
    required this.error,
    required this.isDark,
    required this.config,
    required this.onRetry,
    required this.l10n,
  });

  @override
  Widget build(BuildContext context) {
    final iconSize = config.responsive(small: 56, medium: 68, large: 76);
    final titleSize = config.responsive(small: 17, medium: 19, large: 21);
    final bodySize = config.responsive(small: 12, medium: 14, large: 15);
    final hPad = config.responsive(small: 20, medium: 32, large: 48);

    // Tronquer l'erreur sur petit écran
    final displayError = config.isSmall && error.length > 80
        ? '${error.substring(0, 79)}…'
        : error;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: hPad),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline_rounded,
            size: iconSize,
            color: isDark ? Colors.grey.shade600 : Colors.grey[400],
          ),
          const SizedBox(height: 20),
          Text(
            l10n.loadingError,
            style: TextStyle(
              fontSize: titleSize,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.grey.shade300 : Colors.grey[600],
            ),
          ),
          const SizedBox(height: 10),
          Text(
            displayError,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: bodySize,
              color: isDark ? Colors.grey.shade400 : Colors.grey[500],
              height: 1.5,
            ),
          ),
          const SizedBox(height: 28),
          ElevatedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh_rounded, size: 18),
            label: Text(l10n.retry),
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(
                horizontal: config.isSmall ? 20 : 28,
                vertical: config.isSmall ? 11 : 13,
              ),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ],
      ),
    );
  }
}
