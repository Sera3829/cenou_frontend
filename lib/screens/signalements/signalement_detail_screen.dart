import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../models/signalement.dart';
import '../../providers/signalement_provider.dart';
import '../../services/connectivity_service.dart';
import '../../services/storage_service.dart';
import '../../utils/mobile_responsive.dart';
import '../../l10n/app_localizations.dart';
import '../../widgets/mobile/detail_widgets.dart';
import 'widgets/signalement_detail_cards.dart';
import 'photo_gallery_screen.dart';

/// Écran détail d'un signalement — responsive mobile/tablette.
class SignalementDetailScreen extends StatefulWidget {
  final int signalementId;
  const SignalementDetailScreen({super.key, required this.signalementId});

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
      final provider = Provider.of<SignalementProvider>(context, listen: false);
      final conn = Provider.of<ConnectivityService>(context, listen: false);
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
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                  color: Colors.amber, borderRadius: BorderRadius.circular(12)),
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
                icon: const Icon(Icons.share),
                onPressed: () {},
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

  Widget _buildBody(bool isDark, ConnectivityService conn,
      ResponsiveConfig config, AppLocalizations l10n) {
    if (_isLoading) {
      return Center(
          child: CircularProgressIndicator(
              color: Theme.of(context).colorScheme.primary));
    }
    if (_error != null) {
      return MobileDetailErrorView(
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
              style: TextStyle(color: isDark ? Colors.white : Colors.black87)));
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
  Widget _buildMobileLayout(
      bool isDark, ResponsiveConfig config, AppLocalizations l10n) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      if (_isFromCache) ...[CacheChip(l10n: l10n), const SizedBox(height: 12)],
      SignalementStatusCard(
          signalement: _signalement!,
          isDark: isDark,
          config: config,
          l10n: l10n),
      SizedBox(height: config.isSmall ? 10 : 14),
      SignalementDetailsCard(
          signalement: _signalement!,
          isDark: isDark,
          config: config,
          l10n: l10n),
      SizedBox(height: config.isSmall ? 10 : 14),
      SignalementPhotosSection(
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
        SignalementResolutionCard(
            signalement: _signalement!,
            isDark: isDark,
            config: config,
            l10n: l10n),
      ],
    ]);
  }

  // ── Layout tablette ──────────────────────────────────────────────────────
  Widget _buildTabletLayout(
      bool isDark, ResponsiveConfig config, AppLocalizations l10n) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      if (_isFromCache) ...[CacheChip(l10n: l10n), const SizedBox(height: 12)],
      Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Expanded(
            child: SignalementStatusCard(
                signalement: _signalement!,
                isDark: isDark,
                config: config,
                l10n: l10n)),
        const SizedBox(width: 16),
        Expanded(
            child: SignalementDetailsCard(
                signalement: _signalement!,
                isDark: isDark,
                config: config,
                l10n: l10n)),
      ]),
      const SizedBox(height: 16),
      SignalementPhotosSection(
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
        SignalementResolutionCard(
            signalement: _signalement!,
            isDark: isDark,
            config: config,
            l10n: l10n),
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
