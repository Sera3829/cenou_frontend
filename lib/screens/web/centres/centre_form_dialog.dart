import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../config/theme.dart';
import '../../../l10n/app_localizations.dart';
import '../../../models/admin/centre_admin.dart';

/// Dialogue de création / édition d'un centre.
/// Retourne le corps prêt pour l'API, ou null si annulé.
class CentreFormDialog extends StatefulWidget {
  final AppLocalizations l10n;
  final CentreAdmin? centre; // null = création

  const CentreFormDialog({Key? key, required this.l10n, this.centre}) : super(key: key);

  @override
  State<CentreFormDialog> createState() => _CentreFormDialogState();
}

class _CentreFormDialogState extends State<CentreFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nom;
  late final TextEditingController _ville;
  late final TextEditingController _adresse;
  late final TextEditingController _capacite;

  bool get _isEdit => widget.centre != null;

  @override
  void initState() {
    super.initState();
    final c = widget.centre;
    _nom = TextEditingController(text: c?.nom ?? '');
    _ville = TextEditingController(text: c?.ville ?? '');
    _adresse = TextEditingController(text: c?.adresse ?? '');
    _capacite = TextEditingController(text: c != null ? c.capaciteTotale.toString() : '');
  }

  @override
  void dispose() {
    _nom.dispose();
    _ville.dispose();
    _adresse.dispose();
    _capacite.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    final body = <String, dynamic>{
      'nom': _nom.text.trim(),
      'ville': _ville.text.trim(),
      'adresse': _adresse.text.trim().isEmpty ? null : _adresse.text.trim(),
    };
    if (_capacite.text.trim().isNotEmpty) {
      body['capacite_totale'] = int.tryParse(_capacite.text.trim()) ?? 0;
    }
    Navigator.pop(context, body);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = widget.l10n;
    return AlertDialog(
      backgroundColor: AppTheme.getCardBackground(context),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Row(
        children: [
          Icon(_isEdit ? Icons.edit_rounded : Icons.add_business_rounded,
              color: AppTheme.primaryColor),
          const SizedBox(width: 10),
          Text(_isEdit ? l10n.editCentre : l10n.newCentre,
              style: TextStyle(color: AppTheme.getTextPrimary(context), fontSize: 18)),
        ],
      ),
      content: SizedBox(
        width: 420,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _field(context, _nom, l10n.centreName, Icons.apartment_rounded,
                  validator: (v) => (v == null || v.trim().length < 2) ? l10n.centreName : null),
              const SizedBox(height: 14),
              _field(context, _ville, l10n.centreCity, Icons.location_on_rounded,
                  validator: (v) => (v == null || v.trim().length < 2) ? l10n.centreCity : null),
              const SizedBox(height: 14),
              _field(context, _adresse, l10n.centreAddress, Icons.map_rounded, required: false),
              const SizedBox(height: 14),
              _field(context, _capacite, l10n.centreCapacity, Icons.tag_rounded,
                  required: false,
                  keyboard: TextInputType.number,
                  formatters: [FilteringTextInputFormatter.digitsOnly]),
            ],
          ),
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

  Widget _field(BuildContext context, TextEditingController c, String label, IconData icon,
      {bool required = true,
      TextInputType? keyboard,
      List<TextInputFormatter>? formatters,
      String? Function(String?)? validator}) {
    return TextFormField(
      controller: c,
      keyboardType: keyboard,
      inputFormatters: formatters,
      style: TextStyle(color: AppTheme.getTextPrimary(context)),
      decoration: InputDecoration(
        labelText: required ? '$label *' : label,
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
