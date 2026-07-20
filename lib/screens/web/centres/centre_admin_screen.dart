import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../config/theme.dart';
import '../../../l10n/app_localizations.dart';
import '../../../widgets/skeleton/skeletons.dart';
import '../../../models/admin/centre_admin.dart';
import '../../../providers/web/centre_admin_provider.dart';
import '../dashboard/dashboard_screen.dart';
import 'centre_form_dialog.dart';
import 'pavillon_form_dialog.dart';
import 'chambre_form_dialog.dart';
import 'bulk_chambre_dialog.dart';

/// Espace « Centres » du dashboard — réservé aux administrateurs.
/// Navigation à 3 niveaux : Centres → Pavillons → Chambres.
class CentreAdminScreen extends StatefulWidget {
  const CentreAdminScreen({Key? key}) : super(key: key);

  @override
  State<CentreAdminScreen> createState() => _CentreAdminScreenState();
}

class _CentreAdminScreenState extends State<CentreAdminScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CentreAdminProvider>().loadCentres();
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return DashboardLayout(
      selectedIndex: 7,
      child: Consumer<CentreAdminProvider>(
        builder: (context, provider, _) {
          if (provider.selectedPavillon != null) {
            return _PavillonDetail(provider: provider, l10n: l10n);
          }
          if (provider.selectedCentre != null) {
            return _PavillonsView(provider: provider, l10n: l10n);
          }
          return _CentresGrid(provider: provider, l10n: l10n);
        },
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════════════
// Niveau 1 — Grille des centres
// ════════════════════════════════════════════════════════════════════════

class _CentresGrid extends StatelessWidget {
  final CentreAdminProvider provider;
  final AppLocalizations l10n;
  const _CentresGrid({required this.provider, required this.l10n});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(l10n.centresManagement,
                        style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold,
                            color: AppTheme.getTextPrimary(context))),
                    const SizedBox(height: 4),
                    Text('${provider.centres.length} ${l10n.centres.toLowerCase()}',
                        style: TextStyle(fontSize: 14, color: AppTheme.getTextSecondary(context))),
                  ],
                ),
              ),
              _primaryButton(context, Icons.add_business_rounded, l10n.newCentre,
                  () => _createCentre(context)),
            ],
          ),
          const SizedBox(height: 24),
          Expanded(child: _content(context)),
        ],
      ),
    );
  }

  Widget _content(BuildContext context) {
    if (provider.isLoading && provider.centres.isEmpty) {
      return const SkeletonCentreGrid();
    }
    if (provider.error != null && provider.centres.isEmpty) {
      return _errorState(context, provider.error!, () => provider.loadCentres());
    }
    if (provider.centres.isEmpty) {
      return _emptyState(context, Icons.location_city_rounded, l10n.noCentresYet,
          l10n.addFirstCentre, l10n.newCentre, () => _createCentre(context));
    }
    return LayoutBuilder(builder: (context, c) {
      final cols = c.maxWidth > 1200 ? 3 : (c.maxWidth > 760 ? 2 : 1);
      return GridView.builder(
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: cols, crossAxisSpacing: 16, mainAxisSpacing: 16, mainAxisExtent: 232),
        itemCount: provider.centres.length,
        itemBuilder: (context, i) => _CentreCard(
          centre: provider.centres[i], l10n: l10n,
          onOpen: () => provider.selectCentre(provider.centres[i].id),
          onEdit: () => _editCentre(context, provider.centres[i]),
          onDelete: () => _deleteCentre(context, provider.centres[i]),
        ),
      );
    });
  }

  Future<void> _createCentre(BuildContext context) async {
    final result = await showDialog<Map<String, dynamic>>(
        context: context, builder: (_) => CentreFormDialog(l10n: l10n));
    if (result == null || !context.mounted) return;
    _feedback(context, await provider.createCentre(result), l10n.centreCreated);
  }

  Future<void> _editCentre(BuildContext context, CentreAdmin centre) async {
    final result = await showDialog<Map<String, dynamic>>(
        context: context, builder: (_) => CentreFormDialog(l10n: l10n, centre: centre));
    if (result == null || !context.mounted) return;
    _feedback(context, await provider.updateCentre(centre.id, result), l10n.centreUpdated);
  }

  Future<void> _deleteCentre(BuildContext context, CentreAdmin centre) async {
    if (await _confirmDialog(context, l10n.deleteCentre, l10n.deleteCentreConfirm, l10n) != true
        || !context.mounted) return;
    _feedback(context, await provider.deleteCentre(centre.id), l10n.centreDeleted);
  }
}

