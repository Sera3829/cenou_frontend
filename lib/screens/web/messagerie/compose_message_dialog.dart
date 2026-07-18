import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../config/theme.dart';
import '../../../l10n/app_localizations.dart';
import '../../../providers/web/messagerie_provider.dart';

/// Composition d'un message interne : note générale, par centre, ou direct.
class ComposeMessageDialog extends StatefulWidget {
  final AppLocalizations l10n;
  const ComposeMessageDialog({Key? key, required this.l10n}) : super(key: key);

  @override
  State<ComposeMessageDialog> createState() => _ComposeMessageDialogState();
}

class _ComposeMessageDialogState extends State<ComposeMessageDialog> {
  final _titre = TextEditingController();
  final _contenu = TextEditingController();
  final _search = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  String _mode = 'GENERAL'; // GENERAL, CENTRE, DIRECT
  int? _centreId;
  final Set<int> _userIds = {};
  String _query = '';
  bool _sending = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<MessagerieProvider>().ensureRefs();
    });
  }

  @override
  void dispose() {
    _titre.dispose();
    _contenu.dispose();
    _search.dispose();
    super.dispose();
  }

  Future<void> _submit(AppLocalizations l10n) async {
    if (!_formKey.currentState!.validate()) return;
    if (_mode == 'CENTRE' && _centreId == null) {
      _snack(l10n.msgSelectCentre, AppTheme.errorColor);
      return;
    }
    if (_mode == 'DIRECT' && _userIds.isEmpty) {
      _snack(l10n.msgNoRecipient, AppTheme.errorColor);
      return;
    }
    setState(() => _sending = true);
    final error = await context.read<MessagerieProvider>().envoyer(
          titre: _titre.text.trim(),
          contenu: _contenu.text.trim(),
          mode: _mode,
          centreId: _mode == 'CENTRE' ? _centreId : null,
          userIds: _mode == 'DIRECT' ? _userIds.toList() : null,
        );
    if (!mounted) return;
    setState(() => _sending = false);
    if (error == null) {
      Navigator.pop(context, true);
    } else {
      _snack(error, AppTheme.errorColor);
    }
  }

  void _snack(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg), backgroundColor: color, behavior: SnackBarBehavior.floating));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = widget.l10n;
    return Dialog(
      backgroundColor: AppTheme.getCardBackground(context),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 560, maxHeight: MediaQuery.of(context).size.height * 0.85),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          _header(context, l10n),
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  _modeSelector(context, l10n),
                  const SizedBox(height: 20),
                  if (_mode == 'CENTRE') ...[
                    _centrePicker(context, l10n),
                    const SizedBox(height: 20),
                  ],
                  if (_mode == 'DIRECT') ...[
                    _staffPicker(context, l10n),
                    const SizedBox(height: 20),
                  ],
                  _field(context, _titre, l10n.msgTitle, Icons.title_rounded, maxLen: 100,
                      validator: (v) => (v == null || v.trim().length < 3) ? l10n.msgTitle : null),
                  const SizedBox(height: 16),
                  _field(context, _contenu, l10n.msgBody, Icons.notes_rounded,
                      maxLen: 1000, maxLines: 5,
                      validator: (v) => (v == null || v.trim().length < 3) ? l10n.msgBody : null),
                ]),
              ),
            ),
          ),
          _footer(context, l10n),
        ]),
      ),
    );
  }

  Widget _header(BuildContext context, AppLocalizations l10n) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.primaryColor,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(16), topRight: Radius.circular(16)),
      ),
      child: Row(children: [
        Container(
          padding: const EdgeInsets.all(9),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(10)),
          child: const Icon(Icons.edit_rounded, color: Colors.white, size: 20),
        ),
        const SizedBox(width: 14),
        Expanded(child: Text(l10n.composeMessage,
            style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold))),
        IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.close_rounded, color: Colors.white),
          tooltip: l10n.close,
        ),
      ]),
    );
  }

  Widget _modeSelector(BuildContext context, AppLocalizations l10n) {
    final modes = [
      ('GENERAL', l10n.msgModeGeneral, l10n.msgModeGeneralHint, Icons.campaign_rounded, const Color(0xFF2563EB)),
      ('CENTRE', l10n.msgModeCentre, l10n.msgModeCentreHint, Icons.location_city_rounded, const Color(0xFF059669)),
      ('DIRECT', l10n.msgModeDirect, l10n.msgModeDirectHint, Icons.person_rounded, const Color(0xFF8B5CF6)),
    ];
    return Column(children: modes.map((m) {
      final selected = _mode == m.$1;
      return Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: InkWell(
          onTap: () => setState(() {
            _mode = m.$1;
            _centreId = null;
            _userIds.clear();
          }),
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: selected ? m.$5.withOpacity(0.08) : AppTheme.getDashboardBackground(context),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: selected ? m.$5 : AppTheme.getBorderColor(context),
                width: selected ? 2 : 1),
            ),
            child: Row(children: [
              Icon(m.$4, color: m.$5, size: 22),
              const SizedBox(width: 14),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(m.$2, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14,
                    color: AppTheme.getTextPrimary(context))),
                const SizedBox(height: 2),
                Text(m.$3, style: TextStyle(fontSize: 12, color: AppTheme.getTextSecondary(context))),
              ])),
              if (selected) Icon(Icons.check_circle_rounded, color: m.$5, size: 20),
            ]),
          ),
        ),
      );
    }).toList());
  }

  Widget _centrePicker(BuildContext context, AppLocalizations l10n) {
    return Consumer<MessagerieProvider>(builder: (context, p, _) {
      return DropdownButtonFormField<int>(
        value: _centreId,
        isExpanded: true,
        dropdownColor: AppTheme.getCardBackground(context),
        decoration: _decoration(context, l10n.msgSelectCentre, Icons.location_city_rounded),
        items: p.centres
            .map((c) => DropdownMenuItem(value: c.id,
                child: Text(c.nom, style: TextStyle(color: AppTheme.getTextPrimary(context)))))
            .toList(),
        onChanged: (v) => setState(() => _centreId = v),
        style: TextStyle(color: AppTheme.getTextPrimary(context)),
      );
    });
  }

  Widget _staffPicker(BuildContext context, AppLocalizations l10n) {
    return Consumer<MessagerieProvider>(builder: (context, p, _) {
      final list = p.staff.where((s) {
        if (_query.isEmpty) return true;
        final q = _query.toLowerCase();
        return (s['nom'] as String).toLowerCase().contains(q) ||
            (s['centre'] as String).toLowerCase().contains(q);
      }).toList();
      return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Text(l10n.msgRecipients, style: TextStyle(fontWeight: FontWeight.w600,
              color: AppTheme.getTextPrimary(context))),
          const Spacer(),
          if (_userIds.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
              decoration: BoxDecoration(
                color: const Color(0xFF8B5CF6), borderRadius: BorderRadius.circular(20)),
              child: Text('${_userIds.length}',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
            ),
        ]),
        const SizedBox(height: 10),
        TextField(
          controller: _search,
          onChanged: (v) => setState(() => _query = v),
          style: TextStyle(color: AppTheme.getTextPrimary(context)),
          decoration: _decoration(context, l10n.msgSearchStaff, Icons.search_rounded),
        ),
        const SizedBox(height: 10),
        Container(
          height: 200,
          decoration: BoxDecoration(
            border: Border.all(color: AppTheme.getBorderColor(context)),
            borderRadius: BorderRadius.circular(12),
          ),
          child: list.isEmpty
              ? Center(child: Text(l10n.msgNoStaff,
                  style: TextStyle(color: AppTheme.getTextTertiary(context))))
              : ListView.builder(
                  itemCount: list.length,
                  itemBuilder: (context, i) {
                    final s = list[i];
                    final id = s['id'] as int;
                    final selected = _userIds.contains(id);
                    return CheckboxListTile(
                      value: selected,
                      onChanged: (v) => setState(() {
                        if (v == true) {
                          _userIds.add(id);
                        } else {
                          _userIds.remove(id);
                        }
                      }),
                      dense: true,
                      controlAffinity: ListTileControlAffinity.leading,
                      activeColor: const Color(0xFF8B5CF6),
                      title: Text(s['nom'] as String,
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500,
                              color: AppTheme.getTextPrimary(context))),
                      subtitle: Text(
                        '${s['role']}${(s['centre'] as String).isNotEmpty ? ' · ${s['centre']}' : ''}',
                        style: TextStyle(fontSize: 12, color: AppTheme.getTextSecondary(context))),
                    );
                  },
                ),
        ),
      ]);
    });
  }

  Widget _field(BuildContext context, TextEditingController c, String label, IconData icon,
      {int? maxLen, int maxLines = 1, String? Function(String?)? validator}) {
    return TextFormField(
      controller: c,
      maxLength: maxLen,
      maxLines: maxLines,
      minLines: maxLines,
      style: TextStyle(color: AppTheme.getTextPrimary(context)),
      decoration: _decoration(context, label, icon),
      validator: validator,
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
        borderSide: BorderSide(color: AppTheme.getBorderColor(context))),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: AppTheme.getBorderColor(context))),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppTheme.primaryColor, width: 2)),
    );
  }

  Widget _footer(BuildContext context, AppLocalizations l10n) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.getDashboardBackground(context),
        border: Border(top: BorderSide(color: AppTheme.getBorderColor(context))),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(16), bottomRight: Radius.circular(16)),
      ),
      child: Row(children: [
        const Spacer(),
        TextButton(
          onPressed: _sending ? null : () => Navigator.pop(context),
          child: Text(l10n.cancel, style: TextStyle(color: AppTheme.getTextSecondary(context))),
        ),
        const SizedBox(width: 12),
        ElevatedButton.icon(
          onPressed: _sending ? null : () => _submit(l10n),
          icon: _sending
              ? const SizedBox(width: 16, height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : const Icon(Icons.send_rounded, size: 18),
          label: Text(l10n.msgSend),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.primaryColor, foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
          ),
        ),
      ]),
    );
  }
}
