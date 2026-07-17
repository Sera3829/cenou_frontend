import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../config/theme.dart';
import '../../../l10n/app_localizations.dart';
import '../../../models/admin/centre_admin.dart';
import '../../../providers/web/centre_admin_provider.dart';
import '../dashboard/dashboard_screen.dart';
import 'centre_form_dialog.dart';
import 'chambre_form_dialog.dart';

/// Espace « Centres » du dashboard — réservé aux administrateurs.
/// Master-détail : grille des centres → gestion des chambres d'un centre.
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
          if (provider.selectedCentre != null) {
            return _CentreDetail(provider: provider, l10n: l10n);
          }
          return _CentresGrid(provider: provider, l10n: l10n);
        },
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════════════
// Vue 1 — Grille des centres
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
          _header(context),
          const SizedBox(height: 24),
          Expanded(child: _content(context)),
        ],
      ),
    );
  }

  Widget _header(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l10n.centresManagement,
                  style: TextStyle(
                      fontSize: 24, fontWeight: FontWeight.bold,
                      color: AppTheme.getTextPrimary(context))),
              const SizedBox(height: 4),
              Text('${provider.centres.length} ${l10n.centres.toLowerCase()}',
                  style: TextStyle(fontSize: 14, color: AppTheme.getTextSecondary(context))),
            ],
          ),
        ),
        ElevatedButton.icon(
          onPressed: () => _createCentre(context),
          icon: const Icon(Icons.add_business_rounded, size: 20),
          label: Text(l10n.newCentre),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.primaryColor,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
      ],
    );
  }

  Widget _content(BuildContext context) {
    if (provider.isLoading && provider.centres.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (provider.centres.isEmpty) {
      return _empty(context);
    }
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final cols = width > 1200 ? 3 : (width > 760 ? 2 : 1);
        return GridView.builder(
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: cols,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            mainAxisExtent: 220,
          ),
          itemCount: provider.centres.length,
          itemBuilder: (context, i) => _CentreCard(
            centre: provider.centres[i],
            l10n: l10n,
            onOpen: () => provider.selectCentre(provider.centres[i].id),
            onEdit: () => _editCentre(context, provider.centres[i]),
            onDelete: () => _deleteCentre(context, provider.centres[i]),
          ),
        );
      },
    );
  }

  Widget _empty(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.location_city_rounded, size: 72, color: AppTheme.getTextTertiary(context)),
          const SizedBox(height: 16),
          Text(l10n.noCentresYet,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600,
                  color: AppTheme.getTextSecondary(context))),
          const SizedBox(height: 8),
          Text(l10n.addFirstCentre,
              style: TextStyle(color: AppTheme.getTextTertiary(context))),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: () => _createCentre(context),
            icon: const Icon(Icons.add_business_rounded),
            label: Text(l10n.newCentre),
            style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor, foregroundColor: Colors.white),
          ),
        ],
      ),
    );
  }

  Future<void> _createCentre(BuildContext context) async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (_) => CentreFormDialog(l10n: l10n),
    );
    if (result == null || !context.mounted) return;
    final err = await provider.createCentre(result);
    _feedback(context, err, l10n.centreCreated);
  }

  Future<void> _editCentre(BuildContext context, CentreAdmin centre) async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (_) => CentreFormDialog(l10n: l10n, centre: centre),
    );
    if (result == null || !context.mounted) return;
    final err = await provider.updateCentre(centre.id, result);
    _feedback(context, err, l10n.centreUpdated);
  }

  Future<void> _deleteCentre(BuildContext context, CentreAdmin centre) async {
    final confirm = await _confirmDialog(context, l10n.deleteCentre, l10n.deleteCentreConfirm, l10n);
    if (confirm != true || !context.mounted) return;
    final err = await provider.deleteCentre(centre.id);
    _feedback(context, err, l10n.centreDeleted);
  }
}

