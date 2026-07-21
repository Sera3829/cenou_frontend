import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';

/// Bandeau uniforme signalant que les données affichées proviennent du cache local.
///
/// Deux variantes, distinguées automatiquement par [isOnline] :
///  - hors ligne  → ambre, on n'a pas le choix, pas de bouton de rechargement ;
///  - en ligne    → bleu, le réseau est revenu mais l'écran affiche encore
///                  du cache (erreur serveur) : on propose « Réessayer ».
///
/// À placer juste sous l'AppBar, au-dessus du contenu de l'écran.
class OfflineBanner extends StatelessWidget {
  /// N'affiche rien si les données sont fraîches.
  final bool isFromCache;

  /// État réseau courant, pour choisir la variante et proposer ou non le rechargement.
  final bool isOnline;

  /// Âge du cache en minutes ; masque la mention si null.
  final int? cacheAgeMinutes;

  /// Rechargement déclenché depuis le bandeau (proposé uniquement si en ligne).
  final VoidCallback? onRefresh;

  const OfflineBanner({
    super.key,
    required this.isFromCache,
    required this.isOnline,
    this.cacheAgeMinutes,
    this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    if (!isFromCache) return const SizedBox.shrink();

    final l10n = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Hors ligne : ambre (situation subie). En ligne : bleu (simple info).
    final Color accent = isOnline
        ? (isDark ? const Color(0xFF64B5F6) : const Color(0xFF1E3A8A))
        : (isDark ? const Color(0xFFFFB74D) : const Color(0xFFB26A00));
    final Color background = accent.withValues(alpha: isDark ? 0.16 : 0.10);

    final String titre =
        isOnline ? l10n.staleBannerTitle : l10n.offlineBannerTitle;

    return Material(
      color: background,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          children: [
            Icon(
              isOnline ? Icons.cloud_queue : Icons.cloud_off_rounded,
              size: 18,
              color: accent,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    titre,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: accent,
                    ),
                  ),
                  if (cacheAgeMinutes != null)
                    Text(
                      l10n.lastUpdated(l10n.relativeAge(cacheAgeMinutes!)),
                      style: TextStyle(
                        fontSize: 11,
                        color: accent.withValues(alpha: 0.85),
                      ),
                    ),
                ],
              ),
            ),
            if (isOnline && onRefresh != null) ...[
              const SizedBox(width: 8),
              TextButton(
                onPressed: onRefresh,
                style: TextButton.styleFrom(
                  foregroundColor: accent,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  minimumSize: const Size(0, 32),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Text(
                  l10n.retry,
                  style: const TextStyle(
                      fontSize: 12, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
