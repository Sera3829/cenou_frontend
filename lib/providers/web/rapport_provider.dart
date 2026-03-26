// providers/web/rapport_provider.dart
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:cenou_mobile/services/api_service.dart';
import 'package:cenou_mobile/models/admin/centre.dart';

/// Fournisseur d'état gérant la récupération et la filtration des rapports.
class RapportProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();

  List<Centre> _centres = [];
  bool _isLoading = false;
  String? _error;

  List<Centre> get centres => _centres;
  bool get isLoading => _isLoading;
  String? get error => _error;

  /// Récupère la liste des centres depuis l'API et applique une déduplication.
  Future<void> loadCentres() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // Journalisation du début de l'opération de récupération
      print('[RapportProvider] Fetching centers...');
      final response = await _apiService.get('/api/centres');

      if (response.containsKey('data')) {
        final centresData = response['data'] as List?;
        _centres = (centresData ?? [])
            .map((json) => Centre.fromJson(json))
            .toList();

        /// Processus de déduplication par nom (conserve la première occurrence rencontrée)
        final uniqueCentres = <Centre>[];
        final seenNames = <String>{};

        for (final centre in _centres) {
          if (!seenNames.contains(centre.nom)) {
            seenNames.add(centre.nom);
            uniqueCentres.add(centre);
          }
        }

        _centres = uniqueCentres;

        // Confirmation de la réussite du chargement
        print('[RapportProvider] Successfully loaded ${_centres.length} unique centers');
      }
    } catch (e) {
      _error = e.toString();
      // Journalisation de l'exception pour le débogage technique
      print('[RapportProvider] Error during centers fetch: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Déclenche un rafraîchissement complet du référentiel des centres.
  Future<void> refresh() async {
    await loadCentres();
  }
}

