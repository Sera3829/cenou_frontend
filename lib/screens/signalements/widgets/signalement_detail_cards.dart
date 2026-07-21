import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../config/theme.dart';
import '../../../models/signalement.dart';
import '../../../utils/mobile_responsive.dart';
import '../../../l10n/app_localizations.dart';
import '../../../widgets/mobile/detail_widgets.dart';

class SignalementStatusCard extends StatelessWidget {
  final Signalement signalement;
  final bool isDark;
  final ResponsiveConfig config;
  final AppLocalizations l10n;
  const SignalementStatusCard(
      {super.key,
      required this.signalement,
      required this.isDark,
      required this.config,
      required this.l10n});

  @override
  Widget build(BuildContext context) {
    Color color;
    IconData icon;
    String text;

    if (signalement.isResolu) {
      color = AppTheme.successColor;
      icon = Icons.check_circle;
      text = l10n.problemResolved;
    } else if (signalement.isEnCours) {
      color = AppTheme.infoColor;
      icon = Icons.build;
      text = l10n.inProgressStatus;
    } else if (signalement.isAnnule) {
      color = Colors.grey;
      icon = Icons.cancel;
      text = l10n.reportCancelled;
    } else {
      color = AppTheme.warningColor;
      icon = Icons.pending;
      text = l10n.pendingProcessing;
    }

    final iconSize = config.responsive(small: 44, medium: 54, large: 64);
    final titleSize = config.responsive(small: 14, medium: 17, large: 19);
    final dateSize = config.responsive(small: 11, medium: 12, large: 13);
    final pad = config.responsive(small: 14, medium: 17, large: 20);

    final displayText =
        config.isSmall && text.length > 22 ? '${text.substring(0, 20)}…' : text;

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
              color.withOpacity(isDark ? 0.08 : 0.04)
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
          if (signalement.createdAt != null) ...[
            const SizedBox(height: 5),
            Text(
              config.isSmall
                  ? DateFormat('dd/MM/yyyy', l10n.locale.languageCode)
                      .format(signalement.createdAt)
                  : DateFormat('dd MMMM yyyy à HH:mm', l10n.locale.languageCode)
                      .format(signalement.createdAt),
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

class SignalementDetailsCard extends StatelessWidget {
  final Signalement signalement;
  final bool isDark;
  final ResponsiveConfig config;
  final AppLocalizations l10n;
  const SignalementDetailsCard(
      {super.key,
      required this.signalement,
      required this.isDark,
      required this.config,
      required this.l10n});

  @override
  Widget build(BuildContext context) {
    final titleSize = config.responsive(small: 15, medium: 17, large: 18);
    final pad = config.responsive(small: 12, medium: 15, large: 16);

    // Centre tronqué
    final centre = signalement.nomCentre ?? '';
    final displayCentre = config.isSmall && centre.length > 18
        ? '${centre.substring(0, 17)}…'
        : centre;

    final rows = <DetailRowData>[
      DetailRowData(l10n.type, signalement.typeProbleme.replaceAll('_', ' '),
          Icons.category),
      DetailRowData(
          config.isSmall ? l10n.reportedOnShort : l10n.reportedOn,
          config.isSmall
              ? DateFormat('dd/MM/yyyy HH:mm', l10n.locale.languageCode)
                  .format(signalement.createdAt)
              : DateFormat('dd MMMM yyyy à HH:mm', l10n.locale.languageCode)
                  .format(signalement.createdAt),
          Icons.calendar_today),
      if ((signalement.numeroChambre ?? '').isNotEmpty)
        DetailRowData(
            l10n.room, l10n.roomAbbr(signalement.numeroChambre!), Icons.home),
      if (displayCentre.isNotEmpty)
        DetailRowData(l10n.center, displayCentre, Icons.business),
      DetailRowData(l10n.status, signalement.statut, Icons.info),
    ];

    return Card(
      elevation: isDark ? 4 : 2,
      color: isDark ? const Color(0xFF1E1E1E) : null,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: EdgeInsets.all(pad),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(l10n.problemDetails,
              style: TextStyle(
                  fontSize: titleSize,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black87)),
          Divider(
              height: 20,
              color: isDark ? Colors.grey.shade800 : Colors.grey.shade300),
          config.isTablet
              ? _buildTwoCol(rows, isDark, config)
              : _buildOneCol(rows, isDark, config),
          Divider(
              height: 20,
              color: isDark ? Colors.grey.shade800 : Colors.grey.shade300),
          Text(l10n.description,
              style: TextStyle(
                  fontSize: config.responsive(small: 13, medium: 14, large: 15),
                  fontWeight: FontWeight.w500,
                  color: isDark ? Colors.grey.shade300 : Colors.black87)),
          const SizedBox(height: 6),
          Text(signalement.description,
              style: TextStyle(
                  fontSize: config.responsive(small: 13, medium: 14, large: 15),
                  color: isDark ? Colors.grey.shade300 : Colors.grey[700],
                  height: 1.5)),
        ]),
      ),
    );
  }

  Widget _buildOneCol(
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

  Widget _buildTwoCol(
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

class SignalementPhotosSection extends StatelessWidget {
  final Signalement signalement;
  final bool isDark;
  final ResponsiveConfig config;
  final String? authToken;
  final bool isFromCache;
  final void Function(String, {Color bg}) onSnack;
  final void Function(int, bool) onPhotoTap;
  final AppLocalizations l10n;

  const SignalementPhotosSection({
    super.key,
    required this.signalement,
    required this.isDark,
    required this.config,
    required this.authToken,
    required this.isFromCache,
    required this.onSnack,
    required this.onPhotoTap,
    required this.l10n,
  });

  @override
  Widget build(BuildContext context) {
    if (signalement.photos.isEmpty) return const SizedBox.shrink();

    final titleSize = config.responsive(small: 15, medium: 17, large: 18);
    final crossAxis = config.isTablet ? 4 : 3;

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(l10n.photosCount(signalement.photos.length),
          style: TextStyle(
              fontSize: titleSize,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black87)),
      const SizedBox(height: 12),
      GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: crossAxis,
          childAspectRatio: 1,
          crossAxisSpacing: config.isSmall ? 6 : 8,
          mainAxisSpacing: config.isSmall ? 6 : 8,
        ),
        itemCount: signalement.photos.length,
        itemBuilder: (context, index) {
          final rawUrl = signalement.photos[index];
          final photoUrl = rawUrl.startsWith('http')
              ? rawUrl
              : 'https://cenou-backend.onrender.com$rawUrl';

          return GestureDetector(
            onTap: () {
              if (authToken != null) {
                onPhotoTap(index, isDark);
              } else {
                onSnack(l10n.cannotDisplayPhotos);
              }
            },
            child: ClipRRect(
              borderRadius: BorderRadius.circular(config.isSmall ? 6 : 8),
              child: CachedNetworkImage(
                imageUrl: photoUrl,
                fit: BoxFit.cover,
                placeholder: (_, __) => Container(
                  color: isDark ? Colors.grey.shade800 : Colors.grey[300],
                  child: Center(
                      child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Theme.of(context).colorScheme.primary)),
                ),
                errorWidget: (_, __, ___) => Container(
                  color: isDark ? Colors.grey.shade800 : Colors.grey[300],
                  child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error, color: Colors.red, size: 28),
                        const SizedBox(height: 4),
                        Text(l10n.error,
                            style: TextStyle(
                                fontSize: 10, color: Colors.red.shade300)),
                      ]),
                ),
              ),
            ),
          );
        },
      ),
    ]);
  }
}

