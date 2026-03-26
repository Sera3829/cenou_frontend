import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:cenou_mobile/providers/web/signalement_admin_provider.dart';
import 'package:cenou_mobile/models/signalement.dart';
import 'package:cenou_mobile/config/theme.dart';
import 'package:cenou_mobile/services/api_service.dart';
import '../../../config/app_config.dart';
import '../dashboard/dashboard_screen.dart';

/// Écran d'administration des signalements.
///
/// Permet de consulter, filtrer et gérer les signalements des étudiants.
class SignalementAdminScreen extends StatefulWidget {
  const SignalementAdminScreen({Key? key}) : super(key: key);

  @override
  State<SignalementAdminScreen> createState() => _SignalementAdminScreenState();
}

class _SignalementAdminScreenState extends State<SignalementAdminScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedStatut = 'TOUS';
  String _selectedType = 'TOUS';
  DateTime? _selectedDateFrom;
  DateTime? _selectedDateTo;
  bool _showFilters = true;
  bool _isRefreshing = false;

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

  /// Charge les signalements et les statistiques initiales.
  Future<void> _loadInitialData() async {
    final provider = Provider.of<SignalementAdminProvider>(context, listen: false);
    await Future.wait([
      provider.loadSignalements(),
      provider.loadStatistiques(),
    ]);
  }

  /// Formate une date avec l'heure.
  String _formatDate(DateTime date) => DateFormat('dd/MM/yyyy HH:mm').format(date);

  /// Formate une date sans l'heure.
  String _formatDateOnly(DateTime date) => DateFormat('dd/MM/yyyy').format(date);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return DashboardLayout(
      selectedIndex: 2,
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
    return Consumer<SignalementAdminProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading && provider.signalements.isEmpty) {
          return Center(
            child: CircularProgressIndicator(color: Theme.of(context).colorScheme.primary),
          );
        }

        if (provider.error != null && provider.signalements.isEmpty) {
          return _buildErrorWidget(provider.error!, isDark);
        }

        if (provider.signalements.isEmpty) {
          return _buildEmptyState(isDark);
        }

        return CustomScrollView(
          slivers: [
            SliverToBoxAdapter(child: _buildQuickStats(isDark)),
            SliverToBoxAdapter(
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                height: _showFilters ? null : 0,
                child: _showFilters ? _buildFiltersCard(isDark) : const SizedBox.shrink(),
              ),
            ),
            SliverToBoxAdapter(child: _buildSignalementsTableHeader(isDark)),
            _buildSignalementsList(provider, isDark),
            SliverToBoxAdapter(child: _buildPagination(provider, isDark)),
          ],
        );
      },
    );
  }

  /// Barre flottante des filtres principaux (recherche, statut, type).
  Widget _buildFloatingFiltersBar(bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
      decoration: BoxDecoration(
        color: AppTheme.getTopBarBackground(context),
        border: Border(bottom: BorderSide(color: AppTheme.getBorderColor(context), width: 1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Rechercher étudiant, numéro de suivi, description...',
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
            value: _selectedStatut,
            label: 'Statut',
            items: ['TOUS', 'EN_ATTENTE', 'EN_COURS', 'RESOLU', 'ANNULE'],
            onChanged: (value) {
              setState(() => _selectedStatut = value!);
              _applyFilter('statut', value == 'TOUS' ? null : value);
            },
            labelBuilder: _getStatutLabel,
            isDark: isDark,
          ),
          const SizedBox(width: 12),
          _buildFilterDropdown(
            value: _selectedType,
            label: 'Type',
            items: ['TOUS', 'PLOMBERIE', 'ELECTRICITE', 'TOITURE', 'SERRURE', 'MOBILIER', 'AUTRE'],
            onChanged: (value) {
              setState(() => _selectedType = value!);
              _applyFilter('type', value == 'TOUS' ? null : value);
            },
            labelBuilder: _getTypeLabel,
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
          ElevatedButton.icon(
            onPressed: _isRefreshing ? null : _refreshData,
            icon: _isRefreshing
                ? SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            )
                : Icon(Icons.refresh, size: 18, color: Colors.white),
            label: _isRefreshing
                ? Text('Actualisation...', style: TextStyle(color: Colors.white))
                : Text('Actualiser', style: TextStyle(color: Colors.white)),
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
    required String Function(String) labelBuilder,
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
            labelBuilder(item),
            style: TextStyle(fontSize: 14, color: AppTheme.getTextPrimary(context)),
          ),
        )).toList(),
        onChanged: onChanged,
        style: TextStyle(color: AppTheme.getTextPrimary(context)),
      ),
    );
  }

  /// Section des indicateurs rapides (statistiques).
  Widget _buildQuickStats(bool isDark) {
    return Consumer<SignalementAdminProvider>(
      builder: (context, provider, child) {
        final stats = provider.statistiques ?? {};
        return Container(
          padding: const EdgeInsets.all(24),
          color: isDark ? Colors.grey.shade900.withOpacity(0.5) : const Color(0xFFF1F5F9),
          child: Row(
            children: [
              _buildStatCard(
                label: 'Total Signalements',
                value: '${stats['total'] ?? 0}',
                color: const Color(0xFF3B82F6),
                icon: Icons.warning,
                isDark: isDark,
              ),
              const SizedBox(width: 16),
              _buildStatCard(
                label: 'En Attente',
                value: '${stats['en_attente'] ?? 0}',
                color: const Color(0xFFF59E0B),
                icon: Icons.hourglass_empty,
                isDark: isDark,
              ),
              const SizedBox(width: 16),
              _buildStatCard(
                label: 'En Cours',
                value: '${stats['en_cours'] ?? 0}',
                color: const Color(0xFF3B82F6),
                icon: Icons.build,
                isDark: isDark,
              ),
              const SizedBox(width: 16),
              _buildStatCard(
                label: 'Taux Résolution',
                value: '${(stats['taux_resolution'] ?? 0).toStringAsFixed(1)}%',
                color: const Color(0xFF10B981),
                icon: Icons.check_circle,
                isDark: isDark,
              ),
            ],
          ),
        );
      },
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
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: color),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    label,
                    style: TextStyle(fontSize: 13, color: AppTheme.getTextSecondary(context)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Carte des filtres avancés (dates).
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
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.getTextPrimary(context)),
              ),
              const Spacer(),
              TextButton.icon(
                onPressed: () => setState(() => _showFilters = false),
                icon: Icon(Icons.close, size: 16, color: AppTheme.getTextSecondary(context)),
                label: Text('Fermer', style: TextStyle(color: AppTheme.getTextSecondary(context))),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildDatePicker(
                  label: 'Date début',
                  selectedDate: _selectedDateFrom,
                  onDateSelected: (date) {
                    setState(() => _selectedDateFrom = date);
                    _applyFilter('date_from', date);
                  },
                  isDark: isDark,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildDatePicker(
                  label: 'Date fin',
                  selectedDate: _selectedDateTo,
                  onDateSelected: (date) {
                    setState(() => _selectedDateTo = date);
                    _applyFilter('date_to', date);
                  },
                  isDark: isDark,
                ),
              ),
              const SizedBox(width: 16),
              ElevatedButton.icon(
                onPressed: _applyAllFilters,
                icon: Icon(Icons.check, size: 18, color: Colors.white),
                label: Text('Appliquer', style: TextStyle(color: Colors.white)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Sélecteur de date.
  Widget _buildDatePicker({
    required String label,
    required DateTime? selectedDate,
    required ValueChanged<DateTime> onDateSelected,
    required bool isDark,
  }) {
    return InkWell(
      onTap: () async {
        final date = await showDatePicker(
          context: context,
          initialDate: selectedDate ?? DateTime.now(),
          firstDate: DateTime(2020),
          lastDate: DateTime.now(),
          builder: (context, child) {
            return Theme(
              data: Theme.of(context).copyWith(
                colorScheme: ColorScheme.light(
                  primary: Theme.of(context).colorScheme.primary,
                  onPrimary: Colors.white,
                  surface: AppTheme.getCardBackground(context),
                  onSurface: AppTheme.getTextPrimary(context),
                ),
                dialogBackgroundColor: AppTheme.getCardBackground(context),
              ),
              child: child!,
            );
          },
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
          fillColor: isDark ? Colors.grey.shade900.withOpacity(0.3) : Colors.grey.shade50,
          suffixIcon: Icon(Icons.calendar_today, size: 18, color: AppTheme.getTextSecondary(context)),
        ),
        child: Text(
          selectedDate != null ? _formatDateOnly(selectedDate) : 'Sélectionner',
          style: TextStyle(
            color: selectedDate != null
                ? AppTheme.getTextPrimary(context)
                : AppTheme.getTextSecondary(context),
          ),
        ),
      ),
    );
  }

  /// En‑tête du tableau des signalements.
  Widget _buildSignalementsTableHeader(bool isDark) {
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
          Expanded(flex: 2, child: _HeaderText('Étudiant / Signalement', isDark)),
          Expanded(flex: 2, child: _HeaderText('Description', isDark)),
          Expanded(child: _HeaderText('Type', isDark)),
          Expanded(child: _HeaderText('Statut', isDark)),
          Expanded(child: _HeaderText('Date', isDark)),
          const SizedBox(width: 100),
        ],
      ),
    );
  }

  /// Liste des signalements.
  Widget _buildSignalementsList(SignalementAdminProvider provider, bool isDark) {
    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(32, 0, 32, 24),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
              (context, index) => _buildSignalementRow(
              provider.signalements[index],
              provider,
              index,
              isDark
          ),
          childCount: provider.signalements.length,
        ),
      ),
    );
  }

  /// Ligne d’un signalement dans la liste.
  Widget _buildSignalementRow(
      Signalement signalement,
      SignalementAdminProvider provider,
      int index,
      bool isDark
      ) {
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
          Expanded(flex: 2, child: _buildEtudiantInfo(signalement)),
          Expanded(flex: 2, child: _buildDescription(signalement)),
          Expanded(child: _buildTypeBadge(signalement.typeProbleme, isDark)),
          Expanded(child: _buildStatutBadge(signalement.statut, isDark)),
          Expanded(
            child: Text(
              _formatDate(signalement.createdAt),
              style: TextStyle(color: AppTheme.getTextSecondary(context), fontSize: 13),
            ),
          ),
          SizedBox(width: 100, child: _buildActions(signalement, provider, isDark)),
        ],
      ),
    );
  }

  /// Affiche les informations de l’étudiant.
  Widget _buildEtudiantInfo(Signalement signalement) {
    final nomComplet = signalement.displayEtudiantNomComplet;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          nomComplet,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: AppTheme.getTextPrimary(context),
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          signalement.matricule ?? 'N/A',
          style: TextStyle(fontSize: 12, color: AppTheme.getTextSecondary(context)),
        ),
        const SizedBox(height: 4),
        Text(
          signalement.numeroSuivi,
          style: TextStyle(fontSize: 11, color: AppTheme.getTextTertiary(context)),
        ),
        if (signalement.numeroChambre != null && signalement.nomCentre != null) ...[
          const SizedBox(height: 2),
          Text(
            '${signalement.nomCentre} - Ch. ${signalement.numeroChambre!}',
            style: TextStyle(fontSize: 11, color: AppTheme.getTextTertiary(context)),
          ),
        ],
      ],
    );
  }

  /// Affiche la description du signalement.
  Widget _buildDescription(Signalement signalement) {
    return Text(
      signalement.description.length > 100
          ? '${signalement.description.substring(0, 100)}...'
          : signalement.description,
      style: TextStyle(color: AppTheme.getTextSecondary(context), fontSize: 13),
      maxLines: 3,
      overflow: TextOverflow.ellipsis,
    );
  }

  /// Badge du type de problème.
  Widget _buildTypeBadge(String type, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: _getTypeColor(type).withOpacity(isDark ? 0.2 : 0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        _getTypeLabel(type),
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: _getTypeColor(type),
        ),
      ),
    );
  }

  /// Badge du statut.
  Widget _buildStatutBadge(String statut, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: _getStatutColor(statut).withOpacity(isDark ? 0.2 : 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
            color: _getStatutColor(statut).withOpacity(isDark ? 0.4 : 0.3),
            width: 1
        ),
      ),
      child: Text(
        _getStatutLabel(statut),
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: _getStatutColor(statut),
        ),
      ),
    );
  }

  /// Actions disponibles (menu contextuel).
  Widget _buildActions(Signalement signalement, SignalementAdminProvider provider, bool isDark) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        IconButton(
          onPressed: () => _showSignalementDetails(signalement, provider),
          icon: Icon(Icons.visibility_outlined, size: 20, color: AppTheme.getTextSecondary(context)),
          tooltip: 'Voir détails',
        ),
        PopupMenuButton<String>(
          icon: Icon(Icons.more_vert, size: 20, color: AppTheme.getTextSecondary(context)),
          color: AppTheme.getCardBackground(context),
          surfaceTintColor: AppTheme.getCardBackground(context),
          itemBuilder: (context) => _buildActionMenu(signalement, isDark),
          onSelected: (value) => _handleAction(value, signalement, provider),
        ),
      ],
    );
  }

  /// Menu contextuel d’un signalement.
  List<PopupMenuEntry<String>> _buildActionMenu(Signalement signalement, bool isDark) {
    final items = <PopupMenuEntry<String>>[
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
    ];

    if (signalement.isEnAttente) {
      items.addAll([
        PopupMenuItem(
          value: 'prendre_en_charge',
          child: Row(
            children: [
              Icon(Icons.build, size: 18, color: const Color(0xFF3B82F6)),
              const SizedBox(width: 8),
              Text(
                'Prendre en charge',
                style: TextStyle(color: AppTheme.getTextPrimary(context)),
              ),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'annuler',
          child: Row(
            children: [
              Icon(Icons.cancel, size: 18, color: const Color(0xFFEF4444)),
              const SizedBox(width: 8),
              Text(
                'Annuler le signalement',
                style: TextStyle(color: AppTheme.getTextPrimary(context)),
              ),
            ],
          ),
        ),
      ]);
    }

    if (signalement.isEnCours) {
      items.add(
        PopupMenuItem(
          value: 'resoudre',
          child: Row(
            children: [
              Icon(Icons.check_circle, size: 18, color: const Color(0xFF10B981)),
              const SizedBox(width: 8),
              Text(
                'Marquer comme résolu',
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
            Icon(Icons.photo_library, size: 18, color: AppTheme.getTextSecondary(context)),
            const SizedBox(width: 8),
            Text(
              'Voir les photos',
              style: TextStyle(color: AppTheme.getTextPrimary(context)),
            ),
          ],
        ),
      ),
    ]);

    return items;
  }

  /// Barre de pagination.
  Widget _buildPagination(SignalementAdminProvider provider, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(20),
      margin: const EdgeInsets.fromLTRB(32, 0, 32, 24),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey.shade900.withOpacity(0.5) : const Color(0xFFF8FAFC),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(12),
          bottomRight: Radius.circular(12),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Total: ${provider.totalItems} signalements',
            style: TextStyle(color: AppTheme.getTextSecondary(context), fontSize: 13),
          ),
          Row(
            children: [
              IconButton(
                onPressed: provider.currentPage > 1 ? provider.loadPreviousPage : null,
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
                  'Page ${provider.currentPage} / ${provider.totalPages}',
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
                Icons.warning_outlined,
                size: 80,
                color: AppTheme.getTextTertiary(context)
            ),
            const SizedBox(height: 24),
            Text(
              'Aucun signalement trouvé',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppTheme.getTextSecondary(context),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Ajustez vos filtres ou attendez de nouveaux signalements',
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
          ],
        ),
      ),
    );
  }

  /// Affiche un message d’erreur en cas de problème de chargement.
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
              child: const Text('Réessayer'),
            ),
          ],
        ),
      ),
    );
  }

  /// Exécute l’action sélectionnée dans le menu contextuel.
  Future<void> _handleAction(
      String action,
      Signalement signalement,
      SignalementAdminProvider provider,
      ) async {
    switch (action) {
      case 'details':
        _showSignalementDetails(signalement, provider);
        break;
      case 'prendre_en_charge':
        await _updateSignalementStatus(signalement, 'EN_COURS', provider);
        break;
      case 'resoudre':
        await _updateSignalementStatus(signalement, 'RESOLU', provider);
        break;
      case 'annuler':
        await _updateSignalementStatus(signalement, 'ANNULE', provider);
        break;
      case 'photos':
        _showPhotos(signalement);
        break;
    }
  }

  /// Met à jour le statut d’un signalement.
  Future<void> _updateSignalementStatus(
      Signalement signalement,
      String nouveauStatut,
      SignalementAdminProvider provider,
      ) async {
    try {
      String? commentaire;
      final isDark = Theme.of(context).brightness == Brightness.dark;

      if (nouveauStatut == 'RESOLU' || nouveauStatut == 'ANNULE') {
        commentaire = await _askForComment(nouveauStatut, isDark);
        if (commentaire == null) return;
      }

      await provider.updateStatutSignalement(
        signalementId: signalement.id.toString(),
        nouveauStatut: nouveauStatut,
        commentaire: commentaire,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Signalement ${_getStatutLabel(nouveauStatut).toLowerCase()} avec succès'),
            backgroundColor: _getStatutColor(nouveauStatut),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: ${e.toString()}'),
            backgroundColor: const Color(0xFFEF4444),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  /// Demande un commentaire pour la résolution ou l’annulation.
  Future<String?> _askForComment(String statut, bool isDark) async {
    final controller = TextEditingController();

    final result = await showDialog<String>(
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
                statut == 'RESOLU' ? 'Commentaire de résolution' : 'Raison de l\'annulation',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.getTextPrimary(context),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: controller,
                decoration: InputDecoration(
                  hintText: statut == 'RESOLU'
                      ? 'Décrivez comment le problème a été résolu...'
                      : 'Indiquez la raison de l\'annulation...',
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
                    borderSide: BorderSide(color: Theme.of(context).colorScheme.primary, width: 2),
                  ),
                  filled: true,
                  fillColor: isDark ? Colors.grey.shade900.withOpacity(0.3) : Colors.grey.shade50,
                ),
                maxLines: 4,
                style: TextStyle(color: AppTheme.getTextPrimary(context)),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(
                      'Annuler',
                      style: TextStyle(color: AppTheme.getTextSecondary(context)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: () {
                      if (controller.text.trim().isNotEmpty) {
                        Navigator.pop(context, controller.text.trim());
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Valider'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );

    controller.dispose();
    return result;
  }

  /// Affiche une boîte de dialogue détaillée du signalement.
  void _showSignalementDetails(Signalement signalement, SignalementAdminProvider provider) {
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
            maxWidth: 700,
            maxHeight: MediaQuery.of(context).size.height * 0.9,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // En-tête
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
                        Icons.info_outline,
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
                            'Détails du signalement',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.getTextPrimary(context),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            signalement.numeroSuivi,
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
                      // Informations étudiant
                      _buildSectionHeader('Informations étudiant', Icons.person),
                      const SizedBox(height: 12),
                      _buildInfoGrid([
                        ('Nom complet', signalement.displayEtudiantNomComplet),
                        if (signalement.matricule != null)
                          ('Matricule', signalement.matricule!),
                        if (signalement.telephone != null)
                          ('Téléphone', signalement.telephone!),
                        if (signalement.email != null)
                          ('Email', signalement.email!),
                      ]),

                      const SizedBox(height: 24),

                      // Localisation
                      _buildSectionHeader('Localisation', Icons.location_on),
                      const SizedBox(height: 12),
                      _buildInfoGrid([
                        (
                        'Centre',
                        '${signalement.nomCentre ?? "N/A"} ${signalement.ville != null ? "(${signalement.ville})" : ""}',
                        ),
                        (
                        'Chambre',
                        '${signalement.numeroChambre ?? "N/A"} (${signalement.typeChambre ?? "Type inconnu"})',
                        ),
                      ]),

                      const SizedBox(height: 24),

                      // Détails du problème
                      _buildSectionHeader('Détails du problème', Icons.warning_amber),
                      const SizedBox(height: 12),
                      _buildDetailItem('Type de problème', _getTypeLabel(signalement.typeProbleme)),
                      _buildDetailItem('Description', signalement.description),
                      _buildDetailItem('Statut', _getStatutLabel(signalement.statut)),
                      _buildDetailItem('Date création', _formatDate(signalement.createdAt)),
                      if (signalement.dateResolution != null)
                        _buildDetailItem('Date résolution', _formatDate(signalement.dateResolution!)),
                      if (signalement.commentaireResolution != null)
                        _buildDetailItem('Commentaire', signalement.commentaireResolution!),

                      // Photos
                      if (signalement.photos.isNotEmpty) ...[
                        const SizedBox(height: 24),
                        _buildSectionHeader('Photos (${signalement.photos.length})', Icons.photo_library),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 12,
                          runSpacing: 12,
                          children: signalement.photos.map((photoUrl) {
                            return ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.network(
                                '${AppConfig.staticBaseUrl}$photoUrl',
                                width: 100,
                                height: 100,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return Container(
                                    width: 100,
                                    height: 100,
                                    color: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
                                    child: Icon(
                                      Icons.broken_image,
                                      size: 32,
                                      color: AppTheme.getTextTertiary(context),
                                    ),
                                  );
                                },
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                    ],
                  ),
                ),
              ),

              // Pied de dialogue avec actions
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
                    if (signalement.isEnAttente) ...[
                      const SizedBox(width: 12),
                      ElevatedButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                          _updateSignalementStatus(signalement, 'EN_COURS', provider);
                        },
                        icon: Icon(Icons.build, size: 18, color: Colors.white),
                        label: Text('Prendre en charge', style: TextStyle(color: Colors.white)),
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

  // Méthodes utilitaires pour les cartes de détails

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
          width: 300,
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
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(fontSize: 16, color: AppTheme.getTextPrimary(context)),
          ),
        ],
      ),
    );
  }

  /// Affiche la galerie de photos.
  void _showPhotos(Signalement signalement) {
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
            maxHeight: MediaQuery.of(context).size.height * 0.8,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // En‑tête
              Padding(
                padding: const EdgeInsets.all(24),
                child: Row(
                  children: [
                    Icon(
                      Icons.photo_library,
                      color: Theme.of(context).colorScheme.primary,
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Photos du signalement',
                        style: TextStyle(
                          fontSize: 20,
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
                      tooltip: 'Fermer',
                    ),
                  ],
                ),
              ),

              Divider(height: 1, color: AppTheme.getBorderColor(context)),

              // Contenu scrollable
              Flexible(
                child: signalement.photos.isEmpty
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
                        'Aucune photo disponible',
                        style: TextStyle(
                          fontSize: 16,
                          color: AppTheme.getTextSecondary(context),
                        ),
                      ),
                    ],
                  ),
                )
                    : ListView.separated(
                  padding: const EdgeInsets.all(24),
                  shrinkWrap: true,
                  itemCount: signalement.photos.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 16),
                  itemBuilder: (context, index) {
                    final photoUrl = signalement.photos[index];
                    return ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.network(
                        '${AppConfig.staticBaseUrl}$photoUrl',
                        fit: BoxFit.cover,
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return Container(
                            height: 200,
                            color: isDark
                                ? Colors.grey.shade800
                                : Colors.grey.shade200,
                            child: Center(
                              child: CircularProgressIndicator(
                                value: loadingProgress.expectedTotalBytes != null
                                    ? loadingProgress.cumulativeBytesLoaded /
                                    loadingProgress.expectedTotalBytes!
                                    : null,
                              ),
                            ),
                          );
                        },
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            height: 200,
                            decoration: BoxDecoration(
                              color: isDark
                                  ? Colors.grey.shade800
                                  : Colors.grey.shade200,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.broken_image,
                                  size: 48,
                                  color: AppTheme.getTextTertiary(context),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Image non disponible',
                                  style: TextStyle(
                                    color: AppTheme.getTextSecondary(context),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    );
                  },
                ),
              ),

              Divider(height: 1, color: AppTheme.getBorderColor(context)),

              // Pied
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${signalement.photos.length} photo${signalement.photos.length > 1 ? 's' : ''}',
                      style: TextStyle(
                        color: AppTheme.getTextSecondary(context),
                        fontSize: 14,
                      ),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text(
                        'Fermer',
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

  // Méthodes d’affichage des libellés et couleurs

  String _getStatutLabel(String statut) {
    const statutLabels = {
      'EN_ATTENTE': 'En attente',
      'EN_COURS': 'En cours',
      'RESOLU': 'Résolu',
      'ANNULE': 'Annulé',
      'TOUS': 'Tous',
    };
    return statutLabels[statut] ?? statut;
  }

  Color _getStatutColor(String statut) {
    const statutColors = {
      'EN_ATTENTE': Color(0xFFF59E0B),
      'EN_COURS': Color(0xFF3B82F6),
      'RESOLU': Color(0xFF10B981),
      'ANNULE': Color(0xFFEF4444),
    };
    return statutColors[statut] ?? const Color(0xFF64748B);
  }

  String _getTypeLabel(String type) {
    const typeLabels = {
      'PLOMBERIE': 'Plomberie',
      'ELECTRICITE': 'Électricité',
      'TOITURE': 'Toiture',
      'SERRURE': 'Serrure',
      'MOBILIER': 'Mobilier',
      'AUTRE': 'Autre',
      'TOUS': 'Tous',
    };
    return typeLabels[type] ?? type;
  }

  Color _getTypeColor(String type) {
    const typeColors = {
      'PLOMBERIE': Color(0xFF3B82F6),
      'ELECTRICITE': Color(0xFFF59E0B),
      'TOITURE': Color(0xFF8B5CF6),
      'SERRURE': Color(0xFFEF4444),
      'MOBILIER': Color(0xFF10B981),
      'AUTRE': Color(0xFF64748B),
    };
    return typeColors[type] ?? const Color(0xFF64748B);
  }

  // Actions sur les filtres

  Future<void> _applySearch(String query) async {
    final provider = Provider.of<SignalementAdminProvider>(context, listen: false);
    await provider.searchSignalements(query);
  }

  Future<void> _applyFilter(String key, dynamic value) async {
    final provider = Provider.of<SignalementAdminProvider>(context, listen: false);
    await provider.applyFilter(key, value);
  }

  Future<void> _applyAllFilters() async {
    final provider = Provider.of<SignalementAdminProvider>(context, listen: false);
    await provider.loadSignalements(resetPage: true);
  }

  Future<void> _resetFilters() async {
    setState(() {
      _searchController.clear();
      _selectedStatut = 'TOUS';
      _selectedType = 'TOUS';
      _selectedDateFrom = null;
      _selectedDateTo = null;
    });

    final provider = Provider.of<SignalementAdminProvider>(context, listen: false);
    await provider.resetFilters();
  }

  Future<void> _refreshData() async {
    if (_isRefreshing) return;

    setState(() {
      _isRefreshing = true;
    });

    try {
      final provider = Provider.of<SignalementAdminProvider>(context, listen: false);
      await Future.wait([
        provider.loadSignalements(),
        provider.loadStatistiques(),
      ]);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Données actualisées avec succès'),
            backgroundColor: Color(0xFF10B981),
            duration: Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de l\'actualisation: $e'),
            backgroundColor: const Color(0xFFEF4444),
            duration: const Duration(seconds: 3),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isRefreshing = false;
        });
      }
    }
  }
}

/// Widget utilitaire pour les en‑têtes de colonnes du tableau.
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