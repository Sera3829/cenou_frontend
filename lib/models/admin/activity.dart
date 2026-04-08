import 'package:flutter/material.dart';
import '../../l10n/app_localizations.dart';

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

  // ==================== MÉTHODES LOCALISÉES ====================

  /// Retourne le temps écoulé localisé (ex: "Il y a 5 min" ou "5 min ago")
  String getLocalizedTimeAgo(AppLocalizations l10n) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 1) {
      return l10n.justNow;
    }
    if (difference.inMinutes < 60) {
      return l10n.timeMinutesAgo(difference.inMinutes);
    }
    if (difference.inHours < 24) {
      return l10n.timeHoursAgo(difference.inHours);
    }
    if (difference.inDays < 7) {
      return l10n.timeDaysAgo(difference.inDays);
    }
    if (difference.inDays < 30) {
      final weeks = (difference.inDays / 7).floor();
      return l10n.timeWeeksAgo(weeks);
    }
    final months = (difference.inDays / 30).floor();
    return l10n.timeMonthsAgo(months);
  }

  /// Retourne la description formatée et localisée
  String getLocalizedDescription(AppLocalizations l10n) {
    switch (activityType) {
      case 'SIGNALEMENT_CREATE':
        final type   = metadata['type_probleme'] ?? l10n.problem;
        final chambre= metadata['chambre'] ?? metadata['numero_chambre'] ?? l10n.unknownRoom;
        return l10n.reportCreatedDesc(type, chambre);

      case 'PAIEMENT_CONFIRME':
        final montant = metadata['montant']?.toString() ?? '0';
        final chambre = metadata['chambre'] ?? metadata['numero_chambre'] ?? l10n.unknownRoom;
        return l10n.paymentConfirmedDesc(montant, chambre);

      case 'PAIEMENT_INITIE':
        final montant = metadata['montant']?.toString() ?? '0';
        final chambre = metadata['chambre'] ?? metadata['numero_chambre'] ?? l10n.unknownRoom;
        return l10n.paymentInitiatedDesc(montant, chambre);

      case 'USER_CREATE':
      // Essayer d'abord les champs metadata
        final name = metadata['utilisateur'] ?? metadata['nom'] ??
            metadata['prenom_nom'] ?? '';
        final role = metadata['role']?.toString() ?? '';
        if (name.isNotEmpty) {
          return l10n.registrationDesc(name, role);
        }
        // Fallback : parser la description brute de l'API
        // Format API : "Inscription: Madi OUEDRAOGO (ETUDIANT)"
        return _translateApiDescription(description, l10n);

      case 'SIGNALEMENT_RESOLU':
        final type = metadata['type_probleme'] ?? l10n.problem;
        return l10n.reportResolvedDesc(type);

      case 'SIGNALEMENT_AFFECTE':
        final type = metadata['type_probleme'] ?? l10n.problem;
        return l10n.reportAssignedDesc(type);

      default:
        return _translateApiDescription(description, l10n);
    }
  }


  /// Parse et traduit les descriptions brutes de l'API.
  /// Ex: "Inscription: Madi OUEDRAOGO (ETUDIANT)" → "Registration: Madi OUEDRAOGO (STUDENT)"
  String _translateApiDescription(String apiDesc, AppLocalizations l10n) {
    if (apiDesc.isEmpty) return l10n.unknownActivity;

    // Pattern "Inscription: NOM (ROLE)"
    final inscRegex = RegExp(r'^Inscription\s*:\s*(.+?)\s*\((\w+)\)$', caseSensitive: false);
    final inscMatch = inscRegex.firstMatch(apiDesc);
    if (inscMatch != null) {
      final name = inscMatch.group(1) ?? '';
      final role = inscMatch.group(2) ?? '';
      return l10n.registrationDesc(name, _translateRole(role, l10n));
    }

    // Pattern "Paiement de X FCFA - Y"
    final payRegex = RegExp(r'^Paiement de (.+?) - (.+)$', caseSensitive: false);
    final payMatch = payRegex.firstMatch(apiDesc);
    if (payMatch != null) {
      final amount = payMatch.group(1) ?? '0';
      final room   = payMatch.group(2) ?? l10n.unknownRoom;
      return l10n.paymentConfirmedDesc(amount, room);
    }

    return apiDesc; // pas de pattern connu → retour brut
  }

  String _translateRole(String role, AppLocalizations l10n) {
    switch (role.toUpperCase()) {
      case 'ETUDIANT':
        return l10n.isFrench ? 'ÉTUDIANT' : 'STUDENT';
      case 'GESTIONNAIRE':
        return l10n.isFrench ? 'GESTIONNAIRE' : 'MANAGER';
      case 'ADMIN':
        return l10n.isFrench ? 'ADMIN' : 'ADMIN';
      default:
        return role;
    }
  }

  /// Retourne le titre localisé
  String getLocalizedTitle(AppLocalizations l10n) {
    switch (activityType) {
      case 'SIGNALEMENT_CREATE':  return l10n.actReportCreated;
      case 'PAIEMENT_CONFIRME':   return l10n.actPaymentConf;
      case 'PAIEMENT_INITIE':     return l10n.actPaymentInit;
      case 'USER_CREATE':         return l10n.actNewUser;
      case 'SIGNALEMENT_RESOLU':  return l10n.actReportResolved;
      case 'SIGNALEMENT_AFFECTE': return l10n.actReportAssigned;
      default:
      // Le title vient de l'API en français → on tente de le traduire
        return _translateApiTitle(title, l10n);
    }
  }

  /// Traduit les titres connus que l'API envoie en français.
  String _translateApiTitle(String apiTitle, AppLocalizations l10n) {
    switch (apiTitle.toLowerCase().trim()) {
      case 'nouvel utilisateur':   return l10n.actNewUser;
      case 'paiement confirmé':    return l10n.actPaymentConf;
      case 'paiement initié':      return l10n.actPaymentInit;
      case 'nouveau signalement':  return l10n.actReportCreated;
      case 'signalement résolu':   return l10n.actReportResolved;
      case 'signalement affecté':  return l10n.actReportAssigned;
      default: return apiTitle.isNotEmpty ? apiTitle : l10n.activity;
    }
  }
}