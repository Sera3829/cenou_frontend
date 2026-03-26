import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/app_config.dart';
import '../models/user.dart';
import '../models/paiement.dart';
import '../models/signalement.dart';

/// Service de gestion du stockage local.
///
/// Utilise [FlutterSecureStorage] pour les données sensibles (token)
/// et [SharedPreferences] pour les préférences et caches.
class StorageService {
  // Stockage sécurisé (pour token)
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  // Stockage normal (pour préférences et cache)
  Future<SharedPreferences> get _prefs => SharedPreferences.getInstance();

  // ========== CLÉS DE CACHE ==========
  static const String _paiementsCacheKey = 'cached_paiements';
  static const String _signalementsCacheKey = 'cached_signalements';
  static const String _notificationsCacheKey = 'cached_notifications';
  static const String _paiementsCacheTimestampKey = 'cached_paiements_timestamp';
  static const String _signalementsCacheTimestampKey = 'cached_signalements_timestamp';
  static const String _notificationsCacheTimestampKey = 'cached_notifications_timestamp';
  static const String _annoncesCacheKey = 'cached_annonces';
  static const String _annoncesCacheTimestampKey = 'cached_annonces_timestamp';

  // Durée de validité du cache (1 heure)
  static const Duration _cacheDuration = Duration(hours: 1);

  /// Sauvegarde une annonce dans le cache.
  ///
  /// [annonce] : les données de l'annonce à stocker.
  Future<void> saveAnnonceCache(Map<String, dynamic> annonce) async {
    try {
      final prefs = await _prefs;
      final annonces = await getAnnoncesCache() ?? [];

      // Remplacer si existe, ajouter sinon
      final index = annonces.indexWhere((a) => a['id'] == annonce['id']);
      if (index != -1) {
        annonces[index] = annonce;
      } else {
        annonces.add(annonce);
      }
      final annoncesJson = jsonEncode(annonces);
      await prefs.setString(_annoncesCacheKey, annoncesJson);

      print('Annonce ${annonce['id']} sauvegardee en cache');
    } catch (e) {
      print('Erreur sauvegarde cache annonce: $e');
    }
  }

  /// Récupère toutes les annonces depuis le cache.
  Future<List<Map<String, dynamic>>?> getAnnoncesCache() async {
    try {
      final prefs = await _prefs;
      final annoncesJson = prefs.getString(_annoncesCacheKey);

      if (annoncesJson == null) return null;

      final List<dynamic> jsonList = jsonDecode(annoncesJson);
      return jsonList.map((json) => json as Map<String, dynamic>).toList();
    } catch (e) {
      print('Erreur lecture cache annonces: $e');
      return null;
    }
  }

  /// Récupère une annonce spécifique depuis le cache.
  ///
  /// [annonceId] : identifiant de l'annonce recherchée.
  Future<Map<String, dynamic>?> getAnnonceFromCache(int annonceId) async {
    try {
      final annonces = await getAnnoncesCache();
      if (annonces == null) return null;

      return annonces.firstWhere(
            (a) => a['id'] == annonceId,
        orElse: () => throw Exception(),
      );
    } catch (_) {
      return null;
    }
  }

  /// Supprime le cache des annonces.
  Future<void> deleteAnnoncesCache() async {
    try {
      final prefs = await _prefs;
      await prefs.remove(_annoncesCacheKey);
      await prefs.remove(_annoncesCacheTimestampKey);
      print('Cache annonces supprime');
    } catch (e) {
      print('Erreur suppression cache annonces: $e');
    }
  }

  // ========== TOKEN ==========

  /// Sauvegarde le token d'authentification.
  Future<void> saveToken(String token) async {
    try {
      await _secureStorage.write(key: AppConfig.tokenKey, value: token);
      print('Token sauvegarde');
    } catch (e) {
      print('Erreur sauvegarde token: $e');
    }
  }

  /// Récupère le token d'authentification.
  Future<String?> getToken() async {
    try {
      return await _secureStorage.read(key: AppConfig.tokenKey);
    } catch (e) {
      print('Erreur lecture token: $e');
      return null;
    }
  }

  /// Supprime le token d'authentification.
  Future<void> deleteToken() async {
    try {
      await _secureStorage.delete(key: AppConfig.tokenKey);
      print('Token supprime');
    } catch (e) {
      print('Erreur suppression token: $e');
    }
  }

  // ========== USER DATA ==========

  /// Sauvegarde les données de l'utilisateur connecté.
  Future<void> saveUser(User user) async {
    try {
      final prefs = await _prefs;
      final userJson = jsonEncode(user.toJson());
      await prefs.setString(AppConfig.userKey, userJson);
      print('Utilisateur sauvegarde');
    } catch (e) {
      print('Erreur sauvegarde utilisateur: $e');
    }
  }

  /// Récupère les données de l'utilisateur connecté.
  Future<User?> getUser() async {
    try {
      final prefs = await _prefs;
      final userJson = prefs.getString(AppConfig.userKey);
      if (userJson != null) {
        return User.fromJson(jsonDecode(userJson));
      }
      return null;
    } catch (e) {
      print('Erreur lecture utilisateur: $e');
      return null;
    }
  }

