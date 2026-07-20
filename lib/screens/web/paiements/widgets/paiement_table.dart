import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cenou_mobile/config/theme.dart';
import 'package:cenou_mobile/l10n/app_localizations.dart';
import 'package:cenou_mobile/models/paiement.dart';
import 'package:cenou_mobile/providers/web/paiement_admin_provider.dart';
import 'package:cenou_mobile/screens/web/paiements/utils/paiement_display.dart';
import 'package:cenou_mobile/screens/web/paiements/utils/paiement_export.dart';
import 'package:cenou_mobile/screens/web/paiements/dialogs/paiement_detail_dialog.dart';
import 'package:cenou_mobile/screens/web/paiements/dialogs/paiement_status_dialogs.dart';

/// Tableau des paiements (en-tête + lignes + pagination + menu d'actions).
class PaiementTable extends StatelessWidget {
  final PaiementAdminProvider provider;
  final AppLocalizations l10n;
  const PaiementTable({super.key, required this.provider, required this.l10n});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return LayoutBuilder(builder: (context, constraints) {
      final w = constraints.maxWidth;
      final showDate = w >= 1100;
      final showMode = w >= 900;

      return Container(
        margin: const EdgeInsets.fromLTRB(24, 0, 24, 24),
        decoration: BoxDecoration(
          color: AppTheme.getCardBackground(context),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(isDark ? 0.1 : 0.05), blurRadius: 10),
          ],
        ),
        child: Column(children: [
          // En-têtes
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: BoxDecoration(
              color: isDark ? Colors.grey.shade900.withOpacity(0.5) : const Color(0xFFF8FAFC),
              borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(12), topRight: Radius.circular(12)),
              border:
                  Border(bottom: BorderSide(color: AppTheme.getBorderColor(context), width: 1)),
            ),
            child: Row(children: [
              Expanded(flex: 24, child: _headerText(context, l10n.student)),
              Expanded(flex: 15, child: _headerText(context, l10n.amount)),
              Expanded(flex: 15, child: _headerText(context, l10n.status)),
              if (showMode) Expanded(flex: 16, child: _headerText(context, l10n.mode)),
              if (showDate) Expanded(flex: 16, child: _headerText(context, l10n.date)),
              SizedBox(width: 96, child: _headerText(context, l10n.actions)),
            ]),
          ),
          // Lignes
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: provider.paiements.length,
            itemBuilder: (context, index) => _row(context, provider.paiements[index], index,
                showMode: showMode, showDate: showDate),
          ),
          _pagination(context),
        ]),
      );
    });
  }

  Widget _headerText(BuildContext context, String text) {
    return Text(text,
        style: TextStyle(
            fontWeight: FontWeight.bold, color: AppTheme.getTextPrimary(context), fontSize: 13));
  }

  Widget _row(BuildContext context, Paiement paiement, int index,
      {required bool showMode, required bool showDate}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: index.isEven
            ? AppTheme.getCardBackground(context)
            : (isDark ? Colors.grey.shade900.withOpacity(0.3) : const Color(0xFFFAFAFA)),
        border: Border(bottom: BorderSide(color: AppTheme.getBorderColor(context), width: 1)),
      ),
      child: Row(children: [
        Expanded(
          flex: 24,
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(paiement.etudiantNomComplet,
                style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: AppTheme.getTextPrimary(context),
                    fontSize: 14),
                maxLines: 1,
                overflow: TextOverflow.ellipsis),
            const SizedBox(height: 4),
            Text(paiement.matricule ?? 'N/A',
                style: TextStyle(fontSize: 12, color: AppTheme.getTextSecondary(context))),
            if (paiement.centreNom != null)
              Text(l10n.centerRoom(paiement.centreNom!, paiement.numeroChambre ?? 'N/A'),
                  style: TextStyle(fontSize: 11, color: AppTheme.getTextTertiary(context)),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis),
          ]),
        ),
        Expanded(
          flex: 15,
          child: Text('${formatMontant(paiement.montant, l10n)} F',
              style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: paiement.montant > 0
                      ? const Color(0xFF10B981)
                      : const Color(0xFFEF4444))),
        ),
        Expanded(
          flex: 15,
          child: Align(
            alignment: Alignment.centerLeft,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: paiementStatutColor(paiement.statut).withOpacity(isDark ? 0.2 : 0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                    color: paiementStatutColor(paiement.statut).withOpacity(isDark ? 0.4 : 0.3)),
              ),
              child: Text(paiementStatutLabel(paiement.statut, l10n),
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: paiementStatutColor(paiement.statut)),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis),
            ),
          ),
        ),
        if (showMode)
          Expanded(
            flex: 16,
            child: Text(paiementModeLabel(paiement.modePaiement, l10n),
                style: TextStyle(color: AppTheme.getTextSecondary(context), fontSize: 13),
                maxLines: 1,
                overflow: TextOverflow.ellipsis),
          ),
        if (showDate)
          Expanded(
            flex: 16,
            child: Text(
              paiement.datePaiement != null
                  ? DateFormat('dd/MM/yy HH:mm', l10n.locale.languageCode)
                      .format(paiement.datePaiement!)
                  : 'N/A',
              style: TextStyle(color: AppTheme.getTextSecondary(context), fontSize: 13),
            ),
          ),
        SizedBox(
          width: 96,
          child: Row(mainAxisAlignment: MainAxisAlignment.start, children: [
            IconButton(
              onPressed: () => _openDetails(context, paiement),
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
              itemBuilder: (ctx) => _actionMenu(context, paiement),
              onSelected: (value) => _handleAction(context, value, paiement),
              padding: EdgeInsets.zero,
            ),
          ]),
        ),
      ]),
    );
  }

  List<PopupMenuEntry<String>> _actionMenu(BuildContext context, Paiement paiement) {
    return [
      PopupMenuItem<String>(
        value: 'details',
        child: Row(children: [
          Icon(Icons.info_outline, size: 18, color: AppTheme.getTextSecondary(context)),
          const SizedBox(width: 8),
          Text(l10n.fullDetails, style: TextStyle(color: AppTheme.getTextPrimary(context))),
        ]),
      ),
      if (paiement.statut == 'EN_ATTENTE') ...[
        PopupMenuItem<String>(
          value: 'confirmer',
          child: Row(children: [
            const Icon(Icons.check_circle, size: 18, color: Color(0xFF10B981)),
            const SizedBox(width: 8),
            Text(l10n.confirmPayment, style: TextStyle(color: AppTheme.getTextPrimary(context))),
          ]),
        ),
        PopupMenuItem<String>(
          value: 'rejeter',
          child: Row(children: [
            const Icon(Icons.cancel, size: 18, color: Color(0xFFEF4444)),
            const SizedBox(width: 8),
            Text(l10n.markAsFailed, style: TextStyle(color: AppTheme.getTextPrimary(context))),
          ]),
        ),
      ],
      const PopupMenuDivider(),
      PopupMenuItem<String>(
        value: 'export',
        child: Row(children: [
          Icon(Icons.download, size: 18, color: AppTheme.getTextSecondary(context)),
          const SizedBox(width: 8),
          Text(l10n.exportReceipt, style: TextStyle(color: AppTheme.getTextPrimary(context))),
        ]),
      ),
    ];
  }

  Widget _pagination(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey.shade900.withOpacity(0.5) : const Color(0xFFF8FAFC),
        borderRadius: const BorderRadius.only(
            bottomLeft: Radius.circular(12), bottomRight: Radius.circular(12)),
      ),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(l10n.totalPaymentsCount(provider.totalItems),
            style: TextStyle(color: AppTheme.getTextSecondary(context), fontSize: 13)),
        Row(children: [
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
            onPressed: provider.currentPage < provider.totalPages ? provider.loadNextPage : null,
            icon: const Icon(Icons.chevron_right),
            color: provider.currentPage < provider.totalPages
                ? Theme.of(context).colorScheme.primary
                : AppTheme.getTextTertiary(context),
          ),
        ]),
      ]),
    );
  }

  void _openDetails(BuildContext context, Paiement paiement) {
    showPaiementDetailsDialog(context, paiement, l10n,
        onConfirm: () => confirmPaiementDialog(context, paiement.id.toString(), provider, l10n));
  }

  Future<void> _handleAction(BuildContext context, String action, Paiement paiement) async {
    switch (action) {
      case 'details':
        _openDetails(context, paiement);
        break;
      case 'confirmer':
        await confirmPaiementDialog(context, paiement.id.toString(), provider, l10n);
        break;
      case 'rejeter':
        await rejectPaiementDialog(context, paiement.id.toString(), provider, l10n);
        break;
      case 'export':
        exportReceipt(context, paiement, l10n);
        break;
    }
  }
}
