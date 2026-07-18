import 'dart:async';
import 'package:flutter/foundation.dart';
import '../../services/api_service.dart';
import '../../models/admin/message_interne.dart';
import '../../models/admin/centre.dart';

/// Messagerie interne du staff (cloche du dashboard) : boîte de réception,
/// compteur non lus, composition de messages ciblés et marquage lu.
/// S'appuie sur le backend des annonces (cibles staff).
///
/// Compteur « intelligent » :
/// - rafraîchissement périodique (le badge se met à jour quand un message arrive) ;
/// - marquage lu optimiste (décrément immédiat) ;
/// - file de synchro hors-ligne → ligne : un message lu sans réseau est
///   renvoyé au serveur dès le retour en ligne.
class MessagerieProvider with ChangeNotifier {
  final ApiService _api = ApiService();

  static const _pollInterval = Duration(seconds: 45);

  List<MessageInterne> _messages = [];
  int _unreadCount = 0;
  bool _isLoading = false;
  bool _isSending = false;
  String? _error;

  Timer? _poll;
  final Set<int> _pendingRead = {}; // lectures faites hors ligne, à resynchroniser

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
  /// [silent] : rafraîchissement d'arrière-plan (pas d'indicateur de chargement).
  Future<void> loadInbox({bool silent = false}) async {
    if (!silent) {
      _isLoading = true;
      _error = null;
      notifyListeners();
    }
    // Rejoue d'abord les lectures faites hors ligne (si de retour en ligne).
    await _flushPendingRead();
    try {
      final res = await _api.get('/api/annonces/inbox');
      _messages = ((res['data'] as List?) ?? [])
          .map((e) => MessageInterne.fromJson(e as Map<String, dynamic>))
          .toList();
      // Réapplique les lectures encore en file (au cas où le serveur n'est pas à jour).
      if (_pendingRead.isNotEmpty) {
        _messages = _messages
            .map((m) => _pendingRead.contains(m.id) ? m.copyWith(lu: true) : m)
            .toList();
      }
      _unreadCount = _asInt(res['unread_count']) - _pendingRead.length;
      if (_unreadCount < 0) _unreadCount = 0;
    } catch (e) {
      if (!silent) _error = _clean(e);
      if (kDebugMode) print('Erreur loadInbox: $e');
    } finally {
      if (!silent) _isLoading = false;
      _ensurePolling();
      notifyListeners();
    }
  }

  /// Démarre le rafraîchissement périodique du compteur (une seule fois).
  void _ensurePolling() {
    _poll ??= Timer.periodic(_pollInterval, (_) => loadInbox(silent: true));
  }

  /// Renvoie au serveur les lectures effectuées hors ligne.
  Future<void> _flushPendingRead() async {
    if (_pendingRead.isEmpty) return;
    for (final id in _pendingRead.toList()) {
      try {
        await _api.put('/api/annonces/$id/lu');
        _pendingRead.remove(id);
      } catch (_) {
        // Toujours hors ligne : on retentera au prochain chargement.
      }
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
        // /users/admin/all renvoie { data: { users: [...], pagination } }.
        final data = r['data'];
        final list = (data is Map ? data['users'] : data) as List? ?? [];
        for (final u in list) {
          final m = u as Map<String, dynamic>;
          final nom = '${m['prenom'] ?? ''} ${m['nom'] ?? ''}'.trim();
          staff.add({
            'id': m['id'],
            'nom': nom.isEmpty ? (m['matricule'] ?? '—') : nom,
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

  /// Marque un message comme lu — optimiste (décrément immédiat), avec
  /// mise en file pour resynchronisation si l'appel échoue (hors ligne).
  Future<void> marquerLu(int messageId) async {
    final idx = _messages.indexWhere((m) => m.id == messageId);
    if (idx == -1 || _messages[idx].lu) return;
    _messages[idx] = _messages[idx].copyWith(lu: true);
    if (_unreadCount > 0) _unreadCount--;
    notifyListeners();
    try {
      final res = await _api.put('/api/annonces/$messageId/lu');
      _pendingRead.remove(messageId);
      _unreadCount = _asInt(res['unread_count']);
      notifyListeners();
    } catch (e) {
      // Hors ligne : état local conservé, mis en file pour renvoi ultérieur.
      _pendingRead.add(messageId);
      if (kDebugMode) print('marquerLu hors ligne, mis en file: $e');
    }
  }

  /// Marque tous les messages non lus comme lus.
  Future<void> marquerToutLu() async {
    final unread = _messages.where((m) => !m.lu).map((m) => m.id).toList();
    for (final id in unread) {
      await marquerLu(id);
    }
  }

  @override
  void dispose() {
    _poll?.cancel();
    super.dispose();
  }
}
