import 'package:flutter/material.dart';
import '../../../utils/mobile_responsive.dart';

// ──────────────────────────────────────────────────────────────
// Titre de section
// ──────────────────────────────────────────────────────────────

class SectionTitle extends StatelessWidget {
  final String text;
  final bool isDark;
  final ResponsiveConfig config;

  const SectionTitle({
    super.key,
    required this.text,
    required this.isDark,
    required this.config,
  });

  @override
  Widget build(BuildContext context) {
    final fontSize = config.responsive(small: 15, medium: 17, large: 19);
    return Text(
      text,
      style: TextStyle(
        fontSize: fontSize,
        fontWeight: FontWeight.w700,
        color: isDark ? Colors.white : Colors.grey[800],
      ),
    );
  }
}