class _CentreCard extends StatelessWidget {
  final CentreAdmin centre;
  final AppLocalizations l10n;
  final VoidCallback onOpen, onEdit, onDelete;
  const _CentreCard({
    required this.centre, required this.l10n,
    required this.onOpen, required this.onEdit, required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final taux = centre.tauxOccupation;
    final tauxColor = taux >= 90
        ? AppTheme.errorColor
        : (taux >= 60 ? AppTheme.warningColor : AppTheme.successColor);

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.getCardBackground(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.getBorderColor(context)),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onOpen,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.apartment_rounded, color: AppTheme.primaryColor),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(centre.nom,
                              maxLines: 1, overflow: TextOverflow.ellipsis,
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold,
                                  color: AppTheme.getTextPrimary(context))),
                          Text(centre.ville,
                              style: TextStyle(fontSize: 13, color: AppTheme.getTextSecondary(context))),
                        ],
                      ),
                    ),
                    _menu(context),
                  ],
                ),
                const Spacer(),
                // Barre d'occupation
                Row(
                  children: [
                    Text('${l10n.occupancyRate} · ${taux.toStringAsFixed(0)}%',
                        style: TextStyle(fontSize: 12, color: AppTheme.getTextSecondary(context))),
                  ],
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: (taux / 100).clamp(0.0, 1.0),
                    minHeight: 8,
                    backgroundColor: AppTheme.getBorderColor(context),
                    valueColor: AlwaysStoppedAnimation(tauxColor),
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    _stat(context, Icons.meeting_room_rounded, '${centre.totalLogements}', l10n.rooms),
                    _stat(context, Icons.people_alt_rounded, '${centre.residents}', l10n.residentsLabel),
                    _stat(context, Icons.event_available_rounded,
                        '${centre.logementsDisponibles}', l10n.available),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _stat(BuildContext context, IconData icon, String value, String label) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 15, color: AppTheme.getTextTertiary(context)),
              const SizedBox(width: 4),
              Text(value,
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15,
                      color: AppTheme.getTextPrimary(context))),
            ],
          ),
          Text(label,
              style: TextStyle(fontSize: 11, color: AppTheme.getTextTertiary(context))),
        ],
      ),
    );
  }

  Widget _menu(BuildContext context) {
    return PopupMenuButton<String>(
      icon: Icon(Icons.more_vert_rounded, color: AppTheme.getTextTertiary(context)),
      onSelected: (v) {
        if (v == 'open') onOpen();
        if (v == 'edit') onEdit();
        if (v == 'delete') onDelete();
      },
      itemBuilder: (_) => [
        PopupMenuItem(value: 'open', child: Row(children: [
          const Icon(Icons.meeting_room_rounded, size: 18), const SizedBox(width: 10),
          Text(l10n.manageRooms)])),
        PopupMenuItem(value: 'edit', child: Row(children: [
          const Icon(Icons.edit_rounded, size: 18), const SizedBox(width: 10),
          Text(l10n.editCentre)])),
        PopupMenuItem(value: 'delete', child: Row(children: [
          Icon(Icons.delete_rounded, size: 18, color: AppTheme.errorColor), const SizedBox(width: 10),
          Text(l10n.deleteCentre, style: const TextStyle(color: AppTheme.errorColor))])),
      ],
    );
  }
}

// ════════════════════════════════════════════════════════════════════════
// Vue 2 — Détail d'un centre : gestion des chambres
// ════════════════════════════════════════════════════════════════════════

class _CentreDetail extends StatelessWidget {
  final CentreAdminProvider provider;
  final AppLocalizations l10n;
  const _CentreDetail({required this.provider, required this.l10n});

