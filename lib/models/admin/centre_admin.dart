/// Centre enrichi de statistiques d'occupation (vue admin).
class CentreAdmin {
  final int id;
  final String nom;
  final String ville;
  final String? adresse;
  final int capaciteTotale;
  final int totalLogements;
  final int logementsOccupes;
  final int logementsDisponibles;
  final int logementsMaintenance;
  final int residents;

  CentreAdmin({
    required this.id,
    required this.nom,
    required this.ville,
    this.adresse,
    required this.capaciteTotale,
    required this.totalLogements,
    required this.logementsOccupes,
    required this.logementsDisponibles,
    required this.logementsMaintenance,
    required this.residents,
  });

  /// Taux d'occupation en pourcentage (0 si aucune chambre).
  double get tauxOccupation =>
      totalLogements == 0 ? 0 : (logementsOccupes / totalLogements) * 100;

  static int _toInt(dynamic v) =>
      v == null ? 0 : (v is int ? v : int.tryParse(v.toString()) ?? 0);

  factory CentreAdmin.fromJson(Map<String, dynamic> json) {
    return CentreAdmin(
      id: json['id'] as int,
      nom: json['nom'] as String,
      ville: (json['ville'] ?? '') as String,
      adresse: json['adresse'] as String?,
      capaciteTotale: _toInt(json['capacite_totale']),
      totalLogements: _toInt(json['total_logements']),
      logementsOccupes: _toInt(json['logements_occupes']),
      logementsDisponibles: _toInt(json['logements_disponibles']),
      logementsMaintenance: _toInt(json['logements_maintenance']),
      residents: _toInt(json['residents']),
    );
  }
}

/// Chambre (logement) d'un centre, avec l'occupant actif éventuel.
class Chambre {
  final int id;
  final String numeroChambre;
  final String typeChambre;
  final int prixMensuel;
  final String statut;
  final String? occupantNomComplet;
  final String? occupantMatricule;

  Chambre({
    required this.id,
    required this.numeroChambre,
    required this.typeChambre,
    required this.prixMensuel,
    required this.statut,
    this.occupantNomComplet,
    this.occupantMatricule,
  });

  bool get estOccupee => statut == 'OCCUPE';

  factory Chambre.fromJson(Map<String, dynamic> json) {
    final nom = json['occupant_nom'];
    final prenom = json['occupant_prenom'];
    final complet = (nom != null || prenom != null)
        ? '${prenom ?? ''} ${nom ?? ''}'.trim()
        : null;
    return Chambre(
      id: json['id'] as int,
      numeroChambre: (json['numero_chambre'] ?? '') as String,
      typeChambre: (json['type_chambre'] ?? '') as String,
      prixMensuel: json['prix_mensuel'] == null
          ? 0
          : (json['prix_mensuel'] is int
              ? json['prix_mensuel'] as int
              : int.tryParse(json['prix_mensuel'].toString()) ?? 0),
      statut: (json['statut'] ?? 'DISPONIBLE') as String,
      occupantNomComplet: complet,
      occupantMatricule: json['occupant_matricule'] as String?,
    );
  }
}
