import 'package:flutter/material.dart';

/// Message de la messagerie interne du staff (reçu dans la cloche du dashboard).
/// Réutilise le backend des annonces (cibles GESTIONNAIRES / GESTIONNAIRES_CENTRE /
/// UTILISATEURS), enrichi de l'état de lecture propre au destinataire.
class MessageInterne {
  final int id;
  final String titre;
  final String contenu;
  final String cible;
  final String? centreNom;
  final String? expediteur; // prénom + nom de l'auteur
  final DateTime createdAt;
  final bool lu;

  MessageInterne({
    required this.id,
    required this.titre,
    required this.contenu,
    required this.cible,
    this.centreNom,
    this.expediteur,
    required this.createdAt,
    required this.lu,
  });

  MessageInterne copyWith({bool? lu}) => MessageInterne(
        id: id,
        titre: titre,
        contenu: contenu,
        cible: cible,
        centreNom: centreNom,
        expediteur: expediteur,
        createdAt: createdAt,
        lu: lu ?? this.lu,
      );

  /// Libellé lisible de la portée du message.
  String get porteeLabel {
    switch (cible) {
      case 'GESTIONNAIRES':
        return 'Note générale';
      case 'GESTIONNAIRES_CENTRE':
        return centreNom != null ? 'Centre · $centreNom' : 'Par centre';
      case 'UTILISATEURS':
        return 'Message direct';
      default:
        return cible;
    }
  }

  Color get porteeColor {
    switch (cible) {
      case 'GESTIONNAIRES':
        return const Color(0xFF2563EB); // bleu
      case 'GESTIONNAIRES_CENTRE':
        return const Color(0xFF059669); // vert
      case 'UTILISATEURS':
        return const Color(0xFF8B5CF6); // violet
      default:
        return const Color(0xFF64748B);
    }
  }

  IconData get porteeIcon {
    switch (cible) {
      case 'GESTIONNAIRES':
        return Icons.campaign_rounded;
      case 'GESTIONNAIRES_CENTRE':
        return Icons.location_city_rounded;
      case 'UTILISATEURS':
        return Icons.person_rounded;
      default:
        return Icons.mail_rounded;
    }
  }

  static int _toInt(dynamic v) =>
      v == null ? 0 : (v is int ? v : int.tryParse(v.toString()) ?? 0);

  factory MessageInterne.fromJson(Map<String, dynamic> json) {
    final prenom = json['created_by_prenom'];
    final nom = json['created_by_nom'];
    final exp = (prenom != null || nom != null)
        ? '${prenom ?? ''} ${nom ?? ''}'.trim()
        : null;
    return MessageInterne(
      id: _toInt(json['id']),
      titre: (json['titre'] ?? '') as String,
      contenu: (json['contenu'] ?? '') as String,
      cible: (json['cible'] ?? '') as String,
      centreNom: json['centre_nom'] as String?,
      expediteur: (exp != null && exp.isNotEmpty) ? exp : null,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
      lu: json['lu'] == true,
    );
  }
}
