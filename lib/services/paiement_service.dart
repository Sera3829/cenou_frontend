import '../models/paiement.dart';
import 'api_service.dart';

/// Service de gestion des paiements.
class PaiementService {
  final ApiService _apiService = ApiService();

  /// Récupère l'historique complet des paiements de l'utilisateur connecté.
  ///
  /// Retourne une liste d'objets [Paiement].
  Future<List<Paiement>> getPaiements() async {
    try {
      final response = await _apiService.get('/api/paiements');
      final List<dynamic> data = response['paiements'] as List<dynamic>;
      return data.map((json) => Paiement.fromJson(json)).toList();
    } catch (e) {
      print('Erreur getPaiements: $e');
      rethrow;
    }
  }

  /// Récupère le loyer mensuel de l'étudiant connecté.
  Future<Map<String, dynamic>> getLoyerInfo() async {
    try {
      final response = await _apiService.get('/api/paiements/loyer');
      return response['data'] as Map<String, dynamic>;
    } catch (e) {
      print('Erreur getLoyerInfo: $e');
      rethrow;
    }
  }

  /// Récupère la liste des paiements en attente de validation.
  ///
  /// Retourne une liste d'objets [Paiement] dont le statut est 'EN_ATTENTE'.
  Future<List<Paiement>> getPendingPaiements() async {
    try {
      final response = await _apiService.get('/api/paiements/pending');
      final List<dynamic> data = response['paiements_en_attente'] as List<dynamic>;
      return data.map((json) => Paiement.fromJson(json)).toList();
    } catch (e) {
      print('Erreur getPendingPaiements: $e');
      rethrow;
    }
  }

  /// Récupère un paiement spécifique par son identifiant.
  ///
  /// [id] : identifiant unique du paiement.
  Future<Paiement> getPaiementById(int id) async {
    try {
      final response = await _apiService.get('/api/paiements/$id');
      return Paiement.fromJson(response['paiement']);
    } catch (e) {
      print('Erreur getPaiementById: $e');
      rethrow;
    }
  }

  /// Initie une transaction de paiement.
  ///
  /// [montant] : montant à payer.
  /// [modePaiement] : mode de paiement (ORANGE_MONEY, MOOV_MONEY, etc.).
  /// [numeroTelephone] : numéro de téléphone associé au compte de paiement.
  Future<Map<String, dynamic>> initierPaiement({
    required double montant,
    required String modePaiement,
    required String numeroTelephone,
    required int nombreMois,
  }) async {
    try {
      final response = await _apiService.post('/api/paiements/initier', body: {
        'montant': montant,
        'mode_paiement': modePaiement,
        'numero_telephone': numeroTelephone,
        'nombre_mois': nombreMois,
      });
      return response;
    } catch (e) {
      print('Erreur initierPaiement: $e');
      rethrow;
    }
  }
}