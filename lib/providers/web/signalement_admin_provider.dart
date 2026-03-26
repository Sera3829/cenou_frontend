import 'package:flutter/foundation.dart';
import 'package:cenou_mobile/models/signalement.dart';
import 'package:cenou_mobile/services/api_service.dart';
import 'package:intl/intl.dart';

/// Gestionnaire d'administration des signalements pour l'interface Web.
/// Gère le cycle de vie, la filtration et les statistiques des interventions techniques.
class SignalementAdminProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();

  /// État de la collection et indicateurs de chargement.
  List<Signalement> _signalements = [];
  bool _isLoading = false;
  String? _error;
  Map<String, dynamic>? _statistiques;

  /// Paramètres de filtration actifs.
  String? _filterStatut;
  String? _filterType;
  int? _filterCentreId;
  DateTime? _filterDateFrom;
  DateTime? _filterDateTo;
  String _searchQuery = '';
  int _requestId = 0;

  /// Configuration de la pagination.
  int _currentPage = 1;
  int _totalPages = 1;
  int _totalItems = 0;
  final int _itemsPerPage = 20;

  // ==================== ACCESSEURS (GETTERS) ====================

  List<Signalement> get signalements => _signalements;
  bool get isLoading => _isLoading;
  String? get error => _error;
  Map<String, dynamic>? get statistiques => _statistiques;

  String? get filterStatut => _filterStatut;
  String? get filterType => _filterType;
  int? get filterCentreId => _filterCentreId;
  DateTime? get filterDateFrom => _filterDateFrom;
  DateTime? get filterDateTo => _filterDateTo;
  String get searchQuery => _searchQuery;

  int get currentPage => _currentPage;
  int get totalPages => _totalPages;
  int get totalItems => _totalItems;
  int get itemsPerPage => _itemsPerPage;

  // ==================== LOGIQUE DE CHARGEMENT ====================

  /// Charge la liste des signalements en appliquant les filtres et la pagination.
  /// L'option [resetPage] permet de revenir à la première page lors d'un changement de filtre.
  Future<void> loadSignalements({bool resetPage = false}) async {
    final currentRequestId = ++_requestId;
    if (resetPage) {
      _currentPage = 1;
    }

    setLoading(true);
    _error = null;

    try {
      /// Normalisation des paramètres de filtration.
      final statut = (_filterStatut != null && _filterStatut != 'TOUS')
          ? _filterStatut
          : null;

      final type = (_filterType != null && _filterType != 'TOUS')
          ? _filterType
          : null;

      final dateFrom = _filterDateFrom != null
          ? DateFormat('yyyy-MM-dd').format(_filterDateFrom!)
          : null;

      final dateTo = _filterDateTo != null
          ? DateFormat('yyyy-MM-dd').format(_filterDateTo!)
          : null;

      final search = _searchQuery.isNotEmpty ? _searchQuery : null;

      print('[SignalementAdminProvider] Fetching signalements with filters:');
      print('  - Statut: $statut, Type: $type, CentreID: $_filterCentreId');
      print('  - Range: $dateFrom to $dateTo, Search: $search');
      print('  - Pagination: Page $_currentPage, Limit: $_itemsPerPage');

      /// Exécution de la requête vers le service API.
      final response = await _apiService.getAdminSignalements(
        statut: statut,
        type: type,
        centreId: _filterCentreId,
        dateFrom: dateFrom,
        dateTo: dateTo,
        search: search,
        page: _currentPage,
        limit: _itemsPerPage,
      );

      print('[SignalementAdminProvider] API Raw Response received');

      /// Traitement et validation de la structure de réponse.
      if (response.containsKey('signalements')) {
        final items = response['signalements'] as List;
        final total = response['total'] ?? 0;

        /// Vérification de l'intégrité de la requête (concurrence).
        if (currentRequestId != _requestId) {
          print('[SignalementAdminProvider] Discarding outdated request ($currentRequestId)');
          return;
        }

        _signalements = items.map((json) => Signalement.fromJson(json)).toList();
        _totalItems = total;
        _totalPages = (_totalItems / _itemsPerPage).ceil();

        print('[SignalementAdminProvider] Success: ${_signalements.length} items loaded (Page $_currentPage/$_totalPages)');
      } else {
        print('[SignalementAdminProvider] Error: Invalid API response structure');
        throw Exception('Structure de réponse API invalide');
      }

      /// Actualisation synchronisée des statistiques globales.
      await loadStatistiques();

    } catch (e) {
      _error = e.toString();
      print('[SignalementAdminProvider] Critical error during load: $e');

      _signalements = [];
      _totalItems = 0;
      _totalPages = 1;
    } finally {
      setLoading(false);
    }
  }

  /// Récupère les métriques consolidées basées sur les filtres actuels.
  Future<void> loadStatistiques() async {
    try {
      final params = <String, String>{};

      if (_filterStatut != null && _filterStatut != 'TOUS') {
        params['statut'] = _filterStatut!;
      }
      if (_filterType != null && _filterType != 'TOUS') {
        params['type'] = _filterType!;
      }
      if (_filterCentreId != null) {
        params['centre_id'] = _filterCentreId!.toString();
      }
      if (_filterDateFrom != null) {
        params['date_from'] = DateFormat('yyyy-MM-dd').format(_filterDateFrom!);
      }
      if (_filterDateTo != null) {
        params['date_to'] = DateFormat('yyyy-MM-dd').format(_filterDateTo!);
      }
      if (_searchQuery.isNotEmpty) {
        params['search'] = _searchQuery;
      }

      print('[SignalementAdminProvider] Fetching statistics with params: $params');

      final response = await _apiService.get(
        '/api/signalements/admin/statistics',
        params: params,
      );

      if (response['success'] == true) {
        final data = response['data'];
        final processedData = <String, dynamic>{};

        /// Normalisation des données numériques (Cast explicite String vers Num).
        for (var key in data.keys) {
          final value = data[key];
          if (key == 'taux_resolution') {
            processedData[key] = double.tryParse(value?.toString() ?? '0') ?? 0.0;
          } else if (['total', 'en_attente', 'en_cours', 'resolus', 'annules',
            'plomberie', 'electricite', 'mobilier', 'toiture',
            'serrure', 'autre'].contains(key)) {
            processedData[key] = int.tryParse(value?.toString() ?? '0') ?? 0;
          } else {
            processedData[key] = value;
          }
        }

        _statistiques = processedData;
        print('[SignalementAdminProvider] Statistics updated: Total=${_statistiques?['total']}, Resolution=${_statistiques?['taux_resolution']}%');
      } else {
        print('[SignalementAdminProvider] Warning: API returned success:false for statistics');
      }
    } catch (e) {
      print('[SignalementAdminProvider] Error loading statistics: $e');
    }
  }

  // ==================== GESTION DES FILTRES ====================

  /// Applique un filtre spécifique et déclenche la mise à jour des données.
  Future<void> applyFilter(String key, dynamic value) async {
    print('[SignalementAdminProvider] Applying filter: $key = $value');

    switch (key) {
      case 'statut':
        _filterStatut = value;
        break;
      case 'type':
        _filterType = value;
        break;
      case 'centre_id':
        _filterCentreId = value != null ? int.tryParse(value.toString()) : null;
        break;
      case 'date_from':
        _filterDateFrom = value;
        break;
      case 'date_to':
        _filterDateTo = value;
        break;
    }

    await loadSignalements(resetPage: true);
  }

  /// Procède à une recherche textuelle sur l'ensemble de la collection.
  Future<void> searchSignalements(String query) async {
    _searchQuery = query.trim();
    await loadSignalements(resetPage: true);
  }

  /// Réinitialise l'intégralité des filtres aux valeurs par défaut.
  Future<void> resetFilters() async {
    print('[SignalementAdminProvider] Resetting all filters');
    _filterStatut = null;
    _filterType = null;
    _filterCentreId = null;
    _filterDateFrom = null;
    _filterDateTo = null;
    _searchQuery = '';
    _currentPage = 1;

    await loadSignalements();
  }

  // ==================== PAGINATION ====================

  Future<void> loadNextPage() async {
    if (_currentPage < _totalPages) {
      _currentPage++;
      await loadSignalements();
    }
  }

  Future<void> loadPreviousPage() async {
    if (_currentPage > 1) {
      _currentPage--;
      await loadSignalements();
    }
  }

  Future<void> goToPage(int page) async {
    if (page >= 1 && page <= _totalPages) {
      _currentPage = page;
      await loadSignalements();
    }
  }

  // ==================== ACTIONS MÉTIER ====================

  /// Met à jour le statut d'un signalement.
  /// Réalise une mise à jour optimiste de l'état local pour améliorer la réactivité de l'interface.
  Future<void> updateStatutSignalement({
    required String signalementId,
    required String nouveauStatut,
    String? commentaire,
  }) async {
    try {
      print('[SignalementAdminProvider] Updating status for ID $signalementId to $nouveauStatut');

      final oldIndex = _signalements.indexWhere((s) => s.id.toString() == signalementId);
      if (oldIndex == -1) throw Exception('Ressource introuvable');

      final oldSignalement = _signalements[oldIndex];

      /// 1. Mise à jour optimiste (UI instantanée).
      final updatedSignalement = oldSignalement.copyWith(
        statut: nouveauStatut,
        dateResolution: nouveauStatut == 'RESOLU' ? DateTime.now() : null,
        commentaireResolution: commentaire,
        nom: oldSignalement.nom,
        prenom: oldSignalement.prenom,
        matricule: oldSignalement.matricule,
        telephone: oldSignalement.telephone,
        email: oldSignalement.email,
        nomCentre: oldSignalement.nomCentre,
        numeroChambre: oldSignalement.numeroChambre,
        typeChambre: oldSignalement.typeChambre,
      );

      _signalements[oldIndex] = updatedSignalement;
      notifyListeners();

      print('[SignalementAdminProvider] Local state updated optimistically');

      /// 2. Persistance distante via l'API.
      final updateResponse = await _apiService.put(
        '/api/signalements/admin/$signalementId/statut',
        body: {
          'statut': nouveauStatut,
          if (commentaire != null && commentaire.isNotEmpty)
            'commentaire_resolution': commentaire,
        },
      );

      print('[SignalementAdminProvider] API response success: ${updateResponse['success']}');

      /// 3. Fusion des données finales retournées par le serveur.
      if (updateResponse['success'] == true && updateResponse['data'] != null) {
        final apiSignalement = Signalement.fromJson(updateResponse['data']);

        final mergedSignalement = Signalement(
          id: apiSignalement.id,
          numeroSuivi: apiSignalement.numeroSuivi,
          typeProbleme: apiSignalement.typeProbleme,
          description: apiSignalement.description,
          photos: apiSignalement.photos,
          statut: apiSignalement.statut,
          dateResolution: apiSignalement.dateResolution,
          commentaireResolution: apiSignalement.commentaireResolution,
          createdAt: apiSignalement.createdAt,
          updatedAt: apiSignalement.updatedAt,
          nom: apiSignalement.nom?.isNotEmpty == true ? apiSignalement.nom : oldSignalement.nom,
          prenom: apiSignalement.prenom?.isNotEmpty == true ? apiSignalement.prenom : oldSignalement.prenom,
          matricule: apiSignalement.matricule ?? oldSignalement.matricule,
          telephone: apiSignalement.telephone ?? oldSignalement.telephone,
          email: apiSignalement.email ?? oldSignalement.email,
          nomCentre: apiSignalement.nomCentre ?? oldSignalement.nomCentre,
          numeroChambre: apiSignalement.numeroChambre ?? oldSignalement.numeroChambre,
          typeChambre: apiSignalement.typeChambre ?? oldSignalement.typeChambre,
          ville: apiSignalement.ville ?? oldSignalement.ville,
          centreId: apiSignalement.centreId ?? oldSignalement.centreId,
          etudiantNomComplet: apiSignalement.etudiantNomComplet?.isNotEmpty == true
              ? apiSignalement.etudiantNomComplet
              : oldSignalement.etudiantNomComplet,
        );

        _signalements[oldIndex] = mergedSignalement;
        notifyListeners();
      }

      /// 4. Actualisation des métriques.
      await loadStatistiques();

    } catch (e) {
      print('[SignalementAdminProvider] Error in updateStatutSignalement: $e');
      rethrow;
    }
  }

  /// Affecte une équipe technique à un signalement spécifique.
  Future<void> assignerEquipe({
    required String signalementId,
    required int equipeId,
    String? commentaire,
  }) async {
    setLoading(true);

    try {
      print('[SignalementAdminProvider] Assigning team $equipeId to signalement $signalementId');

      final response = await _apiService.post(
        '/api/signalements/admin/$signalementId/assign',
        body: {
          'equipe_id': equipeId,
          if (commentaire != null) 'commentaire': commentaire,
        },
      );

      if (response['success'] == true) {
        final index = _signalements.indexWhere((s) => s.id.toString() == signalementId);
        if (index != -1) {
          _signalements[index] = _signalements[index].copyWith(
            statut: 'EN_COURS',
          );
          notifyListeners();
        }
        print('[SignalementAdminProvider] Team assigned successfully');
      } else {
        throw Exception(response['error'] ?? 'Erreur lors de l\'affectation');
      }
    } catch (e) {
      _error = e.toString();
      print('[SignalementAdminProvider] Team assignment error: $e');
      rethrow;
    } finally {
      setLoading(false);
    }
  }

  // ==================== UTILITAIRES D'INTERFACE ====================

  /// Gère l'indicateur de chargement global.
  void setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  /// Efface le message d'erreur actuel.
  void clearError() {
    _error = null;
    notifyListeners();
  }
}