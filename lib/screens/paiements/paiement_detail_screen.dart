import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../config/theme.dart';
import '../../providers/paiement_provider.dart';
import '../../services/connectivity_service.dart';
import '../../services/paiement_service.dart';
import '../../models/paiement.dart';
import '../../utils/mobile_responsive.dart';

class PaiementDetailScreen extends StatefulWidget {
  final int paiementId;
  const PaiementDetailScreen({Key? key, required this.paiementId})
      : super(key: key);

  @override
  State<PaiementDetailScreen> createState() => _PaiementDetailScreenState();
}

class _PaiementDetailScreenState extends State<PaiementDetailScreen> {
  Paiement? _paiement;
  bool _isLoading = true;
  String? _error;
  bool _isFromCache = false;

  @override
  void initState() {
    super.initState();
    _loadPaiement();
  }

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
          _error = 'Paiement non disponible hors ligne';
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

  void _showSnack(String msg, {Color bg = Colors.orange}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: bg,
      behavior: SnackBarBehavior.floating,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final conn = Provider.of<ConnectivityService>(context);

    return Scaffold(
      backgroundColor:
      isDark ? const Color(0xFF121212) : AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text(
          'Détails du paiement',
          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 18),
        ),
        actions: [
          if (_isFromCache)
            Container(
              margin: const EdgeInsets.only(right: 6),
              padding:
              const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.amber,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.history, size: 13, color: Colors.white),
                  SizedBox(width: 3),
                  Text('Hors ligne',
                      style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: Colors.white)),
                ],
              ),
            ),
          if (_paiement != null)
            IconButton(
              icon: const Icon(Icons.share),
              onPressed: () {},
              tooltip: 'Partager',
            ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: conn.isOnline ? _loadPaiement : null,
            tooltip: conn.isOffline ? 'Hors ligne' : 'Rafraîchir',
          ),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final config = ResponsiveConfig.fromConstraints(constraints);
          return _buildBody(isDark, conn, config);
        },
      ),
    );
  }

  Widget _buildBody(
      bool isDark, ConnectivityService conn, ResponsiveConfig config) {
    if (_isLoading) {
      return Center(
        child: CircularProgressIndicator(
            color: Theme.of(context).colorScheme.primary),
      );
    }

    if (_error != null) {
      return _ErrorView(
          error: _error!,
          isDark: isDark,
          isOffline: conn.isOffline,
          config: config,
          onRetry: conn.isOnline ? _loadPaiement : null);
    }

    if (_paiement == null) {
      return Center(
        child: Text('Paiement introuvable',
            style:
            TextStyle(color: isDark ? Colors.white : Colors.black87)),
      );
    }

    final hPad = config.isSmall ? 12.0 : 16.0;

    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(hPad, hPad, hPad, 24),
      child: config.isTablet
          ? _buildTabletLayout(isDark, config)
          : _buildMobileLayout(isDark, config),
    );
  }

  // ── Layout mobile : colonnes empilées ────────────────────────────────────
  Widget _buildMobileLayout(bool isDark, ResponsiveConfig config) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_isFromCache) ...[_CacheBanner(), const SizedBox(height: 12)],
        _StatusCard(paiement: _paiement!, isDark: isDark, config: config),
        SizedBox(height: config.isSmall ? 10 : 14),
        _MontantCard(paiement: _paiement!, isDark: isDark, config: config),
        SizedBox(height: config.isSmall ? 10 : 14),
        _DetailsCard(paiement: _paiement!, isDark: isDark, config: config),
        if (_paiement!.isConfirme) ...[
          SizedBox(height: config.isSmall ? 10 : 14),
          _ReceiptCard(
              isDark: isDark,
              isFromCache: _isFromCache,
              config: config,
              onSnack: _showSnack),
        ],
      ],
    );
  }

  // ── Layout tablette : statut + montant côte à côte, puis détails plein ───
  Widget _buildTabletLayout(bool isDark, ResponsiveConfig config) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_isFromCache) ...[_CacheBanner(), const SizedBox(height: 12)],
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _StatusCard(
                  paiement: _paiement!, isDark: isDark, config: config),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _MontantCard(
                  paiement: _paiement!, isDark: isDark, config: config),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _DetailsCard(paiement: _paiement!, isDark: isDark, config: config),
        if (_paiement!.isConfirme) ...[
          const SizedBox(height: 16),
          _ReceiptCard(
              isDark: isDark,
              isFromCache: _isFromCache,
              config: config,
              onSnack: _showSnack),
        ],
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// Widgets internes : PaiementDetail
// ─────────────────────────────────────────────────────────────────

