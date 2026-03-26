import 'package:flutter/material.dart';

/// Modèle représentant une activité ou un événement système au sein du tableau de bord.
class Activity {
  /// Identifiant unique de l'activité (dérivé des métadonnées ou de l'horodatage).
  final String id;

  /// Type d'activité (correspond à la clé 'activity_type' dans le flux JSON).
  final String activityType;

  final String title;
  final String description;
  final DateTime timestamp;
  final Map<String, dynamic> metadata;

  /// Nom de l'utilisateur associé (attribut optionnel selon la source de données).
  final String? userName;

  Activity({
    required this.id,
    required this.activityType,
    required this.title,
    required this.description,
    required this.timestamp,
    required this.metadata,
    this.userName,
  });

  /// Instancie un objet [Activity] à partir d'un dictionnaire JSON.
  factory Activity.fromJson(Map<String, dynamic> json) {
    return Activity(
      id: '${json['metadata']?['signalement_id'] ?? json['metadata']?['paiement_id'] ?? json['timestamp']}',
      activityType: json['activity_type']?.toString() ?? 'UNKNOWN',
      title: json['title']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      timestamp: DateTime.parse(json['timestamp']?.toString() ?? DateTime.now().toIso8601String()),
      metadata: json['metadata'] as Map<String, dynamic>? ?? {},
      userName: _extractUserName(json),
    );
  }

  /// Extrait le nom d'utilisateur des données JSON.
  /// Note : Une implémentation complémentaire via un service tiers peut être nécessaire
  /// si l'API ne fournit pas cette information directement.
  static String? _extractUserName(Map<String, dynamic> json) {
    return null;
  }

  /// Attributs visuels pour l'interface utilisateur.

  /// Retourne l'icône associée au type d'activité.
  IconData get icon {
    switch (activityType) {
      case 'SIGNALEMENT_CREATE': return Icons.warning;
      case 'PAIEMENT_CONFIRME': return Icons.payment;
      case 'PAIEMENT_INITIE': return Icons.payment;
      case 'USER_CREATE': return Icons.person_add;
      case 'SIGNALEMENT_RESOLU': return Icons.check_circle;
      case 'SIGNALEMENT_AFFECTE': return Icons.assignment;
      default: return Icons.notifications;
    }
  }

  /// Retourne la couleur thématique associée au type d'activité.
  Color get color {
    switch (activityType) {
      case 'SIGNALEMENT_CREATE': return const Color(0xFFF59E0B);
      case 'PAIEMENT_CONFIRME': return const Color(0xFF10B981);
      case 'PAIEMENT_INITIE': return const Color(0xFF3B82F6);
      case 'USER_CREATE': return const Color(0xFF8B5CF6);
      case 'SIGNALEMENT_RESOLU': return const Color(0xFF10B981);
      case 'SIGNALEMENT_AFFECTE': return const Color(0xFFEC4899);
      default: return const Color(0xFF64748B);
    }
  }

  /// Calcule le temps écoulé depuis la création de l'activité pour l'affichage textuel.
  String get timeAgo {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 1) return 'À l\'instant';
    if (difference.inMinutes < 60) return 'Il y a ${difference.inMinutes} min';
    if (difference.inHours < 24) return 'Il y a ${difference.inHours} h';
    if (difference.inDays < 7) return 'Il y a ${difference.inDays} j';
    if (difference.inDays < 30) return 'Il y a ${(difference.inDays / 7).floor()} sem';
    return 'Il y a ${(difference.inDays / 30).floor()} mois';
  }

  /// Formate la description en intégrant les métadonnées contextuelles (type, chambre, etc.).
  String get formattedDescription {
    if (description.contains(' - ')) {
      return description;
    }

    switch (activityType) {
      case 'SIGNALEMENT_CREATE':
        final type = metadata['type_probleme'] ?? 'Problème';
        final chambre = metadata['chambre'] ?? metadata['numero_chambre'] ?? 'Chambre inconnue';
        return 'Signalement $type - $chambre';

      case 'PAIEMENT_CONFIRME':
        final montant = metadata['montant'] ?? '0';
        final chambre = metadata['chambre'] ?? 'Chambre inconnue';
        return 'Paiement de $montant FCFA - $chambre';

      default:
        return description;
    }
  }
}