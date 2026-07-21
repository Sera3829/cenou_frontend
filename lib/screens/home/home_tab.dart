import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../models/user.dart';
import '../../providers/auth_provider.dart';
import '../../providers/paiement_provider.dart';
import '../../providers/signalement_provider.dart';
import '../../services/connectivity_service.dart';
import '../../utils/mobile_responsive.dart';
import '../../l10n/app_localizations.dart';
import '../../widgets/offline_banner.dart';
import 'widgets/section_title.dart';
import 'widgets/logement_card.dart';
import 'widgets/stats_grid.dart';
import 'widgets/quick_actions.dart';

// ──────────────────────────────────────────────────────────────
// Onglet Accueil
// ──────────────────────────────────────────────────────────────

class HomeTab extends StatelessWidget {
  final int unreadCount;
  final VoidCallback onNotificationTap;

  const HomeTab({
    super.key,
    this.unreadCount = 0,
    required this.onNotificationTap,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final authProvider = Provider.of<AuthProvider>(context);
    final paiementProvider = Provider.of<PaiementProvider>(context);
    final signalementProvider = Provider.of<SignalementProvider>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final user = authProvider.user;

    return Scaffold(
      backgroundColor:
      isDark ? const Color(0xFF121212) : AppTheme.backgroundColor,
      appBar: _buildAppBar(context, user, isDark, l10n),
      body: Column(
        children: [
          // Fraîcheur des données de l'accueil : l'onglet agrège deux sources,
          // on annonce donc la plus ancienne des deux (le pire des cas).
          OfflineBanner(
            isFromCache:
                paiementProvider.isFromCache || signalementProvider.isFromCache,
            isOnline: context.watch<ConnectivityService>().isOnline,
            cacheAgeMinutes: _ageLePlusAncien(
              paiementProvider.cacheAgeMinutes,
              signalementProvider.cacheAgeMinutes,
            ),
            onRefresh: () {
              paiementProvider.refresh();
              signalementProvider.refresh();
            },
          ),
          Expanded(child: _buildContenu(
              authProvider, paiementProvider, signalementProvider, isDark, user, l10n)),
        ],
      ),
    );
  }

  /// Retourne le plus grand des deux âges (null ignoré).
  static int? _ageLePlusAncien(int? a, int? b) {
    if (a == null) return b;
    if (b == null) return a;
    return a > b ? a : b;
  }

  Widget _buildContenu(
      AuthProvider authProvider,
      PaiementProvider paiementProvider,
      SignalementProvider signalementProvider,
      bool isDark,
      User? user,
      AppLocalizations l10n) {
    return LayoutBuilder(
        builder: (context, constraints) {
          final config = ResponsiveConfig.fromConstraints(constraints);
          return RefreshIndicator(
            onRefresh: () async {
              await Future.wait([
                authProvider.refreshUser(),
                paiementProvider.refresh(),
                signalementProvider.refresh(),
              ]);
            },
            color: Theme.of(context).colorScheme.primary,
            backgroundColor:
            isDark ? const Color(0xFF1E1E1E) : Colors.white,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: config.horizontalPadding.copyWith(
                top: config.isShortScreen ? 12 : 16,
                bottom: config.isShortScreen ? 12 : 24,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Carte logement
                  LogementCard(user: user, isDark: isDark, config: config, l10n: l10n),
                  SizedBox(height: config.isShortScreen ? 12 : 16),

                  // Titre "Aperçu rapide"
                  SectionTitle(
                    text: l10n.quickOverview,
                    isDark: isDark,
                    config: config,
                  ),
                  SizedBox(height: config.isShortScreen ? 8 : 12),

                  // Grille des stats
                  StatsGrid(
                    paiementProvider: paiementProvider,
                    signalementProvider: signalementProvider,
                    isDark: isDark,
                    config: config,
                    l10n: l10n,
                  ),
                  SizedBox(height: config.isShortScreen ? 16 : 24),

                  // Titre "Actions rapides"
                  SectionTitle(
                    text: l10n.quickActions,
                    isDark: isDark,
                    config: config,
                  ),
                  SizedBox(height: config.isShortScreen ? 8 : 12),

                  // Boutons d'action
                  QuickActions(context: context, isDark: isDark, config: config, l10n: l10n),
                  SizedBox(height: config.isShortScreen ? 16 : 32),
                ],
              ),
            ),
          );
        },
      );
  }

  PreferredSizeWidget _buildAppBar(
      BuildContext context, User? user, bool isDark, AppLocalizations l10n) {
    // Prénom tronqué si trop long
    final prenom = user?.prenom ?? 'Utilisateur';
    final displayPrenom =
    prenom.length > 14 ? '${prenom.substring(0, 12)}…' : prenom;

    return AppBar(
      backgroundColor: Theme.of(context).colorScheme.primary,
      elevation: 0,
      centerTitle: true,
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            l10n.hello,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.normal,
              color: Colors.white,
            ),
          ),
          Text(
            displayPrenom,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ],
      ),
      actions: [
        // L'état hors ligne est porté par OfflineBanner sous l'AppBar.

        // Cloche de notifications
        Stack(
          clipBehavior: Clip.none,
          children: [
            IconButton(
              icon: const Icon(Icons.notifications_outlined,
                  color: Colors.white, size: 24),
              onPressed: onNotificationTap,
              tooltip: l10n.notifications,
              padding: const EdgeInsets.all(8),
            ),
            if (unreadCount > 0)
              Positioned(
                right: 6,
                top: 6,
                child: Container(
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Theme.of(context).colorScheme.primary,
                      width: 1.5,
                    ),
                  ),
                  constraints: const BoxConstraints(
                    minWidth: 17,
                    minHeight: 17,
                  ),
                  child: Center(
                    child: Text(
                      unreadCount > 99 ? '99+' : '$unreadCount',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                        height: 1,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(width: 4),
      ],
    );
  }
}

