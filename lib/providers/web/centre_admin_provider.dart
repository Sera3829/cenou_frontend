import 'package:flutter/foundation.dart';
import 'package:cenou_mobile/services/api_service.dart';
import '../../models/admin/centre_admin.dart';

/// État de l'espace « Centres » (admin) : liste des centres et chambres
/// du centre sélectionné, avec les opérations de création/édition/suppression.
class CentreAdminProvider extends ChangeNotifier {
  final ApiService _apiService = ApiService();

  List<CentreAdmin> _centres = [];
  bool _isLoading = false;
  String? _error;

  int? _selectedCentreId;
  List<Chambre> _chambres = [];
  bool _isLoadingChambres = false;

  List<CentreAdmin> get centres => _centres;
  bool get isLoading => _isLoading;
  String? get error => _error;
  int? get selectedCentreId => _selectedCentreId;
  List<Chambre> get chambres => _chambres;
  bool get isLoadingChambres => _isLoadingChambres;

  CentreAdmin? get selectedCentre {
    if (_selectedCentreId == null) return null;
    for (final c in _centres) {
      if (c.id == _selectedCentreId) return c;
    }
    return null;
  }

  // ── Centres ──────────────────────────────────────────────────────────────

  Future<void> loadCentres() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final response = await _apiService.getCentresAdmin();
      final list = (response['data'] as List? ?? []);
      _centres = list.map((e) => CentreAdmin.fromJson(e as Map<String, dynamic>)).toList();
    } catch (e) {
      _error = e.toString();
      if (kDebugMode) print('Erreur loadCentres: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<String?> createCentre(Map<String, dynamic> body) async {
    try {
      await _apiService.createCentre(body);
      await loadCentres();
      return null;
    } catch (e) {
      return _clean(e);
    }
  }

  Future<String?> updateCentre(int id, Map<String, dynamic> body) async {
    try {
      await _apiService.updateCentre(id, body);
      await loadCentres();
      return null;
    } catch (e) {
      return _clean(e);
    }
  }

  Future<String?> deleteCentre(int id) async {
    try {
      await _apiService.deleteCentre(id);
      if (_selectedCentreId == id) {
        _selectedCentreId = null;
        _chambres = [];
      }
      await loadCentres();
      return null;
    } catch (e) {
      return _clean(e);
    }
  }

  // ── Chambres du centre sélectionné ────────────────────────────────────────

  Future<void> selectCentre(int centreId) async {
    _selectedCentreId = centreId;
    _chambres = [];
    notifyListeners();
    await loadChambres();
  }

  void clearSelection() {
    _selectedCentreId = null;
    _chambres = [];
    notifyListeners();
  }

  Future<void> loadChambres() async {
    if (_selectedCentreId == null) return;
    _isLoadingChambres = true;
    notifyListeners();
    try {
      final response = await _apiService.getCentreLogements(_selectedCentreId!);
      final list = (response['data'] as List? ?? []);
      _chambres = list.map((e) => Chambre.fromJson(e as Map<String, dynamic>)).toList();
    } catch (e) {
      if (kDebugMode) print('Erreur loadChambres: $e');
    } finally {
      _isLoadingChambres = false;
      notifyListeners();
    }
  }

  Future<String?> createChambre(Map<String, dynamic> body) async {
    if (_selectedCentreId == null) return 'Aucun centre sélectionné';
    try {
      await _apiService.createLogement(_selectedCentreId!, body);
      await loadChambres();
      await loadCentres(); // rafraîchit les stats du centre
      return null;
    } catch (e) {
      return _clean(e);
    }
  }

  Future<String?> updateChambre(int logementId, Map<String, dynamic> body) async {
    try {
      await _apiService.updateLogement(logementId, body);
      await loadChambres();
      await loadCentres();
      return null;
    } catch (e) {
      return _clean(e);
    }
  }

  Future<String?> deleteChambre(int logementId) async {
    try {
      await _apiService.deleteLogement(logementId);
      await loadChambres();
      await loadCentres();
      return null;
    } catch (e) {
      return _clean(e);
    }
  }

  /// Retire le préfixe « Exception: » des messages d'erreur pour l'affichage.
  String _clean(Object e) => e.toString().replaceFirst('Exception: ', '');
}