class _CacheBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.amber.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.amber.withOpacity(0.4)),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.history, size: 14, color: Colors.amber),
          SizedBox(width: 4),
          Text('Données hors ligne',
              style: TextStyle(
                  color: Colors.amber,
                  fontSize: 12,
                  fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

class _StatusCard extends StatelessWidget {
  final Paiement paiement;
  final bool isDark;
  final ResponsiveConfig config;
  const _StatusCard(
      {required this.paiement, required this.isDark, required this.config});

  @override
  Widget build(BuildContext context) {
    Color color;
    IconData icon;
    String text;

    if (paiement.isConfirme) {
      color = AppTheme.successColor;
      icon = Icons.check_circle;
      text = 'Paiement confirmé';
    } else if (paiement.isEchec) {
      color = AppTheme.errorColor;
      icon = Icons.cancel;
      text = 'Paiement échoué';
    } else {
      color = AppTheme.warningColor;
      icon = Icons.pending;
      text = 'En attente de confirmation';
    }

    final iconSize = config.responsive(small: 48, medium: 58, large: 66);
    final titleSize = config.responsive(small: 16, medium: 18, large: 20);
    final dateSize = config.responsive(small: 12, medium: 13, large: 14);
    final pad = config.responsive(small: 14, medium: 18, large: 20);

    // Texte de statut tronqué sur petit écran
    final displayText =
    config.isSmall && text.length > 22 ? 'En attente…' : text;

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
              color.withOpacity(isDark ? 0.08 : 0.04),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          children: [
            Icon(icon, size: iconSize, color: color),
            const SizedBox(height: 10),
            Text(
              displayText,
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: titleSize,
                  fontWeight: FontWeight.bold,
                  color: color),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            if (paiement.datePaiement != null) ...[
              const SizedBox(height: 6),
              Text(
                config.isSmall
                    ? DateFormat('dd/MM/yyyy HH:mm')
                    .format(paiement.datePaiement!)
                    : DateFormat('dd MMMM yyyy à HH:mm', 'fr_FR')
                    .format(paiement.datePaiement!),
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontSize: dateSize,
                    color: isDark
                        ? Colors.grey.shade400
                        : Colors.grey[600]),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _MontantCard extends StatelessWidget {
  final Paiement paiement;
  final bool isDark;
  final ResponsiveConfig config;
  const _MontantCard(
      {required this.paiement, required this.isDark, required this.config});

  @override
  Widget build(BuildContext context) {
    final amountSize = config.responsive(small: 26, medium: 30, large: 34);
    final labelSize = config.responsive(small: 12, medium: 13, large: 14);
    final pad = config.responsive(small: 14, medium: 18, large: 20);

    return Card(
      elevation: isDark ? 4 : 2,
      color: isDark ? const Color(0xFF1E1E1E) : null,
      shape:
      RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.all(pad),
        child: Column(
          children: [
            Text(
              'Montant',
              style: TextStyle(
                  fontSize: labelSize,
                  color: isDark ? Colors.grey.shade400 : Colors.grey[600]),
            ),
            const SizedBox(height: 8),
            Text(
              '${NumberFormat('#,###').format(paiement.montant)} FCFA',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: amountSize,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.primary,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

class _DetailsCard extends StatelessWidget {
  final Paiement paiement;
  final bool isDark;
  final ResponsiveConfig config;
  const _DetailsCard(
      {required this.paiement, required this.isDark, required this.config});

  @override
  Widget build(BuildContext context) {
    final titleSize = config.responsive(small: 15, medium: 17, large: 18);
    final pad = config.responsive(small: 12, medium: 15, large: 16);

    // Référence tronquée
    final ref = paiement.referenceTransaction ?? 'N/A';
    final displayRef =
    config.isSmall && ref.length > 16 ? '${ref.substring(0, 15)}…' : ref;

    // Centre tronqué
    final centre = paiement.nomCentre ?? '';
    final displayCentre = config.isSmall && centre.length > 18
        ? '${centre.substring(0, 17)}…'
        : centre;

    final rows = <_DetailRowData>[
      _DetailRowData('Mode de paiement',
          paiement.modePaiement.replaceAll('_', ' '), Icons.payment),
      _DetailRowData('Référence', displayRef, Icons.receipt),
      if (paiement.dateEcheance != null)
        _DetailRowData(
            config.isSmall ? 'Échéance' : 'Date d\'échéance',
            DateFormat('dd/MM/yyyy').format(paiement.dateEcheance as DateTime),
            Icons.calendar_today),
      if ((paiement.numeroChambre ?? '').isNotEmpty)
        _DetailRowData('Chambre', 'Ch. ${paiement.numeroChambre}', Icons.home),
      if (displayCentre.isNotEmpty)
        _DetailRowData('Centre', displayCentre, Icons.business),
      _DetailRowData('Statut', paiement.statut, Icons.info),
    ];

    return Card(
      elevation: isDark ? 4 : 2,
      color: isDark ? const Color(0xFF1E1E1E) : null,
      shape:
      RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: EdgeInsets.all(pad),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Informations',
                style: TextStyle(
                    fontSize: titleSize,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black87)),
            Divider(
                height: 20,
                color: isDark
                    ? Colors.grey.shade800
                    : Colors.grey.shade300),
            // Sur tablette : 2 colonnes
            config.isTablet
                ? _buildTwoColumnRows(rows, isDark, config)
                : _buildSingleColumnRows(rows, isDark, config),
          ],
        ),
      ),
    );
  }

  Widget _buildSingleColumnRows(
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

  Widget _buildTwoColumnRows(
      List<_DetailRowData> rows, bool isDark, ResponsiveConfig config) {
    final pairs = <Widget>[];
    for (var i = 0; i < rows.length; i += 2) {
      pairs.add(Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: _DetailRow(
                label: rows[i].label,
                value: rows[i].value,
                icon: rows[i].icon,
                isDark: isDark,
                config: config),
          ),
          if (i + 1 < rows.length) ...[
            const SizedBox(width: 16),
            Expanded(
              child: _DetailRow(
                  label: rows[i + 1].label,
                  value: rows[i + 1].value,
                  icon: rows[i + 1].icon,
                  isDark: isDark,
                  config: config),
            ),
          ],
        ],
      ));
      if (i + 2 < rows.length) pairs.add(const SizedBox(height: 12));
    }
    return Column(children: pairs);
  }
}

class _DetailRowData {
  final String label;
  final String value;
  final IconData icon;
  const _DetailRowData(this.label, this.value, this.icon);
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final bool isDark;
  final ResponsiveConfig config;
  const _DetailRow({
    required this.label,
    required this.value,
    required this.icon,
    required this.isDark,
    required this.config,
  });

  @override
  Widget build(BuildContext context) {
    final iconSize = config.responsive(small: 17, medium: 19, large: 20);
    final labelSize = config.responsive(small: 11, medium: 12, large: 12);
    final valueSize = config.responsive(small: 13, medium: 15, large: 16);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon,
            size: iconSize,
            color: isDark ? Colors.grey.shade400 : Colors.grey[600]),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: TextStyle(
                      fontSize: labelSize,
                      color: isDark
                          ? Colors.grey.shade400
                          : Colors.grey[600])),
              const SizedBox(height: 2),
              Text(value,
                  style: TextStyle(
                      fontSize: valueSize,
                      fontWeight: FontWeight.w500,
                      color: isDark ? Colors.white : Colors.black87),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis),
            ],
          ),
        ),
      ],
    );
  }
}

