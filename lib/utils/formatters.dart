// lib/utils/formatters.dart
import 'dart:ui';
import 'package:intl/intl.dart';

/// Utilitaire de mise en forme des données.
class Formatters {
  /// Formate un montant en devise FCFA.
  ///
  /// [montant] : le montant à formater.
  /// Retourne une chaîne avec séparateurs de milliers (ex: 1 500 000).
  static String formatMontant(double montant) {
    final formatter = NumberFormat('#,##0', 'fr_FR');
    return formatter.format(montant);
  }

  /// Formate une date avec l'heure.
  ///
  /// [date] : la date à formater.
  /// Retourne une chaîne au format 'dd/MM/yyyy HH:mm'.
  static String formatDate(DateTime date) {
    return DateFormat('dd/MM/yyyy HH:mm').format(date);
  }

  /// Formate une date sans l'heure.
  ///
  /// [date] : la date à formater.
  /// Retourne une chaîne au format 'dd/MM/yyyy'.
  static String formatDateOnly(DateTime date) {
    return DateFormat('dd/MM/yyyy').format(date);
  }

  /// Convertit un code de statut en libellé lisible.
  ///
  /// [statut] : le code du statut (EN_ATTENTE, CONFIRME, ECHEC, etc.).
  static String formatStatut(String statut) {
    switch (statut) {
      case 'EN_ATTENTE': return 'En attente';
      case 'CONFIRME': return 'Confirmé';
      case 'ECHEC': return 'Échec';
      case 'TOUS': return 'Tous les statuts';
      default: return statut;
    }
  }

  /// Convertit un code de mode de paiement en libellé lisible.
  ///
  /// [mode] : le code du mode (ORANGE_MONEY, MOOV_MONEY, ESPECES, VIREMENT, etc.).
  static String formatModePaiement(String mode) {
    switch (mode) {
      case 'ORANGE_MONEY': return 'Orange Money';
      case 'MOOV_MONEY': return 'Moov Money';
      case 'ESPECES': return 'Espèces';
      case 'VIREMENT': return 'Virement bancaire';
      case 'TOUS': return 'Tous les modes';
      default: return mode;
    }
  }

  /// Retourne la couleur associée à un statut.
  ///
  /// [statut] : le code du statut.
  static Color getStatutColor(String statut) {
    switch (statut) {
      case 'EN_ATTENTE': return const Color(0xFFF59E0B);
      case 'CONFIRME': return const Color(0xFF10B981);
      case 'ECHEC': return const Color(0xFFEF4444);
      default: return const Color(0xFF64748B);
    }
  }
}