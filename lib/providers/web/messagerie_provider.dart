import 'package:flutter/foundation.dart';
import '../../services/api_service.dart';
import '../../models/admin/message_interne.dart';
import '../../models/admin/centre.dart';

/// Messagerie interne du staff (cloche du dashboard) : boîte de réception,
/// compteur non lus, composition de messages ciblés et marquage lu.
/// S'appuie sur le backend des annonces (cibles staff).
class MessagerieProvider with ChangeNotifier {
  final ApiService _api = ApiService();

  List<MessageInterne> _messages = [];
  int _unreadCount = 0;
  bool _isLoading = false;
  bool _isSending = false;
  String? _error;

  // Référentiels pour la composition (chargés à la demande).
  List<Centre> _centres = [];
  List<Map<String, dynamic>> _staff = [];
  bool _refsLoaded = false;

  List<MessageInterne> get messages => _messages;
  int get unreadCount => _unreadCount;
  bool get isLoading => _isLoading;
  bool get isSending => _isSending;
  String? get error => _error;
  List<Centre> get centres => _centres;
  List<Map<String, dynamic>> get staff => _staff;

  String _clean(Object e) => e.toString().replaceFirst('Exception: ', '');
  static int _asInt(dynamic v) =>
      v == null ? 0 : (v is int ? v : int.tryParse(v.toString()) ?? 0);

  /// Charge la boîte de réception + le compteur non lus.
  Future<void> loadInbox() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final res = await _api.get('/api/annonces/inbox');
      _messages = ((res['data'] as List?) ?? [])
          .map((e) => MessageInterne.fromJson(e as Map<String, dynamic>))
          .toList();
      _unreadCount = _asInt(res['unread_count']);
    } catch (e) {
      _error = _clean(e);
      if (kDebugMode) print('Erreur loadInbox: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Charge une fois les centres et le staff (pour le sélecteur de destinataires).
  Future<void> ensureRefs() async {
    if (_refsLoaded) return;
    try {
      final cRes = await _api.get('/api/centres');
      _centres = (((cRes['data'] as List?) ?? []))
          .map((e) => Centre.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      _centres = [];
    }
    try {
      final staff = <Map<String, dynamic>>[];
      for (final role in ['ADMIN', 'GESTIONNAIRE']) {
        final r = await _api.get('/api/users/admin/all',
            params: {'role': role, 'limit': '200'});
        for (final u in ((r['data'] as List?) ?? [])) {
          final m = u as Map<String, dynamic>;
          staff.add({
            'id': m['id'],
            'nom': '${m['prenom'] ?? ''} ${m['nom'] ?? ''}'.trim(),
            'role': (m['role'] ?? '') as String,
            'centre': (m['centre_nom'] ?? '') as String,
          });
        }
      }
      _staff = staff;
    } catch (_) {
      _staff = [];
    }
    _refsLoaded = true;
    notifyListeners();
  }

  /// Envoie un message. mode ∈ {GENERAL, CENTRE, DIRECT}.
  /// Retourne null en cas de succès, un message d'erreur sinon.
  Future<String?> envoyer({
    required String titre,
    required String contenu,
    required String mode,
    int? centreId,
    List<int>? userIds,
  }) async {
    _isSending = true;
    notifyListeners();
    try {
      final cible = mode == 'CENTRE'
          ? 'GESTIONNAIRES_CENTRE'
          : mode == 'DIRECT'
              ? 'UTILISATEURS'
              : 'GESTIONNAIRES';
      final body = <String, dynamic>{
        'titre': titre,
        'contenu': contenu,
        'cible': cible,
        'statut': 'PUBLIE',
      };
      if (cible == 'GESTIONNAIRES_CENTRE' && centreId != null) {
        body['centre_id'] = centreId;
      }
      if (cible == 'UTILISATEURS' && userIds != null && userIds.isNotEmpty) {
        body['user_ids'] = userIds;
      }
      await _api.post('/api/annonces/send', body: body);
      await loadInbox();
      return null;
    } catch (e) {
      return _clean(e);
    } finally {
      _isSending = false;
      notifyListeners();
    }
  }

  /// Marque un message comme lu (mise à jour optimiste locale).
  Future<void> marquerLu(int messageId) async {
    final idx = _messages.indexWhere((m) => m.id == messageId);
    if (idx == -1 || _messages[idx].lu) return;
    try {
      final res = await _api.put('/api/annonces/$messageId/lu');
      _messages[idx] = _messages[idx].copyWith(lu: true);
      _unreadCount = _asInt(res['unread_count']);
      notifyListeners();
    } catch (e) {
      if (kDebugMode) print('Erreur marquerLu: $e');
    }
  }

  /// Marque tous les messages non lus comme lus.
  Future<void> marquerToutLu() async {
    final unread = _messages.where((m) => !m.lu).map((m) => m.id).toList();
    for (final id in unread) {
      await marquerLu(id);
    }
  }
}
