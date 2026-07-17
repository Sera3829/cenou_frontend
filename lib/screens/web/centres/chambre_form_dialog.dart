import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../config/theme.dart';
import '../../../l10n/app_localizations.dart';
import '../../../models/admin/centre_admin.dart';

/// Dialogue de création / édition d'une chambre.
/// Retourne le corps prêt pour l'API, ou null si annulé.
class ChambreFormDialog extends StatefulWidget {
  final AppLocalizations l10n;
  final Chambre? chambre; // null = création

  const ChambreFormDialog({Key? key, required this.l10n, this.chambre}) : super(key: key);

  @override
  State<ChambreFormDialog> createState() => _ChambreFormDialogState();
}

class _ChambreFormDialogState extends State<ChambreFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _numero;
  late final TextEditingController _prix;
  late String _type;
  late String _statut;

  static const _types = ['SIMPLE', 'DOUBLE', 'STUDIO'];

  bool get _isEdit => widget.chambre != null;
  bool get _estOccupee => widget.chambre?.estOccupee ?? false;

  @override
  void initState() {
    super.initState();
    final c = widget.chambre;
    _numero = TextEditingController(text: c?.numeroChambre ?? '');
    _prix = TextEditingController(text: c != null ? c.prixMensuel.toString() : '');
    _type = c?.typeChambre ?? 'SIMPLE';
    _statut = c?.statut ?? 'DISPONIBLE';
  }

  @override
  void dispose() {
    _numero.dispose();
    _prix.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    final body = <String, dynamic>{
      'numero_chambre': _numero.text.trim(),
      'type_chambre': _type,
      'prix_mensuel': int.tryParse(_prix.text.trim()) ?? 0,
    };
    // On n'envoie le statut que s'il est modifiable (chambre non occupée).
    if (!_estOccupee) body['statut'] = _statut;
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
          Icon(_isEdit ? Icons.edit_rounded : Icons.meeting_room_rounded,
              color: AppTheme.primaryColor),
          const SizedBox(width: 10),
          Text(_isEdit ? l10n.editRoom : l10n.newRoom,
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
              _text(context, _numero, l10n.roomNumber, Icons.tag_rounded,
                  validator: (v) => (v == null || v.trim().isEmpty) ? l10n.roomNumber : null),
              const SizedBox(height: 14),
              _dropdown(
                context,
                label: l10n.roomType,
                icon: Icons.category_rounded,
                value: _type,
                items: _types.map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
                onChanged: (v) => setState(() => _type = v!),
              ),
              const SizedBox(height: 14),
              _text(context, _prix, l10n.monthlyRentLabel, Icons.payments_rounded,
                  keyboard: TextInputType.number,
                  formatters: [FilteringTextInputFormatter.digitsOnly],
                  validator: (v) => (v == null || v.trim().isEmpty) ? l10n.monthlyRentLabel : null),
              const SizedBox(height: 14),
              // Le statut n'est éditable que si la chambre n'est pas occupée.
              _dropdown(
                context,
                label: l10n.roomStatus,
                icon: Icons.info_outline_rounded,
                value: _estOccupee ? 'OCCUPE' : _statut,
                enabled: !_estOccupee,
                items: [
                  DropdownMenuItem(value: 'DISPONIBLE', child: Text(l10n.available)),
                  DropdownMenuItem(value: 'MAINTENANCE', child: Text(l10n.maintenance)),
                  if (_estOccupee)
                    DropdownMenuItem(value: 'OCCUPE', child: Text(l10n.occupied)),
                ],
                onChanged: _estOccupee ? null : (v) => setState(() => _statut = v!),
              ),
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

  Widget _text(BuildContext context, TextEditingController c, String label, IconData icon,
      {TextInputType? keyboard,
      List<TextInputFormatter>? formatters,
      String? Function(String?)? validator}) {
    return TextFormField(
      controller: c,
      keyboardType: keyboard,
      inputFormatters: formatters,
      style: TextStyle(color: AppTheme.getTextPrimary(context)),
      decoration: _decoration(context, '$label *', icon),
      validator: validator,
    );
  }

  Widget _dropdown(BuildContext context,
      {required String label,
      required IconData icon,
      required String value,
      required List<DropdownMenuItem<String>> items,
      required ValueChanged<String?>? onChanged,
      bool enabled = true}) {
    return DropdownButtonFormField<String>(
      value: value,
      items: items,
      onChanged: enabled ? onChanged : null,
      style: TextStyle(color: AppTheme.getTextPrimary(context)),
      dropdownColor: AppTheme.getCardBackground(context),
      decoration: _decoration(context, label, icon),
      disabledHint: Text(widget.l10n.occupied,
          style: TextStyle(color: AppTheme.getTextTertiary(context))),
    );
  }

  InputDecoration _decoration(BuildContext context, String label, IconData icon) {
    return InputDecoration(
      labelText: label,
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
    );
  }
}
