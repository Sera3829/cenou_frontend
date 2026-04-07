// screens/web/users/user_admin_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../models/admin/centre.dart';
import '../../../providers/web/UserAdminProvider.dart';
import '../../../models/admin/admin_user.dart';
import 'package:cenou_mobile/config/theme.dart';
import 'package:cenou_mobile/services/api_service.dart';
import '../../../config/app_config.dart';
import '../dashboard/dashboard_screen.dart';

/// Écran d'administration des utilisateurs.
class UserAdminScreen extends StatefulWidget {
  const UserAdminScreen({Key? key}) : super(key: key);

  @override
  State<UserAdminScreen> createState() => _UserAdminScreenState();
}

class _UserAdminScreenState extends State<UserAdminScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedRole = 'TOUS';
  String _selectedStatut = 'TOUS';
  bool _showFilters = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadInitialData();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadInitialData() async {
    final provider = Provider.of<UserAdminProvider>(context, listen: false);
    await provider.loadUsers();
  }

  String _formatDate(DateTime date) => DateFormat('dd/MM/yyyy').format(date);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return DashboardLayout(
      selectedIndex: 3,
      child: Column(
        children: [
          _buildFloatingFiltersBar(isDark),
          Expanded(child: _buildMainContent(isDark)),
        ],
      ),
    );
  }

  // ==================== CONTENU PRINCIPAL ====================

  Widget _buildMainContent(bool isDark) {
    return Consumer<UserAdminProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading && provider.users.isEmpty) {
          return Center(
            child: CircularProgressIndicator(
                color: Theme.of(context).colorScheme.primary),
          );
        }

        if (provider.error != null && provider.users.isEmpty) {
          return _buildErrorWidget(provider.error!, isDark);
        }

        if (provider.users.isEmpty) {
          return _buildEmptyState(isDark);
        }

        return SingleChildScrollView(
          child: Column(
            children: [
              _buildQuickStats(provider, isDark),
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                height: _showFilters ? null : 0,
                child: _showFilters
                    ? _buildFiltersCard(isDark)
                    : const SizedBox.shrink(),
              ),
              _buildUsersTable(provider, isDark),
            ],
          ),
        );
      },
    );
  }

  // ==================== BARRE DE FILTRES ====================

  Widget _buildFloatingFiltersBar(bool isDark) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isWide = screenWidth > 1100;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      decoration: BoxDecoration(
        color: AppTheme.getTopBarBackground(context),
        border:
        Border(bottom: BorderSide(color: AppTheme.getBorderColor(context))),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 4,
              offset: const Offset(0, 2))
        ],
      ),
      child: isWide
          ? Row(
        children: [
          Expanded(flex: 3, child: _buildSearchField(isDark)),
          const SizedBox(width: 12),
          SizedBox(width: 160, child: _buildRoleDropdown(isDark)),
          const SizedBox(width: 12),
          SizedBox(width: 160, child: _buildStatutDropdown(isDark)),
          const SizedBox(width: 12),
          _buildActionButtons(isDark),
        ],
      )
          : Column(
        children: [
          _buildSearchField(isDark),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(child: _buildRoleDropdown(isDark)),
              const SizedBox(width: 8),
              Expanded(child: _buildStatutDropdown(isDark)),
              const SizedBox(width: 8),
              _buildActionButtons(isDark),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSearchField(bool isDark) {
    return TextField(
      controller: _searchController,
      decoration: InputDecoration(
        hintText: 'Rechercher nom, matricule, email...',
        hintStyle: TextStyle(color: AppTheme.getTextSecondary(context)),
        prefixIcon: Icon(Icons.search,
            size: 20, color: AppTheme.getTextSecondary(context)),
        suffixIcon: _searchController.text.isNotEmpty
            ? IconButton(
          icon: Icon(Icons.clear,
              size: 20, color: AppTheme.getTextSecondary(context)),
          onPressed: () {
            _searchController.clear();
            _applySearch('');
          },
        )
            : null,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: AppTheme.getBorderColor(context)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: AppTheme.getBorderColor(context)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(
              color: Theme.of(context).colorScheme.primary, width: 2),
        ),
        filled: true,
        fillColor: isDark
            ? Colors.grey.shade900.withOpacity(0.3)
            : Colors.grey.shade50,
        contentPadding:
        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        isDense: true,
      ),
      onSubmitted: _applySearch,
      style: TextStyle(color: AppTheme.getTextPrimary(context)),
    );
  }

  Widget _buildRoleDropdown(bool isDark) {
    return DropdownButtonFormField<String>(
      value: _selectedRole,
      decoration: InputDecoration(
        labelText: 'Rôle',
        labelStyle: TextStyle(color: AppTheme.getTextSecondary(context)),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: AppTheme.getBorderColor(context)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: AppTheme.getBorderColor(context)),
        ),
        filled: true,
        fillColor: isDark
            ? Colors.grey.shade900.withOpacity(0.3)
            : Colors.grey.shade50,
        contentPadding:
        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        isDense: true,
      ),
      dropdownColor: AppTheme.getCardBackground(context),
      items: ['TOUS', 'ETUDIANT', 'GESTIONNAIRE', 'ADMIN'].map((item) {
        return DropdownMenuItem(
          value: item,
          child: Text(
            _getRoleLabel(item),
            style: TextStyle(
                fontSize: 14, color: AppTheme.getTextPrimary(context)),
          ),
        );
      }).toList(),
      onChanged: (value) {
        setState(() => _selectedRole = value!);
        _applyFilter('role', value == 'TOUS' ? null : value);
      },
      style: TextStyle(color: AppTheme.getTextPrimary(context)),
    );
  }

  Widget _buildStatutDropdown(bool isDark) {
    return DropdownButtonFormField<String>(
      value: _selectedStatut,
      decoration: InputDecoration(
        labelText: 'Statut',
        labelStyle: TextStyle(color: AppTheme.getTextSecondary(context)),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: AppTheme.getBorderColor(context)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: AppTheme.getBorderColor(context)),
        ),
        filled: true,
        fillColor: isDark
            ? Colors.grey.shade900.withOpacity(0.3)
            : Colors.grey.shade50,
        contentPadding:
        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        isDense: true,
      ),
      dropdownColor: AppTheme.getCardBackground(context),
      items: ['TOUS', 'ACTIF', 'INACTIF', 'SUSPENDU'].map((item) {
        return DropdownMenuItem(
          value: item,
          child: Text(
            _getStatutLabel(item),
            style: TextStyle(
                fontSize: 14, color: AppTheme.getTextPrimary(context)),
          ),
        );
      }).toList(),
      onChanged: (value) {
        setState(() => _selectedStatut = value!);
        _applyFilter('statut', value == 'TOUS' ? null : value);
      },
      style: TextStyle(color: AppTheme.getTextPrimary(context)),
    );
  }

  Widget _buildActionButtons(bool isDark) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          onPressed: () => setState(() => _showFilters = !_showFilters),
          icon: Icon(
            _showFilters ? Icons.filter_list_off : Icons.filter_list,
            color: Theme.of(context).colorScheme.primary,
          ),
          tooltip: _showFilters ? 'Masquer filtres' : 'Plus de filtres',
        ),
        IconButton(
          onPressed: _resetFilters,
          icon: Icon(Icons.refresh, color: AppTheme.getTextSecondary(context)),
          tooltip: 'Réinitialiser',
        ),
        ElevatedButton.icon(
          onPressed: () => _showCreateUserDialog(),
          icon: const Icon(Icons.add, size: 18, color: Colors.white),
          label: const Text('Nouveau', style: TextStyle(color: Colors.white)),
          style: ElevatedButton.styleFrom(
            backgroundColor: Theme.of(context).colorScheme.primary,
            padding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        ),
        const SizedBox(width: 8),
        ElevatedButton(
          onPressed: _refreshData,
          style: ElevatedButton.styleFrom(
            backgroundColor: Theme.of(context).colorScheme.primary,
            padding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
          child:
          const Text('Actualiser', style: TextStyle(color: Colors.white)),
        ),
      ],
    );
  }

  // ==================== STATISTIQUES ====================

  Widget _buildQuickStats(UserAdminProvider provider, bool isDark) {
    final screenWidth = MediaQuery.of(context).size.width;
    final sidebarWidth = screenWidth > 900 ? 280.0 : 0.0;
    final isWide = (screenWidth - sidebarWidth) > 700;
    final stats = _calculateStats(provider);

    return Container(
      padding: const EdgeInsets.all(24),
      color: isDark
          ? Colors.grey.shade900.withOpacity(0.5)
          : const Color(0xFFF1F5F9),
      child: isWide
          ? Row(
        children: [
          _buildStatCard(
              label: 'Total',
              value: '${stats['total']}',
              color: const Color(0xFF3B82F6),
              icon: Icons.people,
              isDark: isDark),
          const SizedBox(width: 16),
          _buildStatCard(
              label: 'Actifs',
              value: '${stats['actifs']}',
              color: const Color(0xFF10B981),
              icon: Icons.check_circle,
              isDark: isDark),
          const SizedBox(width: 16),
          _buildStatCard(
              label: 'Étudiants',
              value: '${stats['etudiants']}',
              color: const Color(0xFF8B5CF6),
              icon: Icons.school,
              isDark: isDark),
          const SizedBox(width: 16),
          _buildStatCard(
              label: 'Gestionnaires',
              value: '${stats['gestionnaires']}',
              color: const Color(0xFFF59E0B),
              icon: Icons.manage_accounts,
              isDark: isDark),
          const SizedBox(width: 16),
          _buildStatCard(
              label: 'Admins',
              value: '${stats['admins']}',
              color: const Color(0xFFEC4899),
              icon: Icons.admin_panel_settings,
              isDark: isDark),
        ],
      )
          : Column(
        children: [
          Row(
            children: [
              Expanded(
                  child: _buildStatCard(
                      label: 'Total',
                      value: '${stats['total']}',
                      color: const Color(0xFF3B82F6),
                      icon: Icons.people,
                      isDark: isDark)),
              const SizedBox(width: 12),
              Expanded(
                  child: _buildStatCard(
                      label: 'Actifs',
                      value: '${stats['actifs']}',
                      color: const Color(0xFF10B981),
                      icon: Icons.check_circle,
                      isDark: isDark)),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                  child: _buildStatCard(
                      label: 'Étudiants',
                      value: '${stats['etudiants']}',
                      color: const Color(0xFF8B5CF6),
                      icon: Icons.school,
                      isDark: isDark)),
              const SizedBox(width: 12),
              Expanded(
                  child: _buildStatCard(
                      label: 'Gestionnaires',
                      value: '${stats['gestionnaires']}',
                      color: const Color(0xFFF59E0B),
                      icon: Icons.manage_accounts,
                      isDark: isDark)),
            ],
          ),
          const SizedBox(height: 12),
          _buildStatCard(
              label: 'Admins',
              value: '${stats['admins']}',
              color: const Color(0xFFEC4899),
              icon: Icons.admin_panel_settings,
              isDark: isDark),
        ],
      ),
    );
  }

  Map<String, int> _calculateStats(UserAdminProvider provider) {
    return {
      'total': provider.users.length,
      'actifs': provider.users.where((u) => u.isActive).length,
      'etudiants': provider.users.where((u) => u.isStudent).length,
      'gestionnaires': provider.users.where((u) => u.isGestionnaire).length,
      'admins': provider.users.where((u) => u.isAdmin).length,
    };
  }

  Widget _buildStatCard({
    required String label,
    required String value,
    required Color color,
    required IconData icon,
    required bool isDark,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppTheme.getCardBackground(context),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(isDark ? 0.1 : 0.05),
                blurRadius: 10)
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(isDark ? 0.2 : 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(value,
                      style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: color)),
                  const SizedBox(height: 4),
                  Text(label,
                      style: TextStyle(
                          fontSize: 13,
                          color: AppTheme.getTextSecondary(context))),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==================== FILTRES AVANCÉS ====================

  Widget _buildFiltersCard(bool isDark) {
    return Container(
      margin: const EdgeInsets.fromLTRB(24, 0, 24, 24),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.getCardBackground(context),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.1 : 0.05),
              blurRadius: 10)
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Filtres avancés',
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.getTextPrimary(context)),
              ),
              const Spacer(),
              TextButton.icon(
                onPressed: () => setState(() => _showFilters = false),
                icon: Icon(Icons.close,
                    size: 16, color: AppTheme.getTextSecondary(context)),
                label: Text('Fermer',
                    style:
                    TextStyle(color: AppTheme.getTextSecondary(context))),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'Autres options de filtrage seront ajoutées ici',
            style: TextStyle(color: AppTheme.getTextSecondary(context)),
          ),
        ],
      ),
    );
  }

  // ==================== TABLEAU RESPONSIVE AVEC SCROLL HORIZONTAL ====================

  Widget _buildUsersTable(UserAdminProvider provider, bool isDark) {
    final screenWidth = MediaQuery.of(context).size.width;
    final sidebarWidth = screenWidth > 900 ? 220.0 : 0.0;
    final availableWidth = screenWidth - sidebarWidth - 48; // marges 24*2
    final tableWidth = availableWidth > 900 ? availableWidth : 900.0;

    // Proportions des colonnes — identiques header & lignes
    final colUtilisateur = tableWidth * 0.23;
    final colMatricule   = tableWidth * 0.13;
    final colRole        = tableWidth * 0.14;
    final colStatut      = tableWidth * 0.14;
    final colDate        = tableWidth * 0.15;
    final colActions     = tableWidth * 0.12; // oeil + stylo + trois-points

    return Container(
      margin: const EdgeInsets.fromLTRB(24, 0, 24, 24),
      decoration: BoxDecoration(
        color: AppTheme.getCardBackground(context),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.1 : 0.05),
              blurRadius: 10)
        ],
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: SizedBox(
          width: tableWidth,
          child: Column(
            children: [
              // ── En-tête ──
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 20, vertical: 16),
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.grey.shade900.withOpacity(0.5)
                      : const Color(0xFFF8FAFC),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(12),
                    topRight: Radius.circular(12),
                  ),
                  border: Border(
                      bottom: BorderSide(
                          color: AppTheme.getBorderColor(context), width: 1)),
                ),
                child: Row(
                  children: [
                    SizedBox(
                        width: colUtilisateur,
                        child: _headerText('Utilisateur')),
                    SizedBox(
                        width: colMatricule,
                        child: _headerText('Matricule')),
                    SizedBox(
                        width: colRole, child: _headerText('Rôle')),
                    SizedBox(
                        width: colStatut, child: _headerText('Statut')),
                    SizedBox(
                        width: colDate,
                        child: _headerText('Date création')),
                    SizedBox(
                        width: colActions,
                        child: _headerText('Actions')),
                  ],
                ),
              ),
              // ── Lignes ──
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: provider.users.length,
                itemBuilder: (context, index) => _buildUserRow(
                  provider.users[index],
                  provider,
                  index,
                  isDark,
                  colUtilisateur: colUtilisateur,
                  colMatricule: colMatricule,
                  colRole: colRole,
                  colStatut: colStatut,
                  colDate: colDate,
                  colActions: colActions,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _headerText(String text) {
    return Text(
      text,
      style: TextStyle(
        fontWeight: FontWeight.bold,
        color: AppTheme.getTextPrimary(context),
        fontSize: 13,
      ),
    );
  }

  // ==================== LIGNE UTILISATEUR ====================

  Widget _buildUserRow(
      AdminUser user,
      UserAdminProvider provider,
      int index,
      bool isDark, {
        required double colUtilisateur,
        required double colMatricule,
        required double colRole,
        required double colStatut,
        required double colDate,
        required double colActions,
      }) {
    return Container(
      padding:
      const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        color: index.isEven
            ? AppTheme.getCardBackground(context)
            : (isDark
            ? Colors.grey.shade900.withOpacity(0.3)
            : const Color(0xFFFAFAFA)),
        border: Border(
            bottom: BorderSide(
                color: AppTheme.getBorderColor(context), width: 1)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Utilisateur
          SizedBox(
            width: colUtilisateur,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '${user.prenom} ${user.nom}',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: AppTheme.getTextPrimary(context),
                    fontSize: 14,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 3),
                Text(
                  user.email,
                  style: TextStyle(
                      fontSize: 12,
                      color: AppTheme.getTextSecondary(context)),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  user.telephone,
                  style: TextStyle(
                      fontSize: 11,
                      color: AppTheme.getTextTertiary(context)),
                ),
                if (user.centreNom != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    user.centreNom!,
                    style: TextStyle(
                        fontSize: 11,
                        color: AppTheme.getTextTertiary(context)),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),

          // Matricule
          SizedBox(
            width: colMatricule,
            child: Text(
              user.matricule,
              style: TextStyle(
                  color: AppTheme.getTextSecondary(context),
                  fontSize: 13),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),

          // Rôle — badge centré, taille au contenu
          SizedBox(
            width: colRole,
            child: Align(
              alignment: Alignment.centerLeft,
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: _getRoleColor(user.role)
                      .withOpacity(isDark ? 0.2 : 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: _getRoleColor(user.role)
                        .withOpacity(isDark ? 0.4 : 0.3),
                    width: 1,
                  ),
                ),
                child: Text(
                  _getRoleLabel(user.role),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: _getRoleColor(user.role),
                  ),
                ),
              ),
            ),
          ),

          // Statut — badge centré avec point coloré
          SizedBox(
            width: colStatut,
            child: Align(
              alignment: Alignment.centerLeft,
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: _getStatutColor(user.statut)
                      .withOpacity(isDark ? 0.2 : 0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: _getStatutColor(user.statut)
                        .withOpacity(isDark ? 0.5 : 0.4),
                    width: 1.5,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: _getStatutColor(user.statut),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      _getStatutLabel(user.statut),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: _getStatutColor(user.statut),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Date création — alignée verticalement avec le reste
          SizedBox(
            width: colDate,
            child: Text(
              _formatDate(user.createdAt),
              style: TextStyle(
                  color: AppTheme.getTextSecondary(context), fontSize: 13),
            ),
          ),

          // Actions — espacement uniforme entre les 3 icônes
          SizedBox(
            width: colActions,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                // Œil
                IconButton(
                  onPressed: () => _showUserDetails(user, provider),
                  icon: Icon(Icons.visibility_outlined,
                      size: 20,
                      color: AppTheme.getTextSecondary(context)),
                  tooltip: 'Voir détails',
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
                const SizedBox(width: 12),
                // Stylo
                IconButton(
                  onPressed: () => _showEditUserDialog(user, provider),
                  icon: const Icon(Icons.edit_outlined,
                      size: 20, color: Color(0xFF3B82F6)),
                  tooltip: 'Modifier',
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
                const SizedBox(width: 12),
                // Trois points
                PopupMenuButton<String>(
                  icon: Icon(Icons.more_vert,
                      size: 20,
                      color: AppTheme.getTextSecondary(context)),
                  color: AppTheme.getCardBackground(context),
                  surfaceTintColor: AppTheme.getCardBackground(context),
                  itemBuilder: (context) =>
                      _buildActionMenu(user, isDark),
                  onSelected: (value) =>
                      _handleAction(value, user, provider),
                  padding: EdgeInsets.zero,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ==================== ÉTATS VIDE / ERREUR ====================

  Widget _buildEmptyState(bool isDark) {
    return Container(
      margin: const EdgeInsets.all(24),
      padding: const EdgeInsets.all(48),
      decoration: BoxDecoration(
        color: AppTheme.getCardBackground(context),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.1 : 0.05),
              blurRadius: 10)
        ],
      ),
      child: Center(
        child: Column(
          children: [
            Icon(Icons.people_outline,
                size: 80, color: AppTheme.getTextTertiary(context)),
            const SizedBox(height: 24),
            Text(
              'Aucun utilisateur trouvé',
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.getTextSecondary(context)),
            ),
            const SizedBox(height: 8),
            Text(
              'Ajustez vos filtres ou créez un nouvel utilisateur',
              style: TextStyle(color: AppTheme.getTextTertiary(context)),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _resetFilters,
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Colors.white,
              ),
              child: const Text('Réinitialiser les filtres'),
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: () => _showCreateUserDialog(),
              icon: const Icon(Icons.add, color: Colors.white),
              label: const Text('Créer un nouvel utilisateur',
                  style: TextStyle(color: Colors.white)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorWidget(String error, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(24),
      margin: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.red.shade900.withOpacity(0.1)
            : const Color(0xFFFEF2F2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color:
            isDark ? Colors.red.shade800 : const Color(0xFFFECACA)),
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 48, color: Colors.red.shade400),
            const SizedBox(height: 16),
            Text('Erreur de chargement',
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.red.shade400)),
            const SizedBox(height: 8),
            Text(error,
                textAlign: TextAlign.center,
                style: TextStyle(
                    color: isDark
                        ? Colors.red.shade300
                        : const Color(0xFF991B1B))),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _refreshData,
              style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red.shade400,
                  foregroundColor: Colors.white),
              child: const Text('Réessayer'),
            ),
          ],
        ),
      ),
    );
  }

  // ==================== MENU CONTEXTUEL ====================

  List<PopupMenuEntry<String>> _buildActionMenu(
      AdminUser user, bool isDark) {
    return [
      PopupMenuItem(
        value: 'details',
        child: Row(children: [
          Icon(Icons.info_outline,
              size: 18, color: AppTheme.getTextSecondary(context)),
          const SizedBox(width: 8),
          Text('Détails complets',
              style: TextStyle(color: AppTheme.getTextPrimary(context))),
        ]),
      ),
      if (user.role == 'ETUDIANT')
        PopupMenuItem(
          value: 'send_annonce',
          child: Row(children: [
            const Icon(Icons.send, size: 18, color: Color(0xFF3B82F6)),
            const SizedBox(width: 8),
            Text('Envoyer une annonce',
                style:
                TextStyle(color: AppTheme.getTextPrimary(context))),
          ]),
        ),
      PopupMenuItem(
        value: 'edit',
        child: Row(children: [
          const Icon(Icons.edit, size: 18, color: Color(0xFF3B82F6)),
          const SizedBox(width: 8),
          Text('Modifier',
              style: TextStyle(color: AppTheme.getTextPrimary(context))),
        ]),
      ),
      if (user.isActive) ...[
        PopupMenuItem(
          value: 'desactiver',
          child: Row(children: [
            const Icon(Icons.pause_circle,
                size: 18, color: Color(0xFFF59E0B)),
            const SizedBox(width: 8),
            Text('Désactiver',
                style:
                TextStyle(color: AppTheme.getTextPrimary(context))),
          ]),
        ),
        PopupMenuItem(
          value: 'suspendre',
          child: Row(children: [
            const Icon(Icons.block, size: 18, color: Color(0xFFEF4444)),
            const SizedBox(width: 8),
            Text('Suspendre',
                style:
                TextStyle(color: AppTheme.getTextPrimary(context))),
          ]),
        ),
      ] else if (user.statut == 'INACTIF' ||
          user.statut == 'SUSPENDU') ...[
        PopupMenuItem(
          value: 'reactiver',
          child: Row(children: [
            const Icon(Icons.play_arrow,
                size: 18, color: Color(0xFF10B981)),
            const SizedBox(width: 8),
            Text('Réactiver',
                style:
                TextStyle(color: AppTheme.getTextPrimary(context))),
          ]),
        ),
      ],
      const PopupMenuDivider(),
      PopupMenuItem(
        value: 'supprimer',
        child: Row(children: [
          const Icon(Icons.delete, size: 18, color: Color(0xFFEF4444)),
          const SizedBox(width: 8),
          Text('Supprimer',
              style: TextStyle(color: Colors.red.shade700)),
        ]),
      ),
    ];
  }

  // ==================== ACTIONS ====================

  Future<void> _handleAction(
      String action, AdminUser user, UserAdminProvider provider) async {
    switch (action) {
      case 'details':
        _showUserDetails(user, provider);
        break;
      case 'edit':
        _showEditUserDialog(user, provider);
        break;
      case 'send_annonce':
        _showSendAnnonceDialog(user);
        break;
      case 'desactiver':
        await _updateUserStatus(user, 'INACTIF', provider);
        break;
      case 'suspendre':
        await _updateUserStatus(user, 'SUSPENDU', provider);
        break;
      case 'reactiver':
        await _updateUserStatus(user, 'ACTIF', provider);
        break;
      case 'supprimer':
        await _deleteUser(user, provider);
        break;
    }
  }

  Future<void> _updateUserStatus(
      AdminUser user, String nouveauStatut, UserAdminProvider provider) async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    try {
      final confirm = await _showConfirmationDialog(
        title: 'Confirmer la modification',
        message:
        'Voulez-vous vraiment ${_getStatutLabel(nouveauStatut).toLowerCase()} cet utilisateur ?',
        isDark: isDark,
      );
      if (confirm == true) {
        await provider.updateUserStatus(user.id, nouveauStatut);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(
              'Utilisateur ${_getStatutLabel(nouveauStatut).toLowerCase()} avec succès'),
          backgroundColor: _getStatutColor(nouveauStatut),
          behavior: SnackBarBehavior.floating,
        ));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Erreur: $e'),
        backgroundColor: const Color(0xFFEF4444),
        behavior: SnackBarBehavior.floating,
      ));
    }
  }

  Future<void> _deleteUser(
      AdminUser user, UserAdminProvider provider) async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    try {
      final confirm = await _showConfirmationDialog(
        title: 'Confirmer la suppression',
        message:
        'Voulez-vous vraiment supprimer définitivement cet utilisateur ?\nCette action est irréversible.',
        isCritical: true,
        isDark: isDark,
      );
      if (confirm == true) {
        await provider.deleteUser(user.id);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Utilisateur supprimé avec succès'),
          backgroundColor: Color(0xFF10B981),
          behavior: SnackBarBehavior.floating,
        ));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Erreur: $e'),
        backgroundColor: const Color(0xFFEF4444),
        behavior: SnackBarBehavior.floating,
      ));
    }
  }

  // ==================== DIALOGUES ====================

  void _showUserDetails(AdminUser user, UserAdminProvider provider) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: AppTheme.getCardBackground(context),
        shape:
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: 600,
            maxHeight: MediaQuery.of(context).size.height * 0.85,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
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
                        color: Theme.of(context)
                            .colorScheme
                            .primary
                            .withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(Icons.person,
                          color: Theme.of(context).colorScheme.primary,
                          size: 24),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Détails de l\'utilisateur',
                              style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color:
                                  AppTheme.getTextPrimary(context))),
                          const SizedBox(height: 4),
                          Text(user.matricule,
                              style: TextStyle(
                                  fontSize: 13,
                                  color: AppTheme.getTextSecondary(
                                      context))),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: Icon(Icons.close,
                          color: AppTheme.getTextSecondary(context)),
                    ),
                  ],
                ),
              ),
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSectionHeader(
                          'Informations personnelles', Icons.person),
                      const SizedBox(height: 12),
                      _buildInfoGrid([
                        ('Nom complet', '${user.prenom} ${user.nom}'),
                        ('Matricule', user.matricule),
                        ('Email', user.email),
                        ('Téléphone', user.telephone),
                      ]),
                      const SizedBox(height: 24),
                      _buildSectionHeader(
                          'Compte', Icons.admin_panel_settings),
                      const SizedBox(height: 12),
                      _buildInfoGrid([
                        ('Rôle', _getRoleLabel(user.role)),
                        ('Statut', _getStatutLabel(user.statut)),
                        ('Date création', _formatDate(user.createdAt)),
                        if (user.updatedAt != null)
                          ('Dernière modification',
                          _formatDate(user.updatedAt!)),
                      ]),
                      if (user.centreNom != null ||
                          user.numeroChambre != null) ...[
                        const SizedBox(height: 24),
                        _buildSectionHeader('Logement', Icons.home),
                        const SizedBox(height: 12),
                        _buildInfoGrid([
                          if (user.centreNom != null)
                            ('Centre', user.centreNom!),
                          if (user.numeroChambre != null)
                            ('Numéro de chambre', user.numeroChambre!),
                        ]),
                      ],
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
                      top: BorderSide(
                          color: AppTheme.getBorderColor(context))),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text('Fermer',
                          style: TextStyle(
                              color: AppTheme.getTextSecondary(context))),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        _showEditUserDialog(user, provider);
                      },
                      icon: const Icon(Icons.edit,
                          size: 18, color: Colors.white),
                      label: const Text('Modifier',
                          style: TextStyle(color: Colors.white)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                        Theme.of(context).colorScheme.primary,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 12),
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

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 18, color: Theme.of(context).colorScheme.primary),
        const SizedBox(width: 8),
        Text(title,
            style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: AppTheme.getTextPrimary(context))),
      ],
    );
  }

  Widget _buildInfoGrid(List<(String, String)> items) {
    return Wrap(
      spacing: 16,
      runSpacing: 12,
      children: items.map((item) {
        return SizedBox(
            width: 250, child: _buildDetailItem(item.$1, item.$2));
      }).toList(),
    );
  }

  Widget _buildDetailItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: TextStyle(
                  fontSize: 12,
                  color: AppTheme.getTextSecondary(context),
                  fontWeight: FontWeight.w500)),
          const SizedBox(height: 4),
          Text(value,
              style: TextStyle(
                  fontSize: 16,
                  color: AppTheme.getTextPrimary(context))),
        ],
      ),
    );
  }

  Future<void> _showSendAnnonceDialog(AdminUser user) async {
    final titreController = TextEditingController();
    final contenuController = TextEditingController();
    bool isSending = false;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => Dialog(
          backgroundColor: AppTheme.getCardBackground(context),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16)),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: 550,
              maxHeight: MediaQuery.of(context).size.height * 0.8,
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
                          color:
                          const Color(0xFF3B82F6).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.send,
                            color: Color(0xFF3B82F6), size: 24),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Envoyer une annonce',
                                style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color:
                                    AppTheme.getTextPrimary(context))),
                            const SizedBox(height: 4),
                            Text('À: ${user.prenom} ${user.nom}',
                                style: TextStyle(
                                    fontSize: 14,
                                    color: AppTheme.getTextSecondary(
                                        context))),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed:
                        isSending ? null : () => Navigator.pop(context),
                        icon: Icon(Icons.close,
                            color: AppTheme.getTextSecondary(context)),
                      ),
                    ],
                  ),
                ),
                Flexible(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      children: [
                        TextField(
                          controller: titreController,
                          decoration: InputDecoration(
                            labelText: 'Titre *',
                            labelStyle: TextStyle(
                                color:
                                AppTheme.getTextSecondary(context)),
                            border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide(
                                    color: AppTheme.getBorderColor(
                                        context))),
                            enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide(
                                    color: AppTheme.getBorderColor(
                                        context))),
                            focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .primary,
                                    width: 2)),
                            filled: true,
                            fillColor: isDark
                                ? Colors.grey.shade900.withOpacity(0.3)
                                : Colors.grey.shade50,
                          ),
                          maxLength: 100,
                          style: TextStyle(
                              color: AppTheme.getTextPrimary(context)),
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: contenuController,
                          decoration: InputDecoration(
                            labelText: 'Message *',
                            labelStyle: TextStyle(
                                color:
                                AppTheme.getTextSecondary(context)),
                            border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide(
                                    color: AppTheme.getBorderColor(
                                        context))),
                            enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide(
                                    color: AppTheme.getBorderColor(
                                        context))),
                            focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .primary,
                                    width: 2)),
                            alignLabelWithHint: true,
                            filled: true,
                            fillColor: isDark
                                ? Colors.grey.shade900.withOpacity(0.3)
                                : Colors.grey.shade50,
                          ),
                          maxLines: 6,
                          maxLength: 500,
                          style: TextStyle(
                              color: AppTheme.getTextPrimary(context)),
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
                        top: BorderSide(
                            color: AppTheme.getBorderColor(context))),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: isSending
                            ? null
                            : () => Navigator.pop(context),
                        child: Text('Annuler',
                            style: TextStyle(
                                color:
                                AppTheme.getTextSecondary(context))),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton.icon(
                        onPressed: isSending
                            ? null
                            : () async {
                          if (titreController.text.trim().isEmpty ||
                              contenuController.text.trim().isEmpty) {
                            ScaffoldMessenger.of(context)
                                .showSnackBar(const SnackBar(
                              content: Text(
                                  'Veuillez remplir tous les champs'),
                              backgroundColor: Colors.orange,
                              behavior: SnackBarBehavior.floating,
                            ));
                            return;
                          }
                          setState(() => isSending = true);
                          try {
                            final apiService = ApiService();
                            await apiService
                                .post('/api/annonces/send', body: {
                              'titre': titreController.text.trim(),
                              'contenu':
                              contenuController.text.trim(),
                              'cible': 'ETUDIANTS',
                              'user_ids': [user.id],
                              'statut': 'PUBLIE',
                            });
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context)
                                .showSnackBar(SnackBar(
                              content: Text(
                                  'Annonce envoyée à ${user.prenom} ${user.nom}'),
                              backgroundColor:
                              const Color(0xFF10B981),
                              behavior: SnackBarBehavior.floating,
                            ));
                          } catch (e) {
                            ScaffoldMessenger.of(context)
                                .showSnackBar(SnackBar(
                              content: Text('Erreur: $e'),
                              backgroundColor:
                              const Color(0xFFEF4444),
                              behavior: SnackBarBehavior.floating,
                            ));
                          } finally {
                            setState(() => isSending = false);
                          }
                        },
                        icon: isSending
                            ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white))
                            : const Icon(Icons.send,
                            size: 18, color: Colors.white),
                        label: Text(isSending ? 'Envoi...' : 'Envoyer',
                            style: const TextStyle(color: Colors.white)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                          Theme.of(context).colorScheme.primary,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 12),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    titreController.dispose();
    contenuController.dispose();
  }

  Future<void> _showCreateUserDialog() async {
    final provider = Provider.of<UserAdminProvider>(context, listen: false);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (provider.centres.isEmpty) {
      await provider.loadCentres();
    }

    final matriculeController = TextEditingController();
    final nomController = TextEditingController();
    final prenomController = TextEditingController();
    final emailController = TextEditingController();
    final telephoneController = TextEditingController();
    final passwordController = TextEditingController();
    final confirmPasswordController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    String selectedRole = 'ETUDIANT';
    String selectedStatut = 'ACTIF';
    int? selectedCentreId;
    int? selectedLogementId;
    bool generatePassword = true;
    bool isPasswordVisible = false;
    bool isConfirmPasswordVisible = false;
    bool isSaving = false;
    List<Map<String, dynamic>> availableLogements = [];

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => Dialog(
          backgroundColor: AppTheme.getCardBackground(context),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16)),
          child: SingleChildScrollView(
            child: Container(
              width: 600,
              padding: const EdgeInsets.all(24),
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Theme.of(context)
                              .colorScheme
                              .primary
                              .withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(Icons.person_add,
                            color:
                            Theme.of(context).colorScheme.primary,
                            size: 24),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Nouvel étudiant',
                                style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color:
                                    AppTheme.getTextPrimary(context))),
                            const SizedBox(height: 4),
                            Text(
                                'Remplissez les informations de l\'étudiant',
                                style: TextStyle(
                                    fontSize: 14,
                                    color: AppTheme.getTextSecondary(
                                        context))),
                          ],
                        ),
                      ),
                    ]),
                    const SizedBox(height: 24),
                    _buildFormField(
                      controller: matriculeController,
                      label: 'Matricule *',
                      hint: 'Ex: ETUD2024001',
                      icon: Icons.badge,
                      isDark: isDark,
                      validator: (v) {
                        if (v == null || v.trim().isEmpty)
                          return 'Le matricule est requis';
                        if (v.trim().length < 5)
                          return 'Au moins 5 caractères';
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    Row(children: [
                      Expanded(
                        child: _buildFormField(
                          controller: nomController,
                          label: 'Nom *',
                          hint: 'Nom de famille',
                          icon: Icons.person,
                          isDark: isDark,
                          validator: (v) {
                            if (v == null || v.trim().isEmpty)
                              return 'Le nom est requis';
                            if (v.trim().length < 2)
                              return 'Au moins 2 caractères';
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildFormField(
                          controller: prenomController,
                          label: 'Prénom *',
                          hint: 'Prénom',
                          icon: Icons.person_outline,
                          isDark: isDark,
                          validator: (v) {
                            if (v == null || v.trim().isEmpty)
                              return 'Le prénom est requis';
                            if (v.trim().length < 2)
                              return 'Au moins 2 caractères';
                            return null;
                          },
                        ),
                      ),
                    ]),
                    const SizedBox(height: 16),
                    _buildFormField(
                      controller: emailController,
                      label: 'Email *',
                      hint: 'exemple@cenou.bf',
                      icon: Icons.email,
                      isDark: isDark,
                      keyboardType: TextInputType.emailAddress,
                      validator: (v) {
                        if (v == null || v.trim().isEmpty)
                          return 'L\'email est requis';
                        if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
                            .hasMatch(v.trim())) return 'Email invalide';
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    _buildFormField(
                      controller: telephoneController,
                      label: 'Téléphone (optionnel)',
                      hint: '+226 70 XX XX XX',
                      icon: Icons.phone,
                      isDark: isDark,
                      keyboardType: TextInputType.phone,
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<int>(
                      value: selectedCentreId,
                      decoration: _dropdownDecoration(
                          'Centre *', Icons.location_city, isDark),
                      dropdownColor: AppTheme.getCardBackground(context),
                      style: TextStyle(
                          color: AppTheme.getTextPrimary(context)),
                      items: provider.centres.map((centre) {
                        return DropdownMenuItem<int>(
                          value: centre.id,
                          child: Text(centre.nom,
                              style: TextStyle(
                                  color:
                                  AppTheme.getTextPrimary(context))),
                        );
                      }).toList(),
                      onChanged: (value) async {
                        setState(() {
                          selectedCentreId = value;
                          selectedLogementId = null;
                          availableLogements = [];
                        });
                        if (value != null) {
                          await provider.loadAvailableLogements(value);
                          setState(() {
                            availableLogements =
                                provider.availableLogements;
                          });
                        }
                      },
                      validator: (v) =>
                      v == null ? 'Sélectionnez un centre' : null,
                    ),
                    if (selectedCentreId != null) ...[
                      const SizedBox(height: 16),
                      DropdownButtonFormField<int>(
                        value: selectedLogementId,
                        decoration: _dropdownDecoration(
                            'Logement (optionnel)', Icons.home, isDark),
                        dropdownColor: AppTheme.getCardBackground(context),
                        style: TextStyle(
                            color: AppTheme.getTextPrimary(context)),
                        items: availableLogements.isEmpty
                            ? [
                          DropdownMenuItem<int>(
                              value: null,
                              child: Text('Aucun logement disponible',
                                  style: TextStyle(
                                      color:
                                      AppTheme.getTextTertiary(
                                          context))))
                        ]
                            : availableLogements.map((l) {
                          return DropdownMenuItem<int>(
                            value: l['id'],
                            child: Text(
                                'Chambre ${l['numero_chambre']} - ${l['type_chambre']}',
                                style: TextStyle(
                                    color:
                                    AppTheme.getTextPrimary(
                                        context))),
                          );
                        }).toList(),
                        onChanged: (v) =>
                            setState(() => selectedLogementId = v),
                      ),
                    ],
                    const SizedBox(height: 16),
                    CheckboxListTile(
                      value: generatePassword,
                      onChanged: (v) => setState(() {
                        generatePassword = v ?? true;
                        if (generatePassword) {
                          passwordController.clear();
                          confirmPasswordController.clear();
                        }
                      }),
                      title: Text(
                          'Générer un mot de passe automatiquement',
                          style: TextStyle(
                              color: AppTheme.getTextPrimary(context),
                              fontSize: 14)),
                      controlAffinity: ListTileControlAffinity.leading,
                      activeColor:
                      Theme.of(context).colorScheme.primary,
                      contentPadding: EdgeInsets.zero,
                    ),
                    if (!generatePassword) ...[
                      const SizedBox(height: 8),
                      _buildPasswordField(
                        controller: passwordController,
                        label: 'Mot de passe *',
                        hint: 'Minimum 6 caractères',
                        isVisible: isPasswordVisible,
                        isDark: isDark,
                        onToggle: () => setState(
                                () => isPasswordVisible = !isPasswordVisible),
                        validator: (v) {
                          if (!generatePassword) {
                            if (v == null || v.trim().isEmpty)
                              return 'Requis';
                            if (v.length < 6)
                              return 'Au moins 6 caractères';
                            if (!RegExp(r'[A-Z]').hasMatch(v))
                              return 'Au moins une majuscule';
                            if (!RegExp(r'[0-9]').hasMatch(v))
                              return 'Au moins un chiffre';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      _buildPasswordField(
                        controller: confirmPasswordController,
                        label: 'Confirmer le mot de passe *',
                        hint: 'Retapez le mot de passe',
                        isVisible: isConfirmPasswordVisible,
                        isDark: isDark,
                        icon: Icons.lock_outline,
                        onToggle: () => setState(() =>
                        isConfirmPasswordVisible =
                        !isConfirmPasswordVisible),
                        validator: (v) {
                          if (!generatePassword) {
                            if (v == null || v.trim().isEmpty)
                              return 'Confirmation requise';
                            if (v != passwordController.text)
                              return 'Les mots de passe ne correspondent pas';
                          }
                          return null;
                        },
                      ),
                    ],
                    if (generatePassword) ...[
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.blue.withOpacity(isDark ? 0.2 : 0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                              color: Colors.blue.withOpacity(0.3)),
                        ),
                        child: Row(children: [
                          const Icon(Icons.info_outline,
                              color: Colors.blue, size: 20),
                          const SizedBox(width: 12),
                          Expanded(
                              child: Text(
                                  'Un mot de passe sécurisé sera généré automatiquement.',
                                  style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.blue.shade700))),
                        ]),
                      ),
                    ],
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: isSaving
                              ? null
                              : () => Navigator.pop(context),
                          child: Text('Annuler',
                              style: TextStyle(
                                  color:
                                  AppTheme.getTextSecondary(context))),
                        ),
                        const SizedBox(width: 12),
                        ElevatedButton.icon(
                          onPressed: isSaving
                              ? null
                              : () async {
                            if (formKey.currentState!.validate()) {
                              final sm =
                              ScaffoldMessenger.of(context);
                              setState(() => isSaving = true);
                              try {
                                await provider.createUser(
                                  matricule: matriculeController.text
                                      .trim(),
                                  nom: nomController.text.trim(),
                                  prenom: prenomController.text.trim(),
                                  email: emailController.text.trim(),
                                  telephone: telephoneController.text
                                      .trim()
                                      .isEmpty
                                      ? null
                                      : telephoneController.text
                                      .trim(),
                                  role: selectedRole,
                                  statut: selectedStatut,
                                  motDePasse: generatePassword
                                      ? null
                                      : passwordController.text.trim(),
                                  centreId: selectedCentreId,
                                  logementId: selectedLogementId,
                                  dateDebut: selectedLogementId != null
                                      ? DateTime.now()
                                      .toIso8601String()
                                      : null,
                                );
                                Navigator.pop(context);
                                sm.showSnackBar(const SnackBar(
                                  content:
                                  Text('Étudiant créé avec succès'),
                                  backgroundColor: Color(0xFF10B981),
                                  behavior:
                                  SnackBarBehavior.floating,
                                ));
                              } catch (e) {
                                setState(() => isSaving = false);
                                sm.showSnackBar(SnackBar(
                                  content: Text('Erreur: $e'),
                                  backgroundColor:
                                  const Color(0xFFEF4444),
                                  behavior:
                                  SnackBarBehavior.floating,
                                ));
                              }
                            }
                          },
                          icon: isSaving
                              ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white))
                              : const Icon(Icons.save, color: Colors.white),
                          label: Text(
                              isSaving ? 'Création...' : 'Créer l\'étudiant',
                              style:
                              const TextStyle(color: Colors.white)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                            Theme.of(context).colorScheme.primary,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 24, vertical: 14),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );

    matriculeController.dispose();
    nomController.dispose();
    prenomController.dispose();
    emailController.dispose();
    telephoneController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
  }

  Future<void> _showEditUserDialog(
      AdminUser user, UserAdminProvider provider) async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    if (provider.centres.isEmpty) await provider.loadCentres();

    final matriculeController =
    TextEditingController(text: user.matricule);
    final nomController = TextEditingController(text: user.nom);
    final prenomController = TextEditingController(text: user.prenom);
    final emailController = TextEditingController(text: user.email);
    final telephoneController =
    TextEditingController(text: user.telephone);
    final formKey = GlobalKey<FormState>();

    String selectedRole = user.role;
    String selectedStatut = user.statut;
    int? selectedCentreId;

    if (user.centreNom != null && user.centreNom!.isNotEmpty) {
      final match = provider.centres.firstWhere(
              (c) => c.nom == user.centreNom,
          orElse: () => Centre(id: 0, nom: ''));
      if (match.id != 0) selectedCentreId = match.id;
    }

    int? selectedLogementId;
    bool isSaving = false;
    List<Map<String, dynamic>> availableLogements = [];

    if (selectedCentreId != null) {
      await provider.loadAvailableLogements(selectedCentreId);
      availableLogements = provider.availableLogements;
      if (user.numeroChambre != null) {
        final cur = availableLogements.firstWhere(
                (l) => l['numero_chambre'] == user.numeroChambre,
            orElse: () => <String, dynamic>{});
        if (cur.isNotEmpty) selectedLogementId = cur['id'] as int?;
      }
    }

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => Dialog(
          backgroundColor: AppTheme.getCardBackground(context),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16)),
          child: SingleChildScrollView(
            child: Container(
              width: 600,
              padding: const EdgeInsets.all(24),
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFF3B82F6).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.edit,
                            color: Color(0xFF3B82F6), size: 24),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Modifier l\'utilisateur',
                                style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color:
                                    AppTheme.getTextPrimary(context))),
                            const SizedBox(height: 4),
                            Text(user.fullName,
                                style: TextStyle(
                                    fontSize: 14,
                                    color: AppTheme.getTextSecondary(
                                        context))),
                          ],
                        ),
                      ),
                    ]),
                    const SizedBox(height: 24),
                    // Matricule (non modifiable)
                    TextFormField(
                      controller: matriculeController,
                      enabled: false,
                      decoration: InputDecoration(
                        labelText: 'Matricule',
                        labelStyle: TextStyle(
                            color: AppTheme.getTextSecondary(context)),
                        prefixIcon: Icon(Icons.badge,
                            color: AppTheme.getTextSecondary(context)),
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(
                                color:
                                AppTheme.getBorderColor(context))),
                        enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(
                                color:
                                AppTheme.getBorderColor(context))),
                        filled: true,
                        fillColor: isDark
                            ? Colors.grey.shade800
                            : Colors.grey.shade200,
                      ),
                      style: TextStyle(
                          color: AppTheme.getTextTertiary(context)),
                    ),
                    const SizedBox(height: 16),
                    Row(children: [
                      Expanded(
                        child: _buildFormField(
                          controller: nomController,
                          label: 'Nom *',
                          icon: Icons.person,
                          isDark: isDark,
                          validator: (v) => (v == null || v.trim().isEmpty)
                              ? 'Requis'
                              : null,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildFormField(
                          controller: prenomController,
                          label: 'Prénom *',
                          icon: Icons.person_outline,
                          isDark: isDark,
                          validator: (v) => (v == null || v.trim().isEmpty)
                              ? 'Requis'
                              : null,
                        ),
                      ),
                    ]),
                    const SizedBox(height: 16),
                    _buildFormField(
                      controller: emailController,
                      label: 'Email *',
                      icon: Icons.email,
                      isDark: isDark,
                      keyboardType: TextInputType.emailAddress,
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return 'Requis';
                        if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
                            .hasMatch(v.trim())) return 'Email invalide';
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    _buildFormField(
                      controller: telephoneController,
                      label: 'Téléphone',
                      icon: Icons.phone,
                      isDark: isDark,
                      keyboardType: TextInputType.phone,
                    ),
                    const SizedBox(height: 16),
                    // Rôle (non modifiable — affichage)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 16),
                      decoration: BoxDecoration(
                        color: isDark
                            ? Colors.grey.shade800
                            : Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                            color: AppTheme.getBorderColor(context)),
                      ),
                      child: Row(children: [
                        Icon(Icons.badge,
                            color: AppTheme.getTextSecondary(context),
                            size: 20),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Rôle',
                                  style: TextStyle(
                                      fontSize: 12,
                                      color:
                                      AppTheme.getTextSecondary(
                                          context))),
                              const SizedBox(height: 4),
                              Text(_getRoleLabel(selectedRole),
                                  style: TextStyle(
                                      fontSize: 16,
                                      color: AppTheme.getTextPrimary(
                                          context),
                                      fontWeight: FontWeight.w500)),
                            ],
                          ),
                        ),
                      ]),
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: selectedStatut,
                      decoration: _dropdownDecoration(
                          'Statut', Icons.circle, isDark),
                      dropdownColor: AppTheme.getCardBackground(context),
                      items: ['ACTIF', 'INACTIF', 'SUSPENDU'].map((s) {
                        return DropdownMenuItem<String>(
                          value: s,
                          child: Text(_getStatutLabel(s),
                              style: TextStyle(
                                  color: _getStatutColor(s),
                                  fontWeight: FontWeight.w500)),
                        );
                      }).toList(),
                      onChanged: (v) =>
                          setState(() => selectedStatut = v!),
                      style: TextStyle(
                          color: AppTheme.getTextPrimary(context)),
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<int?>(
                      value: selectedCentreId,
                      decoration: _dropdownDecoration(
                          'Centre', Icons.location_city, isDark),
                      dropdownColor: AppTheme.getCardBackground(context),
                      items: [
                        const DropdownMenuItem<int?>(
                            value: null,
                            child: Text('Aucun centre')),
                        ...provider.centres.map((c) {
                          return DropdownMenuItem<int?>(
                              value: c.id, child: Text(c.nom));
                        }),
                      ],
                      onChanged: (v) async {
                        setState(() {
                          selectedCentreId = v;
                          selectedLogementId = null;
                          availableLogements = [];
                        });
                        if (v != null) {
                          await provider.loadAvailableLogements(v);
                          setState(() => availableLogements =
                              provider.availableLogements);
                        }
                      },
                      style: TextStyle(
                          color: AppTheme.getTextPrimary(context)),
                    ),
                    if (selectedCentreId != null) ...[
                      const SizedBox(height: 16),
                      DropdownButtonFormField<int?>(
                        value: selectedLogementId,
                        decoration: _dropdownDecoration(
                            'Logement', Icons.home, isDark),
                        dropdownColor:
                        AppTheme.getCardBackground(context),
                        items: [
                          const DropdownMenuItem<int?>(
                              value: null,
                              child: Text('Aucun logement')),
                          ...availableLogements.map((l) {
                            return DropdownMenuItem<int?>(
                              value: l['id'] as int,
                              child: Text(
                                  'Chambre ${l['numero_chambre']} - ${l['type_chambre']}'),
                            );
                          }),
                        ],
                        onChanged: (v) =>
                            setState(() => selectedLogementId = v),
                        style: TextStyle(
                            color: AppTheme.getTextPrimary(context)),
                      ),
                    ],
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: isSaving
                              ? null
                              : () => Navigator.pop(context),
                          child: Text('Annuler',
                              style: TextStyle(
                                  color:
                                  AppTheme.getTextSecondary(context))),
                        ),
                        const SizedBox(width: 12),
                        ElevatedButton.icon(
                          onPressed: isSaving
                              ? null
                              : () async {
                            if (formKey.currentState!.validate()) {
                              final sm =
                              ScaffoldMessenger.of(context);
                              setState(() => isSaving = true);
                              try {
                                await provider.updateUser(
                                  userId: user.id,
                                  nom: nomController.text.trim(),
                                  prenom: prenomController.text.trim(),
                                  email: emailController.text.trim(),
                                  telephone: telephoneController.text
                                      .trim()
                                      .isEmpty
                                      ? null
                                      : telephoneController.text
                                      .trim(),
                                  statut: selectedStatut,
                                  logementId: selectedLogementId,
                                );
                                Navigator.pop(context);
                                sm.showSnackBar(const SnackBar(
                                  content: Text(
                                      'Utilisateur mis à jour avec succès'),
                                  backgroundColor: Color(0xFF10B981),
                                  behavior:
                                  SnackBarBehavior.floating,
                                ));
                              } catch (e) {
                                setState(() => isSaving = false);
                                sm.showSnackBar(SnackBar(
                                  content: Text('Erreur: $e'),
                                  backgroundColor:
                                  const Color(0xFFEF4444),
                                  behavior:
                                  SnackBarBehavior.floating,
                                ));
                              }
                            }
                          },
                          icon: isSaving
                              ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white))
                              : const Icon(Icons.save, color: Colors.white),
                          label: Text(
                              isSaving
                                  ? 'Enregistrement...'
                                  : 'Enregistrer',
                              style:
                              const TextStyle(color: Colors.white)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF3B82F6),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 24, vertical: 14),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );

    matriculeController.dispose();
    nomController.dispose();
    prenomController.dispose();
    emailController.dispose();
    telephoneController.dispose();
  }

  Future<bool?> _showConfirmationDialog({
    required String title,
    required String message,
    bool isCritical = false,
    required bool isDark,
  }) async {
    return showDialog<bool>(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: AppTheme.getCardBackground(context),
        shape:
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.getTextPrimary(context))),
              const SizedBox(height: 16),
              Text(message,
                  style: TextStyle(
                      color: AppTheme.getTextSecondary(context))),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: Text('Annuler',
                        style: TextStyle(
                            color: AppTheme.getTextSecondary(context))),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context, true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isCritical
                          ? const Color(0xFFEF4444)
                          : Theme.of(context).colorScheme.primary,
                      foregroundColor: Colors.white,
                    ),
                    child:
                    Text(isCritical ? 'Supprimer' : 'Confirmer'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ==================== HELPERS FORMULAIRE ====================

  InputDecoration _dropdownDecoration(
      String label, IconData icon, bool isDark) {
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(color: AppTheme.getTextSecondary(context)),
      prefixIcon:
      Icon(icon, color: AppTheme.getTextSecondary(context)),
      border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide:
          BorderSide(color: AppTheme.getBorderColor(context))),
      enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide:
          BorderSide(color: AppTheme.getBorderColor(context))),
      focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(
              color: Theme.of(context).colorScheme.primary, width: 2)),
      filled: true,
      fillColor: isDark
          ? Colors.grey.shade900.withOpacity(0.3)
          : Colors.grey.shade50,
    );
  }

  Widget _buildFormField({
    required TextEditingController controller,
    required String label,
    String? hint,
    required IconData icon,
    required bool isDark,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        labelStyle:
        TextStyle(color: AppTheme.getTextSecondary(context)),
        hintText: hint,
        hintStyle: TextStyle(color: AppTheme.getTextTertiary(context)),
        prefixIcon:
        Icon(icon, color: AppTheme.getTextSecondary(context)),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide:
            BorderSide(color: AppTheme.getBorderColor(context))),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide:
            BorderSide(color: AppTheme.getBorderColor(context))),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(
                color: Theme.of(context).colorScheme.primary, width: 2)),
        filled: true,
        fillColor: isDark
            ? Colors.grey.shade900.withOpacity(0.3)
            : Colors.grey.shade50,
      ),
      style: TextStyle(color: AppTheme.getTextPrimary(context)),
      validator: validator,
    );
  }

  Widget _buildPasswordField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required bool isVisible,
    required bool isDark,
    required VoidCallback onToggle,
    IconData icon = Icons.lock,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: !isVisible,
      decoration: InputDecoration(
        labelText: label,
        labelStyle:
        TextStyle(color: AppTheme.getTextSecondary(context)),
        hintText: hint,
        hintStyle: TextStyle(color: AppTheme.getTextTertiary(context)),
        prefixIcon:
        Icon(icon, color: AppTheme.getTextSecondary(context)),
        suffixIcon: IconButton(
          icon: Icon(
              isVisible ? Icons.visibility : Icons.visibility_off,
              color: AppTheme.getTextSecondary(context)),
          onPressed: onToggle,
        ),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide:
            BorderSide(color: AppTheme.getBorderColor(context))),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide:
            BorderSide(color: AppTheme.getBorderColor(context))),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(
                color: Theme.of(context).colorScheme.primary, width: 2)),
        filled: true,
        fillColor: isDark
            ? Colors.grey.shade900.withOpacity(0.3)
            : Colors.grey.shade50,
      ),
      style: TextStyle(color: AppTheme.getTextPrimary(context)),
      validator: validator,
    );
  }

  // ==================== UTILITAIRES ====================

  String _getRoleLabel(String role) {
    const map = {
      'ETUDIANT': 'Étudiant',
      'GESTIONNAIRE': 'Gestionnaire',
      'ADMIN': 'Administrateur',
      'TOUS': 'Tous',
    };
    return map[role] ?? role;
  }

  Color _getRoleColor(String role) {
    const map = {
      'ETUDIANT': Color(0xFF3B82F6),
      'GESTIONNAIRE': Color(0xFF10B981),
      'ADMIN': Color(0xFF8B5CF6),
    };
    return map[role] ?? const Color(0xFF64748B);
  }

  String _getStatutLabel(String statut) {
    const map = {
      'ACTIF': 'Actif',
      'INACTIF': 'Inactif',
      'SUSPENDU': 'Suspendu',
      'TOUS': 'Tous',
    };
    return map[statut] ?? statut;
  }

  Color _getStatutColor(String statut) {
    const map = {
      'ACTIF': Color(0xFF10B981),
      'INACTIF': Color(0xFFF59E0B),
      'SUSPENDU': Color(0xFFEF4444),
    };
    return map[statut] ?? const Color(0xFF64748B);
  }

  Future<void> _applySearch(String query) async {
    await Provider.of<UserAdminProvider>(context, listen: false)
        .applyFilter('search', query);
  }

  Future<void> _applyFilter(String key, dynamic value) async {
    await Provider.of<UserAdminProvider>(context, listen: false)
        .applyFilter(key, value);
  }

  Future<void> _resetFilters() async {
    setState(() {
      _searchController.clear();
      _selectedRole = 'TOUS';
      _selectedStatut = 'TOUS';
    });
    await Provider.of<UserAdminProvider>(context, listen: false)
        .resetFilters();
  }

  Future<void> _refreshData() async {
    await Provider.of<UserAdminProvider>(context, listen: false)
        .loadUsers();
  }
}