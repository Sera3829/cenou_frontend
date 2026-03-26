// lib/providers/web/paiement_admin_provider.dart
import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:cenou_mobile/models/paiement.dart';
import 'package:cenou_mobile/services/api_service.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart' show kIsWeb;

/// Importation conditionnelle pour les fonctionnalités spécifiques au Web.
import '../../utils/html_utils.dart';

/// Gestionnaire d'état pour l'administration des paiements sur l'interface Web.
class PaiementAdminProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();

  /// États internes de la collection et du cycle de vie.
  List<Paiement> _paiements = [];
  bool _isLoading = false;
  String? _error;
  Map<String, dynamic> _filters = {};
  Map<String, dynamic>? _statistiques;

  // ==================== ACCESSEURS (GETTERS) ====================

  List<Paiement> get paiements => _paiements;
  bool get isLoading => _isLoading;
  String? get error => _error;
  Map<String, dynamic>? get statistiques => _statistiques;
  Map<String, dynamic> get filters => _filters;
  ApiService get apiService => _apiService;

  /// Paramètres de pagination.
  int _currentPage = 1;
  int _totalPages = 1;
  int _totalItems = 0;

  int get currentPage => _currentPage;
  int get totalPages => _totalPages;
  int get totalItems => _totalItems;

  // ==================== MÉTHODES PRINCIPALES ====================

  /// Charge la liste des paiements en appliquant les filtres actifs.
  /// L'option [resetPage] permet de réinitialiser la pagination à la première page.
  Future<void> loadPaiements({bool resetPage = false}) async {
    try {
      setLoading(true);
      _error = null;

      if (resetPage) {
        _currentPage = 1;
      }

      /// Construction des paramètres de requête.
      Map<String, String> params = {
        'page': _currentPage.toString(),
        'limit': '20',
      };

      /// Application des filtres de recherche et de segmentation.
      if (_filters.isNotEmpty) {
        _filters.forEach((key, value) {
          if (value != null && value.toString().isNotEmpty) {
            params[key] = value.toString();
          }
        });
      }

      /// Appel au service API.
      final response = await _apiService.get('/api/paiements/admin/all', params: params);

      if (response['success'] == true) {
        final data = response['data'] as Map<String, dynamic>? ?? {};

        /// Désérialisation de la collection de paiements.
        final List<dynamic> paiementsData = data['paiements'] as List? ?? [];
        _paiements = paiementsData
            .map((json) => Paiement.fromJson(json))
            .toList()
            .cast<Paiement>();

        /// Mise à jour des métadonnées de pagination.
        final pagination = data['pagination'] as Map<String, dynamic>? ?? {};
        _totalItems = pagination['total'] ?? _paiements.length;
        _totalPages = pagination['pages'] ?? 1;
        _currentPage = pagination['page'] ?? 1;

        if (_totalPages == 0) _totalPages = 1;

        /// Chargement synchronisé des statistiques associées aux filtres actuels.
        final statsParams = Map<String, String>.from(params);
        statsParams.remove('page');
        statsParams.remove('limit');

        await loadStatistiques(params: statsParams);

        notifyListeners();
      } else {
        throw Exception(response['message'] ?? 'Erreur lors de la récupération des paiements');
      }
    } catch (e) {
      _error = e.toString();
      _paiements = [];
      notifyListeners();
      rethrow;
    } finally {
      setLoading(false);
    }
  }

  /// Calcule le ratio de réussite des transactions.
  double get tauxReussite {
    if (_statistiques == null || _statistiques!['total'] == 0) return 0.0;

    final total = _statistiques!['total'] ?? 0;
    final confirmes = _statistiques!['confirmes'] ?? 0;

    return (confirmes / total) * 100;
  }

  /// Effectue une recherche textuelle sur la collection de paiements.
  Future<void> searchPaiements(String query) async {
    _filters['search'] = query.isNotEmpty ? query : null;
    await loadPaiements(resetPage: true);
  }

  /// Applique un filtre unitaire et déclenche un rechargement.
  Future<void> applyFilter(String key, dynamic value) async {
    if (value == null || value.toString().isEmpty) {
      _filters.remove(key);
    } else {
      _filters[key] = value;
    }
    await loadPaiements(resetPage: true);
  }

  /// Réinitialise l'intégralité des filtres de recherche.
  Future<void> resetFilters() async {
    _filters.clear();
    await loadPaiements(resetPage: true);
  }

  /// Navigation vers la page suivante de la pagination.
  Future<void> loadNextPage() async {
    if (_currentPage < _totalPages) {
      _currentPage++;
      await loadPaiements();
    }
  }

  /// Navigation vers la page précédente de la pagination.
  Future<void> loadPreviousPage() async {
    if (_currentPage > 1) {
      _currentPage--;
      await loadPaiements();
    }
  }

  /// Met à jour le statut d'une transaction financière.
  /// Réalise une mise à jour optimiste de l'interface avant confirmation de l'API.
  Future<void> updateStatutPaiement({
    required String paiementId,
    required String nouveauStatut,
    String? raison,
  }) async {
    try {
      setLoading(true);

      /// Recherche de l'index de la ressource en mémoire locale.
      final oldPaiementIndex = _paiements.indexWhere((p) => p.id.toString() == paiementId);
      if (oldPaiementIndex == -1) {
        throw Exception('Ressource introuvable dans la collection actuelle');
      }

      final oldPaiement = _paiements[oldPaiementIndex];

      /// Mise à jour optimiste du statut pour assurer la fluidité de l'interface.
      _paiements[oldPaiementIndex] = oldPaiement.copyWith(
        statut: nouveauStatut,
        nom: oldPaiement.nom,
        prenom: oldPaiement.prenom,
        matricule: oldPaiement.matricule,
        centreNom: oldPaiement.centreNom,
        numeroChambre: oldPaiement.numeroChambre,
        montant: oldPaiement.montant,
      );

      notifyListeners();

      final int id = int.tryParse(paiementId) ?? 0;
      final body = {
        'statut': nouveauStatut,
        if (raison != null && raison.isNotEmpty) 'raison': raison,
      };

      /// Soumission de la modification au service distant.
      final response = await _apiService.put(
        '/api/paiements/admin/$id/statut',
        body: body,
      );

      if (response['success'] == true) {
        final updatedPaiementJson = response['data'] as Map<String, dynamic>;

        /// Fusion des données distantes avec l'état local pour maintenir l'intégrité du modèle.
        final updatedPaiement = Paiement.fromJson({
          ...oldPaiement.toJson(),
          ...updatedPaiementJson,
          'statut': nouveauStatut,
          'nom': updatedPaiementJson['nom'] ?? oldPaiement.nom,
          'prenom': updatedPaiementJson['prenom'] ?? oldPaiement.prenom,
          'matricule': updatedPaiementJson['matricule'] ?? oldPaiement.matricule,
          'centre_nom': updatedPaiementJson['centre_nom'] ?? oldPaiement.centreNom,
          'numero_chambre': updatedPaiementJson['numero_chambre'] ?? oldPaiement.numeroChambre,
          'montant': updatedPaiementJson['montant'] ?? oldPaiement.montant,
          'date_paiement': updatedPaiementJson['date_paiement'] ?? oldPaiement.datePaiement?.toIso8601String(),
        });

        _paiements[oldPaiementIndex] = updatedPaiement;

        /// Actualisation des métriques financières globales.
        await loadStatistiques();
        notifyListeners();
      } else {
        throw Exception(response['message'] ?? 'Échec de la mise à jour distante');
      }
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    } finally {
      setLoading(false);
    }
  }

  /// Applique un ensemble de filtres simultanément pour optimiser les appels réseau.
  Future<void> applyMultipleFilters(Map<String, dynamic> newFilters) async {
    newFilters.forEach((key, value) {
      if (value == null || value.toString().isEmpty || value == 'TOUS') {
        _filters.remove(key);
      } else {
        _filters[key] = value;
      }
    });

    await loadPaiements(resetPage: true);
  }

  /// Charge les métriques et indicateurs de performance des paiements.
  Future<void> loadStatistiques({Map<String, String>? params}) async {
    try {
      final response = await _apiService.get(
        '/api/paiements/admin/statistics',
        params: params,
      );

      if (response['success'] == true) {
        _statistiques = response['data'] as Map<String, dynamic>? ?? {};
        notifyListeners();
      }
    } catch (e) {
      /// Réinitialisation des statistiques en cas d'erreur.
      _statistiques = {
        'total': 0,
        'montant_total': 0,
        'en_attente': 0,
        'confirmes': 0,
        'echecs': 0,
        'total_confirme': 0,
        'total_en_attente': 0,
        'total_echec': 0,
      };
      notifyListeners();
    }
  }

  /// Retourne un paiement spécifique à partir de la collection chargée en mémoire.
  Paiement? getPaiementById(String id) {
    try {
      return _paiements.firstWhere((p) => p.id.toString() == id);
    } catch (e) {
      return null;
    }
  }

  // ==================== MÉTHODES D'EXPORTATION ====================

  /// Déclenche la génération et l'exportation du rapport financier au format PDF via le backend.
  Future<void> exportPdfBackend(Map<String, dynamic> filters) async {
    try {
      final body = {
        'format': 'pdf',
        'periode': 'personnalisee',
        ...filters,
      };

      /// Nettoyage des paramètres facultatifs.
      body.removeWhere((key, value) => value == null || value.toString().isEmpty);

      final response = await _apiService.post(
        '/api/rapports/financier',
        body: body,
      );

      /// Traitement spécifique à la plateforme Web pour le téléchargement du flux binaire.
      if (kIsWeb && response is http.Response) {
        if (response.statusCode == 200) {
          _downloadFileWeb(response.bodyBytes, 'application/pdf', 'rapport_paiements.pdf');
        } else {
          throw Exception('Erreur serveur lors de la génération: ${response.statusCode}');
        }
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Génère et télécharge un fichier CSV localement à partir des données fournies.
  Future<void> exportCsvLocal(List<Paiement> paiements) async {
    if (!kIsWeb) return;

    try {
      final csvContent = _generateCsvContent(paiements);
      final bytes = utf8.encode(csvContent);
      _downloadFileWeb(
          bytes,
          'text/csv',
          'paiements_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.csv'
      );
    } catch (e) {
      rethrow;
    }
  }

  // ==================== UTILITAIRES DE SÉRIALISATION ====================

  /// Gère l'interaction avec les API de navigation Web pour le téléchargement de fichiers.
  void _downloadFileWeb(List<int> bytes, String mimeType, String fileName) {
    if (!kIsWeb) return;

    try {
      HtmlUtils.downloadFile(
        bytes: bytes,
        fileName: fileName,
        mimeType: mimeType,
      );
    } catch (e) {
      rethrow;
    }
  }

  /// Génère le contenu au format CSV à partir d'une liste de modèles [Paiement].
  String _generateCsvContent(List<Paiement> paiements) {
    final buffer = StringBuffer();

    /// Définition des en-têtes du document.
    buffer.writeln('Référence,Étudiant,Matricule,Centre,Chambre,Montant,Statut,Mode,Date');

    for (final p in paiements) {
      final dateStr = p.datePaiement != null
          ? DateFormat('dd/MM/yyyy HH:mm').format(p.datePaiement!)
          : 'N/A';

      buffer.writeln([
        '"${p.referenceTransaction ?? 'N/A'}"',
        '"${p.etudiantNomComplet}"',
        '"${p.matricule ?? 'N/A'}"',
        '"${p.centreNom ?? 'N/A'}"',
        '"${p.numeroChambre ?? 'N/A'}"',
        '${p.montant}',
        '"${_getStatutLabel(p.statut)}"',
        '"${_getModeLabel(p.modePaiement)}"',
        '"$dateStr"',
      ].join(','));
    }

    return buffer.toString();
  }

  /// Libellés explicites des statuts de paiement.
  String _getStatutLabel(String statut) {
    switch (statut) {
      case 'EN_ATTENTE': return 'En attente';
      case 'CONFIRME': return 'Confirmé';
      case 'ECHEC': return 'Échec';
      default: return statut;
    }
  }

  /// Libellés explicites des modes de paiement.
  String _getModeLabel(String mode) {
    switch (mode) {
      case 'ORANGE_MONEY': return 'Orange Money';
      case 'MOOV_MONEY': return 'Moov Money';
      case 'ESPECES': return 'Espèces';
      case 'VIREMENT': return 'Virement';
      default: return mode;
    }
  }

  /// Gère l'indicateur de chargement de manière asynchrone pour éviter les conflits de rendu.
  void setLoading(bool loading) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _isLoading = loading;
      notifyListeners();
    });
  }

  /// Utilitaires de conversion sécurisée des types.
  String? _convertToString(dynamic value) {
    if (value == null) return null;
    if (value is String) return value;
    return value.toString();
  }

  int? _convertToInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is String) return int.tryParse(value);
    if (value is num) return value.toInt();
    return null;
  }
}