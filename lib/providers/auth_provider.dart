import 'package:flutter/material.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import '../services/api_service.dart';
import '../services/storage_service.dart';
import '../models/user.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/foundation.dart' show kIsWeb, defaultTargetPlatform, TargetPlatform;

/// Gère l'état d'authentification, le profil utilisateur et les préférences de l'application.
class AuthProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();
  final StorageService _storageService = StorageService();

  bool _isLoading = false;
  bool _isAuthenticated = false;
  Map<String, dynamic>? _currentUser;
  String? _errorMessage;
  bool _isNotifying = false;

  /// Paramètres de configuration utilisateur.
  bool _notificationsEnabled = true;
  String _preferredLanguage = 'fr';
  String _preferredTheme = 'system';
  String? _sessionId;

  AuthProvider() {
    _apiService.onUnauthorized = () {
      _forceLogout();
    };
  }

  /// Déconnexion forcée silencieuse (token expiré)
  Future<void> _forceLogout() async {
    // Éviter de déclencher plusieurs fois simultanément
    if (!_isAuthenticated && _currentUser == null) return;

    print('Déconnexion automatique - token expiré');

    _currentUser = null;
    _isAuthenticated = false;
    _errorMessage = null;
    _notificationsEnabled = true;
    _preferredLanguage = 'fr';
    _preferredTheme = 'system';
    _sessionId = null;

    await _storageService.clearAll();

    _safeNotify();
  }

  // ==================== ACCESSEURS (GETTERS) ====================

  bool get isLoading => _isLoading;
  bool get isAuthenticated => _isAuthenticated;
  Map<String, dynamic>? get currentUser => _currentUser;
  String? get errorMessage => _errorMessage;

  /// Retourne l'instance de l'utilisateur actuel.
  User? get user {
    if (_currentUser == null) return null;
    return User.fromJson(_currentUser!);
  }

  /// Retourne l'identité complète (Prénom Nom).
  String get userFullName {
    if (_currentUser == null) return '';
    return '${_currentUser!['prenom']} ${_currentUser!['nom']}';
  }

  /// Retourne le rôle affecté à l'utilisateur.
  String get userRole => _currentUser?['role'] ?? '';

  bool get isAdmin => userRole == 'ADMIN';
  bool get isGestionnaire => userRole == 'GESTIONNAIRE';
  bool get isEtudiant => userRole == 'ETUDIANT';
  bool get isAdminUser => isAdmin || isGestionnaire;
  bool get notificationsEnabled => _notificationsEnabled;
  String get preferredLanguage => _preferredLanguage;
  String get preferredTheme => _preferredTheme;
  String? get sessionId => _sessionId;

  // ==================== GESTION DES NOTIFICATIONS D'ÉTAT ====================

  /// Déclenche une mise à jour des écouteurs de manière sécurisée après le rendu de la frame.
  void _safeNotify() {
    if (!_isNotifying) {
      _isNotifying = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _isNotifying = false;
        notifyListeners();
      });
    }
  }

  // ==================== LOGIQUE D'AUTHENTIFICATION ====================

  /// Initialise le cycle d'authentification au démarrage de l'application.
  Future<void> initAuth() async {
    return checkAuthStatus();
  }

  /// Vérifie le statut d'authentification en consultant le stockage local et l'API.
  /// Implémente un mode dégradé (fallback) sur le cache en cas d'absence de réseau.
  Future<void> checkAuthStatus() async {
    try {
      _isLoading = true;
      _safeNotify();

      // 1. Vérification de la présence d'un jeton d'accès (Token)
      final token = await _storageService.getToken();
      if (token == null) {
        final cachedUser = await _storageService.getUser();
        if (cachedUser != null) {
          _currentUser = cachedUser.toJson();
          _isAuthenticated = false;
        } else {
          _isAuthenticated = false;
          _currentUser = null;
        }

        _isLoading = false;
        _safeNotify();
        return;
      }

      // 2. Validation du jeton auprès du service distant
      try {
        final response = await _apiService.get('/api/auth/me');
        _currentUser = response['user'];
        _isAuthenticated = true;
        await _storageService.saveUser(User.fromJson(_currentUser!));
      } catch (e) {
        // Si 401, token expiré ou session invalide → déconnexion forcée
        if (e.toString().contains('401') ||
            e.toString().contains('expiré') ||
            e.toString().contains('Session invalide')) {
          await _storageService.clearAll();
          _isAuthenticated = false;
          _currentUser = null;
        } else {
          // Fallback cache pour les erreurs réseau
          final cachedUser = await _storageService.getUser();
          if (cachedUser != null) {
            _currentUser = cachedUser.toJson();
            _isAuthenticated = true;
          }
        }
      }

    } catch (e) {
      try {
        final cachedUser = await _storageService.getUser();
        if (cachedUser != null) {
          _currentUser = cachedUser.toJson();
          _isAuthenticated = false;
        } else {
          _isAuthenticated = false;
          _currentUser = null;
        }
      } catch (cacheError) {
        _isAuthenticated = false;
        _currentUser = null;
      }
    } finally {
      _isLoading = false;
      _safeNotify();
    }
  }

  /// Actualise les données de l'utilisateur à partir du stockage local.
  Future<void> refreshUserFromCache() async {
    try {
      final cachedUser = await _storageService.getUser();
      if (cachedUser != null) {
        _currentUser = cachedUser.toJson();
        _safeNotify();
      }
    } catch (e) {
      // Erreur silencieuse lors de la récupération du cache
    }
  }

  /// Authentifie un utilisateur via ses identifiants.
  Future<bool> login(String identifiant, String motDePasse) async {
    bool success = false;

    try {
      _currentUser = null;
      _isAuthenticated = false;
      _isLoading = true;
      _errorMessage = null;
      _safeNotify();

      final response = await _apiService.login(
        identifiant: identifiant,
        motDePasse: motDePasse,
        requireAdmin: false,
      );

      final role = response['user']['role'];

      // Bloquer Admin/Gestionnaire sur mobile (double sécurité côté Flutter)
      if (!kIsWeb && (role == 'ADMIN' || role == 'GESTIONNAIRE')) {
        await _storageService.clearAll();
        _currentUser = null;
        _isAuthenticated = false;
        _errorMessage = 'Accès non autorisé sur mobile. Utilisez le dashboard web.';
        success = false;
        return success;
      }

      _currentUser = response['user'];
      _isAuthenticated = true;
      _errorMessage = null;

      await _storageService.saveUser(User.fromJson(_currentUser!));
      await _registerFCMToken();

      success = true;
    } catch (e) {
      _errorMessage = _getErrorMessage(e);
      _isAuthenticated = false;
      _currentUser = null;
      success = false;
    } finally {
      _isLoading = false;
      _safeNotify();
    }

    return success;
  }

  /// Enregistre le jeton Firebase Cloud Messaging pour les notifications push.
  Future<void> _registerFCMToken() async {
    try {
      if (_currentUser == null || _currentUser!['id'] == null) return;

      final fcmToken = await FirebaseMessaging.instance.getToken();
      if (fcmToken == null || fcmToken.isEmpty) return;

      await _apiService.post(
        '/api/notifications/register-token',
        body: {
          'fcm_token': fcmToken,
          'device_type': kIsWeb ? 'web' : (defaultTargetPlatform == TargetPlatform.android ? 'android' : 'ios'),
        },
      );
    } catch (e) {
      // Échec de l'enregistrement du token push
    }
  }

  /// Authentifie un administrateur ou un gestionnaire.
  Future<bool> loginAdmin({
    required String identifiant,
    required String motDePasse,
  }) async {
    bool success = false;

    try {
      _isLoading = true;
      _errorMessage = null;
      _safeNotify();

      final response = await _apiService.loginAdmin(
        identifiant: identifiant,
        motDePasse: motDePasse,
      );

      _currentUser = response['user'];
      _isAuthenticated = true;
      _errorMessage = null;

      await _storageService.saveUser(User.fromJson(_currentUser!));
      success = true;
    } catch (e) {
      _errorMessage = _getErrorMessage(e);
      _isAuthenticated = false;
      _currentUser = null;
      success = false;
    } finally {
      _isLoading = false;
      _safeNotify();
    }

    return success;
  }

  /// Procède à l'inscription d'un nouvel étudiant.
  Future<void> register({
    required String matricule,
    required String nom,
    required String prenom,
    required String email,
    String? telephone,
    required String motDePasse,
    required String confirmationMotDePasse,
  }) async {
    try {
      _isLoading = true;
      _safeNotify();

      final response = await _apiService.post('/api/auth/register', body: {
        'matricule': matricule,
        'nom': nom,
        'prenom': prenom,
        'email': email,
        'telephone': telephone,
        'mot_de_passe': motDePasse,
        'confirmation_mot_de_passe': confirmationMotDePasse,
      });

      await _storageService.saveToken(response['token']);
      _currentUser = response['user'];
      _isAuthenticated = true;

      await _storageService.saveUser(User.fromJson(_currentUser!));
      await _registerFCMToken();
    } catch (e) {
      _errorMessage = e.toString();
      rethrow;
    } finally {
      _isLoading = false;
      _safeNotify();
    }
  }

  /// Actualise le profil utilisateur actuel.
  Future<void> refreshUser() async {
    return checkAuthStatus();
  }

  /// Déconnecte l'utilisateur et réinitialise les données persistantes.
  Future<void> logout() async {
    try {
      // Vider IMMÉDIATEMENT la mémoire avant tout appel réseau
      _currentUser = null;
      _isAuthenticated = false;
      _isLoading = true;
      _errorMessage = null;
      _notificationsEnabled = true;
      _preferredLanguage = 'fr';
      _preferredTheme = 'system';
      _sessionId = null;
      _safeNotify(); // L'UI se vide immédiatement

      // Appels réseau et storage ensuite (en arrière-plan)
      try {
        await _apiService.post('/api/auth/logout', body: {});
      } catch (e) {
        // Ignoré si indisponible
      }

      await _storageService.clearAll();

    } catch (e) {
      _errorMessage = 'Erreur lors de la déconnexion';
    } finally {
      _isLoading = false;
      _safeNotify();
    }
  }

  /// Modifie le mot de passe de l'utilisateur.
  Future<bool> changePassword({
    required String ancienMotDePasse,
    required String nouveauMotDePasse,
    required String confirmationNouveauMotDePasse,
  }) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      _safeNotify();

      await _apiService.put('/api/users/change-password', body: {
        'ancien_mot_de_passe': ancienMotDePasse,
        'nouveau_mot_de_passe': nouveauMotDePasse,
        'confirmation_nouveau_mot_de_passe': confirmationNouveauMotDePasse,
      });

      _errorMessage = null;
      return true;
    } catch (e) {
      final errorStr = e.toString();
      if (errorStr.contains('incorrect')) {
        _errorMessage = 'L\'ancien mot de passe est incorrect';
      } else if (errorStr.contains('ne correspondent pas')) {
        _errorMessage = 'Les mots de passe ne correspondent pas';
      } else if (errorStr.contains('validation')) {
        _errorMessage = 'Le nouveau mot de passe ne respecte pas les exigences de sécurité';
      } else {
        _errorMessage = 'Erreur lors du changement de mot de passe';
      }
      return false;
    } finally {
      _isLoading = false;
      _safeNotify();
    }
  }

  /// Met à jour les informations de profil de l'utilisateur.
  Future<bool> updateProfile({
    required String email,
    String? telephone,
  }) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      _safeNotify();

      final Map<String, dynamic> body = {'email': email};
      if (telephone != null && telephone.isNotEmpty) {
        body['telephone'] = telephone;
      }

      final response = await _apiService.put('/api/users/profile', body: body);

      if (response['user'] != null) {
        _currentUser = response['user'];
        await _storageService.saveUser(User.fromJson(_currentUser!));
      }

      _errorMessage = null;
      _safeNotify();
      return true;
    } catch (e) {
      final errorStr = e.toString();
      if (errorStr.contains('409')) {
        _errorMessage = 'Cet email est déjà utilisé par un autre utilisateur';
      } else if (errorStr.contains('400')) {
        _errorMessage = 'Les données fournies sont invalides';
      } else {
        _errorMessage = 'Erreur lors de la mise à jour du profil';
      }
      return false;
    } finally {
      _isLoading = false;
      _safeNotify();
    }
  }

  /// Réinitialise le message d'erreur actuel.
  void clearError() {
    _errorMessage = null;
    _safeNotify();
  }

  /// Met à jour la préférence pour les notifications.
  Future<void> updateNotificationPref(bool enabled) async {
    _notificationsEnabled = enabled;
    _safeNotify();
  }

  /// Met à jour la langue préférée de l'interface.
  Future<void> updateLanguage(String language) async {
    _preferredLanguage = language;
    _safeNotify();
  }

  /// Met à jour la préférence thématique.
  Future<void> updateTheme(String theme) async {
    _preferredTheme = theme;
    _safeNotify();
  }

  /// Génère un identifiant de session unique pour le suivi d'activité.
  void generateSessionId() {
    _sessionId = DateTime.now().millisecondsSinceEpoch.toString() +
        (user?.id?.toString() ?? '');
  }

  /// Traduit les exceptions techniques en messages compréhensibles par l'utilisateur final.
  String _getErrorMessage(dynamic error) {
    final errorStr = error.toString();

    if (errorStr.contains('409') || errorStr.contains('session est déjà active')) {
      return 'Une session est déjà active pour ce compte. Déconnectez-vous d\'abord sur l\'autre appareil.';
    } else if (errorStr.contains('désactivé') || errorStr.contains('suspendu')) {
      return 'Votre compte a été suspendu. Veuillez contacter l\'administration.';
    } else if (errorStr.contains('403')) {
      return 'Accès refusé. Vérifiez vos autorisations.';
    } else if (errorStr.contains('401') || errorStr.contains('incorrect')) {
      return 'Identifiant ou mot de passe incorrect.';
    } else if (errorStr.contains('SocketException') || errorStr.contains('ClientException')) {
      return 'Connexion au serveur impossible. Vérifiez votre accès internet.';
    } else if (errorStr.contains('Timeout')) {
      return 'Le délai de connexion a expiré. Veuillez réessayer.';
    }

    return errorStr.replaceAll('Exception:', '').trim();
  }
}