  @override
  Widget build(BuildContext context) {
    final centre = provider.selectedCentre!;
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _header(context, centre),
          const SizedBox(height: 20),
          Expanded(child: _roomsTable(context)),
        ],
      ),
    );
  }

  Widget _header(BuildContext context, CentreAdmin centre) {
    return Row(
      children: [
        IconButton(
          onPressed: provider.clearSelection,
          icon: const Icon(Icons.arrow_back_rounded),
          tooltip: l10n.back,
          style: IconButton.styleFrom(
            backgroundColor: AppTheme.getCardBackground(context),
            side: BorderSide(color: AppTheme.getBorderColor(context)),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(centre.nom,
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold,
                      color: AppTheme.getTextPrimary(context))),
              Text('${centre.ville}${centre.adresse != null ? ' · ${centre.adresse}' : ''}',
                  style: TextStyle(fontSize: 13, color: AppTheme.getTextSecondary(context))),
            ],
          ),
        ),
        ElevatedButton.icon(
          onPressed: () => _createRoom(context),
          icon: const Icon(Icons.add_rounded, size: 20),
          label: Text(l10n.newRoom),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.primaryColor, foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
      ],
    );
  }

  Widget _roomsTable(BuildContext context) {
    if (provider.isLoadingChambres && provider.chambres.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (provider.chambres.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.meeting_room_outlined, size: 64, color: AppTheme.getTextTertiary(context)),
            const SizedBox(height: 16),
            Text(l10n.noRoomsYet,
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600,
                    color: AppTheme.getTextSecondary(context))),
            const SizedBox(height: 8),
            Text(l10n.addFirstRoom, style: TextStyle(color: AppTheme.getTextTertiary(context))),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () => _createRoom(context),
              icon: const Icon(Icons.add_rounded),
              label: Text(l10n.newRoom),
              style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor, foregroundColor: Colors.white),
            ),
          ],
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.getCardBackground(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.getBorderColor(context)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          _tableHeader(context),
          Expanded(
            child: ListView.separated(
              itemCount: provider.chambres.length,
              separatorBuilder: (_, __) => Divider(height: 1, color: AppTheme.getBorderColor(context)),
              itemBuilder: (context, i) => _roomRow(context, provider.chambres[i]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _tableHeader(BuildContext context) {
    TextStyle s() => TextStyle(fontSize: 12, fontWeight: FontWeight.w600,
        color: AppTheme.getTextSecondary(context));
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      color: AppTheme.getDashboardBackground(context),
      child: Row(
        children: [
          Expanded(flex: 2, child: Text(l10n.roomNumber, style: s())),
          Expanded(flex: 2, child: Text(l10n.roomType, style: s())),
          Expanded(flex: 2, child: Text(l10n.monthlyRentLabel, style: s())),
          Expanded(flex: 2, child: Text(l10n.roomStatus, style: s())),
          Expanded(flex: 3, child: Text(l10n.occupant, style: s())),
          const SizedBox(width: 88),
        ],
      ),
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
      child: Row(
        children: [
          Expanded(flex: 2, child: Text(c.numeroChambre,
              style: txt.copyWith(fontWeight: FontWeight.w600))),
          Expanded(flex: 2, child: Text(c.typeChambre, style: txt)),
          Expanded(flex: 2, child: Text('${c.prixMensuel} FCFA', style: txt)),
          Expanded(
            flex: 2,
            child: Align(
              alignment: Alignment.centerLeft,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: statutColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(statutLabel,
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: statutColor)),
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              c.occupantNomComplet ?? l10n.vacant,
              style: txt.copyWith(
                color: c.occupantNomComplet != null
                    ? AppTheme.getTextPrimary(context)
                    : AppTheme.getTextTertiary(context),
              ),
            ),
          ),
          SizedBox(
            width: 88,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                IconButton(
                  onPressed: () => _editRoom(context, c),
                  icon: const Icon(Icons.edit_rounded, size: 18),
                  tooltip: l10n.editRoom,
                  color: AppTheme.getTextSecondary(context),
                ),
                IconButton(
                  onPressed: c.estOccupee ? null : () => _deleteRoom(context, c),
                  icon: const Icon(Icons.delete_rounded, size: 18),
                  tooltip: l10n.delete,
                  color: c.estOccupee ? AppTheme.getTextTertiary(context) : AppTheme.errorColor,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _createRoom(BuildContext context) async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (_) => ChambreFormDialog(l10n: l10n),
    );
    if (result == null || !context.mounted) return;
    final err = await provider.createChambre(result);
    _feedback(context, err, l10n.roomCreated);
  }

  Future<void> _editRoom(BuildContext context, Chambre chambre) async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (_) => ChambreFormDialog(l10n: l10n, chambre: chambre),
    );
    if (result == null || !context.mounted) return;
    final err = await provider.updateChambre(chambre.id, result);
    _feedback(context, err, l10n.roomUpdated);
  }

  Future<void> _deleteRoom(BuildContext context, Chambre chambre) async {
    final confirm = await _confirmDialog(context, l10n.delete, l10n.deleteRoomConfirm, l10n);
    if (confirm != true || !context.mounted) return;
    final err = await provider.deleteChambre(chambre.id);
    _feedback(context, err, l10n.roomDeleted);
  }
}

// ── Helpers partagés ───────────────────────────────────────────────────────

void _feedback(BuildContext context, String? error, String successMsg) {
  final ok = error == null;
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
    content: Text(ok ? successMsg : error),
    backgroundColor: ok ? AppTheme.successColor : AppTheme.errorColor,
    behavior: SnackBarBehavior.floating,
  ));
}

Future<bool?> _confirmDialog(
    BuildContext context, String title, String message, AppLocalizations l10n) {
  return showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      backgroundColor: AppTheme.getCardBackground(context),
      title: Text(title, style: TextStyle(color: AppTheme.getTextPrimary(context))),
      content: Text(message, style: TextStyle(color: AppTheme.getTextSecondary(context))),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: Text(l10n.cancel, style: TextStyle(color: AppTheme.getTextSecondary(context))),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(context, true),
          style: ElevatedButton.styleFrom(backgroundColor: AppTheme.errorColor, foregroundColor: Colors.white),
          child: Text(l10n.delete),
        ),
      ],
    ),
  );
}
