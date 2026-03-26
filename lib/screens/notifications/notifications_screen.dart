import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../config/theme.dart';
import '../../providers/notification_provider.dart';
import '../../services/connectivity_service.dart';
import 'annonce_details_screen.dart';

/// Écran affichant la liste des notifications.
class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({Key? key}) : super(key: key);

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<NotificationProvider>(context, listen: false).loadNotifications();
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121212) : AppTheme.backgroundColor,
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
                        'Notifications',
                        style: TextStyle(
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    // Badge indiquant que les données proviennent du cache
                    if (provider.isFromCache) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.amber,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: const [
                            Icon(Icons.history, size: 12, color: Colors.white),
                            SizedBox(width: 4),
                            Text(
                              'Cache',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
                if (provider.unreadCount > 0)
                  Text(
                    '${provider.unreadCount} non lue(s)',
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
              if (provider.unreadCount > 0 && provider.canPerformOnlineAction()) {
                return TextButton(
                  onPressed: () async {
                    final success = await provider.markAllAsRead();
                    if (success && context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Toutes les notifications marquées comme lues'),
                          backgroundColor: AppTheme.successColor,
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    } else if (!success && provider.error != null && context.mounted) {
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
                    'Tout marquer lu',
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
      body: _buildBody(isDark),
    );
  }

  /// Construit le contenu principal de l'écran.
  Widget _buildBody(bool isDark) {
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
          return _buildErrorState(provider, isDark);
        }

        if (provider.notifications.isEmpty) {
          return _buildEmptyState(isDark);
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
              return _buildNotificationCard(notification, provider, isDark);
            },
          ),
        );
      },
    );
  }

  /// Construit une carte individuelle pour une notification.
  Widget _buildNotificationCard(
      Map<String, dynamic> notification,
      NotificationProvider provider,
      bool isDark,
      ) {
    final isRead = notification['read'] as bool;
    final type = notification['type'] as String;

    Color typeColor;
    IconData typeIcon;

    switch (type) {
      case 'PAIEMENT':
        typeColor = AppTheme.successColor;
        typeIcon = Icons.payment;
        break;
      case 'SIGNALEMENT':
        typeColor = AppTheme.warningColor;
        typeIcon = Icons.report_problem;
        break;
      case 'ANNONCE':
        typeColor = AppTheme.infoColor;
        typeIcon = Icons.campaign;
        break;
      default:
        typeColor = Colors.grey;
        typeIcon = Icons.notifications;
    }

    return Dismissible(
      key: Key(notification['id'].toString()),
      background: Container(
        decoration: BoxDecoration(
          color: AppTheme.errorColor,
          borderRadius: BorderRadius.circular(12),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      direction: DismissDirection.endToStart,
      onDismissed: (direction) async {
        final success = await provider.deleteNotification(notification['id']);
        if (success && context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Notification supprimée'),
              backgroundColor: AppTheme.successColor,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      },
      confirmDismiss: (direction) async {
        // Vérifier la connexion avant de supprimer
        if (!provider.canPerformOnlineAction()) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Connexion internet requise pour supprimer une notification'),
              backgroundColor: Colors.orange,
              behavior: SnackBarBehavior.floating,
            ),
          );
          return false;
        }

        final isDarkConfirm = Theme.of(context).brightness == Brightness.dark;

        return await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            backgroundColor: isDarkConfirm ? const Color(0xFF1E1E1E) : Colors.white,
            title: Text(
              'Supprimer',
              style: TextStyle(
                color: isDarkConfirm ? Colors.white : Colors.black87,
              ),
            ),
            content: Text(
              'Voulez-vous vraiment supprimer cette notification ?',
              style: TextStyle(
                color: isDarkConfirm ? Colors.grey.shade300 : Colors.grey[700],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: Text(
                  'Annuler',
                  style: TextStyle(
                    color: isDarkConfirm ? Colors.grey.shade400 : Colors.grey[700],
                  ),
                ),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text(
                  'Supprimer',
                  style: TextStyle(color: Colors.red),
                ),
              ),
            ],
          ),
        );
      },
      child: Card(
        elevation: isRead ? (isDark ? 2 : 0) : (isDark ? 4 : 2),
        color: isRead
            ? (isDark ? const Color(0xFF1E1E1E) : Colors.white)
            : typeColor.withOpacity(isDark ? 0.15 : 0.05),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: isRead
              ? BorderSide.none
              : BorderSide(color: typeColor.withOpacity(isDark ? 0.4 : 0.3), width: 1),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () async {
            // Marquer comme lue selon le mode (en ligne ou hors ligne)
            if (provider.canPerformOnlineAction()) {
              final success = await provider.markAsRead(notification['id']);
              if (success && context.mounted) {
                _navigateToNotification(notification);
              }
            } else {
              await provider.markAsReadLocally(notification['id']);
              if (context.mounted) {
                _navigateToNotification(notification);
              }
            }
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: typeColor.withOpacity(isDark ? 0.2 : 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(typeIcon, color: typeColor, size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        notification['title'],
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: isRead ? FontWeight.normal : FontWeight.bold,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        notification['message'],
                        style: TextStyle(
                          fontSize: 14,
                          color: isDark ? Colors.grey.shade300 : Colors.grey[700],
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _formatDate(notification['createdAt']),
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? Colors.grey.shade500 : Colors.grey[500],
                        ),
                      ),
                    ],
                  ),
                ),
                if (!isRead)
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: typeColor,
                      shape: BoxShape.circle,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Navigue vers l'écran approprié en fonction du type de notification.
  void _navigateToNotification(Map<String, dynamic> notification) {
    final type = notification['type'];
    final data = notification['data'] as Map<String, dynamic>? ?? {};

    switch (type) {
      case 'ANNONCE':
        final annonceId = data['annonce_id'];
        if (annonceId != null) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AnnonceDetailsScreen(annonceId: int.parse(annonceId.toString())),
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
          const SnackBar(
            content: Text('Détails non disponibles'),
            backgroundColor: AppTheme.warningColor,
            behavior: SnackBarBehavior.floating,
          ),
        );
    }
  }

  /// Affiche un message lorsque la liste est vide.
  Widget _buildEmptyState(bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.notifications_none,
            size: 80,
            color: isDark ? Colors.grey.shade700 : Colors.grey[300],
          ),
          const SizedBox(height: 16),
          Text(
            'Aucune notification',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.grey.shade300 : Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Vous serez notifié des événements importants',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isDark ? Colors.grey.shade400 : Colors.grey[500],
            ),
          ),
          const SizedBox(height: 24),
          Consumer<NotificationProvider>(
            builder: (context, provider, _) {
              return ElevatedButton(
                onPressed: () => provider.refresh(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Rafraîchir'),
              );
            },
          ),
        ],
      ),
    );
  }

  /// Affiche un message en cas d'erreur de chargement.
  Widget _buildErrorState(NotificationProvider provider, bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 64,
            color: isDark ? Colors.red.shade400 : Colors.red,
          ),
          const SizedBox(height: 16),
          Text(
            'Erreur de chargement',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              provider.error ?? 'Impossible de charger les notifications',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: isDark ? Colors.grey.shade400 : Colors.grey[600],
              ),
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => provider.refresh(),
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Colors.white,
            ),
            child: const Text('Réessayer'),
          ),
        ],
      ),
    );
  }

  /// Formate la date pour l'affichage (ex: "Il y a 5 min", "Il y a 2h", "dd/MM/yyyy").
  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inMinutes < 60) {
      return 'Il y a ${difference.inMinutes} min';
    } else if (difference.inHours < 24) {
      return 'Il y a ${difference.inHours}h';
    } else if (difference.inDays < 7) {
      return 'Il y a ${difference.inDays}j';
    } else {
      return DateFormat('dd/MM/yyyy').format(date);
    }
  }
}