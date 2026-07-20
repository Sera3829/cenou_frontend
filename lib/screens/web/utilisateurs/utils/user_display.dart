import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cenou_mobile/l10n/app_localizations.dart';

/// Helpers de présentation pour les utilisateurs (libellés, couleurs, dates).
/// Purs — aucune dépendance à l'état de l'écran.

String userRoleLabel(String role, AppLocalizations l10n) {
  switch (role) {
    case 'ETUDIANT':
      return l10n.studentRole;
    case 'GESTIONNAIRE':
      return l10n.managerRole;
    case 'ADMIN':
      return l10n.adminRole;
    case 'TOUS':
      return l10n.all;
    default:
      return role;
  }
}

Color userRoleColor(String role) {
  const map = {
    'ETUDIANT': Color(0xFF3B82F6),
    'GESTIONNAIRE': Color(0xFF10B981),
    'ADMIN': Color(0xFF8B5CF6),
  };
  return map[role] ?? const Color(0xFF64748B);
}

String userStatutLabel(String statut, AppLocalizations l10n) {
  switch (statut) {
    case 'ACTIF':
      return l10n.activeStatus;
    case 'INACTIF':
      return l10n.inactiveStatus;
    case 'SUSPENDU':
      return l10n.suspendedStatus;
    case 'TOUS':
      return l10n.all;
    default:
      return statut;
  }
}

Color userStatutColor(String statut) {
  const map = {
    'ACTIF': Color(0xFF10B981),
    'INACTIF': Color(0xFFF59E0B),
    'SUSPENDU': Color(0xFFEF4444),
  };
  return map[statut] ?? const Color(0xFF64748B);
}

String formatUserDate(DateTime date, AppLocalizations l10n) =>
    DateFormat('dd/MM/yyyy', l10n.locale.languageCode).format(date);
