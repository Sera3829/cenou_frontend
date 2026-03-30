import 'package:flutter/material.dart';
import '../models/paiement.dart';
import '../services/paiement_service.dart';
import '../services/storage_service.dart';
import '../services/connectivity_service.dart';

/// Gestionnaire d'état des paiements incluant la synchronisation réseau et la persistance locale.
class PaiementProvider with ChangeNotifier {
  final PaiementService _paiementService = PaiementService();
  final StorageService _storageService = StorageService();
  final ConnectivityService _connectivityService;

  List<Paiement> _paiements = [];
  List<Paiement> _pendingPaiementsList = [];
  bool _isLoading = false;
  String? _error;

  /// Indique si les données actuelles proviennent du cache local (mode hors ligne).
  bool _isFromCache = false;

  // ==================== ACCESSEURS (GETTERS) ====================

  List<Paiement> get paiements => _paiements;
  List<Paiement> get pendingPaiementsList => _pendingPaiementsList;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isFromCache => _isFromCache;
  Map<String, dynamic>? _loyerInfo;
  Map<String, dynamic>? get loyerInfo => _loyerInfo;

  PaiementProvider(this._connectivityService);

  /// Retourne la liste des paiements dont l'échéance est atteinte et le statut non finalisé.
  List<Paiement> get paiementsAttendus {
    return _paiements.where((p) {
      return p.dateEcheance != null &&
          !p.isConfirme &&
          !p.isEchec;
    }).toList();
  }

  // ==================== STATISTIQUES ET MÉTRIQUES ====================

  int get totalPaiements => _paiements.length;
  int get paiementsConfirmes => _paiements.where((p) => p.isConfirme).length;
  int get paiementsEchec => _paiements.where((p) => p.isEchec).length;
  int get pendingPaiementsCount => _pendingPaiementsList.length;
  int get paiementsAttendusCount => paiementsAttendus.length;

  /// Calcul du montant total des transactions confirmées.
  double get montantTotal => _paiements
      .where((p) => p.isConfirme)
      .fold(0, (sum, p) => sum + p.montant);

  /// Calcul du montant total des transactions en attente d'échéance.
  double get montantTotalAttendu => paiementsAttendus
      .fold(0, (sum, p) => sum + p.montant);

  // ==================== LOGIQUE DE CHARGEMENT ====================

  /// Charge la liste des paiements en privilégiant l'API.
  /// En cas d'indisponibilité réseau, bascule automatiquement sur les données persistées localement.
  Future<void> loadPaiements() async {
    _isLoading = true;
    _error = null;
    _isFromCache = false;
    notifyListeners();

    try {
      final isOnline = _connectivityService.isOnline;

      if (isOnline) {
        // Récupération des données distantes via l'API.
        _paiements = await _paiementService.getPaiements();

        // Mise à jour de la persistance locale.
        await _storageService.savePaiementsCache(_paiements);
        _isFromCache = false;
      } else {
        // Récupération des données depuis le stockage local (Mode hors ligne).
        final cachedPaiements = await _storageService.getPaiementsCache();

        if (cachedPaiements != null && cachedPaiements.isNotEmpty) {
          _paiements = cachedPaiements;
          _isFromCache = true;
        } else {
          _paiements = [];
          _error = 'Aucune donnée en cache. Une connexion internet est requise pour synchroniser vos paiements.';
        }
      }
    } catch (e) {
      _error = e.toString();

      // Fallback sur le cache en cas d'exception réseau imprévue.
      if (!_isFromCache) {
        final cachedPaiements = await _storageService.getPaiementsCache();
        if (cachedPaiements != null && cachedPaiements.isNotEmpty) {
          _paiements = cachedPaiements;
          _isFromCache = true;
          _error = 'Erreur réseau. Affichage des données locales disponibles.';
        }
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<Map<String, dynamic>> getLoyerInfo() async {
    try {
      _loyerInfo = await _paiementService.getLoyerInfo();
      notifyListeners();
      return _loyerInfo!;
    } catch (e) {
      rethrow;
    }
  }

  /// Charge les transactions dont le statut est "en attente".
  /// Cette action nécessite impérativement une connexion active.
  Future<void> loadPendingPaiements() async {
    if (!_connectivityService.isOnline) return;

    try {
      _pendingPaiementsList = await _paiementService.getPendingPaiements();
      notifyListeners();
    } catch (e) {
      // Erreur de chargement des paiements en attente.
    }
  }

  /// Évalue la possibilité d'effectuer des actions nécessitant une connectivité réseau.
  bool canPerformOnlineAction() {
    return _connectivityService.isOnline;
  }

  /// Récupère les détails d'un paiement spécifique par son identifiant unique.
  /// Recherche d'abord en mémoire, puis dans l'API ou le cache local selon l'état du réseau.
  Future<Paiement?> getPaiementById(int paiementId) async {
    try {
      final isOnline = _connectivityService.isOnline;

      // 1. Recherche dans l'état actuel de la mémoire.
      for (var paiement in _paiements) {
        if (paiement.id == paiementId) {
          return paiement;
        }
      }

      // 2. Recherche distante ou locale selon la disponibilité.
      if (isOnline) {
        final paiement = await _paiementService.getPaiementById(paiementId);
        if (paiement != null) {
          _paiements.add(paiement);
          await _storageService.savePaiementsCache(_paiements);
          notifyListeners();
        }
        return paiement;
      } else {
        final cachedPaiements = await _storageService.getPaiementsCache();
        if (cachedPaiements != null) {
          for (var paiement in cachedPaiements) {
            if (paiement.id == paiementId) {
              return paiement;
            }
          }
        }
        return null;
      }
    } catch (e) {
      return null;
    }
  }

  /// Initie une nouvelle transaction financière.
  /// Nécessite une connexion internet stable.
  Future<Map<String, dynamic>> initierPaiement({
    required double montant,
    required String modePaiement,
    required String numeroTelephone,
    required int nombreMois,
  }) async {
    if (!canPerformOnlineAction()) {
      throw Exception('Connexion internet requise pour effectuer un paiement');
    }
    try {
      final result = await _paiementService.initierPaiement(
        montant: montant,
        modePaiement: modePaiement,
        numeroTelephone: numeroTelephone,
        nombreMois: nombreMois,
      );
      await refresh();
      return result;
    } catch (e) {
      rethrow;
    }
  }

  /// Procède à la mise à jour complète des données de paiement.
  Future<void> refresh() async {
    await Future.wait([
      loadPaiements(),
      if (_connectivityService.isOnline) loadPendingPaiements(),
    ]);
  }

  /// Force la synchronisation des données directement depuis l'API, ignorant le cache initial.
  Future<void> forceRefreshFromApi() async {
    if (!_connectivityService.isOnline) {
      _error = 'Connexion internet requise pour la synchronisation forcée.';
      notifyListeners();
      return;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _paiements = await _paiementService.getPaiements();
      await _storageService.savePaiementsCache(_paiements);
      _isFromCache = false;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}