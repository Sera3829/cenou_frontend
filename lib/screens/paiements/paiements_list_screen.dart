import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../providers/paiement_provider.dart';
import '../../services/connectivity_service.dart';
import '../../models/paiement.dart';
import '../../utils/mobile_responsive.dart';
import '../../l10n/app_localizations.dart';
import '../../widgets/mobile/list_states.dart';
import '../../widgets/mobile/meta_chip.dart';
import 'widgets/paiement_stats_card.dart';
import 'widgets/paiement_card.dart';
import '../../widgets/offline_banner.dart';
import 'paiement_detail_screen.dart';
import 'initier_paiement_screen.dart';

/// Écran liste des paiements — responsive mobile/tablette.
class PaiementsListScreen extends StatefulWidget {
  const PaiementsListScreen({super.key});

  @override
  State<PaiementsListScreen> createState() => _PaiementsListScreenState();
}

class _PaiementsListScreenState extends State<PaiementsListScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<PaiementProvider>(context, listen: false).refresh();
    });
  }

  // ── Navigation vers le paiement (avec vérif connexion) ──────────────────
  void _goToPaiement(BuildContext context, AppLocalizations l10n) {
    final conn = Provider.of<ConnectivityService>(context, listen: false);
    if (conn.isOffline) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.offlinePaymentRequired),
          backgroundColor: Colors.orange,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const InitierPaiementScreen()),
    );
  }

  // ── Infos statut ─────────────────────────────────────────────────────────
  StatusInfo _getStatusInfo(Paiement p) {
    if (p.isConfirme) {
      return StatusInfo(AppTheme.successColor, Icons.check_circle_rounded);
    }
    if (p.isEchec) {
      return StatusInfo(AppTheme.errorColor, Icons.cancel_rounded);
    }
    return StatusInfo(AppTheme.warningColor, Icons.pending_actions_rounded);
  }

  IconData _getModeIcon(String mode) {
    switch (mode.toUpperCase()) {
      case 'ORANGE_MONEY':
        return Icons.phone_android_rounded;
      case 'MOOV_MONEY':
        return Icons.phone_iphone_rounded;
      case 'WAVE':
        return Icons.account_balance_wallet_rounded;
      case 'ESPECES':
        return Icons.money_rounded;
      case 'VIREMENT':
        return Icons.account_balance_rounded;
      default:
        return Icons.payment_rounded;
    }
  }

  // ── Build ────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor:
          isDark ? const Color(0xFF121212) : AppTheme.backgroundColor,
      appBar: _buildAppBar(isDark, l10n),
      body: Column(
        children: [
          Consumer2<PaiementProvider, ConnectivityService>(
            builder: (_, provider, reseau, __) => OfflineBanner(
              isFromCache: provider.isFromCache,
              isOnline: reseau.isOnline,
              cacheAgeMinutes: provider.cacheAgeMinutes,
              onRefresh: provider.refresh,
            ),
          ),
          Expanded(child: _buildContenu(isDark, l10n)),
        ],
      ),
      floatingActionButton: _buildFab(context, l10n),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  Widget _buildContenu(bool isDark, AppLocalizations l10n) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final config = ResponsiveConfig.fromConstraints(constraints);
        return Consumer<PaiementProvider>(
          builder: (context, provider, _) {
            if (provider.isLoading && provider.paiements.isEmpty) {
              return MobileLoadingState(
                  config: config, message: l10n.loadingPayments);
            }
            if (provider.error != null) {
              return MobileErrorState(
                error: provider.error!,
                isDark: isDark,
                config: config,
                onRetry: provider.refresh,
                l10n: l10n,
              );
            }
            return RefreshIndicator(
              onRefresh: provider.refresh,
              color: Theme.of(context).colorScheme.primary,
              backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
              child: CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  SliverToBoxAdapter(
                    child: PaiementStatsCard(
                      provider: provider,
                      isDark: isDark,
                      config: config,
                      onPay: () => _goToPaiement(context, l10n),
                      l10n: l10n,
                    ),
                  ),
                  SliverPadding(
                    padding: EdgeInsets.fromLTRB(
                      config.isSmall ? 12 : 16,
                      12,
                      config.isSmall ? 12 : 16,
                      100, // espace pour le FAB
                    ),
                    sliver: provider.paiements.isEmpty
                        ? SliverToBoxAdapter(
                            child: MobileEmptyState(
                                isDark: isDark,
                                config: config,
                                icon: Icons.receipt_long_outlined,
                                titre: l10n.noPayments,
                                sousTitre: l10n.noPaymentsSub))
                        : SliverList(
                            delegate: SliverChildBuilderDelegate(
                              (_, i) => PaiementCard(
                                paiement: provider.paiements[i],
                                isDark: isDark,
                                config: config,
                                statusInfo:
                                    _getStatusInfo(provider.paiements[i]),
                                modeIcon: _getModeIcon(
                                    provider.paiements[i].modePaiement),
                                onTap: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => PaiementDetailScreen(
                                        paiementId: provider.paiements[i].id),
                                  ),
                                ),
                                l10n: l10n,
                              ),
                              childCount: provider.paiements.length,
                            ),
                          ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  PreferredSizeWidget _buildAppBar(bool isDark, AppLocalizations l10n) {
    return AppBar(
      title: Text(
        l10n.navPayments,
        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 19),
      ),
      centerTitle: true,
      actions: [
        // L'état « données en cache » est porté par OfflineBanner sous l'AppBar.
        IconButton(
          icon: const Icon(Icons.history_rounded),
          onPressed: () {},
          tooltip: l10n.fullHistory,
        ),
      ],
    );
  }

  Widget _buildFab(BuildContext context, AppLocalizations l10n) {
    final config = ResponsiveConfig.fromConstraints(
      BoxConstraints(maxWidth: MediaQuery.of(context).size.width),
    );
    return FloatingActionButton.extended(
      onPressed: () => _goToPaiement(context, l10n),
      icon: const Icon(Icons.add_rounded, size: 22),
      label: Text(
        config.isSmall ? l10n.newPaymentShort : l10n.newPayment,
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
      backgroundColor: Theme.of(context).colorScheme.primary,
      foregroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 4,
    );
  }
}
