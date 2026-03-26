import '../models/user.dart';
import 'api_service.dart';
import 'storage_service.dart';

/// Service d'authentification gérant la connexion, l'inscription, la déconnexion
/// et la persistance des données utilisateur.
class AuthService {
  final ApiService _apiService = ApiService();
  final StorageService _storageService = StorageService();

  /// Authentifie un utilisateur avec son identifiant et son mot de passe.
  ///
  /// Retourne un objet [User] et sauvegarde le token ainsi que les informations
  /// utilisateur dans le stockage local.
  Future<User> login(String identifiant, String motDePasse) async {
    try {
      print('Tentative de connexion...');

      final response = await _apiService.post('/auth/login', body: {
        'identifiant': identifiant,
        'mot_de_passe': motDePasse,
      });

      final user = User.fromJson(response['user']);
      final token = response['token'] as String;

      await _storageService.saveToken(token);
      await _storageService.saveUser(user);

      print('Connexion reussie: ${user.nomComplet}');

      return user;
    } catch (e) {
      print('Erreur connexion: $e');
      rethrow;
    }
  }

  /// Inscrit un nouvel utilisateur.
  ///
  /// Retourne l'utilisateur créé et sauvegarde le token ainsi que les informations
  /// utilisateur dans le stockage local.
  Future<User> register({
    required String matricule,
    required String nom,
    required String prenom,
    required String email,
    String? telephone,
    required String motDePasse,
    required String confirmationMotDePasse,
  }) async {
    try {
      print('Tentative d\'inscription...');

      final response = await _apiService.post('/auth/register', body: {
        'matricule': matricule,
        'nom': nom,
        'prenom': prenom,
        'email': email,
        'telephone': telephone,
        'mot_de_passe': motDePasse,
        'confirmation_mot_de_passe': confirmationMotDePasse,
      });

      final user = User.fromJson(response['user']);
      final token = response['token'] as String;

      await _storageService.saveToken(token);
      await _storageService.saveUser(user);

      print('Inscription reussie: ${user.nomComplet}');

      return user;
    } catch (e) {
      print('Erreur inscription: $e');
      rethrow;
    }
  }

  /// Déconnecte l'utilisateur.
  ///
  /// Invalide le token côté serveur et efface toutes les données locales.
  Future<void> logout() async {
    try {
      print('Deconnexion...');

      try {
        await _apiService.post('/auth/logout');
      } catch (e) {
        print('Erreur logout API: $e');
      }

      await _storageService.clearAll();

      print('Deconnexion reussie');
    } catch (e) {
      print('Erreur deconnexion: $e');
      rethrow;
    }
  }

  /// Retourne l'utilisateur actuellement connecté depuis le stockage local.
  Future<User?> getCurrentUser() async {
    try {
      return await _storageService.getUser();
    } catch (e) {
      print('Erreur recuperation utilisateur: $e');
      return null;
    }
  }

  /// Vérifie si un utilisateur est authentifié (token présent).
  Future<bool> isAuthenticated() async {
    return await _storageService.isAuthenticated();
  }

  /// Rafraîchit les données de l'utilisateur depuis le serveur.
  Future<User> refreshUser() async {
    try {
      final response = await _apiService.get('/auth/me');
      final user = User.fromJson(response['user']);
      await _storageService.saveUser(user);
      return user;
    } catch (e) {
      print('Erreur refresh user: $e');
      rethrow;
    }
  }
}