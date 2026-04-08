import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';
import '../../app_config.dart';
import '../../config/theme.dart';
import '../../models/signalement.dart';
import '../../providers/signalement_provider.dart';
import '../../services/connectivity_service.dart';
import '../../services/signalement_service.dart';
import '../../services/storage_service.dart';
import '../../utils/mobile_responsive.dart';
import '../../l10n/app_localizations.dart';

/// Écran détail d'un signalement — responsive mobile/tablette.
class SignalementDetailScreen extends StatefulWidget {
  final int signalementId;
  const SignalementDetailScreen({Key? key, required this.signalementId})
      : super(key: key);

  @override
  State<SignalementDetailScreen> createState() =>
      _SignalementDetailScreenState();
}

class _SignalementDetailScreenState extends State<SignalementDetailScreen> {
  Signalement? _signalement;
  bool _isLoading = true;
  String? _error;
  String? _authToken;
  bool _isFromCache = false;

  @override
  void initState() {
    super.initState();
    _loadSignalement();
  }

  Future<void> _loadSignalement() async {
    setState(() {
      _isLoading = true;
      _error = null;
      _isFromCache = false;
    });
    try {
      final provider =
      Provider.of<SignalementProvider>(context, listen: false);
      final conn =
      Provider.of<ConnectivityService>(context, listen: false);
      final signalement =
      await provider.getSignalementById(widget.signalementId);
      if (signalement == null) throw Exception('Signalement non trouvé');
      final token = await StorageService().getToken();
      setState(() {
        _signalement = signalement;
        _authToken = token;
        _isLoading = false;
        _isFromCache = provider.isFromCache || conn.isOffline;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  void _showSnack(String msg, {Color bg = Colors.orange}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: bg,
      behavior: SnackBarBehavior.floating,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final conn = Provider.of<ConnectivityService>(context);

    return Scaffold(
      backgroundColor:
      isDark ? const Color(0xFF121212) : AppTheme.backgroundColor,
      appBar: AppBar(
        title: Text(l10n.reportDetails,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 18)),
        actions: [
          if (_isFromCache)
            Container(
              margin: const EdgeInsets.only(right: 6),
              padding:
              const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                  color: Colors.amber,
                  borderRadius: BorderRadius.circular(12)),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                const Icon(Icons.history, size: 13, color: Colors.white),
                const SizedBox(width: 3),
                Text(l10n.offline,
                    style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: Colors.white)),
              ]),
            ),
          if (_signalement != null)
            IconButton(
                icon: const Icon(Icons.share), onPressed: () {},
                tooltip: l10n.share),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: conn.isOnline ? _loadSignalement : null,
            tooltip: conn.isOffline ? l10n.offline : l10n.refresh,
          ),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final config = ResponsiveConfig.fromConstraints(constraints);
          return _buildBody(isDark, conn, config, l10n);
        },
      ),
    );
  }

  Widget _buildBody(
      bool isDark, ConnectivityService conn, ResponsiveConfig config, AppLocalizations l10n) {
    if (_isLoading) {
      return Center(
          child: CircularProgressIndicator(
              color: Theme.of(context as BuildContext).colorScheme.primary));
    }
    if (_error != null) {
      return _ErrorView(
        error: _error!,
        isDark: isDark,
        isOffline: conn.isOffline,
        config: config,
        onRetry: conn.isOnline ? _loadSignalement : null,
        l10n: l10n,
      );
    }
    if (_signalement == null) {
      return Center(
          child: Text(l10n.reportNotFound,
              style: TextStyle(
                  color: isDark ? Colors.white : Colors.black87)));
    }

    final hPad = config.isSmall ? 12.0 : 16.0;

    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(hPad, hPad, hPad, 24),
      child: config.isTablet
          ? _buildTabletLayout(isDark, config, l10n)
          : _buildMobileLayout(isDark, config, l10n),
    );
  }

  // ── Layout mobile ────────────────────────────────────────────────────────
  Widget _buildMobileLayout(bool isDark, ResponsiveConfig config, AppLocalizations l10n) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      if (_isFromCache) ...[_CacheBanner(l10n: l10n), const SizedBox(height: 12)],
      _StatusCard(signalement: _signalement!, isDark: isDark, config: config, l10n: l10n),
      SizedBox(height: config.isSmall ? 10 : 14),
      _DetailsCard(signalement: _signalement!, isDark: isDark, config: config, l10n: l10n),
      SizedBox(height: config.isSmall ? 10 : 14),
      _PhotosSection(
          signalement: _signalement!,
          isDark: isDark,
          config: config,
          authToken: _authToken,
          isFromCache: _isFromCache,
          onSnack: _showSnack,
          onPhotoTap: _showPhotoGallery,
          l10n: l10n),
      if (_signalement!.isResolu) ...[
        SizedBox(height: config.isSmall ? 10 : 14),
        _ResolutionCard(
            signalement: _signalement!, isDark: isDark, config: config, l10n: l10n),
      ],
    ]);
  }

  // ── Layout tablette ──────────────────────────────────────────────────────
  Widget _buildTabletLayout(bool isDark, ResponsiveConfig config, AppLocalizations l10n) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      if (_isFromCache) ...[_CacheBanner(l10n: l10n), const SizedBox(height: 12)],
      Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Expanded(
            child: _StatusCard(
                signalement: _signalement!, isDark: isDark, config: config, l10n: l10n)),
        const SizedBox(width: 16),
        Expanded(
            child: _DetailsCard(
                signalement: _signalement!, isDark: isDark, config: config, l10n: l10n)),
      ]),
      const SizedBox(height: 16),
      _PhotosSection(
          signalement: _signalement!,
          isDark: isDark,
          config: config,
          authToken: _authToken,
          isFromCache: _isFromCache,
          onSnack: _showSnack,
          onPhotoTap: _showPhotoGallery,
          l10n: l10n),
      if (_signalement!.isResolu) ...[
        const SizedBox(height: 16),
        _ResolutionCard(
            signalement: _signalement!, isDark: isDark, config: config, l10n: l10n),
      ],
    ]);
  }

  void _showPhotoGallery(int initialIndex, bool isDark) {
    if (_authToken == null) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PhotoGalleryScreen(
          signalementId: _signalement!.id,
          photoCount: _signalement!.photos.length,
          initialIndex: initialIndex,
          token: _authToken!,
          photos: _signalement!.photos,
          isDark: isDark,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// Widgets internes
// ─────────────────────────────────────────────────────────────────

class _CacheBanner extends StatelessWidget {
  final AppLocalizations l10n;
  const _CacheBanner({required this.l10n});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding:
      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.amber.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.amber.withOpacity(0.4)),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        const Icon(Icons.history, size: 14, color: Colors.amber),
        const SizedBox(width: 4),
        Text(l10n.offlineData,
            style: const TextStyle(
                color: Colors.amber,
                fontSize: 12,
                fontWeight: FontWeight.w600)),
      ]),
    );
  }
}

