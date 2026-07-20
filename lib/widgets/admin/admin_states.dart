import 'package:flutter/material.dart';
import 'package:cenou_mobile/config/theme.dart';

/// États « vide » et « erreur » génériques pour les écrans d'administration.
/// Réutilisables (paiements, signalements, utilisateurs…).

class AdminEmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final List<Widget> actions;
  const AdminEmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.actions = const [],
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.all(24),
      padding: const EdgeInsets.all(48),
      decoration: BoxDecoration(
        color: AppTheme.getCardBackground(context),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(isDark ? 0.1 : 0.05), blurRadius: 10),
        ],
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 80, color: AppTheme.getTextTertiary(context)),
            const SizedBox(height: 24),
            Text(title,
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.getTextSecondary(context))),
            if (subtitle != null) ...[
              const SizedBox(height: 8),
              Text(subtitle!, style: TextStyle(color: AppTheme.getTextTertiary(context))),
            ],
            for (final action in actions) ...[
              const SizedBox(height: 12),
              action,
            ],
          ],
        ),
      ),
    );
  }
}

class AdminErrorState extends StatelessWidget {
  final String error;
  final String title;
  final String retryLabel;
  final VoidCallback onRetry;
  const AdminErrorState({
    super.key,
    required this.error,
    required this.title,
    required this.retryLabel,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(24),
      margin: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? Colors.red.shade900.withOpacity(0.1) : const Color(0xFFFEF2F2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isDark ? Colors.red.shade800 : const Color(0xFFFECACA)),
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 48, color: Colors.red.shade400),
            const SizedBox(height: 16),
            Text(title,
                style: TextStyle(
                    fontSize: 18, fontWeight: FontWeight.w600, color: Colors.red.shade400)),
            const SizedBox(height: 8),
            Text(error,
                textAlign: TextAlign.center,
                style: TextStyle(
                    color: isDark ? Colors.red.shade300 : const Color(0xFF991B1B))),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: onRetry,
              style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red.shade400, foregroundColor: Colors.white),
              child: Text(retryLabel),
            ),
          ],
        ),
      ),
    );
  }
}
