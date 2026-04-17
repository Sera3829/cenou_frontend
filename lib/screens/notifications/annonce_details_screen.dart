// annonce_details_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../config/theme.dart';
import '../../providers/notification_provider.dart';
import '../../services/connectivity_service.dart';
import '../../l10n/app_localizations.dart';

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

      final provider = Provider.of<NotificationProvider>(context, listen: false);
      final response = await provider.getAnnonceById(widget.annonceId);

      print('RAW RESPONSE: $response');

      if (response == null) {
        throw Exception('Annonce introuvable');
      }

      Map<String, dynamic>? annonce;

// 🔥 Gérer plusieurs formats possibles
      if (response is Map<String, dynamic>) {

        if (response.containsKey('data')) {
          annonce = response['data'];
        } else if (response.containsKey('annonce')) {
          annonce = response['annonce'];
        } else {
          annonce = response; // cas direct
        }

      }

      if (annonce == null) {
        throw Exception('Format de réponse invalide');
      }

      setState(() {
        _annonce = Map<String, dynamic>.from(annonce!);
        _isLoading = false;
      });

    } catch (e) {
      print('ERREUR LOAD ANNONCE: $e');

      final conn = Provider.of<ConnectivityService>(context, listen: false);
      final l10n = AppLocalizations.of(context);

      setState(() {
        _isLoading = false;
        _hasError = true;
        _errorMessage = conn.isOffline
            ? l10n.announceNotAvailableOffline
            : l10n.cannotLoadAnnounce;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final connectivityService = Provider.of<ConnectivityService>(context);

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121212) : AppTheme.backgroundColor,
      appBar: AppBar(
        title: Text(l10n.announceDetails),
        actions: [
          IconButton(
            onPressed: connectivityService.isOnline ? _loadAnnonce : null,
            icon: const Icon(Icons.refresh),
            tooltip: connectivityService.isOffline ? l10n.offline : l10n.refresh,
          ),
        ],
      ),
      body: _buildBody(isDark, connectivityService, l10n),
    );
  }

  /// Construit le contenu principal en fonction de l'état de chargement et de connectivité.
  Widget _buildBody(bool isDark, ConnectivityService connectivityService, AppLocalizations l10n) {
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
              connectivityService.isOffline ? l10n.offline : l10n.error,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage ?? l10n.cannotLoadAnnounce,
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
                child: Text(l10n.retry),
              ),
          ],
        ),
      );
    }

    // Indication visuelle si les données proviennent du cache (hors ligne)
    final isFromCache = connectivityService.isOffline;

    // Sécurisation des champs
    final cible = _annonce!['cible']?.toString() ?? 'TOUS';
    final titre = _annonce!['titre']?.toString() ?? 'Sans titre';
    final contenu = _annonce!['contenu']?.toString() ?? '';
    final totalDestinataires = int.tryParse(
        _annonce!['total_destinataires']?.toString() ?? '0'
    );
    final createdAt = _annonce!['created_at'];
    final createdByNom = _annonce!['created_by_nom'];
    final createdByPrenom = _annonce!['created_by_prenom'];

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
                children: [
                  const Icon(Icons.history, size: 14, color: Colors.amber),
                  const SizedBox(width: 4),
                  Text(
                    l10n.offline,
                    style: const TextStyle(
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
              color: _getTypeColor(cible).withOpacity(isDark ? 0.2 : 0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: _getTypeColor(cible).withOpacity(isDark ? 0.4 : 0.3),
              ),
            ),
            child: Text(
              _getTypeLabel(cible, l10n),
              style: TextStyle(
                color: _getTypeColor(cible),
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Titre
          Text(
            titre,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
          const SizedBox(height: 8),

          // Date de publication
          if (createdAt != null)
            Text(
              l10n.publishedOn(_formatDate(createdAt, l10n)),
              style: TextStyle(
                fontSize: 14,
                color: isDark ? Colors.grey.shade400 : Colors.grey[600],
              ),
            ),
          const SizedBox(height: 4),

          // Auteur
          if (createdByNom != null)
            Text(
              l10n.byAuthor('$createdByNom ${createdByPrenom ?? ''}'.trim()),
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
              contenu,
              style: TextStyle(
                fontSize: 16,
                height: 1.5,
                color: isDark ? Colors.grey.shade300 : Colors.black87,
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Informations sur les destinataires
          if (totalDestinataires != null) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(isDark ? 0.2 : 0.05),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Colors.blue.withOpacity(isDark ? 0.4 : 0.2),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.group,
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    l10n.sentToNPeople(totalDestinataires),
                  ),
                ],
              ),
            ),
          ]
        ],
      ),
    );
  }

  /// Formate la date pour l'affichage.
  String _formatDate(dynamic date, AppLocalizations l10n) {
    try {
      if (date is String) {
        return DateFormat('dd/MM/yyyy à HH:mm', l10n.locale.languageCode).format(DateTime.parse(date));
      } else if (date is DateTime) {
        return DateFormat('dd/MM/yyyy à HH:mm', l10n.locale.languageCode).format(date);
      }
      return l10n.unknownDate;
    } catch (e) {
      return l10n.unknownDate;
    }
  }

  /// Retourne le libellé du type d'annonce.
  String _getTypeLabel(String cible, AppLocalizations l10n) {
    switch (cible) {
      case 'TOUS':
        return l10n.announceTypeGeneral;
      case 'CENTRE_SPECIFIQUE':
        return l10n.announceTypeByCenter;
      case 'ETUDIANTS':
        return l10n.announceTypeSpecificStudents;
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