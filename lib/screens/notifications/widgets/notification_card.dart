import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../config/theme.dart';
import '../../../providers/notification_provider.dart';
import '../../../l10n/app_localizations.dart';

/// Carte d'une notification dans la liste.
///
/// Le fournisseur est passé tel quel : la carte gère elle-même la suppression
/// par balayage et le marquage en lecture, [onOpen] ne servant qu'à la suite
/// de la navigation, qui dépend du type de notification.
class NotificationCard extends StatelessWidget {
  final Map<String, dynamic> notification;
  final NotificationProvider provider;
  final bool isDark;
  final AppLocalizations l10n;
  final VoidCallback onOpen;

  const NotificationCard({
    super.key,
    required this.notification,
    required this.provider,
    required this.isDark,
    required this.l10n,
    required this.onOpen,
  });

  @override
  Widget build(BuildContext context) {
    final isRead = notification['read'] as bool;
    final type = notification['type'] as String;

    Color typeColor;
    IconData typeIcon;
    String typeLabel;

    switch (type) {
      case 'PAIEMENT':
        typeColor = AppTheme.successColor;
        typeIcon = Icons.payment;
        typeLabel = l10n.notifTypePaiement;
        break;
      case 'SIGNALEMENT':
        typeColor = AppTheme.warningColor;
        typeIcon = Icons.report_problem;
        typeLabel = l10n.notifTypeSignalement;
        break;
      case 'ANNONCE':
        typeColor = AppTheme.infoColor;
        typeIcon = Icons.campaign;
        typeLabel = l10n.notifTypeAnnonce;
        break;
      default:
        typeColor = Colors.grey;
        typeIcon = Icons.notifications;
        typeLabel = l10n.notifTypeAutre;
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
            SnackBar(
              content: Text(l10n.notificationDeleted),
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
            SnackBar(
              content: Text(l10n.offlineDeleteNotif),
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
            backgroundColor:
                isDarkConfirm ? const Color(0xFF1E1E1E) : Colors.white,
            title: Text(
              l10n.delete,
              style: TextStyle(
                color: isDarkConfirm ? Colors.white : Colors.black87,
              ),
            ),
            content: Text(
              l10n.deleteNotificationConfirm,
              style: TextStyle(
                color: isDarkConfirm ? Colors.grey.shade300 : Colors.grey[700],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: Text(
                  l10n.cancel,
                  style: TextStyle(
                    color:
                        isDarkConfirm ? Colors.grey.shade400 : Colors.grey[700],
                  ),
                ),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: Text(
                  l10n.delete,
                  style: const TextStyle(color: Colors.red),
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
            : typeColor.withOpacity(isDark ? 0.12 : 0.04),
        // Un seul signal fort pour le non-lu : un bandeau d'accent à gauche,
        // dans la couleur du type. Plus lisible que d'empiler teinte + bordure.
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        clipBehavior: Clip.antiAlias,
        child: Container(
          decoration: BoxDecoration(
            border: Border(
              left: BorderSide(
                color: isRead ? Colors.transparent : typeColor,
                width: 4,
              ),
            ),
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () async {
              // Le provider gère lui-même le repli hors ligne (marquage local
              // + rejeu au retour du réseau) : rien à distinguer ici.
              await provider.markAsRead(notification['id']);
              if (context.mounted) {
                onOpen();
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
                            fontWeight:
                                isRead ? FontWeight.normal : FontWeight.bold,
                            color: isDark ? Colors.white : Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          notification['message'],
                          style: TextStyle(
                            fontSize: 14,
                            color: isDark
                                ? Colors.grey.shade300
                                : Colors.grey[700],
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Text(
                              typeLabel,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: typeColor,
                              ),
                            ),
                            Text(
                              '  ·  ${_formatDate(notification['createdAt'], l10n)}',
                              style: TextStyle(
                                fontSize: 12,
                                color: isDark
                                    ? Colors.grey.shade500
                                    : Colors.grey[500],
                              ),
                            ),
                          ],
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
      ),
    );
  }

  /// Formate la date pour l'affichage (ex: "Il y a 5 min", "Il y a 2h", "dd/MM/yyyy").
  String _formatDate(DateTime date, AppLocalizations l10n) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inMinutes < 60) {
      return l10n.timeMinutesAgo(difference.inMinutes);
    } else if (difference.inHours < 24) {
      return l10n.timeHoursAgo(difference.inHours);
    } else if (difference.inDays < 7) {
      return l10n.timeDaysAgo(difference.inDays);
    } else {
      return DateFormat('dd/MM/yyyy').format(date);
    }
  }
}
