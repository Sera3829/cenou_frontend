import 'dart:async';
import 'dart:io';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';

/// Service de gestion de la connectivité réseau.
///
/// Surveille les changements d'état de connexion et vérifie la disponibilité
/// réelle d'Internet via une requête DNS.
class ConnectivityService with ChangeNotifier {
  final Connectivity _connectivity = Connectivity();
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;

  bool _isOnline = true;
  bool _isChecking = false;

  /// Indique si l'appareil est connecté à Internet.
  bool get isOnline => _isOnline;

  /// Indique si l'appareil est hors ligne.
  bool get isOffline => !_isOnline;

  /// Indique si une vérification de connectivité est en cours.
  bool get isChecking => _isChecking;

  ConnectivityService() {
    _initConnectivity();
    _connectivitySubscription =
        _connectivity.onConnectivityChanged.listen(_updateConnectionStatus);
  }

  /// Initialise la surveillance de la connectivité.
  Future<void> _initConnectivity() async {
    try {
      final result = await _connectivity.checkConnectivity();
      await _updateConnectionStatus(result);
    } catch (e) {
      print('Erreur initialisation connectivite: $e');
      _isOnline = false;
      notifyListeners();
    }
  }

  /// Met à jour le statut de connexion en fonction des résultats de connectivité.
  Future<void> _updateConnectionStatus(List<ConnectivityResult> results) async {
    // Absence de toute connectivité
    if (results.contains(ConnectivityResult.none)) {
      _isOnline = false;
      print('Hors ligne');
      notifyListeners();
      return;
    }

    // Connexion mobile ou Wi-Fi : vérifier la disponibilité réelle d'Internet
    if (results.contains(ConnectivityResult.mobile) ||
        results.contains(ConnectivityResult.wifi)) {
      final hasInternet = await checkInternetConnection();
      _isOnline = hasInternet;
      print(hasInternet ? 'En ligne' : 'Hors ligne (pas de connexion internet)');
      notifyListeners();
      return;
    }

    // Cas par défaut
    _isOnline = false;
    notifyListeners();
  }

  /// Vérifie la disponibilité réelle d'Internet en effectuant une requête DNS.
  Future<bool> checkInternetConnection() async {
    if (_isChecking) return _isOnline;

    _isChecking = true;

    try {
      final result = await InternetAddress.lookup('google.com')
          .timeout(const Duration(seconds: 5));

      _isChecking = false;
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } on SocketException catch (_) {
      _isChecking = false;
      return false;
    } on TimeoutException catch (_) {
      _isChecking = false;
      return false;
    } catch (e) {
      print('Erreur verification internet: $e');
      _isChecking = false;
      return false;
    }
  }

  /// Force une vérification manuelle de la connectivité.
  Future<bool> checkConnection() async {
    final result = await _connectivity.checkConnectivity();
    await _updateConnectionStatus(result);
    return _isOnline;
  }

  @override
  void dispose() {
    _connectivitySubscription?.cancel();
    super.dispose();
  }
}