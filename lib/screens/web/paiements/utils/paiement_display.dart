import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cenou_mobile/l10n/app_localizations.dart';

/// Helpers de présentation pour les paiements (montant, libellés, couleurs). Purs.

String formatMontant(double montant, AppLocalizations l10n) {
  final formatter = NumberFormat('#,##0', l10n.locale.languageCode);
  return formatter.format(montant);
}

String paiementStatutLabel(String statut, AppLocalizations l10n) {
  switch (statut) {
    case 'EN_ATTENTE':
      return l10n.pendingStatus;
    case 'CONFIRME':
      return l10n.confirmedStatus;
    case 'ECHEC':
      return l10n.failedStatus;
    case 'TOUS':
      return l10n.all;
    default:
      return statut;
  }
}

Color paiementStatutColor(String statut) {
  switch (statut) {
    case 'EN_ATTENTE':
      return const Color(0xFFF59E0B);
    case 'CONFIRME':
      return const Color(0xFF10B981);
    case 'ECHEC':
      return const Color(0xFFEF4444);
    default:
      return const Color(0xFF64748B);
  }
}

String paiementModeLabel(String mode, AppLocalizations l10n) {
  switch (mode) {
    case 'ORANGE_MONEY':
      return l10n.orangeMoney;
    case 'MOOV_MONEY':
      return l10n.moovMoney;
    case 'ESPECES':
      return l10n.cash;
    case 'VIREMENT':
      return l10n.transfer;
    case 'TOUS':
      return l10n.all;
    default:
      return mode;
  }
}
