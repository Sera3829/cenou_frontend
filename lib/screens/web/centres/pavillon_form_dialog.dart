import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../config/theme.dart';
import '../../../l10n/app_localizations.dart';
import '../../../models/admin/centre_admin.dart';

/// Dialogue de création / édition d'un pavillon.
/// Retourne le corps prêt pour l'API ({nom, capacite}), ou null si annulé.
class PavillonFormDialog extends StatefulWidget {
  final AppLocalizations l10n;
  final Pavillon? pavillon; // null = création

  const PavillonFormDialog({Key? key, required this.l10n, this.pavillon}) : super(key: key);

  @override
  State<PavillonFormDialog> createState() => _PavillonFormDialogState();
}

class _PavillonFormDialogState extends State<PavillonFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nom;
  late final TextEditingController _capacite;

  bool get _isEdit => widget.pavillon != null;

  @override
  void initState() {
    super.initState();
    final p = widget.pavillon;
    _nom = TextEditingController(text: p?.nom ?? '');
    _capacite = TextEditingController(text: p != null ? p.capacite.toString() : '');
  }

  @override
  void dispose() {
    _nom.dispose();
    _capacite.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.pop(context, <String, dynamic>{
      'nom': _nom.text.trim(),
      'capacite': int.tryParse(_capacite.text.trim()) ?? 0,
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = widget.l10n;
    return AlertDialog(
      backgroundColor: AppTheme.getCardBackground(context),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Row(children: [
        Icon(_isEdit ? Icons.edit_rounded : Icons.dashboard_customize_rounded,
            color: AppTheme.primaryColor),
        const SizedBox(width: 10),
        Text(_isEdit ? l10n.editPavillon : l10n.newPavillon,
            style: TextStyle(color: AppTheme.getTextPrimary(context), fontSize: 18)),
      ]),
      content: SizedBox(
        width: 420,
        child: Form(
          key: _formKey,
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            _text(context, _nom, l10n.pavillonName, Icons.badge_rounded,
                validator: (v) => (v == null || v.trim().isEmpty) ? l10n.pavillonName : null),
            const SizedBox(height: 14),
            _text(context, _capacite, l10n.pavillonCapacity, Icons.grid_view_rounded,
                keyboard: TextInputType.number,
                formatters: [FilteringTextInputFormatter.digitsOnly],
                validator: (v) => (v == null || v.trim().isEmpty || (int.tryParse(v.trim()) ?? 0) <= 0)
                    ? l10n.pavillonCapacity : null),
          ]),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l10n.cancel, style: TextStyle(color: AppTheme.getTextSecondary(context))),
        ),
        ElevatedButton(
          onPressed: _submit,
          style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor, foregroundColor: Colors.white),
          child: Text(_isEdit ? l10n.save : l10n.create),
        ),
      ],
    );
  }

  Widget _text(BuildContext context, TextEditingController c, String label, IconData icon,
      {TextInputType? keyboard,
      List<TextInputFormatter>? formatters,
      String? Function(String?)? validator}) {
    return TextFormField(
      controller: c,
      keyboardType: keyboard,
      inputFormatters: formatters,
      style: TextStyle(color: AppTheme.getTextPrimary(context)),
      decoration: InputDecoration(
        labelText: '$label *',
        labelStyle: TextStyle(color: AppTheme.getTextSecondary(context)),
        prefixIcon: Icon(icon, color: AppTheme.getTextTertiary(context), size: 20),
        filled: true,
        fillColor: AppTheme.getDashboardBackground(context),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppTheme.getBorderColor(context)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppTheme.getBorderColor(context)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppTheme.primaryColor, width: 2),
        ),
      ),
      validator: validator,
    );
  }
}