class _CentreCard extends StatelessWidget {
  final CentreAdmin centre;
  final AppLocalizations l10n;
  final VoidCallback onOpen, onEdit, onDelete;
  const _CentreCard({required this.centre, required this.l10n,
    required this.onOpen, required this.onEdit, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final taux = centre.tauxOccupation;
    final tauxColor = taux >= 90 ? AppTheme.errorColor : (taux >= 60 ? AppTheme.warningColor : AppTheme.successColor);
    return _cardShell(context, onOpen, [
      Row(children: [
        _iconBox(context, Icons.apartment_rounded, AppTheme.primaryColor),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(centre.nom, maxLines: 1, overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.getTextPrimary(context))),
          Text(centre.ville, style: TextStyle(fontSize: 13, color: AppTheme.getTextSecondary(context))),
        ])),
        _menu(context, l10n.managePavillon, l10n.editCentre, l10n.deleteCentre, onOpen, onEdit, onDelete),
      ]),
      const Spacer(),
      Text('${l10n.occupancyShort} · ${taux.toStringAsFixed(0)}%',
          style: TextStyle(fontSize: 12, color: AppTheme.getTextSecondary(context))),
      const SizedBox(height: 6),
      _bar(context, taux, tauxColor),
      const SizedBox(height: 14),
      Row(children: [
        _stat(context, Icons.dashboard_rounded, '${centre.totalPavillons}', l10n.pavillons),
        _stat(context, Icons.meeting_room_rounded, '${centre.totalLogements}', l10n.rooms),
        _stat(context, Icons.people_alt_rounded, '${centre.residents}', l10n.residentsLabel),
      ]),
    ]);
  }

  Widget _menu(BuildContext context, String open, String edit, String del,
      VoidCallback onOpen, VoidCallback onEdit, VoidCallback onDelete) {
    return PopupMenuButton<String>(
      icon: Icon(Icons.more_vert_rounded, color: AppTheme.getTextTertiary(context)),
      onSelected: (v) => v == 'open' ? onOpen() : v == 'edit' ? onEdit() : onDelete(),
      itemBuilder: (_) => [
        PopupMenuItem(value: 'open', child: Row(children: [
          const Icon(Icons.dashboard_rounded, size: 18), const SizedBox(width: 10), Text(open)])),
        PopupMenuItem(value: 'edit', child: Row(children: [
          const Icon(Icons.edit_rounded, size: 18), const SizedBox(width: 10), Text(edit)])),
        PopupMenuItem(value: 'delete', child: Row(children: [
          Icon(Icons.delete_rounded, size: 18, color: AppTheme.errorColor), const SizedBox(width: 10),
          Text(del, style: const TextStyle(color: AppTheme.errorColor))])),
      ],
    );
  }

  Widget _stat(BuildContext context, IconData icon, String value, String label) => Expanded(
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Icon(icon, size: 15, color: AppTheme.getTextTertiary(context)),
        const SizedBox(width: 4),
        Text(value, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppTheme.getTextPrimary(context))),
      ]),
      Text(label, style: TextStyle(fontSize: 11, color: AppTheme.getTextTertiary(context)),
          maxLines: 1, overflow: TextOverflow.ellipsis),
    ]),
  );
}

// ════════════════════════════════════════════════════════════════════════
// Niveau 2 — Pavillons d'un centre
// ════════════════════════════════════════════════════════════════════════

class _PavillonsView extends StatelessWidget {
  final CentreAdminProvider provider;
  final AppLocalizations l10n;
  const _PavillonsView({required this.provider, required this.l10n});

