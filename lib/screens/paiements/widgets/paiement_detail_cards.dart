import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../config/theme.dart';
import '../../../models/paiement.dart';
import '../../../utils/mobile_responsive.dart';
import '../../../l10n/app_localizations.dart';
import '../../../widgets/mobile/detail_widgets.dart';

class PaiementStatusCard extends StatelessWidget {
  final Paiement paiement;
  final bool isDark;
  final ResponsiveConfig config;
  final AppLocalizations l10n;
  const PaiementStatusCard(
      {super.key,
      required this.paiement,
      required this.isDark,
      required this.config,
      required this.l10n});

  @override
  Widget build(BuildContext context) {
    Color color;
    IconData icon;
    String text;

    if (paiement.isConfirme) {
      color = AppTheme.successColor;
      icon = Icons.check_circle;
      text = l10n.paymentConfirmed;
    } else if (paiement.isEchec) {
      color = AppTheme.errorColor;
      icon = Icons.cancel;
      text = l10n.paymentFailed;
    } else {
      color = AppTheme.warningColor;
      icon = Icons.pending;
      text = l10n.paymentPending;
    }

    final iconSize = config.responsive(small: 48, medium: 58, large: 66);
    final titleSize = config.responsive(small: 16, medium: 18, large: 20);
    final dateSize = config.responsive(small: 12, medium: 13, large: 14);
    final pad = config.responsive(small: 14, medium: 18, large: 20);
    final displayText =
        config.isSmall && text.length > 22 ? l10n.pendingShort : text;

    return Card(
      elevation: isDark ? 4 : 2,
      color: isDark ? const Color(0xFF1E1E1E) : null,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.all(pad),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          gradient: LinearGradient(
            colors: [
              color.withOpacity(isDark ? 0.2 : 0.1),
              color.withOpacity(isDark ? 0.08 : 0.04),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(children: [
          Icon(icon, size: iconSize, color: color),
          const SizedBox(height: 10),
          Text(displayText,
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: titleSize,
                  fontWeight: FontWeight.bold,
                  color: color),
              maxLines: 2,
              overflow: TextOverflow.ellipsis),
          if (paiement.datePaiement != null) ...[
            const SizedBox(height: 6),
            Text(
              config.isSmall
                  ? DateFormat('dd/MM/yyyy HH:mm', l10n.locale.languageCode)
                      .format(paiement.datePaiement!)
                  : DateFormat('dd MMMM yyyy à HH:mm', l10n.locale.languageCode)
                      .format(paiement.datePaiement!),
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: dateSize,
                  color: isDark ? Colors.grey.shade400 : Colors.grey[600]),
            ),
          ],
        ]),
      ),
    );
  }
}

class PaiementMontantCard extends StatelessWidget {
  final Paiement paiement;
  final bool isDark;
  final ResponsiveConfig config;
  final AppLocalizations l10n;
  const PaiementMontantCard(
      {super.key,
      required this.paiement,
      required this.isDark,
      required this.config,
      required this.l10n});

  @override
  Widget build(BuildContext context) {
    final amountSize = config.responsive(small: 26, medium: 30, large: 34);
    final labelSize = config.responsive(small: 12, medium: 13, large: 14);
    final pad = config.responsive(small: 14, medium: 18, large: 20);

    return Card(
      elevation: isDark ? 4 : 2,
      color: isDark ? const Color(0xFF1E1E1E) : null,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.all(pad),
        child: Column(children: [
          Text(l10n.amount,
              style: TextStyle(
                  fontSize: labelSize,
                  color: isDark ? Colors.grey.shade400 : Colors.grey[600])),
          const SizedBox(height: 8),
          Text(
            '${NumberFormat('#,###', l10n.locale.languageCode).format(paiement.montant)} FCFA',
            textAlign: TextAlign.center,
            style: TextStyle(
                fontSize: amountSize,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.primary),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ]),
      ),
    );
  }
}

class PaiementDetailsCard extends StatelessWidget {
  final Paiement paiement;
  final bool isDark;
  final ResponsiveConfig config;
  final AppLocalizations l10n;
  const PaiementDetailsCard(
      {super.key,
      required this.paiement,
      required this.isDark,
      required this.config,
      required this.l10n});

