import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cenou_mobile/l10n/app_localizations.dart';
import 'package:cenou_mobile/providers/web/signalement_admin_provider.dart';
import 'package:cenou_mobile/widgets/skeleton/skeletons.dart';
import 'package:cenou_mobile/widgets/admin/admin_states.dart';
import '../dashboard/dashboard_screen.dart';
import 'widgets/signalement_filters_bar.dart';
import 'widgets/signalement_filters_card.dart';
import 'widgets/signalement_stats.dart';
import 'widgets/signalement_table.dart';

/// Écran d'administration des signalements (coquille : état + composition).
class SignalementAdminScreen extends StatefulWidget {
  const SignalementAdminScreen({Key? key}) : super(key: key);

  @override
  State<SignalementAdminScreen> createState() => _SignalementAdminScreenState();
}

class _SignalementAdminScreenState extends State<SignalementAdminScreen> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  String _selectedStatut = 'TOUS';
  String _selectedType = 'TOUS';
  DateTime? _selectedDateFrom;
  DateTime? _selectedDateTo;
  bool _showFilters = true;
  bool _isRefreshing = false;

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

  SignalementAdminProvider get _provider =>
      Provider.of<SignalementAdminProvider>(context, listen: false);

  Future<void> _loadInitialData() =>
      Future.wait([_provider.loadSignalements(), _provider.loadStatistiques()]);

  Future<void> _applySearch(String query) => _provider.searchSignalements(query);

  Future<void> _applyFilter(String key, dynamic value) => _provider.applyFilter(key, value);

  Future<void> _applyAllFilters() => _provider.loadSignalements(resetPage: true);

  Future<void> _resetFilters() async {
    setState(() {
      _searchController.clear();
      _selectedStatut = 'TOUS';
      _selectedType = 'TOUS';
      _selectedDateFrom = null;
      _selectedDateTo = null;
    });
    await _provider.resetFilters();
  }

  Future<void> _refreshData() async {
    if (_isRefreshing) return;
    setState(() => _isRefreshing = true);
    final l10n = AppLocalizations.of(context);
    try {
      await Future.wait([_provider.loadSignalements(), _provider.loadStatistiques()]);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(l10n.dataRefreshed),
          backgroundColor: const Color(0xFF10B981),
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
        ));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('${l10n.error}: $e'),
          backgroundColor: const Color(0xFFEF4444),
          behavior: SnackBarBehavior.floating,
        ));
      }
    } finally {
      if (mounted) setState(() => _isRefreshing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return DashboardLayout(
      selectedIndex: 2,
      child: Column(
        children: [
          SignalementFiltersBar(
            searchController: _searchController,
            selectedStatut: _selectedStatut,
            selectedType: _selectedType,
            showFilters: _showFilters,
            isRefreshing: _isRefreshing,
            l10n: l10n,
            onSearch: _applySearch,
            onStatutChanged: (value) {
              setState(() => _selectedStatut = value);
              _applyFilter('statut', value == 'TOUS' ? null : value);
            },
            onTypeChanged: (value) {
              setState(() => _selectedType = value);
              _applyFilter('type', value == 'TOUS' ? null : value);
            },
            onToggleFilters: () => setState(() => _showFilters = !_showFilters),
            onReset: _resetFilters,
            onRefresh: _refreshData,
          ),
          Expanded(
            child: CustomScrollView(
              controller: _scrollController,
              slivers: [
                SliverToBoxAdapter(
                  child: Column(
                    children: [
                      SignalementStats(l10n: l10n),
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        height: _showFilters ? null : 0,
                        child: _showFilters
                            ? SignalementFiltersCard(
                                selectedDateFrom: _selectedDateFrom,
                                selectedDateTo: _selectedDateTo,
                                l10n: l10n,
                                onDateFrom: (d) => setState(() => _selectedDateFrom = d),
                                onDateTo: (d) => setState(() => _selectedDateTo = d),
                                onApply: _applyAllFilters,
                                onClose: () => setState(() => _showFilters = false),
                              )
                            : const SizedBox.shrink(),
                      ),
                    ],
                  ),
                ),
                SliverToBoxAdapter(
                  child: Consumer<SignalementAdminProvider>(
                    builder: (context, provider, _) {
                      if (provider.isLoading && provider.signalements.isEmpty) {
                        return const Padding(
                          padding: EdgeInsets.all(24),
                          child: SkeletonDataTable(),
                        );
                      }
                      if (provider.error != null && provider.signalements.isEmpty) {
                        return AdminErrorState(
                          error: provider.error!,
                          title: l10n.loadingError,
                          retryLabel: l10n.retry,
                          onRetry: _refreshData,
                        );
                      }
                      if (provider.signalements.isEmpty) {
                        return AdminEmptyState(
                          icon: Icons.warning_outlined,
                          title: l10n.noReportsFound,
                          subtitle: l10n.adjustFiltersOrWait,
                          actions: [
                            ElevatedButton(
                              onPressed: _resetFilters,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Theme.of(context).colorScheme.primary,
                                foregroundColor: Colors.white,
                              ),
                              child: Text(l10n.resetFilters),
                            ),
                          ],
                        );
                      }
                      return SignalementTable(provider: provider, l10n: l10n);
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
