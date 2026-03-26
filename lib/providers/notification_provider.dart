import 'package:flutter/material.dart';
import '../services/notification_api_service.dart';
import '../services/storage_service.dart';
import '../services/connectivity_service.dart';

/// Gestionnaire d'état des notifications incluant la persistence locale et la synchronisation réseau.
class NotificationProvider with ChangeNotifier {
  final NotificationApiService _notificationApiService = NotificationApiService();
  final StorageService _storageService = StorageService();
  final ConnectivityService _connectivityService;

  List<Map<String, dynamic>> _notifications = [];
  bool _isLoading = false;
  String? _error;
  bool _isFromCache = false;

  // ==================== ACCESSEURS (GETTERS) ====================

  List<Map<String, dynamic>> get notifications => _notifications;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isFromCache => _isFromCache;

  /// Nombre de notifications dont l'état de lecture est faux.
  int get unreadCount => _notifications.where((n) => !n['read']).length;

  /// Nombre total de notifications chargées en mémoire.
  int get totalCount => _notifications.length;

  NotificationProvider(this._connectivityService);

  // ==================== LOGIQUE MÉTIER ====================

  /// Charge les notifications en privilégiant l'API si la connexion est active.
  /// En cas d'absence de réseau, bascule automatiquement sur le cache local.
  Future<void> loadNotifications({int limit = 50}) async {
    _isLoading = true;
    _error = null;
    _isFromCache = false;
    notifyListeners();

    try {
      final isOnline = _connectivityService.isOnline;

      if (isOnline) {
        // Récupération des données distantes
        final rawNotifications = await _notificationApiService.getNotifications(limit: limit);

        // Synchronisation avec l'état de lecture local
        final cachedNotifications = await _storageService.getNotificationsCache();

        if (cachedNotifications != null && cachedNotifications.isNotEmpty) {
          final restoredCache = _restoreNotificationsFromCache(cachedNotifications);

          _notifications = rawNotifications.map((apiNotif) {
            final cachedNotif = restoredCache.firstWhere(
                  (c) => c['id'] == apiNotif['id'],
              orElse: () => {},
            );

            if (cachedNotif.isNotEmpty) {
              return {
                ...apiNotif,
                'read': cachedNotif['read'] ?? apiNotif['read'],
              };
            }
            return apiNotif;
          }).toList();
        } else {
          _notifications = List<Map<String, dynamic>>.from(rawNotifications);
        }

        // Mise à jour de la persistance locale des annonces et notifications
        await _saveAllAnnoncesToCache();
        final cacheReadyNotifications = _convertNotificationsForCache(_notifications);
        await _storageService.saveNotificationsCache(cacheReadyNotifications);

        _isFromCache = false;
      } else {
        // Traitement du mode hors ligne via le cache persistant
        final cachedNotifications = await _storageService.getNotificationsCache();

        if (cachedNotifications != null && cachedNotifications.isNotEmpty) {
          _notifications = _restoreNotificationsFromCache(cachedNotifications);
          _isFromCache = true;
        } else {
          _notifications = [];
          _error = 'Données locales indisponibles. Une connexion internet est requise.';
        }
      }
    } catch (e) {
      _error = e.toString();

      // Tentative de récupération sur erreur réseau (Fallback)
      if (!_isFromCache) {
        final cachedNotifications = await _storageService.getNotificationsCache();
        if (cachedNotifications != null && cachedNotifications.isNotEmpty) {
          _notifications = _restoreNotificationsFromCache(cachedNotifications);
          _isFromCache = true;
          _error = 'Erreur réseau. Affichage des données en cache.';
        }
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Récupère les détails d'une annonce spécifique par son identifiant unique.
  Future<Map<String, dynamic>?> getAnnonceById(int annonceId) async {
    try {
      final isOnline = _connectivityService.isOnline;

      if (isOnline) {
        final annonce = await _notificationApiService.getAnnonceById(annonceId);
        if (annonce != null) {
          await _storageService.saveAnnonceCache(annonce);
          return annonce;
        } else {
          throw Exception('Ressource introuvable');
        }
      } else {
        final cachedAnnonce = await _storageService.getAnnonceFromCache(annonceId);
        if (cachedAnnonce != null) {
          return cachedAnnonce;
        } else {
          throw Exception('Ressource indisponible hors ligne');
        }
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Met en cache l'intégralité des annonces disponibles pour consultation hors ligne.
  Future<void> _saveAllAnnoncesToCache() async {
    try {
      final annonces = await _notificationApiService.getAnnonces();

      if (annonces.isEmpty) return;

      for (var annonceNotif in annonces) {
        try {
          final annonceId = annonceNotif['data']['annonce_id'] as int;
          final annonceDetails = await _notificationApiService.getAnnonceById(annonceId);

          if (annonceDetails != null) {
            await _storageService.saveAnnonceCache(annonceDetails);
          }
        } catch (e) {
          // Échec de mise en cache pour une unité atomique
        }
      }
    } catch (e) {
      // Erreur lors du processus de synchronisation globale
    }
  }

  /// Modifie l'état de lecture d'une notification dans le stockage local.
  Future<void> markAsReadLocally(dynamic notificationId) async {
    try {
      final index = _notifications.indexWhere((n) => n['id'] == notificationId);
      if (index != -1) {
        _notifications[index]['read'] = true;
        final cacheReady = _convertNotificationsForCache(_notifications);
        await _storageService.saveNotificationsCache(cacheReady);
        notifyListeners();
      }
    } catch (e) {
      // Erreur de mise à jour locale
    }
  }

  /// Marque l'ensemble des notifications comme lues dans le stockage local.
  Future<void> markAllAsReadLocally() async {
    try {
      for (var notification in _notifications) {
        notification['read'] = true;
      }
      final cacheReady = _convertNotificationsForCache(_notifications);
      await _storageService.saveNotificationsCache(cacheReady);
      notifyListeners();
    } catch (e) {
      // Erreur de mise à jour globale locale
    }
  }

  /// Prépare les objets de type [DateTime] pour la sérialisation JSON.
  List<Map<String, dynamic>> _convertNotificationsForCache(List<Map<String, dynamic>> notifications) {
    return notifications.map((notif) {
      final converted = Map<String, dynamic>.from(notif);

      if (converted['createdAt'] is DateTime) {
        converted['createdAt'] = (converted['createdAt'] as DateTime).toIso8601String();
      }

      if (converted['data'] is Map) {
        final data = Map<String, dynamic>.from(converted['data']);
        data.forEach((key, value) {
          if (value is DateTime) {
            data[key] = value.toIso8601String();
          }
        });
        converted['data'] = data;
      }

      return converted;
    }).toList();
  }

  /// Désérialise les dates et données structurées lors de la récupération du cache.
  List<Map<String, dynamic>> _restoreNotificationsFromCache(List<Map<String, dynamic>> cachedNotifications) {
    return cachedNotifications.map((notif) {
      final restored = Map<String, dynamic>.from(notif);

      if (restored['createdAt'] is String) {
        try {
          restored['createdAt'] = DateTime.parse(restored['createdAt'] as String);
        } catch (e) {
          restored['createdAt'] = DateTime.now();
        }
      }

      if (restored['data'] is Map) {
        final data = Map<String, dynamic>.from(restored['data']);
        data.forEach((key, value) {
          if (value is String) {
            try {
              final parsed = DateTime.tryParse(value);
              if (parsed != null) {
                data[key] = parsed;
              }
            } catch (_) {}
          }
        });
        restored['data'] = data;
      }

      return restored;
    }).toList();
  }

  /// Envoie une requête réseau pour marquer une notification comme lue.
  Future<bool> markAsRead(dynamic notificationId) async {
    if (!_connectivityService.isOnline) {
      _error = 'Une connexion internet est requise pour cette action.';
      notifyListeners();
      return false;
    }

    try {
      await _notificationApiService.markAsRead(notificationId);
      final index = _notifications.indexWhere((n) => n['id'] == notificationId);
      if (index != -1) {
        _notifications[index]['read'] = true;
        final cacheReady = _convertNotificationsForCache(_notifications);
        await _storageService.saveNotificationsCache(cacheReady);
        notifyListeners();
      }
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  /// Envoie une requête réseau pour marquer l'intégralité des notifications comme lues.
  Future<bool> markAllAsRead() async {
    if (!_connectivityService.isOnline) {
      _error = 'Une connexion internet est requise pour cette action.';
      notifyListeners();
      return false;
    }

    try {
      await _notificationApiService.markAllAsRead();
      for (var notification in _notifications) {
        notification['read'] = true;
      }
      final cacheReady = _convertNotificationsForCache(_notifications);
      await _storageService.saveNotificationsCache(cacheReady);
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  /// Supprime une notification de la base de données distante et du cache local.
  Future<bool> deleteNotification(dynamic notificationId) async {
    if (!_connectivityService.isOnline) {
      _error = 'Une connexion internet est requise pour supprimer cette ressource.';
      notifyListeners();
      return false;
    }

    try {
      await _notificationApiService.deleteNotification(notificationId);
      _notifications.removeWhere((n) => n['id'] == notificationId);
      final cacheReady = _convertNotificationsForCache(_notifications);
      await _storageService.saveNotificationsCache(cacheReady);
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  /// Récupère le compteur de notifications non lues en consultant les différents niveaux de cache.
  Future<int> getUnreadCount() async {
    try {
      if (_notifications.isNotEmpty) return unreadCount;

      final cachedNotifications = await _storageService.getNotificationsCache();
      if (cachedNotifications != null && cachedNotifications.isNotEmpty) {
        final restored = _restoreNotificationsFromCache(cachedNotifications);
        return restored.where((n) => !n['read']).length;
      }

      if (_connectivityService.isOnline) {
        try {
          return await _notificationApiService.getUnreadCount();
        } catch (e) {
          return 0;
        }
      }
      return 0;
    } catch (e) {
      return unreadCount;
    }
  }

  /// Déclenche un rafraîchissement complet des données.
  Future<void> refresh() async {
    await loadNotifications();
  }

  /// Force la synchronisation avec l'API en ignorant le cache initial.
  Future<void> forceRefreshFromApi() async {
    if (!_connectivityService.isOnline) {
      _error = 'Action impossible hors ligne.';
      notifyListeners();
      return;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final rawNotifications = await _notificationApiService.getNotifications(limit: 50);
      _notifications = List<Map<String, dynamic>>.from(rawNotifications);

      await _saveAllAnnoncesToCache();
      final cacheReady = _convertNotificationsForCache(_notifications);
      await _storageService.saveNotificationsCache(cacheReady);

      _isFromCache = false;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Vérifie la disponibilité des services en ligne.
  bool canPerformOnlineAction() {
    return _connectivityService.isOnline;
  }

  /// Réinitialise l'état d'erreur.
  void clearError() {
    _error = null;
    notifyListeners();
  }
}