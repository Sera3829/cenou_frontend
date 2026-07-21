import 'package:flutter/material.dart';
import 'package:printing/printing.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/paiement_provider.dart';
import '../../services/connectivity_service.dart';
import '../../services/paiement_service.dart';
import '../../models/paiement.dart';
import '../../utils/mobile_responsive.dart';
import 'package:share_plus/share_plus.dart';
import '../../services/receipt_pdf_service.dart';
import '../../l10n/app_localizations.dart';
import '../../widgets/mobile/detail_widgets.dart';
import 'widgets/paiement_detail_cards.dart';

class PaiementDetailScreen extends StatefulWidget {
  final int paiementId;
  const PaiementDetailScreen({super.key, required this.paiementId});

  @override
  State<PaiementDetailScreen> createState() => _PaiementDetailScreenState();
}

class _PaiementDetailScreenState extends State<PaiementDetailScreen> {
  Paiement? _paiement;
  bool _isLoading = true;
  bool _isActioning = false; // spinner pendant téléchargement/partage
  String? _error;
  bool _isFromCache = false;

  @override
  void initState() {
    super.initState();
    _loadPaiement();
  }

  // ── Chargement ─────────────────────────────────────────────────────────

  Future<void> _loadPaiement() async {
    setState(() {
      _isLoading = true;
      _error = null;
      _isFromCache = false;
    });
    try {
      final provider = Provider.of<PaiementProvider>(context, listen: false);
      final existing = provider.paiements.firstWhere(
        (p) => p.id == widget.paiementId,
        orElse: () => throw Exception('Not found'),
      );
      setState(() {
        _paiement = existing;
        _isLoading = false;
        _isFromCache = provider.isFromCache;
      });
    } catch (_) {
      await _loadIndividuel();
    }
  }

