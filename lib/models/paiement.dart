class Paiement {
  final int id;
  final String numeroReference;
  final double montant;
  final String modePaiement;
  final String statut;
  final DateTime? datePaiement;
  final DateTime? dateEcheance;
  final String? referenceTransaction;
  final String? numeroChambre;
  final String? nomCentre;
  final String? description;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? typePaiement;
  final int? userId;
  final String? matricule;
  final String? nom;
  final String? prenom;
  final String? centreNom;
  final String? centreVille;
  final String? typeChambre;
  final double? prixMensuel;
  final int? centreId;

  Paiement({
    required this.id,
    required this.numeroReference,
    required this.montant,
    required this.modePaiement,
    required this.statut,
    this.datePaiement,
    this.dateEcheance,
    this.referenceTransaction,
    this.numeroChambre,
    this.nomCentre,
    this.description,
    required this.createdAt,
    required this.updatedAt,
    this.typePaiement,
    this.userId,
    this.matricule,
    this.nom,
    this.prenom,
    this.centreNom,
    this.centreVille,
    this.typeChambre,
    this.prixMensuel,
    this.centreId,
  });

  /// Accesseurs calculés (Getters) pour la logique d'état du paiement.
  bool get isConfirme => statut == 'CONFIRME' || statut == 'PAYE';
  bool get isEchec => statut == 'ECHEC' || statut == 'ANNULE' || statut == 'FAILED';
  bool get isEnRetard => dateEcheance != null && dateEcheance!.isBefore(DateTime.now());

  /// Construit une instance de [Paiement] à partir d'une structure JSON.
  factory Paiement.fromJson(Map<String, dynamic> json) {
    return Paiement(
      id: _parseInt(json['id']),
      numeroReference: json['numero_reference']?.toString() ?? '',
      montant: _parseDouble(json['montant']),
      modePaiement: json['mode_paiement']?.toString() ?? '',
      statut: json['statut']?.toString() ?? 'EN_ATTENTE',
      datePaiement: _parseDateTime(json['date_paiement']),
      dateEcheance: _parseDateTime(json['date_echeance']),
      referenceTransaction: json['reference_transaction']?.toString(),
      numeroChambre: json['numero_chambre']?.toString(),
      nomCentre: json['nom_centre']?.toString(),
      description: json['description']?.toString(),
      createdAt: _parseDateTime(json['created_at']) ?? DateTime.now(),
      updatedAt: _parseDateTime(json['updated_at']) ?? DateTime.now(),
      typePaiement: json['type_paiement']?.toString(),
      userId: _parseInt(json['user_id']),
      matricule: json['matricule']?.toString(),
      nom: json['nom']?.toString(),
      prenom: json['prenom']?.toString(),
      centreNom: json['centre_nom']?.toString(),
      centreVille: json['centre_ville']?.toString(),
      typeChambre: json['type_chambre']?.toString(),
      prixMensuel: _parseDouble(json['prix_mensuel']),
      centreId: _parseInt(json['centre_id']),
    );
  }

  /// Méthodes utilitaires pour la conversion sécurisée des types de données.
  static int _parseInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) {
      return int.tryParse(value) ?? 0;
    }
    return 0;
  }

  static double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is num) return value.toDouble();
    if (value is String) {
      return double.tryParse(value) ?? 0.0;
    }
    return 0.0;
  }

  static DateTime? _parseDateTime(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    if (value is String) {
      try {
        return DateTime.parse(value);
      } catch (e) {
        return null;
      }
    }
    return null;
  }

  /// Retourne l'identité complète de l'étudiant associé au paiement.
  String get etudiantNomComplet {
    if (nom != null && prenom != null) {
      return '$nom $prenom';
    } else if (nom != null) {
      return nom!;
    } else if (prenom != null) {
      return prenom!;
    }
    return 'Étudiant inconnu';
  }

  /// Crée une copie de l'objet actuel avec des attributs modifiés.
  Paiement copyWith({
    int? id,
    String? numeroReference,
    double? montant,
    String? modePaiement,
    String? statut,
    DateTime? datePaiement,
    DateTime? dateEcheance,
    String? referenceTransaction,
    String? numeroChambre,
    String? nomCentre,
    String? description,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? typePaiement,
    int? userId,
    String? matricule,
    String? nom,
    String? prenom,
    String? centreNom,
    String? centreVille,
    String? typeChambre,
    double? prixMensuel,
    int? centreId,
  }) {
    return Paiement(
      id: id ?? this.id,
      numeroReference: numeroReference ?? this.numeroReference,
      montant: montant ?? this.montant,
      modePaiement: modePaiement ?? this.modePaiement,
      statut: statut ?? this.statut,
      datePaiement: datePaiement ?? this.datePaiement,
      dateEcheance: dateEcheance ?? this.dateEcheance,
      referenceTransaction: referenceTransaction ?? this.referenceTransaction,
      numeroChambre: numeroChambre ?? this.numeroChambre,
      nomCentre: nomCentre ?? this.nomCentre,
      description: description ?? this.description,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      typePaiement: typePaiement ?? this.typePaiement,
      userId: userId ?? this.userId,
      matricule: matricule ?? this.matricule,
      nom: nom ?? this.nom,
      prenom: prenom ?? this.prenom,
      centreNom: centreNom ?? this.centreNom,
      centreVille: centreVille ?? this.centreVille,
      typeChambre: typeChambre ?? this.typeChambre,
      prixMensuel: prixMensuel ?? this.prixMensuel,
      centreId: centreId ?? this.centreId,
    );
  }

  /// Sérialise l'objet en format [Map] pour les transferts sortants.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'numero_reference': numeroReference,
      'montant': montant,
      'mode_paiement': modePaiement,
      'statut': statut,
      'date_paiement': datePaiement?.toIso8601String(),
      'date_echeance': dateEcheance?.toIso8601String(),
      'reference_transaction': referenceTransaction,
      'numero_chambre': numeroChambre,
      'nom_centre': nomCentre,
      'description': description,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'type_paiement': typePaiement,
    };
  }
}