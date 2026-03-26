import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../config/theme.dart';
import '../../providers/paiement_provider.dart';
import '../../services/connectivity_service.dart';
import '../../models/paiement.dart';
import '../../services/paiement_service.dart';

class PaiementDetailScreen extends StatefulWidget {
  final int paiementId;

  const PaiementDetailScreen({
    Key? key,
    required this.paiementId,
  }) : super(key: key);

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
      final connectivityService = Provider.of<ConnectivityService>(context, listen: false);

      // 1. Chercher d'abord dans la liste des paiements déjà chargés
      final existingPaiement = provider.paiements.firstWhere(
            (p) => p.id == widget.paiementId,
        orElse: () => throw Exception('Not found'),
      );

      setState(() {
        _paiement = existingPaiement;
        _isLoading = false;
        _isFromCache = provider.isFromCache;
      });

    } catch (e) {
      // 2. Si pas trouvé dans la liste, charger individuellement
      await _loadPaiementIndividuel();
    }
  }

  Future<void> _loadPaiementIndividuel() async {
    try {
      final provider = Provider.of<PaiementProvider>(context, listen: false);
      final connectivityService = Provider.of<ConnectivityService>(context, listen: false);

      final isOnline = connectivityService.isOnline;

      if (isOnline) {
        // En ligne : charger depuis l'API via le service
        final paiementService = PaiementService();
        final paiement = await paiementService.getPaiementById(widget.paiementId);

        setState(() {
          _paiement = paiement;
          _isLoading = false;
          _isFromCache = false;
        });
      } else {
        // Hors ligne : essayer de trouver dans le cache via le provider
        // Note: Il faudrait ajouter une méthode dans PaiementProvider pour chercher par ID
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

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final connectivityService = Provider.of<ConnectivityService>(context);

    return Scaffold(
      backgroundColor: isDark ? Color(0xFF121212) : AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('Détails du paiement'),
        actions: [
          // Badge "Cache" si nécessaire
          if (_isFromCache)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.amber,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Icon(Icons.history, size: 14, color: Colors.white),
                    SizedBox(width: 4),
                    Text(
                      'Hors ligne',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          if (_paiement != null)
            IconButton(
              icon: const Icon(Icons.share),
              onPressed: () {
                // TODO: Partager le reçu
              },
            ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: connectivityService.isOnline ? _loadPaiement : null,
            tooltip: connectivityService.isOffline ? 'Hors ligne' : 'Rafraîchir',
          ),
        ],
      ),
      body: _buildBody(isDark, connectivityService),
    );
  }

  Widget _buildBody(bool isDark, ConnectivityService connectivityService) {
    if (_isLoading) {
      return Center(
        child: CircularProgressIndicator(
          color: Theme.of(context).colorScheme.primary,
        ),
      );
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
                connectivityService.isOffline ? Icons.wifi_off : Icons.error_outline,
                size: 64,
                color: isDark ? Colors.grey.shade600 : Colors.grey[400]
            ),
            const SizedBox(height: 16),
            Text(
                connectivityService.isOffline ? 'Hors ligne' : 'Erreur de chargement',
                style: TextStyle(
                    fontSize: 18,
                    color: isDark ? Colors.grey.shade300 : Colors.grey[600]
                )
            ),
            const SizedBox(height: 8),
            Text(
                _error!,
                textAlign: TextAlign.center,
                style: TextStyle(
                    color: isDark ? Colors.grey.shade400 : Colors.grey[500]
                )
            ),
            const SizedBox(height: 16),
            if (connectivityService.isOnline)
              ElevatedButton.icon(
                onPressed: _loadPaiement,
                icon: const Icon(Icons.refresh),
                label: const Text('Réessayer'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Colors.white,
                ),
              ),
          ],
        ),
      );
    }

    if (_paiement == null) {
      return Center(
        child: Text(
          'Paiement introuvable',
          style: TextStyle(
            color: isDark ? Colors.white : Colors.black87,
          ),
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Indicateur "Cache" en haut
          if (_isFromCache) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.amber.withOpacity(isDark ? 0.2 : 0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: Colors.amber.withOpacity(isDark ? 0.4 : 0.3),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  Icon(Icons.history, size: 14, color: Colors.amber),
                  SizedBox(width: 4),
                  Text(
                    'Données hors ligne',
                    style: TextStyle(
                      color: Colors.amber,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
          ],

          _buildStatusCard(isDark),
          const SizedBox(height: 16),
          _buildMontantCard(isDark),
          const SizedBox(height: 16),
          _buildDetailsCard(isDark),
          const SizedBox(height: 16),
          if (_paiement!.isConfirme) _buildReceiptSection(isDark),
        ],
      ),
    );
  }

  Widget _buildStatusCard(bool isDark) {
    Color statusColor;
    IconData statusIcon;
    String statusText;

    if (_paiement!.isConfirme) {
      statusColor = AppTheme.successColor;
      statusIcon = Icons.check_circle;
      statusText = 'Paiement confirmé';
    } else if (_paiement!.isEchec) {
      statusColor = AppTheme.errorColor;
      statusIcon = Icons.cancel;
      statusText = 'Paiement échoué';
    } else {
      statusColor = AppTheme.warningColor;
      statusIcon = Icons.pending;
      statusText = 'En attente de confirmation';
    }

    return Card(
      elevation: isDark ? 4 : 2,
      color: isDark ? Color(0xFF1E1E1E) : null,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
            colors: [
              statusColor.withOpacity(isDark ? 0.2 : 0.1),
              statusColor.withOpacity(isDark ? 0.1 : 0.05)
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          children: [
            Icon(statusIcon, size: 64, color: statusColor),
            const SizedBox(height: 12),
            Text(
              statusText,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: statusColor,
              ),
            ),
            if (_paiement!.datePaiement != null) ...[
              const SizedBox(height: 8),
              Text(
                DateFormat('dd MMMM yyyy à HH:mm', 'fr_FR').format(_paiement!.datePaiement!),
                style: TextStyle(
                    color: isDark ? Colors.grey.shade400 : Colors.grey[600]
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildMontantCard(bool isDark) {
    return Card(
      elevation: isDark ? 4 : 2,
      color: isDark ? Color(0xFF1E1E1E) : null,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Text(
              'Montant',
              style: TextStyle(
                fontSize: 14,
                color: isDark ? Colors.grey.shade400 : Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '${NumberFormat('#,###').format(_paiement!.montant)} FCFA',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailsCard(bool isDark) {
    return Card(
      elevation: isDark ? 4 : 2,
      color: isDark ? Color(0xFF1E1E1E) : null,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Informations',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
            Divider(
              height: 24,
              color: isDark ? Colors.grey.shade800 : Colors.grey.shade300,
            ),
            _buildDetailRow(
              'Mode de paiement',
              _paiement!.modePaiement.replaceAll('_', ' '),
              Icons.payment,
              isDark,
            ),
            const SizedBox(height: 12),
            _buildDetailRow(
              'Référence',
              _paiement!.referenceTransaction ?? 'N/A',
              Icons.receipt,
              isDark,
            ),
            const SizedBox(height: 12),
            _buildDetailRow(
              'Date d\'échéance',
              DateFormat('dd/MM/yyyy').format(_paiement!.dateEcheance as DateTime),
              Icons.calendar_today,
              isDark,
            ),
            if (_paiement!.numeroChambre != null) ...[
              const SizedBox(height: 12),
              _buildDetailRow(
                'Chambre',
                '${_paiement!.numeroChambre} (${_paiement!.numeroChambre})',
                Icons.home,
                isDark,
              ),
            ],
            if (_paiement!.nomCentre != null) ...[
              const SizedBox(height: 12),
              _buildDetailRow(
                'Centre',
                _paiement!.nomCentre!,
                Icons.business,
                isDark,
              ),
            ],
            const SizedBox(height: 12),
            _buildDetailRow(
              'Statut',
              _paiement!.statut,
              Icons.info,
              isDark,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, IconData icon, bool isDark) {
    return Row(
      children: [
        Icon(
            icon,
            size: 20,
            color: isDark ? Colors.grey.shade400 : Colors.grey[600]
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: isDark ? Colors.grey.shade400 : Colors.grey[600],
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildReceiptSection(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Reçu',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : Colors.black87,
          ),
        ),
        const SizedBox(height: 12),
        Card(
          elevation: isDark ? 4 : 2,
          color: isDark ? Color(0xFF1E1E1E) : null,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Column(
            children: [
              ListTile(
                leading: Icon(Icons.picture_as_pdf, color: AppTheme.errorColor),
                title: Text(
                  'Télécharger le reçu PDF',
                  style: TextStyle(
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
                trailing: Icon(
                  Icons.download,
                  color: isDark ? Colors.grey.shade400 : Colors.grey[600],
                ),
                onTap: () {
                  if (!_isFromCache) {
                    // TODO: Télécharger le reçu PDF
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Fonctionnalité bientôt disponible'),
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Téléchargement non disponible hors ligne'),
                        backgroundColor: Colors.orange,
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  }
                },
              ),
              Divider(
                height: 1,
                color: isDark ? Colors.grey.shade800 : Colors.grey.shade300,
              ),
              ListTile(
                leading: Icon(Icons.share, color: Theme.of(context).colorScheme.primary),
                title: Text(
                  'Partager le reçu',
                  style: TextStyle(
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
                trailing: Icon(
                  Icons.arrow_forward_ios,
                  size: 16,
                  color: isDark ? Colors.grey.shade400 : Colors.grey[600],
                ),
                onTap: () {
                  if (!_isFromCache) {
                    // TODO: Partager le reçu
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Fonctionnalité bientôt disponible'),
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Partage non disponible hors ligne'),
                        backgroundColor: Colors.orange,
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
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