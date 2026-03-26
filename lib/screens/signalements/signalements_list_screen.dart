import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../config/theme.dart';
import '../../providers/signalement_provider.dart';
import '../../services/connectivity_service.dart';
import '../../models/signalement.dart';
import 'signalement_detail_screen.dart';
import 'create_signalement_screen.dart';

/// Écran affichant la liste des signalements de l'utilisateur.
class SignalementsListScreen extends StatefulWidget {
  const SignalementsListScreen({Key? key}) : super(key: key);

  @override
  State<SignalementsListScreen> createState() => _SignalementsListScreenState();
}

class _SignalementsListScreenState extends State<SignalementsListScreen> {
  @override
  void initState() {
    super.initState();
    // Charge les signalements après le premier affichage
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<SignalementProvider>(context, listen: false).loadSignalements();
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121212) : AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text(
          'Mes Signalements',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
        actions: [
          // Indicateur de cache (données hors ligne)
          Consumer<SignalementProvider>(
            builder: (context, provider, _) {
              if (provider.isFromCache) {
                return Container(
                  margin: const EdgeInsets.only(right: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
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
                        'Cache',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                );
              }
              return const SizedBox.shrink();
            },
          ),

          // Bouton d'information sur les types de problèmes
          IconButton(
            icon: const Icon(Icons.info_outline_rounded),
            onPressed: _showInfoDialog,
            tooltip: 'Types de problèmes',
          ),
        ],
      ),
      body: Consumer<SignalementProvider>(
        builder: (context, signalementProvider, _) {
          if (signalementProvider.isLoading && signalementProvider.signalements.isEmpty) {
            return const _LoadingState();
          }

          if (signalementProvider.error != null) {
            return _buildErrorState(signalementProvider, isDark);
          }

          return RefreshIndicator(
            onRefresh: () => signalementProvider.refresh(),
            color: Theme.of(context).colorScheme.primary,
            backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                // Carte des statistiques
                SliverToBoxAdapter(
                  child: _buildStatsCard(signalementProvider),
                ),

                // En-tête de la liste
                if (signalementProvider.signalements.isNotEmpty)
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
                    sliver: SliverToBoxAdapter(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Historique (${signalementProvider.totalSignalements})',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: isDark ? Colors.grey.shade300 : Colors.grey[700],
                            ),
                          ),
                          if (signalementProvider.signalements.isNotEmpty)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                              decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.primary.withOpacity(isDark ? 0.2 : 0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                '${signalementProvider.totalSignalements} signalement(s)',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),

                // Liste des signalements
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 80),
                  sliver: signalementProvider.signalements.isEmpty
                      ? SliverToBoxAdapter(child: _buildEmptyState(isDark))
                      : SliverList(
                    delegate: SliverChildBuilderDelegate(
                          (context, index) {
                        final signalement = signalementProvider.signalements[index];
                        return _buildSignalementCard(context, signalement, isDark);
                      },
                      childCount: signalementProvider.signalements.length,
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'btn_ajouter_signalement',
        onPressed: () {
          // Vérification de la connexion avant de créer un signalement
          final connectivity = Provider.of<ConnectivityService>(context, listen: false);
          if (connectivity.isOffline) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Connexion internet requise pour créer un signalement'),
                backgroundColor: Colors.orange,
              ),
            );
            return;
          }

          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const CreateSignalementScreen(),
            ),
          );
        },
        icon: const Icon(Icons.add_rounded, size: 22),
        label: const Text(
          'Créer un signalement',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        backgroundColor: AppTheme.errorColor,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        elevation: 4,
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  /// Construit la carte des statistiques.
  Widget _buildStatsCard(SignalementProvider provider) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.errorColor,
            AppTheme.errorColor.withOpacity(0.85),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppTheme.errorColor.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Titre
          Row(
            children: [
              Icon(
                Icons.bar_chart_rounded,
                color: Colors.white.withOpacity(0.9),
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Aperçu des signalements',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.9),
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Grille des indicateurs
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 4,
            childAspectRatio: 0.9,
            crossAxisSpacing: 12,
            mainAxisSpacing: 0,
            children: [
              _buildStatItem(
                'Total',
                provider.totalSignalements.toString(),
                Icons.report_problem_rounded,
                Colors.white.withOpacity(0.9),
              ),
              _buildStatItem(
                'En attente',
                provider.signalementsEnAttente.toString(),
                Icons.pending_actions_rounded,
                Colors.amber[300]!,
              ),
              _buildStatItem(
                'En cours',
                provider.signalementsEnCours.toString(),
                Icons.build_rounded,
                Colors.blue[300]!,
              ),
              _buildStatItem(
                'Résolus',
                provider.signalementsResolus.toString(),
                Icons.check_circle_rounded,
                Colors.green[300]!,
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Construit un élément de statistique.
  Widget _buildStatItem(String label, String value, IconData icon, Color iconColor) {
    return FittedBox(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: iconColor,
              size: 20,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withOpacity(0.8),
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  /// Construit une carte représentant un signalement.
  Widget _buildSignalementCard(BuildContext context, Signalement signalement, bool isDark) {
    final statusInfo = _getStatusInfo(signalement);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Card(
        elevation: isDark ? 4 : 1,
        color: isDark ? const Color(0xFF1E1E1E) : null,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => SignalementDetailScreen(signalementId: signalement.id),
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // En-tête avec statut et numéro de suivi
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Badge de statut
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: statusInfo.color.withOpacity(isDark ? 0.2 : 0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            statusInfo.icon,
                            color: statusInfo.color,
                            size: 14,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            signalement.statut.replaceAll('_', ' '),
                            style: TextStyle(
                              color: statusInfo.color,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Spacer(),
                    // Numéro de suivi
                    Text(
                      signalement.numeroSuivi,
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? Colors.grey.shade400 : Colors.grey[500],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Type de problème
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary.withOpacity(isDark ? 0.2 : 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        _getProblemTypeIcon(signalement.typeProbleme),
                        color: Theme.of(context).colorScheme.primary,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        signalement.typeProbleme.replaceAll('_', ' '),
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Description
                Text(
                  signalement.description,
                  style: TextStyle(
                    fontSize: 14,
                    color: isDark ? Colors.grey.shade300 : Colors.grey[700],
                    height: 1.5,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 16),

                // Pied de carte : date, nombre de photos, chambre
                Row(
                  children: [
                    // Date
                    Row(
                      children: [
                        Icon(
                          Icons.calendar_today_rounded,
                          size: 14,
                          color: isDark ? Colors.grey.shade400 : Colors.grey[500],
                        ),
                        const SizedBox(width: 6),
                        Text(
                          DateFormat('dd MMM yyyy - HH:mm').format(signalement.createdAt),
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark ? Colors.grey.shade400 : Colors.grey[600],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                    // Photos
                    if (signalement.photos.isNotEmpty)
                      Row(
                        children: [
                          Icon(
                            Icons.photo_library_rounded,
                            size: 14,
                            color: isDark ? Colors.grey.shade400 : Colors.grey[500],
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${signalement.photos.length}',
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark ? Colors.grey.shade400 : Colors.grey[600],
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    // Chambre (si disponible)
                    if (signalement.numeroChambre != null && signalement.numeroChambre!.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(left: 12),
                        child: Row(
                          children: [
                            Icon(
                              Icons.room_rounded,
                              size: 14,
                              color: isDark ? Colors.grey.shade400 : Colors.grey[500],
                            ),
                            const SizedBox(width: 4),
                            Text(
                              signalement.numeroChambre!,
                              style: TextStyle(
                                fontSize: 12,
                                color: isDark ? Colors.grey.shade400 : Colors.grey[600],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Affiche un message lorsque la liste est vide.
  Widget _buildEmptyState(bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 60),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.report_problem_outlined,
            size: 80,
            color: isDark ? Colors.grey.shade700 : Colors.grey[300],
          ),
          const SizedBox(height: 24),
          Text(
            'Aucun signalement',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: isDark ? Colors.grey.shade300 : Colors.grey[600],
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Vous n\'avez effectué aucun signalement pour le moment',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 15,
              color: isDark ? Colors.grey.shade400 : Colors.grey[500],
              height: 1.5,
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  /// Affiche un message d'erreur en cas de problème de chargement.
  Widget _buildErrorState(SignalementProvider provider, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline_rounded,
            size: 72,
            color: isDark ? Colors.grey.shade600 : Colors.grey[400],
          ),
          const SizedBox(height: 24),
          Text(
            'Erreur de chargement',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.grey.shade300 : Colors.grey[600],
            ),
          ),
          const SizedBox(height: 12),
          Text(
            provider.error!,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 15,
              color: isDark ? Colors.grey.shade400 : Colors.grey[500],
              height: 1.5,
            ),
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: () => provider.refresh(),
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Réessayer'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Affiche une boîte de dialogue listant les types de problèmes.
  void _showInfoDialog() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.info_rounded,
                    color: Theme.of(context).colorScheme.primary,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Types de problèmes',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Text(
                'Catégories de signalements disponibles :',
                style: TextStyle(
                  fontSize: 14,
                  color: isDark ? Colors.grey.shade400 : Colors.grey,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 16),
              ..._buildProblemTypesList(isDark),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('Compris'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Construit la liste des types de problèmes pour la boîte de dialogue.
  List<Widget> _buildProblemTypesList(bool isDark) {
    final problems = [
      {'type': 'PLOMBERIE', 'desc': 'Fuite d\'eau, robinets, sanitaires'},
      {'type': 'ÉLECTRICITÉ', 'desc': 'Pannes, prises, interrupteurs'},
      {'type': 'TOITURE', 'desc': 'Infiltrations, tuiles, gouttières'},
      {'type': 'SERRURE', 'desc': 'Portes, fenêtres, fermetures'},
      {'type': 'MOBILIER', 'desc': 'Lits, tables, chaises, armoires'},
      {'type': 'AUTRE', 'desc': 'Autres problèmes non listés'},
    ];

    return problems.map((problem) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              margin: const EdgeInsets.only(top: 4),
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    problem['type']!,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    problem['desc']!,
                    style: TextStyle(
                      fontSize: 13,
                      color: isDark ? Colors.grey.shade400 : Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }).toList();
  }

  // Méthodes utilitaires

  _StatusInfo _getStatusInfo(Signalement signalement) {
    if (signalement.isResolu) {
      return _StatusInfo(AppTheme.successColor, Icons.check_circle_rounded);
    } else if (signalement.isEnCours) {
      return _StatusInfo(AppTheme.infoColor, Icons.build_rounded);
    } else if (signalement.isAnnule) {
      return _StatusInfo(Colors.grey, Icons.cancel_rounded);
    } else {
      return _StatusInfo(AppTheme.warningColor, Icons.pending_actions_rounded);
    }
  }

  /// Retourne l'icône associée à un type de problème.
  IconData _getProblemTypeIcon(String type) {
    switch (type.toUpperCase()) {
      case 'PLOMBERIE':
        return Icons.plumbing_rounded;
      case 'ELECTRICITE':
        return Icons.electrical_services_rounded;
      case 'TOITURE':
        return Icons.roofing_rounded;
      case 'SERRURE':
        return Icons.lock_rounded;
      case 'MOBILIER':
        return Icons.chair_rounded;
      default:
        return Icons.more_horiz_rounded;
    }
  }
}

/// Structure interne pour stocker les informations de statut (couleur et icône).
class _StatusInfo {
  final Color color;
  final IconData icon;

  _StatusInfo(this.color, this.icon);
}

/// État de chargement temporaire.
class _LoadingState extends StatelessWidget {
  const _LoadingState({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            strokeWidth: 2,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(height: 20),
          Text(
            'Chargement des signalements...',
            style: TextStyle(
              fontSize: 16,
              color: isDark ? Colors.grey.shade300 : Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }
}