import 'dart:convert';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'api_service.dart';
import 'storage_service.dart';
import 'navigation_service.dart';

/// Canal Android unique pour annonces & messages. DOIT correspondre au
/// `channelId` envoyé par le backend (notificationBroadcastService : 'annonces')
/// et être créé en importance HAUTE + son pour la bannière et le son système.
const AndroidNotificationChannel kAnnoncesChannel = AndroidNotificationChannel(
  'annonces',
  'Annonces & messages',
  description: 'Annonces et messages de l\'application CENOU',
  importance: Importance.high,
  playSound: true,
);

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

      // Crée le canal Android (importance haute + son) — indispensable pour la
      // bannière et le son, y compris quand l'app est fermée (Android 8+).
      await _localNotifications
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(kAnnoncesChannel);

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

  /// Gère les notifications reçues au premier plan : affiche une notification
  /// locale (FCM n'en affiche pas automatiquement quand l'app est ouverte).
  Future<void> _handleForegroundMessage(RemoteMessage message) async {
    print('Notification recue (foreground): ${message.notification?.title}');

    final notification = message.notification;
    if (notification == null) return;

    // Emporte les données de routage dans le payload pour le tap.
    final payload = jsonEncode({
      'type': message.data['type'],
      'annonce_id': message.data['annonce_id'],
      'notificationId': message.data['notificationId'],
    });

    await _localNotifications.show(
      id: notification.hashCode,
      title: notification.title,
      body: notification.body,
      notificationDetails: NotificationDetails(
        android: AndroidNotificationDetails(
          kAnnoncesChannel.id,
          kAnnoncesChannel.name,
          channelDescription: kAnnoncesChannel.description,
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
      payload: payload,
    );
  }

  /// Tap sur une notification système (app en arrière-plan ou fermée).
  void _handleBackgroundMessage(RemoteMessage message) {
    print('Notification ouverte (background): ${message.notification?.title}');
    _navigateToScreen(message.data['type'], annonceId: message.data['annonce_id']);
  }

  /// Tap sur une notification locale (app au premier plan).
  void _onNotificationTapped(NotificationResponse response) {
    print('Notification tappee: ${response.payload}');
    final raw = response.payload;
    if (raw == null || raw.isEmpty) return;
    try {
      final data = jsonDecode(raw) as Map<String, dynamic>;
      _navigateToScreen(data['type'] as String?, annonceId: data['annonce_id']?.toString());
    } catch (_) {
      _navigateToScreen(null);
    }
  }

  /// Navigue vers l'écran correspondant au type de notification, via la
  /// clé de navigation globale (aucun BuildContext requis).
  void _navigateToScreen(String? type, {String? annonceId}) {
    final nav = navigatorKey.currentState;
    if (nav == null) return;
    if (type == 'ANNONCE') {
      final id = int.tryParse(annonceId ?? '');
      if (id != null && id > 0) {
        nav.pushNamed('/annonce-details', arguments: id);
        return;
      }
    }
    // Par défaut : ouvre la liste des notifications de l'app.
    nav.pushNamed('/notifications');
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