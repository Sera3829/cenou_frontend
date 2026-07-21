import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../providers/signalement_provider.dart';
import '../../services/connectivity_service.dart';
import '../../models/signalement.dart';
import '../../utils/mobile_responsive.dart';
import '../../l10n/app_localizations.dart';
import '../../widgets/mobile/list_states.dart';
import '../../widgets/mobile/meta_chip.dart';
import 'widgets/signalement_stats_card.dart';
import 'widgets/signalement_card.dart';
import 'dialogs/problem_types_dialog.dart';
import '../../widgets/offline_banner.dart';
import 'signalement_detail_screen.dart';
import 'create_signalement_screen.dart';

/// Écran liste des signalements — responsive mobile/tablette.
class SignalementsListScreen extends StatefulWidget {
  const SignalementsListScreen({super.key});

  @override
  State<SignalementsListScreen> createState() => _SignalementsListScreenState();
}

class _SignalementsListScreenState extends State<SignalementsListScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<SignalementProvider>(context, listen: false)
          .loadSignalements();
    });
  }

  // ── Navigation vers créer signalement (avec vérif connexion) ────────────
  void _goToCreate(BuildContext context, AppLocalizations l10n) {
    final conn = Provider.of<ConnectivityService>(context, listen: false);
    if (conn.isOffline) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(l10n.offlineCreateReport),
        backgroundColor: Colors.orange,
        behavior: SnackBarBehavior.floating,
      ));
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const CreateSignalementScreen()),
    );
  }

  // ── Infos statut ─────────────────────────────────────────────────────────
  StatusInfo _getStatusInfo(Signalement s) {
    if (s.isResolu) {
      return StatusInfo(AppTheme.successColor, Icons.check_circle_rounded);
    }
    if (s.isEnCours) {
      return StatusInfo(AppTheme.infoColor, Icons.build_rounded);
    }
    if (s.isAnnule) {
      return StatusInfo(Colors.grey, Icons.cancel_rounded);
    }
    return StatusInfo(AppTheme.warningColor, Icons.pending_actions_rounded);
  }

  IconData _getProblemIcon(String type) {
    switch (type.toUpperCase()) {
      case 'PLOMBERIE':
        return Icons.plumbing_rounded;
      case 'ELECTRICITE':
        return Icons.electrical_services_rounded;
      case 'TOITURE':
        return Icons.roofing_rounded;
      case 'SERRURE':
        return Icons.lock_rounded;
      case 'MOBILIER':
        return Icons.chair_rounded;
      default:
        return Icons.more_horiz_rounded;
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
          Consumer2<SignalementProvider, ConnectivityService>(
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
        return Consumer<SignalementProvider>(
          builder: (context, provider, _) {
            if (provider.isLoading && provider.signalements.isEmpty) {
              return MobileLoadingState(
                  config: config, message: l10n.loadingReports);
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
                    child: SignalementStatsCard(
                      provider: provider,
                      isDark: isDark,
                      config: config,
                      l10n: l10n,
                    ),
                  ),
                  if (provider.signalements.isNotEmpty)
                    SliverPadding(
                      padding: EdgeInsets.fromLTRB(
                        config.isSmall ? 12 : 20,
                        8,
                        config.isSmall ? 12 : 20,
                        4,
                      ),
                      sliver: SliverToBoxAdapter(
                        child: SignalementListHeader(
                          provider: provider,
                          isDark: isDark,
                          config: config,
                          l10n: l10n,
                        ),
                      ),
                    ),
                  SliverPadding(
                    padding: EdgeInsets.fromLTRB(
                      config.isSmall ? 12 : 16,
                      4,
                      config.isSmall ? 12 : 16,
                      100,
                    ),
                    sliver: provider.signalements.isEmpty
                        ? SliverToBoxAdapter(
                            child: MobileEmptyState(
                                isDark: isDark,
                                config: config,
                                icon: Icons.report_problem_outlined,
                                titre: l10n.noReports,
                                sousTitre: l10n.noReportsSub))
                        : SliverList(
                            delegate: SliverChildBuilderDelegate(
                              (_, i) => SignalementCard(
                                signalement: provider.signalements[i],
                                isDark: isDark,
                                config: config,
                                statusInfo:
                                    _getStatusInfo(provider.signalements[i]),
                                problemIcon: _getProblemIcon(
                                    provider.signalements[i].typeProbleme),
                                onTap: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => SignalementDetailScreen(
                                        signalementId:
                                            provider.signalements[i].id),
                                  ),
                                ),
                                l10n: l10n,
                              ),
                              childCount: provider.signalements.length,
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
        l10n.myReports,
        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 19),
      ),
      centerTitle: true,
      actions: [
        // L'état « données en cache » est porté par OfflineBanner sous l'AppBar.
        IconButton(
          icon: const Icon(Icons.info_outline_rounded),
          onPressed: () => showProblemTypesDialog(context, l10n),
          tooltip: l10n.problemTypes,
        ),
      ],
    );
  }

  Widget _buildFab(BuildContext context, AppLocalizations l10n) {
    final config = ResponsiveConfig.fromConstraints(
      BoxConstraints(maxWidth: MediaQuery.of(context).size.width),
    );
    return FloatingActionButton.extended(
      heroTag: 'btn_ajouter_signalement',
      onPressed: () => _goToCreate(context, l10n),
      icon: const Icon(Icons.add_rounded, size: 22),
      label: Text(
        config.isSmall ? l10n.reportShort : l10n.createReport,
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
      backgroundColor: AppTheme.errorColor,
      foregroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 4,
    );
  }
}
