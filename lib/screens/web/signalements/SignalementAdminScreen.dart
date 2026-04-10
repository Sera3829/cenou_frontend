import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:cenou_mobile/providers/web/signalement_admin_provider.dart';
import 'package:cenou_mobile/models/signalement.dart';
import 'package:cenou_mobile/config/theme.dart';
import '../../../config/app_config.dart';
import '../dashboard/dashboard_screen.dart';
import '../../../l10n/app_localizations.dart';

class SignalementAdminScreen extends StatefulWidget {
  const SignalementAdminScreen({Key? key}) : super(key: key);

  @override
  State<SignalementAdminScreen> createState() =>
      _SignalementAdminScreenState();
}

class _SignalementAdminScreenState extends State<SignalementAdminScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedStatut = 'TOUS';
  String _selectedType = 'TOUS';
  DateTime? _selectedDateFrom;
  DateTime? _selectedDateTo;
  bool _showFilters = true;
  bool _isRefreshing = false;

  // Contrôleurs pour le scroll
  final ScrollController _scrollController = ScrollController();
  final ScrollController _tableHScrollCtrl = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadInitialData());
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    _tableHScrollCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadInitialData() async {
    final provider = Provider.of<SignalementAdminProvider>(context, listen: false);
    await Future.wait([provider.loadSignalements(), provider.loadStatistiques()]);
  }

  String _formatDate(DateTime d, AppLocalizations l10n) => DateFormat('dd/MM/yy HH:mm', l10n.locale.languageCode).format(d);
  String _formatDateOnly(DateTime d, AppLocalizations l10n) => DateFormat('dd/MM/yyyy', l10n.locale.languageCode).format(d);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return DashboardLayout(
      selectedIndex: 2,
      child: Column(
        children: [
          // ① Barre de filtres rapides (fixe en haut)
          _buildFloatingFiltersBar(isDark, l10n),

          // ② Zone scrollable principale
          Expanded(
            child: CustomScrollView(
              controller: _scrollController,
              slivers: [
                // Stats + filtres avancés — scrollent normalement
                SliverToBoxAdapter(
                  child: Column(
                    children: [
                      _buildQuickStats(isDark, l10n),
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        height: _showFilters ? null : 0,
                        child: _showFilters
                            ? _buildFiltersCard(isDark, l10n)
                            : const SizedBox.shrink(),
                      ),
                    ],
                  ),
                ),

                // ③ Barre de scroll horizontal — STICKY (pinned: true)
                SliverPersistentHeader(
                  pinned: true,
                  delegate: _HScrollBarDelegate(
                    hScrollCtrl: _tableHScrollCtrl,
                    isDark: isDark,
                  ),
                ),

                // ④ Tableau (en-têtes + lignes + pagination)
                SliverToBoxAdapter(
                  child: _buildSignalementsList(isDark, l10n),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ==================== BARRE DE FILTRES ====================

  Widget _buildFloatingFiltersBar(bool isDark, AppLocalizations l10n) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isWide = screenWidth > 1100;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      decoration: BoxDecoration(
        color: AppTheme.getTopBarBackground(context),
        border: Border(
          bottom: BorderSide(color: AppTheme.getBorderColor(context)),
        ),
      ),
      child: isWide
          ? Row(
        children: [
          Expanded(flex: 3, child: _buildSearchField(isDark, l10n)),
          const SizedBox(width: 12),
          SizedBox(width: 160, child: _buildStatutDropdown(isDark, l10n)),
          const SizedBox(width: 12),
          SizedBox(width: 160, child: _buildTypeDropdown(isDark, l10n)),
          const SizedBox(width: 12),
          _buildFilterButtons(l10n),
        ],
      )
          : Column(
        children: [
          _buildSearchField(isDark, l10n),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(child: _buildStatutDropdown(isDark, l10n)),
              const SizedBox(width: 8),
              Expanded(child: _buildTypeDropdown(isDark, l10n)),
              const SizedBox(width: 8),
              _buildFilterButtons(l10n),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSearchField(bool isDark, AppLocalizations l10n) {
    return TextField(
      controller: _searchController,
      decoration: InputDecoration(
        hintText: l10n.searchReportHint,
        prefixIcon: Icon(
          Icons.search,
          size: 20,
          color: AppTheme.getTextSecondary(context),
        ),
        suffixIcon: _searchController.text.isNotEmpty
            ? IconButton(
          icon: Icon(
            Icons.clear,
            size: 20,
            color: AppTheme.getTextSecondary(context),
          ),
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
            color: Theme.of(context).colorScheme.primary,
            width: 2,
          ),
        ),
        filled: true,
        fillColor: isDark
            ? Colors.grey.shade900.withOpacity(0.3)
            : Colors.grey.shade50,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        isDense: true,
        hintStyle: TextStyle(color: AppTheme.getTextSecondary(context)),
      ),
      onSubmitted: _applySearch,
      style: TextStyle(color: AppTheme.getTextPrimary(context)),
    );
  }

  Widget _buildStatutDropdown(bool isDark, AppLocalizations l10n) {
    return DropdownButtonFormField<String>(
      value: _selectedStatut,
      decoration: InputDecoration(
        labelText: l10n.status,
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
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        isDense: true,
      ),
      dropdownColor: AppTheme.getCardBackground(context),
      items: ['TOUS', 'EN_ATTENTE', 'EN_COURS', 'RESOLU', 'ANNULE']
          .map(
            (v) => DropdownMenuItem(
          value: v,
          child: Text(
            _getStatutLabel(v, l10n),
            style: TextStyle(
              fontSize: 14,
              color: AppTheme.getTextPrimary(context),
            ),
          ),
        ),
      )
          .toList(),
      onChanged: (value) {
        setState(() => _selectedStatut = value!);
        _applyFilter('statut', value == 'TOUS' ? null : value);
      },
      style: TextStyle(color: AppTheme.getTextPrimary(context)),
    );
  }

  Widget _buildTypeDropdown(bool isDark, AppLocalizations l10n) {
    return DropdownButtonFormField<String>(
      value: _selectedType,
      decoration: InputDecoration(
        labelText: l10n.type,
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
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        isDense: true,
      ),
      dropdownColor: AppTheme.getCardBackground(context),
      items: [
        'TOUS',
        'PLOMBERIE',
        'ELECTRICITE',
        'TOITURE',
        'SERRURE',
        'MOBILIER',
        'AUTRE'
      ].map(
            (v) => DropdownMenuItem(
          value: v,
          child: Text(
            _getTypeLabel(v, l10n),
            style: TextStyle(
              fontSize: 14,
              color: AppTheme.getTextPrimary(context),
            ),
          ),
        ),
      ).toList(),
      onChanged: (value) {
        setState(() => _selectedType = value!);
        _applyFilter('type', value == 'TOUS' ? null : value);
      },
      style: TextStyle(color: AppTheme.getTextPrimary(context)),
    );
  }

  Widget _buildFilterButtons(AppLocalizations l10n) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          onPressed: () => setState(() => _showFilters = !_showFilters),
          icon: Icon(
            _showFilters ? Icons.filter_list_off : Icons.filter_list,
            color: Theme.of(context).colorScheme.primary,
          ),
          tooltip: _showFilters ? l10n.hideFilters : l10n.moreFilters,
        ),
        IconButton(
          onPressed: _resetFilters,
          icon: Icon(
            Icons.refresh,
            color: AppTheme.getTextSecondary(context),
          ),
          tooltip: l10n.reset,
        ),
        ElevatedButton(
          onPressed: _isRefreshing ? null : _refreshData,
          style: ElevatedButton.styleFrom(
            backgroundColor: Theme.of(context).colorScheme.primary,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: _isRefreshing
              ? const SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          )
              : Text(
            l10n.refresh,
            style: const TextStyle(color: Colors.white),
          ),
        ),
      ],
    );
  }

  // ==================== STATISTIQUES ====================

  Widget _buildQuickStats(bool isDark, AppLocalizations l10n) {
    return Consumer<SignalementAdminProvider>(
      builder: (context, provider, child) {
        final stats = provider.statistiques ?? {};
        final screenWidth = MediaQuery.of(context).size.width;
        final sidebarWidth = screenWidth > 900 ? 280.0 : 0.0;
        final isWide = (screenWidth - sidebarWidth) > 700;

        return Container(
          padding: const EdgeInsets.all(24),
          color: isDark
              ? Colors.grey.shade900.withOpacity(0.5)
              : const Color(0xFFF1F5F9),
          child: isWide
              ? Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  label: l10n.totalReports,
                  value: '${stats['total'] ?? 0}',
                  color: const Color(0xFF3B82F6),
                  icon: Icons.warning,
                  isDark: isDark,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildStatCard(
                  label: l10n.pending,
                  value: '${stats['en_attente'] ?? 0}',
                  color: const Color(0xFFF59E0B),
                  icon: Icons.hourglass_empty,
                  isDark: isDark,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildStatCard(
                  label: l10n.inProgress,
                  value: '${stats['en_cours'] ?? 0}',
                  color: const Color(0xFF3B82F6),
                  icon: Icons.build,
                  isDark: isDark,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildStatCard(
                  label: l10n.resolutionRate,
                  value:
                  '${(stats['taux_resolution'] ?? 0).toStringAsFixed(1)}%',
                  color: const Color(0xFF10B981),
                  icon: Icons.check_circle,
                  isDark: isDark,
                ),
              ),
            ],
          )
              : Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      label: l10n.total,
                      value: '${stats['total'] ?? 0}',
                      color: const Color(0xFF3B82F6),
                      icon: Icons.warning,
                      isDark: isDark,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildStatCard(
                      label: l10n.pending,
                      value: '${stats['en_attente'] ?? 0}',
                      color: const Color(0xFFF59E0B),
                      icon: Icons.hourglass_empty,
                      isDark: isDark,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      label: l10n.inProgress,
                      value: '${stats['en_cours'] ?? 0}',
                      color: const Color(0xFF3B82F6),
                      icon: Icons.build,
                      isDark: isDark,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildStatCard(
                      label: l10n.rate,
                      value:
                      '${(stats['taux_resolution'] ?? 0).toStringAsFixed(1)}%',
                      color: const Color(0xFF10B981),
                      icon: Icons.check_circle,
                      isDark: isDark,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatCard({
    required String label,
    required String value,
    required Color color,
    required IconData icon,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
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
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 13,
                    color: AppTheme.getTextSecondary(context),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ==================== FILTRES AVANCÉS ====================

  Widget _buildFiltersCard(bool isDark, AppLocalizations l10n) {
    return Container(
      margin: const EdgeInsets.fromLTRB(24, 0, 24, 24),
      padding: const EdgeInsets.all(20),
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
          Row(
            children: [
              Text(
                l10n.advancedFilters,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.getTextPrimary(context),
                ),
              ),
              const Spacer(),
              TextButton.icon(
                onPressed: () => setState(() => _showFilters = false),
                icon: Icon(
                  Icons.close,
                  size: 16,
                  color: AppTheme.getTextSecondary(context),
                ),
                label: Text(
                  l10n.close,
                  style: TextStyle(color: AppTheme.getTextSecondary(context)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildDatePicker(
                  label: l10n.startDate,
                  selectedDate: _selectedDateFrom,
                  onDateSelected: (d) => setState(() => _selectedDateFrom = d),
                  isDark: isDark,
                  l10n: l10n,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildDatePicker(
                  label: l10n.endDate,
                  selectedDate: _selectedDateTo,
                  onDateSelected: (d) => setState(() => _selectedDateTo = d),
                  isDark: isDark,
                  l10n: l10n,
                ),
              ),
              const SizedBox(width: 16),
              ElevatedButton.icon(
                onPressed: _applyAllFilters,
                icon: const Icon(Icons.check, size: 18, color: Colors.white),
                label: Text(
                  l10n.apply,
                  style: const TextStyle(color: Colors.white),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDatePicker({
    required String label,
    required DateTime? selectedDate,
    required ValueChanged<DateTime> onDateSelected,
    required bool isDark,
    required AppLocalizations l10n,
  }) {
    return InkWell(
      onTap: () async {
        final date = await showDatePicker(
          context: context,
          initialDate: selectedDate ?? DateTime.now(),
          firstDate: DateTime(2020),
          lastDate: DateTime.now(),
          builder: (ctx, child) => Theme(
            data: Theme.of(ctx).copyWith(
              colorScheme: ColorScheme.light(
                primary: Theme.of(ctx).colorScheme.primary,
                onPrimary: Colors.white,
                surface: AppTheme.getCardBackground(ctx),
                onSurface: AppTheme.getTextPrimary(ctx),
              ),
              dialogBackgroundColor: AppTheme.getCardBackground(ctx),
            ),
            child: child!,
          ),
        );
        if (date != null) onDateSelected(date);
      },
      child: InputDecorator(
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
          fillColor: isDark
              ? Colors.grey.shade900.withOpacity(0.3)
              : Colors.grey.shade50,
          suffixIcon: Icon(
            Icons.calendar_today,
            size: 18,
            color: AppTheme.getTextSecondary(context),
          ),
        ),
        child: Text(
          selectedDate != null ? _formatDateOnly(selectedDate, l10n) : l10n.select,
          style: TextStyle(
            color: selectedDate != null
                ? AppTheme.getTextPrimary(context)
                : AppTheme.getTextSecondary(context),
          ),
        ),
      ),
    );
  }

  // ==================== TABLEAU ====================

  Widget _buildSignalementsList(bool isDark, AppLocalizations l10n) {
    return Consumer<SignalementAdminProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading && provider.signalements.isEmpty) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(48),
              child: CircularProgressIndicator(),
            ),
          );
        }
        if (provider.error != null && provider.signalements.isEmpty) {
          return _buildErrorWidget(provider.error!, isDark, l10n);
        }
        if (provider.signalements.isEmpty) {
          return _buildEmptyState(isDark, l10n);
        }

        final screenWidth = MediaQuery.of(context).size.width;
        final sidebarWidth = screenWidth > 900 ? 220.0 : 0.0;
        final availableWidth = screenWidth - sidebarWidth - 48;
        final tableWidth = availableWidth > 800 ? availableWidth : 800.0;

        final colEtudiant = tableWidth * 0.22;
        final colDescription = tableWidth * 0.24;
        final colType = tableWidth * 0.13;
        final colStatut = tableWidth * 0.15;
        final colDate = tableWidth * 0.16;
        final colActions = tableWidth * 0.10;

        return Container(
          margin: const EdgeInsets.fromLTRB(24, 0, 24, 24),
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
            children: [
              // Tableau scrollable horizontalement — MÊME controller que la barre sticky
              SingleChildScrollView(
                controller: _tableHScrollCtrl,
                scrollDirection: Axis.horizontal,
                child: SizedBox(
                  width: tableWidth,
                  child: Column(
                    children: [
                      // En-tête
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
                              color: AppTheme.getBorderColor(context),
                              width: 1,
                            ),
                          ),
                        ),
                        child: Row(
                          children: [
                            SizedBox(
                                width: colEtudiant,
                                child: _headerText(l10n.student)),
                            SizedBox(
                                width: colDescription,
                                child: _headerText(l10n.description)),
                            SizedBox(width: colType, child: _headerText(l10n.type)),
                            SizedBox(
                                width: colStatut,
                                child: _headerText(l10n.status)),
                            SizedBox(width: colDate, child: _headerText(l10n.date)),
                            SizedBox(
                                width: colActions,
                                child: _headerText(l10n.actions)),
                          ],
                        ),
                      ),
                      // Lignes
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: provider.signalements.length,
                        itemBuilder: (context, index) => _buildRow(
                          provider.signalements[index],
                          provider,
                          index,
                          isDark,
                          l10n,
                          colEtudiant: colEtudiant,
                          colDescription: colDescription,
                          colType: colType,
                          colStatut: colStatut,
                          colDate: colDate,
                          colActions: colActions,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              _buildPagination(provider, isDark, l10n),
            ],
          ),
        );
      },
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

  Widget _buildRow(
      Signalement s,
      SignalementAdminProvider provider,
      int index,
      bool isDark,
      AppLocalizations l10n, {
        required double colEtudiant,
        required double colDescription,
        required double colType,
        required double colStatut,
        required double colDate,
        required double colActions,
      }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: index.isEven
            ? AppTheme.getCardBackground(context)
            : (isDark
            ? Colors.grey.shade900.withOpacity(0.3)
            : const Color(0xFFFAFAFA)),
        border: Border(
          bottom: BorderSide(
            color: AppTheme.getBorderColor(context),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          // Étudiant
          SizedBox(
            width: colEtudiant,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  s.displayEtudiantNomComplet,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: AppTheme.getTextPrimary(context),
                    fontSize: 14,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  s.matricule ?? 'N/A',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppTheme.getTextSecondary(context),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  s.numeroSuivi,
                  style: TextStyle(
                    fontSize: 11,
                    color: AppTheme.getTextTertiary(context),
                  ),
                ),
                if (s.numeroChambre != null && s.nomCentre != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    l10n.centerRoom(s.nomCentre!, s.numeroChambre!),
                    style: TextStyle(
                      fontSize: 11,
                      color: AppTheme.getTextTertiary(context),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
          // Description
          SizedBox(
            width: colDescription,
            child: Text(
              s.description.length > 100
                  ? '${s.description.substring(0, 100)}...'
                  : s.description,
              style: TextStyle(
                color: AppTheme.getTextSecondary(context),
                fontSize: 13,
              ),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          // Type - badge aligné à gauche, taille au contenu
          SizedBox(
            width: colType,
            child: Align(
              alignment: Alignment.centerLeft,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: _getTypeColor(s.typeProbleme)
                      .withOpacity(isDark ? 0.2 : 0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: _getTypeColor(s.typeProbleme)
                        .withOpacity(isDark ? 0.4 : 0.3),
                  ),
                ),
                child: Text(
                  _getTypeLabel(s.typeProbleme, l10n),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: _getTypeColor(s.typeProbleme),
                  ),
                ),
              ),
            ),
          ),
          // Statut - badge aligné à gauche, taille au contenu
          SizedBox(
            width: colStatut,
            child: Align(
              alignment: Alignment.centerLeft,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color:
                  _getStatutColor(s.statut).withOpacity(isDark ? 0.2 : 0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: _getStatutColor(s.statut)
                        .withOpacity(isDark ? 0.4 : 0.3),
                  ),
                ),
                child: Text(
                  _getStatutLabel(s.statut, l10n),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: _getStatutColor(s.statut),
                  ),
                ),
              ),
            ),
          ),
          // Date
          SizedBox(
            width: colDate,
            child: Text(
              _formatDate(s.createdAt, l10n),
              style: TextStyle(
                color: AppTheme.getTextSecondary(context),
                fontSize: 13,
              ),
            ),
          ),
          // Actions - alignées à gauche
          SizedBox(
            width: colActions,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                IconButton(
                  onPressed: () => _showSignalementDetails(s, provider, l10n),
                  icon: Icon(
                    Icons.visibility_outlined,
                    size: 20,
                    color: AppTheme.getTextSecondary(context),
                  ),
                  tooltip: l10n.viewDetails,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
                const SizedBox(width: 8),
                PopupMenuButton<String>(
                  icon: Icon(
                    Icons.more_vert,
                    size: 20,
                    color: AppTheme.getTextSecondary(context),
                  ),
                  color: AppTheme.getCardBackground(context),
                  surfaceTintColor: AppTheme.getCardBackground(context),
                  itemBuilder: (context) => _buildActionMenu(s, isDark, l10n),
                  onSelected: (value) => _handleAction(value, s, provider, l10n),
                  padding: EdgeInsets.zero,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ==================== PAGINATION ====================

  Widget _buildPagination(SignalementAdminProvider provider, bool isDark, AppLocalizations l10n) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.grey.shade900.withOpacity(0.5)
            : const Color(0xFFF8FAFC),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(12),
          bottomRight: Radius.circular(12),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            l10n.totalReportsCount(provider.totalItems),
            style: TextStyle(
              color: AppTheme.getTextSecondary(context),
              fontSize: 13,
            ),
          ),
          Row(
            children: [
              IconButton(
                onPressed:
                provider.currentPage > 1 ? provider.loadPreviousPage : null,
                icon: const Icon(Icons.chevron_left),
                color: provider.currentPage > 1
                    ? Theme.of(context).colorScheme.primary
                    : AppTheme.getTextTertiary(context),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: AppTheme.getCardBackground(context),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppTheme.getBorderColor(context)),
                ),
                child: Text(
                  l10n.pageOf(provider.currentPage, provider.totalPages),
                  style: TextStyle(
                    color: AppTheme.getTextPrimary(context),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              IconButton(
                onPressed: provider.currentPage < provider.totalPages
                    ? provider.loadNextPage
                    : null,
                icon: const Icon(Icons.chevron_right),
                color: provider.currentPage < provider.totalPages
                    ? Theme.of(context).colorScheme.primary
                    : AppTheme.getTextTertiary(context),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ==================== ÉTATS VIDE / ERREUR ====================

  Widget _buildEmptyState(bool isDark, AppLocalizations l10n) {
    return Container(
      margin: const EdgeInsets.all(24),
      padding: const EdgeInsets.all(48),
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
      child: Center(
        child: Column(
          children: [
            Icon(
              Icons.warning_outlined,
              size: 80,
              color: AppTheme.getTextTertiary(context),
            ),
            const SizedBox(height: 24),
            Text(
              l10n.noReportsFound,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppTheme.getTextSecondary(context),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              l10n.adjustFiltersOrWait,
              style: TextStyle(color: AppTheme.getTextTertiary(context)),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _resetFilters,
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Colors.white,
              ),
              child: Text(l10n.resetFilters),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorWidget(String error, bool isDark, AppLocalizations l10n) {
    return Container(
      padding: const EdgeInsets.all(24),
      margin: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.red.shade900.withOpacity(0.1)
            : const Color(0xFFFEF2F2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? Colors.red.shade800 : const Color(0xFFFECACA),
        ),
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline,
              size: 48,
              color: Colors.red.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              l10n.loadingError,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.red.shade400,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              error,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: isDark ? Colors.red.shade300 : const Color(0xFF991B1B),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _refreshData,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.shade400,
                foregroundColor: Colors.white,
              ),
              child: Text(l10n.retry),
            ),
          ],
        ),
      ),
    );
  }

  // ==================== MENU CONTEXTUEL ====================

  List<PopupMenuEntry<String>> _buildActionMenu(Signalement s, bool isDark, AppLocalizations l10n) {
    final items = <PopupMenuEntry<String>>[
      PopupMenuItem(
        value: 'details',
        child: Row(
          children: [
            Icon(
              Icons.info_outline,
              size: 18,
              color: AppTheme.getTextSecondary(context),
            ),
            const SizedBox(width: 8),
            Text(
              l10n.fullDetails,
              style: TextStyle(color: AppTheme.getTextPrimary(context)),
            ),
          ],
        ),
      ),
    ];
    if (s.isEnAttente) {
      items.addAll([
        PopupMenuItem(
          value: 'prendre_en_charge',
          child: Row(
            children: [
              const Icon(Icons.build, size: 18, color: Color(0xFF3B82F6)),
              const SizedBox(width: 8),
              Text(
                l10n.takeCharge,
                style: TextStyle(color: AppTheme.getTextPrimary(context)),
              ),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'annuler',
          child: Row(
            children: [
              const Icon(Icons.cancel, size: 18, color: Color(0xFFEF4444)),
              const SizedBox(width: 8),
              Text(
                l10n.cancelReport,
                style: TextStyle(color: AppTheme.getTextPrimary(context)),
              ),
            ],
          ),
        ),
      ]);
    }
    if (s.isEnCours) {
      items.add(
        PopupMenuItem(
          value: 'resoudre',
          child: Row(
            children: [
              const Icon(Icons.check_circle, size: 18, color: Color(0xFF10B981)),
              const SizedBox(width: 8),
              Text(
                l10n.markAsResolved,
                style: TextStyle(color: AppTheme.getTextPrimary(context)),
              ),
            ],
          ),
        ),
      );
    }
    items.addAll([
      const PopupMenuDivider(),
      PopupMenuItem(
        value: 'photos',
        child: Row(
          children: [
            Icon(
              Icons.photo_library,
              size: 18,
              color: AppTheme.getTextSecondary(context),
            ),
            const SizedBox(width: 8),
            Text(
              l10n.viewPhotos,
              style: TextStyle(color: AppTheme.getTextPrimary(context)),
            ),
          ],
        ),
      ),
    ]);
    return items;
  }

  // ==================== DIALOGUE DÉTAILS ====================

  void _showSignalementDetails(Signalement s, SignalementAdminProvider provider, AppLocalizations l10n) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: AppTheme.getCardBackground(context),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        insetPadding: const EdgeInsets.symmetric(horizontal: 40, vertical: 40),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: 560,
            maxHeight: MediaQuery.of(context).size.height * 0.85,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
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
                      child: Icon(
                        Icons.info_outline,
                        color: Theme.of(context).colorScheme.primary,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l10n.reportDetails,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.getTextPrimary(context),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            s.numeroSuivi,
                            style: TextStyle(
                              fontSize: 12,
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
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _dlgSection(l10n.student, Icons.person),
                      const SizedBox(height: 10),
                      _dlgItem(l10n.fullName, s.displayEtudiantNomComplet),
                      if (s.matricule != null) _dlgItem(l10n.matricule, s.matricule!),
                      if (s.telephone != null) _dlgItem(l10n.phone, s.telephone!),
                      if (s.email != null) _dlgItem(l10n.email, s.email!),
                      const SizedBox(height: 16),
                      _dlgSection(l10n.localization, Icons.location_on),
                      const SizedBox(height: 10),
                      _dlgItem(
                        l10n.center,
                        '${s.nomCentre ?? "N/A"}${s.ville != null ? " (${s.ville})" : ""}',
                      ),
                      _dlgItem(
                        l10n.room,
                        '${s.numeroChambre ?? "N/A"} (${s.typeChambre ?? "Type inconnu"})',
                      ),
                      const SizedBox(height: 16),
                      _dlgSection(l10n.problem, Icons.warning_amber),
                      const SizedBox(height: 10),
                      _dlgItem(l10n.type, _getTypeLabel(s.typeProbleme, l10n)),
                      _dlgItem(l10n.descriptionLabel, s.description),
                      _dlgItem(l10n.statusLabel, _getStatutLabel(s.statut, l10n)),
                      _dlgItem(l10n.creationDate, _formatDate(s.createdAt, l10n)),
                      if (s.dateResolution != null)
                        _dlgItem(l10n.resolutionDate, _formatDate(s.dateResolution!, l10n)),
                      if (s.commentaireResolution != null)
                        _dlgItem(l10n.comment, s.commentaireResolution!),
                      if (s.photos.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        _dlgSection('${l10n.photosCount} (${s.photos.length})', Icons.photo_library),
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 12,
                          runSpacing: 12,
                          children: s.photos.map((url) {
                            final full = url.startsWith('http')
                                ? url
                                : '${AppConfig.staticBaseUrl}$url';
                            return ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.network(
                                full,
                                width: 100,
                                height: 100,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => Container(
                                  width: 100,
                                  height: 100,
                                  color: isDark
                                      ? Colors.grey.shade800
                                      : Colors.grey.shade200,
                                  child: Icon(
                                    Icons.broken_image,
                                    size: 32,
                                    color: AppTheme.getTextTertiary(context),
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const Divider(height: 1),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.grey.shade900.withOpacity(0.5)
                      : const Color(0xFFF8FAFC),
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(16),
                    bottomRight: Radius.circular(16),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text(
                        l10n.close,
                        style: TextStyle(color: AppTheme.getTextSecondary(context)),
                      ),
                    ),
                    if (s.isEnAttente) ...[
                      const SizedBox(width: 12),
                      ElevatedButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                          _updateStatus(s, 'EN_COURS', provider, l10n);
                        },
                        icon: const Icon(Icons.build, size: 18, color: Colors.white),
                        label: Text(
                          l10n.takeCharge,
                          style: const TextStyle(color: Colors.white),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Theme.of(context).colorScheme.primary,
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _dlgSection(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Theme.of(context).colorScheme.primary),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: AppTheme.getTextPrimary(context),
          ),
        ),
      ],
    );
  }

  Widget _dlgItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: AppTheme.getTextSecondary(context),
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              color: AppTheme.getTextPrimary(context),
            ),
          ),
        ],
      ),
    );
  }

  // ==================== DIALOGUE PHOTOS ====================

  void _showPhotos(Signalement s, AppLocalizations l10n) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: AppTheme.getCardBackground(context),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        insetPadding: const EdgeInsets.symmetric(horizontal: 40, vertical: 40),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: 480,
            maxHeight: MediaQuery.of(context).size.height * 0.8,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    Icon(
                      Icons.photo_library,
                      color: Theme.of(context).colorScheme.primary,
                      size: 22,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        l10n.viewPhotos,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.getTextPrimary(context),
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: Icon(
                        Icons.close,
                        color: AppTheme.getTextSecondary(context),
                      ),
                    ),
                  ],
                ),
              ),
              Divider(height: 1, color: AppTheme.getBorderColor(context)),
              Flexible(
                child: s.photos.isEmpty
                    ? Padding(
                  padding: const EdgeInsets.all(48),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.image_not_supported,
                        size: 64,
                        color: AppTheme.getTextTertiary(context),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        l10n.noPhotosAvailable,
                        style: TextStyle(
                          fontSize: 16,
                          color: AppTheme.getTextSecondary(context),
                        ),
                      ),
                    ],
                  ),
                )
                    : ListView.separated(
                  padding: const EdgeInsets.all(20),
                  shrinkWrap: true,
                  itemCount: s.photos.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 16),
                  itemBuilder: (context, index) {
                    final url = s.photos[index];
                    final full = url.startsWith('http')
                        ? url
                        : '${AppConfig.staticBaseUrl}$url';
                    return ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.network(
                        full,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          height: 200,
                          decoration: BoxDecoration(
                            color: isDark
                                ? Colors.grey.shade800
                                : Colors.grey.shade200,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Center(
                            child: Icon(
                              Icons.broken_image,
                              size: 48,
                              color: AppTheme.getTextTertiary(context),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              Divider(height: 1, color: AppTheme.getBorderColor(context)),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      l10n.photoCount(s.photos.length),
                      style: TextStyle(
                        color: AppTheme.getTextSecondary(context),
                        fontSize: 14,
                      ),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text(
                        l10n.close,
                        style: TextStyle(color: AppTheme.getTextSecondary(context)),
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

  // ==================== ACTIONS ====================

  Future<void> _handleAction(
      String action,
      Signalement s,
      SignalementAdminProvider provider,
      AppLocalizations l10n,
      ) async {
    switch (action) {
      case 'details':
        _showSignalementDetails(s, provider, l10n);
        break;
      case 'prendre_en_charge':
        await _updateStatus(s, 'EN_COURS', provider, l10n);
        break;
      case 'resoudre':
        await _updateStatus(s, 'RESOLU', provider, l10n);
        break;
      case 'annuler':
        await _updateStatus(s, 'ANNULE', provider, l10n);
        break;
      case 'photos':
        _showPhotos(s, l10n);
        break;
    }
  }

  Future<void> _updateStatus(
      Signalement s,
      String nouveauStatut,
      SignalementAdminProvider provider,
      AppLocalizations l10n,
      ) async {
    try {
      String? commentaire;
      if (nouveauStatut == 'RESOLU' || nouveauStatut == 'ANNULE') {
        commentaire = await _askForComment(
          nouveauStatut,
          Theme.of(context).brightness == Brightness.dark,
          l10n,
        );
        if (commentaire == null) return;
      }
      await provider.updateStatutSignalement(
        signalementId: s.id.toString(),
        nouveauStatut: nouveauStatut,
        commentaire: commentaire,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              l10n.reportStatusUpdated(_getStatutLabel(nouveauStatut, l10n)),
            ),
            backgroundColor: _getStatutColor(nouveauStatut),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${l10n.error}: ${e.toString()}'),
            backgroundColor: const Color(0xFFEF4444),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<String?> _askForComment(String statut, bool isDark, AppLocalizations l10n) async {
    final ctrl = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: AppTheme.getCardBackground(context),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        insetPadding: const EdgeInsets.symmetric(horizontal: 40, vertical: 40),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  statut == 'RESOLU'
                      ? l10n.resolutionComment
                      : l10n.cancellationReason,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.getTextPrimary(context),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: ctrl,
                  decoration: InputDecoration(
                    hintText: statut == 'RESOLU'
                        ? l10n.describeResolution
                        : l10n.indicateCancellationReason,
                    hintStyle: TextStyle(color: AppTheme.getTextSecondary(context)),
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
                    filled: true,
                    fillColor: isDark
                        ? Colors.grey.shade900.withOpacity(0.3)
                        : Colors.grey.shade50,
                  ),
                  maxLines: 4,
                  style: TextStyle(color: AppTheme.getTextPrimary(context)),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text(
                        l10n.cancel,
                        style: TextStyle(color: AppTheme.getTextSecondary(context)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton(
                      onPressed: () {
                        if (ctrl.text.trim().isNotEmpty) {
                          Navigator.pop(context, ctrl.text.trim());
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        foregroundColor: Colors.white,
                      ),
                      child: Text(l10n.validate),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
    ctrl.dispose();
    return result;
  }

  // ==================== FILTRES ====================

  Future<void> _applySearch(String query) async {
    await Provider.of<SignalementAdminProvider>(context, listen: false)
        .searchSignalements(query);
  }

  Future<void> _applyFilter(String key, dynamic value) async {
    await Provider.of<SignalementAdminProvider>(context, listen: false)
        .applyFilter(key, value);
  }

  Future<void> _applyAllFilters() async {
    await Provider.of<SignalementAdminProvider>(context, listen: false)
        .loadSignalements(resetPage: true);
  }

  Future<void> _resetFilters() async {
    setState(() {
      _searchController.clear();
      _selectedStatut = 'TOUS';
      _selectedType = 'TOUS';
      _selectedDateFrom = null;
      _selectedDateTo = null;
    });
    await Provider.of<SignalementAdminProvider>(context, listen: false)
        .resetFilters();
  }

  Future<void> _refreshData() async {
    if (_isRefreshing) return;
    setState(() => _isRefreshing = true);
    try {
      final l10n = AppLocalizations.of(context);
      final provider = Provider.of<SignalementAdminProvider>(context, listen: false);
      await Future.wait([provider.loadSignalements(), provider.loadStatistiques()]);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.dataRefreshed),
            backgroundColor: const Color(0xFF10B981),
            duration: const Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      final l10n = AppLocalizations.of(context);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${l10n.error}: $e'),
            backgroundColor: const Color(0xFFEF4444),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isRefreshing = false);
    }
  }

  // ==================== LIBELLÉS & COULEURS ====================

  String _getStatutLabel(String s, AppLocalizations l10n) {
    switch (s) {
      case 'EN_ATTENTE': return l10n.pendingStatus;
      case 'EN_COURS': return l10n.inProgressStatus;
      case 'RESOLU': return l10n.resolvedStatus;
      case 'ANNULE': return l10n.cancelledStatus;
      case 'TOUS': return l10n.all;
      default: return s;
    }
  }

  Color _getStatutColor(String s) {
    const map = {
      'EN_ATTENTE': Color(0xFFF59E0B),
      'EN_COURS': Color(0xFF3B82F6),
      'RESOLU': Color(0xFF10B981),
      'ANNULE': Color(0xFFEF4444),
    };
    return map[s] ?? const Color(0xFF64748B);
  }

  String _getTypeLabel(String t, AppLocalizations l10n) {
    switch (t) {
      case 'PLOMBERIE': return l10n.plumbing;
      case 'ELECTRICITE': return l10n.electricity;
      case 'TOITURE': return l10n.roofing;
      case 'SERRURE': return l10n.locks;
      case 'MOBILIER': return l10n.furniture;
      case 'AUTRE': return l10n.other;
      case 'TOUS': return l10n.all;
      default: return t;
    }
  }

  Color _getTypeColor(String t) {
    const map = {
      'PLOMBERIE': Color(0xFF3B82F6),
      'ELECTRICITE': Color(0xFFF59E0B),
      'TOITURE': Color(0xFF8B5CF6),
      'SERRURE': Color(0xFFEF4444),
      'MOBILIER': Color(0xFF10B981),
      'AUTRE': Color(0xFF64748B),
    };
    return map[t] ?? const Color(0xFF64748B);
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// _HScrollBarDelegate — barre de scroll horizontal sticky
// ═══════════════════════════════════════════════════════════════════════════

class _HScrollBarDelegate extends SliverPersistentHeaderDelegate {
  final ScrollController hScrollCtrl;
  final bool isDark;

  const _HScrollBarDelegate({
    required this.hScrollCtrl,
    required this.isDark,
  });

  static const double _barHeight = 48.0;

  @override double get minExtent => _barHeight;
  @override double get maxExtent => _barHeight;

  @override
  bool shouldRebuild(_HScrollBarDelegate old) =>
      old.isDark != isDark || old.hScrollCtrl != hScrollCtrl;

  void _nudge(double delta) {
    if (!hScrollCtrl.hasClients) return;
    final target = (hScrollCtrl.offset + delta).clamp(
      0.0,
      hScrollCtrl.position.maxScrollExtent,
    );
    hScrollCtrl.animateTo(
      target,
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOut,
    );
  }

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    final isDarkCtx = Theme.of(context).brightness == Brightness.dark;
    final primary   = Theme.of(context).colorScheme.primary;

    return Container(
      height: _barHeight,
      decoration: BoxDecoration(
        color: isDarkCtx ? const Color(0xFF1A1A2E) : const Color(0xFFF0F4FF),
        border: Border(
          top:    BorderSide(color: AppTheme.getBorderColor(context)),
          bottom: BorderSide(color: AppTheme.getBorderColor(context)),
        ),
        boxShadow: overlapsContent
            ? [BoxShadow(
          color:  Colors.black.withOpacity(isDarkCtx ? 0.2 : 0.08),
          offset: const Offset(0, 3),
          blurRadius: 6,
        )]
            : null,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Row(children: [
          Icon(Icons.swap_horiz_rounded, size: 18, color: primary),
          const SizedBox(width: 10),
          Expanded(
            child: AnimatedBuilder(
              animation: hScrollCtrl,
              builder: (context, _) {
                double progress = 0.0;
                if (hScrollCtrl.hasClients) {
                  final max = hScrollCtrl.position.maxScrollExtent;
                  if (max > 0) {
                    progress = (hScrollCtrl.offset / max).clamp(0.0, 1.0);
                  }
                }
                return Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Scroll horizontal',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                        letterSpacing: 0.4,
                        color: isDarkCtx
                            ? Colors.white38
                            : Colors.black38,
                      ),
                    ),
                    const SizedBox(height: 4),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: progress,
                        minHeight: 5,
                        backgroundColor: isDarkCtx
                            ? Colors.white12
                            : Colors.black.withOpacity(0.08),
                        valueColor: AlwaysStoppedAnimation<Color>(primary),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
          const SizedBox(width: 10),
          _ArrowBtn(
            icon:      Icons.chevron_left,
            tooltip:   'Défiler à gauche',
            onPressed: () => _nudge(-160),
          ),
          const SizedBox(width: 4),
          _ArrowBtn(
            icon:      Icons.chevron_right,
            tooltip:   'Défiler à droite',
            onPressed: () => _nudge(160),
          ),
        ]),
      ),
    );
  }
}

class _ArrowBtn extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;
  const _ArrowBtn({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 30,
      height: 30,
      child: IconButton(
        padding:   EdgeInsets.zero,
        icon:      Icon(icon, size: 20),
        color:     Theme.of(context).colorScheme.primary,
        onPressed: onPressed,
        tooltip:   tooltip,
      ),
    );
  }
}