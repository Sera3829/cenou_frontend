import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';
import 'storage_service.dart';

/// Service centralisé pour les appels API et la gestion de l'authentification.
class ApiService {
  final StorageService _storageService = StorageService();
  String? _token;
  String? _refreshToken;

  /// Callback appelé automatiquement quand le token expire (401)
  Function()? onUnauthorized;

  /// Initialise le service en chargeant le jeton d'authentification depuis le stockage.
  Future<void> init() async {
    try {
      _token = await _storageService.getToken();
      print('Token charge: ${_token != null ? "OUI" : "NON"}');
    } catch (e) {
      print('Erreur initialisation ApiService: $e');
    }
  }

  // ==================== GESTION DES HEADERS ====================

  /// En-têtes par défaut pour les requêtes JSON.
  Map<String, String> get _defaultHeaders => {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };

  /// Génère les en-têtes d'authentification incluant le jeton Bearer.
  Future<Map<String, String>> _getAuthHeaders() async {
    // Toujours relire depuis le storage pour avoir le token le plus récent
    _token = await _storageService.getToken();

    final headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };

    if (_token != null && _token!.isNotEmpty) {
      headers['Authorization'] = 'Bearer $_token';
    }

    return headers;
  }

  /// Version synchrone des en-têtes, utilisée en interne.
  Map<String, String> _getHeaders() {
    final headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };

    if (_token != null && _token!.isNotEmpty) {
      headers['Authorization'] = 'Bearer $_token';
    }

    return headers;
  }

  /// Met à jour le jeton en mémoire et dans le stockage persistant.
  Future<void> setToken(String token) async {
    _token = token;
    await _storageService.saveToken(token);
    print('Token mis a jour');
  }

  /// Supprime le jeton d'authentification.
  Future<void> clearToken() async {
    _token = null;
    await _storageService.deleteToken();
    print('Token supprime');
  }

  // ==================== MÉTHODES HTTP GÉNÉRIQUES ====================

  /// Effectue une requête GET avec paramètres optionnels.
  Future<dynamic> get(String endpoint, {Map<String, String>? params}) async {
    try {
      Uri uri = Uri.parse('${AppConfig.apiBaseUrl}$endpoint');

      if (params != null && params.isNotEmpty) {
        uri = uri.replace(queryParameters: params);
      }

      final headers = await _getAuthHeaders();

      print('GET: $uri');

      final response = await http
          .get(uri, headers: headers)
          .timeout(AppConfig.connectionTimeout);

      return _handleResponse(response);
    } catch (e) {
      print('GET Error: $e');
      throw _handleError(e);
    }
  }

  /// Récupère la liste des utilisateurs pour l'administration avec filtres.
  Future<Map<String, dynamic>> getAdminUsers({
    String? role,
    String? statut,
    int? centreId,
    String? search,
    int? page,
    int? limit,
  }) async {
    final params = <String, String>{};
    if (role != null) params['role'] = role;
    if (statut != null) params['statut'] = statut;
    if (centreId != null) params['centre_id'] = centreId.toString();
    if (search != null) params['search'] = search;
    if (page != null) params['page'] = page.toString();
    if (limit != null) params['limit'] = limit.toString();

    final response = await get('/api/users/admin/all', params: params);
    return response as Map<String, dynamic>;
  }

  /// Met à jour le statut d'un utilisateur.
  Future<Map<String, dynamic>> updateUserStatus(int userId, String statut) async {
    final body = {'statut': statut};
    final response = await put(
      '/api/users/admin/$userId/statut',
      body: body,
    );
    return response as Map<String, dynamic>;
  }

  /// Met à jour les informations d'un utilisateur.
  Future<Map<String, dynamic>> updateUser(int userId, Map<String, dynamic> data) async {
    final response = await put(
      '/api/users/admin/$userId',
      body: data,
    );
    return response as Map<String, dynamic>;
  }

  /// Crée un nouvel utilisateur.
  Future<Map<String, dynamic>> createUser(Map<String, dynamic> data) async {
    final response = await post(
      '/api/users/admin/create',
      body: data,
    );
    return response as Map<String, dynamic>;
  }

  /// Supprime un utilisateur.
  Future<Map<String, dynamic>> deleteUser(int userId) async {
    final response = await delete('/api/users/admin/$userId');
    return response as Map<String, dynamic>;
  }

  /// Effectue une requête POST avec corps JSON.
  Future<dynamic> post(String endpoint, {Map<String, dynamic>? body}) async {
    try {
      final url = Uri.parse('${AppConfig.apiBaseUrl}$endpoint');
      final headers = await _getAuthHeaders();

      print('POST: $url');
      if (body != null) {
        print('Body: $body');
      }

      final response = await http.post(
        url,
        headers: headers,
        body: body != null ? json.encode(body) : null,
      ).timeout(AppConfig.connectionTimeout);

      print('Response Status: ${response.statusCode}');
      print('Content-Type: ${response.headers['content-type']}');

      /// Détection des réponses binaires (fichiers)
      final contentType = response.headers['content-type'] ?? '';
      if (contentType.contains('application/pdf') ||
          contentType.contains('application/vnd.ms-excel') ||
          contentType.contains('application/vnd.openxmlformats-officedocument.spreadsheetml.sheet') ||
          contentType.contains('application/octet-stream')) {
        print('Reponse binaire detectee, retour brut');
        return response;
      }

      return _handleResponse(response);
    } on TimeoutException catch (e) {
      print('Timeout: $e');
      throw Exception('Timeout: Le serveur ne repond pas');
    } catch (e) {
      // Détection des erreurs réseau (SocketException, ClientException, XMLHttpRequest)
      if (e.toString().contains('SocketException') ||
          e.toString().contains('ClientException') ||
          e.toString().contains('XMLHttpRequest')) {
        print('Network error: $e');
        throw Exception('Pas de connexion internet ou serveur inaccessible');
      }
      print('POST Error: $e');
      rethrow;
    }
  }

  /// Effectue une requête PUT avec corps JSON.
  Future<dynamic> put(String endpoint, {Map<String, dynamic>? body}) async {
    try {
      final url = Uri.parse('${AppConfig.apiBaseUrl}$endpoint');
      final headers = await _getAuthHeaders();

      print('PUT: $url');
      if (body != null) {
        print('Body: $body');
      }

      final response = await http.put(
        url,
        headers: headers,
        body: body != null ? json.encode(body) : null,
      ).timeout(AppConfig.connectionTimeout);

      return _handleResponse(response);
    } catch (e) {
      print('PUT Error: $e');
      throw _handleError(e);
    }
  }

  /// Effectue une requête DELETE.
  Future<dynamic> delete(String endpoint) async {
    try {
      final url = Uri.parse('${AppConfig.apiBaseUrl}$endpoint');
      final headers = await _getAuthHeaders();

      print('DELETE: $url');

      final response = await http
          .delete(url, headers: headers)
          .timeout(AppConfig.connectionTimeout);

      return _handleResponse(response);
    } catch (e) {
      print('DELETE Error: $e');
      throw _handleError(e);
    }
  }

  /// Effectue une requête multipart pour l'upload de fichiers.
  Future<dynamic> postMultipart(
      String endpoint, {
        required Map<String, String> fields,
        required List<http.MultipartFile> files,
      }) async {
    try {
      final url = Uri.parse('${AppConfig.apiBaseUrl}$endpoint');
      final token = await _storageService.getToken();

      print('POST Multipart: $url');
      print('Fields: $fields');
      print('Files: ${files.length}');

      final request = http.MultipartRequest('POST', url);

      if (token != null) {
        request.headers['Authorization'] = 'Bearer $token';
      }

      request.fields.addAll(fields);
      request.files.addAll(files);

      final streamedResponse =
      await request.send().timeout(AppConfig.connectionTimeout);
      final response = await http.Response.fromStream(streamedResponse);

      return _handleResponse(response);
    } catch (e) {
      print('Multipart Error: $e');
      throw _handleError(e);
    }
  }

  // ==================== MÉTHODES ADMIN SPÉCIFIQUES ====================

  /// Récupère l'activité récente pour le tableau de bord.
  Future<Map<String, dynamic>> getRecentActivity() async {
    final response = await get('/api/admin/dashboard/recent-activity');
    return response as Map<String, dynamic>;
  }

  /// Authentification administrateur.
  Future<Map<String, dynamic>> loginAdmin({
    required String identifiant,
    required String motDePasse,
  }) async {
    try {
      print('Debut loginAdmin');

      final response = await login(
        identifiant: identifiant,
        motDePasse: motDePasse,
        requireAdmin: true,
      );

      print('Admin login reussi: ${response['user']['role']}');
      return response;
    } catch (e) {
      print('Admin Login Error: $e');
      rethrow;
    }
  }

  /// Authentification générique avec option de vérification administrateur.
  Future<Map<String, dynamic>> login({
    required String identifiant,
    required String motDePasse,
    bool requireAdmin = false,
  }) async {
    try {
      final url = Uri.parse('${AppConfig.apiBaseUrl}/api/auth/login');

      print('LOGIN: $url');

      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'x-platform': kIsWeb ? 'web' : 'mobile',
        },
        body: json.encode({
          'identifiant': identifiant,
          'mot_de_passe': motDePasse,
        }),
      ).timeout(AppConfig.connectionTimeout);

      final result = _handleResponse(response);

      if (result['token'] != null) {
        await setToken(result['token']);
      }

      if (requireAdmin) {
        final userRole = result['user']['role'];
        if (!['ADMIN', 'GESTIONNAIRE'].contains(userRole)) {
          await clearToken();
          throw ApiException('Acces reserve aux administrateurs', 403);
        }
      }

      return result;
    } catch (e) {
      print('Login Error: $e');
      throw _handleError(e);
    }
  }

  /// Vérifie si l'utilisateur connecté est administrateur ou gestionnaire.
  Future<bool> isAdminUser() async {
    try {
      final token = await _storageService.getToken();
      if (token == null) return false;

      final response = await get('/api/auth/me');
      final result = response as Map<String, dynamic>;
      final userRole = result['user']['role'];
      return ['ADMIN', 'GESTIONNAIRE'].contains(userRole);
    } catch (e) {
      print('Check admin status error: $e');
      return false;
    }
  }

  /// Récupère les statistiques du tableau de bord.
  Future<Map<String, dynamic>> getDashboardStats() async {
    final response = await get('/api/admin/dashboard/stats');
    return response as Map<String, dynamic>;
  }

  /// Récupère les données des graphiques du tableau de bord.
  Future<Map<String, dynamic>> getDashboardCharts(
      {String? period, int? centreId}) async {
    final params = <String, String>{};
    if (period != null) params['period'] = period;
    if (centreId != null) params['centre_id'] = centreId.toString();

    final response = await get('/api/admin/dashboard/charts', params: params);
    return response as Map<String, dynamic>;
  }

  /// Récupère la liste des paiements pour l'administration.
  Future<Map<String, dynamic>> getAdminPaiements({
    int? page,
    int? limit,
    String? statut,
    String? modePaiement,
    String? dateFrom,
    String? dateTo,
    int? centreId,
    String? search,
  }) async {
    final params = <String, String>{};
    if (page != null) params['page'] = page.toString();
    if (limit != null) params['limit'] = limit.toString();
    if (statut != null) params['statut'] = statut;
    if (modePaiement != null) params['mode_paiement'] = modePaiement;
    if (dateFrom != null) params['date_from'] = dateFrom;
    if (dateTo != null) params['date_to'] = dateTo;
    if (centreId != null) params['centre_id'] = centreId.toString();
    if (search != null) params['search'] = search;

    final response = await get('/api/paiements/admin/all', params: params);
    return response as Map<String, dynamic>;
  }

  /// Met à jour le statut d'un paiement.
  Future<Map<String, dynamic>> updatePaiementStatus(
      int paiementId, String statut,
      {String? raison}) async {
    final body = {
      'statut': statut,
      if (raison != null) 'raison': raison,
    };

    final response = await put(
      '/api/paiements/admin/$paiementId/statut',
      body: body,
    );
    return response as Map<String, dynamic>;
  }

  /// Récupère les statistiques des paiements.
  Future<Map<String, dynamic>> getPaiementStatistics() async {
    final response = await get('/api/paiements/admin/statistics');
    return response as Map<String, dynamic>;
  }

  /// Récupère la liste des signalements pour l'administration.
  Future<Map<String, dynamic>> getAdminSignalements({
    String? statut,
    String? type,
    int? centreId,
    String? dateFrom,
    String? dateTo,
    String? search,
    int? page,
    int? limit,
  }) async {
    final params = <String, String>{};
    if (statut != null) params['statut'] = statut;
    if (type != null) params['type'] = type;
    if (centreId != null) params['centre_id'] = centreId.toString();
    if (dateFrom != null) params['date_from'] = dateFrom;
    if (dateTo != null) params['date_to'] = dateTo;
    if (search != null) params['search'] = search;
    if (page != null) params['page'] = page.toString();
    if (limit != null) params['limit'] = limit.toString();

    final response = await get('/api/signalements/admin/all', params: params);
    return response as Map<String, dynamic>;
  }

  /// Met à jour le statut d'un signalement.
  Future<Map<String, dynamic>> updateSignalementStatus(
      int signalementId, String statut,
      {String? commentaire}) async {
    final Map<String, dynamic> bodyData = {
      'statut': statut,
      if (commentaire != null) 'commentaire_resolution': commentaire,
    };

    print('Body avant envoi: $bodyData');

    final response = await put(
      '/api/signalements/admin/$signalementId/statut',
      body: bodyData,
    );

    print('Reponse API: $response');
    return response as Map<String, dynamic>;
  }

  /// Récupère le rapport financier.
  Future<Map<String, dynamic>> getFinancialReport({
    String? dateFrom,
    String? dateTo,
    int? centreId,
    String? statut = 'CONFIRME',
  }) async {
    final params = <String, String>{
      'statut': statut!,
    };
    if (dateFrom != null) params['date_from'] = dateFrom;
    if (dateTo != null) params['date_to'] = dateTo;
    if (centreId != null) params['centre_id'] = centreId.toString();

    final response = await get('/api/admin/reports/financial', params: params);
    return response as Map<String, dynamic>;
  }

  // ==================== GESTION DES RÉPONSES ====================

  /// Traite la réponse HTTP et convertit en objet Dart.
  dynamic _handleResponse(http.Response response) {
    print('Response Status: ${response.statusCode}');
    print('Response Body: ${response.body}');

    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (response.body.isEmpty) return {};
      try {
        return json.decode(response.body);
      } catch (e) {
        print("Avertissement: Reponse non JSON recue pour un statut 2xx");
        return {"data": response.body};
      }
    } else {
      String errorMessage = 'Une erreur est survenue';
      try {
        if (response.body.isNotEmpty) {
          final errorData = json.decode(response.body);
          errorMessage = errorData['error'] ??
              errorData['message'] ??
              'Une erreur est survenue';
        }
      } catch (_) {
        errorMessage = response.body.isNotEmpty
            ? response.body
            : 'Erreur HTTP ${response.statusCode}';
      }

      print('Backend error message: "$errorMessage"');

      final uri = response.request?.url.toString() ?? '';

      if (response.statusCode == 401) {
        //Déclencher la déconnexion automatique
        print('Token expiré détecté → déconnexion automatique');
        onUnauthorized?.call();

        if (uri.contains('/api/auth/login')) {
          throw ApiException(errorMessage, 401);
        } else {
          throw ApiException('Session expirée. Veuillez vous reconnecter.', 401);
        }
      } else if (response.statusCode == 403) {
        throw ApiException(errorMessage.isNotEmpty ? errorMessage : 'Accès refusé', 403);
      } else if (response.statusCode == 404) {
        throw ApiException(errorMessage.isNotEmpty ? errorMessage : 'Ressource introuvable', 404);
      } else if (response.statusCode >= 500) {
        throw ApiException('Erreur serveur. Veuillez réessayer plus tard.', 500);
      } else {
        throw ApiException(errorMessage, response.statusCode);
      }
    }
  }

  /// Convertit les exceptions techniques en ApiException.
  Exception _handleError(dynamic error) {
    if (error is ApiException) {
      return error;
    } else if (error.toString().contains('SocketException') || error.toString().contains('ClientException')) {
      return ApiException('Pas de connexion internet ou serveur inaccessible', 0);
    } else if (error.toString().contains('TimeoutException')) {
      return ApiException('Délai d\'attente dépassé. Veuillez réessayer.', 0);
    } else {
      return ApiException('Erreur inattendue: ${error.toString()}', 0);
    }
  }
}

/// Exception spécifique aux erreurs retournées par l'API.
class ApiException implements Exception {
  final String message;
  final int statusCode;

  ApiException(this.message, this.statusCode);

  @override
  String toString() => message;
}