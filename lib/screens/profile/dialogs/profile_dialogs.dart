import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../config/theme.dart';
import '../../../providers/auth_provider.dart';
import '../../../models/user.dart';
import '../../../utils/session_reset.dart';
import '../../../l10n/app_localizations.dart';

void showEditProfileDialog(
    BuildContext context, User? user, bool isDark, AppLocalizations l10n) {
  if (user == null) return;
  final emailCtrl = TextEditingController(text: user.email);
  final telephoneCtrl = TextEditingController(text: user.telephone ?? '');
  final formKey = GlobalKey<FormState>();

  showDialog(
    context: context,
    builder: (dialogCtx) => Dialog(
      backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // En-tête
              Row(children: [
                Icon(Icons.edit_rounded,
                    color:
                        isDark ? Colors.blue.shade300 : AppTheme.primaryColor),
                const SizedBox(width: 12),
                Text(l10n.editProfile,
                    style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : Colors.black87)),
              ]),
              const SizedBox(height: 20),
              // Info non modifiable
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50.withOpacity(isDark ? 0.1 : 0.5),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                      color:
                          isDark ? Colors.blue.shade700 : Colors.blue.shade200),
                ),
                child: Row(children: [
                  Icon(Icons.info_outline,
                      size: 18,
                      color:
                          isDark ? Colors.blue.shade300 : Colors.blue.shade700),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      l10n.nameNotEditable,
                      style: TextStyle(
                          fontSize: 12,
                          color: isDark
                              ? Colors.blue.shade300
                              : Colors.blue.shade700),
                    ),
                  ),
                ]),
              ),
              const SizedBox(height: 16),
              // Formulaire
              Form(
                key: formKey,
                child: Column(children: [
                  _buildDialogField(emailCtrl, l10n.email, Icons.email_outlined,
                      isDark, TextInputType.emailAddress, (v) {
                    if (v == null || v.isEmpty) return l10n.emailRequired;
                    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
                        .hasMatch(v)) {
                      return l10n.emailInvalid;
                    }
                    return null;
                  }),
                  const SizedBox(height: 14),
                  _buildDialogField(telephoneCtrl, l10n.phoneOptional,
                      Icons.phone_outlined, isDark, TextInputType.phone, (v) {
                    if (v != null && v.isNotEmpty && v.length < 8) {
                      return l10n.phoneMin;
                    }
                    return null;
                  }),
                ]),
              ),
              const SizedBox(height: 20),
              // Boutons
              Row(mainAxisAlignment: MainAxisAlignment.end, children: [
                TextButton(
                  onPressed: () {
                    emailCtrl.dispose();
                    telephoneCtrl.dispose();
                    Navigator.pop(dialogCtx);
                  },
                  child: Text(l10n.cancel,
                      style: TextStyle(
                          color: isDark
                              ? Colors.grey.shade400
                              : Colors.grey.shade700)),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: () async {
                    if (!formKey.currentState!.validate()) return;
                    Navigator.pop(dialogCtx);
                    await _runWithLoader(context, isDark, () async {
                      final auth =
                          Provider.of<AuthProvider>(context, listen: false);
                      final ok = await auth.updateProfile(
                        email: emailCtrl.text.trim(),
                        telephone: telephoneCtrl.text.trim().isEmpty
                            ? null
                            : telephoneCtrl.text.trim(),
                      );
                      emailCtrl.dispose();
                      telephoneCtrl.dispose();
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                          content: Text(ok
                              ? l10n.profileUpdated
                              : auth.errorMessage ?? l10n.error),
                          backgroundColor: ok ? Colors.green : Colors.red,
                          behavior: SnackBarBehavior.floating,
                        ));
                      }
                    });
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        isDark ? Colors.blue.shade700 : AppTheme.primaryColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text(l10n.save),
                ),
              ]),
            ],
          ),
        ),
      ),
    ),
  );
}