// ── Résolution ───────────────────────────────────────────────────────────

class SignalementResolutionCard extends StatelessWidget {
  final Signalement signalement;
  final bool isDark;
  final ResponsiveConfig config;
  final AppLocalizations l10n;
  const SignalementResolutionCard(
      {super.key,
      required this.signalement,
      required this.isDark,
      required this.config,
      required this.l10n});

  @override
  Widget build(BuildContext context) {
    final titleSize = config.responsive(small: 15, medium: 17, large: 18);
    final textSize = config.responsive(small: 12, medium: 14, large: 15);
    final pad = config.responsive(small: 12, medium: 15, large: 16);

    return Card(
      elevation: isDark ? 4 : 2,
      color: isDark ? const Color(0xFF1E1E1E) : null,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: EdgeInsets.all(pad),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Icon(Icons.check_circle,
                color: AppTheme.successColor,
                size: config.responsive(small: 20, medium: 22, large: 24)),
            const SizedBox(width: 10),
            Text(l10n.resolution,
                style: TextStyle(
                    fontSize: titleSize,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black87)),
          ]),
          Divider(
              height: 20,
              color: isDark ? Colors.grey.shade800 : Colors.grey.shade300),
          if (signalement.dateResolution != null) ...[
            Text(
              l10n.resolvedOn(config.isSmall
                  ? DateFormat('dd/MM/yyyy', l10n.locale.languageCode)
                      .format(signalement.dateResolution!)
                  : DateFormat('dd MMMM yyyy à HH:mm', l10n.locale.languageCode)
                      .format(signalement.dateResolution!)),
              style: TextStyle(
                  fontSize: textSize,
                  color: isDark ? Colors.grey.shade400 : Colors.grey[600]),
            ),
            const SizedBox(height: 10),
          ],
          if (signalement.commentaireResolution != null) ...[
            Text(l10n.commentLabel,
                style: TextStyle(
                    fontSize: textSize,
                    fontWeight: FontWeight.w500,
                    color: isDark ? Colors.grey.shade300 : Colors.black87)),
            const SizedBox(height: 6),
            Text(signalement.commentaireResolution!,
                style: TextStyle(
                    fontSize: textSize,
                    color: isDark ? Colors.grey.shade300 : Colors.grey[700],
                    height: 1.5)),
          ],
        ]),
      ),
    );
  }
}

// ── Erreur ───────────────────────────────────────────────────────────────
