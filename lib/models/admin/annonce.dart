import 'package:flutter/material.dart';

/// Modèle représentant une annonce ou une notification administrative au sein du système.
class Annonce {
  final int id;
  final String titre;
  final String contenu;
  final String cible;
  final int? centreId;
  final String? centreNom;
  final String statut;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? datePublication;
  final DateTime? dateExpiration;
  final int createdBy;
  final String? createdByName;
  final int totalDestinataires;

  Annonce({
    required this.id,
    required this.titre,
    required this.contenu,
    required this.cible,
    this.centreId,
    this.centreNom,
    required this.statut,
    required this.createdAt,
    required this.updatedAt,
    this.datePublication,
    this.dateExpiration,
    required this.createdBy,
    this.createdByName,
    required this.totalDestinataires,
  });

  /// Initialise une instance de [Annonce] à partir d'un dictionnaire JSON.
  factory Annonce.fromJson(Map<String, dynamic> json) {
    /// Gestion de la dynamicité du type pour le champ 'total_destinataires'.
    final totalDest = json['total_destinataires'];
    final totalDestinataires = totalDest is String
        ? int.tryParse(totalDest) ?? 0
        : (totalDest as int?) ?? 0;

    return Annonce(
      id: json['id'] as int,
      titre: json['titre'] as String,
      contenu: json['contenu'] as String,
      cible: json['cible'] as String,
      centreId: json['centre_id'] as int?,
      centreNom: json['centre_nom'] as String?,
      statut: json['statut'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      datePublication: json['date_publication'] != null
          ? DateTime.parse(json['date_publication'] as String)
          : null,
      dateExpiration: json['date_expiration'] != null
          ? DateTime.parse(json['date_expiration'] as String)
          : null,
      createdBy: json['created_by'] as int,
      createdByName: json['created_by_name'] as String?,
      totalDestinataires: totalDestinataires,
    );
  }

  /// Sérialise l'objet pour les transferts de données sortants.
  Map<String, dynamic> toJson() {
    return {
      'titre': titre,
      'contenu': contenu,
      'cible': cible,
      if (centreId != null) 'centre_id': centreId,
      'statut': statut,
      if (datePublication != null)
        'date_publication': datePublication!.toIso8601String(),
      if (dateExpiration != null)
        'date_expiration': dateExpiration!.toIso8601String(),
    };
  }

  /// Retourne le libellé associé au type de cible.
  String get typeLabel {
    switch (cible) {
      case 'TOUS': return 'Générale';
      case 'CENTRE_SPECIFIQUE': return 'Par centre';
      case 'ETUDIANTS': return 'Étudiants spécifiques';
      case 'GESTIONNAIRES': return 'Gestionnaires';
      default: return cible;
    }
  }

  /// Retourne la couleur thématique associée au type de cible.
  Color get typeColor {
    switch (cible) {
      case 'TOUS': return Colors.blue;
      case 'CENTRE_SPECIFIQUE': return Colors.green;
      case 'ETUDIANTS': return Colors.purple;
      case 'GESTIONNAIRES': return Colors.orange;
      default: return Colors.grey;
    }
  }

  /// Retourne le libellé utilisateur du statut actuel.
  String get statutLabel {
    switch (statut) {
      case 'PUBLIE': return 'Publiée';
      case 'BROUILLON': return 'Brouillon';
      case 'ARCHIVEE': return 'Archivée';
      default: return statut;
    }
  }

  /// Retourne la couleur sémantique associée au statut.
  Color get statutColor {
    switch (statut) {
      case 'PUBLIE': return Colors.green;
      case 'BROUILLON': return Colors.orange;
      case 'ARCHIVEE': return Colors.grey;
      default: return Colors.grey;
    }
  }

  /// Génère un résumé textuel de la portée de l'annonce.
  String get summary {
    if (cible == 'TOUS') return 'À tous les étudiants';
    if (cible == 'CENTRE_SPECIFIQUE') return 'Centre: $centreNom';
    if (cible == 'ETUDIANTS') {
      return '$totalDestinataires étudiant(s) spécifique(s)';
    }
    if (cible == 'GESTIONNAIRES') {
      return 'Aux gestionnaires';
    }
    return 'Destinataires spécifiques';
  }

  /// Évalue si l'annonce est actuellement active selon le statut et la période de validité.
  bool get isActive {
    if (statut != 'PUBLIE') return false;
    if (dateExpiration != null && dateExpiration!.isBefore(DateTime.now())) {
      return false;
    }
    if (datePublication != null && datePublication!.isAfter(DateTime.now())) {
      return false;
    }
    return true;
  }
}