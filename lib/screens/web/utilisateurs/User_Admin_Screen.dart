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
///
/// Permet de consulter, filtrer, créer, modifier et gérer les utilisateurs.
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
    // Charge les données après le premier affichage
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadInitialData();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  /// Charge les utilisateurs via le provider.
  Future<void> _loadInitialData() async {
    final provider = Provider.of<UserAdminProvider>(context, listen: false);
    await provider.loadUsers();
  }

  /// Formate une date sans heure.
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

  /// Construit le contenu principal.
  Widget _buildMainContent(bool isDark) {
    return Consumer<UserAdminProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading && provider.users.isEmpty) {
          return Center(
            child: CircularProgressIndicator(color: Theme.of(context).colorScheme.primary),
          );
        }

        if (provider.error != null && provider.users.isEmpty) {
          return _buildErrorWidget(provider.error!, isDark);
        }

        if (provider.users.isEmpty) {
          return _buildEmptyState(isDark);
        }

        return CustomScrollView(
          slivers: [
            SliverToBoxAdapter(child: _buildQuickStats(provider, isDark)),
            SliverToBoxAdapter(
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                height: _showFilters ? null : 0,
                child: _showFilters ? _buildFiltersCard(isDark) : const SizedBox.shrink(),
              ),
            ),
            SliverToBoxAdapter(child: _buildUsersTableHeader(isDark)),
            _buildUsersList(provider, isDark),
          ],
        );
      },
    );
  }

  /// En‑tête du tableau des utilisateurs.
  Widget _buildUsersTableHeader(bool isDark) {
    return Container(
      margin: const EdgeInsets.fromLTRB(32, 0, 32, 0),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey.shade900.withOpacity(0.5) : const Color(0xFFF8FAFC),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(12),
          topRight: Radius.circular(12),
        ),
        border: Border(bottom: BorderSide(color: AppTheme.getBorderColor(context), width: 1)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(isDark ? 0.1 : 0.05), blurRadius: 10)],
      ),
      child: Row(
        children: [
          Expanded(flex: 2, child: _HeaderText('Utilisateur', isDark)),
          Expanded(child: _HeaderText('Matricule', isDark)),
          Expanded(child: _HeaderText('Rôle', isDark)),
          Expanded(child: _HeaderText('Statut', isDark)),
          Expanded(child: _HeaderText('Date création', isDark)),
          const SizedBox(width: 100),
        ],
      ),
    );
  }

  /// Liste des utilisateurs.
  Widget _buildUsersList(UserAdminProvider provider, bool isDark) {
    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(32, 0, 32, 24),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
              (context, index) => _buildUserRow(provider.users[index], provider, index, isDark),
          childCount: provider.users.length,
        ),
      ),
    );
  }

  /// Barre flottante des filtres principaux.
  Widget _buildFloatingFiltersBar(bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
      decoration: BoxDecoration(
        color: AppTheme.getTopBarBackground(context),
        border: Border(bottom: BorderSide(color: AppTheme.getBorderColor(context), width: 1)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4, offset: const Offset(0, 2))],
      ),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Rechercher nom, matricule, email...',
                hintStyle: TextStyle(color: AppTheme.getTextSecondary(context)),
                prefixIcon: Icon(Icons.search, size: 20, color: AppTheme.getTextSecondary(context)),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                  icon: Icon(Icons.clear, size: 20, color: AppTheme.getTextSecondary(context)),
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
                  borderSide: BorderSide(color: Theme.of(context).colorScheme.primary, width: 2),
                ),
                filled: true,
                fillColor: isDark ? Colors.grey.shade900.withOpacity(0.3) : Colors.grey.shade50,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                isDense: true,
              ),
              onSubmitted: _applySearch,
              style: TextStyle(color: AppTheme.getTextPrimary(context)),
            ),
          ),
          const SizedBox(width: 12),
          _buildFilterDropdown(
            value: _selectedRole,
            label: 'Rôle',
            items: ['TOUS', 'ETUDIANT', 'GESTIONNAIRE', 'ADMIN'],
            onChanged: (value) {
              setState(() => _selectedRole = value!);
              _applyFilter('role', value == 'TOUS' ? null : value);
            },
            isDark: isDark,
          ),
          const SizedBox(width: 12),
          _buildFilterDropdown(
            value: _selectedStatut,
            label: 'Statut',
            items: ['TOUS', 'ACTIF', 'INACTIF', 'SUSPENDU'],
            onChanged: (value) {
              setState(() => _selectedStatut = value!);
              _applyFilter('statut', value == 'TOUS' ? null : value);
            },
            isDark: isDark,
          ),
          const SizedBox(width: 12),
          OutlinedButton.icon(
            onPressed: () => setState(() => _showFilters = !_showFilters),
            icon: Icon(
              _showFilters ? Icons.filter_list_off : Icons.filter_list,
              size: 18,
              color: Theme.of(context).colorScheme.primary,
            ),
            label: Text(
              _showFilters ? 'Masquer' : 'Plus',
              style: TextStyle(color: Theme.of(context).colorScheme.primary),
            ),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              side: BorderSide(color: Theme.of(context).colorScheme.primary.withOpacity(0.5)),
            ),
          ),
          const SizedBox(width: 12),
          IconButton(
            onPressed: _resetFilters,
            icon: Icon(Icons.refresh, size: 20, color: AppTheme.getTextSecondary(context)),
            tooltip: 'Réinitialiser les filtres',
          ),
          const SizedBox(width: 12),
          OutlinedButton.icon(
            onPressed: () {
              Navigator.pushNamed(context, '/admin/annonces');
            },
            icon: Icon(Icons.campaign, size: 18, color: Theme.of(context).colorScheme.primary),
            label: Text(
              'Annonces',
              style: TextStyle(color: Theme.of(context).colorScheme.primary),
            ),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              side: BorderSide(color: Theme.of(context).colorScheme.primary.withOpacity(0.5)),
            ),
          ),
          const SizedBox(width: 12),
          ElevatedButton.icon(
            onPressed: () => _showCreateUserDialog(),
            icon: Icon(Icons.add, size: 18, color: Colors.white),
            label: const Text('Nouvel utilisateur', style: TextStyle(color: Colors.white)),
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.primary,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
          const SizedBox(width: 12),
          ElevatedButton.icon(
            onPressed: _refreshData,
            icon: Icon(Icons.refresh, size: 18, color: Colors.white),
            label: const Text('Actualiser', style: TextStyle(color: Colors.white)),
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.primary,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
        ],
      ),
    );
  }

  /// Construit un filtre déroulant.
  Widget _buildFilterDropdown({
    required String value,
    required String label,
    required List<String> items,
    required ValueChanged<String?> onChanged,
    required bool isDark,
  }) {
    return SizedBox(
      width: 180,
      child: DropdownButtonFormField<String>(
        value: value,
        decoration: InputDecoration(
          labelText: label,
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
          fillColor: isDark ? Colors.grey.shade900.withOpacity(0.3) : Colors.grey.shade50,
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          isDense: true,
        ),
        dropdownColor: AppTheme.getCardBackground(context),
        items: items.map((item) => DropdownMenuItem(
          value: item,
          child: Text(
            _getRoleLabel(item),
            style: TextStyle(fontSize: 14, color: AppTheme.getTextPrimary(context)),
          ),
        )).toList(),
        onChanged: onChanged,
        style: TextStyle(color: AppTheme.getTextPrimary(context)),
      ),
    );
  }

  /// Section des indicateurs rapides.
  Widget _buildQuickStats(UserAdminProvider provider, bool isDark) {
    final bool isWide = MediaQuery.of(context).size.width > 1000;
    final stats = _calculateStats(provider);

    return Container(
      padding: const EdgeInsets.all(24),
      color: isDark ? Colors.grey.shade900.withOpacity(0.5) : const Color(0xFFF1F5F9),
      child: isWide ? _buildWideStats(stats, isDark) : _buildNarrowStats(stats, isDark),
    );
  }

  /// Calcule les statistiques à partir des utilisateurs.
  Map<String, int> _calculateStats(UserAdminProvider provider) {
    return {
      'total': provider.users.length,
      'actifs': provider.users.where((u) => u.isActive).length,
      'etudiants': provider.users.where((u) => u.isStudent).length,
      'gestionnaires': provider.users.where((u) => u.isGestionnaire).length,
      'admins': provider.users.where((u) => u.isAdmin).length,
    };
  }

  /// Affichage des statistiques en mode large.
  Widget _buildWideStats(Map<String, int> stats, bool isDark) {
    return Row(
      children: [
        _buildStatCard(
          label: 'Total',
          value: '${stats['total']}',
          color: Color(0xFF3B82F6),
          icon: Icons.people,
          isDark: isDark,
        ),
        SizedBox(width: 16),
        _buildStatCard(
          label: 'Actifs',
          value: '${stats['actifs']}',
          color: Color(0xFF10B981),
          icon: Icons.check_circle,
          isDark: isDark,
        ),
        SizedBox(width: 16),
        _buildStatCard(
          label: 'Étudiants',
          value: '${stats['etudiants']}',
          color: Color(0xFF8B5CF6),
          icon: Icons.school,
          isDark: isDark,
        ),
        SizedBox(width: 16),
        _buildStatCard(
          label: 'Gestionnaires',
          value: '${stats['gestionnaires']}',
          color: Color(0xFFF59E0B),
          icon: Icons.manage_accounts,
          isDark: isDark,
        ),
        SizedBox(width: 16),
        _buildStatCard(
          label: 'Admins',
          value: '${stats['admins']}',
          color: Color(0xFFEC4899),
          icon: Icons.admin_panel_settings,
          isDark: isDark,
        ),
      ],
    );
  }

  /// Affichage des statistiques en mode étroit.
  Widget _buildNarrowStats(Map<String, int> stats, bool isDark) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                label: 'Total',
                value: '${stats['total']}',
                color: Color(0xFF3B82F6),
                icon: Icons.people,
                isDark: isDark,
              ),
            ),
            SizedBox(width: 16),
            Expanded(
              child: _buildStatCard(
                label: 'Actifs',
                value: '${stats['actifs']}',
                color: Color(0xFF10B981),
                icon: Icons.check_circle,
                isDark: isDark,
              ),
            ),
          ],
        ),
        SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                label: 'Étudiants',
                value: '${stats['etudiants']}',
                color: Color(0xFF8B5CF6),
                icon: Icons.school,
                isDark: isDark,
              ),
            ),
            SizedBox(width: 16),
            Expanded(
              child: _buildStatCard(
                label: 'Gestionnaires',
                value: '${stats['gestionnaires']}',
                color: Color(0xFFF59E0B),
                icon: Icons.manage_accounts,
                isDark: isDark,
              ),
            ),
          ],
        ),
        SizedBox(height: 16),
        Container(
          width: 200,
          child: _buildStatCard(
            label: 'Admins',
            value: '${stats['admins']}',
            color: Color(0xFFEC4899),
            icon: Icons.admin_panel_settings,
            isDark: isDark,
          ),
        ),
      ],
    );
  }

  /// Carte d’un indicateur statistique.
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
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(isDark ? 0.1 : 0.05), blurRadius: 10)],
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
                  Text(
                      value,
                      style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: color)
                  ),
                  const SizedBox(height: 4),
                  Text(
                      label,
                      style: TextStyle(fontSize: 13, color: AppTheme.getTextSecondary(context))
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Carte des filtres avancés.
  Widget _buildFiltersCard(bool isDark) {
    return Container(
      margin: const EdgeInsets.fromLTRB(32, 0, 32, 24),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.getCardBackground(context),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(isDark ? 0.1 : 0.05), blurRadius: 10)],
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
                    color: AppTheme.getTextPrimary(context)
                ),
              ),
              const Spacer(),
              TextButton.icon(
                onPressed: () => setState(() => _showFilters = false),
                icon: Icon(Icons.close, size: 16, color: AppTheme.getTextSecondary(context)),
                label: Text(
                  'Fermer',
                  style: TextStyle(color: AppTheme.getTextSecondary(context)),
                ),
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

  /// Ligne d’un utilisateur dans la liste.
  Widget _buildUserRow(AdminUser user, UserAdminProvider provider, int index, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: index.isEven
            ? AppTheme.getCardBackground(context)
            : (isDark ? Colors.grey.shade900.withOpacity(0.3) : const Color(0xFFFAFAFA)),
        border: Border(bottom: BorderSide(color: AppTheme.getBorderColor(context), width: 1)),
      ),
      child: Row(
        children: [
          Expanded(flex: 2, child: _buildUserInfo(user)),
          Expanded(
              child: Text(
                  user.matricule,
                  style: TextStyle(color: AppTheme.getTextSecondary(context), fontSize: 13)
              )
          ),
          Expanded(child: _buildRoleBadge(user.role, isDark)),
          Expanded(child: _buildStatutBadge(user.statut, isDark)),
          Expanded(
            child: Text(
              _formatDate(user.createdAt),
              style: TextStyle(color: AppTheme.getTextSecondary(context), fontSize: 13),
            ),
          ),
          SizedBox(
            width: 120,
            child: _buildActions(user, provider, isDark),
          ),
        ],
      ),
    );
  }

  /// Affiche les informations de base de l'utilisateur.
  Widget _buildUserInfo(AdminUser user) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${user.prenom} ${user.nom}',
          style: TextStyle(
              fontWeight: FontWeight.w600,
              color: AppTheme.getTextPrimary(context),
              fontSize: 14
          ),
        ),
        const SizedBox(height: 4),
        Text(
            user.email,
            style: TextStyle(fontSize: 12, color: AppTheme.getTextSecondary(context))
        ),
        const SizedBox(height: 4),
        Text(
            user.telephone,
            style: TextStyle(fontSize: 11, color: AppTheme.getTextTertiary(context))
        ),
        if (user.centreNom != null) ...[
          const SizedBox(height: 2),
          Text(
            user.centreNom!,
            style: TextStyle(fontSize: 11, color: AppTheme.getTextTertiary(context)),
          ),
        ],
      ],
    );
  }

  /// Badge du rôle.
  Widget _buildRoleBadge(String role, bool isDark) {
    return Center(
      child: Container(
        constraints: const BoxConstraints(
          minWidth: 90,
          minHeight: 28,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: _getRoleColor(role).withOpacity(isDark ? 0.2 : 0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: _getRoleColor(role).withOpacity(isDark ? 0.3 : 0.2),
            width: 1,
          ),
        ),
        child: Center(
          child: Text(
            _getRoleLabel(role),
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: _getRoleColor(role),
              letterSpacing: 0.3,
            ),
          ),
        ),
      ),
    );
  }

  /// Badge du statut.
  Widget _buildStatutBadge(String statut, bool isDark) {
    return Center(
      child: Container(
        constraints: const BoxConstraints(
          minWidth: 80,
          minHeight: 28,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: _getStatutColor(statut).withOpacity(isDark ? 0.2 : 0.1),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: _getStatutColor(statut).withOpacity(isDark ? 0.5 : 0.4),
            width: 1.5,
          ),
        ),
        child: Center(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  color: _getStatutColor(statut),
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                _getStatutLabel(statut),
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: _getStatutColor(statut),
                  letterSpacing: 0.3,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Boutons d'action pour un utilisateur.
  Widget _buildActions(AdminUser user, UserAdminProvider provider, bool isDark) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Voir détails
        IconButton(
          onPressed: () => _showUserDetails(user, provider),
          icon: Icon(Icons.visibility_outlined, size: 18, color: AppTheme.getTextSecondary(context)),
          tooltip: 'Voir détails',
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
          splashRadius: 20,
        ),

        // Modifier
        IconButton(
          onPressed: () => _showEditUserDialog(user, provider),
          icon: Icon(Icons.edit_outlined, size: 18, color: const Color(0xFF3B82F6)),
          tooltip: 'Modifier',
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
          splashRadius: 20,
        ),

        // Menu
        PopupMenuButton<String>(
          icon: Icon(Icons.more_vert, size: 18, color: AppTheme.getTextSecondary(context)),
          color: AppTheme.getCardBackground(context),
          surfaceTintColor: AppTheme.getCardBackground(context),
          itemBuilder: (context) => _buildActionMenu(user, isDark),
          onSelected: (value) => _handleAction(value, user, provider),
          padding: EdgeInsets.zero,
          splashRadius: 20,
        ),
      ],
    );
  }

  /// Affiche un message lorsque la liste est vide.
  Widget _buildEmptyState(bool isDark) {
    return Container(
      margin: const EdgeInsets.all(32),
      padding: const EdgeInsets.all(48),
      decoration: BoxDecoration(
        color: AppTheme.getCardBackground(context),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(isDark ? 0.1 : 0.05), blurRadius: 10)],
      ),
      child: Center(
        child: Column(
          children: [
            Icon(
                Icons.people_outline,
                size: 80,
                color: AppTheme.getTextTertiary(context)
            ),
            const SizedBox(height: 24),
            Text(
              'Aucun utilisateur trouvé',
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.getTextSecondary(context)
              ),
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
              icon: Icon(Icons.add, color: Colors.white),
              label: const Text('Créer un nouvel utilisateur', style: TextStyle(color: Colors.white)),
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

  /// Affiche un message d'erreur.
  Widget _buildErrorWidget(String error, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(24),
      margin: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: isDark ? Colors.red.shade900.withOpacity(0.1) : const Color(0xFFFEF2F2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: isDark ? Colors.red.shade800 : const Color(0xFFFECACA)
        ),
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 48, color: Colors.red.shade400),
            const SizedBox(height: 16),
            Text(
              'Erreur de chargement',
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.red.shade400
              ),
            ),
            const SizedBox(height: 8),
            Text(
                error,
                textAlign: TextAlign.center,
                style: TextStyle(
                    color: isDark ? Colors.red.shade300 : const Color(0xFF991B1B)
                )
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _refreshData,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.shade400,
                foregroundColor: Colors.white,
              ),
              child: const Text('Réessayer'),
            ),
          ],
        ),
      ),
    );
  }

  /// Menu contextuel d’un utilisateur.
  List<PopupMenuEntry<String>> _buildActionMenu(AdminUser user, bool isDark) {
    return [
      PopupMenuItem(
        value: 'details',
        child: Row(
          children: [
            Icon(Icons.info_outline, size: 18, color: AppTheme.getTextSecondary(context)),
            const SizedBox(width: 8),
            Text(
              'Détails complets',
              style: TextStyle(color: AppTheme.getTextPrimary(context)),
            ),
          ],
        ),
      ),
      if (user.role == 'ETUDIANT')
        PopupMenuItem(
          value: 'send_annonce',
          child: Row(
            children: [
              Icon(Icons.send, size: 18, color: const Color(0xFF3B82F6)),
              const SizedBox(width: 8),
              Text(
                'Envoyer une annonce',
                style: TextStyle(color: AppTheme.getTextPrimary(context)),
              ),
            ],
          ),
        ),
      PopupMenuItem(
        value: 'edit',
        child: Row(
          children: [
            Icon(Icons.edit, size: 18, color: const Color(0xFF3B82F6)),
            const SizedBox(width: 8),
            Text(
              'Modifier',
              style: TextStyle(color: AppTheme.getTextPrimary(context)),
            ),
          ],
        ),
      ),
      if (user.isActive) ...[
        PopupMenuItem(
          value: 'desactiver',
          child: Row(
            children: [
              Icon(Icons.pause_circle, size: 18, color: const Color(0xFFF59E0B)),
              const SizedBox(width: 8),
              Text(
                'Désactiver',
                style: TextStyle(color: AppTheme.getTextPrimary(context)),
              ),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'suspendre',
          child: Row(
            children: [
              Icon(Icons.block, size: 18, color: const Color(0xFFEF4444)),
              const SizedBox(width: 8),
              Text(
                'Suspendre',
                style: TextStyle(color: AppTheme.getTextPrimary(context)),
              ),
            ],
          ),
        ),
      ] else if (user.statut == 'INACTIF' || user.statut == 'SUSPENDU') ...[
        PopupMenuItem(
          value: 'reactiver',
          child: Row(
            children: [
              Icon(Icons.play_arrow, size: 18, color: const Color(0xFF10B981)),
              const SizedBox(width: 8),
              Text(
                'Réactiver',
                style: TextStyle(color: AppTheme.getTextPrimary(context)),
              ),
            ],
          ),
        ),
      ],
      const PopupMenuDivider(),
      PopupMenuItem(
        value: 'supprimer',
        child: Row(
          children: [
            const Icon(Icons.delete, size: 18, color: Color(0xFFEF4444)),
            const SizedBox(width: 8),
            Text(
              'Supprimer',
              style: TextStyle(color: Colors.red.shade700),
            ),
          ],
        ),
      ),
    ];
  }

  /// Exécute l’action sélectionnée dans le menu contextuel.
  Future<void> _handleAction(String action, AdminUser user, UserAdminProvider provider) async {
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

  /// Affiche le dialogue d'envoi d'une annonce à un étudiant.
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
            borderRadius: BorderRadius.circular(16),
          ),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: 550,
              maxHeight: MediaQuery.of(context).size.height * 0.8,
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
                          color: const Color(0xFF3B82F6).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          Icons.send,
                          color: const Color(0xFF3B82F6),
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Envoyer une annonce',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.getTextPrimary(context),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'À: ${user.prenom} ${user.nom}',
                              style: TextStyle(
                                fontSize: 14,
                                color: AppTheme.getTextSecondary(context),
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: isSending ? null : () => Navigator.pop(context),
                        icon: Icon(
                          Icons.close,
                          color: AppTheme.getTextSecondary(context),
                        ),
                        tooltip: 'Fermer',
                      ),
                    ],
                  ),
                ),

                // Formulaire
                Flexible(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        TextField(
                          controller: titreController,
                          decoration: InputDecoration(
                            labelText: 'Titre *',
                            labelStyle: TextStyle(color: AppTheme.getTextSecondary(context)),
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
                                color: Theme.of(context).colorScheme.primary,
                                width: 2,
                              ),
                            ),
                            hintText: 'Ex: Information importante',
                            hintStyle: TextStyle(color: AppTheme.getTextTertiary(context)),
                            filled: true,
                            fillColor: isDark
                                ? Colors.grey.shade900.withOpacity(0.3)
                                : Colors.grey.shade50,
                          ),
                          maxLength: 100,
                          style: TextStyle(color: AppTheme.getTextPrimary(context)),
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: contenuController,
                          decoration: InputDecoration(
                            labelText: 'Message *',
                            labelStyle: TextStyle(color: AppTheme.getTextSecondary(context)),
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
                                color: Theme.of(context).colorScheme.primary,
                                width: 2,
                              ),
                            ),
                            hintText: 'Votre message...',
                            hintStyle: TextStyle(color: AppTheme.getTextTertiary(context)),
                            alignLabelWithHint: true,
                            filled: true,
                            fillColor: isDark
                                ? Colors.grey.shade900.withOpacity(0.3)
                                : Colors.grey.shade50,
                          ),
                          maxLines: 6,
                          maxLength: 500,
                          style: TextStyle(color: AppTheme.getTextPrimary(context)),
                        ),
                      ],
                    ),
                  ),
                ),

                // Footer
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
                        onPressed: isSending ? null : () => Navigator.pop(context),
                        child: Text(
                          'Annuler',
                          style: TextStyle(color: AppTheme.getTextSecondary(context)),
                        ),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton.icon(
                        onPressed: isSending
                            ? null
                            : () async {
                          if (titreController.text.trim().isEmpty ||
                              contenuController.text.trim().isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Veuillez remplir tous les champs'),
                                backgroundColor: Colors.orange,
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                            return;
                          }

                          setState(() => isSending = true);

                          try {
                            final apiService = ApiService();
                            await apiService.post('/api/annonces/send', body: {
                              'titre': titreController.text.trim(),
                              'contenu': contenuController.text.trim(),
                              'cible': 'ETUDIANTS',
                              'user_ids': [user.id],
                              'statut': 'PUBLIE',
                            });

                            Navigator.pop(context);

                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Annonce envoyée à ${user.prenom} ${user.nom}',
                                ),
                                backgroundColor: const Color(0xFF10B981),
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          } catch (e) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Erreur: $e'),
                                backgroundColor: const Color(0xFFEF4444),
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
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
                            color: Colors.white,
                          ),
                        )
                            : const Icon(Icons.send, size: 18, color: Colors.white),
                        label: Text(
                          isSending ? 'Envoi...' : 'Envoyer',
                          style: const TextStyle(color: Colors.white),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Theme.of(context).colorScheme.primary,
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
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
  }

  /// Met à jour le statut d’un utilisateur.
  Future<void> _updateUserStatus(AdminUser user, String nouveauStatut, UserAdminProvider provider) async {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    try {
      final confirm = await _showConfirmationDialog(
        title: 'Confirmer la modification',
        message: 'Voulez-vous vraiment ${_getStatutLabel(nouveauStatut).toLowerCase()} cet utilisateur ?',
        isDark: isDark,
      );

      if (confirm == true) {
        await provider.updateUserStatus(user.id, nouveauStatut);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Utilisateur ${_getStatutLabel(nouveauStatut).toLowerCase()} avec succès'),
            backgroundColor: _getStatutColor(nouveauStatut),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur: $e'),
          backgroundColor: const Color(0xFFEF4444),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  /// Supprime un utilisateur.
  Future<void> _deleteUser(AdminUser user, UserAdminProvider provider) async {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    try {
      final confirm = await _showConfirmationDialog(
        title: 'Confirmer la suppression',
        message: 'Voulez-vous vraiment supprimer définitivement cet utilisateur ?\nCette action est irréversible.',
        isCritical: true,
        isDark: isDark,
      );

      if (confirm == true) {
        await provider.deleteUser(user.id);

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Utilisateur supprimé avec succès'),
            backgroundColor: Color(0xFF10B981),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur: $e'),
          backgroundColor: const Color(0xFFEF4444),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  /// Affiche une boîte de dialogue détaillée de l'utilisateur.
  void _showUserDetails(AdminUser user, UserAdminProvider provider) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: AppTheme.getCardBackground(context),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
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
                        color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        Icons.person,
                        color: Theme.of(context).colorScheme.primary,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Détails de l\'utilisateur',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.getTextPrimary(context),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            user.matricule,
                            style: TextStyle(
                              fontSize: 13,
                              color: AppTheme.getTextSecondary(context),
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: Icon(
                        Icons.close,
                        color: AppTheme.getTextSecondary(context),
                      ),
                      tooltip: 'Fermer',
                    ),
                  ],
                ),
              ),

              // Contenu scrollable
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Informations personnelles
                      _buildSectionHeader('Informations personnelles', Icons.person),
                      const SizedBox(height: 12),
                      _buildInfoGrid([
                        ('Nom complet', '${user.prenom} ${user.nom}'),
                        ('Matricule', user.matricule),
                        ('Email', user.email),
                        ('Téléphone', user.telephone),
                      ]),

                      const SizedBox(height: 24),

                      // Statut et rôle
                      _buildSectionHeader('Compte', Icons.admin_panel_settings),
                      const SizedBox(height: 12),
                      _buildInfoGrid([
                        ('Rôle', _getRoleLabel(user.role)),
                        ('Statut', _getStatutLabel(user.statut)),
                        ('Date création', _formatDate(user.createdAt)),
                        if (user.updatedAt != null)
                          ('Dernière modification', _formatDate(user.updatedAt!)),
                      ]),

                      // Logement (si applicable)
                      if (user.centreNom != null || user.numeroChambre != null) ...[
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

              // Footer avec actions
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
                      onPressed: () => Navigator.pop(context),
                      child: Text(
                        'Fermer',
                        style: TextStyle(color: AppTheme.getTextSecondary(context)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        _showEditUserDialog(user, provider);
                      },
                      icon: Icon(Icons.edit, size: 18, color: Colors.white),
                      label: Text('Modifier', style: TextStyle(color: Colors.white)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
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

  // Méthodes utilitaires pour les détails

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 18, color: Theme.of(context).colorScheme.primary),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: AppTheme.getTextPrimary(context),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoGrid(List<(String, String)> items) {
    return Wrap(
      spacing: 16,
      runSpacing: 12,
      children: items.map((item) {
        return SizedBox(
          width: 250,
          child: _buildDetailItem(item.$1, item.$2),
        );
      }).toList(),
    );
  }

  Widget _buildDetailItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
                fontSize: 12,
                color: AppTheme.getTextSecondary(context),
                fontWeight: FontWeight.w500
            ),
          ),
          const SizedBox(height: 4),
          Text(
              value,
              style: TextStyle(fontSize: 16, color: AppTheme.getTextPrimary(context))
          ),
        ],
      ),
    );
  }

  /// Affiche le dialogue de création d'un nouvel utilisateur.
  Future<void> _showCreateUserDialog() async {
    final provider = Provider.of<UserAdminProvider>(context, listen: false);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Charger les centres si pas encore fait
    if (provider.centres.isEmpty) {
      await provider.loadCentres();
    }

    // Contrôleurs
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
            borderRadius: BorderRadius.circular(16),
          ),
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
                    // Header
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            Icons.person_add,
                            color: Theme.of(context).colorScheme.primary,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Nouvel étudiant',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.getTextPrimary(context),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Remplissez les informations de l\'étudiant',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: AppTheme.getTextSecondary(context),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Matricule
                    TextFormField(
                      controller: matriculeController,
                      decoration: InputDecoration(
                        labelText: 'Matricule *',
                        labelStyle: TextStyle(color: AppTheme.getTextSecondary(context)),
                        hintText: 'Ex: ETUD2024001',
                        hintStyle: TextStyle(color: AppTheme.getTextTertiary(context)),
                        prefixIcon: Icon(Icons.badge, color: AppTheme.getTextSecondary(context)),
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
                          borderSide: BorderSide(color: Theme.of(context).colorScheme.primary, width: 2),
                        ),
                        filled: true,
                        fillColor: isDark ? Colors.grey.shade900.withOpacity(0.3) : Colors.grey.shade50,
                      ),
                      style: TextStyle(color: AppTheme.getTextPrimary(context)),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Le matricule est requis';
                        }
                        if (value.trim().length < 5) {
                          return 'Le matricule doit contenir au moins 5 caractères';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Nom et Prénom
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: nomController,
                            decoration: InputDecoration(
                              labelText: 'Nom *',
                              labelStyle: TextStyle(color: AppTheme.getTextSecondary(context)),
                              hintText: 'Nom de famille',
                              hintStyle: TextStyle(color: AppTheme.getTextTertiary(context)),
                              prefixIcon: Icon(Icons.person, color: AppTheme.getTextSecondary(context)),
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
                                borderSide: BorderSide(color: Theme.of(context).colorScheme.primary, width: 2),
                              ),
                              filled: true,
                              fillColor: isDark ? Colors.grey.shade900.withOpacity(0.3) : Colors.grey.shade50,
                            ),
                            style: TextStyle(color: AppTheme.getTextPrimary(context)),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Le nom est requis';
                              }
                              if (value.trim().length < 2) {
                                return 'Au moins 2 caractères';
                              }
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextFormField(
                            controller: prenomController,
                            decoration: InputDecoration(
                              labelText: 'Prénom *',
                              labelStyle: TextStyle(color: AppTheme.getTextSecondary(context)),
                              hintText: 'Prénom',
                              hintStyle: TextStyle(color: AppTheme.getTextTertiary(context)),
                              prefixIcon: Icon(Icons.person_outline, color: AppTheme.getTextSecondary(context)),
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
                                borderSide: BorderSide(color: Theme.of(context).colorScheme.primary, width: 2),
                              ),
                              filled: true,
                              fillColor: isDark ? Colors.grey.shade900.withOpacity(0.3) : Colors.grey.shade50,
                            ),
                            style: TextStyle(color: AppTheme.getTextPrimary(context)),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Le prénom est requis';
                              }
                              if (value.trim().length < 2) {
                                return 'Au moins 2 caractères';
                              }
                              return null;
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Email
                    TextFormField(
                      controller: emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: InputDecoration(
                        labelText: 'Email *',
                        labelStyle: TextStyle(color: AppTheme.getTextSecondary(context)),
                        hintText: 'exemple@cenou.bf',
                        hintStyle: TextStyle(color: AppTheme.getTextTertiary(context)),
                        prefixIcon: Icon(Icons.email, color: AppTheme.getTextSecondary(context)),
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
                          borderSide: BorderSide(color: Theme.of(context).colorScheme.primary, width: 2),
                        ),
                        filled: true,
                        fillColor: isDark ? Colors.grey.shade900.withOpacity(0.3) : Colors.grey.shade50,
                      ),
                      style: TextStyle(color: AppTheme.getTextPrimary(context)),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'L\'email est requis';
                        }
                        if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value.trim())) {
                          return 'Email invalide';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Téléphone
                    TextFormField(
                      controller: telephoneController,
                      keyboardType: TextInputType.phone,
                      decoration: InputDecoration(
                        labelText: 'Téléphone (optionnel)',
                        labelStyle: TextStyle(color: AppTheme.getTextSecondary(context)),
                        hintText: '+226 70 XX XX XX',
                        hintStyle: TextStyle(color: AppTheme.getTextTertiary(context)),
                        prefixIcon: Icon(Icons.phone, color: AppTheme.getTextSecondary(context)),
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
                          borderSide: BorderSide(color: Theme.of(context).colorScheme.primary, width: 2),
                        ),
                        filled: true,
                        fillColor: isDark ? Colors.grey.shade900.withOpacity(0.3) : Colors.grey.shade50,
                      ),
                      style: TextStyle(color: AppTheme.getTextPrimary(context)),
                      validator: (value) {
                        if (value != null && value.trim().isNotEmpty) {
                          if (!RegExp(r'^\+?[0-9]{8,15}$').hasMatch(value.trim().replaceAll(' ', ''))) {
                            return 'Numéro de téléphone invalide';
                          }
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Centre
                    DropdownButtonFormField<int>(
                      value: selectedCentreId,
                      decoration: InputDecoration(
                        labelText: 'Centre *',
                        labelStyle: TextStyle(color: AppTheme.getTextSecondary(context)),
                        hintText: 'Sélectionner un centre',
                        hintStyle: TextStyle(color: AppTheme.getTextTertiary(context)),
                        prefixIcon: Icon(Icons.location_city, color: AppTheme.getTextSecondary(context)),
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
                          borderSide: BorderSide(color: Theme.of(context).colorScheme.primary, width: 2),
                        ),
                        filled: true,
                        fillColor: isDark ? Colors.grey.shade900.withOpacity(0.3) : Colors.grey.shade50,
                      ),
                      dropdownColor: AppTheme.getCardBackground(context),
                      style: TextStyle(color: AppTheme.getTextPrimary(context)),
                      items: provider.centres.map((centre) {
                        return DropdownMenuItem<int>(
                          value: centre.id,
                          child: Text(centre.nom, style: TextStyle(color: AppTheme.getTextPrimary(context))),
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
                            availableLogements = provider.availableLogements;
                          });
                        }
                      },
                      validator: (value) {
                        if (value == null) {
                          return 'Sélectionnez un centre';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Logement (conditionnel)
                    if (selectedCentreId != null)
                      DropdownButtonFormField<int>(
                        value: selectedLogementId,
                        decoration: InputDecoration(
                          labelText: 'Logement (optionnel)',
                          labelStyle: TextStyle(color: AppTheme.getTextSecondary(context)),
                          hintText: 'Sélectionner un logement',
                          hintStyle: TextStyle(color: AppTheme.getTextTertiary(context)),
                          prefixIcon: Icon(Icons.home, color: AppTheme.getTextSecondary(context)),
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
                            borderSide: BorderSide(color: Theme.of(context).colorScheme.primary, width: 2),
                          ),
                          filled: true,
                          fillColor: isDark ? Colors.grey.shade900.withOpacity(0.3) : Colors.grey.shade50,
                        ),
                        dropdownColor: AppTheme.getCardBackground(context),
                        style: TextStyle(color: AppTheme.getTextPrimary(context)),
                        items: availableLogements.isEmpty
                            ? [
                          DropdownMenuItem<int>(
                            value: null,
                            child: Text(
                              'Aucun logement disponible',
                              style: TextStyle(color: AppTheme.getTextTertiary(context)),
                            ),
                          ),
                        ]
                            : availableLogements.map((logement) {
                          return DropdownMenuItem<int>(
                            value: logement['id'],
                            child: Text(
                              'Chambre ${logement['numero_chambre']} - ${logement['type_chambre']}',
                              style: TextStyle(color: AppTheme.getTextPrimary(context)),
                            ),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            selectedLogementId = value;
                          });
                        },
                      ),
                    if (selectedCentreId != null) const SizedBox(height: 16),

                    // Option génération mot de passe
                    CheckboxListTile(
                      value: generatePassword,
                      onChanged: (value) {
                        setState(() {
                          generatePassword = value ?? true;
                          if (generatePassword) {
                            passwordController.clear();
                            confirmPasswordController.clear();
                          }
                        });
                      },
                      title: Text(
                        'Générer un mot de passe automatiquement',
                        style: TextStyle(color: AppTheme.getTextPrimary(context), fontSize: 14),
                      ),
                      controlAffinity: ListTileControlAffinity.leading,
                      activeColor: Theme.of(context).colorScheme.primary,
                      contentPadding: EdgeInsets.zero,
                    ),
                    const SizedBox(height: 8),

                    // Mot de passe manuel (si pas auto-généré)
                    if (!generatePassword) ...[
                      TextFormField(
                        controller: passwordController,
                        obscureText: !isPasswordVisible,
                        decoration: InputDecoration(
                          labelText: 'Mot de passe *',
                          labelStyle: TextStyle(color: AppTheme.getTextSecondary(context)),
                          hintText: 'Minimum 6 caractères',
                          hintStyle: TextStyle(color: AppTheme.getTextTertiary(context)),
                          prefixIcon: Icon(Icons.lock, color: AppTheme.getTextSecondary(context)),
                          suffixIcon: IconButton(
                            icon: Icon(
                              isPasswordVisible ? Icons.visibility : Icons.visibility_off,
                              color: AppTheme.getTextSecondary(context),
                            ),
                            onPressed: () {
                              setState(() {
                                isPasswordVisible = !isPasswordVisible;
                              });
                            },
                          ),
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
                            borderSide: BorderSide(color: Theme.of(context).colorScheme.primary, width: 2),
                          ),
                          filled: true,
                          fillColor: isDark ? Colors.grey.shade900.withOpacity(0.3) : Colors.grey.shade50,
                        ),
                        style: TextStyle(color: AppTheme.getTextPrimary(context)),
                        validator: (value) {
                          if (!generatePassword) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Le mot de passe est requis';
                            }
                            if (value.length < 6) {
                              return 'Au moins 6 caractères';
                            }
                            if (!RegExp(r'[A-Z]').hasMatch(value)) {
                              return 'Au moins une majuscule';
                            }
                            if (!RegExp(r'[0-9]').hasMatch(value)) {
                              return 'Au moins un chiffre';
                            }
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: confirmPasswordController,
                        obscureText: !isConfirmPasswordVisible,
                        decoration: InputDecoration(
                          labelText: 'Confirmer le mot de passe *',
                          labelStyle: TextStyle(color: AppTheme.getTextSecondary(context)),
                          hintText: 'Retapez le mot de passe',
                          hintStyle: TextStyle(color: AppTheme.getTextTertiary(context)),
                          prefixIcon: Icon(Icons.lock_outline, color: AppTheme.getTextSecondary(context)),
                          suffixIcon: IconButton(
                            icon: Icon(
                              isConfirmPasswordVisible ? Icons.visibility : Icons.visibility_off,
                              color: AppTheme.getTextSecondary(context),
                            ),
                            onPressed: () {
                              setState(() {
                                isConfirmPasswordVisible = !isConfirmPasswordVisible;
                              });
                            },
                          ),
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
                            borderSide: BorderSide(color: Theme.of(context).colorScheme.primary, width: 2),
                          ),
                          filled: true,
                          fillColor: isDark ? Colors.grey.shade900.withOpacity(0.3) : Colors.grey.shade50,
                        ),
                        style: TextStyle(color: AppTheme.getTextPrimary(context)),
                        validator: (value) {
                          if (!generatePassword) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Confirmation requise';
                            }
                            if (value != passwordController.text) {
                              return 'Les mots de passe ne correspondent pas';
                            }
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                    ],

                    // Info si génération auto
                    if (generatePassword)
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.blue.withOpacity(isDark ? 0.2 : 0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.blue.withOpacity(0.3)),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.info_outline, color: Colors.blue, size: 20),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Un mot de passe sécurisé sera généré automatiquement et affiché après la création.',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.blue.shade700,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    const SizedBox(height: 24),

                    // Boutons
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: isSaving ? null : () => Navigator.pop(context),
                          child: Text(
                            'Annuler',
                            style: TextStyle(color: AppTheme.getTextSecondary(context)),
                          ),
                        ),
                        const SizedBox(width: 12),
                        ElevatedButton.icon(
                          onPressed: isSaving ? null : () async {
                            if (formKey.currentState!.validate()) {
                              final scaffoldMessenger = ScaffoldMessenger.of(context);
                              setState(() => isSaving = true);
                              try {
                                await provider.createUser(
                                  matricule: matriculeController.text.trim(),
                                  nom: nomController.text.trim(),
                                  prenom: prenomController.text.trim(),
                                  email: emailController.text.trim(),
                                  telephone: telephoneController.text.trim().isEmpty
                                      ? null
                                      : telephoneController.text.trim(),
                                  role: selectedRole,
                                  statut: selectedStatut,
                                  motDePasse: generatePassword
                                      ? null
                                      : passwordController.text.trim(),
                                  centreId: selectedCentreId,
                                  logementId: selectedLogementId,
                                  dateDebut: selectedLogementId != null
                                      ? DateTime.now().toIso8601String()
                                      : null,
                                );
                                Navigator.pop(context);
                                scaffoldMessenger.showSnackBar(
                                  SnackBar(
                                    content: Row(
                                      children: [
                                        Icon(Icons.check_circle, color: Colors.white),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Text(
                                            'Étudiant créé avec succès${generatePassword ? '. Un mot de passe temporaire a été généré.' : ''}',
                                          ),
                                        ),
                                      ],
                                    ),
                                    backgroundColor: const Color(0xFF10B981),
                                    behavior: SnackBarBehavior.floating,
                                  ),
                                );
                              } catch (e) {
                                setState(() => isSaving = false);
                                scaffoldMessenger.showSnackBar(
                                  SnackBar(
                                    content: Text('Erreur: $e'),
                                    backgroundColor: const Color(0xFFEF4444),
                                    behavior: SnackBarBehavior.floating,
                                  ),
                                );
                              }
                            }
                          },
                          icon: isSaving
                              ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                              : const Icon(Icons.save, color: Colors.white),
                          label: Text(
                            isSaving ? 'Création...' : 'Créer l\'étudiant',
                            style: const TextStyle(color: Colors.white),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Theme.of(context).colorScheme.primary,
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
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

    // Nettoyer les contrôleurs
    matriculeController.dispose();
    nomController.dispose();
    prenomController.dispose();
    emailController.dispose();
    telephoneController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
  }

  /// Affiche le dialogue de modification d'un utilisateur.
  Future<void> _showEditUserDialog(AdminUser user, UserAdminProvider provider) async {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Charger les centres si pas encore fait
    if (provider.centres.isEmpty) {
      await provider.loadCentres();
    }

    // Contrôleurs pré-remplis
    final matriculeController = TextEditingController(text: user.matricule);
    final nomController = TextEditingController(text: user.nom);
    final prenomController = TextEditingController(text: user.prenom);
    final emailController = TextEditingController(text: user.email);
    final telephoneController = TextEditingController(text: user.telephone);

    final formKey = GlobalKey<FormState>();

    String selectedRole = user.role;
    String selectedStatut = user.statut;

    // Trouver le centre correspondant au nom
    int? selectedCentreId;
    if (user.centreNom != null && user.centreNom!.isNotEmpty) {
      final matchingCentre = provider.centres.firstWhere(
            (c) => c.nom == user.centreNom,
        orElse: () => Centre(id: 0, nom: ''),
      );
      if (matchingCentre.id != 0) {
        selectedCentreId = matchingCentre.id;
      }
    }

    int? selectedLogementId;
    bool isSaving = false;
    List<Map<String, dynamic>> availableLogements = [];

    // Charger les logements disponibles si un centre est sélectionné
    if (selectedCentreId != null) {
      await provider.loadAvailableLogements(selectedCentreId);
      availableLogements = provider.availableLogements;

      // Trouver le logement actuel si existe (basé sur le numéro de chambre)
      if (user.numeroChambre != null && user.numeroChambre!.isNotEmpty) {
        final currentLogement = availableLogements.firstWhere(
              (l) => l['numero_chambre'] == user.numeroChambre,
          orElse: () => <String, dynamic>{},
        );
        if (currentLogement.isNotEmpty) {
          selectedLogementId = currentLogement['id'] as int?;
        }
      }
    }

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => Dialog(
          backgroundColor: AppTheme.getCardBackground(context),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
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
                    // Header
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFF3B82F6).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.edit,
                            color: Color(0xFF3B82F6),
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Modifier l\'utilisateur',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.getTextPrimary(context),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                user.fullName,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: AppTheme.getTextSecondary(context),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Matricule (non modifiable)
                    TextFormField(
                      controller: matriculeController,
                      enabled: false,
                      decoration: InputDecoration(
                        labelText: 'Matricule',
                        labelStyle: TextStyle(color: AppTheme.getTextSecondary(context)),
                        prefixIcon: Icon(Icons.badge, color: AppTheme.getTextSecondary(context)),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: AppTheme.getBorderColor(context)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: AppTheme.getBorderColor(context)),
                        ),
                        filled: true,
                        fillColor: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
                      ),
                      style: TextStyle(color: AppTheme.getTextTertiary(context)),
                    ),
                    const SizedBox(height: 16),

                    // Nom et Prénom
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: nomController,
                            decoration: InputDecoration(
                              labelText: 'Nom *',
                              labelStyle: TextStyle(color: AppTheme.getTextSecondary(context)),
                              prefixIcon: Icon(Icons.person, color: AppTheme.getTextSecondary(context)),
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
                                borderSide: BorderSide(color: const Color(0xFF3B82F6), width: 2),
                              ),
                              filled: true,
                              fillColor: isDark ? Colors.grey.shade900.withOpacity(0.3) : Colors.grey.shade50,
                            ),
                            style: TextStyle(color: AppTheme.getTextPrimary(context)),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Le nom est requis';
                              }
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextFormField(
                            controller: prenomController,
                            decoration: InputDecoration(
                              labelText: 'Prénom *',
                              labelStyle: TextStyle(color: AppTheme.getTextSecondary(context)),
                              prefixIcon: Icon(Icons.person_outline, color: AppTheme.getTextSecondary(context)),
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
                                borderSide: BorderSide(color: const Color(0xFF3B82F6), width: 2),
                              ),
                              filled: true,
                              fillColor: isDark ? Colors.grey.shade900.withOpacity(0.3) : Colors.grey.shade50,
                            ),
                            style: TextStyle(color: AppTheme.getTextPrimary(context)),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Le prénom est requis';
                              }
                              return null;
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Email
                    TextFormField(
                      controller: emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: InputDecoration(
                        labelText: 'Email *',
                        labelStyle: TextStyle(color: AppTheme.getTextSecondary(context)),
                        prefixIcon: Icon(Icons.email, color: AppTheme.getTextSecondary(context)),
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
                          borderSide: BorderSide(color: const Color(0xFF3B82F6), width: 2),
                        ),
                        filled: true,
                        fillColor: isDark ? Colors.grey.shade900.withOpacity(0.3) : Colors.grey.shade50,
                      ),
                      style: TextStyle(color: AppTheme.getTextPrimary(context)),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'L\'email est requis';
                        }
                        if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value.trim())) {
                          return 'Email invalide';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Téléphone
                    TextFormField(
                      controller: telephoneController,
                      keyboardType: TextInputType.phone,
                      decoration: InputDecoration(
                        labelText: 'Téléphone',
                        labelStyle: TextStyle(color: AppTheme.getTextSecondary(context)),
                        prefixIcon: Icon(Icons.phone, color: AppTheme.getTextSecondary(context)),
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
                          borderSide: BorderSide(color: const Color(0xFF3B82F6), width: 2),
                        ),
                        filled: true,
                        fillColor: isDark ? Colors.grey.shade900.withOpacity(0.3) : Colors.grey.shade50,
                      ),
                      style: TextStyle(color: AppTheme.getTextPrimary(context)),
                    ),
                    const SizedBox(height: 16),

                    // Rôle (non modifiable)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                      decoration: BoxDecoration(
                        color: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppTheme.getBorderColor(context)),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.badge, color: AppTheme.getTextSecondary(context), size: 20),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Rôle',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: AppTheme.getTextSecondary(context),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  _getRoleLabel(selectedRole),
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: AppTheme.getTextPrimary(context),
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Statut
                    DropdownButtonFormField<String>(
                      value: selectedStatut,
                      decoration: InputDecoration(
                        labelText: 'Statut',
                        labelStyle: TextStyle(color: AppTheme.getTextSecondary(context)),
                        prefixIcon: Icon(Icons.circle, color: AppTheme.getTextSecondary(context)),
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
                          borderSide: BorderSide(color: const Color(0xFF3B82F6), width: 2),
                        ),
                        filled: true,
                        fillColor: isDark ? Colors.grey.shade900.withOpacity(0.3) : Colors.grey.shade50,
                      ),
                      dropdownColor: AppTheme.getCardBackground(context),
                      items: ['ACTIF', 'INACTIF', 'SUSPENDU'].map((statut) {
                        return DropdownMenuItem<String>(
                          value: statut,
                          child: Text(
                            _getStatutLabel(statut),
                            style: TextStyle(
                              color: _getStatutColor(statut),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          selectedStatut = value!;
                        });
                      },
                      style: TextStyle(color: AppTheme.getTextPrimary(context)),
                    ),
                    const SizedBox(height: 16),

                    // Centre
                    DropdownButtonFormField<int?>(
                      value: selectedCentreId,
                      decoration: InputDecoration(
                        labelText: 'Centre',
                        labelStyle: TextStyle(color: AppTheme.getTextSecondary(context)),
                        prefixIcon: Icon(Icons.location_city, color: AppTheme.getTextSecondary(context)),
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
                          borderSide: BorderSide(color: const Color(0xFF3B82F6), width: 2),
                        ),
                        filled: true,
                        fillColor: isDark ? Colors.grey.shade900.withOpacity(0.3) : Colors.grey.shade50,
                      ),
                      dropdownColor: AppTheme.getCardBackground(context),
                      items: [
                        const DropdownMenuItem<int?>(
                          value: null,
                          child: Text('Aucun centre'),
                        ),
                        ...provider.centres.map((centre) {
                          return DropdownMenuItem<int?>(
                            value: centre.id,
                            child: Text(centre.nom),
                          );
                        }),
                      ],
                      onChanged: (value) async {
                        setState(() {
                          selectedCentreId = value;
                          selectedLogementId = null;
                          availableLogements = [];
                        });

                        if (value != null) {
                          await provider.loadAvailableLogements(value);
                          setState(() {
                            availableLogements = provider.availableLogements;
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 16),

                    // Logement
                    if (selectedCentreId != null)
                      DropdownButtonFormField<int?>(
                        value: selectedLogementId,
                        decoration: InputDecoration(
                          labelText: 'Logement',
                          labelStyle: TextStyle(color: AppTheme.getTextSecondary(context)),
                          prefixIcon: Icon(Icons.home, color: AppTheme.getTextSecondary(context)),
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
                            borderSide: BorderSide(color: const Color(0xFF3B82F6), width: 2),
                          ),
                          filled: true,
                          fillColor: isDark ? Colors.grey.shade900.withOpacity(0.3) : Colors.grey.shade50,
                        ),
                        dropdownColor: AppTheme.getCardBackground(context),
                        items: [
                          const DropdownMenuItem<int?>(
                            value: null,
                            child: Text('Aucun logement'),
                          ),
                          ...availableLogements.map((logement) {
                            return DropdownMenuItem<int?>(
                              value: logement['id'] as int,
                              child: Text(
                                'Chambre ${logement['numero_chambre']} - ${logement['type_chambre']}',
                              ),
                            );
                          }),
                        ],
                        onChanged: (value) {
                          setState(() {
                            selectedLogementId = value;
                          });
                        },
                      ),
                    if (selectedCentreId != null) const SizedBox(height: 16),

                    // Boutons
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: isSaving ? null : () => Navigator.pop(context),
                          child: Text(
                            'Annuler',
                            style: TextStyle(color: AppTheme.getTextSecondary(context)),
                          ),
                        ),
                        const SizedBox(width: 12),
                        ElevatedButton.icon(
                          onPressed: isSaving ? null : () async {
                            if (formKey.currentState!.validate()) {
                              final scaffoldMessenger = ScaffoldMessenger.of(context);
                              setState(() => isSaving = true);
                              try {
                                await provider.updateUser(
                                  userId: user.id,
                                  nom: nomController.text.trim(),
                                  prenom: prenomController.text.trim(),
                                  email: emailController.text.trim(),
                                  telephone: telephoneController.text.trim().isEmpty
                                      ? null
                                      : telephoneController.text.trim(),
                                  statut: selectedStatut,
                                  logementId: selectedLogementId,
                                );
                                Navigator.pop(context);
                                scaffoldMessenger.showSnackBar(
                                  const SnackBar(
                                    content: Text('Utilisateur mis à jour avec succès'),
                                    backgroundColor: Color(0xFF10B981),
                                    behavior: SnackBarBehavior.floating,
                                  ),
                                );
                              } catch (e) {
                                setState(() => isSaving = false);
                                scaffoldMessenger.showSnackBar(
                                  SnackBar(
                                    content: Text('Erreur: $e'),
                                    backgroundColor: const Color(0xFFEF4444),
                                    behavior: SnackBarBehavior.floating,
                                  ),
                                );
                              }
                            }
                          },
                          icon: isSaving
                              ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                              : const Icon(Icons.save, color: Colors.white),
                          label: Text(isSaving ? 'Enregistrement...' : 'Enregistrer'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF3B82F6),
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
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

    // Dispose des contrôleurs après la fermeture du dialogue
    matriculeController.dispose();
    nomController.dispose();
    prenomController.dispose();
    emailController.dispose();
    telephoneController.dispose();
  }

  /// Affiche une boîte de dialogue de confirmation.
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
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.getTextPrimary(context),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                message,
                style: TextStyle(color: AppTheme.getTextSecondary(context)),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: Text(
                      'Annuler',
                      style: TextStyle(color: AppTheme.getTextSecondary(context)),
                    ),
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
                    child: Text(isCritical ? 'Supprimer' : 'Confirmer'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getRoleLabel(String role) {
    const roleLabels = {
      'ETUDIANT': 'Étudiant',
      'GESTIONNAIRE': 'Gestionnaire',
      'ADMIN': 'Administrateur',
      'TOUS': 'Tous',
    };
    return roleLabels[role] ?? role;
  }

  Color _getRoleColor(String role) {
    const roleColors = {
      'ETUDIANT': Color(0xFF3B82F6),
      'GESTIONNAIRE': Color(0xFF10B981),
      'ADMIN': Color(0xFF8B5CF6),
    };
    return roleColors[role] ?? const Color(0xFF64748B);
  }

  String _getStatutLabel(String statut) {
    const statutLabels = {
      'ACTIF': 'Actif',
      'INACTIF': 'Inactif',
      'SUSPENDU': 'Suspendu',
      'TOUS': 'Tous',
    };
    return statutLabels[statut] ?? statut;
  }

  Color _getStatutColor(String statut) {
    const statutColors = {
      'ACTIF': Color(0xFF10B981),
      'INACTIF': Color(0xFFF59E0B),
      'SUSPENDU': Color(0xFFEF4444),
    };
    return statutColors[statut] ?? const Color(0xFF64748B);
  }

  Future<void> _applySearch(String query) async {
    final provider = Provider.of<UserAdminProvider>(context, listen: false);
    await provider.applyFilter('search', query);
  }

  Future<void> _applyFilter(String key, dynamic value) async {
    final provider = Provider.of<UserAdminProvider>(context, listen: false);
    await provider.applyFilter(key, value);
  }

  Future<void> _resetFilters() async {
    setState(() {
      _searchController.clear();
      _selectedRole = 'TOUS';
      _selectedStatut = 'TOUS';
    });
    final provider = Provider.of<UserAdminProvider>(context, listen: false);
    await provider.resetFilters();
  }

  Future<void> _refreshData() async {
    final provider = Provider.of<UserAdminProvider>(context, listen: false);
    await provider.loadUsers();
  }
}

/// Widget utilitaire pour les en‑têtes de colonnes.
class _HeaderText extends StatelessWidget {
  final String text;
  final bool isDark;

  const _HeaderText(this.text, this.isDark);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        fontWeight: FontWeight.bold,
        color: AppTheme.getTextPrimary(context),
        fontSize: 13,
      ),
    );
  }
}