import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../config/theme.dart';
import '../../../providers/auth_provider.dart';
import '../../../l10n/app_localizations.dart';
import '../widgets/settings_widgets.dart';

/// Dialogue de changement de mot de passe.

/// [context] doit être celui de l'écran, pas celui du dialogue : il sert encore
/// après la fermeture, pour l'indicateur de progression et le message final.
void showChangePasswordDialog(BuildContext context, AppLocalizations l10n) {
  final isDark = Theme.of(context).brightness == Brightness.dark;
  final oldCtrl = TextEditingController();
  final newCtrl = TextEditingController();
  final confCtrl = TextEditingController();
  final formKey = GlobalKey<FormState>();
  bool oldVis = false, newVis = false, confVis = false;

  showDialog(
    context: context,
    builder: (dialogCtx) => LayoutBuilder(
      builder: (ctx, constraints) {
        final fs = constraints.maxWidth < 360 ? 12.0 : 13.0;
        final sp = constraints.maxWidth < 360 ? 12.0 : 14.0;
        return Dialog(
          backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          insetPadding:
              const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: StatefulBuilder(
                builder: (sbCtx, setSt) => Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [
                        Icon(Icons.lock_reset_rounded,
                            color: isDark
                                ? Colors.blue.shade300
                                : AppTheme.primaryColor),
                        const SizedBox(width: 12),
                        Text(l10n.changePassword,
                            style: TextStyle(
                                fontSize: fs + 4,
                                fontWeight: FontWeight.bold,
                                color: isDark ? Colors.white : Colors.black87)),
                      ]),
                      const SizedBox(height: 16),
                      // Exigences
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50
                              .withOpacity(isDark ? 0.1 : 0.5),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                              color: isDark
                                  ? Colors.blue.shade700
                                  : Colors.blue.shade200),
                        ),
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(children: [
                                Icon(Icons.info_outline,
                                    size: 15,
                                    color: isDark
                                        ? Colors.blue.shade300
                                        : Colors.blue.shade700),
                                const SizedBox(width: 6),
                                Text(l10n.passwordReqs,
                                    style: TextStyle(
                                        fontSize: fs,
                                        fontWeight: FontWeight.bold,
                                        color: isDark
                                            ? Colors.blue.shade300
                                            : Colors.blue.shade700)),
                              ]),
                              const SizedBox(height: 6),
                              for (final r in [
                                l10n.pwdMin6,
                                l10n.pwdUppercase,
                                l10n.pwdDigit
                              ])
                                Padding(
                                  padding:
                                      const EdgeInsets.only(left: 6, top: 3),
                                  child: Row(children: [
                                    Icon(Icons.check_circle_outline,
                                        size: fs,
                                        color: isDark
                                            ? Colors.blue.shade300
                                            : Colors.blue.shade700),
                                    const SizedBox(width: 6),
                                    Text(r,
                                        style: TextStyle(
                                            fontSize: fs - 1,
                                            color: isDark
                                                ? Colors.blue.shade300
                                                : Colors.blue.shade700)),
                                  ]),
                                ),
                            ]),
                      ),
                      const SizedBox(height: 16),
                      _pwdField(
                          oldCtrl,
                          l10n.oldPassword,
                          oldVis,
                          isDark,
                          () => setSt(() => oldVis = !oldVis),
                          (v) =>
                              (v == null || v.isEmpty) ? l10n.required_ : null,
                          fs),
                      SizedBox(height: sp),
                      _pwdField(newCtrl, l10n.newPassword, newVis, isDark,
                          () => setSt(() => newVis = !newVis), (v) {
                        if (v == null || v.isEmpty) return l10n.required_;
                        if (v.length < 6) return l10n.pwdMin6err;
                        if (!RegExp(r"[A-Z]").hasMatch(v)) {
                          return l10n.pwdUppercaseErr;
                        }
                        if (!RegExp(r"[0-9]").hasMatch(v)) {
                          return l10n.pwdDigitErr;
                        }
                        return null;
                      }, fs),
                      SizedBox(height: sp),
                      _pwdField(
                          confCtrl,
                          l10n.confirmPassword,
                          confVis,
                          isDark,
                          () => setSt(() => confVis = !confVis),
                          (v) => v != newCtrl.text ? l10n.pwdMismatch : null,
                          fs),
                      const SizedBox(height: 20),
                      Row(mainAxisAlignment: MainAxisAlignment.end, children: [
                        TextButton(
                          onPressed: () {
                            for (final c in [oldCtrl, newCtrl, confCtrl]) {
                              c.dispose();
                            }
                            Navigator.pop(dialogCtx);
                          },
                          child: Text(l10n.cancel,
                              style: TextStyle(
                                  fontSize: fs,
                                  color: isDark
                                      ? Colors.grey.shade400
                                      : Colors.grey.shade700)),
                        ),
                        const SizedBox(width: 12),
                        ElevatedButton(
                          onPressed: () async {
                            if (!formKey.currentState!.validate()) return;
                            Navigator.pop(dialogCtx);
                            showDialog(
                              context: context,
                              barrierDismissible: false,
                              builder: (_) => const Center(
                                  child: CircularProgressIndicator(
                                      color: Colors.green, strokeWidth: 3)),
                            );
                            try {
                              final auth = Provider.of<AuthProvider>(context,
                                  listen: false);
                              final ok = await auth.changePassword(
                                ancienMotDePasse: oldCtrl.text,
                                nouveauMotDePasse: newCtrl.text,
                                confirmationNouveauMotDePasse: confCtrl.text,
                              );
                              // L'appel réseau peut avoir survécu à l'écran :
                              // sans contexte valide, plus rien à fermer ni à
                              // afficher. Le `finally` libère quand même les
                              // contrôleurs.
                              if (!context.mounted) return;

                              Navigator.pop(context);
                              afficherSnack(
                                  context,
                                  ok
                                      ? l10n.passwordChanged
                                      : auth.errorMessage ?? l10n.error,
                                  bg: ok ? Colors.green : Colors.red);
                            } catch (e) {
                              if (!context.mounted) return;

                              Navigator.pop(context);
                              afficherSnack(context, '${l10n.error}: $e',
                                  bg: Colors.red);
                            } finally {
                              for (final c in [oldCtrl, newCtrl, confCtrl]) {
                                c.dispose();
                              }
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: isDark
                                ? Colors.blue.shade700
                                : AppTheme.primaryColor,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                          ),
                          child: Text(l10n.change),
                        ),
                      ]),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    ),
  );
}

Widget _pwdField(
    TextEditingController ctrl,
    String label,
    bool visible,
    bool isDark,
    VoidCallback onToggle,
    String? Function(String?) validator,
    double fs) {
  return TextFormField(
    controller: ctrl,
    obscureText: !visible,
    style:
        TextStyle(fontSize: fs, color: isDark ? Colors.white : Colors.black87),
    decoration: InputDecoration(
      labelText: label,
      labelStyle: TextStyle(
          fontSize: fs,
          color: isDark ? Colors.grey.shade400 : Colors.grey.shade700),
      prefixIcon: Icon(Icons.lock_outline,
          size: fs + 2,
          color: isDark ? Colors.grey.shade400 : Colors.grey.shade600),
      suffixIcon: IconButton(
        icon: Icon(visible ? Icons.visibility : Icons.visibility_off,
            size: fs + 2,
            color: isDark ? Colors.grey.shade400 : Colors.grey.shade600),
        onPressed: onToggle,
      ),
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