  @override
  Widget build(BuildContext context) {
    final centre = provider.selectedCentre!;
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _detailHeader(
            context,
            onBack: provider.clearCentreSelection,
            title: centre.nom,
            subtitle: '${centre.ville} · ${centre.totalPavillons} ${l10n.pavillons.toLowerCase()}',
            actionIcon: Icons.add_rounded,
            actionLabel: l10n.newPavillon,
            onAction: () => _createPavillon(context),
            l10n: l10n,
          ),
          const SizedBox(height: 20),
          Expanded(child: _content(context)),
        ],
      ),
    );
  }

  Widget _content(BuildContext context) {
    if (provider.isLoadingPavillons && provider.pavillons.isEmpty) {
      return const SkeletonCentreGrid(count: 4);
    }
    if (provider.pavillons.isEmpty) {
      return _emptyState(context, Icons.dashboard_customize_rounded, l10n.noPavillonsYet,
          l10n.addFirstPavillon, l10n.newPavillon, () => _createPavillon(context));
    }
    return LayoutBuilder(builder: (context, c) {
      final cols = c.maxWidth > 1200 ? 3 : (c.maxWidth > 760 ? 2 : 1);
      return GridView.builder(
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: cols, crossAxisSpacing: 16, mainAxisSpacing: 16, mainAxisExtent: 190),
        itemCount: provider.pavillons.length,
        itemBuilder: (context, i) => _PavillonCard(
          pavillon: provider.pavillons[i], l10n: l10n,
          onOpen: () => provider.selectPavillon(provider.pavillons[i].id),
          onEdit: () => _editPavillon(context, provider.pavillons[i]),
          onDelete: () => _deletePavillon(context, provider.pavillons[i]),
        ),
      );
    });
  }

  Future<void> _createPavillon(BuildContext context) async {
    final result = await showDialog<Map<String, dynamic>>(
        context: context, builder: (_) => PavillonFormDialog(l10n: l10n));
    if (result == null || !context.mounted) return;
    _feedback(context, await provider.createPavillon(result), l10n.pavillonCreated);
  }

  Future<void> _editPavillon(BuildContext context, Pavillon p) async {
    final result = await showDialog<Map<String, dynamic>>(
        context: context, builder: (_) => PavillonFormDialog(l10n: l10n, pavillon: p));
    if (result == null || !context.mounted) return;
    _feedback(context, await provider.updatePavillon(p.id, result), l10n.pavillonUpdated);
  }

  Future<void> _deletePavillon(BuildContext context, Pavillon p) async {
    if (await _confirmDialog(context, l10n.deletePavillon, l10n.deletePavillonConfirm, l10n) != true
        || !context.mounted) return;
    _feedback(context, await provider.deletePavillon(p.id), l10n.pavillonDeleted);
  }
}

class _PavillonCard extends StatelessWidget {
  final Pavillon pavillon;
  final AppLocalizations l10n;
  final VoidCallback onOpen, onEdit, onDelete;
  const _PavillonCard({required this.pavillon, required this.l10n,
    required this.onOpen, required this.onEdit, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final taux = pavillon.tauxOccupation;
    final tauxColor = taux >= 90 ? AppTheme.errorColor : (taux >= 60 ? AppTheme.warningColor : AppTheme.successColor);
    return _cardShell(context, onOpen, [
      Row(children: [
        _iconBox(context, Icons.dashboard_rounded, const Color(0xFF8B5CF6)),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(pavillon.nom, maxLines: 1, overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.getTextPrimary(context))),
          Text('${pavillon.totalLogements} / ${pavillon.capacite} ${l10n.rooms.toLowerCase()}',
              style: TextStyle(fontSize: 13, color: AppTheme.getTextSecondary(context))),
        ])),
        PopupMenuButton<String>(
          icon: Icon(Icons.more_vert_rounded, color: AppTheme.getTextTertiary(context)),
          onSelected: (v) => v == 'open' ? onOpen() : v == 'edit' ? onEdit() : onDelete(),
          itemBuilder: (_) => [
            PopupMenuItem(value: 'open', child: Row(children: [
              const Icon(Icons.meeting_room_rounded, size: 18), const SizedBox(width: 10), Text(l10n.managePavillon)])),
            PopupMenuItem(value: 'edit', child: Row(children: [
              const Icon(Icons.edit_rounded, size: 18), const SizedBox(width: 10), Text(l10n.editPavillon)])),
            PopupMenuItem(value: 'delete', child: Row(children: [
              Icon(Icons.delete_rounded, size: 18, color: AppTheme.errorColor), const SizedBox(width: 10),
              Text(l10n.deletePavillon, style: const TextStyle(color: AppTheme.errorColor))])),
          ],
        ),
      ]),
      const Spacer(),
      Text('${l10n.occupancyShort} · ${taux.toStringAsFixed(0)}%',
          style: TextStyle(fontSize: 12, color: AppTheme.getTextSecondary(context))),
      const SizedBox(height: 6),
      _bar(context, taux, tauxColor),
    ]);
  }
}