  Future<void> _loadIndividuel() async {
    final l10n = AppLocalizations.of(context);
    try {
      final conn = Provider.of<ConnectivityService>(context, listen: false);
      if (conn.isOnline) {
        final p = await PaiementService().getPaiementById(widget.paiementId);
        setState(() {
          _paiement = p;
          _isLoading = false;
        });
      } else {
        setState(() {
          _error = l10n.paymentNotAvailableOffline;
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  // ── Helpers nom étudiant ───────────────────────────────────────────────

  /// Retourne le nom complet depuis AuthProvider (source la plus fiable).
  String get _studentName {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    return auth.userFullName.isNotEmpty
        ? auth.userFullName
        : [_paiement?.prenom, _paiement?.nom]
            .whereType<String>()
            .where((s) => s.isNotEmpty)
            .join(' ');
  }

  String get _studentMatricule {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    return auth.user?.matricule ?? _paiement?.matricule ?? '';
  }

  String get _pdfFileName =>
      'recu_cenou_${_paiement?.referenceTransaction ?? _paiement?.id}.pdf';

  // ── Actions reçu ──────────────────────────────────────────────────────

  /// Ouvre le viewer PDF système (impression / aperçu).
  Future<void> _downloadReceipt() async {
    final l10n = AppLocalizations.of(context);
    if (_paiement == null || _isActioning) return;
    setState(() => _isActioning = true);
    try {
      _showSnack(l10n.generatingPdf, bg: Colors.blue);
      final pdf = await ReceiptPdfService.generateReceipt(
        _paiement!,
        studentName: _studentName,
        studentMatricule: _studentMatricule,
      );

      // Sauvegarder dans Downloads puis ouvrir
      final savedPath =
          await ReceiptPdfService.savePdfToDownloads(pdf, _pdfFileName);

      // Ouvrir avec le viewer système
      await Printing.layoutPdf(
        onLayout: (_) async => await pdf.save(),
        name: _pdfFileName,
      );

      _showSnack(l10n.pdfSavedTo(savedPath), bg: Colors.green);
    } catch (e) {
      _showSnack('${l10n.error}: $e', bg: Colors.red);
    } finally {
      if (mounted) setState(() => _isActioning = false);
    }
  }

  /// Génère le PDF et ouvre le sélecteur de partage natif.
  Future<void> _shareReceipt() async {
    final l10n = AppLocalizations.of(context);
    if (_paiement == null || _isActioning) return;
    setState(() => _isActioning = true);
    try {
      _showSnack(l10n.preparingShare, bg: Colors.blue);
      final pdf = await ReceiptPdfService.generateReceipt(
        _paiement!,
        studentName: _studentName,
        studentMatricule: _studentMatricule,
      );
      final file = await ReceiptPdfService.savePdfToTemp(pdf, _pdfFileName);
      await Share.shareXFiles(
        [XFile(file.path, mimeType: 'application/pdf')],
        subject: l10n.receiptSubject,
        text: l10n.receiptShareText(
            _paiement!.referenceTransaction ?? _paiement!.id.toString()),
      );
    } catch (e) {
      _showSnack('${l10n.shareError}: $e', bg: Colors.red);
    } finally {
      if (mounted) setState(() => _isActioning = false);
    }
  }

  void _showSnack(String msg, {Color bg = Colors.orange}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: bg,
      behavior: SnackBarBehavior.floating,
    ));
  }

  // ── Build ──────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final conn = Provider.of<ConnectivityService>(context);

    return Scaffold(
      backgroundColor:
          isDark ? const Color(0xFF121212) : AppTheme.backgroundColor,
      appBar: AppBar(
        title: Text(l10n.paymentDetails,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 18)),
        actions: [
          if (_isFromCache)
            Container(
              margin: const EdgeInsets.only(right: 6),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                  color: Colors.amber, borderRadius: BorderRadius.circular(12)),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.history, size: 13, color: Colors.white),
                  const SizedBox(width: 3),
                  Text(l10n.offline,
                      style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: Colors.white)),
                ],
              ),
            ),
          // Bouton partage rapide dans l'AppBar
          if (_paiement != null && _paiement!.isConfirme && !_isFromCache)
            _isActioning
                ? const Padding(
                    padding: EdgeInsets.all(12),
                    child: SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2)),
                  )
                : IconButton(
                    icon: const Icon(Icons.share),
                    onPressed: _shareReceipt,
                    tooltip: l10n.shareReceipt,
                  ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: conn.isOnline ? _loadPaiement : null,
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
        onRetry: conn.isOnline ? _loadPaiement : null,
        l10n: l10n,
      );
    }
    if (_paiement == null) {
      return Center(
          child: Text(l10n.paymentNotFound,
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

  // ── Layouts ────────────────────────────────────────────────────────────

  Widget _buildMobileLayout(
      bool isDark, ResponsiveConfig config, AppLocalizations l10n) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      if (_isFromCache) ...[CacheChip(l10n: l10n), const SizedBox(height: 12)],
      PaiementStatusCard(
          paiement: _paiement!, isDark: isDark, config: config, l10n: l10n),
      SizedBox(height: config.isSmall ? 10 : 14),
      PaiementMontantCard(
          paiement: _paiement!, isDark: isDark, config: config, l10n: l10n),
      SizedBox(height: config.isSmall ? 10 : 14),
      PaiementDetailsCard(
          paiement: _paiement!, isDark: isDark, config: config, l10n: l10n),
      if (_paiement!.isConfirme) ...[
        SizedBox(height: config.isSmall ? 10 : 14),
        PaiementReceiptCard(
          isDark: isDark,
          isFromCache: _isFromCache,
          isActioning: _isActioning,
          config: config,
          onSnack: _showSnack,
          onDownload: _downloadReceipt,
          onShare: _shareReceipt,
          l10n: l10n,
        ),
      ],
    ]);
  }

  Widget _buildTabletLayout(
      bool isDark, ResponsiveConfig config, AppLocalizations l10n) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      if (_isFromCache) ...[CacheChip(l10n: l10n), const SizedBox(height: 12)],
      Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Expanded(
            child: PaiementStatusCard(
                paiement: _paiement!,
                isDark: isDark,
                config: config,
                l10n: l10n)),
        const SizedBox(width: 16),
        Expanded(
            child: PaiementMontantCard(
                paiement: _paiement!,
                isDark: isDark,
                config: config,
                l10n: l10n)),
      ]),
      const SizedBox(height: 16),
      PaiementDetailsCard(
          paiement: _paiement!, isDark: isDark, config: config, l10n: l10n),
      if (_paiement!.isConfirme) ...[
        const SizedBox(height: 16),
        PaiementReceiptCard(
          isDark: isDark,
          isFromCache: _isFromCache,
          isActioning: _isActioning,
          config: config,
          onSnack: _showSnack,
          onDownload: _downloadReceipt,
          onShare: _shareReceipt,
          l10n: l10n,
        ),
      ],
    ]);
  }
}

// ══════════════════════════════════════════════════════════════
// Widgets internes
// ══════════════════════════════════════════════════════════════
