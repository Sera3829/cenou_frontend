import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cenou_mobile/config/theme.dart';
import 'package:cenou_mobile/l10n/app_localizations.dart';
import 'package:cenou_mobile/providers/web/paiement_admin_provider.dart';
import 'package:cenou_mobile/screens/web/paiements/utils/paiement_display.dart';

/// Bandeau de statistiques des paiements (total, montant, en attente, taux).
class PaiementStats extends StatelessWidget {
  final AppLocalizations l10n;
  const PaiementStats({super.key, required this.l10n});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Consumer<PaiementAdminProvider>(
      builder: (context, provider, child) {
        final stats = provider.statistiques ?? {};
        final totalPaiements = (int.tryParse(stats['confirmes'] ?? '0') ?? 0) +
            (int.tryParse(stats['en_attente'] ?? '0') ?? 0) +
            (int.tryParse(stats['echecs'] ?? '0') ?? 0);
        final montantTotal = (double.tryParse(stats['total_confirme'] ?? '0') ?? 0) +
            (double.tryParse(stats['total_en_attente'] ?? '0') ?? 0) +
            (double.tryParse(stats['total_echec'] ?? '0') ?? 0);
        final enAttente = int.tryParse(stats['en_attente'] ?? '0') ?? 0;
        final confirmes = int.tryParse(stats['confirmes'] ?? '0') ?? 0;
        final tauxReussite = totalPaiements > 0 ? ((confirmes / totalPaiements) * 100) : 0;

        final screenWidth = MediaQuery.of(context).size.width;
        final sidebarWidth = screenWidth > 900 ? 280.0 : 0.0;
        final isWide = (screenWidth - sidebarWidth) > 700;

        return Container(
          padding: const EdgeInsets.all(24),
          color: isDark ? Colors.grey.shade900.withOpacity(0.5) : const Color(0xFFF1F5F9),
          child: isWide
              ? Row(children: [
                  Expanded(child: _card(context, l10n.totalPayments, '$totalPaiements', const Color(0xFF3B82F6), Icons.payments, isDark)),
                  const SizedBox(width: 16),
                  Expanded(child: _card(context, l10n.totalAmount, '${formatMontant(montantTotal, l10n)} F', const Color(0xFF10B981), Icons.account_balance_wallet, isDark)),
                  const SizedBox(width: 16),
                  Expanded(child: _card(context, l10n.pending, '$enAttente', const Color(0xFFF59E0B), Icons.hourglass_empty, isDark)),
                  const SizedBox(width: 16),
                  Expanded(child: _card(context, l10n.successRate, '${tauxReussite.toStringAsFixed(1)}%', const Color(0xFF8B5CF6), Icons.trending_up, isDark)),
                ])
              : Column(children: [
                  Row(children: [
                    Expanded(child: _card(context, l10n.total, '$totalPaiements', const Color(0xFF3B82F6), Icons.payments, isDark)),
                    const SizedBox(width: 12),
                    Expanded(child: _card(context, l10n.amount, '${formatMontant(montantTotal, l10n)} F', const Color(0xFF10B981), Icons.account_balance_wallet, isDark)),
                  ]),
                  const SizedBox(height: 12),
                  Row(children: [
                    Expanded(child: _card(context, l10n.pending, '$enAttente', const Color(0xFFF59E0B), Icons.hourglass_empty, isDark)),
                    const SizedBox(width: 12),
                    Expanded(child: _card(context, l10n.rate, '${tauxReussite.toStringAsFixed(1)}%', const Color(0xFF8B5CF6), Icons.trending_up, isDark)),
                  ]),
                ]),
        );
      },
    );
  }

  Widget _card(BuildContext context, String label, String value, Color color, IconData icon, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.getCardBackground(context),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(isDark ? 0.1 : 0.05), blurRadius: 10),
        ],
      ),
      child: Row(children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withOpacity(isDark ? 0.2 : 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color, size: 28),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(value,
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: color)),
            const SizedBox(height: 4),
            Text(label, style: TextStyle(fontSize: 13, color: AppTheme.getTextSecondary(context))),
          ]),
        ),
      ]),
    );
  }
}
