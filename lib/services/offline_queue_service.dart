import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// Nature d'une action différée. Volontairement fermé : toute nouvelle valeur
/// doit passer le critère de sûreté documenté sur [OfflineQueueService].
enum OfflineActionType {
  /// Marquer une notification précise comme lue.
  notificationRead,

  /// Marquer toutes les notifications comme lues.
  notificationReadAll,
}

/// Une action réalisée hors ligne, en attente de rejeu.
class OfflineAction {
  final OfflineActionType type;

  /// Identifiant de la cible ; null pour les actions globales.
  final String? targetId;

  final DateTime createdAt;

  OfflineAction({
    required this.type,
    this.targetId,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  /// Clé d'unicité : deux actions identiques ne sont jamais empilées deux fois.
  String get cle => '${type.name}:${targetId ?? '*'}';

  Map<String, dynamic> toJson() => {
        'type': type.name,
        'targetId': targetId,
        'createdAt': createdAt.toIso8601String(),
      };

  static OfflineAction? fromJson(Map<String, dynamic> json) {
    OfflineActionType? type;
    for (final t in OfflineActionType.values) {
      if (t.name == json['type']) type = t;
    }
    // Type inconnu (file écrite par une version plus récente) : on ignore.
    if (type == null) return null;

    return OfflineAction(
      type: type,
      targetId: json['targetId'] as String?,
      createdAt:
          DateTime.tryParse(json['createdAt'] as String? ?? '') ?? DateTime.now(),
    );
  }
}

/// File d'attente durable des actions effectuées hors ligne, rejouées dès le
/// retour du réseau.
///
/// **Périmètre volontairement restreint aux actions idempotentes et sans effet
/// financier.** Rejouer une opération d'argent est dangereux : un paiement
/// remis en file pourrait débiter deux fois l'étudiant si la réponse du serveur
/// s'est perdue. Les paiements restent donc strictement en ligne
/// (`PaiementProvider.initierPaiement` refuse hors ligne), et cette règle vaut
/// aussi pour l'intégration CinetPay à venir.
///
/// La file est vidée à la déconnexion : une action empilée par un utilisateur
/// ne doit jamais être rejouée avec le jeton du suivant.
class OfflineQueueService {
  static const String _cleFile = 'offline_action_queue';

  static final OfflineQueueService _instance = OfflineQueueService._interne();
  factory OfflineQueueService() => _instance;
  OfflineQueueService._interne();

  Future<SharedPreferences> get _prefs => SharedPreferences.getInstance();

  /// Actions en attente, de la plus ancienne à la plus récente.
  Future<List<OfflineAction>> enAttente() async {
    try {
      final prefs = await _prefs;
      final brut = prefs.getString(_cleFile);
      if (brut == null || brut.isEmpty) return [];

      final liste = jsonDecode(brut) as List;
      return liste
          .map((e) => OfflineAction.fromJson(Map<String, dynamic>.from(e)))
          .whereType<OfflineAction>()
          .toList();
    } catch (e) {
      // File corrompue : mieux vaut repartir à vide que bloquer l'application.
      return [];
    }
  }

  /// Empile une action, en ignorant les doublons exacts.
  Future<void> empiler(OfflineAction action) async {
    try {
      final actions = await enAttente();
      if (actions.any((a) => a.cle == action.cle)) return;

      actions.add(action);
      await _ecrire(actions);
    } catch (e) {
      // Échec d'écriture : l'action reste appliquée localement, sans rejeu.
    }
  }

  /// Retire les actions dont le rejeu a réussi.
  Future<void> retirer(Iterable<String> cles) async {
    try {
      final restantes =
          (await enAttente()).where((a) => !cles.contains(a.cle)).toList();
      await _ecrire(restantes);
    } catch (e) {
      // Sans effet : les actions restées en file seront simplement retentées.
    }
  }

  /// Vide la file. À appeler à la déconnexion (cloisonnement des sessions).
  Future<void> vider() async {
    try {
      final prefs = await _prefs;
      await prefs.remove(_cleFile);
    } catch (e) {
      // Rien à faire.
    }
  }

  Future<void> _ecrire(List<OfflineAction> actions) async {
    final prefs = await _prefs;
    await prefs.setString(
      _cleFile,
      jsonEncode(actions.map((a) => a.toJson()).toList()),
    );
  }
}
