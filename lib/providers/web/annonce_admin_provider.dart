// providers/web/annonce_admin_provider.dart
import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../../services/api_service.dart';
import '../../models/admin/annonce.dart';
import '../../models/admin/centre.dart';

/// Gestionnaire d'administration pour la diffusion et le suivi des annonces institutionnelles.
class AnnonceAdminProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();

  List<Annonce> _annonces = [];
  List<Centre> _centres = [];
  List<Map<String, dynamic>> _etudiants = [];
  bool _isLoading = false;
  bool _isSending = false;
  String? _error;

  // ==================== ACCESSEURS (GETTERS) ====================

  List<Annonce> get annonces => _annonces;
  List<Centre> get centres => _centres;
  List<Map<String, dynamic>> get etudiants => _etudiants;
  bool get isLoading => _isLoading;
  bool get isSending => _isSending;
  String? get error => _error;

  /// Charge l'ensemble des données nécessaires à l'interface d'administration.
  /// Récupère simultanément les annonces, les centres et le référentiel des étudiants.
  Future<void> loadData() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // 1. Récupération du flux des annonces existantes
      try {
        final annoncesResponse = await _apiService.get('/api/annonces/admin/all');
        _annonces = (annoncesResponse['data'] as List?)
            ?.map((json) => Annonce.fromJson(json))
            .toList() ?? [];
      } catch (e) {
        _annonces = [];
      }

      // 2. Récupération de la liste des centres pour la segmentation (filtres)
      try {
        final centresResponse = await _apiService.get('/api/centres');
        if (centresResponse.containsKey('data')) {
          final centresData = centresResponse['data'] as List?;
          _centres = (centresData ?? [])
              .map((json) => Centre.fromJson(json))
              .toList();
        } else {
          _centres = [];
        }
      } catch (e) {
        _centres = [];
      }

      // 3. Récupération du référentiel étudiant pour la sélection ciblée
      try {
        final etudiantsResponse = await _apiService.get('/api/users/admin/etudiants');
        _etudiants = (etudiantsResponse['data'] as List?)
            ?.map((user) {
          final userMap = user as Map<String, dynamic>;
          return {
            'id': userMap['id'] as int,
            'nom': '${userMap['prenom'] ?? ''} ${userMap['nom'] ?? ''}'.trim(),
            'matricule': userMap['matricule'] as String? ?? '',
            'centre': userMap['centre_nom'] as String? ?? 'Non affecté',
            'selected': false,
          };
        }).toList() ?? [];
      } catch (e) {
        _etudiants = [];
      }

    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Procède à l'émission d'une nouvelle annonce via les paramètres spécifiés.
  /// Gère l'injection conditionnelle des segments d'audience (centres, utilisateurs).
  Future<Map<String, dynamic>> sendAnnonce({
    required String titre,
    required String contenu,
    required String cible,
    int? centreId,
    List<int>? userIds,
    String statut = 'PUBLIE',
    DateTime? datePublication,
    DateTime? dateExpiration,
  }) async {
    _isSending = true;
    _error = null;
    notifyListeners();

    try {
      final body = <String, dynamic>{
        'titre': titre,
        'contenu': contenu,
        'cible': cible,
        'statut': statut,
      };

      /// Injection conditionnelle des paramètres d'audience et de planification.
      if (centreId != null) {
        body['centre_id'] = centreId;
      }

      if (userIds != null && userIds.isNotEmpty) {
        body['user_ids'] = userIds;
      }

      if (datePublication != null) {
        body['date_publication'] = datePublication.toIso8601String();
      }

      if (dateExpiration != null) {
        body['date_expiration'] = dateExpiration.toIso8601String();
      }

      /// Soumission vers le point de terminaison API.
      final response = await _apiService.post('/api/annonces/send', body: body);

      /// Actualisation synchronisée des données après confirmation du succès.
      await loadData();

      return response;
    } catch (e) {
      _error = e.toString();
      rethrow;
    } finally {
      _isSending = false;
      notifyListeners();
    }
  }

  /// Met à jour l'état de publication d'une annonce spécifique.
  /// Procède d'abord à la validation distante, puis répercute le changement localement.
  Future<void> updateStatut(int annonceId, String nouveauStatut) async {
    try {
      await _apiService.put('/api/annonces/$annonceId/statut', body: {
        'statut': nouveauStatut,
      });

      /// Répercussion locale pour la mise à jour immédiate de l'interface graphique.
      final index = _annonces.indexWhere((a) => a.id == annonceId);
      if (index != -1) {
        _annonces[index] = Annonce.fromJson({
          ..._annonces[index].toJson(),
          'statut': nouveauStatut,
        });
        notifyListeners();
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Supprime définitivement une annonce de la base de données.
  Future<void> deleteAnnonce(int annonceId) async {
    try {
      await _apiService.delete('/api/annonces/$annonceId');

      /// Mise à jour de l'état local après confirmation de la suppression distante.
      _annonces.removeWhere((a) => a.id == annonceId);
      notifyListeners();
    } catch (e) {
      rethrow;
    }
  }

  /// Déclenche un rafraîchissement complet du module d'annonces.
  Future<void> refresh() async {
    await loadData();
  }
}