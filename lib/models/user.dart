/// Représente un utilisateur au sein du système CENOU.
class User {
  final int id;
  final String matricule;
  final String nom;
  final String prenom;
  final String email;
  final String? telephone;
  final String role;
  final String statut;
  final String? numeroChambre;
  final String? nomCentre;
  final int? loyerMensuel;

  User({
    required this.id,
    required this.matricule,
    required this.nom,
    required this.prenom,
    required this.email,
    this.telephone,
    required this.role,
    required this.statut,
    this.numeroChambre,
    this.nomCentre,
    this.loyerMensuel,
  });

  /// Retourne l'identité complète de l'utilisateur.
  String get nomComplet => '$nom $prenom';

  /// Génère les initiales de l'utilisateur à partir de son nom et de son prénom.
  String get initiales {
    final n = nom.isNotEmpty ? nom[0] : '';
    final p = prenom.isNotEmpty ? prenom[0] : '';
    return '$n$p'.toUpperCase();
  }

  /// Initialise une instance de [User] à partir d'une structure de données JSON.
  /// Gère explicitement la conversion des types et les valeurs par défaut.
  factory User.fromJson(Map<String, dynamic> json) {
    return User(
        id: json['id'] as int,
        matricule: json['matricule'] as String,
        nom: json['nom'] as String,
        prenom: json['prenom'] as String,
        email: json['email'] as String,
        telephone: json['telephone'] as String?,
        role: json['role'] as String,
        statut: json['statut'] as String? ?? 'ACTIF',
        numeroChambre: json['numero_chambre'] as String?,
        nomCentre: json['nom_centre'] as String?,
        loyerMensuel: json['loyer_mensuel'] as int?
    );
  }

  /// Sérialise l'instance actuelle en un dictionnaire [Map].
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'matricule': matricule,
      'nom': nom,
      'prenom': prenom,
      'email': email,
      'telephone': telephone, // Attribut optionnel
      'role': role,
      'statut': statut,
      'numero_chambre': numeroChambre,
      'nom_centre': nomCentre,
      'loyer_mensuel': loyerMensuel,
    };
  }

  /// Crée une copie de l'instance actuelle avec la possibilité de modifier certains attributs.
  User copyWith({
    int? id,
    String? matricule,
    String? nom,
    String? prenom,
    String? email,
    String? telephone,
    String? role,
    String? statut,
    String? numeroChambre,
    String? nomCentre,
    int? loyerMensuel,
  }) {
    return User(
      id: id ?? this.id,
      matricule: matricule ?? this.matricule,
      nom: nom ?? this.nom,
      prenom: prenom ?? this.prenom,
      email: email ?? this.email,
      telephone: telephone ?? this.telephone,
      role: role ?? this.role,
      statut: statut ?? this.statut,
      numeroChambre: numeroChambre ?? this.numeroChambre,
      nomCentre: nomCentre ?? this.nomCentre,
      loyerMensuel: loyerMensuel ?? this.loyerMensuel,
    );
  }
}