  /// Supprime les données de l'utilisateur connecté.
  Future<void> deleteUser() async {
    try {
      final prefs = await _prefs;
      await prefs.remove(AppConfig.userKey);
      print('Utilisateur supprime');
    } catch (e) {
      print('Erreur suppression utilisateur: $e');
    }
  }

  // ========== FCM TOKEN ==========

  /// Sauvegarde le token FCM.
  Future<void> saveFcmToken(String token) async {
    try {
      final prefs = await _prefs;
      await prefs.setString(AppConfig.fcmTokenKey, token);
      print('Token FCM sauvegarde');
    } catch (e) {
      print('Erreur sauvegarde token FCM: $e');
    }
  }

  /// Récupère le token FCM.
  Future<String?> getFcmToken() async {
    try {
      final prefs = await _prefs;
      return prefs.getString(AppConfig.fcmTokenKey);
    } catch (e) {
      print('Erreur lecture token FCM: $e');
      return null;
    }
  }

  // ========== CACHE PAIEMENTS ==========

  /// Sauvegarde la liste des paiements en cache.
  Future<void> savePaiementsCache(List<Paiement> paiements) async {
    try {
      final prefs = await _prefs;
      final paiementsJson = jsonEncode(paiements.map((p) => p.toJson()).toList());
      await prefs.setString(_paiementsCacheKey, paiementsJson);

      // Sauvegarder le timestamp
      await prefs.setInt(_paiementsCacheTimestampKey, DateTime.now().millisecondsSinceEpoch);

      print('Cache paiements sauvegarde: ${paiements.length} paiement(s)');
    } catch (e) {
      print('Erreur sauvegarde cache paiements: $e');
    }
  }

  /// Récupère la liste des paiements depuis le cache.
  Future<List<Paiement>?> getPaiementsCache() async {
    try {
      final prefs = await _prefs;
      final paiementsJson = prefs.getString(_paiementsCacheKey);

      if (paiementsJson == null) {
        print('Aucun cache paiements trouve');
        return null;
      }

      // Vérifier si le cache est encore valide
      final timestamp = prefs.getInt(_paiementsCacheTimestampKey);
      if (timestamp != null) {
        final cacheDate = DateTime.fromMillisecondsSinceEpoch(timestamp);
        final now = DateTime.now();

        if (now.difference(cacheDate) > _cacheDuration) {
          print('Cache paiements expire (${now.difference(cacheDate).inMinutes} minutes)');
          return null;
        }
      }

      final List<dynamic> jsonList = jsonDecode(paiementsJson);
      final paiements = jsonList.map((json) => Paiement.fromJson(json)).toList();

      print('Cache paiements charge: ${paiements.length} paiement(s)');
      return paiements;
    } catch (e) {
      print('Erreur lecture cache paiements: $e');
      return null;
    }
  }

  /// Supprime le cache des paiements.
  Future<void> deletePaiementsCache() async {
    try {
      final prefs = await _prefs;
      await prefs.remove(_paiementsCacheKey);
      await prefs.remove(_paiementsCacheTimestampKey);
      print('Cache paiements supprime');
    } catch (e) {
      print('Erreur suppression cache paiements: $e');
    }
  }

  // ========== CACHE SIGNALEMENTS ==========

  /// Sauvegarde la liste des signalements en cache.
  Future<void> saveSignalementsCache(List<Signalement> signalements) async {
    try {
      final prefs = await _prefs;
      final signalementsJson = jsonEncode(signalements.map((s) => s.toJson()).toList());
      await prefs.setString(_signalementsCacheKey, signalementsJson);

      // Sauvegarder le timestamp
      await prefs.setInt(_signalementsCacheTimestampKey, DateTime.now().millisecondsSinceEpoch);

      print('Cache signalements sauvegarde: ${signalements.length} signalement(s)');
    } catch (e) {
      print('Erreur sauvegarde cache signalements: $e');
    }
  }

  /// Récupère la liste des signalements depuis le cache.
  Future<List<Signalement>?> getSignalementsCache() async {
    try {
      final prefs = await _prefs;
      final signalementsJson = prefs.getString(_signalementsCacheKey);

      if (signalementsJson == null) {
        print('Aucun cache signalements trouve');
        return null;
      }

      // Vérifier si le cache est encore valide
      final timestamp = prefs.getInt(_signalementsCacheTimestampKey);
      if (timestamp != null) {
        final cacheDate = DateTime.fromMillisecondsSinceEpoch(timestamp);
        final now = DateTime.now();

        if (now.difference(cacheDate) > _cacheDuration) {
          print('Cache signalements expire (${now.difference(cacheDate).inMinutes} minutes)');
          return null;
        }
      }

      final List<dynamic> jsonList = jsonDecode(signalementsJson);
      final signalements = jsonList.map((json) => Signalement.fromJson(json)).toList();

      print('Cache signalements charge: ${signalements.length} signalement(s)');
      return signalements;
    } catch (e) {
      print('Erreur lecture cache signalements: $e');
      return null;
    }
  }

