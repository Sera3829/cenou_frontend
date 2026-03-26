import 'dart:math';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';
import '../../config/theme.dart';
import '../../models/signalement.dart';
import '../../providers/signalement_provider.dart';
import '../../services/connectivity_service.dart';
import '../../services/signalement_service.dart';
import '../../services/storage_service.dart';

/// Écran d'affichage des détails d'un signalement.
class SignalementDetailScreen extends StatefulWidget {
  final int signalementId;

  const SignalementDetailScreen({
    Key? key,
    required this.signalementId,
  }) : super(key: key);

  @override
  State<SignalementDetailScreen> createState() => _SignalementDetailScreenState();
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
    print('Initialisation SignalementDetailScreen');
    _loadSignalement();
  }

  /// Charge les détails du signalement via le provider.
  Future<void> _loadSignalement() async {
    setState(() {
      _isLoading = true;
      _error = null;
      _isFromCache = false;
    });

    try {
      final provider = Provider.of<SignalementProvider>(context, listen: false);
      final connectivityService = Provider.of<ConnectivityService>(context, listen: false);

      final signalement = await provider.getSignalementById(widget.signalementId);

      if (signalement == null) {
        throw Exception('Signalement non trouvé');
      }

      final storageService = StorageService();
      final token = await storageService.getToken();

      setState(() {
        _signalement = signalement;
        _authToken = token;
        _isLoading = false;
        _isFromCache = provider.isFromCache || connectivityService.isOffline;
      });

      print('Signalement charge: ${signalement.id}');
      print('Depuis le cache: $_isFromCache');

    } catch (e) {
      print('Erreur lors du chargement du signalement: $e');
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
      backgroundColor: isDark ? const Color(0xFF121212) : AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('Détails du signalement'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: connectivityService.isOnline ? _loadSignalement : null,
            tooltip: connectivityService.isOffline ? 'Hors ligne' : 'Rafraîchir',
          ),
        ],
      ),
      body: _buildBody(isDark, connectivityService),
    );
  }

  /// Construit le contenu principal en fonction de l'état.
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
                onPressed: _loadSignalement,
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

    if (_signalement == null) {
      return Center(
        child: Text(
          'Signalement introuvable',
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
          // Indicateur de mode hors ligne
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
          _buildDetailsCard(isDark),
          const SizedBox(height: 16),
          _buildPhotosSection(isDark),
          if (_signalement!.isResolu) ...[
            const SizedBox(height: 16),
            _buildResolutionCard(isDark),
          ],
        ],
      ),
    );
  }

  /// Carte affichant le statut du signalement.
  Widget _buildStatusCard(bool isDark) {
    Color statusColor;
    IconData statusIcon;
    String statusText;

    if (_signalement!.isResolu) {
      statusColor = AppTheme.successColor;
      statusIcon = Icons.check_circle;
      statusText = 'Problème résolu';
    } else if (_signalement!.isEnCours) {
      statusColor = AppTheme.infoColor;
      statusIcon = Icons.build;
      statusText = 'En cours de traitement';
    } else if (_signalement!.isAnnule) {
      statusColor = Colors.grey;
      statusIcon = Icons.cancel;
      statusText = 'Signalement annulé';
    } else {
      statusColor = AppTheme.warningColor;
      statusIcon = Icons.pending;
      statusText = 'En attente de traitement';
    }

    return Card(
      elevation: isDark ? 4 : 2,
      color: isDark ? const Color(0xFF1E1E1E) : null,
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
            const SizedBox(height: 8),
            Text(
              'Signalement ' + _signalement!.id.toString().replaceAll('_', ' '),
              style: TextStyle(
                fontSize: 16,
                color: isDark ? Colors.grey.shade400 : Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Carte affichant les détails du signalement.
  Widget _buildDetailsCard(bool isDark) {
    return Card(
      elevation: isDark ? 4 : 2,
      color: isDark ? const Color(0xFF1E1E1E) : null,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Détails du problème',
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
                'Type',
                _signalement!.typeProbleme.replaceAll('_', ' '),
                Icons.category,
                isDark
            ),
            const SizedBox(height: 12),
            _buildDetailRow(
                'Signalé le',
                DateFormat('dd MMMM yyyy à HH:mm', 'fr_FR').format(_signalement!.createdAt),
                Icons.calendar_today,
                isDark
            ),
            if (_signalement!.numeroChambre != null) ...[
              const SizedBox(height: 12),
              _buildDetailRow(
                  'Chambre',
                  _signalement!.numeroChambre!,
                  Icons.home,
                  isDark
              ),
            ],
            if (_signalement!.nomCentre != null) ...[
              const SizedBox(height: 12),
              _buildDetailRow(
                  'Centre',
                  _signalement!.nomCentre!,
                  Icons.business,
                  isDark
              ),
            ],
            Divider(
              height: 24,
              color: isDark ? Colors.grey.shade800 : Colors.grey.shade300,
            ),
            Text(
              'Description',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: isDark ? Colors.grey.shade300 : Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _signalement!.description,
              style: TextStyle(
                  fontSize: 15,
                  color: isDark ? Colors.grey.shade300 : Colors.grey[700],
                  height: 1.5
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Ligne d'information dans la carte des détails.
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
                      color: isDark ? Colors.grey.shade400 : Colors.grey[600]
                  )
              ),
              const SizedBox(height: 2),
              Text(
                  value,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: isDark ? Colors.white : Colors.black87,
                  )
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Section d'affichage des photos.
  Widget _buildPhotosSection(bool isDark) {
    if (_signalement!.photos.isEmpty) {
      return const SizedBox.shrink();
    }

    print('Construction galerie - Token disponible: ${_authToken != null}');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Photos',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : Colors.black87,
          ),
        ),
        const SizedBox(height: 12),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            childAspectRatio: 1,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
          ),
          itemCount: _signalement!.photos.length,
          itemBuilder: (context, index) {
            final signalementService = SignalementService();
            final photoUrl = signalementService.getPhotoUrl(
              _signalement!.id,
              index,
              _signalement!.photos,
            );

            print('Photo $index: $photoUrl');

            return GestureDetector(
              onTap: () {
                if (_authToken != null) {
                  _showPhotoGallery(index, isDark);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Impossible d\'afficher les photos'),
                      backgroundColor: Colors.orange,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              },
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: CachedNetworkImage(
                  imageUrl: photoUrl,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => Container(
                    color: isDark ? Colors.grey.shade800 : Colors.grey[300],
                    child: Center(
                      child: CircularProgressIndicator(
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ),
                  errorWidget: (context, url, error) {
                    print('Erreur photo $index: $error - URL: $url');
                    return Container(
                      color: isDark ? Colors.grey.shade800 : Colors.grey[300],
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.error, color: Colors.red, size: 32),
                          const SizedBox(height: 4),
                          Text(
                              'Erreur',
                              style: TextStyle(
                                  fontSize: 10,
                                  color: Colors.red
                              )
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  /// Affiche la galerie photo en plein écran.
  void _showPhotoGallery(int initialIndex, bool isDark) {
    if (_authToken == null) return;

    print("Token utilise pour les images: ${_authToken?.substring(0, 20)}...");
    final signalementService = SignalementService();
    final testUrl = signalementService.getPhotoUrl(
      _signalement!.id,
      initialIndex,
      _signalement!.photos,
    );
    print("URL test: $testUrl");

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PhotoGalleryScreen(
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

  /// Carte affichant la résolution du signalement (si résolu).
  Widget _buildResolutionCard(bool isDark) {
    return Card(
      elevation: isDark ? 4 : 2,
      color: isDark ? const Color(0xFF1E1E1E) : null,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                    Icons.check_circle,
                    color: AppTheme.successColor
                ),
                const SizedBox(width: 12),
                Text(
                    'Résolution',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Colors.black87,
                    )
                ),
              ],
            ),
            Divider(
              height: 24,
              color: isDark ? Colors.grey.shade800 : Colors.grey.shade300,
            ),
            if (_signalement!.dateResolution != null) ...[
              Text(
                'Résolu le ${DateFormat('dd MMMM yyyy à HH:mm', 'fr_FR').format(_signalement!.dateResolution!)}',
                style: TextStyle(
                    fontSize: 14,
                    color: isDark ? Colors.grey.shade400 : Colors.grey[600]
                ),
              ),
              const SizedBox(height: 12),
            ],
            if (_signalement!.commentaireResolution != null) ...[
              Text(
                  'Commentaire :',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: isDark ? Colors.grey.shade300 : Colors.black87,
                  )
              ),
              const SizedBox(height: 8),
              Text(
                _signalement!.commentaireResolution!,
                style: TextStyle(
                    fontSize: 15,
                    color: isDark ? Colors.grey.shade300 : Colors.grey[700],
                    height: 1.5
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Écran de galerie photo en plein écran.
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
    final signalementService = SignalementService();

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text('${_currentIndex + 1} / ${widget.photoCount}'),
      ),
      body: PhotoViewGallery.builder(
        scrollPhysics: const BouncingScrollPhysics(),
        builder: (BuildContext context, int index) {
          final photoUrl = signalementService.getPhotoUrl(
            widget.signalementId,
            index,
            widget.photos,
          );

          return PhotoViewGalleryPageOptions(
            imageProvider: CachedNetworkImageProvider(
              photoUrl,
              headers: {'Authorization': 'Bearer ${widget.token}'},
            ),
            initialScale: PhotoViewComputedScale.contained,
            minScale: PhotoViewComputedScale.contained,
            maxScale: PhotoViewComputedScale.covered * 2,
          );
        },
        itemCount: widget.photoCount,
        loadingBuilder: (context, event) => const Center(
          child: CircularProgressIndicator(
            color: Colors.white,
          ),
        ),
        pageController: _pageController,
        onPageChanged: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
      ),
    );
  }
}