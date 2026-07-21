import 'package:flutter/material.dart';
import '../../../config/theme.dart';
import '../../../utils/mobile_responsive.dart';

/// Message flottant de confirmation ou d'erreur.
///
/// [context] doit rester valide au moment de l'appel : depuis un dialogue,
/// passer le contexte de l'écran et non celui du dialogue, qui ne vaut plus
/// rien une fois le dialogue fermé.
void afficherSnack(BuildContext context, String message,
    {Color bg = Colors.orange}) {
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
    content: Text(message),
    backgroundColor: bg,
    behavior: SnackBarBehavior.floating,
  ));
}

/// Séparateur horizontal des listes de réglages.
Widget settingsDivider(bool isDark) => Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Divider(
          height: 0,
          thickness: 1,
          color: isDark ? Colors.grey.shade800 : Colors.grey[300]),
    );

class SettingsSectionTitle extends StatelessWidget {
  final String text;
  final bool isDark;
  final ResponsiveConfig config;
  const SettingsSectionTitle(
      {super.key,
      required this.text,
      required this.isDark,
      required this.config});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(text,
          style: TextStyle(
              fontSize: config.responsive(small: 13, medium: 15, large: 16),
              fontWeight: FontWeight.w600,
              color: isDark
                  ? Colors.blue.shade300
                  : Theme.of(context).colorScheme.primary)),
    );
  }
}

class SettingsCard extends StatelessWidget {
  final bool isDark;
  final List<Widget> children;
  const SettingsCard({super.key, required this.isDark, required this.children});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: isDark ? 4 : 2,
      color: isDark ? const Color(0xFF1E1E1E) : null,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Column(children: children),
    );
  }
}

class SettingTile extends StatelessWidget {
  final IconData icon;
  final String title, subtitle;
  final VoidCallback onTap;
  final bool isDark;
  final ResponsiveConfig config;
  const SettingTile(
      {super.key,
      required this.icon,
      required this.title,
      required this.subtitle,
      required this.onTap,
      required this.isDark,
      required this.config});

  @override
  Widget build(BuildContext context) {
    final iconSize = config.responsive(small: 20, medium: 22, large: 24);
    final titleSize = config.responsive(small: 13, medium: 14, large: 15);
    final subSize = config.responsive(small: 10, medium: 11, large: 12);
    final iconPad = config.responsive(small: 8, medium: 10, large: 11);

    return ListTile(
      onTap: onTap,
      leading: Container(
        padding: EdgeInsets.all(iconPad),
        decoration: BoxDecoration(
          color: isDark
              ? AppTheme.primaryColor.withOpacity(0.2)
              : AppTheme.primaryColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon,
            size: iconSize,
            color: isDark ? Colors.blue.shade300 : AppTheme.primaryColor),
      ),
      title: Text(title,
          style: TextStyle(
              fontWeight: FontWeight.w500,
              fontSize: titleSize,
              color: isDark ? Colors.white : Colors.black87)),
      subtitle: Text(subtitle,
          style: TextStyle(
              fontSize: subSize,
              color: isDark ? Colors.grey.shade400 : Colors.grey[600])),
      trailing: Icon(Icons.chevron_right_rounded,
          color: isDark ? Colors.grey.shade600 : Colors.grey,
          size: config.responsive(small: 18, medium: 20, large: 22)),
    );
  }
}