class _ReceiptCard extends StatelessWidget {
  final bool isDark;
  final bool isFromCache;
  final ResponsiveConfig config;
  final void Function(String, {Color bg}) onSnack;
  const _ReceiptCard({
    required this.isDark,
    required this.isFromCache,
    required this.config,
    required this.onSnack,
  });

  @override
  Widget build(BuildContext context) {
    final titleSize = config.responsive(small: 15, medium: 17, large: 18);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Reçu',
            style: TextStyle(
                fontSize: titleSize,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black87)),
        const SizedBox(height: 10),
        Card(
          elevation: isDark ? 4 : 2,
          color: isDark ? const Color(0xFF1E1E1E) : null,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14)),
          child: Column(
            children: [
              ListTile(
                leading: Icon(Icons.picture_as_pdf,
                    color: AppTheme.errorColor,
                    size: config.isSmall ? 22 : 26),
                title: Text(
                  config.isSmall ? 'Télécharger PDF' : 'Télécharger le reçu PDF',
                  style: TextStyle(
                      fontSize: config.responsive(small: 13, medium: 15, large: 15),
                      color: isDark ? Colors.white : Colors.black87),
                ),
                trailing: Icon(Icons.download,
                    color: isDark ? Colors.grey.shade400 : Colors.grey[600],
                    size: 20),
                onTap: () {
                  if (isFromCache) {
                    onSnack('Téléchargement non disponible hors ligne');
                  } else {
                    onSnack('Fonctionnalité bientôt disponible',
                        bg: Theme.of(context).colorScheme.primary);
                  }
                },
              ),
              Divider(
                  height: 1,
                  color: isDark
                      ? Colors.grey.shade800
                      : Colors.grey.shade300),
              ListTile(
                leading: Icon(Icons.share,
                    color: Theme.of(context).colorScheme.primary,
                    size: config.isSmall ? 22 : 26),
                title: Text(
                  'Partager le reçu',
                  style: TextStyle(
                      fontSize: config.responsive(small: 13, medium: 15, large: 15),
                      color: isDark ? Colors.white : Colors.black87),
                ),
                trailing: Icon(Icons.arrow_forward_ios,
                    size: 14,
                    color: isDark ? Colors.grey.shade400 : Colors.grey[600]),
                onTap: () {
                  if (isFromCache) {
                    onSnack('Partage non disponible hors ligne');
                  } else {
                    onSnack('Fonctionnalité bientôt disponible',
                        bg: Theme.of(context).colorScheme.primary);
                  }
                },
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String error;
  final bool isDark;
  final bool isOffline;
  final ResponsiveConfig config;
  final VoidCallback? onRetry;
  const _ErrorView({
    required this.error,
    required this.isDark,
    required this.isOffline,
    required this.config,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final iconSize = config.responsive(small: 52, medium: 62, large: 70);
    final titleSize = config.responsive(small: 15, medium: 17, large: 18);
    final bodySize = config.responsive(small: 12, medium: 13, large: 14);
    final displayError = config.isSmall && error.length > 70
        ? '${error.substring(0, 69)}…'
        : error;

    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(
            horizontal: config.responsive(small: 24, medium: 36, large: 48)),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isOffline ? Icons.wifi_off : Icons.error_outline,
              size: iconSize,
              color: isDark ? Colors.grey.shade600 : Colors.grey[400],
            ),
            const SizedBox(height: 14),
            Text(
              isOffline ? 'Hors ligne' : 'Erreur de chargement',
              style: TextStyle(
                  fontSize: titleSize,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.grey.shade300 : Colors.grey[600]),
            ),
            const SizedBox(height: 8),
            Text(
              displayError,
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: bodySize,
                  color: isDark ? Colors.grey.shade400 : Colors.grey[500],
                  height: 1.4),
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 22),
              ElevatedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh, size: 18),
                label: const Text('Réessayer'),
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                  Theme.of(context).colorScheme.primary,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(
                      horizontal: config.isSmall ? 20 : 28,
                      vertical: config.isSmall ? 11 : 13),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}