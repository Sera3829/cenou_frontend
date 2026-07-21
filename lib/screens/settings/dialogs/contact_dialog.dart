import 'package:flutter/material.dart';
import '../../../config/theme.dart';
import '../../../l10n/app_localizations.dart';

/// Coordonnées du support.
void showContactDialog(BuildContext context, AppLocalizations l10n) {
  final isDark = Theme.of(context).brightness == Brightness.dark;
  showDialog(
    context: context,
    builder: (ctx) => AlertDialog(
      backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text(l10n.supportTitle,
          style: TextStyle(color: isDark ? Colors.white : Colors.black87)),
      content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.supportContact,
                style: TextStyle(
                    color: isDark ? Colors.grey.shade300 : Colors.black87)),
            const SizedBox(height: 12),
            _contactRow(Icons.email_rounded, '70382983b@gmail.com', isDark),
            const SizedBox(height: 8),
            _contactRow(Icons.phone_rounded, '+226 70 38 29 83', isDark),
            const SizedBox(height: 8),
            _contactRow(Icons.access_time_rounded, l10n.supportHours, isDark),
            const SizedBox(height: 8),
            _contactRow(Icons.location_on_rounded,
                'Bobo Dioulasso, Belle Ville', isDark),
          ]),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l10n.close,
                style: TextStyle(color: isDark ? Colors.grey.shade400 : null))),
        ElevatedButton(
            onPressed: () => Navigator.pop(ctx), child: Text(l10n.sendEmail)),
      ],
    ),
  );
}

Widget _contactRow(IconData icon, String text, bool isDark) {
  return Row(children: [
    Icon(icon, size: 17, color: AppTheme.primaryColor),
    const SizedBox(width: 10),
    Flexible(
        child: Text(text,
            style: TextStyle(color: isDark ? Colors.white : Colors.black87))),
  ]);
}
