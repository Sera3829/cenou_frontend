import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'package:cenou_mobile/providers/auth_provider.dart';
import 'package:cenou_mobile/services/api_service.dart';
import 'package:intl/intl.dart';
import '../../../models/admin/activity.dart';
import '../../../config/theme.dart';

/// Disposition principale du tableau de bord avec une barre latérale et une barre supérieure.
class DashboardLayout extends StatefulWidget {
  final Widget child;
  final int selectedIndex;

  const DashboardLayout({
    Key? key,
    required this.child,
    required this.selectedIndex,
  }) : super(key: key);

  @override
  State<DashboardLayout> createState() => _DashboardLayoutState();
}

class _DashboardLayoutState extends State<DashboardLayout> {
  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final screenWidth = MediaQuery.of(context).size.width;
    final bool isDesktop = screenWidth > 900; // Seuil augmenté

    return Scaffold(
      backgroundColor: AppTheme.getDashboardBackground(context),
      //  Drawer pour petit écran
      drawer: !isDesktop ? Drawer(
        child: _buildDesktopSidebar(authProvider),
      ) : null,
      body: Row(
        children: [
          if (isDesktop) _buildDesktopSidebar(authProvider),
          Expanded(
            child: Column(
              children: [
                _buildTopBar(isDesktop),
                Expanded(child: widget.child),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Construit la barre latérale pour les écrans de bureau.
  Widget _buildDesktopSidebar(AuthProvider authProvider) {
    final screenWidth = MediaQuery.of(context).size.width;
    final sidebarWidth = screenWidth > 1200 ? 280.0 : 220.0;
    return Container(
      width: sidebarWidth,
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 20,
          ),
        ],
      ),
      child: Column(
        children: [
          // Zone supérieure (couleur claire)
          Expanded(
            child: Container(
              color: AppTheme.getSidebarBackground(context),
              child: Column(
                children: [
                  _buildSidebarHeader(),
                  _buildUserInfo(authProvider),
                  Expanded(
                    child: SingleChildScrollView(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Column(
                          children: [
                            _buildMenuItem(
                              index: 0,
                              icon: Icons.dashboard_rounded,
                              label: 'Tableau de bord',
                              route: '/admin/dashboard',
                            ),
                            _buildMenuItem(
                              index: 1,
                              icon: Icons.payment_rounded,
                              label: 'Paiements',
                              route: '/admin/paiements',
                            ),
                            _buildMenuItem(
                              index: 2,
                              icon: Icons.warning_rounded,
                              label: 'Signalements',
                              route: '/admin/signalements',
                            ),
                            _buildMenuItem(
                              index: 3,
                              icon: Icons.people_rounded,
                              label: 'Utilisateurs',
                              route: '/admin/utilisateurs',
                            ),
                            _buildMenuItem(
                              index: 4,
                              icon: Icons.campaign_rounded,
                              label: 'Annonces',
                              route: '/admin/annonces',
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Zone inférieure (couleur sombre)
          Container(
            color: AppTheme.getSidebarBottomBackground(context),
            child: Column(
              children: [
                _buildMenuItem(
                  index: 5,
                  icon: Icons.bar_chart_rounded,
                  label: 'Rapports',
                  route: '/admin/rapports',
                  isDark: true,
                ),
                _buildMenuItem(
                  index: 6,
                  icon: Icons.settings_rounded,
                  label: 'Paramètres',
                  route: '/admin/settings',
                  isDark: true,
                ),
                _buildLogoutButton(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Construit l'en-tête de la barre latérale.
  Widget _buildSidebarHeader() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: isDark ? Colors.grey.shade800 : const Color(0xFFBFDBFE),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppTheme.getCardBackground(context),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.asset(
                'assets/images/logo_cenou.png',
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) {
                  return Icon(
                    Icons.admin_panel_settings_rounded,
                    color: isDark ? Colors.blue.shade300 : const Color(0xFF1E3A8A),
                    size: 28,
                  );
                },
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'CENOU',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.blue.shade300 : const Color(0xFF1E3A8A),
                  ),
                ),
                Text(
                  'Dashboard Admin',
                  style: TextStyle(
                    fontSize: 11,
                    color: AppTheme.getTextSecondary(context),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Affiche les informations de l'utilisateur connecté.
  Widget _buildUserInfo(AuthProvider authProvider) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(20),
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.getCardBackground(context),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isDark
                    ? [const Color(0xFF1E3A8A), const Color(0xFF3B82F6)]
                    : [const Color(0xFF1E3A8A), const Color(0xFF3B82F6)],
              ),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Icon(
              Icons.person_rounded,
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  authProvider.userFullName,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppTheme.getTextPrimary(context),
                    fontSize: 14,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: isDark
                        ? Colors.blue.shade900.withOpacity(0.3)
                        : const Color(0xFF1E3A8A).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    authProvider.isAdmin ? 'Admin' : 'Gestionnaire',
                    style: TextStyle(
                      fontSize: 10,
                      color: isDark ? Colors.blue.shade300 : const Color(0xFF1E3A8A),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Construit un élément du menu.
  Widget _buildMenuItem({
    required int index,
    required IconData icon,
    required String label,
    required String route,
    bool isDark = false,
  }) {
    final bool isSelected = widget.selectedIndex == index;
    final bool isContextDark = Theme.of(context).brightness == Brightness.dark;

    Color? selectedColor;
    Color? unselectedIconColor;
    Color? unselectedTextColor;

    if (isDark) {
      selectedColor = Colors.white.withOpacity(0.15);
      unselectedIconColor = Colors.white.withOpacity(0.7);
      unselectedTextColor = Colors.white.withOpacity(0.7);
    } else {
      selectedColor = const Color(0xFF1E3A8A);
      unselectedIconColor = isContextDark ? Colors.grey.shade400 : const Color(0xFF64748B);
      unselectedTextColor = isContextDark ? Colors.grey.shade400 : const Color(0xFF64748B);
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
      child: InkWell(
        onTap: () {
          if (!isSelected) {
            Navigator.pushReplacementNamed(context, route);
          }
        },
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? selectedColor : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            children: [
              Icon(
                icon,
                size: 20,
                color: isSelected
                    ? (isDark ? Colors.white : Colors.white)
                    : unselectedIconColor,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                    fontSize: 14,
                    color: isSelected
                        ? (isDark ? Colors.white : Colors.white)
                        : unselectedTextColor,
                  ),
                ),
              ),
              if (isSelected)
                Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white : Colors.white,
                    shape: BoxShape.circle,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  /// Construit le bouton de déconnexion.
  Widget _buildLogoutButton() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: InkWell(
        onTap: () => _showLogoutConfirmation(context),
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: isDark
                ? Colors.red.shade900.withOpacity(0.3)
                : Colors.red.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            children: [
              Icon(
                Icons.logout_rounded,
                color: isDark ? Colors.red.shade300 : Colors.red.shade400,
                size: 20,
              ),
              const SizedBox(width: 12),
              Text(
                'Déconnexion',
                style: TextStyle(
                  color: isDark ? Colors.red.shade300 : Colors.red.shade400,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Affiche une boîte de dialogue de confirmation avant déconnexion.
  void _showLogoutConfirmation(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        backgroundColor: AppTheme.getCardBackground(context),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: 480,
            maxHeight: MediaQuery.of(context).size.height * 0.6,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.grey.shade900.withOpacity(0.5)
                      : const Color(0xFFF8FAFC),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.red.shade400.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        Icons.logout_rounded,
                        color: Colors.red.shade400,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        'Déconnexion',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.getTextPrimary(context),
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(dialogContext),
                      icon: Icon(
                        Icons.close,
                        color: AppTheme.getTextSecondary(context),
                      ),
                      tooltip: 'Fermer',
                    ),
                  ],
                ),
              ),
              Flexible(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Êtes-vous sûr de vouloir vous déconnecter ?',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.getTextPrimary(context),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Vous devrez vous reconnecter pour accéder au dashboard.',
                        style: TextStyle(
                          fontSize: 14,
                          color: AppTheme.getTextSecondary(context),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.grey.shade900.withOpacity(0.5)
                      : const Color(0xFFF8FAFC),
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(16),
                    bottomRight: Radius.circular(16),
                  ),
                  border: Border(
                    top: BorderSide(color: AppTheme.getBorderColor(context)),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(dialogContext),
                      child: Text(
                        'Annuler',
                        style: TextStyle(
                          color: AppTheme.getTextSecondary(context),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton.icon(
                      onPressed: () async {
                        Navigator.pop(dialogContext);
                        final authProvider = Provider.of<AuthProvider>(context, listen: false);
                        await authProvider.logout();
                        if (context.mounted) {
                          Navigator.pushReplacementNamed(context, '/admin/login');
                        }
                      },
                      icon: Icon(Icons.logout_rounded, size: 18, color: Colors.white),
                      label: Text(
                        'Se déconnecter',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red.shade400,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Construit la barre supérieure (top bar).
  Widget _buildTopBar(bool isDesktop) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isDesktop ? 32 : 16,
        vertical: 16,
      ),
      decoration: BoxDecoration(
        color: AppTheme.getTopBarBackground(context),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
          ),
        ],
      ),
      child: Row(
        children: [
          // Bouton hamburger sur petit écran
          if (!isDesktop)
            Builder(
              builder: (context) => IconButton(
                icon: Icon(
                  Icons.menu_rounded,
                  color: AppTheme.getTextPrimary(context),
                ),
                onPressed: () => Scaffold.of(context).openDrawer(),
              ),
            ),
          if (!isDesktop) const SizedBox(width: 8),

          Expanded(
            child: Text(
              _getPageTitle(widget.selectedIndex),
              style: TextStyle(
                fontSize: isDesktop ? 20 : 16, // Taille adaptée
                fontWeight: FontWeight.bold,
                color: AppTheme.getTextPrimary(context),
              ),
            ),
          ),

          // Date cachée sur très petit écran
          if (isDesktop) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppTheme.getBorderColor(context),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                _getFormattedDate(),
                style: TextStyle(
                  fontSize: 13,
                  color: AppTheme.getTextSecondary(context),
                ),
              ),
            ),
            const SizedBox(width: 16),
          ],

          IconButton(
            icon: Badge(
              label: const Text('3'),
              child: Icon(
                Icons.notifications_none_rounded,
                color: AppTheme.getTextSecondary(context),
              ),
            ),
            onPressed: () {},
          ),
        ],
      ),
    );
  }
  /// Retourne le titre de la page en fonction de l'index sélectionné.
  String _getPageTitle(int index) {
    const titles = [
      'Tableau de bord',
      'Gestion des Paiements',
      'Gestion des Signalements',
      'Gestion des Utilisateurs',
      'Gestion des Annonces',
      'Rapports & Statistiques',
      'Paramètres du Système',
    ];
    return titles[index];
  }

  /// Retourne la date actuelle formatée.
  String _getFormattedDate() {
    final now = DateTime.now();
    final days = ['Lun', 'Mar', 'Mer', 'Jeu', 'Ven', 'Sam', 'Dim'];
    final months = [
      'Jan', 'Fév', 'Mar', 'Avr', 'Mai', 'Juin',
      'Juil', 'Août', 'Sep', 'Oct', 'Nov', 'Déc'
    ];
    return '${days[now.weekday - 1]}, ${now.day} ${months[now.month - 1]}';
  }
}

/// Écran du tableau de bord affichant les statistiques et graphiques.
class DashboardScreen extends StatefulWidget {
  const DashboardScreen({Key? key}) : super(key: key);

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final ApiService _apiService = ApiService();
  late Future<Map<String, dynamic>> _dashboardStatsFuture;
  late Future<Map<String, dynamic>> _dashboardChartsFuture;
  late Future<Map<String, dynamic>> _recentActivityFuture;

  List<ChartData> _revenueData = [];
  List<PieData> _signalementTypesData = [];

  // Évite le double chargement
  bool _isFirstLoad = true;

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Recharger sauf lors du premier chargement
    if (!_isFirstLoad) {
      _loadDashboardData();
    } else {
      _isFirstLoad = false;
    }
  }

  /// Charge toutes les données du tableau de bord.
  void _loadDashboardData() {
    setState(() {
      _dashboardStatsFuture = _apiService.getDashboardStats();
      _dashboardChartsFuture = _apiService.getDashboardCharts(period: 'month');
      _recentActivityFuture = _apiService.getRecentActivity();
    });
  }

  /// Formate un montant avec séparateur de milliers.
  String _formatMontant(double montant) {
    final formatter = NumberFormat('#,##0', 'fr_FR');
    return formatter.format(montant);
  }

  /// Formate une période pour l'affichage sur les axes.
  String _formatChartPeriod(String period) {
    try {
      final date = DateTime.parse(period);
      final months = [
        'Jan', 'Fév', 'Mar', 'Avr', 'Mai', 'Juin',
        'Juil', 'Août', 'Sep', 'Oct', 'Nov', 'Déc'
      ];
      return '${months[date.month - 1]}';
    } catch (e) {
      return period;
    }
  }

  /// Traite les données de graphiques brutes.
  void _processChartData(Map<String, dynamic> chartsData) {
    _revenueData = [];
    _signalementTypesData = [];

    final data = chartsData['data'] as Map<String, dynamic>? ?? {};
    final paiementsData = data['paiements'] as List? ?? [];

    if (paiementsData.isNotEmpty) {
      final Map<String, double> revenueByPeriod = {};

      for (var item in paiementsData) {
        final period = item['period']?.toString() ?? '';
        final total = _safeToDouble(item['total']);
        final periodFormatted = _formatChartPeriod(period);
        revenueByPeriod[periodFormatted] = (revenueByPeriod[periodFormatted] ?? 0) + total;
      }

      _revenueData = revenueByPeriod.entries
          .map((entry) => ChartData(period: entry.key, value: entry.value))
          .toList();
      _revenueData.sort((a, b) => a.period.compareTo(b.period));
    }

    final signalementsTypesData = data['signalements_types'] as List? ?? [];
    if (signalementsTypesData.isNotEmpty) {
      _signalementTypesData = signalementsTypesData
          .map((item) => PieData(
        type: item['type_probleme']?.toString() ?? 'Autre',
        value: _safeToDouble(item['count']),
      ))
          .toList();
    }
  }

  /// Convertit une valeur en double de manière sécurisée.
  double _safeToDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) {
      final clean = value.replaceAll(',', '.').replaceAll(' ', '');
      return double.tryParse(clean) ?? 0.0;
    }
    return 0.0;
  }

  @override
  Widget build(BuildContext context) {
    return DashboardLayout(
      selectedIndex: 0,
      child: SingleChildScrollView(
        padding: EdgeInsets.symmetric(
          horizontal: MediaQuery.of(context).size.width > 900 ? 32 : 16,
          vertical: 32,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildWelcomeSection(),
            const SizedBox(height: 32),
            FutureBuilder<Map<String, dynamic>>(
              future: _dashboardStatsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return _buildErrorWidget(snapshot.error.toString());
                }
                final stats = snapshot.data?['data'] ?? {};
                return _buildStatsGrid(stats);
              },
            ),
            const SizedBox(height: 32),
            LayoutBuilder(
              builder: (context, constraints) {
                final width = constraints.maxWidth;

                if (width >= 900) {
                  // Grand écran : côte à côte
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: 2,
                        child: FutureBuilder<Map<String, dynamic>>(
                          future: _dashboardChartsFuture,
                          builder: (context, snapshot) {
                            if (snapshot.connectionState == ConnectionState.waiting) {
                              return const Center(child: CircularProgressIndicator());
                            }
                            if (snapshot.hasData) {
                              _processChartData(snapshot.data!);
                              return _buildRevenueChart();
                            }
                            return Container();
                          },
                        ),
                      ),
                      const SizedBox(width: 24),
                      Expanded(
                        flex: 1,
                        child: _buildSignalementsChart(),
                      ),
                    ],
                  );
                } else {
                  // Petit écran : empilés verticalement
                  return Column(
                    children: [
                      FutureBuilder<Map<String, dynamic>>(
                        future: _dashboardChartsFuture,
                        builder: (context, snapshot) {
                          if (snapshot.connectionState == ConnectionState.waiting) {
                            return const Center(child: CircularProgressIndicator());
                          }
                          if (snapshot.hasData) {
                            _processChartData(snapshot.data!);
                            return _buildRevenueChart();
                          }
                          return Container();
                        },
                      ),
                      const SizedBox(height: 24),
                      _buildSignalementsChart(),
                    ],
                  );
                }
              },
            ),
            const SizedBox(height: 32),
            _buildRecentActivity(),
          ],
        ),
      ),
    );
  }

  /// Section de bienvenue.
  Widget _buildWelcomeSection() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final screenWidth = MediaQuery.of(context).size.width;
    final isWide = screenWidth > 900;

    return Container(
      padding: EdgeInsets.all(isWide ? 28 : 20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [const Color(0xFF0F172A), const Color(0xFF1E40AF)]
              : [const Color(0xFF1E3A8A), const Color(0xFF3B82F6)],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Bienvenue sur le Dashboard',
                  style: TextStyle(
                    fontSize: isWide ? 26 : 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Gérez vos résidences universitaires en temps réel.',
                  style: TextStyle(
                    fontSize: isWide ? 15 : 13,
                    color: Colors.white.withOpacity(0.9),
                  ),
                ),
                const SizedBox(height: 20),
                ElevatedButton.icon(
                  onPressed: _loadDashboardData,
                  icon: Icon(Icons.refresh_rounded, size: 18,
                      color: isDark ? const Color(0xFF1E3A8A) : Colors.white),
                  label: Text('Actualiser',
                      style: TextStyle(
                          color: isDark ? const Color(0xFF1E3A8A) : Colors.white)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isDark ? Colors.white : Colors.white.withOpacity(0.9),
                    foregroundColor: const Color(0xFF1E3A8A),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    elevation: 0,
                  ),
                ),
              ],
            ),
          ),
          // Icône cachée sur petit écran
          if (isWide)
            Icon(Icons.insights_rounded, size: 100,
                color: Colors.white.withOpacity(0.9)),
        ],
      ),
    );
  }

  /// Grille des indicateurs de performance.
  Widget _buildStatsGrid(Map<String, dynamic> stats) {
    final general = stats['general'] as Map<String, dynamic>? ?? {};
    final paiements = stats['paiements'] as Map<String, dynamic>? ?? {};
    final signalements = stats['signalements'] as Map<String, dynamic>? ?? {};

    // Utiliser MediaQuery directement - plus fiable sur Flutter Web
    final screenWidth = MediaQuery.of(context).size.width;
    final sidebarWidth = screenWidth > 900 ? 280.0 : 0.0;
    final contentWidth = screenWidth - sidebarWidth;

    int crossAxisCount;
    double childAspectRatio;

    if (contentWidth >= 1000) {
      crossAxisCount = 4;
      childAspectRatio = 1.6;
    } else if (contentWidth >= 700) {
      crossAxisCount = 2;
      childAspectRatio = 1.8;
    } else if (contentWidth >= 400) {
      crossAxisCount = 2;
      childAspectRatio = 1.5;
    } else {
      crossAxisCount = 1;
      childAspectRatio = 2.5;
    }

    final cards = [
      _buildStatCard(
        title: 'Total Étudiants',
        value: '${general['total_etudiants'] ?? '0'}',
        icon: Icons.people_rounded,
        color: const Color(0xFF3B82F6),
        change: '${((int.tryParse(general['logements_occupes'] ?? '0') ?? 0) / (int.tryParse(general['total_logements'] ?? '1') ?? 1) * 100).toStringAsFixed(1)}% occ.',
      ),
      _buildStatCard(
        title: 'Paiements Confirmés',
        value: '${paiements['paiements_confirme'] ?? '0'}',
        icon: Icons.payment_rounded,
        color: const Color(0xFF10B981),
        change: '${((int.tryParse(paiements['paiements_confirme'] ?? '0') ?? 0) * 100 / (int.tryParse(paiements['total_paiements'] ?? '1') ?? 1)).toStringAsFixed(1)}%',
      ),
      _buildStatCard(
        title: 'Signalements Actifs',
        value: '${signalements['signalements_en_attente'] ?? '0'}',
        icon: Icons.warning_rounded,
        color: const Color(0xFFF59E0B),
        change: '${signalements['signalements_resolus'] ?? '0'} résolus',
      ),
      _buildStatCard(
        title: 'Revenus 30j',
        value: '${_formatMontant(double.tryParse(paiements['montant_30jours']?.toString() ?? '0') ?? 0)} F',
        icon: Icons.attach_money_rounded,
        color: const Color(0xFF8B5CF6),
        change: 'Moy: ${_formatMontant(double.tryParse(paiements['montant_moyen']?.toString() ?? '0') ?? 0)}',
      ),
    ];

    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: crossAxisCount,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      childAspectRatio: childAspectRatio,
      children: cards,
    );
  }

  /// Carte d'indicateur unique.
  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    required String change,
  }) {
    final bool isPositive = !change.contains('-') && !change.contains('résolus') && !change.contains('occ.');
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: EdgeInsets.all(MediaQuery.of(context).size.width > 900 ? 20 : 12),
      decoration: BoxDecoration(
        color: AppTheme.getCardBackground(context),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.1 : 0.05),
            blurRadius: 10,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withOpacity(isDark ? 0.2 : 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: isPositive
                      ? const Color(0xFF10B981).withOpacity(isDark ? 0.2 : 0.1)
                      : const Color(0xFFEF4444).withOpacity(isDark ? 0.2 : 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isPositive ? Icons.arrow_upward : Icons.arrow_downward,
                      size: 12,
                      color: isPositive ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      change,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: isPositive ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: AppTheme.getTextPrimary(context),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              color: AppTheme.getTextSecondary(context),
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  /// Graphique des revenus mensuels.
  Widget _buildRevenueChart() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.getCardBackground(context),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.1 : 0.05),
            blurRadius: 10,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Revenus Mensuels',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppTheme.getTextPrimary(context),
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 300,
            child: _revenueData.isNotEmpty
                ? SfCartesianChart(
              primaryXAxis: CategoryAxis(
                labelStyle: TextStyle(
                  color: AppTheme.getTextSecondary(context),
                ),
              ),
              primaryYAxis: NumericAxis(
                numberFormat: NumberFormat('#,### F'),
                labelStyle: TextStyle(
                  color: AppTheme.getTextSecondary(context),
                ),
              ),
              plotAreaBorderWidth: 0,
              series: <CartesianSeries>[
                ColumnSeries<ChartData, String>(
                  dataSource: _revenueData,
                  xValueMapper: (ChartData data, _) => data.period,
                  yValueMapper: (ChartData data, _) => data.value,
                  color: isDark ? const Color(0xFF60A5FA) : const Color(0xFF1E3A8A),
                ),
              ],
            )
                : Center(
              child: Text(
                'Aucune donnée',
                style: TextStyle(color: AppTheme.getTextSecondary(context)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Graphique des signalements par type.
  Widget _buildSignalementsChart() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return FutureBuilder<Map<String, dynamic>>(
      future: _dashboardChartsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppTheme.getCardBackground(context),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(isDark ? 0.1 : 0.05),
                  blurRadius: 10,
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Signalements par Type',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.getTextPrimary(context),
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  height: 300,
                  child: Center(
                    child: CircularProgressIndicator(
                      color: AppTheme.primaryColor,
                    ),
                  ),
                ),
              ],
            ),
          );
        }

        if (snapshot.hasError) {
          return Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppTheme.getCardBackground(context),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(isDark ? 0.1 : 0.05),
                  blurRadius: 10,
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Signalements par Type',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.getTextPrimary(context),
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  height: 300,
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.error_outline, size: 50, color: Colors.red),
                        const SizedBox(height: 12),
                        Text(
                          'Erreur de chargement',
                          style: TextStyle(color: Colors.red),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        }

        if (snapshot.hasData) {
          _processChartData(snapshot.data!);
        }

        return Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: AppTheme.getCardBackground(context),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(isDark ? 0.1 : 0.05),
                blurRadius: 10,
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Signalements par Type',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.getTextPrimary(context),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Distribution des problèmes signalés',
                style: TextStyle(
                  color: AppTheme.getTextSecondary(context),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                height: 300,
                child: _signalementTypesData.isNotEmpty
                    ? SfCircularChart(
                  tooltipBehavior: TooltipBehavior(
                    enable: true,
                    format: 'point.x : point.y signalements',
                    canShowMarker: false,
                  ),
                  series: <CircularSeries>[
                    PieSeries<PieData, String>(
                      dataSource: _signalementTypesData,
                      xValueMapper: (PieData data, _) => data.type,
                      yValueMapper: (PieData data, _) => data.value,
                      dataLabelSettings: DataLabelSettings(
                        isVisible: true,
                        labelPosition: ChartDataLabelPosition.outside,
                        textStyle: TextStyle(
                          fontSize: 12,
                          color: AppTheme.getTextPrimary(context),
                        ),
                      ),
                      explode: true,
                      explodeIndex: 0,
                      enableTooltip: true,
                    ),
                  ],
                )
                    : Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.pie_chart,
                        size: 50,
                        color: AppTheme.getTextTertiary(context),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Aucune donnée disponible',
                        style: TextStyle(color: AppTheme.getTextSecondary(context)),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  /// Section des activités récentes.
  Widget _buildRecentActivity() {
    return FutureBuilder<Map<String, dynamic>>(
      future: _recentActivityFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildRecentActivitySkeleton();
        }

        if (snapshot.hasError) {
          return _buildRecentActivityError(snapshot.error.toString());
        }

        final data = snapshot.data?['data'] as Map<String, dynamic>? ?? {};
        final activitiesData = data['activities'] as List? ?? [];

        if (activitiesData.isEmpty) {
          return _buildNoRecentActivity();
        }

        final activities = activitiesData
            .map((json) => Activity.fromJson(json))
            .toList();

        return Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: AppTheme.getCardBackground(context),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(Theme.of(context).brightness == Brightness.dark ? 0.1 : 0.05),
                blurRadius: 10,
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Activité Récente',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.getTextPrimary(context),
                    ),
                  ),
                  TextButton(
                    onPressed: _loadDashboardData,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.refresh,
                          size: 16,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Actualiser',
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              ...activities.take(5).map((activity) => _buildActivityItem(activity)),
              if (activities.length > 5) ...[
                const SizedBox(height: 12),
                Center(
                  child: TextButton(
                    onPressed: () {},
                    child: Text(
                      'Voir toutes les activités',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  /// Squelette d'affichage pendant le chargement des activités.
  Widget _buildRecentActivitySkeleton() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.getCardBackground(context),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.1 : 0.05),
            blurRadius: 10,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 150,
            height: 24,
            decoration: BoxDecoration(
              color: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(height: 16),
          ...List.generate(3, (index) => _buildActivitySkeletonItem()),
        ],
      ),
    );
  }

  /// Élément squelette pour une activité.
  Widget _buildActivitySkeletonItem() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 120,
                  height: 16,
                  decoration: BoxDecoration(
                    color: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  margin: const EdgeInsets.only(bottom: 8),
                ),
                Container(
                  width: double.infinity,
                  height: 14,
                  decoration: BoxDecoration(
                    color: isDark ? Colors.grey.shade700 : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  margin: const EdgeInsets.only(bottom: 4),
                ),
                Container(
                  width: 180,
                  height: 14,
                  decoration: BoxDecoration(
                    color: isDark ? Colors.grey.shade700 : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: 60,
            height: 14,
            decoration: BoxDecoration(
              color: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        ],
      ),
    );
  }

  /// Affiche une erreur pour les activités récentes.
  Widget _buildRecentActivityError(String error) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? Colors.red.shade900.withOpacity(0.1) : const Color(0xFFFEF2F2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? Colors.red.shade800 : const Color(0xFFFECACA),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Activité Récente',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppTheme.getTextPrimary(context),
            ),
          ),
          const SizedBox(height: 16),
          Center(
            child: Column(
              children: [
                Icon(
                  Icons.error_outline,
                  size: 48,
                  color: Colors.red.shade400,
                ),
                const SizedBox(height: 12),
                Text(
                  'Erreur de chargement',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Colors.red.shade400,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  error.length > 100 ? '${error.substring(0, 100)}...' : error,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: isDark ? Colors.red.shade300 : const Color(0xFF991B1B),
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _loadDashboardData,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red.shade400,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Réessayer'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Affichage lorsqu'aucune activité récente n'est disponible.
  Widget _buildNoRecentActivity() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.getCardBackground(context),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(Theme.of(context).brightness == Brightness.dark ? 0.1 : 0.05),
            blurRadius: 10,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Activité Récente',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppTheme.getTextPrimary(context),
            ),
          ),
          const SizedBox(height: 20),
          Center(
            child: Column(
              children: [
                Icon(
                  Icons.notifications_none,
                  size: 50,
                  color: AppTheme.getTextTertiary(context),
                ),
                const SizedBox(height: 16),
                Text(
                  'Aucune activité récente',
                  style: TextStyle(
                    color: AppTheme.getTextSecondary(context),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Les nouvelles activités apparaîtront ici',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppTheme.getTextTertiary(context),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Construit un élément individuel d'activité.
  Widget _buildActivityItem(Activity activity) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.getBorderColor(context)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: activity.color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(activity.icon, color: activity.color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  activity.title,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: AppTheme.getTextPrimary(context),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  activity.formattedDescription,
                  style: TextStyle(
                    color: AppTheme.getTextSecondary(context),
                    fontSize: 13,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                if (activity.metadata['type_probleme'] != null) ...[
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: activity.color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      activity.metadata['type_probleme'].toString(),
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                        color: activity.color,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                activity.timeAgo,
                style: TextStyle(
                  color: AppTheme.getTextTertiary(context),
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                DateFormat('HH:mm').format(activity.timestamp),
                style: TextStyle(
                  color: AppTheme.getTextTertiary(context).withOpacity(0.7),
                  fontSize: 10,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Affiche un widget d'erreur général.
  Widget _buildErrorWidget(String error) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? Colors.red.shade900.withOpacity(0.1) : Colors.red.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(Icons.error_outline, color: Colors.red.shade400, size: 48),
          const SizedBox(height: 12),
          Text(
            'Erreur: $error',
            style: TextStyle(color: isDark ? Colors.red.shade300 : Colors.red.shade600),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _loadDashboardData,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade400,
              foregroundColor: Colors.white,
            ),
            child: const Text('Réessayer'),
          ),
        ],
      ),
    );
  }
}

/// Données pour un graphique en colonnes.
class ChartData {
  final String period;
  final double value;
  ChartData({required this.period, required this.value});
}

/// Données pour un graphique circulaire.
class PieData {
  final String type;
  final double value;
  PieData({required this.type, required this.value});
}