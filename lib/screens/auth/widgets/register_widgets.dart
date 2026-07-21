import 'package:flutter/material.dart';
import '../../../utils/mobile_responsive.dart';
import '../../../l10n/app_localizations.dart';

/// Une exigence de mot de passe, cochée ou non.
Widget buildPasswordRule(String text, bool valid) {
  return Row(
    children: [
      Icon(
        valid ? Icons.check_circle : Icons.cancel,
        size: 14,
        color: valid ? Colors.green : Colors.red.shade400,
      ),
      const SizedBox(width: 6),
      Text(
        text,
        style: TextStyle(
          fontSize: 11,
          color: valid ? Colors.green : Colors.grey.shade600,
        ),
      ),
    ],
  );
}

// ==================== HEADER ====================

/// En-tête de l'écran d'inscription.
Widget buildRegisterHeader(BuildContext context, bool isDark,
    ResponsiveConfig config, AppLocalizations l10n) {
  final titleSize = config.responsive(small: 24, medium: 28, large: 32);
  final subtitleSize = config.responsive(small: 14, medium: 15, large: 16);

  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        l10n.createAccountTitle,
        style: TextStyle(
          fontSize: titleSize,
          fontWeight: FontWeight.bold,
          color: Theme.of(context).colorScheme.primary,
        ),
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
      const SizedBox(height: 8),
      Text(
        l10n.fillInfoToRegister,
        style: TextStyle(
          fontSize: subtitleSize,
          color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
        ),
      ),
      const SizedBox(height: 24),
    ],
  );
}
