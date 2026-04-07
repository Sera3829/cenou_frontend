import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/notification_provider.dart';
import '../../providers/paiement_provider.dart';
import '../../providers/signalement_provider.dart';
import '../../models/user.dart';
import '../../services/connectivity_service.dart';
import '../../utils/mobile_responsive.dart';
import '../paiements/paiements_list_screen.dart';
import '../signalements/signalements_list_screen.dart';
import '../notifications/notifications_screen.dart';
import 'dart:async';

/// Écran principal avec navigation par onglets — responsive mobile/tablette.
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

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final conn = Provider.of<ConnectivityService>(context, listen: false);
      conn.addListener(_onConnectivityChanged);
      Provider.of<NotificationProvider>(context, listen: false).loadNotifications();
    });
    _loadUnreadCount();
    _startPeriodicRefresh();
    _listenToForegroundNotifications();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    try {
      final conn = Provider.of<ConnectivityService>(context, listen: false);
      conn.removeListener(_onConnectivityChanged);
    } catch (_) {}
    _timer?.cancel();
    _foregroundSubscription?.cancel();
    super.dispose();
  }

  void _onConnectivityChanged() {
    final conn = Provider.of<ConnectivityService>(context, listen: false);
    if (conn.isOnline) {
      Provider.of<NotificationProvider>(context, listen: false).loadNotifications();
      _loadUnreadCount();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _loadUnreadCount();
  }

  void _startPeriodicRefresh() {
    _timer = Timer.periodic(const Duration(seconds: 30), (_) => _loadUnreadCount());
  }

  void _listenToForegroundNotifications() {
    _foregroundSubscription = FirebaseMessaging.onMessage.listen((_) => _loadUnreadCount());
  }

  Future<void> _loadUnreadCount() async {
    try {
      final count = await Provider.of<NotificationProvider>(context, listen: false)
          .getUnreadCount();
      if (mounted) setState(() => _unreadCount = count);
    } catch (_) {}
  }

  List<Widget> _getScreens() {
    return [
      HomeTab(
        unreadCount: _unreadCount,
        onNotificationTap: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const NotificationsScreen()),
          );
          _loadUnreadCount();
        },
      ),
      const PaiementsListScreen(),
      const SignalementsListScreen(),
      // ProfileScreen — importé selon votre arborescence
      const _PlaceholderScreen(label: 'Profil'),
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
      bottomNavigationBar: _BottomNav(
        currentIndex: _currentIndex,
        unreadCount: _unreadCount,
        isDark: isDark,
        onTap: (i) => setState(() => _currentIndex = i),
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────
// Barre de navigation du bas
// ──────────────────────────────────────────────────────────────

class _BottomNav extends StatelessWidget {
  final int currentIndex;
  final int unreadCount;
  final bool isDark;
  final ValueChanged<int> onTap;

  const _BottomNav({
    required this.currentIndex,
    required this.unreadCount,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
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
        child: BottomNavigationBar(
          currentIndex: currentIndex,
          onTap: onTap,
          type: BottomNavigationBarType.fixed,
          selectedItemColor: Theme.of(context).colorScheme.primary,
          unselectedItemColor:
          isDark ? Colors.grey.shade400 : Colors.grey[600],
          backgroundColor:
          isDark ? const Color(0xFF1E1E1E) : Colors.white,
          selectedLabelStyle: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 11,
          ),
          unselectedLabelStyle: const TextStyle(fontSize: 11),
          items: [
            const BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined, size: 24),
              activeIcon: Icon(Icons.home_rounded, size: 26),
              label: 'Accueil',
            ),
            const BottomNavigationBarItem(
              icon: Icon(Icons.payment_outlined, size: 24),
              activeIcon: Icon(Icons.payment_rounded, size: 26),
              label: 'Paiements',
            ),
            const BottomNavigationBarItem(
              icon: Icon(Icons.report_problem_outlined, size: 24),
              activeIcon: Icon(Icons.report_problem_rounded, size: 26),
              label: 'Signalements',
            ),
            const BottomNavigationBarItem(
              icon: Icon(Icons.person_outline_rounded, size: 24),
              activeIcon: Icon(Icons.person_rounded, size: 26),
              label: 'Profil',
            ),
          ],
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────
// Onglet Accueil
// ──────────────────────────────────────────────────────────────

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
    final user = authProvider.user;

    return Scaffold(
      backgroundColor:
      isDark ? const Color(0xFF121212) : AppTheme.backgroundColor,
      appBar: _buildAppBar(context, user, isDark),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final config = ResponsiveConfig.fromConstraints(constraints);
          return RefreshIndicator(
            onRefresh: () async {
              await Future.wait([
                authProvider.refreshUser(),
                paiementProvider.refresh(),
                signalementProvider.refresh(),
              ]);
            },
            color: Theme.of(context).colorScheme.primary,
            backgroundColor:
            isDark ? const Color(0xFF1E1E1E) : Colors.white,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: config.horizontalPadding.copyWith(
                top: config.isShortScreen ? 12 : 16,
                bottom: config.isShortScreen ? 12 : 24,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Carte logement
                  _LogementCard(user: user, isDark: isDark, config: config),
                  SizedBox(height: config.isShortScreen ? 12 : 16),

                  // Titre "Aperçu rapide"
                  _SectionTitle(
                    text: 'Aperçu rapide',
                    isDark: isDark,
                    config: config,
                  ),
                  SizedBox(height: config.isShortScreen ? 8 : 12),

                  // Grille des stats
                  _StatsGrid(
                    paiementProvider: paiementProvider,
                    signalementProvider: signalementProvider,
                    isDark: isDark,
                    config: config,
                  ),
                  SizedBox(height: config.isShortScreen ? 16 : 24),

                  // Titre "Actions rapides"
                  _SectionTitle(
                    text: 'Actions rapides',
                    isDark: isDark,
                    config: config,
                  ),
                  SizedBox(height: config.isShortScreen ? 8 : 12),

                  // Boutons d'action
                  _QuickActions(context: context, isDark: isDark, config: config),
                  SizedBox(height: config.isShortScreen ? 16 : 32),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(
      BuildContext context, User? user, bool isDark) {
    // Prénom tronqué si trop long
    final prenom = user?.prenom ?? 'Utilisateur';
    final displayPrenom =
    prenom.length > 14 ? '${prenom.substring(0, 12)}…' : prenom;

    return AppBar(
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
              fontSize: 13,
              fontWeight: FontWeight.normal,
              color: Colors.white,
            ),
          ),
          Text(
            displayPrenom,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ],
      ),
      actions: [
        // Badge hors ligne
        Consumer<ConnectivityService>(
          builder: (context, conn, _) {
            if (conn.isOffline) {
              return Container(
                margin: const EdgeInsets.only(right: 6),
                padding:
                const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.orange,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.cloud_off, size: 13, color: Colors.white),
                    SizedBox(width: 3),
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
              );
            }
            return const SizedBox.shrink();
          },
        ),

        // Cloche de notifications
        Stack(
          clipBehavior: Clip.none,
          children: [
            IconButton(
              icon: const Icon(Icons.notifications_outlined,
                  color: Colors.white, size: 24),
              onPressed: onNotificationTap,
              tooltip: 'Notifications',
              padding: const EdgeInsets.all(8),
            ),
            if (unreadCount > 0)
              Positioned(
                right: 6,
                top: 6,
                child: Container(
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Theme.of(context).colorScheme.primary,
                      width: 1.5,
                    ),
                  ),
                  constraints: const BoxConstraints(
                    minWidth: 17,
                    minHeight: 17,
                  ),
                  child: Center(
                    child: Text(
                      unreadCount > 99 ? '99+' : '$unreadCount',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 9,
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
        const SizedBox(width: 4),
      ],
    );
  }
}

// ──────────────────────────────────────────────────────────────
// Titre de section
// ──────────────────────────────────────────────────────────────

class _SectionTitle extends StatelessWidget {
  final String text;
  final bool isDark;
  final ResponsiveConfig config;

  const _SectionTitle({
    required this.text,
    required this.isDark,
    required this.config,
  });

  @override
  Widget build(BuildContext context) {
    final fontSize = config.responsive(small: 15, medium: 17, large: 19);
    return Text(
      text,
      style: TextStyle(
        fontSize: fontSize,
        fontWeight: FontWeight.w700,
        color: isDark ? Colors.white : Colors.grey[800],
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────
// Carte logement
// ──────────────────────────────────────────────────────────────

class _LogementCard extends StatelessWidget {
  final User? user;
  final bool isDark;
  final ResponsiveConfig config;

  const _LogementCard({
    required this.user,
    required this.isDark,
    required this.config,
  });

  @override
  Widget build(BuildContext context) {
    final padding = config.responsive(small: 14, medium: 18, large: 22);
    final iconSize = config.responsive(small: 22, medium: 26, large: 30);
    final titleSize = config.responsive(small: 15, medium: 18, large: 20);

    // Tronquer le nom du centre si trop long
    final nomCentre = user?.nomCentre ?? 'Mon Logement';
    final displayNom =
    nomCentre.length > 22 ? '${nomCentre.substring(0, 20)}…' : nomCentre;

    return Card(
      elevation: isDark ? 4 : 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.all(padding),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            colors: isDark
                ? [const Color(0xFF1565C0), const Color(0xFF0D47A1)]
                : [AppTheme.primaryColor, const Color(0xFF1565C0)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // En-tête : icône + nom centre
            Row(
              children: [
                Icon(Icons.home_rounded,
                    color: Colors.white.withOpacity(0.9), size: iconSize),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    displayNom,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: titleSize,
                      fontWeight: FontWeight.w700,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),

            SizedBox(height: config.isShortScreen ? 14 : 20),

            // Séparateur
            Container(
              height: 1,
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [
                  Colors.transparent,
                  Colors.white.withOpacity(0.3),
                  Colors.transparent,
                ]),
              ),
            ),

            SizedBox(height: config.isShortScreen ? 12 : 18),

            // 3 infos : Matricule | Chambre | Statut
            // Sur petit écran, espacement réduit + textes plus courts
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _InfoItem(
                  icon: Icons.badge_rounded,
                  label: 'Matricule',
                  value: _truncate(user?.matricule ?? '--', config.isSmall ? 8 : 12),
                  config: config,
                ),
                _InfoItem(
                  icon: Icons.meeting_room_rounded,
                  label: config.isSmall ? 'Ch.' : 'Chambre',
                  value: _truncate(
                      user?.numeroChambre ?? 'N/A', config.isSmall ? 6 : 10),
                  config: config,
                ),
                _InfoItem(
                  icon: Icons.verified_user_rounded,
                  label: 'Statut',
                  value: user?.statut == 'ACTIF' ? 'Actif' : 'Inactif',
                  config: config,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _truncate(String s, int max) =>
      s.length > max ? '${s.substring(0, max - 1)}…' : s;
}

class _InfoItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final ResponsiveConfig config;

  const _InfoItem({
    required this.icon,
    required this.label,
    required this.value,
    required this.config,
  });

  @override
  Widget build(BuildContext context) {
    final iconSize = config.responsive(small: 14, medium: 17, large: 20);
    final iconPad = config.responsive(small: 7, medium: 9, large: 11);
    final labelSize = config.responsive(small: 9, medium: 11, large: 12);
    final valueSize = config.responsive(small: 11, medium: 13, large: 14);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: EdgeInsets.all(iconPad),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.15),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: Colors.white.withOpacity(0.9), size: iconSize),
        ),
        SizedBox(height: config.isSmall ? 5 : 8),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withOpacity(0.7),
            fontSize: labelSize,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          value,
          style: TextStyle(
            color: Colors.white,
            fontSize: valueSize,
            fontWeight: FontWeight.w600,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}

// ──────────────────────────────────────────────────────────────
// Grille des statistiques
// ──────────────────────────────────────────────────────────────

class _StatsGrid extends StatelessWidget {
  final PaiementProvider paiementProvider;
  final SignalementProvider signalementProvider;
  final bool isDark;
  final ResponsiveConfig config;

  const _StatsGrid({
    required this.paiementProvider,
    required this.signalementProvider,
    required this.isDark,
    required this.config,
  });

  @override
  Widget build(BuildContext context) {
    // Tablette → 4 colonnes / mobile → 2 colonnes
    final crossAxis = config.isTablet ? 4 : 2;
    // Ratio : plus haut sur petit écran (icône + texte ont besoin de place)
    final ratio = config.responsive(small: 1.05, medium: 1.2, large: 1.4);

    final items = [
      _StatItem(
        title: 'Paiements',
        value: paiementProvider.paiementsConfirmes.toString(),
        icon: Icons.payment_rounded,
        color: AppTheme.successColor,
        subtitle: 'Confirmés',
      ),
      _StatItem(
        title: 'En attente',
        value: paiementProvider.pendingPaiementsCount.toString(),
        icon: Icons.pending_actions_rounded,
        color: AppTheme.warningColor,
        subtitle: 'Paiements',
      ),
      _StatItem(
        title: 'Signalements',
        value: signalementProvider.totalSignalements.toString(),
        icon: Icons.report_problem_rounded,
        color: AppTheme.errorColor,
        subtitle: 'Total',
      ),
      _StatItem(
        title: config.isSmall ? 'Signalem.' : 'Signalements',
        value: signalementProvider.signalementsEnAttente.toString(),
        icon: Icons.pending_rounded,
        color: AppTheme.infoColor,
        subtitle: 'En attente',
      ),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxis,
        mainAxisSpacing: config.isSmall ? 8 : 12,
        crossAxisSpacing: config.isSmall ? 8 : 12,
        childAspectRatio: ratio,
      ),
      itemCount: items.length,
      itemBuilder: (_, i) => _StatCard(item: items[i], isDark: isDark, config: config),
    );
  }
}

class _StatItem {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final String subtitle;

  const _StatItem({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    required this.subtitle,
  });
}

class _StatCard extends StatelessWidget {
  final _StatItem item;
  final bool isDark;
  final ResponsiveConfig config;

  const _StatCard({
    required this.item,
    required this.isDark,
    required this.config,
  });

  @override
  Widget build(BuildContext context) {
    final iconSize = config.responsive(small: 20, medium: 24, large: 28);
    final iconPad = config.responsive(small: 8, medium: 10, large: 12);
    final valueSize = config.responsive(small: 20, medium: 24, large: 26);
    final titleSize = config.responsive(small: 11, medium: 13, large: 14);
    final subtitleSize = config.responsive(small: 9, medium: 11, large: 12);
    final cardPad = config.responsive(small: 10, medium: 14, large: 16);

    return Card(
      elevation: isDark ? 4 : 2,
      color: isDark ? const Color(0xFF1E1E1E) : null,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: EdgeInsets.all(cardPad),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: EdgeInsets.all(iconPad),
              decoration: BoxDecoration(
                color: item.color.withOpacity(isDark ? 0.2 : 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(item.icon, color: item.color, size: iconSize),
            ),
            SizedBox(height: config.isSmall ? 6 : 10),
            Text(
              item.value,
              style: TextStyle(
                fontSize: valueSize,
                fontWeight: FontWeight.w700,
                color: item.color,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            Text(
              item.title,
              style: TextStyle(
                fontSize: titleSize,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white : Colors.grey[800],
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 2),
            Text(
              item.subtitle,
              style: TextStyle(
                fontSize: subtitleSize,
                color: isDark ? Colors.grey.shade400 : Colors.grey[600],
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

// ──────────────────────────────────────────────────────────────
// Actions rapides
// ──────────────────────────────────────────────────────────────

class _QuickActions extends StatelessWidget {
  final BuildContext context;
  final bool isDark;
  final ResponsiveConfig config;

  const _QuickActions({
    required this.context,
    required this.isDark,
    required this.config,
  });

  @override
  Widget build(BuildContext _) {
    // Sur tablette : 2 boutons côte à côte
    if (config.isTablet) {
      return Row(
        children: [
          Expanded(
            child: _ActionButton(
              title: 'Effectuer un paiement',
              description: 'Régler votre loyer',
              icon: Icons.payment_rounded,
              color: Theme.of(context).colorScheme.primary,
              isDark: isDark,
              config: config,
              onTap: () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const PaiementsListScreen())),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _ActionButton(
              title: 'Signaler un problème',
              description: 'Panne ou dysfonctionnement',
              icon: Icons.report_problem_rounded,
              color: AppTheme.errorColor,
              isDark: isDark,
              config: config,
              onTap: () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const SignalementsListScreen())),
            ),
          ),
        ],
      );
    }

    // Mobile : empilés verticalement
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _ActionButton(
          title: 'Effectuer un paiement',
          description: config.isSmall
              ? 'Régler votre loyer'
              : 'Régler votre loyer ou autres frais',
          icon: Icons.payment_rounded,
          color: Theme.of(context).colorScheme.primary,
          isDark: isDark,
          config: config,
          onTap: () => Navigator.push(context,
              MaterialPageRoute(builder: (_) => const PaiementsListScreen())),
        ),
        SizedBox(height: config.isSmall ? 8 : 12),
        _ActionButton(
          title: 'Signaler un problème',
          description: config.isSmall
              ? 'Panne ou dysfonctionnement'
              : 'Signaler une panne ou un dysfonctionnement',
          icon: Icons.report_problem_rounded,
          color: AppTheme.errorColor,
          isDark: isDark,
          config: config,
          onTap: () => Navigator.push(context,
              MaterialPageRoute(builder: (_) => const SignalementsListScreen())),
        ),
      ],
    );
  }
}

class _ActionButton extends StatelessWidget {
  final String title;
  final String description;
  final IconData icon;
  final Color color;
  final bool isDark;
  final ResponsiveConfig config;
  final VoidCallback onTap;

  const _ActionButton({
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
    required this.isDark,
    required this.config,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final iconSize = config.responsive(small: 22, medium: 25, large: 28);
    final iconPad = config.responsive(small: 10, medium: 12, large: 14);
    final titleSize = config.responsive(small: 13, medium: 15, large: 16);
    final descSize = config.responsive(small: 11, medium: 13, large: 13);
    final cardPad = config.responsive(small: 12, medium: 15, large: 16);

    return Card(
      elevation: isDark ? 4 : 2,
      color: isDark ? const Color(0xFF1E1E1E) : null,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: EdgeInsets.all(cardPad),
          child: Row(
            children: [
              Container(
                padding: EdgeInsets.all(iconPad),
                decoration: BoxDecoration(
                  color: color.withOpacity(isDark ? 0.2 : 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: iconSize),
              ),
              SizedBox(width: config.isSmall ? 10 : 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: titleSize,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 3),
                    Text(
                      description,
                      style: TextStyle(
                        fontSize: descSize,
                        color: isDark
                            ? Colors.grey.shade400
                            : Colors.grey[600],
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios_rounded,
                size: 14,
                color: isDark ? Colors.grey.shade600 : Colors.grey[400],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────
// Placeholder — à remplacer par les vrais écrans
// ──────────────────────────────────────────────────────────────

class _PlaceholderScreen extends StatelessWidget {
  final String label;
  const _PlaceholderScreen({required this.label});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(child: Text(label)),
    );
  }
}