import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cenou_mobile/l10n/app_localizations.dart';
import 'package:cenou_mobile/providers/auth_provider.dart';

/// Carte de bienvenue du tableau de bord (salutation personnalisée + rafraîchir).
class DashboardWelcome extends StatelessWidget {
  final AppLocalizations l10n;
  final VoidCallback onRefresh;
  const DashboardWelcome({super.key, required this.l10n, required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isWide = MediaQuery.of(context).size.width > 900;

    final prenom = Provider.of<AuthProvider>(context, listen: false).user?.prenom ?? '';
    final greeting = prenom.isNotEmpty ? '${l10n.hello} $prenom' : l10n.welcomeDashboard;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: isWide ? 28 : 20, vertical: isWide ? 24 : 20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [const Color(0xFF0F172A), const Color(0xFF1E40AF)]
              : [const Color(0xFF1E3A8A), const Color(0xFF3B82F6)],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(greeting,
                    style: TextStyle(
                        fontSize: isWide ? 24 : 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        height: 1.2)),
                const SizedBox(height: 8),
                Text(l10n.manageResidencesRealtime,
                    style: TextStyle(
                        fontSize: isWide ? 14 : 13, color: Colors.white.withOpacity(0.85))),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Material(
            color: Colors.white.withOpacity(0.15),
            borderRadius: BorderRadius.circular(12),
            child: InkWell(
              onTap: onRefresh,
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.refresh_rounded, size: 18, color: Colors.white),
                    if (isWide) ...[
                      const SizedBox(width: 8),
                      Text(l10n.refresh,
                          style: const TextStyle(
                              color: Colors.white, fontWeight: FontWeight.w600)),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
