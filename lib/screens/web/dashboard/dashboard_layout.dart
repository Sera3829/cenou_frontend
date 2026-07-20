import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cenou_mobile/providers/auth_provider.dart';
import 'package:cenou_mobile/providers/web/messagerie_provider.dart';
import 'package:cenou_mobile/utils/session_reset.dart';
import 'package:cenou_mobile/config/theme.dart';
import 'package:cenou_mobile/l10n/app_localizations.dart';
import '../messagerie/messagerie_panel.dart';

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
  void initState() {
    super.initState();
    // Charge le compteur de messages non lus pour la cloche.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<MessagerieProvider>().loadInbox();
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final authProvider = Provider.of<AuthProvider>(context);
    final screenWidth = MediaQuery.of(context).size.width;
    final bool isDesktop = screenWidth > 900; // Seuil augmenté

    return Scaffold(
      backgroundColor: AppTheme.getDashboardBackground(context),
      // Panneau de messagerie interne (ouvert depuis la cloche)
      endDrawer: const MessageriePanel(),
      //  Drawer pour petit écran
      drawer: !isDesktop ? Drawer(
        child: _buildDesktopSidebar(authProvider, l10n),
      ) : null,
      body: Row(
        children: [
          if (isDesktop) _buildDesktopSidebar(authProvider, l10n),
          Expanded(
            child: Column(
              children: [
                _buildTopBar(isDesktop, l10n),
                Expanded(child: widget.child),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Construit la barre latérale pour les écrans de bureau.
  Widget _buildDesktopSidebar(AuthProvider authProvider, AppLocalizations l10n) {
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
                  _buildSidebarHeader(l10n),
                  _buildUserInfo(authProvider, l10n),
                  Expanded(
                    child: SingleChildScrollView(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Column(
                          children: [
                            _buildMenuItem(
                              index: 0,
                              icon: Icons.dashboard_rounded,
                              label: l10n.dashboard,
                              route: '/admin/dashboard',
                              l10n: l10n,
                            ),
                            _buildMenuItem(
                              index: 1,
                              icon: Icons.payment_rounded,
                              label: l10n.payments,
                              route: '/admin/paiements',
                              l10n: l10n,
                            ),
                            _buildMenuItem(
                              index: 2,
                              icon: Icons.warning_rounded,
                              label: l10n.reports,
                              route: '/admin/signalements',
                              l10n: l10n,
                            ),
                            _buildMenuItem(
                              index: 3,
                              icon: Icons.people_rounded,
                              label: l10n.users,
                              route: '/admin/utilisateurs',
                              l10n: l10n,
                            ),
                            // « Centres » : gestion réservée aux administrateurs
                            if (authProvider.isAdmin)
                              _buildMenuItem(
                                index: 7,
                                icon: Icons.apartment_rounded,
                                label: l10n.centres,
                                route: '/admin/centres',
                                l10n: l10n,
                              ),
                            _buildMenuItem(
                              index: 4,
                              icon: Icons.campaign_rounded,
                              label: l10n.announcements,
                              route: '/admin/annonces',
                              l10n: l10n,
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
                  label: l10n.reportsStats,
                  route: '/admin/rapports',
                  isDark: true,
                  l10n: l10n,
                ),
                _buildMenuItem(
                  index: 6,
                  icon: Icons.settings_rounded,
                  label: l10n.settings,
                  route: '/admin/settings',
                  isDark: true,
                  l10n: l10n,
                ),
                _buildLogoutButton(l10n),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Construit l'en-tête de la barre latérale.
  Widget _buildSidebarHeader(AppLocalizations l10n) {
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
                  l10n.adminDashboard,
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
  Widget _buildUserInfo(AuthProvider authProvider, AppLocalizations l10n) {
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
                    authProvider.isAdmin ? l10n.admin : l10n.manager,
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
    required AppLocalizations l10n,
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
  Widget _buildLogoutButton(AppLocalizations l10n) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: InkWell(
        onTap: () => _showLogoutConfirmation(context, l10n),
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
                l10n.logout,
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
  void _showLogoutConfirmation(BuildContext context, AppLocalizations l10n) {
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
                        l10n.logout,
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
                      tooltip: l10n.close,
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
                        l10n.logoutConfirm,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.getTextPrimary(context),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        l10n.mustReconnect,
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
                        l10n.cancel,
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
                        // Garde-fou anti-fuite entre sessions.
                        resetUserSession(context);
                        await authProvider.logout();
                        if (context.mounted) {
                          Navigator.pushReplacementNamed(context, '/admin/login');
                        }
                      },
                      icon: Icon(Icons.logout_rounded, size: 18, color: Colors.white),
                      label: Text(
                        l10n.logoutButton,
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
  Widget _buildTopBar(bool isDesktop, AppLocalizations l10n) {
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
              _getPageTitle(widget.selectedIndex, l10n),
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
                _getFormattedDate(l10n),
                style: TextStyle(
                  fontSize: 13,
                  color: AppTheme.getTextSecondary(context),
                ),
              ),
            ),
            const SizedBox(width: 16),
          ],

          Builder(
            builder: (context) => Consumer<MessagerieProvider>(
              builder: (context, msg, _) {
                final n = msg.unreadCount;
                final bell = Icon(
                  Icons.notifications_none_rounded,
                  color: AppTheme.getTextSecondary(context),
                );
                return IconButton(
                  tooltip: l10n.messagerie,
                  icon: n > 0
                      ? Badge(
                          label: Text(n > 99 ? '99+' : '$n'),
                          backgroundColor: AppTheme.errorColor,
                          child: bell,
                        )
                      : bell,
                  onPressed: () => Scaffold.of(context).openEndDrawer(),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  /// Retourne le titre de la page en fonction de l'index sélectionné.
  String _getPageTitle(int index, AppLocalizations l10n) {
    final titles = [
      l10n.dashboard,
      l10n.paymentManagement,
      l10n.reportManagement,
      l10n.userManagement,
      l10n.announcementManagement,
      l10n.reportsStatistics,
      l10n.systemSettings,
    ];
    return titles[index];
  }

  /// Retourne la date actuelle formatée.
  String _getFormattedDate(AppLocalizations l10n) {
    final now = DateTime.now();
    final days = l10n.weekdaysShort.split(',');
    final months = l10n.monthsShort.split(',');
    return '${days[now.weekday - 1]}, ${now.day} ${months[now.month - 1]}';
  }
}

/// Écran du tableau de bord affichant les statistiques et graphiques.