  /// Supprime le cache des signalements.
  Future<void> deleteSignalementsCache() async {
    try {
      final prefs = await _prefs;
      await prefs.remove(_signalementsCacheKey);
      await prefs.remove(_signalementsCacheTimestampKey);
      print('Cache signalements supprime');
    } catch (e) {
      print('Erreur suppression cache signalements: $e');
    }
  }

  // ========== CACHE NOTIFICATIONS ==========

  /// Sauvegarde la liste des notifications en cache.
  Future<void> saveNotificationsCache(List<Map<String, dynamic>> notifications) async {
    try {
      final prefs = await _prefs;
      final notificationsJson = jsonEncode(notifications);
      await prefs.setString(_notificationsCacheKey, notificationsJson);

      // Sauvegarder le timestamp
      await prefs.setInt(_notificationsCacheTimestampKey, DateTime.now().millisecondsSinceEpoch);

      print('Cache notifications sauvegarde: ${notifications.length} notification(s)');
    } catch (e) {
      print('Erreur sauvegarde cache notifications: $e');
    }
  }

  /// Récupère la liste des notifications depuis le cache.
  Future<List<Map<String, dynamic>>?> getNotificationsCache() async {
    try {
      final prefs = await _prefs;
      final notificationsJson = prefs.getString(_notificationsCacheKey);

      if (notificationsJson == null) {
        print('Aucun cache notifications trouve');
        return null;
      }

      // Vérifier si le cache est encore valide
      final timestamp = prefs.getInt(_notificationsCacheTimestampKey);
      if (timestamp != null) {
        final cacheDate = DateTime.fromMillisecondsSinceEpoch(timestamp);
        final now = DateTime.now();

        if (now.difference(cacheDate) > _cacheDuration) {
          print('Cache notifications expire (${now.difference(cacheDate).inMinutes} minutes)');
          return null;
        }
      }

      final List<dynamic> jsonList = jsonDecode(notificationsJson);
      final notifications = jsonList.map((json) => json as Map<String, dynamic>).toList();

      print('Cache notifications charge: ${notifications.length} notification(s)');
      return notifications;
    } catch (e) {
      print('Erreur lecture cache notifications: $e');
      return null;
    }
  }

  /// Supprime le cache des notifications.
  Future<void> deleteNotificationsCache() async {
    try {
      final prefs = await _prefs;
      await prefs.remove(_notificationsCacheKey);
      await prefs.remove(_notificationsCacheTimestampKey);
      print('Cache notifications supprime');
    } catch (e) {
      print('Erreur suppression cache notifications: $e');
    }
  }

  // ========== CLEAR ALL ==========

  /// Supprime toutes les données locales (déconnexion).
  Future<void> clearAll() async {
    try {
      await deleteToken();
      await deleteUser();
      await deletePaiementsCache();
      await deleteSignalementsCache();
      await deleteNotificationsCache();
      await deleteAnnoncesCache();
      print('Toutes les donnees supprimees (y compris caches)');
    } catch (e) {
      print('Erreur suppression donnees: $e');
    }
  }

  /// Retourne l'âge du cache des annonces en minutes.
  Future<int?> getAnnoncesCacheAge() async {
    try {
      final prefs = await _prefs;
      final timestamp = prefs.getInt(_annoncesCacheTimestampKey);
      if (timestamp == null) return null;

      final cacheDate = DateTime.fromMillisecondsSinceEpoch(timestamp);
      return DateTime.now().difference(cacheDate).inMinutes;
    } catch (e) {
      return null;
    }
  }

  // ========== CHECK AUTH ==========

  /// Vérifie si l'utilisateur est authentifié.
  Future<bool> isAuthenticated() async {
    final token = await getToken();
    return token != null && token.isNotEmpty;
  }

  // ========== HELPERS ==========

  /// Retourne l'âge du cache des paiements en minutes.
  Future<int?> getPaiementsCacheAge() async {
    try {
      final prefs = await _prefs;
      final timestamp = prefs.getInt(_paiementsCacheTimestampKey);
      if (timestamp == null) return null;

      final cacheDate = DateTime.fromMillisecondsSinceEpoch(timestamp);
      return DateTime.now().difference(cacheDate).inMinutes;
    } catch (e) {
      return null;
    }
  }

  /// Retourne l'âge du cache des signalements en minutes.
  Future<int?> getSignalementsCacheAge() async {
    try {
      final prefs = await _prefs;
      final timestamp = prefs.getInt(_signalementsCacheTimestampKey);
      if (timestamp == null) return null;

      final cacheDate = DateTime.fromMillisecondsSinceEpoch(timestamp);
      return DateTime.now().difference(cacheDate).inMinutes;
    } catch (e) {
      return null;
    }
  }

  /// Retourne l'âge du cache des notifications en minutes.
  Future<int?> getNotificationsCacheAge() async {
    try {
      final prefs = await _prefs;
      final timestamp = prefs.getInt(_notificationsCacheTimestampKey);
      if (timestamp == null) return null;

      final cacheDate = DateTime.fromMillisecondsSinceEpoch(timestamp);
      return DateTime.now().difference(cacheDate).inMinutes;
    } catch (e) {
      return null;
    }
  }
}