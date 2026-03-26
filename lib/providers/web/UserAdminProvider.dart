import 'package:flutter/foundation.dart';
import '../../models/admin/admin_user.dart';
import '../../models/admin/centre.dart';
import 'package:cenou_mobile/services/api_service.dart';

class UserAdminProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();

  List<AdminUser> _users = [];
  List<Centre> _centres = [];
  List<Map<String, dynamic>> _availableLogements = [];
  bool _isLoading = false;
  String? _error;
  bool _disposed = false;

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  void safeNotify() {
    if (!_disposed) {
      notifyListeners();
    }
  }

  // Filtres
  String _selectedRole = 'TOUS';
  String _selectedStatut = 'TOUS';
  String _searchQuery = '';

  // Stats pour affichage
  int _totalItems = 0;

  // Getters
  List<AdminUser> get users => _users;
  List<Centre> get centres => _centres;
  List<Map<String, dynamic>> get availableLogements => _availableLogements;
  bool get isLoading => _isLoading;
  String? get error => _error;
  ApiService get apiService => _apiService;

  String get selectedRole => _selectedRole;
  String get selectedStatut => _selectedStatut;
  String get searchQuery => _searchQuery;

  int get totalItems => _totalItems;

  // Charger tous les utilisateurs en une fois
  Future<void> loadUsers() async {
    setLoading(true);
    _error = null;

    try {
      final response = await _apiService.getAdminUsers(
        role: _selectedRole != 'TOUS' ? _selectedRole : null,
        statut: _selectedStatut != 'TOUS' ? _selectedStatut : null,
        search: _searchQuery.isNotEmpty ? _searchQuery : null,
        page: 1,
        limit: 1000,
      );

      if (!response.containsKey('data')) {
        throw Exception('Reponse API invalide: pas de cle "data"');
      }

      final data = response['data'] as Map<String, dynamic>;

      if (!data.containsKey('users')) {
        throw Exception('Reponse API invalide: pas de cle "users" dans data');
      }

      final items = data['users'] as List? ?? [];
      List<AdminUser> mappedUsers = items.map((json) {
        try {
          return AdminUser.fromJson(json);
        } catch (e) {
          rethrow;
        }
      }).toList();

      final Map<int, AdminUser> uniqueUsersMap = {};
      for (var user in mappedUsers) {
        uniqueUsersMap[user.id] = user;
      }

      _users = uniqueUsersMap.values.toList();
      _totalItems = _users.length;

    } catch (e, stackTrace) {
      _error = e.toString();
      _users = [];
      _totalItems = 0;
    } finally {
      setLoading(false);
    }
  }

  // Charger les centres
  Future<void> loadCentres() async {
    try {
      final response = await _apiService.get('/api/centres');

      if (response.containsKey('data')) {
        final centresData = response['data'] as List?;
        _centres = (centresData ?? [])
            .map((json) => Centre.fromJson(json))
            .toList();
        safeNotify();
      } else {
        _centres = [];
      }
    } catch (e) {
      _centres = [];
    }
  }

  // Charger les logements disponibles d'un centre
  Future<void> loadAvailableLogements(int centreId) async {
    try {
      final response = await _apiService.get('/api/logements?centre_id=$centreId&statut=DISPONIBLE');

      if (response.containsKey('data')) {
        _availableLogements = List<Map<String, dynamic>>.from(response['data'] ?? []);
        safeNotify();
      } else {
        _availableLogements = [];
      }
    } catch (e) {
      _availableLogements = [];
    }
  }

  // Créer un utilisateur
  Future<void> createUser({
    required String matricule,
    required String nom,
    required String prenom,
    required String email,
    String? telephone,
    required String role,
    String statut = 'ACTIF',
    String? motDePasse,
    int? centreId,
    int? logementId,
    String? dateDebut,
    String? dateFin,
  }) async {
    try {
      final body = <String, dynamic>{
        'matricule': matricule,
        'nom': nom,
        'prenom': prenom,
        'email': email,
        'role': role,
        'statut': statut,
      };

      if (telephone != null && telephone.isNotEmpty) {
        body['telephone'] = telephone;
      }

      if (motDePasse != null && motDePasse.isNotEmpty) {
        body['mot_de_passe'] = motDePasse;
        body['confirmation_mot_de_passe'] = motDePasse;
      }

      if (centreId != null) {
        body['centre_id'] = centreId;
      }

      if (logementId != null) {
        body['logement_id'] = logementId;
      }

      if (dateDebut != null) {
        body['date_debut'] = dateDebut;
      }

      if (dateFin != null) {
        body['date_fin'] = dateFin;
      }

      final response = await _apiService.post('/api/users/admin/create', body: body);

      final userData = response['data']['user'] ?? response['data'];
      final createdUser = AdminUser.fromJson(userData);
      _users.insert(0, createdUser);
      _totalItems = _users.length;
      safeNotify();

    } catch (e, stackTrace) {
      rethrow;
    }
  }

  // Mettre à jour un utilisateur
  Future<void> updateUser({
    required int userId,
    String? nom,
    String? prenom,
    String? email,
    String? telephone,
    String? statut,
    int? logementId,
    String? dateDebut,
    String? dateFin,
  }) async {
    try {
      final body = <String, dynamic>{};

      if (nom != null && nom.isNotEmpty) {
        body['nom'] = nom;
      }
      if (prenom != null && prenom.isNotEmpty) {
        body['prenom'] = prenom;
      }
      if (email != null && email.isNotEmpty) {
        body['email'] = email;
      }
      if (telephone != null && telephone.isNotEmpty) {
        body['telephone'] = telephone;
      }
      if (statut != null && statut.isNotEmpty) {
        body['statut'] = statut;
      }
      if (logementId != null) {
        body['logement_id'] = logementId;
      }
      if (dateDebut != null) {
        body['date_debut'] = dateDebut;
      }
      if (dateFin != null) {
        body['date_fin'] = dateFin;
      }

      final response = await _apiService.put('/api/users/admin/$userId', body: body);

      final index = _users.indexWhere((u) => u.id == userId);
      if (index != -1) {
        _users[index] = AdminUser.fromJson(response['data']['user'] ?? response['data']);
        safeNotify();
      }

    } catch (e) {
      rethrow;
    }
  }

  // Mettre à jour le statut d'un utilisateur
  Future<void> updateUserStatus(int userId, String nouveauStatut) async {
    try {
      await _apiService.put('/api/users/admin/$userId/statut', body: {'statut': nouveauStatut});

      final index = _users.indexWhere((u) => u.id == userId);
      if (index != -1) {
        _users[index] = _users[index].copyWith(statut: nouveauStatut);
        safeNotify();
      }
    } catch (e) {
      rethrow;
    }
  }

  // Supprimer un utilisateur
  Future<void> deleteUser(int userId) async {
    try {
      await _apiService.delete('/api/users/admin/$userId');

      _users.removeWhere((u) => u.id == userId);
      _totalItems = _users.length;
      safeNotify();
    } catch (e) {
      rethrow;
    }
  }

  // Appliquer un filtre
  Future<void> applyFilter(String key, dynamic value) async {
    switch (key) {
      case 'role':
        _selectedRole = value ?? 'TOUS';
        break;
      case 'statut':
        _selectedStatut = value ?? 'TOUS';
        break;
      case 'search':
        _searchQuery = value ?? '';
        break;
    }
    await loadUsers();
  }

  // Réinitialiser les filtres
  Future<void> resetFilters() async {
    _selectedRole = 'TOUS';
    _selectedStatut = 'TOUS';
    _searchQuery = '';
    await loadUsers();
  }

  // Utilitaires
  void setLoading(bool loading) {
    _isLoading = loading;
    safeNotify();
  }

  void clearError() {
    _error = null;
    safeNotify();
  }
}