/// Modèle représentant un centre de gestion ou une résidence au sein du système.
class Centre {
  final int id;
  final String nom;
  final String? ville;
  final String? adresse;
  final int? capaciteTotale;
  final DateTime? createdAt;

  Centre({
    required this.id,
    required this.nom,
    this.ville,
    this.adresse,
    this.capaciteTotale,
    this.createdAt,
  });

  /// Initialise une instance de [Centre] à partir d'un dictionnaire JSON.
  factory Centre.fromJson(Map<String, dynamic> json) {
    return Centre(
      id: json['id'] as int,
      nom: json['nom'] as String,
      ville: json['ville'] as String?,
      adresse: json['adresse'] as String?,
      capaciteTotale: json['capacite_totale'] as int?,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
    );
  }

  /// Sérialise l'instance actuelle en un dictionnaire [Map] pour les transferts de données.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nom': nom,
      'ville': ville,
      'adresse': adresse,
      'capacite_totale': capaciteTotale,
      'created_at': createdAt?.toIso8601String(),
    };
  }

  /// Retourne le nom du centre comme représentation textuelle de l'objet.
  @override
  String toString() => nom;
}