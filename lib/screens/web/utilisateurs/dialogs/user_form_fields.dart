import 'package:flutter/material.dart';
import 'package:cenou_mobile/config/theme.dart';

/// Champs de formulaire réutilisables par les dialogues utilisateur
/// (création / édition). Purs helpers de présentation.

InputDecoration userDropdownDecoration(
    BuildContext context, String label, IconData icon, bool isDark) {
  return InputDecoration(
    labelText: label,
    labelStyle: TextStyle(color: AppTheme.getTextSecondary(context)),
    prefixIcon: Icon(icon, color: AppTheme.getTextSecondary(context)),
    border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: AppTheme.getBorderColor(context))),
    enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: AppTheme.getBorderColor(context))),
    focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide:
            BorderSide(color: Theme.of(context).colorScheme.primary, width: 2)),
    filled: true,
    fillColor:
        isDark ? Colors.grey.shade900.withOpacity(0.3) : Colors.grey.shade50,
  );
}

Widget userFormField(
  BuildContext context, {
  required TextEditingController controller,
  required String label,
  String? hint,
  required IconData icon,
  required bool isDark,
  TextInputType? keyboardType,
  String? Function(String?)? validator,
}) {
  return TextFormField(
    controller: controller,
    keyboardType: keyboardType,
    decoration: InputDecoration(
      labelText: label,
      labelStyle: TextStyle(color: AppTheme.getTextSecondary(context)),
      hintText: hint,
      hintStyle: TextStyle(color: AppTheme.getTextTertiary(context)),
      prefixIcon: Icon(icon, color: AppTheme.getTextSecondary(context)),
      border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: AppTheme.getBorderColor(context))),
      enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: AppTheme.getBorderColor(context))),
      focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(
              color: Theme.of(context).colorScheme.primary, width: 2)),
      filled: true,
      fillColor:
          isDark ? Colors.grey.shade900.withOpacity(0.3) : Colors.grey.shade50,
    ),
    style: TextStyle(color: AppTheme.getTextPrimary(context)),
    validator: validator,
  );
}

Widget userPasswordField(
  BuildContext context, {
  required TextEditingController controller,
  required String label,
  required String hint,
  required bool isVisible,
  required bool isDark,
  required VoidCallback onToggle,
  IconData icon = Icons.lock,
  String? Function(String?)? validator,
}) {
  return TextFormField(
    controller: controller,
    obscureText: !isVisible,
    decoration: InputDecoration(
      labelText: label,
      labelStyle: TextStyle(color: AppTheme.getTextSecondary(context)),
      hintText: hint,
      hintStyle: TextStyle(color: AppTheme.getTextTertiary(context)),
      prefixIcon: Icon(icon, color: AppTheme.getTextSecondary(context)),
      suffixIcon: IconButton(
        icon: Icon(isVisible ? Icons.visibility : Icons.visibility_off,
            color: AppTheme.getTextSecondary(context)),
        onPressed: onToggle,
      ),
      border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: AppTheme.getBorderColor(context))),
      enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: AppTheme.getBorderColor(context))),
      focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(
              color: Theme.of(context).colorScheme.primary, width: 2)),
      filled: true,
      fillColor:
          isDark ? Colors.grey.shade900.withOpacity(0.3) : Colors.grey.shade50,
    ),
    style: TextStyle(color: AppTheme.getTextPrimary(context)),
    validator: validator,
  );
}
