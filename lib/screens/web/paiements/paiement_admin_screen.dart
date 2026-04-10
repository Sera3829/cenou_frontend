// ─────────────────────────────────────────────────────────────────────────────
// FICHIER : lib/screens/web/paiements/paiement_admin_screen.dart
//
// SEUL CHANGEMENT : méthode build() + _buildPaiementsList() refactorisés
// pour utiliser un CustomScrollView avec SliverPersistentHeader(pinned: true).
//
// Toute la logique métier (filtres, actions, stats, pagination, dialogs)
// est INCHANGÉE — seul le layout de la section tableau est modifié.
// ─────────────────────────────────────────────────────────────────────────────

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart' show kIsWeb;
import '../../../providers/web/paiement_admin_provider.dart';
import 'package:cenou_mobile/models/paiement.dart';
import 'package:cenou_mobile/config/theme.dart';
import 'package:cenou_mobile/services/api_service.dart';
import 'export_preview_screen.dart';
import '../../../utils/html_utils.dart';
import '../dashboard/dashboard_screen.dart';
import '../../../l10n/app_localizations.dart';

class PaiementAdminScreen extends StatefulWidget {
  const PaiementAdminScreen({Key? key}) : super(key: key);

  @override
  State<PaiementAdminScreen> createState() => _PaiementAdminScreenState();
}

