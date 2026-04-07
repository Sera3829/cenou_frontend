// lib/widgets/custom_text_field.dart
import 'package:flutter/material.dart';
import '../config/theme.dart';

class CustomTextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final IconData? prefixIcon;
  final Widget? suffixIcon;
  final bool obscureText;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;
  final int? maxLines;
  final int? maxLength;
  final String? errorText;
  final Color? borderColor;
  final Function(String)? onChanged;
  final Function()? onTap;
  final bool readOnly;
  final bool? enabled;
  final TextInputAction? textInputAction;
  final FocusNode? focusNode;
  final Color? labelColor;
  final void Function(String)? onFieldSubmitted;
  final Iterable<String>? autofillHints;
  final TextCapitalization textCapitalization;

  const CustomTextField({
    Key? key,
    required this.controller,
    required this.label,
    required this.hint,
    this.prefixIcon,
    this.suffixIcon,
    this.obscureText = false,
    this.keyboardType,
    this.validator,
    this.maxLines = 1,
    this.maxLength,
    this.errorText,
    this.borderColor,
    this.onChanged,
    this.onTap,
    this.readOnly = false,
    this.enabled,
    this.textInputAction,
    this.focusNode,
    this.labelColor,
    this.onFieldSubmitted,
    this.autofillHints,
    this.textCapitalization = TextCapitalization.none,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final bool hasExternalError = errorText != null && errorText!.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: hasExternalError
                ? AppTheme.errorColor
                : (labelColor ?? theme.textTheme.bodyLarge?.color),
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          obscureText: obscureText,
          keyboardType: keyboardType,
          maxLines: maxLines,
          maxLength: maxLength,
          readOnly: readOnly,
          enabled: enabled ?? true,
          textInputAction: textInputAction,
          focusNode: focusNode,
          onChanged: onChanged,
          onTap: onTap,
          onFieldSubmitted: onFieldSubmitted,
          autofillHints: autofillHints,
          textCapitalization: textCapitalization,
          validator: validator,
          style: TextStyle(
            color: (enabled == false) ? Colors.grey[600] : theme.textTheme.bodyLarge?.color,
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: Colors.grey[400]),
            prefixIcon: prefixIcon != null
                ? Icon(prefixIcon, color: Colors.grey[600])
                : null,
            suffixIcon: suffixIcon,
            filled: true,
            fillColor: (enabled == false)
                ? (isDark ? Colors.grey[800] : Colors.grey[100])
                : (isDark ? Colors.grey[900] : Colors.grey[50]),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: borderColor ?? Colors.grey[300]!,
                width: 1,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: borderColor ?? Colors.grey[300]!,
                width: 1,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: borderColor ?? AppTheme.primaryColor,
                width: 2,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppTheme.errorColor, width: 2),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppTheme.errorColor, width: 2),
            ),
            contentPadding: EdgeInsets.symmetric(
              horizontal: 16,
              vertical: maxLines != null && maxLines! > 1 ? 12 : 16,
            ),
            counterText: maxLength != null ? null : '',
            errorStyle: const TextStyle(fontSize: 12, color: AppTheme.errorColor),
            errorMaxLines: 2,
          ),
        ),
        if (hasExternalError) ...[
          const SizedBox(height: 6),
          Padding(
            padding: const EdgeInsets.only(left: 16.0),
            child: Row(
              children: [
                const Icon(Icons.error_outline, size: 14, color: AppTheme.errorColor),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    errorText!,
                    style: const TextStyle(fontSize: 12, color: AppTheme.errorColor),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}