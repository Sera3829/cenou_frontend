import 'package:flutter/material.dart';
import 'package:cenou_mobile/config/theme.dart';
import 'package:cenou_mobile/l10n/app_localizations.dart';
import 'package:cenou_mobile/models/signalement.dart';
import 'package:cenou_mobile/providers/web/signalement_admin_provider.dart';
import 'package:cenou_mobile/screens/web/signalements/utils/signalement_display.dart';
import 'package:cenou_mobile/screens/web/signalements/dialogs/signalement_detail_dialog.dart';
import 'package:cenou_mobile/screens/web/signalements/dialogs/signalement_photos_dialog.dart';

/// Tableau des signalements (en-tête + lignes + pagination + menu d'actions).
class SignalementTable extends StatelessWidget {
  final SignalementAdminProvider provider;
  final AppLocalizations l10n;
  const SignalementTable({super.key, required this.provider, required this.l10n});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return LayoutBuilder(builder: (context, constraints) {
      final w = constraints.maxWidth;
      final showDate = w >= 1100;
      final showDescription = w >= 900;

      return Container(
        margin: const EdgeInsets.fromLTRB(24, 0, 24, 24),
        decoration: BoxDecoration(
          color: AppTheme.getCardBackground(context),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(isDark ? 0.1 : 0.05), blurRadius: 10),
          ],
        ),
        child: Column(
          children: [
            // En-tête
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: BoxDecoration(
                color: isDark ? Colors.grey.shade900.withOpacity(0.5) : const Color(0xFFF8FAFC),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(12),
                  topRight: Radius.circular(12),
                ),
                border: Border(
                    bottom: BorderSide(color: AppTheme.getBorderColor(context), width: 1)),
              ),
              child: Row(
                children: [
                  Expanded(flex: 22, child: _headerText(context, l10n.student)),
                  if (showDescription)
                    Expanded(flex: 26, child: _headerText(context, l10n.description)),
                  Expanded(flex: 14, child: _headerText(context, l10n.type)),
                  Expanded(flex: 15, child: _headerText(context, l10n.status)),
                  if (showDate) Expanded(flex: 15, child: _headerText(context, l10n.date)),
                  SizedBox(width: 96, child: _headerText(context, l10n.actions)),
                ],
              ),
            ),
            // Lignes
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: provider.signalements.length,
              itemBuilder: (context, index) => _row(context, provider.signalements[index], index,
                  showDescription: showDescription, showDate: showDate),
            ),
            _pagination(context),
          ],
        ),
      );
    });
  }

  Widget _headerText(BuildContext context, String text) {
    return Text(text,
        style: TextStyle(
            fontWeight: FontWeight.bold, color: AppTheme.getTextPrimary(context), fontSize: 13));
  }

  Widget _row(BuildContext context, Signalement s, int index,
      {required bool showDescription, required bool showDate}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: index.isEven
            ? AppTheme.getCardBackground(context)
            : (isDark ? Colors.grey.shade900.withOpacity(0.3) : const Color(0xFFFAFAFA)),
        border: Border(bottom: BorderSide(color: AppTheme.getBorderColor(context), width: 1)),
      ),
      child: Row(
        children: [
          // Étudiant
          Expanded(
            flex: 22,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(s.displayEtudiantNomComplet,
                    style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: AppTheme.getTextPrimary(context),
                        fontSize: 14),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
                const SizedBox(height: 4),
                Text(s.matricule ?? 'N/A',
                    style: TextStyle(fontSize: 12, color: AppTheme.getTextSecondary(context))),
                const SizedBox(height: 2),
                Text(s.numeroSuivi,
                    style: TextStyle(fontSize: 11, color: AppTheme.getTextTertiary(context))),
                if (s.numeroChambre != null && s.nomCentre != null) ...[
                  const SizedBox(height: 2),
                  Text(l10n.centerRoom(s.nomCentre!, s.numeroChambre!),
                      style: TextStyle(fontSize: 11, color: AppTheme.getTextTertiary(context)),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                ],
              ],
            ),
          ),
          // Description
          if (showDescription)
            Expanded(
              flex: 26,
              child: Padding(
                padding: const EdgeInsets.only(right: 12),
                child: Text(
                  s.description.length > 100
                      ? '${s.description.substring(0, 100)}...'
                      : s.description,
                  style: TextStyle(color: AppTheme.getTextSecondary(context), fontSize: 13),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          // Type
          Expanded(
            flex: 14,
            child: Align(
              alignment: Alignment.centerLeft,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: signalementTypeColor(s.typeProbleme).withOpacity(isDark ? 0.2 : 0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                      color: signalementTypeColor(s.typeProbleme).withOpacity(isDark ? 0.4 : 0.3)),
                ),
                child: Text(signalementTypeLabel(s.typeProbleme, l10n),
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: signalementTypeColor(s.typeProbleme))),
              ),
            ),
          ),
          // Statut
          Expanded(
            flex: 15,
            child: Align(
              alignment: Alignment.centerLeft,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: signalementStatutColor(s.statut).withOpacity(isDark ? 0.2 : 0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                      color: signalementStatutColor(s.statut).withOpacity(isDark ? 0.4 : 0.3)),
                ),
                child: Text(signalementStatutLabel(s.statut, l10n),
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: signalementStatutColor(s.statut))),
              ),
            ),
          ),
          // Date
          if (showDate)
            Expanded(
              flex: 15,
              child: Text(formatSignalementDate(s.createdAt, l10n),
                  style: TextStyle(color: AppTheme.getTextSecondary(context), fontSize: 13)),
            ),
          // Actions
          SizedBox(
            width: 96,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                IconButton(
                  onPressed: () => _openDetails(context, s),
                  icon: Icon(Icons.visibility_outlined,
                      size: 20, color: AppTheme.getTextSecondary(context)),
                  tooltip: l10n.viewDetails,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
                const SizedBox(width: 8),
                PopupMenuButton<String>(
                  icon: Icon(Icons.more_vert, size: 20, color: AppTheme.getTextSecondary(context)),
                  color: AppTheme.getCardBackground(context),
                  surfaceTintColor: AppTheme.getCardBackground(context),
                  itemBuilder: (context) => _actionMenu(context, s),
                  onSelected: (value) => _handleAction(context, value, s),
                  padding: EdgeInsets.zero,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<PopupMenuEntry<String>> _actionMenu(BuildContext context, Signalement s) {
    final items = <PopupMenuEntry<String>>[
      PopupMenuItem(
        value: 'details',
        child: Row(children: [
          Icon(Icons.info_outline, size: 18, color: AppTheme.getTextSecondary(context)),
          const SizedBox(width: 8),
          Text(l10n.fullDetails, style: TextStyle(color: AppTheme.getTextPrimary(context))),
        ]),
      ),
    ];
    if (s.isEnAttente) {
      items.addAll([
        PopupMenuItem(
          value: 'prendre_en_charge',
          child: Row(children: [
            const Icon(Icons.build, size: 18, color: Color(0xFF3B82F6)),
            const SizedBox(width: 8),
            Text(l10n.takeCharge, style: TextStyle(color: AppTheme.getTextPrimary(context))),
          ]),
        ),
        PopupMenuItem(
          value: 'annuler',
          child: Row(children: [
            const Icon(Icons.cancel, size: 18, color: Color(0xFFEF4444)),
            const SizedBox(width: 8),
            Text(l10n.cancelReport, style: TextStyle(color: AppTheme.getTextPrimary(context))),
          ]),
        ),
      ]);
    }
    if (s.isEnCours) {
      items.add(PopupMenuItem(
        value: 'resoudre',
        child: Row(children: [
          const Icon(Icons.check_circle, size: 18, color: Color(0xFF10B981)),
          const SizedBox(width: 8),
          Text(l10n.markAsResolved, style: TextStyle(color: AppTheme.getTextPrimary(context))),
        ]),
      ));
    }
    items.addAll([
      const PopupMenuDivider(),
      PopupMenuItem(
        value: 'photos',
        child: Row(children: [
          Icon(Icons.photo_library, size: 18, color: AppTheme.getTextSecondary(context)),
          const SizedBox(width: 8),
          Text(l10n.viewPhotos, style: TextStyle(color: AppTheme.getTextPrimary(context))),
        ]),
      ),
    ]);
    return items;
  }

  Widget _pagination(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey.shade900.withOpacity(0.5) : const Color(0xFFF8FAFC),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(12),
          bottomRight: Radius.circular(12),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(l10n.totalReportsCount(provider.totalItems),
              style: TextStyle(color: AppTheme.getTextSecondary(context), fontSize: 13)),
          Row(
            children: [
              IconButton(
                onPressed: provider.currentPage > 1 ? provider.loadPreviousPage : null,
                icon: const Icon(Icons.chevron_left),
                color: provider.currentPage > 1
                    ? Theme.of(context).colorScheme.primary
                    : AppTheme.getTextTertiary(context),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: AppTheme.getCardBackground(context),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppTheme.getBorderColor(context)),
                ),
                child: Text(l10n.pageOf(provider.currentPage, provider.totalPages),
                    style: TextStyle(
                        color: AppTheme.getTextPrimary(context), fontWeight: FontWeight.w500)),
              ),
              IconButton(
                onPressed:
                    provider.currentPage < provider.totalPages ? provider.loadNextPage : null,
                icon: const Icon(Icons.chevron_right),
                color: provider.currentPage < provider.totalPages
                    ? Theme.of(context).colorScheme.primary
                    : AppTheme.getTextTertiary(context),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _openDetails(BuildContext context, Signalement s) {
    showSignalementDetailsDialog(context, s, l10n,
        onTakeCharge: () => _updateStatus(context, s, 'EN_COURS'));
  }

  Future<void> _handleAction(BuildContext context, String action, Signalement s) async {
    switch (action) {
      case 'details':
        _openDetails(context, s);
        break;
      case 'prendre_en_charge':
        await _updateStatus(context, s, 'EN_COURS');
        break;
      case 'resoudre':
        await _updateStatus(context, s, 'RESOLU');
        break;
      case 'annuler':
        await _updateStatus(context, s, 'ANNULE');
        break;
      case 'photos':
        showSignalementPhotosDialog(context, s, l10n);
        break;
    }
  }

  Future<void> _updateStatus(BuildContext context, Signalement s, String nouveauStatut) async {
    try {
      String? commentaire;
      if (nouveauStatut == 'RESOLU' || nouveauStatut == 'ANNULE') {
        commentaire = await askSignalementComment(context, nouveauStatut, l10n);
        if (commentaire == null) return;
      }
      await provider.updateStatutSignalement(
        signalementId: s.id.toString(),
        nouveauStatut: nouveauStatut,
        commentaire: commentaire,
      );
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(l10n.reportStatusUpdated(signalementStatutLabel(nouveauStatut, l10n))),
        backgroundColor: signalementStatutColor(nouveauStatut),
        behavior: SnackBarBehavior.floating,
      ));
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('${l10n.error}: ${e.toString()}'),
        backgroundColor: const Color(0xFFEF4444),
        behavior: SnackBarBehavior.floating,
      ));
    }
  }
}
