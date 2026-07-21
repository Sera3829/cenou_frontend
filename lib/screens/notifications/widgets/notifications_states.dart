import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/notification_provider.dart';
import '../../../l10n/app_localizations.dart';

/// Liste de notifications vide.
class NotificationsEmptyState extends StatelessWidget {
  final bool isDark;
  final AppLocalizations l10n;

  const NotificationsEmptyState(
      {super.key, required this.isDark, required this.l10n});

  @override
  Widget build(BuildContext context) {
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
            l10n.noNotifications,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.grey.shade300 : Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            l10n.noNotificationsSub,
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
                child: Text(l10n.refresh),
              );
            },
          ),
        ],
      ),
    );
  }
}

/// Échec du chargement des notifications.
class NotificationsErrorState extends StatelessWidget {
  final NotificationProvider provider;
  final bool isDark;
  final AppLocalizations l10n;

  const NotificationsErrorState(
      {super.key,
      required this.provider,
      required this.isDark,
      required this.l10n});

  @override
  Widget build(BuildContext context) {
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
            l10n.loadingError,
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
              provider.error ?? l10n.cannotLoadNotifications,
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
            child: Text(l10n.retry),
          ),
        ],
      ),
    );
  }
}
