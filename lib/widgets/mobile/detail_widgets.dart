import 'package:flutter/material.dart';
import '../../utils/mobile_responsive.dart';
import '../../l10n/app_localizations.dart';

// ════════════════════════════════════════════════════════════════
// Éléments partagés des écrans de détail mobiles (paiement, signalement…).
//
// Ils étaient dupliqués à l'identique d'un écran à l'autre.
// ════════════════════════════════════════════════════════════════

class CacheChip extends StatelessWidget {
  final AppLocalizations l10n;
  const CacheChip({super.key, required this.l10n});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.amber.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.amber.withOpacity(0.4)),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        const Icon(Icons.history, size: 14, color: Colors.amber),
        const SizedBox(width: 4),
        Text(l10n.offlineData,
            style: const TextStyle(
                color: Colors.amber,
                fontSize: 12,
                fontWeight: FontWeight.w600)),
      ]),
    );
  }
}

class DetailRowData {
  final String label, value;
  final IconData icon;
  const DetailRowData(this.label, this.value, this.icon);
}

class DetailRow extends StatelessWidget {
  final String label, value;
  final IconData icon;
  final bool isDark;
  final ResponsiveConfig config;
  const DetailRow({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    required this.isDark,
    required this.config,
  });

  @override
  Widget build(BuildContext context) {
    final iconSize = config.responsive(small: 17, medium: 19, large: 20);
    final labelSize = config.responsive(small: 11, medium: 12, large: 12);
    final valueSize = config.responsive(small: 13, medium: 15, large: 16);

    return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Icon(icon,
          size: iconSize,
          color: isDark ? Colors.grey.shade400 : Colors.grey[600]),
      const SizedBox(width: 10),
      Expanded(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label,
              style: TextStyle(
                  fontSize: labelSize,
                  color: isDark ? Colors.grey.shade400 : Colors.grey[600])),
          const SizedBox(height: 2),
          Text(value,
              style: TextStyle(
                  fontSize: valueSize,
                  fontWeight: FontWeight.w500,
                  color: isDark ? Colors.white : Colors.black87),
              maxLines: 2,
              overflow: TextOverflow.ellipsis),
        ]),
      ),
    ]);
  }
}

// ── _ReceiptCard — avec spinner et états désactivés ──────────────────────────

class MobileDetailErrorView extends StatelessWidget {
  final String error;
  final bool isDark, isOffline;
  final ResponsiveConfig config;
  final VoidCallback? onRetry;
  final AppLocalizations l10n;

  const MobileDetailErrorView({
    super.key,
    required this.error,
    required this.isDark,
    required this.isOffline,
    required this.config,
    required this.onRetry,
    required this.l10n,
  });

  @override
  Widget build(BuildContext context) {
    final iconSize = config.responsive(small: 52, medium: 62, large: 70);
    final titleSize = config.responsive(small: 15, medium: 17, large: 18);
    final bodySize = config.responsive(small: 12, medium: 13, large: 14);
    final displayError = config.isSmall && error.length > 70
        ? '${error.substring(0, 69)}…'
        : error;

    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(
            horizontal: config.responsive(small: 24, medium: 36, large: 48)),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(
            isOffline ? Icons.wifi_off : Icons.error_outline,
            size: iconSize,
            color: isDark ? Colors.grey.shade600 : Colors.grey[400],
          ),
          const SizedBox(height: 14),
          Text(
            isOffline ? l10n.offline : l10n.loadingError,
            style: TextStyle(
                fontSize: titleSize,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.grey.shade300 : Colors.grey[600]),
          ),
          const SizedBox(height: 8),
          Text(displayError,
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: bodySize,
                  color: isDark ? Colors.grey.shade400 : Colors.grey[500],
                  height: 1.4)),
          if (onRetry != null) ...[
            const SizedBox(height: 22),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh, size: 18),
              label: Text(l10n.retry),
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(
                    horizontal: config.isSmall ? 20 : 28,
                    vertical: config.isSmall ? 11 : 13),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ]),
      ),
    );
  }
}
