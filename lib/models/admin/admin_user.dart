/// Modèle représentant un utilisateur administratif ou un profil utilisateur complet.
class AdminUser {
  final int id;
  final String matricule;
  final String nom;
  final String prenom;
  final String email;
  final String telephone;
  final String role;
  final String statut;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final String? centreNom;
  final String? numeroChambre;

  AdminUser({
    required this.id,
    required this.matricule,
    required this.nom,
    required this.prenom,
    required this.email,
    required this.telephone,
    required this.role,
    required this.statut,
    required this.createdAt,
    this.updatedAt,
    this.centreNom,
    this.numeroChambre,
  });

  /// Désérialise une structure JSON pour instancier un objet [AdminUser].
  /// Assure la robustesse via des valeurs par défaut en cas d'attributs manquants.
  factory AdminUser.fromJson(Map<String, dynamic> json) {
    return AdminUser(
      id: json['id'] ?? 0,
      matricule: json['matricule'] ?? '',
      nom: json['nom'] ?? '',
      prenom: json['prenom'] ?? '',
      email: json['email'] ?? '',
      telephone: json['telephone'] ?? '',
      role: json['role'] ?? '',
      statut: json['statut'] ?? 'ACTIF',
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: json['updated_at'] != null ? DateTime.parse(json['updated_at']) : null,
      centreNom: json['centre_nom'],
      numeroChambre: json['numero_chambre'],
    );
  }

  /// Retourne une nouvelle instance de [AdminUser] avec les attributs spécifiés modifiés.
  /// Utilisé pour la gestion d'état immuable.
  AdminUser copyWith({
    int? id,
    String? matricule,
    String? nom,
    String? prenom,
    String? email,
    String? telephone,
    String? role,
    String? statut,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? centreNom,
    String? numeroChambre,
  }) {
    return AdminUser(
      id: id ?? this.id,
      matricule: matricule ?? this.matricule,
      nom: nom ?? this.nom,
      prenom: prenom ?? this.prenom,
      email: email ?? this.email,
      telephone: telephone ?? this.telephone,
      role: role ?? this.role,
      statut: statut ?? this.statut,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      centreNom: centreNom ?? this.centreNom,
      numeroChambre: numeroChambre ?? this.numeroChambre,
    );
  }

  /// Concatène le prénom et le nom pour l'affichage de l'identité complète.
  String get fullName => '$prenom $nom';

  /// Prédicats d'état et de rôles pour la logique métier.
  bool get isActive => statut == 'ACTIF';
  bool get isStudent => role == 'ETUDIANT';
  bool get isAdmin => role == 'ADMIN';
  bool get isGestionnaire => role == 'GESTIONNAIRE';
}