class _StatusCard extends StatelessWidget {
  final Signalement signalement;
  final bool isDark;
  final ResponsiveConfig config;
  final AppLocalizations l10n;
  const _StatusCard(
      {required this.signalement,
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

    final iconSize  = config.responsive(small: 44, medium: 54, large: 64);
    final titleSize = config.responsive(small: 14, medium: 17, large: 19);
    final dateSize  = config.responsive(small: 11, medium: 12, large: 13);
    final pad       = config.responsive(small: 14, medium: 17, large: 20);

    final displayText = config.isSmall && text.length > 22
        ? '${text.substring(0, 20)}…'
        : text;

    return Card(
      elevation: isDark ? 4 : 2,
      color: isDark ? const Color(0xFF1E1E1E) : null,
      shape:
      RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
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
                  ? DateFormat('dd/MM/yyyy', l10n.locale.languageCode).format(signalement.createdAt)
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

class _DetailsCard extends StatelessWidget {
  final Signalement signalement;
  final bool isDark;
  final ResponsiveConfig config;
  final AppLocalizations l10n;
  const _DetailsCard(
      {required this.signalement,
        required this.isDark,
        required this.config,
        required this.l10n});

  @override
  Widget build(BuildContext context) {
    final titleSize = config.responsive(small: 15, medium: 17, large: 18);
    final pad       = config.responsive(small: 12, medium: 15, large: 16);

    // Centre tronqué
    final centre = signalement.nomCentre ?? '';
    final displayCentre = config.isSmall && centre.length > 18
        ? '${centre.substring(0, 17)}…'
        : centre;

    final rows = <_DetailRowData>[
      _DetailRowData(
          l10n.type,
          signalement.typeProbleme.replaceAll('_', ' '),
          Icons.category),
      _DetailRowData(
          config.isSmall ? l10n.reportedOnShort : l10n.reportedOn,
          config.isSmall
              ? DateFormat('dd/MM/yyyy HH:mm', l10n.locale.languageCode).format(signalement.createdAt)
              : DateFormat('dd MMMM yyyy à HH:mm', l10n.locale.languageCode)
              .format(signalement.createdAt),
          Icons.calendar_today),
      if ((signalement.numeroChambre ?? '').isNotEmpty)
        _DetailRowData(l10n.room, l10n.roomAbbr(signalement.numeroChambre!), Icons.home),
      if (displayCentre.isNotEmpty)
        _DetailRowData(l10n.center, displayCentre, Icons.business),
      _DetailRowData(l10n.status, signalement.statut, Icons.info),
    ];

    return Card(
      elevation: isDark ? 4 : 2,
      color: isDark ? const Color(0xFF1E1E1E) : null,
      shape:
      RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
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
                  fontSize:
                  config.responsive(small: 13, medium: 14, large: 15),
                  color: isDark ? Colors.grey.shade300 : Colors.grey[700],
                  height: 1.5)),
        ]),
      ),
    );
  }

  Widget _buildOneCol(
      List<_DetailRowData> rows, bool isDark, ResponsiveConfig config) {
    return Column(
      children: rows
          .map((r) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: _DetailRow(
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
      List<_DetailRowData> rows, bool isDark, ResponsiveConfig config) {
    final pairs = <Widget>[];
    for (var i = 0; i < rows.length; i += 2) {
      pairs.add(Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Expanded(
            child: _DetailRow(
                label: rows[i].label,
                value: rows[i].value,
                icon: rows[i].icon,
                isDark: isDark,
                config: config)),
        if (i + 1 < rows.length) ...[
          const SizedBox(width: 16),
          Expanded(
              child: _DetailRow(
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

class _DetailRowData {
  final String label, value;
  final IconData icon;
  const _DetailRowData(this.label, this.value, this.icon);
}

class _DetailRow extends StatelessWidget {
  final String label, value;
  final IconData icon;
  final bool isDark;
  final ResponsiveConfig config;
  const _DetailRow(
      {required this.label,
        required this.value,
        required this.icon,
        required this.isDark,
        required this.config});

  @override
  Widget build(BuildContext context) {
    final iconSize  = config.responsive(small: 16, medium: 18, large: 20);
    final labelSize = config.responsive(small: 10, medium: 11, large: 12);
    final valueSize = config.responsive(small: 12, medium: 14, large: 15);

    return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Icon(icon,
          size: iconSize,
          color: isDark ? Colors.grey.shade400 : Colors.grey[600]),
      const SizedBox(width: 10),
      Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(label,
                style: TextStyle(
                    fontSize: labelSize,
                    color: isDark ? Colors.grey.shade400 : Colors.grey[600])),
            const SizedBox(height: 2),
            Text(value,
                style: TextStyle(
                    fontSize: valueSize,
                    fontWeight: FontWeight.w500,
                    color: isDark ? Colors.white : Colors.black87),
                maxLines: 2,
                overflow: TextOverflow.ellipsis),
          ])),
    ]);
  }
}

// ── Photos ───────────────────────────────────────────────────────────────

class _PhotosSection extends StatelessWidget {
  final Signalement signalement;
  final bool isDark;
  final ResponsiveConfig config;
  final String? authToken;
  final bool isFromCache;
  final void Function(String, {Color bg}) onSnack;
  final void Function(int, bool) onPhotoTap;
  final AppLocalizations l10n;

  const _PhotosSection({
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
                          color:
                          Theme.of(context).colorScheme.primary)),
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

class _ResolutionCard extends StatelessWidget {
  final Signalement signalement;
  final bool isDark;
  final ResponsiveConfig config;
  final AppLocalizations l10n;
  const _ResolutionCard(
      {required this.signalement,
        required this.isDark,
        required this.config,
        required this.l10n});

  @override
  Widget build(BuildContext context) {
    final titleSize = config.responsive(small: 15, medium: 17, large: 18);
    final textSize  = config.responsive(small: 12, medium: 14, large: 15);
    final pad       = config.responsive(small: 12, medium: 15, large: 16);

    return Card(
      elevation: isDark ? 4 : 2,
      color: isDark ? const Color(0xFF1E1E1E) : null,
      shape:
      RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: EdgeInsets.all(pad),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Icon(Icons.check_circle, color: AppTheme.successColor,
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
              l10n.resolvedOn(
                  config.isSmall
                      ? DateFormat('dd/MM/yyyy', l10n.locale.languageCode).format(signalement.dateResolution!)
                      : DateFormat('dd MMMM yyyy à HH:mm', l10n.locale.languageCode).format(signalement.dateResolution!)
              ),
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

class _ErrorView extends StatelessWidget {
  final String error;
  final bool isDark, isOffline;
  final ResponsiveConfig config;
  final VoidCallback? onRetry;
  final AppLocalizations l10n;
  const _ErrorView(
      {required this.error,
        required this.isDark,
        required this.isOffline,
        required this.config,
        required this.onRetry,
        required this.l10n});

  @override
  Widget build(BuildContext context) {
    final iconSize  = config.responsive(small: 52, medium: 62, large: 70);
    final titleSize = config.responsive(small: 15, medium: 17, large: 18);
    final bodySize  = config.responsive(small: 12, medium: 13, large: 14);
    final hPad      = config.responsive(small: 24, medium: 36, large: 48);

    final displayError =
    config.isSmall && error.length > 70 ? '${error.substring(0, 69)}…' : error;

    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: hPad),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(isOffline ? Icons.wifi_off : Icons.error_outline,
              size: iconSize,
              color: isDark ? Colors.grey.shade600 : Colors.grey[400]),
          const SizedBox(height: 14),
          Text(isOffline ? l10n.offline : l10n.loadingError,
              style: TextStyle(
                  fontSize: titleSize,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.grey.shade300 : Colors.grey[600])),
          const SizedBox(height: 8),
          Text(displayError,
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: bodySize,
                  color: isDark ? Colors.grey.shade400 : Colors.grey[500],
                  height: 1.4)),
          if (onRetry != null) ...[
            const SizedBox(height: 22),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh, size: 18),
              label: Text(l10n.retry),
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(
                    horizontal: config.isSmall ? 20 : 28,
                    vertical: config.isSmall ? 11 : 13),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ]),
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════
// Galerie photo plein écran
// ════════════════════════════════════════════════════════════════

class PhotoGalleryScreen extends StatefulWidget {
  final int signalementId;
  final int photoCount;
  final int initialIndex;
  final String token;
  final List<String> photos;
  final bool isDark;

  const PhotoGalleryScreen({
    Key? key,
    required this.signalementId,
    required this.photoCount,
    required this.initialIndex,
    required this.token,
    required this.photos,
    required this.isDark,
  }) : super(key: key);

  @override
  State<PhotoGalleryScreen> createState() => _PhotoGalleryScreenState();
}

class _PhotoGalleryScreenState extends State<PhotoGalleryScreen> {
  late PageController _pageController;
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final svc = SignalementService();
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text('${_currentIndex + 1} / ${widget.photoCount}'),
      ),
      body: PhotoViewGallery.builder(
        scrollPhysics: const BouncingScrollPhysics(),
        builder: (_, index) {
          final url = svc.getPhotoUrl(
              widget.signalementId, index, widget.photos);
          return PhotoViewGalleryPageOptions(
            imageProvider: CachedNetworkImageProvider(url,
                headers: {'Authorization': 'Bearer ${widget.token}'}),
            initialScale: PhotoViewComputedScale.contained,
            minScale: PhotoViewComputedScale.contained,
            maxScale: PhotoViewComputedScale.covered * 2,
          );
        },
        itemCount: widget.photoCount,
        loadingBuilder: (_, __) =>
        const Center(child: CircularProgressIndicator(color: Colors.white)),
        pageController: _pageController,
        onPageChanged: (i) => setState(() => _currentIndex = i),
      ),
    );
  }
}