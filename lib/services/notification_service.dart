import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'api_service.dart';
import 'storage_service.dart';

/// Service de gestion des notifications push et locales.
class NotificationService {
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();
  final ApiService _apiService = ApiService();
  final StorageService _storageService = StorageService();

  /// Initialise le service de notifications.
  Future<void> initialize() async {
    try {
      print('========================================');
      print('INITIALISATION DU SERVICE NOTIFICATIONS');
      print('========================================');

      // Demander la permission
      final settings = await _firebaseMessaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );

      print('Statut permission: ${settings.authorizationStatus}');

      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        print('Permission notifications accordee');
      } else if (settings.authorizationStatus == AuthorizationStatus.denied) {
        print('Permission notifications refusee');
        return;
      } else {
        print('Permission notifications: ${settings.authorizationStatus}');
        return;
      }

      // Initialiser les notifications locales
      const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
      const iosSettings = DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );

      const initSettings = InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      );

      await _localNotifications.initialize(
        settings: initSettings,
        onDidReceiveNotificationResponse: _onNotificationTapped,
      );

      print('Notifications locales initialisees');

      // Récupérer le token FCM
      final token = await _firebaseMessaging.getToken();
      if (token != null) {
        print('FCM Token obtenu: ${token.substring(0, 30)}...');
        await _saveFCMToken(token);
      } else {
        print('Impossible d\'obtenir le token FCM');
      }

      // Écouter les changements de token
      _firebaseMessaging.onTokenRefresh.listen((newToken) {
        print('Token FCM rafraichi');
        _saveFCMToken(newToken);
      });

      // Gérer les notifications quand l'app est ouverte
      FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

      // Gérer les notifications quand l'app est en arrière-plan
      FirebaseMessaging.onMessageOpenedApp.listen(_handleBackgroundMessage);

      // Vérifier si l'app a été ouverte depuis une notification
      final initialMessage = await _firebaseMessaging.getInitialMessage();
      if (initialMessage != null) {
        print('App ouverte depuis une notification');
        _handleBackgroundMessage(initialMessage);
      }

      print('========================================');
      print('SERVICE DE NOTIFICATIONS PRET');
      print('========================================');
    } catch (e, stackTrace) {
      print('========================================');
      print('ERREUR INITIALISATION NOTIFICATIONS');
      print('Erreur: $e');
      print('Stack: $stackTrace');
      print('========================================');
    }
  }

  /// Sauvegarde le token FCM sur le serveur.
  Future<void> _saveFCMToken(String token) async {
    try {
      await _storageService.saveFcmToken(token);

      // Envoyer au serveur
      await _apiService.post('/api/notifications/register-token', body: {
        'fcm_token': token,
        'device_type': 'android',
      });

      print('Token FCM enregistre sur le serveur');
    } catch (e) {
      print('Erreur sauvegarde token FCM: $e');
    }
  }

  /// Gère les notifications reçues au premier plan.
  Future<void> _handleForegroundMessage(RemoteMessage message) async {
    print('Notification recue (foreground): ${message.notification?.title}');

    final notification = message.notification;

    if (notification != null) {
      await _localNotifications.show(
        id: notification.hashCode,
        title: notification.title,
        body: notification.body,
        notificationDetails: NotificationDetails(
          android: AndroidNotificationDetails(
            'cenou_channel',
            'CENOU Notifications',
            channelDescription: 'Notifications de l\'application CENOU',
            importance: Importance.high,
            priority: Priority.high,
            icon: '@mipmap/ic_launcher',
          ),
          iOS: const DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
        payload: message.data['notificationId'],
      );
    }
  }

  /// Gère les notifications ouvertes alors que l'application est en arrière-plan.
  void _handleBackgroundMessage(RemoteMessage message) {
    print('Notification ouverte (background): ${message.notification?.title}');

    final type = message.data['type'];
    final notificationId = message.data['notificationId'];

    if (type != null && notificationId != null) {
      _navigateToScreen(type, notificationId);
    }
  }

  /// Gère le tap sur la notification locale.
  void _onNotificationTapped(NotificationResponse response) {
    print('Notification tappee: ${response.payload}');

    if (response.payload != null) {
      // Navigation à implémenter selon le besoin
    }
  }

  /// Navigue vers l'écran correspondant au type de notification.
  void _navigateToScreen(String type, String id) {
    switch (type) {
      case 'PAIEMENT':
      // Navigation vers les détails du paiement
        break;
      case 'SIGNALEMENT':
      // Navigation vers les détails du signalement
        break;
      case 'ANNONCE':
      // Navigation vers les annonces
        break;
      default:
      // Navigation vers l'écran d'accueil
        break;
    }
  }

  /// Retourne le nombre de notifications non lues.
  Future<int> getUnreadCount() async {
    try {
      // À implémenter avec l'API
      return 0;
    } catch (e) {
      return 0;
    }
  }
}

/// Handler pour les notifications en arrière-plan (fonction top-level).
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  print('Notification en arriere-plan: ${message.notification?.title}');
}