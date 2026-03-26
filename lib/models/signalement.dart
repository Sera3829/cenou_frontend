/// Représente un signalement technique ou administratif soumis par un étudiant.
class Signalement {
  final int id;
  final String numeroSuivi;
  final String typeProbleme;
  final String description;
  final List<String> photos;
  final String statut;
  final DateTime? dateResolution;
  final String? commentaireResolution;
  final DateTime createdAt;
  final DateTime updatedAt;

  /// Informations relatives à l'affectation géographique de l'étudiant.
  final String? numeroChambre;
  final String? typeChambre;
  final String? nomCentre;
  final String? ville;
  final int? centreId;

  /// Données d'identification et coordonnées de l'étudiant.
  final String? nom;
  final String? prenom;
  final String? matricule;
  final String? telephone;
  final String? email;
  final String? etudiantNomComplet;

  Signalement({
    required this.id,
    required this.numeroSuivi,
    required this.typeProbleme,
    required this.description,
    required this.photos,
    required this.statut,
    this.dateResolution,
    this.commentaireResolution,
    required this.createdAt,
    required this.updatedAt,
    this.numeroChambre,
    this.typeChambre,
    this.nomCentre,
    this.ville,
    this.centreId,
    this.nom,
    this.prenom,
    this.matricule,
    this.telephone,
    this.email,
    this.etudiantNomComplet,
  });

  /// Prédicats d'état pour le suivi du cycle de vie du signalement.
  bool get isEnAttente => statut == 'EN_ATTENTE';
  bool get isEnCours => statut == 'EN_COURS';
  bool get isResolu => statut == 'RESOLU';
  bool get isAnnule => statut == 'ANNULE';

  /// Résout l'identité complète de l'étudiant en fonction des attributs disponibles.
  String get displayEtudiantNomComplet {
    // Priorité à l'attribut calculé par le backend
    if (etudiantNomComplet != null && etudiantNomComplet!.isNotEmpty) {
      return etudiantNomComplet!;
    }

    // Construction manuelle à partir des segments d'identité
    if (nom != null && prenom != null) {
      return '$nom $prenom';
    } else if (nom != null) {
      return nom!;
    } else if (prenom != null) {
      return prenom!;
    }

    // Valeur de repli par défaut
    return 'N/A';
  }

  /// Initialise une instance de [Signalement] à partir d'une structure de données JSON.
  factory Signalement.fromJson(Map<String, dynamic> json) {
    return Signalement(
      id: json['id'] as int,
      numeroSuivi: json['numero_suivi'] ?? '',
      typeProbleme: json['type_probleme'] ?? '',
      description: json['description'] ?? '',
      photos: json['photos'] != null
          ? List<String>.from(json['photos'] as List)
          : [],
      statut: json['statut'] ?? '',
      dateResolution: json['date_resolution'] != null
          ? DateTime.parse(json['date_resolution'])
          : null,
      commentaireResolution: json['commentaire_resolution'] as String?,
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
      numeroChambre: json['numero_chambre'] as String?,
      typeChambre: json['type_chambre'] as String?,
      nomCentre: json['nom_centre'] as String?,
      ville: json['ville'] as String?,
      centreId: json['centre_id'] as int?,
      nom: json['nom'] as String? ?? '',
      prenom: json['prenom'] as String? ?? '',
      matricule: json['matricule'] as String?,
      telephone: json['telephone'] as String?,
      email: json['email'] as String?,
      etudiantNomComplet: json['etudiant_nom_complet'] as String? ?? '',
    );
  }

  /// Sérialise l'objet en un dictionnaire [Map] pour les transferts de données.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'numero_suivi': numeroSuivi,
      'type_probleme': typeProbleme,
      'description': description,
      'photos': photos,
      'statut': statut,
      'date_resolution': dateResolution?.toIso8601String(),
      'commentaire_resolution': commentaireResolution,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'numero_chambre': numeroChambre,
      'type_chambre': typeChambre,
      'nom_centre': nomCentre,
      'ville': ville,
      'centre_id': centreId,
      'nom': nom,
      'prenom': prenom,
      'matricule': matricule,
      'telephone': telephone,
      'email': email,
    };
  }

  /// Retourne une nouvelle instance de [Signalement] avec les propriétés spécifiées mises à jour.
  Signalement copyWith({
    int? id,
    String? numeroSuivi,
    String? typeProbleme,
    String? description,
    List<String>? photos,
    String? statut,
    DateTime? dateResolution,
    String? commentaireResolution,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? numeroChambre,
    String? typeChambre,
    String? nomCentre,
    String? ville,
    int? centreId,
    String? nom,
    String? prenom,
    String? matricule,
    String? telephone,
    String? email,
  }) {
    return Signalement(
      id: id ?? this.id,
      numeroSuivi: numeroSuivi ?? this.numeroSuivi,
      typeProbleme: typeProbleme ?? this.typeProbleme,
      description: description ?? this.description,
      photos: photos ?? this.photos,
      statut: statut ?? this.statut,
      dateResolution: dateResolution ?? this.dateResolution,
      commentaireResolution: commentaireResolution ?? this.commentaireResolution,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      numeroChambre: numeroChambre ?? this.numeroChambre,
      typeChambre: typeChambre ?? this.typeChambre,
      nomCentre: nomCentre ?? this.nomCentre,
      ville: ville ?? this.ville,
      centreId: centreId ?? this.centreId,
      nom: nom ?? this.nom,
      prenom: prenom ?? this.prenom,
      matricule: matricule ?? this.matricule,
      telephone: telephone ?? this.telephone,
      email: email ?? this.email,
    );
  }
}