// ════════════════════════════════════════════════════════════════════════
// Niveau 3 — Chambres d'un pavillon
// ════════════════════════════════════════════════════════════════════════

class _PavillonDetail extends StatelessWidget {
  final CentreAdminProvider provider;
  final AppLocalizations l10n;
  const _PavillonDetail({required this.provider, required this.l10n});

  @override
  Widget build(BuildContext context) {
    final pav = provider.selectedPavillon!;
    final centre = provider.selectedCentre;
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            IconButton(
              onPressed: provider.clearPavillonSelection,
              icon: const Icon(Icons.arrow_back_rounded),
              tooltip: l10n.back,
              style: IconButton.styleFrom(
                backgroundColor: AppTheme.getCardBackground(context),
                side: BorderSide(color: AppTheme.getBorderColor(context)),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(pav.nom, style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppTheme.getTextPrimary(context))),
              Text('${centre?.nom ?? ''} · ${pav.totalLogements} ${l10n.rooms.toLowerCase()}',
                  style: TextStyle(fontSize: 13, color: AppTheme.getTextSecondary(context))),
            ])),
            // Bouton création en masse
            OutlinedButton.icon(
              onPressed: () => _bulkCreate(context),
              icon: const Icon(Icons.library_add_rounded, size: 18),
              label: Text(l10n.bulkCreate),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppTheme.primaryColor,
                side: const BorderSide(color: AppTheme.primaryColor),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(width: 10),
            _primaryButton(context, Icons.add_rounded, l10n.newRoom, () => _createRoom(context)),
          ]),
          const SizedBox(height: 20),
          Expanded(child: _table(context)),
        ],
      ),
    );
  }

  Widget _table(BuildContext context) {
    if (provider.isLoadingChambres && provider.chambres.isEmpty) {
      return const SkeletonDataTable(columns: 4);
    }
    if (provider.chambres.isEmpty) {
      return _emptyState(context, Icons.meeting_room_outlined, l10n.noRoomsYet,
          l10n.addFirstRoom, l10n.bulkCreate, () => _bulkCreate(context));
    }
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.getCardBackground(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.getBorderColor(context)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(children: [
        _tableHeader(context),
        Expanded(
          child: ListView.separated(
            itemCount: provider.chambres.length,
            separatorBuilder: (_, __) => Divider(height: 1, color: AppTheme.getBorderColor(context)),
            itemBuilder: (context, i) => _roomRow(context, provider.chambres[i]),
          ),
        ),
      ]),
    );
  }

  Widget _tableHeader(BuildContext context) {
    TextStyle s() => TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.getTextSecondary(context));
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      color: AppTheme.getDashboardBackground(context),
      child: Row(children: [
        Expanded(flex: 2, child: Text(l10n.roomNumber, style: s())),
        Expanded(flex: 2, child: Text(l10n.roomType, style: s())),
        Expanded(flex: 2, child: Text(l10n.monthlyRentLabel, style: s())),
        Expanded(flex: 2, child: Text(l10n.roomStatus, style: s())),
        Expanded(flex: 3, child: Text(l10n.occupant, style: s())),
        const SizedBox(width: 88),
      ]),
    );
  }

  Widget _roomRow(BuildContext context, Chambre c) {
    final (statutColor, statutLabel) = switch (c.statut) {
      'OCCUPE' => (AppTheme.warningColor, l10n.occupied),
      'MAINTENANCE' => (AppTheme.errorColor, l10n.maintenance),
      _ => (AppTheme.successColor, l10n.available),
    };
    final txt = TextStyle(fontSize: 13, color: AppTheme.getTextPrimary(context));
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      child: Row(children: [
        Expanded(flex: 2, child: Text(c.numeroChambre, style: txt.copyWith(fontWeight: FontWeight.w600))),
        Expanded(flex: 2, child: Text(c.typeChambre, style: txt)),
        Expanded(flex: 2, child: Text('${c.prixMensuel} FCFA', style: txt)),
        Expanded(flex: 2, child: Align(alignment: Alignment.centerLeft, child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(color: statutColor.withOpacity(0.12), borderRadius: BorderRadius.circular(20)),
          child: Text(statutLabel, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: statutColor)),
        ))),
        Expanded(flex: 3, child: Text(c.occupantNomComplet ?? l10n.vacant,
            style: txt.copyWith(color: c.occupantNomComplet != null
                ? AppTheme.getTextPrimary(context) : AppTheme.getTextTertiary(context)))),
        SizedBox(width: 88, child: Row(mainAxisAlignment: MainAxisAlignment.end, children: [
          IconButton(onPressed: () => _editRoom(context, c), icon: const Icon(Icons.edit_rounded, size: 18),
              tooltip: l10n.editRoom, color: AppTheme.getTextSecondary(context)),
          IconButton(onPressed: c.estOccupee ? null : () => _deleteRoom(context, c),
              icon: const Icon(Icons.delete_rounded, size: 18), tooltip: l10n.delete,
              color: c.estOccupee ? AppTheme.getTextTertiary(context) : AppTheme.errorColor),
        ])),
      ]),
    );
  }

  Future<void> _createRoom(BuildContext context) async {
    final result = await showDialog<Map<String, dynamic>>(
        context: context, builder: (_) => ChambreFormDialog(l10n: l10n));
    if (result == null || !context.mounted) return;
    await _submitRoom(context, result, ajuster: false);
  }

  Future<void> _submitRoom(BuildContext context, Map<String, dynamic> body,
      {required bool ajuster}) async {
    final r = await provider.createChambre(body, ajuster: ajuster);
    if (!context.mounted) return;
    if (r.capaciteDepassee) {
      final ok = await _askAjuster(context, r.error!);
      if (ok == true && context.mounted) await _submitRoom(context, body, ajuster: true);
      return;
    }
    _feedback(context, r.error, l10n.roomCreated);
  }

  Future<void> _bulkCreate(BuildContext context) async {
    final result = await showDialog<Map<String, dynamic>>(
        context: context, builder: (_) => BulkChambreDialog(l10n: l10n));
    if (result == null || !context.mounted) return;
    await _submitBulk(context, result, ajuster: false);
  }

  Future<void> _submitBulk(BuildContext context, Map<String, dynamic> body,
      {required bool ajuster}) async {
    final r = await provider.bulkCreateChambres(body, ajuster: ajuster);
    if (!context.mounted) return;
    if (r.capaciteDepassee) {
      final ok = await _askAjuster(context, r.error!);
      if (ok == true && context.mounted) await _submitBulk(context, body, ajuster: true);
      return;
    }
    _feedbackMsg(context, r.error, r.message ?? l10n.roomCreated);
  }

  /// Dialogue « capacité dépassée » : propose d'ajuster la capacité du pavillon.
  Future<bool?> _askAjuster(BuildContext context, String message) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.getCardBackground(context),
        title: Row(children: [
          Icon(Icons.warning_amber_rounded, color: AppTheme.warningColor),
          const SizedBox(width: 10),
          Text(l10n.capacityExceeded,
              style: TextStyle(color: AppTheme.getTextPrimary(context), fontSize: 18)),
        ]),
        content: Text(message, style: TextStyle(color: AppTheme.getTextSecondary(context))),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.cancel, style: TextStyle(color: AppTheme.getTextSecondary(context))),
          ),
          ElevatedButton.icon(
            onPressed: () => Navigator.pop(context, true),
            icon: const Icon(Icons.tune_rounded, size: 18),
            label: Text(l10n.adjustCapacity),
            style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor, foregroundColor: Colors.white),
          ),
        ],
      ),
    );
  }

  Future<void> _editRoom(BuildContext context, Chambre chambre) async {
    final result = await showDialog<Map<String, dynamic>>(
        context: context, builder: (_) => ChambreFormDialog(l10n: l10n, chambre: chambre));
    if (result == null || !context.mounted) return;
    _feedback(context, await provider.updateChambre(chambre.id, result), l10n.roomUpdated);
  }

  Future<void> _deleteRoom(BuildContext context, Chambre chambre) async {
    if (await _confirmDialog(context, l10n.delete, l10n.deleteRoomConfirm, l10n) != true
        || !context.mounted) return;
    _feedback(context, await provider.deleteChambre(chambre.id), l10n.roomDeleted);
  }
}

