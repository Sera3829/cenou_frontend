import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../config/theme.dart';
import '../../../l10n/app_localizations.dart';

/// Dialogue de création de chambres en masse.
/// Génère une série de numéros `prefixe + (debut..debut+nombre-1)` avec zéros
/// de remplissage, tous du même type et prix. Aperçu en direct.
/// Retourne le corps prêt pour l'API, ou null si annulé.
class BulkChambreDialog extends StatefulWidget {
  final AppLocalizations l10n;

  const BulkChambreDialog({Key? key, required this.l10n}) : super(key: key);

  @override
  State<BulkChambreDialog> createState() => _BulkChambreDialogState();
}

class _BulkChambreDialogState extends State<BulkChambreDialog> {
  final _formKey = GlobalKey<FormState>();
  final _prefixe = TextEditingController(text: 'C-');
  final _debut = TextEditingController(text: '1');
  final _nombre = TextEditingController(text: '10');
  final _padding = TextEditingController(text: '3');
  final _prix = TextEditingController();
  String _type = 'SIMPLE';

  static const _types = ['SIMPLE', 'DOUBLE', 'STUDIO'];
  static const _maxBulk = 1000;

  @override
  void dispose() {
    _prefixe.dispose();
    _debut.dispose();
    _nombre.dispose();
    _padding.dispose();
    _prix.dispose();
    super.dispose();
  }

  int get _debutV => int.tryParse(_debut.text.trim()) ?? 0;
  int get _nombreV => int.tryParse(_nombre.text.trim()) ?? 0;
  int get _paddingV => int.tryParse(_padding.text.trim()) ?? 0;

  String _numero(int n) => '${_prefixe.text}${n.toString().padLeft(_paddingV, '0')}';

  /// Quelques numéros représentatifs pour l'aperçu.
  List<String> get _apercu {
    final nb = _nombreV.clamp(0, _maxBulk);
    if (nb <= 0) return [];
    if (nb <= 4) return List.generate(nb, (i) => _numero(_debutV + i));
    return [
      _numero(_debutV),
      _numero(_debutV + 1),
      '…',
      _numero(_debutV + nb - 1),
    ];
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.pop(context, <String, dynamic>{
      'prefixe': _prefixe.text,
      'debut': _debutV,
      'nombre': _nombreV,
      'padding': _paddingV,
      'type_chambre': _type,
      'prix_mensuel': int.tryParse(_prix.text.trim()) ?? 0,
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = widget.l10n;
    return AlertDialog(
      backgroundColor: AppTheme.getCardBackground(context),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Row(children: [
        const Icon(Icons.library_add_rounded, color: AppTheme.primaryColor),
        const SizedBox(width: 10),
        Expanded(
          child: Text(l10n.bulkCreateRooms,
              style: TextStyle(color: AppTheme.getTextPrimary(context), fontSize: 18)),
        ),
      ]),
      content: SizedBox(
        width: 480,
        child: Form(
          key: _formKey,
          onChanged: () => setState(() {}),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Row(children: [
              Expanded(
                flex: 2,
                child: _text(context, _prefixe, l10n.roomPrefix, Icons.abc_rounded,
                    hint: l10n.roomPrefixHint),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _text(context, _debut, l10n.startNumber, Icons.pin_rounded,
                    number: true,
                    validator: (v) =>
                        (v == null || v.trim().isEmpty) ? '—' : null),
              ),
            ]),
            const SizedBox(height: 14),
            Row(children: [
              Expanded(
                child: _text(context, _nombre, l10n.roomsCount, Icons.tag_rounded,
                    number: true, validator: _validNombre),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _text(context, _padding, l10n.numberPadding, Icons.exposure_zero_rounded,
                    number: true),
              ),
            ]),
            const SizedBox(height: 14),
            Row(children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _type,
                  items: _types
                      .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                      .toList(),
                  onChanged: (v) => setState(() => _type = v!),
                  style: TextStyle(color: AppTheme.getTextPrimary(context)),
                  dropdownColor: AppTheme.getCardBackground(context),
                  decoration: _decoration(context, l10n.roomType, Icons.category_rounded),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _text(context, _prix, l10n.monthlyRentLabel, Icons.payments_rounded,
                    number: true,
                    validator: (v) =>
                        (v == null || v.trim().isEmpty) ? '—' : null),
              ),
            ]),
            const SizedBox(height: 18),
            _previewBox(context, l10n),
          ]),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l10n.cancel, style: TextStyle(color: AppTheme.getTextSecondary(context))),
        ),
        ElevatedButton.icon(
          onPressed: _submit,
          icon: const Icon(Icons.check_rounded, size: 18),
          label: Text('${l10n.create} (${_nombreV.clamp(0, _maxBulk)})'),
          style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor, foregroundColor: Colors.white),
        ),
      ],
    );
  }

  String? _validNombre(String? v) {
    final n = int.tryParse((v ?? '').trim()) ?? 0;
    if (n < 1) return '≥ 1';
    if (n > _maxBulk) return '≤ $_maxBulk';
    return null;
  }

  Widget _previewBox(BuildContext context, AppLocalizations l10n) {
    final apercu = _apercu;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.primaryColor.withOpacity(0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.primaryColor.withOpacity(0.2)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(Icons.visibility_rounded, size: 16, color: AppTheme.primaryColor),
          const SizedBox(width: 6),
          Text(l10n.preview,
              style: TextStyle(
                  fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.primaryColor)),
        ]),
        const SizedBox(height: 10),
        if (apercu.isEmpty)
          Text('—', style: TextStyle(color: AppTheme.getTextTertiary(context)))
        else
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: apercu
                .map((n) => Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: AppTheme.getCardBackground(context),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppTheme.getBorderColor(context)),
                      ),
                      child: Text(n,
                          style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.getTextPrimary(context))),
                    ))
                .toList(),
          ),
      ]),
    );
  }

  Widget _text(BuildContext context, TextEditingController c, String label, IconData icon,
      {bool number = false, String? hint, String? Function(String?)? validator}) {
    return TextFormField(
      controller: c,
      keyboardType: number ? TextInputType.number : null,
      inputFormatters: number ? [FilteringTextInputFormatter.digitsOnly] : null,
      style: TextStyle(color: AppTheme.getTextPrimary(context)),
      decoration: _decoration(context, label, icon, hint: hint),
      validator: validator,
    );
  }

  InputDecoration _decoration(BuildContext context, String label, IconData icon, {String? hint}) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      hintStyle: TextStyle(color: AppTheme.getTextTertiary(context), fontSize: 12),
      labelStyle: TextStyle(color: AppTheme.getTextSecondary(context)),
      prefixIcon: Icon(icon, color: AppTheme.getTextTertiary(context), size: 20),
      filled: true,
      fillColor: AppTheme.getDashboardBackground(context),
      isDense: true,
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