  @override
  Widget build(BuildContext context) {
    final titleSize = config.responsive(small: 15, medium: 17, large: 18);
    final pad = config.responsive(small: 12, medium: 15, large: 16);

    final ref = paiement.referenceTransaction ?? 'N/A';
    final displayRef =
        config.isSmall && ref.length > 16 ? '${ref.substring(0, 15)}…' : ref;
    final centre = paiement.nomCentre ?? '';
    final displayCentre = config.isSmall && centre.length > 18
        ? '${centre.substring(0, 17)}…'
        : centre;

    final rows = <DetailRowData>[
      DetailRowData(l10n.paymentMethod,
          paiement.modePaiement.replaceAll('_', ' '), Icons.payment),
      DetailRowData(l10n.reference, displayRef, Icons.receipt),
      if (paiement.dateEcheance != null)
        DetailRowData(
            config.isSmall ? l10n.dueDateShort : l10n.dueDate,
            DateFormat('dd/MM/yyyy', l10n.locale.languageCode)
                .format(paiement.dateEcheance as DateTime),
            Icons.calendar_today),
      if ((paiement.numeroChambre ?? '').isNotEmpty)
        DetailRowData(
            l10n.room, l10n.roomAbbr(paiement.numeroChambre!), Icons.home),
      if (displayCentre.isNotEmpty)
        DetailRowData(l10n.center, displayCentre, Icons.business),
      DetailRowData(l10n.status, paiement.statut, Icons.info),
    ];

    return Card(
      elevation: isDark ? 4 : 2,
      color: isDark ? const Color(0xFF1E1E1E) : null,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: EdgeInsets.all(pad),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(l10n.information,
              style: TextStyle(
                  fontSize: titleSize,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black87)),
          Divider(
              height: 20,
              color: isDark ? Colors.grey.shade800 : Colors.grey.shade300),
          config.isTablet
              ? _buildTwoColumnRows(rows, isDark, config)
              : _buildSingleColumnRows(rows, isDark, config),
        ]),
      ),
    );
  }

  Widget _buildSingleColumnRows(
      List<DetailRowData> rows, bool isDark, ResponsiveConfig config) {
    return Column(
      children: rows
          .map((r) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: DetailRow(
                    label: r.label,
                    value: r.value,
                    icon: r.icon,
                    isDark: isDark,
                    config: config),
              ))
          .toList(),
    );
  }

  Widget _buildTwoColumnRows(
      List<DetailRowData> rows, bool isDark, ResponsiveConfig config) {
    final pairs = <Widget>[];
    for (var i = 0; i < rows.length; i += 2) {
      pairs.add(Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Expanded(
            child: DetailRow(
                label: rows[i].label,
                value: rows[i].value,
                icon: rows[i].icon,
                isDark: isDark,
                config: config)),
        if (i + 1 < rows.length) ...[
          const SizedBox(width: 16),
          Expanded(
              child: DetailRow(
                  label: rows[i + 1].label,
                  value: rows[i + 1].value,
                  icon: rows[i + 1].icon,
                  isDark: isDark,
                  config: config)),
        ],
      ]));
      if (i + 2 < rows.length) pairs.add(const SizedBox(height: 12));
    }
    return Column(children: pairs);
  }
}

class PaiementReceiptCard extends StatelessWidget {
  final bool isDark;
  final bool isFromCache;
  final bool isActioning;
  final ResponsiveConfig config;
  final void Function(String, {Color bg}) onSnack;
  final VoidCallback onDownload;
  final VoidCallback onShare;
  final AppLocalizations l10n;

  const PaiementReceiptCard({
    super.key,
    required this.isDark,
    required this.isFromCache,
    required this.isActioning,
    required this.config,
    required this.onSnack,
    required this.onDownload,
    required this.onShare,
    required this.l10n,
  });

  @override
  Widget build(BuildContext context) {
    final titleSize = config.responsive(small: 15, medium: 17, large: 18);
    final tileTextSize = config.responsive(small: 13, medium: 15, large: 15);
    final iconSize = config.isSmall ? 22.0 : 26.0;

    Widget leadingIcon(IconData icon, Color color) => isActioning
        ? SizedBox(
            width: iconSize,
            height: iconSize,
            child: CircularProgressIndicator(strokeWidth: 2, color: color))
        : Icon(icon, color: color, size: iconSize);

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(l10n.receipt,
          style: TextStyle(
              fontSize: titleSize,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black87)),
      const SizedBox(height: 10),
      Card(
        elevation: isDark ? 4 : 2,
        color: isDark ? const Color(0xFF1E1E1E) : null,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        child: Column(children: [
          // Télécharger
          ListTile(
            leading: leadingIcon(Icons.picture_as_pdf, AppTheme.errorColor),
            title: Text(
              config.isSmall ? l10n.downloadPdfShort : l10n.downloadPdf,
              style: TextStyle(
                  fontSize: tileTextSize,
                  color: isDark ? Colors.white : Colors.black87),
            ),
            subtitle: isActioning
                ? Text(l10n.inProgress,
                    style: TextStyle(
                        fontSize: 11,
                        color:
                            isDark ? Colors.grey.shade400 : Colors.grey[600]))
                : null,
            trailing: isActioning
                ? null
                : Icon(Icons.download,
                    color: isDark ? Colors.grey.shade400 : Colors.grey[600],
                    size: 20),
            onTap: isActioning
                ? null
                : () {
                    if (isFromCache) {
                      onSnack(l10n.noDownloadOffline);
                    } else {
                      onDownload();
                    }
                  },
          ),
          Divider(
              height: 1,
              color: isDark ? Colors.grey.shade800 : Colors.grey.shade300),
          // Partager
          ListTile(
            leading:
                leadingIcon(Icons.share, Theme.of(context).colorScheme.primary),
            title: Text(l10n.shareReceipt,
                style: TextStyle(
                    fontSize: tileTextSize,
                    color: isDark ? Colors.white : Colors.black87)),
            subtitle: isActioning
                ? Text(l10n.preparing,
                    style: TextStyle(
                        fontSize: 11,
                        color:
                            isDark ? Colors.grey.shade400 : Colors.grey[600]))
                : null,
            trailing: isActioning
                ? null
                : Icon(Icons.arrow_forward_ios,
                    size: 14,
                    color: isDark ? Colors.grey.shade400 : Colors.grey[600]),
            onTap: isActioning
                ? null
                : () {
                    if (isFromCache) {
                      onSnack(l10n.noShareOffline);
                    } else {
                      onShare();
                    }
                  },
          ),
        ]),
      ),
    ]);
  }
}

// ── _ErrorView ────────────────────────────────────────────────────────────────
