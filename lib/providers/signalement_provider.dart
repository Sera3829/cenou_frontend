import 'dart:io';
import 'package:flutter/material.dart';
import '../models/signalement.dart';
import '../services/signalement_service.dart';
import '../services/storage_service.dart';
import '../services/connectivity_service.dart';
import '../config/app_config.dart';

/// Gestionnaire d'état des signalements incluant la synchronisation réseau et la persistance locale.
class SignalementProvider with ChangeNotifier {
  final SignalementService _signalementService = SignalementService();
  final StorageService _storageService = StorageService();
  final ConnectivityService _connectivityService;

  List<Signalement> _signalements = [];
  bool _isLoading = false;
  String? _error;

  /// Indique si les données actuellement affichées proviennent du cache local.
  bool _isFromCache = false;

  // ==================== ACCESSEURS (GETTERS) ====================

  List<Signalement> get signalements => _signalements;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isFromCache => _isFromCache;

  SignalementProvider(this._connectivityService);

  /// Collecte des métriques et statistiques sur les signalements chargés.
  int get totalSignalements => _signalements.length;
  int get signalementsEnAttente => _signalements.where((s) => s.isEnAttente).length;
  int get signalementsEnCours => _signalements.where((s) => s.isEnCours).length;
  int get signalementsResolus => _signalements.where((s) => s.isResolu).length;

  /// Charge la liste des signalements en privilégiant l'API.
  /// En cas d'absence de connectivité, bascule automatiquement sur le stockage local.
  Future<void> loadSignalements() async {
    _isLoading = true;
    _error = null;
    _isFromCache = false;
    notifyListeners();

    try {
      /// Vérification de la connectivité réseau.
      final isOnline = _connectivityService.isOnline;

      if (isOnline) {
        print('📶 En ligne - Chargement signalements depuis l\'API');

        /// Récupération des données via le service distant.
        _signalements = await _signalementService.getSignalements();

        /// Mise à jour de la persistance locale.
        await _storageService.saveSignalementsCache(_signalements);

        _isFromCache = false;
        print('✅ Signalements chargés depuis l\'API: ${_signalements.length}');
      } else {
        print('Lors de la session hors ligne - Chargement depuis le cache');

        /// Récupération des données depuis le stockage local.
        final cachedSignalements = await _storageService.getSignalementsCache();

        if (cachedSignalements != null && cachedSignalements.isNotEmpty) {
          _signalements = cachedSignalements;
          _isFromCache = true;

          final cacheAge = await _storageService.getSignalementsCacheAge();
          print('Signalements chargés depuis le cache: ${_signalements.length} (âge: $cacheAge min)');
        } else {
          _signalements = [];
          _error = 'Aucune donnée en cache. Une connexion internet est requise pour synchroniser vos signalements.';
          print('Alerte : Aucun cache disponible');
        }
      }

    } catch (e) {
      _error = e.toString();
      print('Erreur loadSignalements: $e');

      /// Procédure de secours : tentative de récupération via le cache en cas d'erreur réseau.
      if (!_isFromCache) {
        print('Tentative de récupération via le cache local...');
        final cachedSignalements = await _storageService.getSignalementsCache();

        if (cachedSignalements != null && cachedSignalements.isNotEmpty) {
          _signalements = cachedSignalements;
          _isFromCache = true;
          _error = 'Erreur réseau. Affichage des données locales disponibles.';
          print('Bascule sur le cache effectuée : ${_signalements.length}');
        }
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Évalue si l'état actuel de la connectivité permet une action réseau.
  bool canPerformOnlineAction() {
    return _connectivityService.isOnline;
  }

  /// Initialise la création d'un nouveau signalement.
  /// Cette action nécessite impérativement une connexion internet active.
  Future<Signalement> creerSignalement({
    required String typeProbleme,
    required String description,
    required List<File> photos,
  }) async {
    if (!canPerformOnlineAction()) {
      throw Exception('Connexion internet requise pour créer un signalement');
    }

    try {
      final signalement = await _signalementService.creerSignalement(
        typeProbleme: typeProbleme,
        description: description,
        photos: photos,
      );

      /// Rafraîchissement automatique de la liste locale.
      await loadSignalements();

      return signalement;
    } catch (e) {
      print('Erreur lors de la création du signalement: $e');
      rethrow;
    }
  }

  /// Déclenche un cycle complet de rafraîchissement des données.
  Future<void> refresh() async {
    await loadSignalements();
  }

  /// Récupère les détails d'un signalement par son identifiant unique.
  /// Priorise la recherche en mémoire vive, puis sollicite l'API ou le cache local.
  Future<Signalement?> getSignalementById(int signalementId) async {
    try {
      final isOnline = _connectivityService.isOnline;

      /// 1. Recherche au sein de la collection chargée en mémoire.
      try {
        final existing = _signalements.firstWhere(
              (s) => s.id == signalementId,
        );
        return existing;
      } catch (e) {
        // Poursuite vers les sources de données persistantes si absent de la mémoire.
      }

      /// 2. Sollicitation du service distant ou du cache local.
      if (isOnline) {
        try {
          final signalement = await _signalementService.getSignalementById(signalementId);

          /// Mise à jour de la collection locale et de la persistance.
          if (signalement != null && !_signalements.any((s) => s.id == signalementId)) {
            _signalements.add(signalement);
            await _storageService.saveSignalementsCache(_signalements);
            notifyListeners();
          }

          return signalement;
        } catch (error) {
          print('Erreur lors du chargement individuel du signalement $signalementId: $error');
          return null;
        }
      } else {
        /// Mode hors ligne : consultation du stockage local.
        final cachedSignalements = await _storageService.getSignalementsCache();
        if (cachedSignalements != null) {
          try {
            return cachedSignalements.firstWhere(
                  (s) => s.id == signalementId,
            );
          } catch (e) {
            return null;
          }
        }
        return null;
      }
    } catch (e) {
      print('Erreur getSignalementById: $e');
      return null;
    }
  }

  /// Force la synchronisation des données depuis le serveur, ignorant le cache initial.
  Future<void> forceRefreshFromApi() async {
    if (!_connectivityService.isOnline) {
      _error = 'Une connexion internet est requise pour forcer la synchronisation.';
      notifyListeners();
      return;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _signalements = await _signalementService.getSignalements();
      await _storageService.saveSignalementsCache(_signalements);
      _isFromCache = false;
      print('Synchronisation forcée réussie depuis l\'API: ${_signalements.length}');
    } catch (e) {
      _error = e.toString();
      print('Erreur lors de la synchronisation forcée: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Construit l'URL absolue d'une ressource multimédia associée à un signalement.
  String getPhotoUrl(int signalementId, int photoIndex, List<String> photos) {
    try {
      if (photoIndex < 0 || photoIndex >= photos.length) {
        return '';
      }

      final path = photos[photoIndex];
      String filename = path.split('/').last;

      return '${AppConfig.staticBaseUrl}/uploads/signalements/$filename';
    } catch (e) {
      print('Erreur lors de la résolution de l\'URL photo: $e');
      return '';
    }
  }
}