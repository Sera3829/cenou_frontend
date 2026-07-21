import 'package:flutter/material.dart';
import '../../../l10n/app_localizations.dart';

/// Invite à signaler un problème depuis l'\''écran dédié.
void showReportDialog(BuildContext context, AppLocalizations l10n) {
  final isDark = Theme.of(context).brightness == Brightness.dark;
  showDialog(
    context: context,
    builder: (ctx) => AlertDialog(
      backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text(l10n.reportTitle,
          style: TextStyle(color: isDark ? Colors.white : Colors.black87)),
      content: Text(l10n.reportContent,
          style:
              TextStyle(color: isDark ? Colors.grey.shade300 : Colors.black87)),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l10n.cancel,
                style: TextStyle(color: isDark ? Colors.grey.shade400 : null))),
        ElevatedButton(
          onPressed: () {
            Navigator.pop(ctx);
            Navigator.pushNamed(context, '/signalements');
          },
          child: Text(l10n.report),
        ),
      ],
    ),
  );
}
