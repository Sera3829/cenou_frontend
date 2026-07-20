import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cenou_mobile/l10n/app_localizations.dart';

/// Helpers de présentation pour les signalements (libellés, couleurs, dates). Purs.

String formatSignalementDate(DateTime d, AppLocalizations l10n) =>
    DateFormat('dd/MM/yy HH:mm', l10n.locale.languageCode).format(d);

String formatSignalementDateOnly(DateTime d, AppLocalizations l10n) =>
    DateFormat('dd/MM/yyyy', l10n.locale.languageCode).format(d);

String signalementStatutLabel(String s, AppLocalizations l10n) {
  switch (s) {
    case 'EN_ATTENTE':
      return l10n.pendingStatus;
    case 'EN_COURS':
      return l10n.inProgressStatus;
    case 'RESOLU':
      return l10n.resolvedStatus;
    case 'ANNULE':
      return l10n.cancelledStatus;
    case 'TOUS':
      return l10n.all;
    default:
      return s;
  }
}

Color signalementStatutColor(String s) {
  const map = {
    'EN_ATTENTE': Color(0xFFF59E0B),
    'EN_COURS': Color(0xFF3B82F6),
    'RESOLU': Color(0xFF10B981),
    'ANNULE': Color(0xFFEF4444),
  };
  return map[s] ?? const Color(0xFF64748B);
}

String signalementTypeLabel(String t, AppLocalizations l10n) {
  switch (t) {
    case 'PLOMBERIE':
      return l10n.plumbing;
    case 'ELECTRICITE':
      return l10n.electricity;
    case 'TOITURE':
      return l10n.roofing;
    case 'SERRURE':
      return l10n.locks;
    case 'MOBILIER':
      return l10n.furniture;
    case 'AUTRE':
      return l10n.other;
    case 'TOUS':
      return l10n.all;
    default:
      return t;
  }
}

Color signalementTypeColor(String t) {
  const map = {
    'PLOMBERIE': Color(0xFF3B82F6),
    'ELECTRICITE': Color(0xFFF59E0B),
    'TOITURE': Color(0xFF8B5CF6),
    'SERRURE': Color(0xFFEF4444),
    'MOBILIER': Color(0xFF10B981),
    'AUTRE': Color(0xFF64748B),
  };
  return map[t] ?? const Color(0xFF64748B);
}
