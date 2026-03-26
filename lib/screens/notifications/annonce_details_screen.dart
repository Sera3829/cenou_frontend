// annonce_details_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../config/theme.dart';
import '../../providers/notification_provider.dart';
import '../../services/connectivity_service.dart';

/// Écran d'affichage des détails d'une annonce.
class AnnonceDetailsScreen extends StatefulWidget {
  final int annonceId;

  const AnnonceDetailsScreen({Key? key, required this.annonceId}) : super(key: key);

  @override
  State<AnnonceDetailsScreen> createState() => _AnnonceDetailsScreenState();
}

class _AnnonceDetailsScreenState extends State<AnnonceDetailsScreen> {
  Map<String, dynamic>? _annonce;
  bool _isLoading = true;
  bool _hasError = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadAnnonce();
  }

  /// Charge les détails de l'annonce via le provider.
  Future<void> _loadAnnonce() async {
    try {
      setState(() {
        _isLoading = true;
        _hasError = false;
        _errorMessage = null;
      });

      final notificationProvider = Provider.of<NotificationProvider>(context, listen: false);
      final annonce = await notificationProvider.getAnnonceById(widget.annonceId);

      setState(() {
        _annonce = annonce;
        _isLoading = false;
      });
    } catch (e) {
      print('Erreur lors du chargement de l\'annonce: $e');

      final connectivityService = Provider.of<ConnectivityService>(context, listen: false);

      setState(() {
        _isLoading = false;
        _hasError = true;
        _errorMessage = connectivityService.isOffline
            ? 'Cette annonce n\'est pas disponible hors ligne'
            : 'Impossible de charger l\'annonce';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final connectivityService = Provider.of<ConnectivityService>(context);

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121212) : AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('Détails de l\'annonce'),
        actions: [
          IconButton(
            onPressed: connectivityService.isOnline ? _loadAnnonce : null,
            icon: const Icon(Icons.refresh),
            tooltip: connectivityService.isOffline ? 'Hors ligne' : 'Rafraîchir',
          ),
        ],
      ),
      body: _buildBody(isDark, connectivityService),
    );
  }

  /// Construit le contenu principal en fonction de l'état de chargement et de connectivité.
  Widget _buildBody(bool isDark, ConnectivityService connectivityService) {
    if (_isLoading) {
      return Center(
        child: CircularProgressIndicator(
          color: Theme.of(context).colorScheme.primary,
        ),
      );
    }

    if (_hasError || _annonce == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
                connectivityService.isOffline ? Icons.wifi_off : Icons.error_outline,
                size: 64,
                color: isDark ? Colors.red.shade400 : Colors.red
            ),
            const SizedBox(height: 16),
            Text(
              connectivityService.isOffline ? 'Hors ligne' : 'Erreur',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage ?? 'Impossible de charger l\'annonce',
              style: TextStyle(
                color: isDark ? Colors.grey.shade400 : Colors.grey[600],
              ),
            ),
            const SizedBox(height: 24),
            if (connectivityService.isOnline)
              ElevatedButton(
                onPressed: _loadAnnonce,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Réessayer'),
              ),
          ],
        ),
      );
    }

    // Indication visuelle si les données proviennent du cache (hors ligne)
    final isFromCache = connectivityService.isOffline;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isFromCache) ...[
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
                    'Hors ligne',
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

          // Badge du type d'annonce
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: _getTypeColor(_annonce!['cible']).withOpacity(isDark ? 0.2 : 0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: _getTypeColor(_annonce!['cible']).withOpacity(isDark ? 0.4 : 0.3),
              ),
            ),
            child: Text(
              _getTypeLabel(_annonce!['cible']),
              style: TextStyle(
                color: _getTypeColor(_annonce!['cible']),
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Titre
          Text(
            _annonce!['titre'],
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
          const SizedBox(height: 8),

          // Date de publication
          Text(
            'Publiée le ${_formatDate(_annonce!['created_at'])}',
            style: TextStyle(
              fontSize: 14,
              color: isDark ? Colors.grey.shade400 : Colors.grey[600],
            ),
          ),
          const SizedBox(height: 4),

          // Auteur
          if (_annonce!['created_by_nom'] != null)
            Text(
              'Par ${_annonce!['created_by_nom']} ${_annonce!['created_by_prenom'] ?? ''}',
              style: TextStyle(
                fontSize: 14,
                color: isDark ? Colors.grey.shade400 : Colors.grey[600],
              ),
            ),
          const SizedBox(height: 24),

          // Contenu de l'annonce
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(isDark ? 0.2 : 0.05),
                  blurRadius: 10,
                ),
              ],
            ),
            child: Text(
              _annonce!['contenu'],
              style: TextStyle(
                fontSize: 16,
                height: 1.5,
                color: isDark ? Colors.grey.shade300 : Colors.black87,
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Informations sur les destinataires
          if (_annonce!['total_destinataires'] != null)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(isDark ? 0.2 : 0.05),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                    color: Colors.blue.withOpacity(isDark ? 0.4 : 0.2)
                ),
              ),
              child: Row(
                children: [
                  Icon(
                      Icons.group,
                      size: 16,
                      color: isDark ? Colors.blue.shade300 : Colors.blue
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Envoyée à ${_annonce!['total_destinataires']} personne(s)',
                    style: TextStyle(
                      color: isDark ? Colors.blue.shade300 : Colors.blue,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  /// Formate la date pour l'affichage.
  String _formatDate(dynamic date) {
    try {
      if (date is String) {
        return DateFormat('dd/MM/yyyy à HH:mm').format(DateTime.parse(date));
      } else if (date is DateTime) {
        return DateFormat('dd/MM/yyyy à HH:mm').format(date);
      }
      return 'Date inconnue';
    } catch (e) {
      return 'Date inconnue';
    }
  }

  /// Retourne le libellé du type d'annonce.
  String _getTypeLabel(String cible) {
    switch (cible) {
      case 'TOUS':
        return 'Générale';
      case 'CENTRE_SPECIFIQUE':
        return 'Par centre';
      case 'ETUDIANTS':
        return 'Étudiants spécifiques';
      default:
        return cible;
    }
  }

  /// Retourne la couleur associée au type d'annonce.
  Color _getTypeColor(String cible) {
    switch (cible) {
      case 'TOUS':
        return Colors.blue;
      case 'CENTRE_SPECIFIQUE':
        return Colors.green;
      case 'ETUDIANTS':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }
}