import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../providers/notification_provider.dart';
import '../../services/connectivity_service.dart';
import '../../l10n/app_localizations.dart';
import '../../widgets/offline_banner.dart';
import 'widgets/notification_card.dart';
import 'widgets/notifications_states.dart';
import 'annonce_details_screen.dart';

/// Écran affichant la liste des notifications.
class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<NotificationProvider>(context, listen: false)
          .loadNotifications();
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor:
          isDark ? const Color(0xFF121212) : AppTheme.backgroundColor,
      appBar: AppBar(
        title: Consumer<NotificationProvider>(
          builder: (context, provider, _) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Expanded(
                      child: Text(
                        l10n.notifications,
                        style: TextStyle(
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    // L'état « données en cache » est porté par OfflineBanner
                    // sous l'AppBar.
                  ],
                ),
                if (provider.unreadCount > 0)
                  Text(
                    l10n.unreadCountText(provider.unreadCount),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.normal,
                      color: isDark ? Colors.grey.shade400 : Colors.grey[700],
                    ),
                  ),
              ],
            );
          },
        ),
        actions: [
          Consumer<NotificationProvider>(
            builder: (context, provider, _) {
              // Plus conditionné au réseau : hors ligne, le marquage est
              // appliqué localement puis rejoué à la reconnexion.
              if (provider.unreadCount > 0) {
                return TextButton(
                  onPressed: () async {
                    final success = await provider.markAllAsRead();
                    if (success && context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(l10n.allMarkedAsRead),
                          backgroundColor: AppTheme.successColor,
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    } else if (!success &&
                        provider.error != null &&
                        context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(provider.error!),
                          backgroundColor: AppTheme.errorColor,
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    }
                  },
                  child: Text(
                    l10n.markAllRead,
                    style: TextStyle(
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Consumer2<NotificationProvider, ConnectivityService>(
            builder: (_, provider, reseau, __) => OfflineBanner(
              isFromCache: provider.isFromCache,
              isOnline: reseau.isOnline,
              cacheAgeMinutes: provider.cacheAgeMinutes,
              onRefresh: provider.refresh,
            ),
          ),
          Expanded(child: _buildBody(isDark, l10n)),
        ],
      ),
    );
  }

  /// Construit le contenu principal de l'écran.
  Widget _buildBody(bool isDark, AppLocalizations l10n) {
    return Consumer<NotificationProvider>(
      builder: (context, provider, _) {
        if (provider.isLoading && provider.notifications.isEmpty) {
          return Center(
            child: CircularProgressIndicator(
              color: Theme.of(context).colorScheme.primary,
            ),
          );
        }

        if (provider.error != null && provider.notifications.isEmpty) {
          return NotificationsErrorState(
              provider: provider, isDark: isDark, l10n: l10n);
        }

        if (provider.notifications.isEmpty) {
          return NotificationsEmptyState(isDark: isDark, l10n: l10n);
        }

        return RefreshIndicator(
          onRefresh: () => provider.refresh(),
          color: Theme.of(context).colorScheme.primary,
          backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
          child: ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: provider.notifications.length,
            separatorBuilder: (context, index) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final notification = provider.notifications[index];
              return NotificationCard(
                notification: notification,
                provider: provider,
                isDark: isDark,
                l10n: l10n,
                onOpen: () => _navigateToNotification(notification, l10n),
              );
            },
          ),
        );
      },
    );
  }

  /// Navigue vers l'écran approprié en fonction du type de notification.
  void _navigateToNotification(
      Map<String, dynamic> notification, AppLocalizations l10n) {
    final type = notification['type'];
    final data = notification['data'] as Map<String, dynamic>? ?? {};

    switch (type) {
      case 'ANNONCE':
        final annonceId = data['annonce_id'];
        if (annonceId != null) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AnnonceDetailsScreen(
                  annonceId: int.parse(annonceId.toString())),
            ),
          );
        }
        break;
      case 'PAIEMENT':
        // À implémenter : navigation vers les détails du paiement
        break;
      case 'SIGNALEMENT':
        // À implémenter : navigation vers les détails du signalement
        break;
      default:
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.detailsNotAvailable),
            backgroundColor: AppTheme.warningColor,
            behavior: SnackBarBehavior.floating,
          ),
        );
    }
  }
}
