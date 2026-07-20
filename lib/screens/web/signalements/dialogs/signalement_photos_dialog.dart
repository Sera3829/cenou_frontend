import 'package:flutter/material.dart';
import 'package:cenou_mobile/config/theme.dart';
import 'package:cenou_mobile/config/app_config.dart';
import 'package:cenou_mobile/l10n/app_localizations.dart';
import 'package:cenou_mobile/models/signalement.dart';

/// Galerie des photos d'un signalement.
void showSignalementPhotosDialog(BuildContext context, Signalement s, AppLocalizations l10n) {
  final isDark = Theme.of(context).brightness == Brightness.dark;
  showDialog(
    context: context,
    builder: (context) => Dialog(
      backgroundColor: AppTheme.getCardBackground(context),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 40, vertical: 40),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 480,
          maxHeight: MediaQuery.of(context).size.height * 0.8,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Icon(Icons.photo_library, color: Theme.of(context).colorScheme.primary, size: 22),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(l10n.viewPhotos,
                        style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.getTextPrimary(context))),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: Icon(Icons.close, color: AppTheme.getTextSecondary(context)),
                  ),
                ],
              ),
            ),
            Divider(height: 1, color: AppTheme.getBorderColor(context)),
            Flexible(
              child: s.photos.isEmpty
                  ? Padding(
                      padding: const EdgeInsets.all(48),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.image_not_supported,
                              size: 64, color: AppTheme.getTextTertiary(context)),
                          const SizedBox(height: 16),
                          Text(l10n.noPhotosAvailable,
                              style: TextStyle(
                                  fontSize: 16, color: AppTheme.getTextSecondary(context))),
                        ],
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.all(20),
                      shrinkWrap: true,
                      itemCount: s.photos.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 16),
                      itemBuilder: (context, index) {
                        final url = s.photos[index];
                        final full =
                            url.startsWith('http') ? url : '${AppConfig.staticBaseUrl}$url';
                        return ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.network(
                            full,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(
                              height: 200,
                              decoration: BoxDecoration(
                                color: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Center(
                                child: Icon(Icons.broken_image,
                                    size: 48, color: AppTheme.getTextTertiary(context)),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
            ),
            Divider(height: 1, color: AppTheme.getBorderColor(context)),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(l10n.photoCount(s.photos.length),
                      style: TextStyle(color: AppTheme.getTextSecondary(context), fontSize: 14)),
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(l10n.close,
                        style: TextStyle(color: AppTheme.getTextSecondary(context))),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

/// Demande un commentaire (résolution) ou un motif (annulation).
/// Retourne le texte saisi, ou null si annulé.
Future<String?> askSignalementComment(
    BuildContext context, String statut, AppLocalizations l10n) async {
  final isDark = Theme.of(context).brightness == Brightness.dark;
  final ctrl = TextEditingController();
  final result = await showDialog<String>(
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
              Text(statut == 'RESOLU' ? l10n.resolutionComment : l10n.cancellationReason,
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.getTextPrimary(context))),
              const SizedBox(height: 16),
              TextField(
                controller: ctrl,
                decoration: InputDecoration(
                  hintText:
                      statut == 'RESOLU' ? l10n.describeResolution : l10n.indicateCancellationReason,
                  hintStyle: TextStyle(color: AppTheme.getTextSecondary(context)),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: AppTheme.getBorderColor(context)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: AppTheme.getBorderColor(context)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide:
                        BorderSide(color: Theme.of(context).colorScheme.primary, width: 2),
                  ),
                  filled: true,
                  fillColor: isDark ? Colors.grey.shade900.withOpacity(0.3) : Colors.grey.shade50,
                ),
                maxLines: 4,
                style: TextStyle(color: AppTheme.getTextPrimary(context)),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(l10n.cancel,
                        style: TextStyle(color: AppTheme.getTextSecondary(context))),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: () {
                      if (ctrl.text.trim().isNotEmpty) {
                        Navigator.pop(context, ctrl.text.trim());
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      foregroundColor: Colors.white,
                    ),
                    child: Text(l10n.validate),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    ),
  );
  ctrl.dispose();
  return result;
}
