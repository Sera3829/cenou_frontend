// screens/web/utilisateurs/user_admin_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cenou_mobile/config/theme.dart';
import 'package:cenou_mobile/l10n/app_localizations.dart';
import 'package:cenou_mobile/providers/web/user_admin_provider.dart';
import 'package:cenou_mobile/widgets/skeleton/skeletons.dart';
import 'package:cenou_mobile/widgets/admin/admin_states.dart';
import '../dashboard/dashboard_screen.dart';
import 'dialogs/user_form_dialog.dart';
import 'widgets/user_filters_bar.dart';
import 'widgets/user_stats.dart';
import 'widgets/user_table.dart';

/// Écran d'administration des utilisateurs (coquille : état + composition).
/// La logique métier (filtres, chargement) vit dans [UserAdminProvider] ;
/// l'UI est découpée en composants (barre de filtres, stats, tableau, dialogues).
class UserAdminScreen extends StatefulWidget {
  const UserAdminScreen({Key? key}) : super(key: key);

  @override
  State<UserAdminScreen> createState() => _UserAdminScreenState();
}

class _UserAdminScreenState extends State<UserAdminScreen> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  String _selectedRole = 'TOUS';
  String _selectedStatut = 'TOUS';
  bool _showFilters = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadInitialData());
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadInitialData() =>
      Provider.of<UserAdminProvider>(context, listen: false).loadUsers();

  Future<void> _applySearch(String query) =>
      Provider.of<UserAdminProvider>(context, listen: false).applyFilter('search', query);

  Future<void> _applyFilter(String key, dynamic value) =>
      Provider.of<UserAdminProvider>(context, listen: false).applyFilter(key, value);

  Future<void> _resetFilters() async {
    setState(() {
      _searchController.clear();
      _selectedRole = 'TOUS';
      _selectedStatut = 'TOUS';
    });
    await Provider.of<UserAdminProvider>(context, listen: false).resetFilters();
  }

  Future<void> _refreshData() =>
      Provider.of<UserAdminProvider>(context, listen: false).loadUsers();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return DashboardLayout(
      selectedIndex: 3,
      child: Column(
        children: [
          UserFiltersBar(
            searchController: _searchController,
            selectedRole: _selectedRole,
            selectedStatut: _selectedStatut,
            showFilters: _showFilters,
            l10n: l10n,
            onSearch: _applySearch,
            onRoleChanged: (value) {
              setState(() => _selectedRole = value);
              _applyFilter('role', value == 'TOUS' ? null : value);
            },
            onStatutChanged: (value) {
              setState(() => _selectedStatut = value);
              _applyFilter('statut', value == 'TOUS' ? null : value);
            },
            onToggleFilters: () => setState(() => _showFilters = !_showFilters),
            onReset: _resetFilters,
            onRefresh: _refreshData,
            onNewUser: () => showCreateUserDialog(context, l10n),
          ),
          Expanded(
            child: Consumer<UserAdminProvider>(
              builder: (context, provider, _) {
                if (provider.isLoading && provider.users.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.all(24),
                    child: SkeletonDataTable(),
                  );
                }
                if (provider.error != null && provider.users.isEmpty) {
                  return AdminErrorState(
                    error: provider.error!,
                    title: l10n.loadingError,
                    retryLabel: l10n.retry,
                    onRetry: _refreshData,
                  );
                }
                if (provider.users.isEmpty) {
                  return AdminEmptyState(
                    icon: Icons.people_outline,
                    title: l10n.noUsersFound,
                    subtitle: l10n.adjustFiltersOrCreate,
                    actions: [
                      ElevatedButton(
                        onPressed: _resetFilters,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Theme.of(context).colorScheme.primary,
                          foregroundColor: Colors.white,
                        ),
                        child: Text(l10n.resetFilters),
                      ),
                      ElevatedButton.icon(
                        onPressed: () => showCreateUserDialog(context, l10n),
                        icon: const Icon(Icons.add, color: Colors.white),
                        label: Text(l10n.createNewUser,
                            style: const TextStyle(color: Colors.white)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Theme.of(context).colorScheme.primary,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ],
                  );
                }

                return CustomScrollView(
                  controller: _scrollController,
                  slivers: [
                    SliverToBoxAdapter(
                      child: Column(
                        children: [
                          UserStats(provider: provider, l10n: l10n),
                          AnimatedSize(
                            duration: const Duration(milliseconds: 300),
                            child: _showFilters
                                ? _buildFiltersCard(context, l10n)
                                : const SizedBox.shrink(),
                          ),
                        ],
                      ),
                    ),
                    SliverToBoxAdapter(
                      child: UserTable(provider: provider, l10n: l10n),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  /// Carte « filtres avancés » (repli).
  Widget _buildFiltersCard(BuildContext context, AppLocalizations l10n) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.fromLTRB(24, 0, 24, 24),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.getCardBackground(context),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(isDark ? 0.1 : 0.05), blurRadius: 10),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(l10n.advancedFilters,
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.getTextPrimary(context))),
              const Spacer(),
              TextButton.icon(
                onPressed: () => setState(() => _showFilters = false),
                icon: Icon(Icons.close, size: 16, color: AppTheme.getTextSecondary(context)),
                label: Text(l10n.close,
                    style: TextStyle(color: AppTheme.getTextSecondary(context))),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(l10n.otherFilterOptions,
              style: TextStyle(color: AppTheme.getTextSecondary(context))),
        ],
      ),
    );
  }
}