Widget _buildDialogField(
    TextEditingController ctrl,
    String label,
    IconData icon,
    bool isDark,
    TextInputType keyboardType,
    String? Function(String?) validator) {
  return TextFormField(
    controller: ctrl,
    keyboardType: keyboardType,
    style: TextStyle(color: isDark ? Colors.white : Colors.black87),
    decoration: InputDecoration(
      labelText: label,
      labelStyle: TextStyle(
          color: isDark ? Colors.grey.shade400 : Colors.grey.shade700),
      prefixIcon: Icon(icon,
          color: isDark ? Colors.grey.shade400 : Colors.grey.shade600),
      filled: true,
      fillColor: isDark ? const Color(0xFF2D2D2D) : Colors.grey.shade50,
      border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
              color: isDark ? Colors.grey.shade700 : Colors.grey.shade300)),
      enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
              color: isDark ? Colors.grey.shade700 : Colors.grey.shade300)),
      focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
              color: isDark ? Colors.blue.shade300 : AppTheme.primaryColor,
              width: 2)),
    ),
    validator: validator,
  );
}

Future<void> _runWithLoader(
    BuildContext context, bool isDark, Future<void> Function() task) async {
  final l10n = AppLocalizations.of(context);
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (_) => PopScope(
      canPop: false,
      child: Center(
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
              borderRadius: BorderRadius.circular(16)),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            CircularProgressIndicator(color: AppTheme.primaryColor),
            const SizedBox(height: 16),
            Text(l10n.updatingProfile,
                style:
                    TextStyle(color: isDark ? Colors.white : Colors.black87)),
          ]),
        ),
      ),
    ),
  );
  try {
    await task();
  } finally {
    if (context.mounted) Navigator.pop(context);
  }
}

// ── Dialogue déconnexion ────────────────────────────────────────────────
Future<void> showLogoutDialog(
  BuildContext context,
  AuthProvider authProvider,
  bool isDark,
  AppLocalizations l10n,
) async {
  final result = await showDialog<bool>(
    context: context,
    useRootNavigator: true,
    builder: (ctx) => AlertDialog(
      backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Row(children: [
        Icon(Icons.logout_rounded,
            color: isDark ? Colors.red.shade300 : Colors.red),
        const SizedBox(width: 12),
        Text(l10n.logoutTitle,
            style: TextStyle(color: isDark ? Colors.white : Colors.black87)),
      ]),
      content: Text(
        l10n.logoutConfirm,
        style: TextStyle(
            color: isDark ? Colors.grey.shade300 : Colors.grey.shade700),
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.cancel)),
        ElevatedButton(
          onPressed: () => Navigator.pop(ctx, true),
          style: ElevatedButton.styleFrom(
              backgroundColor:
                  isDark ? Colors.red.shade700 : AppTheme.errorColor),
          child: Text(l10n.logoutButton,
              style: const TextStyle(color: Colors.white)),
        ),
      ],
    ),
  );

  if (result != true || !context.mounted) return;

  // Montrer loader
  showDialog(
    context: context,
    barrierDismissible: false,
    useRootNavigator: true,
    builder: (_) => PopScope(
      canPop: false,
      child: Center(
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
              borderRadius: BorderRadius.circular(16)),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            CircularProgressIndicator(color: AppTheme.primaryColor),
            const SizedBox(height: 16),
            Text(l10n.loggingOut,
                style:
                    TextStyle(color: isDark ? Colors.white : Colors.black87)),
          ]),
        ),
      ),
    ),
  );

  if (result != true || !context.mounted) return;

  // Garde-fou anti-fuite : vide l'état des providers avant de déconnecter.
  resetUserSession(context);
  try {
    await authProvider.logout();
  } catch (_) {}

  if (!context.mounted) return;

  Navigator.of(context, rootNavigator: true)
      .pushNamedAndRemoveUntil('/login', (route) => false);
}
