import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:badges/badges.dart' as badges;
import '../../config/theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/notification_provider.dart';
import '../../providers/paiement_provider.dart';
import '../../providers/signalement_provider.dart';
import '../../models/user.dart';
import '../../services/notification_api_service.dart';
import '../../services/connectivity_service.dart';
import '../profile/profile_screen.dart';
import '../paiements/paiements_list_screen.dart';
import '../signalements/signalements_list_screen.dart';
import '../notifications/notifications_screen.dart';
import 'dart:async';

/// Écran principal de l'application avec navigation par onglets.
class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  int _currentIndex = 0;
  int _unreadCount = 0;
  Timer? _timer;
  StreamSubscription<RemoteMessage>? _foregroundSubscription;
  final NotificationApiService _notificationApiService = NotificationApiService();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    // Toutes les initialisations asynchrones sont effectuées après le premier build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final connectivityService = Provider.of<ConnectivityService>(context, listen: false);
      connectivityService.addListener(_onConnectivityChanged);

      final notificationProvider = Provider.of<NotificationProvider>(context, listen: false);
      notificationProvider.loadNotifications();
    });

    _loadUnreadCount();
    _startPeriodicRefresh();
    _listenToForegroundNotifications();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);

    try {
      final connectivityService = Provider.of<ConnectivityService>(context, listen: false);
      connectivityService.removeListener(_onConnectivityChanged);
    } catch (e) {
      print('Erreur lors de la suppression de l\'écouteur de connectivite: $e');
    }

    _timer?.cancel();
    _foregroundSubscription?.cancel();
    super.dispose();
  }

  /// Réagit aux changements d'état de la connectivité réseau.
  void _onConnectivityChanged() {
    final connectivityService = Provider.of<ConnectivityService>(context, listen: false);

    if (connectivityService.isOnline) {
      print('Connexion retablie - Rechargement des notifications');

      final notificationProvider = Provider.of<NotificationProvider>(context, listen: false);
      notificationProvider.loadNotifications();

      _loadUnreadCount();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _loadUnreadCount();
    }
  }

  /// Démarre un rafraîchissement périodique du compteur de notifications.
  void _startPeriodicRefresh() {
    _timer = Timer.periodic(const Duration(seconds: 30), (_) {
      _loadUnreadCount();
    });
  }

  /// Écoute les notifications reçues au premier plan.
  void _listenToForegroundNotifications() {
    _foregroundSubscription = FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print('Notification recue en temps reel: ${message.notification?.title}');
      _loadUnreadCount();
    });
  }

  /// Charge le nombre de notifications non lues.
  Future<void> _loadUnreadCount() async {
    try {
      final notificationProvider = Provider.of<NotificationProvider>(context, listen: false);
      final count = await notificationProvider.getUnreadCount();

      if (mounted) {
        setState(() {
          _unreadCount = count;
        });
      }
    } catch (e) {
      print('Erreur lors du chargement du badge: $e');
    }
  }

  /// Retourne la liste des écrans associés aux onglets.
  List<Widget> _getScreens() {
    return [
      HomeTab(
        unreadCount: _unreadCount,
        onNotificationTap: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const NotificationsScreen(),
            ),
          );
          _loadUnreadCount();
        },
      ),
      const PaiementsListScreen(),
      const SignalementsListScreen(),
      const ProfileScreen(),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _getScreens(),
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.2 : 0.1),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
          child: Theme(
            data: Theme.of(context).copyWith(
              platform: TargetPlatform.android,
            ),
            child: BottomNavigationBar(
              currentIndex: _currentIndex,
              onTap: (index) {
                setState(() {
                  _currentIndex = index;
                });
              },
              type: BottomNavigationBarType.fixed,
              selectedItemColor: Theme.of(context).colorScheme.primary,
              unselectedItemColor: isDark ? Colors.grey.shade400 : Colors.grey[600],
              backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
              selectedLabelStyle: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 11,
              ),
              unselectedLabelStyle: const TextStyle(
                fontSize: 11,
              ),
              items: [
                _buildBottomNavItem(
                  icon: Icons.home_outlined,
                  activeIcon: Icons.home_rounded,
                  label: 'Accueil',
                ),
                _buildBottomNavItem(
                  icon: Icons.payment_outlined,
                  activeIcon: Icons.payment_rounded,
                  label: 'Paiements',
                ),
                _buildBottomNavItem(
                  icon: Icons.report_problem_outlined,
                  activeIcon: Icons.report_problem_rounded,
                  label: 'Signalements',
                ),
                _buildBottomNavItem(
                  icon: Icons.person_outline_rounded,
                  activeIcon: Icons.person_rounded,
                  label: 'Profil',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Construit un élément de la barre de navigation.
  BottomNavigationBarItem _buildBottomNavItem({
    required IconData icon,
    required IconData activeIcon,
    required String label,
  }) {
    return BottomNavigationBarItem(
      icon: Icon(icon, size: 24),
      activeIcon: Icon(activeIcon, size: 26),
      label: label,
      tooltip: label,
    );
  }
}

/// Onglet d'accueil affichant les informations de l'utilisateur et un aperçu.
class HomeTab extends StatelessWidget {
  final int unreadCount;
  final VoidCallback onNotificationTap;

  const HomeTab({
    Key? key,
    this.unreadCount = 0,
    required this.onNotificationTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final paiementProvider = Provider.of<PaiementProvider>(context);
    final signalementProvider = Provider.of<SignalementProvider>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final User? user = authProvider.user;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121212) : AppTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.primary,
        elevation: 0,
        centerTitle: true,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Bonjour,',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.normal,
                color: Colors.white,
              ),
            ),
            Text(
              user?.prenom ?? 'Utilisateur',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ],
        ),
        actions: [
          // Indicateur de hors ligne
          Consumer<ConnectivityService>(
            builder: (context, connectivity, _) {
              if (connectivity.isOffline) {
                return Container(
                  margin: const EdgeInsets.only(right: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.orange,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Icon(Icons.cloud_off, size: 14, color: Colors.white),
                      SizedBox(width: 4),
                      Text(
                        'Hors ligne',
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

          // Badge de notifications
          Stack(
            clipBehavior: Clip.none,
            children: [
              IconButton(
                icon: const Icon(Icons.notifications_outlined, color: Colors.white),
                onPressed: onNotificationTap,
                tooltip: 'Notifications',
                padding: const EdgeInsets.all(8),
              ),
              if (unreadCount > 0)
                Positioned(
                  right: 6,
                  top: 6,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Theme.of(context).colorScheme.primary,
                        width: 2,
                      ),
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 18,
                      minHeight: 18,
                    ),
                    child: Center(
                      child: Text(
                        unreadCount > 99 ? '99+' : '$unreadCount',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          height: 1,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await Future.wait([
            authProvider.refreshUser(),
            paiementProvider.refresh(),
            signalementProvider.refresh(),
          ]);
        },
        color: Theme.of(context).colorScheme.primary,
        backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Carte des informations de logement
              _buildLogementCard(user, isDark),
              const SizedBox(height: 16),

              // Section Aperçu rapide
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Text(
                  'Aperçu rapide',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : Colors.grey[800],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              _buildStatsGrid(paiementProvider, signalementProvider, isDark),
              const SizedBox(height: 24),

              // Section Actions rapides
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Text(
                  'Actions rapides',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : Colors.grey[800],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              _buildQuickActions(context, isDark),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  /// Construit la carte d'information du logement.
  Widget _buildLogementCard(User? user, bool isDark) {
    return Card(
      elevation: isDark ? 4 : 3,
      color: isDark ? const Color(0xFF1E1E1E) : null,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            colors: isDark
                ? [
              const Color(0xFF1565C0),
              const Color(0xFF0D47A1),
            ]
                : [
              AppTheme.primaryColor,
              const Color(0xFF1565C0),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Icon(
                  Icons.home_rounded,
                  color: Colors.white.withOpacity(0.9),
                  size: 30,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SizedBox(height: 4),
                      Text(
                        user?.nomCentre ?? 'Mon Logement',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Container(
              height: 1,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.transparent,
                    Colors.white.withOpacity(0.3),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildInfoItem(
                  Icons.badge_rounded,
                  'Matricule',
                  user?.matricule ?? '--',
                ),
                _buildInfoItem(
                  Icons.meeting_room_rounded,
                  'Chambre',
                  user?.numeroChambre ?? 'Non attribué',
                ),
                _buildInfoItem(
                  Icons.verified_user_rounded,
                  'Statut',
                  user?.statut == 'ACTIF' ? 'Actif' : 'Inactif',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Construit un élément d'information dans la carte logement.
  Widget _buildInfoItem(IconData icon, String label, String value) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.15),
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            color: Colors.white.withOpacity(0.9),
            size: 18,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withOpacity(0.7),
            fontSize: 11,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  /// Construit la grille des statistiques.
  Widget _buildStatsGrid(PaiementProvider paiementProvider, SignalementProvider signalementProvider, bool isDark) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.2,
      children: [
        _buildStatCard(
          title: 'Paiements',
          value: paiementProvider.paiementsConfirmes.toString(),
          icon: Icons.payment_rounded,
          color: AppTheme.successColor,
          subtitle: 'Confirmés',
          isDark: isDark,
        ),
        _buildStatCard(
          title: 'En attente',
          value: paiementProvider.pendingPaiementsCount.toString(),
          icon: Icons.pending_actions_rounded,
          color: AppTheme.warningColor,
          subtitle: 'Paiements',
          isDark: isDark,
        ),
        _buildStatCard(
          title: 'Signalements',
          value: signalementProvider.totalSignalements.toString(),
          icon: Icons.report_problem_rounded,
          color: AppTheme.errorColor,
          subtitle: 'Total',
          isDark: isDark,
        ),
        _buildStatCard(
          title: 'Signalements',
          value: signalementProvider.signalementsEnAttente.toString(),
          icon: Icons.pending_rounded,
          color: AppTheme.infoColor,
          subtitle: 'En attente',
          isDark: isDark,
        ),
      ],
    );
  }

  /// Construit une carte de statistique individuelle.
  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    required String subtitle,
    required bool isDark,
  }) {
    return Card(
      elevation: isDark ? 4 : 2,
      color: isDark ? const Color(0xFF1E1E1E) : null,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: FittedBox(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withOpacity(isDark ? 0.2 : 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 26,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                value,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : Colors.grey[800],
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 11,
                  color: isDark ? Colors.grey.shade400 : Colors.grey[600],
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Construit les boutons d'actions rapides.
  Widget _buildQuickActions(BuildContext context, bool isDark) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildActionButton(
          context,
          title: 'Effectuer un paiement',
          icon: Icons.payment_rounded,
          color: Theme.of(context).colorScheme.primary,
          description: 'Régler votre loyer ou autres frais',
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const PaiementsListScreen(),
              ),
            );
          },
          isDark: isDark,
        ),
        const SizedBox(height: 12),
        _buildActionButton(
          context,
          title: 'Signaler un problème',
          icon: Icons.report_problem_rounded,
          color: AppTheme.errorColor,
          description: 'Signaler une panne ou un dysfonctionnement',
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const SignalementsListScreen(),
              ),
            );
          },
          isDark: isDark,
        ),
      ],
    );
  }

  /// Construit un bouton d'action.
  Widget _buildActionButton(
      BuildContext context, {
        required String title,
        required IconData icon,
        required Color color,
        required String description,
        required VoidCallback onTap,
        required bool isDark,
      }) {
    return Card(
      elevation: isDark ? 4 : 2,
      color: isDark ? const Color(0xFF1E1E1E) : null,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: color.withOpacity(isDark ? 0.2 : 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 26,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: TextStyle(
                        fontSize: 13,
                        color: isDark ? Colors.grey.shade400 : Colors.grey[600],
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios_rounded,
                size: 16,
                color: isDark ? Colors.grey.shade600 : Colors.grey[400],
              ),
            ],
          ),
        ),
      ),
    );
  }
}