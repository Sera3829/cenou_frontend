import 'package:flutter/foundation.dart';
import 'package:cenou_mobile/services/api_service.dart';
import '../../models/admin/centre_admin.dart';

/// État de l'espace « Centres » (admin), navigation à trois niveaux :
/// Centres → Pavillons du centre → Chambres du pavillon.
class CentreAdminProvider extends ChangeNotifier {
  final ApiService _apiService = ApiService();

  // Niveau 1 — centres
  List<CentreAdmin> _centres = [];
  bool _isLoading = false;
  String? _error;

  // Niveau 2 — pavillons du centre sélectionné
  int? _selectedCentreId;
  List<Pavillon> _pavillons = [];
  bool _isLoadingPavillons = false;

  // Niveau 3 — chambres du pavillon sélectionné
  int? _selectedPavillonId;
  List<Chambre> _chambres = [];
  bool _isLoadingChambres = false;

  List<CentreAdmin> get centres => _centres;
  bool get isLoading => _isLoading;
  String? get error => _error;

  int? get selectedCentreId => _selectedCentreId;
  List<Pavillon> get pavillons => _pavillons;
  bool get isLoadingPavillons => _isLoadingPavillons;

  int? get selectedPavillonId => _selectedPavillonId;
  List<Chambre> get chambres => _chambres;
  bool get isLoadingChambres => _isLoadingChambres;

  CentreAdmin? get selectedCentre {
    for (final c in _centres) {
      if (c.id == _selectedCentreId) return c;
    }
    return null;
  }

  Pavillon? get selectedPavillon {
    for (final p in _pavillons) {
      if (p.id == _selectedPavillonId) return p;
    }
    return null;
  }

  String _clean(Object e) => e.toString().replaceFirst('Exception: ', '');

  // ── Niveau 1 : centres ─────────────────────────────────────────────────

  Future<void> loadCentres() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final response = await _apiService.getCentresAdmin();
      final list = (response['data'] as List? ?? []);
      _centres = list.map((e) => CentreAdmin.fromJson(e as Map<String, dynamic>)).toList();
    } catch (e) {
      _error = _clean(e);
      if (kDebugMode) print('Erreur loadCentres: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<String?> createCentre(Map<String, dynamic> body) => _wrap(() async {
        await _apiService.createCentre(body);
        await loadCentres();
      });

  Future<String?> updateCentre(int id, Map<String, dynamic> body) => _wrap(() async {
        await _apiService.updateCentre(id, body);
        await loadCentres();
      });

  Future<String?> deleteCentre(int id) => _wrap(() async {
        await _apiService.deleteCentre(id);
        if (_selectedCentreId == id) clearCentreSelection();
        await loadCentres();
      });

  // ── Niveau 2 : pavillons ───────────────────────────────────────────────

  Future<void> selectCentre(int centreId) async {
    _selectedCentreId = centreId;
    _selectedPavillonId = null;
    _pavillons = [];
    _chambres = [];
    notifyListeners();
    await loadPavillons();
  }

  void clearCentreSelection() {
    _selectedCentreId = null;
    _selectedPavillonId = null;
    _pavillons = [];
    _chambres = [];
    notifyListeners();
  }

  Future<void> loadPavillons() async {
    if (_selectedCentreId == null) return;
    _isLoadingPavillons = true;
    notifyListeners();
    try {
      final response = await _apiService.getCentrePavillons(_selectedCentreId!);
      final list = (response['data'] as List? ?? []);
      _pavillons = list.map((e) => Pavillon.fromJson(e as Map<String, dynamic>)).toList();
    } catch (e) {
      if (kDebugMode) print('Erreur loadPavillons: $e');
    } finally {
      _isLoadingPavillons = false;
      notifyListeners();
    }
  }

  Future<String?> createPavillon(Map<String, dynamic> body) => _wrap(() async {
        await _apiService.createPavillon(_selectedCentreId!, body);
        await loadPavillons();
        await loadCentres();
      });

  Future<String?> updatePavillon(int id, Map<String, dynamic> body) => _wrap(() async {
        await _apiService.updatePavillon(id, body);
        await loadPavillons();
      });

  Future<String?> deletePavillon(int id) => _wrap(() async {
        await _apiService.deletePavillon(id);
        if (_selectedPavillonId == id) clearPavillonSelection();
        await loadPavillons();
        await loadCentres();
      });

  // ── Niveau 3 : chambres ────────────────────────────────────────────────

  Future<void> selectPavillon(int pavillonId) async {
    _selectedPavillonId = pavillonId;
    _chambres = [];
    notifyListeners();
    await loadChambres();
  }

  void clearPavillonSelection() {
    _selectedPavillonId = null;
    _chambres = [];
    notifyListeners();
  }

  Future<void> loadChambres() async {
    if (_selectedPavillonId == null) return;
    _isLoadingChambres = true;
    notifyListeners();
    try {
      final response = await _apiService.getPavillonLogements(_selectedPavillonId!);
      final list = (response['data'] as List? ?? []);
      _chambres = list.map((e) => Chambre.fromJson(e as Map<String, dynamic>)).toList();
    } catch (e) {
      if (kDebugMode) print('Erreur loadChambres: $e');
    } finally {
      _isLoadingChambres = false;
      notifyListeners();
    }
  }

  /// Rafraîchit chambres + pavillons + centres (les stats remontent).
  Future<void> _refreshChambres() async {
    await loadChambres();
    await loadPavillons();
    await loadCentres();
  }

  /// Détecte l'erreur « capacité du pavillon dépassée » renvoyée par le backend.
  bool _capaciteDepassee(Object e) =>
      e is ApiException && e.code == 'CAPACITE_DEPASSEE';

  /// Crée une chambre. `ajuster: true` relève la capacité du pavillon si besoin.
  /// Retourne capaciteDepassee=true si le backend refuse pour cause de capacité.
  Future<({String? error, String? message, bool capaciteDepassee})> createChambre(
      Map<String, dynamic> body, {bool ajuster = false}) async {
    try {
      final payload = ajuster ? {...body, 'ajuster': true} : body;
      await _apiService.createPavillonLogement(_selectedPavillonId!, payload);
      await _refreshChambres();
      return (error: null, message: null, capaciteDepassee: false);
    } catch (e) {
      return (error: _clean(e), message: null, capaciteDepassee: _capaciteDepassee(e));
    }
  }

  /// Création en masse — message de résultat (créées/ignorées) en cas de succès.
  /// `ajuster: true` relève la capacité du pavillon pour absorber le lot.
  Future<({String? error, String? message, bool capaciteDepassee})> bulkCreateChambres(
      Map<String, dynamic> body, {bool ajuster = false}) async {
    try {
      final payload = ajuster ? {...body, 'ajuster': true} : body;
      final res = await _apiService.bulkCreateLogements(_selectedPavillonId!, payload);
      await _refreshChambres();
      return (error: null, message: res['message'] as String?, capaciteDepassee: false);
    } catch (e) {
      return (error: _clean(e), message: null, capaciteDepassee: _capaciteDepassee(e));
    }
  }

  Future<String?> updateChambre(int id, Map<String, dynamic> body) => _wrap(() async {
        await _apiService.updateLogement(id, body);
        await _refreshChambres();
      });

  Future<String?> deleteChambre(int id) => _wrap(() async {
        await _apiService.deleteLogement(id);
        await _refreshChambres();
      });

  /// Exécute une action ; retourne null si succès, le message d'erreur sinon.
  Future<String?> _wrap(Future<void> Function() action) async {
    try {
      await action();
      return null;
    } catch (e) {
      return _clean(e);
    }
  }
}