class _PaiementAdminScreenState extends State<PaiementAdminScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedStatut = 'TOUS';
  String _selectedMode   = 'TOUS';
  DateTime? _selectedDateFrom;
  DateTime? _selectedDateTo;
  bool _showFilters = true;

  // ScrollController partagé entre le CustomScrollView et la barre sticky
  final ScrollController _scrollController = ScrollController();
  // ScrollController du tableau horizontal (barre sticky + tableau partagent le même)
  final ScrollController _tableHScrollCtrl = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadInitialData());
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _tableHScrollCtrl.dispose();
    _searchController.dispose();
    super.dispose();
  }

  String _formatMontant(double montant, AppLocalizations l10n) {
    final formatter = NumberFormat('#,##0', l10n.locale.languageCode);
    return formatter.format(montant);
  }

  Future<void> _loadInitialData() async {
    final provider = Provider.of<PaiementAdminProvider>(context, listen: false);
    await provider.loadPaiements();
    await provider.loadStatistiques();
  }

  // ── BUILD ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final l10n  = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return DashboardLayout(
      selectedIndex: 1,
      child: Column(
        children: [
          // ① Barre de filtres rapides (fixe en haut, hors scroll)
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
                      AnimatedSize(
                        duration: const Duration(milliseconds: 300),
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
                  child: _buildPaiementsList(isDark, l10n),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── BARRE DE FILTRES (inchangée) ─────────────────────────────────────────

  Widget _buildFloatingFiltersBar(bool isDark, AppLocalizations l10n) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isWide = screenWidth > 1100;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      decoration: BoxDecoration(
        color: AppTheme.getTopBarBackground(context),
        border: Border(
            bottom: BorderSide(color: AppTheme.getBorderColor(context))),
      ),
      child: isWide
          ? Row(children: [
        Expanded(flex: 3, child: _buildSearchField(isDark, l10n)),
        const SizedBox(width: 12),
        SizedBox(width: 160, child: _buildStatutDropdown(isDark, l10n)),
        const SizedBox(width: 12),
        SizedBox(width: 160, child: _buildModeDropdown(isDark, l10n)),
        const SizedBox(width: 12),
        _buildFilterButtons(l10n),
      ])
          : Column(children: [
        _buildSearchField(isDark, l10n),
        const SizedBox(height: 8),
        Row(children: [
          Expanded(child: _buildStatutDropdown(isDark, l10n)),
          const SizedBox(width: 8),
          Expanded(child: _buildModeDropdown(isDark, l10n)),
          const SizedBox(width: 8),
          _buildFilterButtons(l10n),
        ]),
      ]),
    );
  }

  Widget _buildSearchField(bool isDark, AppLocalizations l10n) {
    return TextField(
      controller: _searchController,
      decoration: InputDecoration(
        hintText: l10n.searchStudentReference,
        prefixIcon: Icon(Icons.search, size: 20,
            color: AppTheme.getTextSecondary(context)),
        suffixIcon: _searchController.text.isNotEmpty
            ? IconButton(
          icon: Icon(Icons.clear, size: 20,
              color: AppTheme.getTextSecondary(context)),
          onPressed: () {
            _searchController.clear();
            _applySearch('');
          },
        )
            : null,
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
        contentPadding:
        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        isDense: true,
        hintStyle:
        TextStyle(color: AppTheme.getTextSecondary(context)),
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
        labelStyle:
        TextStyle(color: AppTheme.getTextSecondary(context)),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide:
            BorderSide(color: AppTheme.getBorderColor(context))),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide:
            BorderSide(color: AppTheme.getBorderColor(context))),
        filled: true,
        fillColor: isDark
            ? Colors.grey.shade900.withOpacity(0.3)
            : Colors.grey.shade50,
        contentPadding:
        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        isDense: true,
      ),
      dropdownColor: AppTheme.getCardBackground(context),
      items: ['TOUS', 'EN_ATTENTE', 'CONFIRME', 'ECHEC']
          .map((v) => DropdownMenuItem<String>(
        value: v,
        child: Text(_getStatutLabel(v, l10n),
            style: TextStyle(
                fontSize: 14,
                color: AppTheme.getTextPrimary(context))),
      ))
          .toList(),
      onChanged: (value) {
        setState(() => _selectedStatut = value!);
        _applyFilter('statut', value == 'TOUS' ? null : value);
      },
      style: TextStyle(color: AppTheme.getTextPrimary(context)),
    );
  }

  Widget _buildModeDropdown(bool isDark, AppLocalizations l10n) {
    return DropdownButtonFormField<String>(
      value: _selectedMode,
      decoration: InputDecoration(
        labelText: l10n.mode,
        labelStyle:
        TextStyle(color: AppTheme.getTextSecondary(context)),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide:
            BorderSide(color: AppTheme.getBorderColor(context))),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide:
            BorderSide(color: AppTheme.getBorderColor(context))),
        filled: true,
        fillColor: isDark
            ? Colors.grey.shade900.withOpacity(0.3)
            : Colors.grey.shade50,
        contentPadding:
        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        isDense: true,
      ),
      dropdownColor: AppTheme.getCardBackground(context),
      items: ['TOUS', 'ORANGE_MONEY', 'MOOV_MONEY', 'ESPECES', 'VIREMENT']
          .map((v) => DropdownMenuItem<String>(
        value: v,
        child: Text(_getModeLabel(v, l10n),
            style: TextStyle(
                fontSize: 14,
                color: AppTheme.getTextPrimary(context))),
      ))
          .toList(),
      onChanged: (value) {
        setState(() => _selectedMode = value!);
        _applyFilter(
            'mode_paiement', value == 'TOUS' ? null : value);
      },
      style: TextStyle(color: AppTheme.getTextPrimary(context)),
    );
  }

  Widget _buildFilterButtons(AppLocalizations l10n) {
    return Row(mainAxisSize: MainAxisSize.min, children: [
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
        icon: Icon(Icons.refresh,
            color: AppTheme.getTextSecondary(context)),
        tooltip: l10n.reset,
      ),
      IconButton(
        onPressed: () => _exportPaiements(l10n),
        icon: Icon(Icons.download,
            color: Theme.of(context).colorScheme.primary),
        tooltip: l10n.export,
      ),
      ElevatedButton(
        onPressed: _refreshData,
        style: ElevatedButton.styleFrom(
          backgroundColor: Theme.of(context).colorScheme.primary,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        child: Text(l10n.refresh,
            style: const TextStyle(color: Colors.white)),
      ),
    ]);
  }

  // ── STATS (inchangées) ───────────────────────────────────────────────────

  Widget _buildQuickStats(bool isDark, AppLocalizations l10n) {
    return Consumer<PaiementAdminProvider>(
      builder: (context, provider, child) {
        final stats = provider.statistiques ?? {};
        final totalPaiements =
            (int.tryParse(stats['confirmes'] ?? '0') ?? 0) +
                (int.tryParse(stats['en_attente'] ?? '0') ?? 0) +
                (int.tryParse(stats['echecs'] ?? '0') ?? 0);
        final montantTotal =
            (double.tryParse(stats['total_confirme'] ?? '0') ?? 0) +
                (double.tryParse(stats['total_en_attente'] ?? '0') ?? 0) +
                (double.tryParse(stats['total_echec'] ?? '0') ?? 0);
        final enAttente =
            int.tryParse(stats['en_attente'] ?? '0') ?? 0;
        final confirmes = int.tryParse(stats['confirmes'] ?? '0') ?? 0;
        final tauxReussite = totalPaiements > 0
            ? ((confirmes / totalPaiements) * 100)
            : 0;

        final screenWidth = MediaQuery.of(context).size.width;
        final sidebarWidth = screenWidth > 900 ? 280.0 : 0.0;
        final contentWidth = screenWidth - sidebarWidth;
        final isWide = contentWidth > 700;

        return Container(
          padding: const EdgeInsets.all(24),
          color: isDark
              ? Colors.grey.shade900.withOpacity(0.5)
              : const Color(0xFFF1F5F9),
          child: isWide
              ? Row(children: [
            Expanded(
                child: _buildStatCard(
                    label: l10n.totalPayments,
                    value: '$totalPaiements',
                    color: const Color(0xFF3B82F6),
                    icon: Icons.payments,
                    isDark: isDark)),
            const SizedBox(width: 16),
            Expanded(
                child: _buildStatCard(
                    label: l10n.totalAmount,
                    value:
                    '${_formatMontant(montantTotal, l10n)} F',
                    color: const Color(0xFF10B981),
                    icon: Icons.account_balance_wallet,
                    isDark: isDark)),
            const SizedBox(width: 16),
            Expanded(
                child: _buildStatCard(
                    label: l10n.pending,
                    value: '$enAttente',
                    color: const Color(0xFFF59E0B),
                    icon: Icons.hourglass_empty,
                    isDark: isDark)),
            const SizedBox(width: 16),
            Expanded(
                child: _buildStatCard(
                    label: l10n.successRate,
                    value:
                    '${tauxReussite.toStringAsFixed(1)}%',
                    color: const Color(0xFF8B5CF6),
                    icon: Icons.trending_up,
                    isDark: isDark)),
          ])
              : Column(children: [
            Row(children: [
              Expanded(
                  child: _buildStatCard(
                      label: l10n.total,
                      value: '$totalPaiements',
                      color: const Color(0xFF3B82F6),
                      icon: Icons.payments,
                      isDark: isDark)),
              const SizedBox(width: 12),
              Expanded(
                  child: _buildStatCard(
                      label: l10n.amount,
                      value:
                      '${_formatMontant(montantTotal, l10n)} F',
                      color: const Color(0xFF10B981),
                      icon: Icons.account_balance_wallet,
                      isDark: isDark)),
            ]),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(
                  child: _buildStatCard(
                      label: l10n.pending,
                      value: '$enAttente',
                      color: const Color(0xFFF59E0B),
                      icon: Icons.hourglass_empty,
                      isDark: isDark)),
              const SizedBox(width: 12),
              Expanded(
                  child: _buildStatCard(
                      label: l10n.rate,
                      value:
                      '${tauxReussite.toStringAsFixed(1)}%',
                      color: const Color(0xFF8B5CF6),
                      icon: Icons.trending_up,
                      isDark: isDark)),
            ]),
          ]),
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
              blurRadius: 10)
        ],
      ),
      child: Row(children: [
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
              ]),
        ),
      ]),
    );
  }

  // ── FILTRES AVANCÉS (inchangés) ──────────────────────────────────────────

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
              blurRadius: 10)
        ],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Text(l10n.advancedFilters,
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.getTextPrimary(context))),
          const Spacer(),
          TextButton.icon(
            onPressed: () => setState(() => _showFilters = false),
            icon: Icon(Icons.close,
                size: 16, color: AppTheme.getTextSecondary(context)),
            label: Text(l10n.close,
                style: TextStyle(
                    color: AppTheme.getTextSecondary(context))),
          ),
        ]),
        const SizedBox(height: 16),
        Row(children: [
          Expanded(child: _buildDatePicker(l10n.startDate, _selectedDateFrom, isDark, l10n, (d) => setState(() => _selectedDateFrom = d))),
          const SizedBox(width: 16),
          Expanded(child: _buildDatePicker(l10n.endDate, _selectedDateTo, isDark, l10n, (d) => setState(() => _selectedDateTo = d))),
          const SizedBox(width: 16),
          ElevatedButton.icon(
            onPressed: _applyAllFilters,
            icon: Icon(Icons.check, size: 18, color: Colors.white),
            label: Text(l10n.apply,
                style: const TextStyle(color: Colors.white)),
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.primary,
              padding: const EdgeInsets.symmetric(
                  horizontal: 24, vertical: 16),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
          ),
        ]),
      ]),
    );
  }

  Widget _buildDatePicker(String label, DateTime? value, bool isDark,
      AppLocalizations l10n, ValueChanged<DateTime> onPicked) {
    return InkWell(
      onTap: () async {
        final date = await showDatePicker(
          context: context,
          initialDate: value ?? DateTime.now(),
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
        if (date != null) onPicked(date);
      },
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          labelStyle:
          TextStyle(color: AppTheme.getTextSecondary(context)),
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide:
              BorderSide(color: AppTheme.getBorderColor(context))),
          enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide:
              BorderSide(color: AppTheme.getBorderColor(context))),
          filled: true,
          fillColor: isDark
              ? Colors.grey.shade900.withOpacity(0.3)
              : Colors.grey.shade50,
          suffixIcon: Icon(Icons.calendar_today,
              size: 18,
              color: AppTheme.getTextSecondary(context)),
        ),
        child: Text(
          value != null
              ? DateFormat('dd/MM/yyyy', l10n.locale.languageCode)
              .format(value)
              : l10n.select,
          style: TextStyle(
            color: value != null
                ? AppTheme.getTextPrimary(context)
                : AppTheme.getTextSecondary(context),
          ),
        ),
      ),
    );
  }

  // ── TABLEAU — partage le même ScrollController horizontal ────────────────

  Widget _buildPaiementsList(bool isDark, AppLocalizations l10n) {
    return Consumer<PaiementAdminProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading && provider.paiements.isEmpty) {
          return const Center(
              child: Padding(
                  padding: EdgeInsets.all(48.0),
                  child: CircularProgressIndicator()));
        }
        if (provider.error != null && provider.paiements.isEmpty) {
          return _buildErrorWidget(provider.error!, isDark, l10n);
        }
        if (provider.paiements.isEmpty) {
          return _buildEmptyState(isDark, l10n);
        }

        final screenWidth = MediaQuery.of(context).size.width;
        final sidebarWidth = screenWidth > 900 ? 220.0 : 0.0;
        final availableWidth = screenWidth - sidebarWidth - 48;
        final tableWidth = availableWidth > 700 ? availableWidth : 700.0;

        final colEtudiant = tableWidth * 0.20;
        final colMontant  = tableWidth * 0.14;
        final colStatut   = tableWidth * 0.14;
        final colMode     = tableWidth * 0.16;
        final colDate     = tableWidth * 0.16;
        final colActions  = tableWidth * 0.13;

        return Container(
          margin: const EdgeInsets.fromLTRB(24, 0, 24, 24),
          decoration: BoxDecoration(
            color: AppTheme.getCardBackground(context),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                  color: Colors.black
                      .withOpacity(isDark ? 0.1 : 0.05),
                  blurRadius: 10)
            ],
          ),
          child: Column(children: [
            // Tableau scrollable horizontalement — MÊME controller que la barre sticky
            SingleChildScrollView(
              controller: _tableHScrollCtrl,
              scrollDirection: Axis.horizontal,
              child: SizedBox(
                width: tableWidth,
                child: Column(children: [
                  // En-têtes
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 16),
                    decoration: BoxDecoration(
                      color: isDark
                          ? Colors.grey.shade900.withOpacity(0.5)
                          : const Color(0xFFF8FAFC),
                      borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(12),
                          topRight: Radius.circular(12)),
                      border: Border(
                          bottom: BorderSide(
                              color: AppTheme.getBorderColor(context),
                              width: 1)),
                    ),
                    child: Row(children: [
                      SizedBox(width: colEtudiant, child: _headerText(l10n.student)),
                      SizedBox(width: colMontant,  child: _headerText(l10n.amount)),
                      SizedBox(width: colStatut,   child: _headerText(l10n.status)),
                      SizedBox(width: colMode,     child: _headerText(l10n.mode)),
                      SizedBox(width: colDate,     child: _headerText(l10n.date)),
                      SizedBox(width: colActions,  child: _headerText(l10n.actions)),
                    ]),
                  ),
                  // Lignes
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: provider.paiements.length,
                    itemBuilder: (context, index) =>
                        _buildPaiementRow(
                          provider.paiements[index],
                          provider,
                          index,
                          isDark,
                          l10n,
                          colEtudiant: colEtudiant,
                          colMontant: colMontant,
                          colStatut: colStatut,
                          colMode: colMode,
                          colDate: colDate,
                          colActions: colActions,
                        ),
                  ),
                ]),
              ),
            ),
            // Pagination (pleine largeur, hors scroll horizontal)
            _buildPagination(provider, isDark, l10n),
          ]),
        );
      },
    );
  }

  Widget _headerText(String text) {
    return Text(text,
        style: TextStyle(
            fontWeight: FontWeight.bold,
            color: AppTheme.getTextPrimary(context),
            fontSize: 13));
  }

  // ── LIGNES DU TABLEAU (inchangées) ───────────────────────────────────────

  Widget _buildPaiementRow(
      Paiement paiement,
      PaiementAdminProvider provider,
      int index,
      bool isDark,
      AppLocalizations l10n, {
        required double colEtudiant,
        required double colMontant,
        required double colStatut,
        required double colMode,
        required double colDate,
        required double colActions,
      }) {
    return Container(
      padding:
      const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
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
      child: Row(children: [
        SizedBox(
          width: colEtudiant,
          child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(paiement.etudiantNomComplet,
                    style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: AppTheme.getTextPrimary(context),
                        fontSize: 14),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
                const SizedBox(height: 4),
                Text(paiement.matricule ?? 'N/A',
                    style: TextStyle(
                        fontSize: 12,
                        color: AppTheme.getTextSecondary(context))),
                if (paiement.centreNom != null)
                  Text(
                    l10n.centerRoom(paiement.centreNom!,
                        paiement.numeroChambre ?? 'N/A'),
                    style: TextStyle(
                        fontSize: 11,
                        color: AppTheme.getTextTertiary(context)),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
              ]),
        ),
        SizedBox(
          width: colMontant,
          child: Text(
            '${_formatMontant(paiement.montant, l10n)} F',
            style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: paiement.montant > 0
                    ? const Color(0xFF10B981)
                    : const Color(0xFFEF4444)),
          ),
        ),
        SizedBox(
          width: colStatut,
          child: Align(
            alignment: Alignment.centerLeft,
            child: Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: _getStatutColor(paiement.statut)
                    .withOpacity(isDark ? 0.2 : 0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                    color: _getStatutColor(paiement.statut)
                        .withOpacity(isDark ? 0.4 : 0.3)),
              ),
              child: Text(
                _getStatutLabel(paiement.statut, l10n),
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: _getStatutColor(paiement.statut)),
              ),
            ),
          ),
        ),
        SizedBox(
          width: colMode,
          child: Text(_getModeLabel(paiement.modePaiement, l10n),
              style: TextStyle(
                  color: AppTheme.getTextSecondary(context),
                  fontSize: 13),
              maxLines: 1,
              overflow: TextOverflow.ellipsis),
        ),
        SizedBox(
          width: colDate,
          child: Text(
            paiement.datePaiement != null
                ? DateFormat('dd/MM/yy HH:mm',
                l10n.locale.languageCode)
                .format(paiement.datePaiement!)
                : 'N/A',
            style: TextStyle(
                color: AppTheme.getTextSecondary(context),
                fontSize: 13),
          ),
        ),
        SizedBox(
          width: colActions,
          child: Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                IconButton(
                  onPressed: () =>
                      _showPaiementDetails(paiement, provider, l10n),
                  icon: Icon(Icons.visibility_outlined,
                      size: 20,
                      color: AppTheme.getTextSecondary(context)),
                  tooltip: l10n.viewDetails,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
                const SizedBox(width: 8),
                PopupMenuButton<String>(
                  icon: Icon(Icons.more_vert,
                      size: 20,
                      color: AppTheme.getTextSecondary(context)),
                  color: AppTheme.getCardBackground(context),
                  surfaceTintColor: AppTheme.getCardBackground(context),
                  itemBuilder: (ctx) =>
                      _buildActionMenu(paiement, l10n),
                  onSelected: (value) =>
                      _handleAction(value, paiement, provider, l10n),
                  padding: EdgeInsets.zero,
                ),
              ]),
        ),
      ]),
    );
  }

  // ── PAGINATION (inchangée) ───────────────────────────────────────────────

  Widget _buildPagination(
      PaiementAdminProvider provider, bool isDark, AppLocalizations l10n) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.grey.shade900.withOpacity(0.5)
            : const Color(0xFFF8FAFC),
        borderRadius: const BorderRadius.only(
            bottomLeft: Radius.circular(12),
            bottomRight: Radius.circular(12)),
      ),
      child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(l10n.totalPaymentsCount(provider.totalItems),
                style: TextStyle(
                    color: AppTheme.getTextSecondary(context),
                    fontSize: 13)),
            Row(children: [
              IconButton(
                onPressed: provider.currentPage > 1
                    ? provider.loadPreviousPage
                    : null,
                icon: const Icon(Icons.chevron_left),
                color: provider.currentPage > 1
                    ? Theme.of(context).colorScheme.primary
                    : AppTheme.getTextTertiary(context),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: AppTheme.getCardBackground(context),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                      color: AppTheme.getBorderColor(context)),
                ),
                child: Text(
                  l10n.pageOf(
                      provider.currentPage, provider.totalPages),
                  style: TextStyle(
                      color: AppTheme.getTextPrimary(context),
                      fontWeight: FontWeight.w500),
                ),
              ),
              IconButton(
                onPressed:
                provider.currentPage < provider.totalPages
                    ? provider.loadNextPage
                    : null,
                icon: const Icon(Icons.chevron_right),
                color: provider.currentPage < provider.totalPages
                    ? Theme.of(context).colorScheme.primary
                    : AppTheme.getTextTertiary(context),
              ),
            ]),
          ]),
    );
  }

  // ── ÉTATS VIDES / ERREUR (inchangés) ────────────────────────────────────

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
              blurRadius: 10)
        ],
      ),
      child: Center(
        child: Column(children: [
          Icon(Icons.payments_outlined,
              size: 80,
              color: AppTheme.getTextTertiary(context)),
          const SizedBox(height: 24),
          Text(l10n.noPaymentsFound,
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.getTextSecondary(context))),
          const SizedBox(height: 8),
          Text(l10n.adjustFiltersOrWait,
              style: TextStyle(
                  color: AppTheme.getTextTertiary(context))),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _resetFilters,
            style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Colors.white),
            child: Text(l10n.resetFilters),
          ),
        ]),
      ),
    );
  }

  Widget _buildErrorWidget(
      String error, bool isDark, AppLocalizations l10n) {
    return Container(
      padding: const EdgeInsets.all(24),
      margin: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.red.shade900.withOpacity(0.1)
            : const Color(0xFFFEF2F2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: isDark
                ? Colors.red.shade800
                : const Color(0xFFFECACA)),
      ),
      child: Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.error_outline,
              size: 48, color: Colors.red.shade400),
          const SizedBox(height: 16),
          Text(l10n.loadingError,
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
            child: Text(l10n.retry),
          ),
        ]),
      ),
    );
  }

  // ── UTILITAIRES (inchangés) ──────────────────────────────────────────────

  String _getStatutLabel(String statut, AppLocalizations l10n) {
    switch (statut) {
      case 'EN_ATTENTE': return l10n.pendingStatus;
      case 'CONFIRME':   return l10n.confirmedStatus;
      case 'ECHEC':      return l10n.failedStatus;
      case 'TOUS':       return l10n.all;
      default:           return statut;
    }
  }

  Color _getStatutColor(String statut) {
    switch (statut) {
      case 'EN_ATTENTE': return const Color(0xFFF59E0B);
      case 'CONFIRME':   return const Color(0xFF10B981);
      case 'ECHEC':      return const Color(0xFFEF4444);
      default:           return const Color(0xFF64748B);
    }
  }

  String _getModeLabel(String mode, AppLocalizations l10n) {
    switch (mode) {
      case 'ORANGE_MONEY': return l10n.orangeMoney;
      case 'MOOV_MONEY':   return l10n.moovMoney;
      case 'ESPECES':      return l10n.cash;
      case 'VIREMENT':     return l10n.transfer;
      case 'TOUS':         return l10n.all;
      default:             return mode;
    }
  }

  List<PopupMenuEntry<String>> _buildActionMenu(
      Paiement paiement, AppLocalizations l10n) {
    return [
      PopupMenuItem<String>(
        value: 'details',
        child: Row(children: [
          Icon(Icons.info_outline,
              size: 18, color: AppTheme.getTextSecondary(context)),
          const SizedBox(width: 8),
          Text(l10n.fullDetails,
              style: TextStyle(
                  color: AppTheme.getTextPrimary(context))),
        ]),
      ),
      if (paiement.statut == 'EN_ATTENTE') ...[
        PopupMenuItem<String>(
          value: 'confirmer',
          child: Row(children: [
            const Icon(Icons.check_circle,
                size: 18, color: Color(0xFF10B981)),
            const SizedBox(width: 8),
            Text(l10n.confirmPayment,
                style: TextStyle(
                    color: AppTheme.getTextPrimary(context))),
          ]),
        ),
        PopupMenuItem<String>(
          value: 'rejeter',
          child: Row(children: [
            const Icon(Icons.cancel,
                size: 18, color: Color(0xFFEF4444)),
            const SizedBox(width: 8),
            Text(l10n.markAsFailed,
                style: TextStyle(
                    color: AppTheme.getTextPrimary(context))),
          ]),
        ),
      ],
      const PopupMenuDivider(),
      PopupMenuItem<String>(
        value: 'export',
        child: Row(children: [
          Icon(Icons.download,
              size: 18, color: AppTheme.getTextSecondary(context)),
          const SizedBox(width: 8),
          Text(l10n.exportReceipt,
              style: TextStyle(
                  color: AppTheme.getTextPrimary(context))),
        ]),
      ),
    ];
  }

  // ── ACTIONS (inchangées) ─────────────────────────────────────────────────

  Future<void> _applySearch(String query) async {
    final provider = Provider.of<PaiementAdminProvider>(context, listen: false);
    await provider.searchPaiements(query);
  }

  Future<void> _applyFilter(String key, dynamic value) async {
    final provider = Provider.of<PaiementAdminProvider>(context, listen: false);
    await provider.applyFilter(key, value);
  }

  Future<void> _applyAllFilters() async {
    final provider = Provider.of<PaiementAdminProvider>(context, listen: false);
    await provider.applyMultipleFilters({
      'statut': _selectedStatut,
      'mode_paiement': _selectedMode,
      'search': _searchController.text,
      'date_from': _selectedDateFrom != null
          ? DateFormat('yyyy-MM-dd').format(_selectedDateFrom!)
          : null,
      'date_to': _selectedDateTo != null
          ? DateFormat('yyyy-MM-dd').format(_selectedDateTo!)
          : null,
    });
  }

  Future<void> _resetFilters() async {
    setState(() {
      _searchController.clear();
      _selectedStatut   = 'TOUS';
      _selectedMode     = 'TOUS';
      _selectedDateFrom = null;
      _selectedDateTo   = null;
    });
    final provider = Provider.of<PaiementAdminProvider>(context, listen: false);
    await provider.resetFilters();
  }

  Future<void> _refreshData() async {
    final provider = Provider.of<PaiementAdminProvider>(context, listen: false);
    await provider.loadPaiements();
  }

  void _showPaiementDetails(
      Paiement paiement, PaiementAdminProvider provider, AppLocalizations l10n) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: AppTheme.getCardBackground(context),
        shape:
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        insetPadding:
        const EdgeInsets.symmetric(horizontal: 40, vertical: 40),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(l10n.paymentDetails,
                      style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.getTextPrimary(context))),
                  const SizedBox(height: 16),
                  const Divider(),
                  const SizedBox(height: 8),
                  SingleChildScrollView(
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _buildDetailItem(l10n.reference, paiement.referenceTransaction ?? 'N/A', l10n),
                          _buildDetailItem(l10n.student, paiement.etudiantNomComplet, l10n),
                          if (paiement.matricule != null) _buildDetailItem(l10n.matricule, paiement.matricule!, l10n),
                          _buildDetailItem(l10n.center, paiement.centreNom ?? 'N/A', l10n),
                          _buildDetailItem(l10n.room, paiement.numeroChambre ?? 'N/A', l10n),
                          _buildDetailItem(l10n.amount, '${_formatMontant(paiement.montant, l10n)} FCFA', l10n),
                          _buildDetailItem(l10n.status, _getStatutLabel(paiement.statut, l10n), l10n),
                          _buildDetailItem(l10n.mode, _getModeLabel(paiement.modePaiement, l10n), l10n),
                          _buildDetailItem(l10n.paymentDate,
                              paiement.datePaiement != null
                                  ? DateFormat('dd/MM/yyyy HH:mm', l10n.locale.languageCode).format(paiement.datePaiement!)
                                  : l10n.notDefined, l10n),
                        ]),
                  ),
                  const SizedBox(height: 16),
                  const Divider(),
                  const SizedBox(height: 8),
                  Row(mainAxisAlignment: MainAxisAlignment.end, children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text(l10n.close,
                          style: TextStyle(
                              color: AppTheme.getTextSecondary(context))),
                    ),
                    if (paiement.statut == 'EN_ATTENTE') ...[
                      const SizedBox(width: 12),
                      ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context);
                          _confirmPaiement(paiement.id.toString(), provider, l10n);
                        },
                        style: ElevatedButton.styleFrom(
                            backgroundColor: Theme.of(context).colorScheme.primary,
                            foregroundColor: Colors.white),
                        child: Text(l10n.confirm),
                      ),
                    ],
                  ]),
                ]),
          ),
        ),
      ),
    );
  }

  Widget _buildDetailItem(
      String label, String value, AppLocalizations l10n) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
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
      ]),
    );
  }

  Future<void> _handleAction(String action, Paiement paiement,
      PaiementAdminProvider provider, AppLocalizations l10n) async {
    switch (action) {
      case 'details':
        _showPaiementDetails(paiement, provider, l10n);
        break;
      case 'confirmer':
        await _confirmPaiement(paiement.id.toString(), provider, l10n);
        break;
      case 'rejeter':
        await _rejectPaiement(paiement.id.toString(), provider, l10n);
        break;
      case 'export':
        _exportReceipt(paiement, l10n);
        break;
    }
  }

  Future<void> _confirmPaiement(String paiementId,
      PaiementAdminProvider provider, AppLocalizations l10n) async {
    final commentaireController = TextEditingController();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    try {
      final commentaire = await showDialog<String>(
        context: context,
        builder: (ctx) => Dialog(
          backgroundColor: AppTheme.getCardBackground(context),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Text(l10n.confirmPaymentTitle,
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.getTextPrimary(context))),
              const SizedBox(height: 16),
              Text(l10n.confirmPaymentQuestion,
                  style: TextStyle(
                      color: AppTheme.getTextSecondary(context))),
              const SizedBox(height: 16),
              TextField(
                controller: commentaireController,
                decoration: InputDecoration(
                  labelText: l10n.optionalComment,
                  labelStyle: TextStyle(
                      color: AppTheme.getTextSecondary(context)),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(
                          color: AppTheme.getBorderColor(context))),
                  enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(
                          color: AppTheme.getBorderColor(context))),
                  focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(
                          color: Theme.of(context).colorScheme.primary,
                          width: 2)),
                  filled: true,
                  fillColor: isDark
                      ? Colors.grey.shade900.withOpacity(0.3)
                      : Colors.grey.shade50,
                ),
                maxLines: 3,
                style: TextStyle(color: AppTheme.getTextPrimary(context)),
              ),
              const SizedBox(height: 24),
              Row(mainAxisAlignment: MainAxisAlignment.end, children: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: Text(l10n.cancel,
                      style: TextStyle(
                          color: AppTheme.getTextSecondary(context))),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: () =>
                      Navigator.pop(ctx, commentaireController.text),
                  style: ElevatedButton.styleFrom(
                      backgroundColor:
                      Theme.of(context).colorScheme.primary,
                      foregroundColor: Colors.white),
                  child: Text(l10n.confirm),
                ),
              ]),
            ]),
          ),
        ),
      );
      if (commentaire == null) return;
      await provider.updateStatutPaiement(
          paiementId: paiementId,
          nouveauStatut: 'CONFIRME',
          raison: commentaire.isNotEmpty ? commentaire : null);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(l10n.paymentConfirmedSuccess),
            backgroundColor: const Color(0xFF10B981),
            behavior: SnackBarBehavior.floating));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('${l10n.error}: $e'),
            backgroundColor: const Color(0xFFEF4444),
            behavior: SnackBarBehavior.floating));
      }
    } finally {
      commentaireController.dispose();
    }
  }

  Future<void> _rejectPaiement(String paiementId,
      PaiementAdminProvider provider, AppLocalizations l10n) async {
    final raisonController = TextEditingController();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    try {
      final raison = await showDialog<String>(
        context: context,
        builder: (ctx) => Dialog(
          backgroundColor: AppTheme.getCardBackground(context),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Text(l10n.markAsFailedTitle,
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.getTextPrimary(context))),
              const SizedBox(height: 16),
              Text(l10n.indicateFailureReason,
                  style: TextStyle(
                      color: AppTheme.getTextSecondary(context))),
              const SizedBox(height: 16),
              TextField(
                controller: raisonController,
                decoration: InputDecoration(
                  labelText: l10n.reason,
                  labelStyle: TextStyle(
                      color: AppTheme.getTextSecondary(context)),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(
                          color: AppTheme.getBorderColor(context))),
                  enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(
                          color: AppTheme.getBorderColor(context))),
                  focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(
                          color: Theme.of(context).colorScheme.primary,
                          width: 2)),
                  hintText: l10n.failureReasonHint,
                  hintStyle: TextStyle(
                      color: AppTheme.getTextTertiary(context)),
                  filled: true,
                  fillColor: isDark
                      ? Colors.grey.shade900.withOpacity(0.3)
                      : Colors.grey.shade50,
                ),
                maxLines: 3,
                style: TextStyle(color: AppTheme.getTextPrimary(context)),
              ),
              const SizedBox(height: 24),
              Row(mainAxisAlignment: MainAxisAlignment.end, children: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: Text(l10n.cancel,
                      style: TextStyle(
                          color: AppTheme.getTextSecondary(context))),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: () =>
                      Navigator.pop(ctx, raisonController.text),
                  style: ElevatedButton.styleFrom(
                      backgroundColor:
                      Theme.of(context).colorScheme.primary,
                      foregroundColor: Colors.white),
                  child: Text(l10n.validate),
                ),
              ]),
            ]),
          ),
        ),
      );
      if (raison == null) return;
      await provider.updateStatutPaiement(
          paiementId: paiementId,
          nouveauStatut: 'ECHEC',
          raison: raison.isNotEmpty ? raison : null);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(l10n.paymentMarkedAsFailed),
            backgroundColor: const Color(0xFFEF4444),
            behavior: SnackBarBehavior.floating));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('${l10n.error}: $e'),
            backgroundColor: const Color(0xFFEF4444),
            behavior: SnackBarBehavior.floating));
      }
    } finally {
      raisonController.dispose();
    }
  }

  void _exportReceipt(Paiement paiement, AppLocalizations l10n) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(l10n.exportReceiptFor(
            paiement.referenceTransaction ?? '')),
        behavior: SnackBarBehavior.floating));
  }

  Future<void> _exportPaiements(AppLocalizations l10n) async {
    final provider =
    Provider.of<PaiementAdminProvider>(context, listen: false);
    if (provider.paiements.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(l10n.noPaymentsToExport),
          backgroundColor: const Color(0xFFF59E0B),
          behavior: SnackBarBehavior.floating));
      return;
    }
    final format = await showDialog<String>(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: AppTheme.getCardBackground(context),
        shape:
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Text(l10n.exportPayments,
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.getTextPrimary(context))),
            const SizedBox(height: 16),
            Text(l10n.chooseExportFormat,
                style: TextStyle(
                    color: AppTheme.getTextSecondary(context))),
            const SizedBox(height: 24),
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              TextButton(
                  onPressed: () => Navigator.pop(ctx, 'pdf'),
                  child: const Row(children: [
                    Icon(Icons.picture_as_pdf, color: Colors.red),
                    SizedBox(width: 8),
                    Text('PDF')
                  ])),
              const SizedBox(width: 16),
              TextButton(
                  onPressed: () => Navigator.pop(ctx, 'excel'),
                  child: const Row(children: [
                    Icon(Icons.table_chart, color: Colors.green),
                    SizedBox(width: 8),
                    Text('Excel')
                  ])),
              const SizedBox(width: 16),
              TextButton(
                  onPressed: () => Navigator.pop(ctx, 'word'),
                  child: const Row(children: [
                    Icon(Icons.description, color: Colors.blue),
                    SizedBox(width: 8),
                    Text('Word')
                  ])),
            ]),
            const SizedBox(height: 24),
            Row(mainAxisAlignment: MainAxisAlignment.end, children: [
              TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: Text(l10n.cancel,
                      style: TextStyle(
                          color: AppTheme.getTextSecondary(context)))),
            ]),
          ]),
        ),
      ),
    );
    if (format != null) {
      try {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content:
            Text(l10n.generatingFormat(format.toUpperCase())),
            duration: const Duration(seconds: 2),
            behavior: SnackBarBehavior.floating));
        await Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => ExportPreviewScreen(
                    format: format,
                    paiements: provider.paiements,
                    filters: provider.filters)));
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text('${l10n.exportError}: $e'),
              backgroundColor: const Color(0xFFEF4444),
              behavior: SnackBarBehavior.floating));
        }
      }
    }
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// _HScrollBarDelegate — barre de scroll horizontal sticky
//
// S'affiche AU-DESSUS des en-têtes du tableau.
// Colle en haut du viewport dès qu'elle sort de l'écran (pinned: true).
// Partage le même ScrollController (_tableHScrollCtrl) que le tableau,
// donc bouger la barre fait bouger le tableau et vice-versa.
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

          // ── Barre de progression (lit le controller, ne crée PAS de ScrollView) ──
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

          // ── Flèches ──────────────────────────────────────────────────────
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