// ── Helpers partagés ───────────────────────────────────────────────────────

Widget _cardShell(BuildContext context, VoidCallback onTap, List<Widget> children) {
  return Container(
    decoration: BoxDecoration(
      color: AppTheme.getCardBackground(context),
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: AppTheme.getBorderColor(context)),
    ),
    child: Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: children),
        ),
      ),
    ),
  );
}

Widget _iconBox(BuildContext context, IconData icon, Color color) => Container(
  padding: const EdgeInsets.all(10),
  decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
  child: Icon(icon, color: color),
);

Widget _bar(BuildContext context, double taux, Color color) => ClipRRect(
  borderRadius: BorderRadius.circular(4),
  child: LinearProgressIndicator(
    value: (taux / 100).clamp(0.0, 1.0),
    minHeight: 8,
    backgroundColor: AppTheme.getBorderColor(context),
    valueColor: AlwaysStoppedAnimation(color),
  ),
);

Widget _primaryButton(BuildContext context, IconData icon, String label, VoidCallback onTap) {
  return ElevatedButton.icon(
    onPressed: onTap,
    icon: Icon(icon, size: 20),
    label: Text(label),
    style: ElevatedButton.styleFrom(
      backgroundColor: AppTheme.primaryColor, foregroundColor: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
  );
}

Widget _detailHeader(BuildContext context, {
  required VoidCallback onBack, required String title, required String subtitle,
  required IconData actionIcon, required String actionLabel, required VoidCallback onAction,
  required AppLocalizations l10n,
}) {
  return Row(children: [
    IconButton(
      onPressed: onBack, icon: const Icon(Icons.arrow_back_rounded), tooltip: l10n.back,
      style: IconButton.styleFrom(
        backgroundColor: AppTheme.getCardBackground(context),
        side: BorderSide(color: AppTheme.getBorderColor(context)),
      ),
    ),
    const SizedBox(width: 16),
    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(title, style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppTheme.getTextPrimary(context))),
      Text(subtitle, style: TextStyle(fontSize: 13, color: AppTheme.getTextSecondary(context))),
    ])),
    _primaryButton(context, actionIcon, actionLabel, onAction),
  ]);
}

