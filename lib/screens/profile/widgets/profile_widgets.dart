import 'package:flutter/material.dart';
import '../../../config/theme.dart';
import '../../../models/user.dart';
import '../../../utils/mobile_responsive.dart';
import '../../../l10n/app_localizations.dart';

class ProfileHeader extends StatelessWidget {
  final User user;
  final ResponsiveConfig config;
  final AppLocalizations l10n;
  const ProfileHeader(
      {super.key,
      required this.user,
      required this.config,
      required this.l10n});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final avatarRadius = config.responsive(small: 40, medium: 48, large: 56);
    final nameSize = config.responsive(small: 20, medium: 23, large: 26);
    final matSize = config.responsive(small: 13, medium: 14, large: 15);
    final vPad = config.responsive(small: 28, medium: 36, large: 44);

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: isDark
              ? [
                  AppTheme.primaryColor.withOpacity(0.7),
                  AppTheme.primaryColor.withOpacity(0.5)
                ]
              : [
                  AppTheme.primaryColor.withOpacity(0.9),
                  AppTheme.primaryColor.withOpacity(0.7)
                ],
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
      ),
      padding: EdgeInsets.fromLTRB(24, vPad, 24, vPad - 4),
      child: Column(children: [
        Stack(alignment: Alignment.bottomRight, children: [
          Container(
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border:
                  Border.all(color: Colors.white.withOpacity(0.3), width: 3),
            ),
            child: CircleAvatar(
              radius: avatarRadius,
              backgroundColor: Colors.white,
              child: Text(user.initiales,
                  style: TextStyle(
                      fontSize: avatarRadius * 0.7,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.primaryColor)),
            ),
          ),
          Container(
            padding: const EdgeInsets.all(5),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              border: Border.all(color: AppTheme.primaryColor, width: 2),
            ),
            child: Icon(_getStatusIcon(user.statut),
                size: 14, color: _getStatusColor(user.statut)),
          ),
        ]),
        SizedBox(height: config.isSmall ? 14 : 18),
        Text(user.nomComplet,
            style: TextStyle(
                fontSize: nameSize,
                fontWeight: FontWeight.w700,
                color: Colors.white),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis),
        const SizedBox(height: 4),
        Text(user.matricule,
            style: TextStyle(
                fontSize: matSize, color: Colors.white.withOpacity(0.9))),
        Container(
          margin: EdgeInsets.only(top: config.isSmall ? 8 : 12),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(_formatStatus(user.statut, l10n),
              style: TextStyle(
                  fontSize: config.responsive(small: 11, medium: 12, large: 13),
                  fontWeight: FontWeight.w600,
                  color: Colors.white)),
        ),
      ]),
    );
  }

  IconData _getStatusIcon(String s) {
    switch (s.toUpperCase()) {
      case 'ACTIF':
        return Icons.check_circle_rounded;
      case 'INACTIF':
        return Icons.pause_circle_rounded;
      case 'SUSPENDU':
        return Icons.block_rounded;
      default:
        return Icons.person_rounded;
    }
  }

  Color _getStatusColor(String s) {
    switch (s.toUpperCase()) {
      case 'ACTIF':
        return Colors.green;
      case 'INACTIF':
        return Colors.orange;
      case 'SUSPENDU':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _formatStatus(String s, AppLocalizations l10n) {
    switch (s.toUpperCase()) {
      case 'ACTIF':
        return l10n.statusActive;
      case 'INACTIF':
        return l10n.statusInactive;
      case 'SUSPENDU':
        return l10n.statusSuspended;
      default:
        return s;
    }
  }
}

class InfoTile extends StatelessWidget {
  final IconData icon;
  final String title, value;
  final Color color;
  final bool isDark;
  final ResponsiveConfig config;
  const InfoTile(
      {super.key,
      required this.icon,
      required this.title,
      required this.value,
      required this.color,
      required this.isDark,
      required this.config});

  @override
  Widget build(BuildContext context) {
    final iconSize = config.responsive(small: 18, medium: 20, large: 22);
    final iconPad = config.responsive(small: 8, medium: 10, large: 11);
    final labelSize = config.responsive(small: 11, medium: 12, large: 13);
    final valueSize = config.responsive(small: 14, medium: 15, large: 16);

    return Padding(
      padding: EdgeInsets.symmetric(
          vertical: config.isSmall ? 10 : 12, horizontal: 16),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          padding: EdgeInsets.all(iconPad),
          decoration: BoxDecoration(
            color: color.withOpacity(isDark ? 0.2 : 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon,
              size: iconSize, color: isDark ? color.withOpacity(0.7) : color),
        ),
        const SizedBox(width: 14),
        Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title,
              style: TextStyle(
                  fontSize: labelSize,
                  color: isDark ? Colors.grey.shade400 : Colors.grey[600],
                  fontWeight: FontWeight.w500)),
          const SizedBox(height: 3),
          Text(value,
              style: TextStyle(
                  fontSize: valueSize,
                  fontWeight: FontWeight.w500,
                  color: isDark ? Colors.white : Colors.black87),
              maxLines: 2,
              overflow: TextOverflow.ellipsis),
        ])),
      ]),
    );
  }
}

class ActionTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor, bgColor, tileBgColor;
  final String title;
  final String? subtitle;
  final bool isDark;
  final ResponsiveConfig config;
  final VoidCallback onTap;
  const ActionTile(
      {super.key,
      required this.icon,
      required this.iconColor,
      required this.title,
      required this.subtitle,
      required this.bgColor,
      required this.tileBgColor,
      required this.isDark,
      required this.config,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    final titleSize = config.responsive(small: 13, medium: 14, large: 15);
    final subSize = config.responsive(small: 10, medium: 11, large: 12);
    final iconPad = config.responsive(small: 8, medium: 10, large: 11);

    return ListTile(
      onTap: onTap,
      contentPadding: EdgeInsets.symmetric(
          horizontal: 16, vertical: config.isSmall ? 2 : 4),
      leading: Container(
        padding: EdgeInsets.all(iconPad),
        decoration: BoxDecoration(
            color: bgColor, borderRadius: BorderRadius.circular(12)),
        child: Icon(icon,
            color: iconColor,
            size: config.responsive(small: 18, medium: 21, large: 23)),
      ),
      title: Text(title,
          style: TextStyle(
              fontWeight: FontWeight.w500,
              fontSize: titleSize,
              color: isDark ? Colors.white : Colors.black87)),
      subtitle: subtitle != null
          ? Text(subtitle!,
              style: TextStyle(
                  fontSize: subSize,
                  color: isDark ? Colors.grey.shade400 : Colors.grey.shade600))
          : null,
      trailing: Icon(Icons.chevron_right_rounded,
          color: isDark ? Colors.grey.shade600 : Colors.grey),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      tileColor: tileBgColor,
    );
  }
}

class StatRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final bool isDark;
  final ResponsiveConfig config;
  const StatRow(
      {super.key,
      required this.icon,
      required this.label,
      required this.color,
      required this.isDark,
      required this.config});

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Icon(icon,
          color: color,
          size: config.responsive(small: 18, medium: 20, large: 22)),
      const SizedBox(width: 10),
      Expanded(
        child: Text(label,
            style: TextStyle(
                fontSize: config.responsive(small: 12, medium: 13, large: 14),
                color: isDark ? Colors.grey.shade300 : Colors.black87)),
      ),
    ]);
  }
}

class ProfileLoadingState extends StatelessWidget {
  final AppLocalizations l10n;
  const ProfileLoadingState({super.key, required this.l10n});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Center(
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryColor)),
      const SizedBox(height: 20),
      Text(l10n.loadingProfile,
          style: TextStyle(
              fontSize: 15,
              color: isDark ? Colors.grey.shade400 : Colors.grey[600])),
    ]));
  }
}
