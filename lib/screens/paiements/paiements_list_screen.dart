import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../config/theme.dart';
import '../../providers/paiement_provider.dart';
import '../../services/connectivity_service.dart';
import '../../models/paiement.dart';
import 'paiement_detail_screen.dart';
import 'initier_paiement_screen.dart';

/// Écran affichant la liste des paiements de l'utilisateur.
class PaiementsListScreen extends StatefulWidget {
  const PaiementsListScreen({Key? key}) : super(key: key);

  @override
  State<PaiementsListScreen> createState() => _PaiementsListScreenState();
}

class _PaiementsListScreenState extends State<PaiementsListScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<PaiementProvider>(context, listen: false).refresh();
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121212) : AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text(
          'Mes Paiements',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
        actions: [
          Consumer<PaiementProvider>(
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

          IconButton(
            icon: const Icon(Icons.history_rounded),
            onPressed: () {
              // TODO: Afficher historique complet
            },
            tooltip: 'Historique complet',
          ),
        ],
      ),
      body: Consumer<PaiementProvider>(
        builder: (context, paiementProvider, _) {
          if (paiementProvider.isLoading && paiementProvider.paiements.isEmpty) {
            return const _LoadingState();
          }

          if (paiementProvider.error != null) {
            return _buildErrorState(paiementProvider, isDark);
          }

          return RefreshIndicator(
            onRefresh: () => paiementProvider.refresh(),
            color: Theme.of(context).colorScheme.primary,
            backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                // Carte des statistiques
                SliverToBoxAdapter(
                  child: _buildStatsCard(paiementProvider),
                ),
                // Liste des paiements historiques
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
                  sliver: paiementProvider.paiements.isEmpty
                      ? SliverToBoxAdapter(child: _buildEmptyState(isDark))
                      : SliverList(
                    delegate: SliverChildBuilderDelegate(
                          (context, index) {
                        final paiement = paiementProvider.paiements[index];
                        return _buildPaiementCard(context, paiement, isDark);
                      },
                      childCount: paiementProvider.paiements.length,
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          // Vérifier la connexion avant de permettre un nouveau paiement
          final connectivity = Provider.of<ConnectivityService>(context, listen: false);
          if (connectivity.isOffline) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Connexion internet requise pour effectuer un paiement'),
                backgroundColor: Colors.orange,
              ),
            );
            return;
          }

          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const InitierPaiementScreen(),
            ),
          );
        },
        icon: const Icon(Icons.add_rounded, size: 22),
        label: const Text(
          'Nouveau paiement',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        elevation: 4,
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  /// Construit la carte récapitulative des statistiques financières.
  Widget _buildStatsCard(PaiementProvider provider) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Theme.of(context).colorScheme.primary,
            const Color(0xFF1565C0),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(
                Icons.bar_chart_rounded,
                color: Colors.white.withOpacity(0.9),
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Résumé financier',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.9),
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Grille de statistiques
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 3,
            childAspectRatio: 1.2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 0,
            children: [
              _buildStatItem(
                'Total',
                provider.totalPaiements.toString(),
                Icons.receipt_long_rounded,
                Colors.white.withOpacity(0.9),
              ),
              _buildStatItem(
                'Confirmés',
                provider.paiementsConfirmes.toString(),
                Icons.check_circle_rounded,
                Colors.green[300]!,
              ),
              _buildStatItem(
                'En cours',
                provider.pendingPaiementsCount.toString(),
                Icons.pending_actions_rounded,
                Colors.amber[300]!,
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Montant total payé
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.attach_money_rounded,
                  color: Colors.white.withOpacity(0.9),
                  size: 24,
                ),
                const SizedBox(width: 12),
                Flexible(
                  child: Text(
                    'Total payé: ${NumberFormat('#,###').format(provider.montantTotal)} FCFA',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),

          // Montant attendu (à payer)
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.orange.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.warning_amber_rounded,
                  color: Colors.orange[300],
                  size: 20,
                ),
                const SizedBox(width: 12),
                Flexible(
                  child: Text(
                    'À régler: ${NumberFormat('#,###').format(provider.montantTotalAttendu)} FCFA',
                    style: TextStyle(
                      color: Colors.orange[300],
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Affiche la section des paiements attendus (non encore payés).
  Widget _buildPaiementsAttendusSection(BuildContext context, PaiementProvider provider, bool isDark) {
    final attendus = provider.paiementsAttendus;
    if (attendus.isEmpty) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(
                Icons.warning_amber_rounded,
                color: Colors.red,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Paiements attendus',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : Colors.grey[800],
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${attendus.length}',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Colors.red,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...attendus.map((p) => _buildPaiementAttenduCard(context, p, isDark)).toList(),
        ],
      ),
    );
  }

  /// Carte pour un paiement attendu.
  Widget _buildPaiementAttenduCard(BuildContext context, Paiement paiement, bool isDark) {
    final isEnRetard = paiement.isEnRetard;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      child: Card(
        elevation: isDark ? 4 : 2,
        color: isDark ? const Color(0xFF1E1E1E) : null,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: isEnRetard ? Colors.red : Colors.orange,
            width: 1.5,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: (isEnRetard ? Colors.red : Colors.orange).withOpacity(isDark ? 0.2 : 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isEnRetard ? Icons.error_rounded : Icons.schedule_rounded,
                  color: isEnRetard ? Colors.red : Colors.orange,
                  size: 22,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${NumberFormat('#,###').format(paiement.montant)} FCFA',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      isEnRetard
                          ? 'En retard • Échéance: ${DateFormat('dd/MM/yyyy').format(paiement.dateEcheance as DateTime)}'
                          : 'Échéance: ${DateFormat('dd/MM/yyyy').format(paiement.dateEcheance as DateTime)}',
                      style: TextStyle(
                        fontSize: 13,
                        color: isDark ? Colors.grey.shade400 : Colors.grey[600],
                      ),
                    ),
                    if (paiement.description != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        paiement.description!,
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? Colors.grey.shade500 : Colors.grey[500],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 12),
              ElevatedButton(
                onPressed: () {
                  // Vérifier la connexion avant de lancer le paiement
                  final connectivity = Provider.of<ConnectivityService>(context, listen: false);
                  if (connectivity.isOffline) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Connexion internet requise pour effectuer un paiement'),
                        backgroundColor: Colors.orange,
                      ),
                    );
                    return;
                  }

                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const InitierPaiementScreen(),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Payer',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Affiche la section des paiements en cours (initiés).
  Widget _buildPaiementsEnAttenteSection(BuildContext context, List<Paiement> paiementsEnAttente, bool isDark) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(
                Icons.pending_actions_rounded,
                color: Theme.of(context).colorScheme.primary,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Paiements en cours',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : Colors.grey[800],
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary.withOpacity(isDark ? 0.2 : 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${paiementsEnAttente.length}',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...paiementsEnAttente.map((p) => _buildPendingCard(context, p, isDark)).toList(),
        ],
      ),
    );
  }

  /// Carte pour un paiement en attente (en cours).
  Widget _buildPendingCard(BuildContext context, Paiement paiement, bool isDark) {
    final isEnRetard = paiement.isEnRetard;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      child: Card(
        elevation: isDark ? 4 : 2,
        color: isDark ? const Color(0xFF1E1E1E) : null,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: isEnRetard ? AppTheme.errorColor : AppTheme.warningColor,
            width: 1.5,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: (isEnRetard ? AppTheme.errorColor : AppTheme.warningColor)
                      .withOpacity(isDark ? 0.2 : 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isEnRetard ? Icons.error_rounded : Icons.pending_actions_rounded,
                  color: isEnRetard ? AppTheme.errorColor : AppTheme.warningColor,
                  size: 22,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${NumberFormat('#,###').format(paiement.montant)} FCFA',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      isEnRetard
                          ? 'En retard • Échéance: ${DateFormat('dd/MM/yyyy').format(paiement.dateEcheance as DateTime)}'
                          : 'Échéance: ${DateFormat('dd/MM/yyyy').format(paiement.dateEcheance as DateTime)}',
                      style: TextStyle(
                        fontSize: 13,
                        color: isDark ? Colors.grey.shade400 : Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              ElevatedButton(
                onPressed: () {
                  final connectivity = Provider.of<ConnectivityService>(context, listen: false);
                  if (connectivity.isOffline) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Connexion internet requise pour effectuer un paiement'),
                        backgroundColor: Colors.orange,
                      ),
                    );
                    return;
                  }

                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const InitierPaiementScreen(),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Payer',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Carte pour un paiement historique.
  Widget _buildPaiementCard(BuildContext context, Paiement paiement, bool isDark) {
    final statusInfo = _getStatusInfo(paiement);

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
                builder: (context) => PaiementDetailScreen(paiementId: paiement.id),
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // En-tête avec statut et montant
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
                            paiement.statut,
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
                    // Référence
                    Expanded(
                      child: Text(
                        paiement.referenceTransaction as String,
                        textAlign: TextAlign.right,
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? Colors.grey.shade400 : Colors.grey[500],
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Montant et mode
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary.withOpacity(isDark ? 0.2 : 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        _getPaymentModeIcon(paiement.modePaiement),
                        color: Theme.of(context).colorScheme.primary,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '${NumberFormat('#,###').format(paiement.montant)} FCFA',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: isDark ? Colors.white : Colors.black87,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            paiement.modePaiement.replaceAll('_', ' '),
                            style: TextStyle(
                              fontSize: 14,
                              color: isDark ? Colors.grey.shade400 : Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Informations complémentaires
                Wrap(
                  spacing: 12,
                  runSpacing: 8,
                  children: [
                    // Date de paiement
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.calendar_today_rounded,
                          size: 14,
                          color: isDark ? Colors.grey.shade400 : Colors.grey[500],
                        ),
                        const SizedBox(width: 6),
                        Text(
                          paiement.datePaiement != null
                              ? DateFormat('dd MMM yyyy - HH:mm').format(paiement.datePaiement!)
                              : 'En attente',
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark ? Colors.grey.shade400 : Colors.grey[600],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    // Chambre
                    if (paiement.numeroChambre != null && paiement.numeroChambre!.isNotEmpty)
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.room_rounded,
                            size: 14,
                            color: isDark ? Colors.grey.shade400 : Colors.grey[500],
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Ch. ${paiement.numeroChambre!}',
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark ? Colors.grey.shade400 : Colors.grey[600],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    // Centre
                    if (paiement.nomCentre != null && paiement.nomCentre!.isNotEmpty)
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.business_rounded,
                            size: 14,
                            color: isDark ? Colors.grey.shade400 : Colors.grey[500],
                          ),
                          const SizedBox(width: 4),
                          Text(
                            paiement.nomCentre!,
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark ? Colors.grey.shade400 : Colors.grey[600],
                              fontWeight: FontWeight.w500,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
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

  /// Construit un élément de statistique dans la carte.
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

  /// Affiche l'état vide.
  Widget _buildEmptyState(bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 60),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.receipt_long_outlined,
            size: 80,
            color: isDark ? Colors.grey.shade700 : Colors.grey[300],
          ),
          const SizedBox(height: 24),
          Text(
            'Aucun paiement',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: isDark ? Colors.grey.shade300 : Colors.grey[600],
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Vos paiements effectués apparaîtront ici',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 15,
              color: isDark ? Colors.grey.shade400 : Colors.grey[500],
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  /// Affiche un message d'erreur.
  Widget _buildErrorState(PaiementProvider provider, bool isDark) {
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

  // Méthodes utilitaires

  _StatusInfo _getStatusInfo(Paiement paiement) {
    if (paiement.isConfirme) {
      return _StatusInfo(AppTheme.successColor, Icons.check_circle_rounded);
    } else if (paiement.isEchec) {
      return _StatusInfo(AppTheme.errorColor, Icons.cancel_rounded);
    } else {
      return _StatusInfo(AppTheme.warningColor, Icons.pending_actions_rounded);
    }
  }

  IconData _getPaymentModeIcon(String mode) {
    switch (mode.toUpperCase()) {
      case 'ORANGE_MONEY':
        return Icons.phone_android_rounded;
      case 'MOOV_MONEY':
        return Icons.phone_iphone_rounded;
      case 'WAVE':
        return Icons.account_balance_wallet_rounded;
      case 'ESPECES':
        return Icons.money_rounded;
      case 'VIREMENT':
        return Icons.account_balance_rounded;
      default:
        return Icons.payment_rounded;
    }
  }
}

/// Structure d'information sur le statut d'un paiement (couleur et icône).
class _StatusInfo {
  final Color color;
  final IconData icon;

  _StatusInfo(this.color, this.icon);
}

/// Écran de chargement temporaire.
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
            'Chargement des paiements...',
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