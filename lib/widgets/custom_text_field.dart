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
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final bool hasError = errorText != null && errorText!.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: hasError ? AppTheme.errorColor : (labelColor ?? Colors.black87),
          ),
        ),
        const SizedBox(height: 8),
        TextField( // TextField au lieu de TextFormField
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
          style: TextStyle(
            color: (enabled == false) ? Colors.grey[600] : Colors.black,
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(
              color: Colors.grey[400],
            ),
            prefixIcon: prefixIcon != null
                ? Icon(
              prefixIcon,
              color: hasError
                  ? AppTheme.errorColor
                  : Colors.grey[600],
            )
                : null,
            suffixIcon: suffixIcon,
            filled: true,
            fillColor: (enabled == false)
                ? Colors.grey[100]
                : Colors.grey[50],
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: hasError
                    ? AppTheme.errorColor
                    : (borderColor ?? Colors.grey[300]!),
                width: hasError ? 2 : 1,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: hasError
                    ? AppTheme.errorColor
                    : (borderColor ?? Colors.grey[300]!),
                width: hasError ? 2 : 1,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: hasError
                    ? AppTheme.errorColor
                    : (borderColor ?? AppTheme.primaryColor),
                width: 2,
              ),
            ),
            contentPadding: EdgeInsets.symmetric(
              horizontal: 16,
              vertical: maxLines != null && maxLines! > 1 ? 12 : 16,
            ),
            // PAS de errorText dans InputDecoration
            counterText: maxLength != null ? null : '',
          ),
        ),
        // Message d'erreur EXTERNE au TextField
        if (hasError) ...[
          const SizedBox(height: 6),
          Padding(
            padding: const EdgeInsets.only(left: 16.0),
            child: Row(
              children: [
                const Icon(
                  Icons.error_outline,
                  size: 14,
                  color: AppTheme.errorColor,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    errorText!,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppTheme.errorColor,
                      height: 1.2,
                    ),
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