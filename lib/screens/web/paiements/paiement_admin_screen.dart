import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:cenou_mobile/l10n/app_localizations.dart';
import 'package:cenou_mobile/providers/web/paiement_admin_provider.dart';
import 'package:cenou_mobile/widgets/skeleton/skeletons.dart';
import 'package:cenou_mobile/widgets/admin/admin_states.dart';
import '../dashboard/dashboard_layout.dart';
import 'utils/paiement_export.dart';
import 'widgets/paiement_filters_bar.dart';
import 'widgets/paiement_filters_card.dart';
import 'widgets/paiement_stats.dart';
import 'widgets/paiement_table.dart';

/// Écran d'administration des paiements (coquille : état + composition).
class PaiementAdminScreen extends StatefulWidget {
  const PaiementAdminScreen({Key? key}) : super(key: key);

  @override
  State<PaiementAdminScreen> createState() => _PaiementAdminScreenState();
}

class _PaiementAdminScreenState extends State<PaiementAdminScreen> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  String _selectedStatut = 'TOUS';
  String _selectedMode = 'TOUS';
  DateTime? _selectedDateFrom;
  DateTime? _selectedDateTo;
  bool _showFilters = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadInitialData());
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  PaiementAdminProvider get _provider =>
      Provider.of<PaiementAdminProvider>(context, listen: false);

  Future<void> _loadInitialData() async {
    await _provider.loadPaiements();
    await _provider.loadStatistiques();
  }

  Future<void> _applySearch(String query) => _provider.searchPaiements(query);

  Future<void> _applyFilter(String key, dynamic value) => _provider.applyFilter(key, value);

  Future<void> _applyAllFilters() => _provider.applyMultipleFilters({
        'statut': _selectedStatut,
        'mode_paiement': _selectedMode,
        'search': _searchController.text,
        'date_from':
            _selectedDateFrom != null ? DateFormat('yyyy-MM-dd').format(_selectedDateFrom!) : null,
        'date_to':
            _selectedDateTo != null ? DateFormat('yyyy-MM-dd').format(_selectedDateTo!) : null,
      });

  Future<void> _resetFilters() async {
    setState(() {
      _searchController.clear();
      _selectedStatut = 'TOUS';
      _selectedMode = 'TOUS';
      _selectedDateFrom = null;
      _selectedDateTo = null;
    });
    await _provider.resetFilters();
  }

  Future<void> _refreshData() => _provider.loadPaiements();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return DashboardLayout(
      selectedIndex: 1,
      child: Column(
        children: [
          PaiementFiltersBar(
            searchController: _searchController,
            selectedStatut: _selectedStatut,
            selectedMode: _selectedMode,
            showFilters: _showFilters,
            l10n: l10n,
            onSearch: _applySearch,
            onStatutChanged: (value) {
              setState(() => _selectedStatut = value);
              _applyFilter('statut', value == 'TOUS' ? null : value);
            },
            onModeChanged: (value) {
              setState(() => _selectedMode = value);
              _applyFilter('mode_paiement', value == 'TOUS' ? null : value);
            },
            onToggleFilters: () => setState(() => _showFilters = !_showFilters),
            onReset: _resetFilters,
            onExport: () => exportPaiements(context, _provider, l10n),
            onRefresh: _refreshData,
          ),
          Expanded(
            child: CustomScrollView(
              controller: _scrollController,
              slivers: [
                SliverToBoxAdapter(
                  child: Column(
                    children: [
                      PaiementStats(l10n: l10n),
                      AnimatedSize(
                        duration: const Duration(milliseconds: 300),
                        child: _showFilters
                            ? PaiementFiltersCard(
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
                  child: Consumer<PaiementAdminProvider>(
                    builder: (context, provider, _) {
                      if (provider.isLoading && provider.paiements.isEmpty) {
                        return const Padding(
                          padding: EdgeInsets.all(24),
                          child: SkeletonDataTable(),
                        );
                      }
                      if (provider.error != null && provider.paiements.isEmpty) {
                        return AdminErrorState(
                          error: provider.error!,
                          title: l10n.loadingError,
                          retryLabel: l10n.retry,
                          onRetry: _refreshData,
                        );
                      }
                      if (provider.paiements.isEmpty) {
                        return AdminEmptyState(
                          icon: Icons.payments_outlined,
                          title: l10n.noPaymentsFound,
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
                      return PaiementTable(provider: provider, l10n: l10n);
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