Widget _emptyState(BuildContext context, IconData icon, String title, String sub,
    String actionLabel, VoidCallback onAction) {
  return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
    Icon(icon, size: 68, color: AppTheme.getTextTertiary(context)),
    const SizedBox(height: 16),
    Text(title, style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: AppTheme.getTextSecondary(context))),
    const SizedBox(height: 8),
    Text(sub, style: TextStyle(color: AppTheme.getTextTertiary(context))),
    const SizedBox(height: 20),
    ElevatedButton.icon(onPressed: onAction, icon: const Icon(Icons.add_rounded), label: Text(actionLabel),
        style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryColor, foregroundColor: Colors.white)),
  ]));
}

Widget _errorState(BuildContext context, String error, VoidCallback onRetry) {
  return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
    Icon(Icons.error_outline_rounded, size: 56, color: AppTheme.errorColor),
    const SizedBox(height: 16),
    Padding(padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Text(error, textAlign: TextAlign.center, style: TextStyle(color: AppTheme.getTextSecondary(context)))),
    const SizedBox(height: 20),
    ElevatedButton(onPressed: onRetry,
        style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryColor, foregroundColor: Colors.white),
        child: const Text('Réessayer')),
  ]));
}

void _feedback(BuildContext context, String? error, String successMsg) =>
    _feedbackMsg(context, error, successMsg);

void _feedbackMsg(BuildContext context, String? error, String successMsg) {
  final ok = error == null;
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
    content: Text(ok ? successMsg : error),
    backgroundColor: ok ? AppTheme.successColor : AppTheme.errorColor,
    behavior: SnackBarBehavior.floating,
  ));
}

Future<bool?> _confirmDialog(BuildContext context, String title, String message, AppLocalizations l10n) {
  return showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      backgroundColor: AppTheme.getCardBackground(context),
      title: Text(title, style: TextStyle(color: AppTheme.getTextPrimary(context))),
      content: Text(message, style: TextStyle(color: AppTheme.getTextSecondary(context))),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.cancel, style: TextStyle(color: AppTheme.getTextSecondary(context)))),
        ElevatedButton(onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.errorColor, foregroundColor: Colors.white),
            child: Text(l10n.delete)),
      ],
    ),
  );
}
