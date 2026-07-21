import 'package:flutter/material.dart';

/// Couple couleur + icône décrivant un statut (confirmé, en attente, résolu…).
///
/// Chaque écran garde sa propre table de correspondance métier ; seul le
/// contenant est partagé.
class StatusInfo {
  final Color color;
  final IconData icon;
  const StatusInfo(this.color, this.icon);
}

/// Petite information secondaire d'une carte de liste : date, référence,
/// mode de paiement… Icône discrète suivie d'un libellé.
class MetaChip extends StatelessWidget {
  final IconData icon;
  final String text;
  final bool isDark;
  final double fontSize;

  const MetaChip({
    super.key,
    required this.icon,
    required this.text,
    required this.isDark,
    required this.fontSize,
  });

  @override
  Widget build(BuildContext context) {
    final color = isDark ? Colors.grey.shade400 : Colors.grey[600]!;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 12, color: color),
        const SizedBox(width: 4),
        Text(
          text,
          style: TextStyle(
            fontSize: fontSize,
            color: color,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
