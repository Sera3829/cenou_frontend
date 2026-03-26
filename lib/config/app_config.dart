import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class AppConfig {
  /// Détection de la plateforme d'exécution (Web vs Mobile).
  static bool get isWeb => kIsWeb;
  static bool get isMobile => !kIsWeb;

  /// Configuration des points d'entrée API selon l'environnement.
  static String get apiBaseUrl {
    if (kIsWeb) {
      // Configuration pour l'interface Web (Dashboard)
      return 'https://cenou-backend.onrender.com';
    } else {
      // Configuration pour l'application Mobile
      return 'https://cenou-backend.onrender.com';
    }
  }

  /// URL de base pour l'accès aux ressources statiques.
  static String get staticBaseUrl => apiBaseUrl;

  /// Informations générales de l'application.
  static const String appName = 'CENOU Dashboard';
  static const String appVersion = '1.0.0';

  /// Clés de stockage pour la persistance locale des données.
  static const String tokenKey = 'auth_token';
  static const String userKey = 'user_data';
  static const String fcmTokenKey = 'fcm_token';

  /// Paramètres de pagination par défaut.
  static const int itemsPerPage = 20;

  /// Configuration des contraintes de téléchargement d'images.
  static const int maxImageSize = 5 * 1024 * 1024; // Limite de 5 Mo
  static const int maxImagesPerSignalement = 5;

  /// Délais d'expiration des requêtes réseau (Timeouts).
  static const Duration connectionTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 30);

  /// État du mode de débogage.
  static const bool debugMode = true;
}