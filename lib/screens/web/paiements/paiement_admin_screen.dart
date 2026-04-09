import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
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
  final TextEditingController _searchController   = TextEditingController();
  final ScrollController _horizontalScrollCtrl    = ScrollController();
  final ValueNotifier<double> _scrollProgress     = ValueNotifier(0.0); // 0..1

  String _selectedStatut = 'TOUS';
  String _selectedMode   = 'TOUS';
  DateTime? _selectedDateFrom;
  DateTime? _selectedDateTo;
  bool _showFilters = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadInitialData());
    _horizontalScrollCtrl.addListener(_onHorizontalScroll);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _horizontalScrollCtrl.removeListener(_onHorizontalScroll);
    _horizontalScrollCtrl.dispose();
    _scrollProgress.dispose();
    super.dispose();
  }

  void _onHorizontalScroll() {
    if (!_horizontalScrollCtrl.hasClients) return;
    final max = _horizontalScrollCtrl.position.maxScrollExtent;
    if (max <= 0) { _scrollProgress.value = 0; return; }
    _scrollProgress.value =
        (_horizontalScrollCtrl.offset / max).clamp(0.0, 1.0);
  }

  void _scrollLeft()  => _horizontalScrollCtrl.animateTo(
    (_horizontalScrollCtrl.offset - 280).clamp(0, double.infinity),
    duration: const Duration(milliseconds: 280),
    curve: Curves.easeOutCubic,
  );
  void _scrollRight() => _horizontalScrollCtrl.animateTo(
    _horizontalScrollCtrl.offset + 280,
    duration: const Duration(milliseconds: 280),
    curve: Curves.easeOutCubic,
  );

  String _formatMontant(double montant, AppLocalizations l10n) =>
      NumberFormat('#,##0', l10n.locale.languageCode).format(montant);

  Future<void> _loadInitialData() async {
    final p = Provider.of<PaiementAdminProvider>(context, listen: false);
    await p.loadPaiements();
    await p.loadStatistiques();
  }

  // ══════════════════════════════════════════════════════════════════════════
  // BUILD
  // ══════════════════════════════════════════════════════════════════════════

  @override
  Widget build(BuildContext context) {
    final l10n   = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return DashboardLayout(
      selectedIndex: 1,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Barre de filtres (toujours visible en haut) ──────────────────
          _buildFloatingFiltersBar(isDark, l10n),

          // ── Corps principal ──────────────────────────────────────────────
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Statistiques rapides
                _buildQuickStats(isDark, l10n),

                // Filtres avancés (collapsible)
                AnimatedSize(
                  duration: const Duration(milliseconds: 280),
                  curve: Curves.easeInOut,
                  child: _showFilters
                      ? _buildFiltersCard(isDark, l10n)
                      : const SizedBox.shrink(),
                ),

                // ── TABLE (prend tout l'espace restant) ──────────────────
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                    child: _buildStickyTable(isDark, l10n),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // TABLEAU STICKY
  // ══════════════════════════════════════════════════════════════════════════

  Widget _buildStickyTable(bool isDark, AppLocalizations l10n) {
    return Consumer<PaiementAdminProvider>(
      builder: (context, provider, _) {
        // ── États non-données ────────────────────────────────────────────
        if (provider.isLoading && provider.paiements.isEmpty) {
          return _buildCenteredState(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              CircularProgressIndicator(color: Theme.of(context).colorScheme.primary),
              const SizedBox(height: 16),
              Text(l10n.loading,
                  style: TextStyle(color: AppTheme.getTextSecondary(context))),
            ]),
            isDark: isDark,
          );
        }
        if (provider.error != null && provider.paiements.isEmpty) {
          return _buildErrorWidget(provider.error!, isDark, l10n);
        }
        if (provider.paiements.isEmpty) {
          return _buildEmptyState(isDark, l10n);
        }

        // ── Calcul des colonnes ──────────────────────────────────────────
        final sw            = MediaQuery.of(context).size.width;
        final sidebarW      = sw > 900 ? 220.0 : 0.0;
        final availableW    = sw - sidebarW - 48;
        final tableW        = availableW > 760 ? availableW : 760.0;

        final cols = _TableCols(tableW);

        // ── Conteneur principal ──────────────────────────────────────────
        return Container(
          decoration: BoxDecoration(
            color:        AppTheme.getCardBackground(context),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color:    Colors.black.withOpacity(isDark ? 0.12 : 0.06),
                blurRadius: 16,
                offset:   const Offset(0, 4),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Column(
              children: [
                // ① BARRE DE NAVIGATION STICKY ─────────────────────────
                _buildStickyNavBar(isDark, l10n, tableW, availableW, provider),

                // ② EN-TÊTE DU TABLEAU (scroll horizontal synchronisé) ──
                _buildStickyTableHeader(isDark, l10n, cols),

                // ③ LIGNES (scroll H et V) ────────────────────────────
                Expanded(
                  child: Scrollbar(
                    controller: _horizontalScrollCtrl,
                    thumbVisibility: false, // barre déjà dans le nav
                    child: SingleChildScrollView(
                      controller:      _horizontalScrollCtrl,
                      scrollDirection: Axis.horizontal,
                      physics:         const BouncingScrollPhysics(),
                      child: SizedBox(
                        width: tableW,
                        child: ListView.builder(
                          itemCount:   provider.paiements.length,
                          itemBuilder: (ctx, i) => _buildPaiementRow(
                            provider.paiements[i], provider, i,
                            isDark, l10n, cols,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                // ④ PAGINATION STICKY ─────────────────────────────────
                _buildPagination(provider, isDark, l10n),
              ],
            ),
          ),
        );
      },
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // BARRE DE NAVIGATION HORIZONTALE (sticky, professionnelle)
  // ══════════════════════════════════════════════════════════════════════════

  Widget _buildStickyNavBar(
      bool isDark, AppLocalizations l10n,
      double tableW, double availableW,
      PaiementAdminProvider provider,
      ) {
    final needsScroll = tableW > availableW;
    final primary     = Theme.of(context).colorScheme.primary;

    return Container(
      height:  48,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: isDark
            ? const Color(0xFF1A1F2E)
            : const Color(0xFFF1F5F9),
        border: Border(
          bottom: BorderSide(
            color: isDark ? Colors.white.withOpacity(0.06) : Colors.black.withOpacity(0.07),
          ),
        ),
      ),
      child: Row(
        children: [
          // ── Info lignes ───────────────────────────────────────────────
          Icon(Icons.table_rows_outlined, size: 15,
              color: AppTheme.getTextSecondary(context)),
          const SizedBox(width: 6),
          Text(
            '${provider.paiements.length} / ${provider.totalItems}',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppTheme.getTextSecondary(context),
            ),
          ),

          const Spacer(),

          if (needsScroll) ...[
            // ── Barre de progression horizontale ──────────────────────
            ValueListenableBuilder<double>(
              valueListenable: _scrollProgress,
              builder: (_, progress, __) {
                return _HScrollProgressBar(
                  progress: progress,
                  color:    primary,
                  isDark:   isDark,
                );
              },
            ),
            const SizedBox(width: 12),

            // ── Bouton ← ──────────────────────────────────────────────
            _NavIconButton(
              icon:    Icons.chevron_left_rounded,
              tooltip: l10n.scrollLeft,
              color:   primary,
              isDark:  isDark,
              onPressed: _scrollLeft,
            ),
            const SizedBox(width: 4),

            // ── Indicateur position ───────────────────────────────────
            ValueListenableBuilder<double>(
              valueListenable: _scrollProgress,
              builder: (_, progress, __) => Container(
                width: 36,
                alignment: Alignment.center,
                child: Text(
                  '${(progress * 100).round()}%',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: primary,
                    letterSpacing: 0.3,
                  ),
                ),
              ),
            ),

            // ── Bouton → ──────────────────────────────────────────────
            _NavIconButton(
              icon:    Icons.chevron_right_rounded,
              tooltip: l10n.scrollRight,
              color:   primary,
              isDark:  isDark,
              onPressed: _scrollRight,
            ),
            const SizedBox(width: 8),
          ] else ...[
            // Pas de scroll nécessaire
            Icon(Icons.check_circle_outline, size: 13,
                color: const Color(0xFF10B981)),
            const SizedBox(width: 4),
            Text(
              l10n.tableFullyVisible,
              style: const TextStyle(
                fontSize: 11,
                color: Color(0xFF10B981),
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(width: 8),
          ],

          // ── Refresh ───────────────────────────────────────────────────
          _NavIconButton(
            icon:     Icons.refresh_rounded,
            tooltip:  l10n.refresh,
            color:    AppTheme.getTextSecondary(context),
            isDark:   isDark,
            onPressed: _refreshData,
          ),
        ],
      ),
    );
  }

  // ── En-tête colonnes (sticky, scroll H synchronisé) ─────────────────────

  Widget _buildStickyTableHeader(bool isDark, AppLocalizations l10n, _TableCols cols) {
    return SingleChildScrollView(
      controller:      _horizontalScrollCtrl,
      scrollDirection: Axis.horizontal,
      physics:         const NeverScrollableScrollPhysics(), // piloté par le controller
      child: SizedBox(
        width: cols.total,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          decoration: BoxDecoration(
            color: isDark
                ? Colors.white.withOpacity(0.03)
                : const Color(0xFFF8FAFC),
            border: Border(
              bottom: BorderSide(color: AppTheme.getBorderColor(context)),
            ),
          ),
          child: Row(
            children: [
              SizedBox(width: cols.etudiant, child: _headerCell(l10n.student)),
              SizedBox(width: cols.montant,  child: _headerCell(l10n.amount)),
              SizedBox(width: cols.statut,   child: _headerCell(l10n.status)),
              SizedBox(width: cols.mode,     child: _headerCell(l10n.mode)),
              SizedBox(width: cols.date,     child: _headerCell(l10n.date)),
              SizedBox(width: cols.actions,  child: _headerCell(l10n.actions)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _headerCell(String text) => Text(
    text,
    style: TextStyle(
      fontWeight: FontWeight.w700,
      fontSize:   12,
      letterSpacing: 0.4,
      color: AppTheme.getTextPrimary(context),
    ),
  );

  // ══════════════════════════════════════════════════════════════════════════
  // LIGNE DE PAIEMENT
  // ══════════════════════════════════════════════════════════════════════════

  Widget _buildPaiementRow(
      Paiement paiement, PaiementAdminProvider provider,
      int index, bool isDark, AppLocalizations l10n, _TableCols cols,
      ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        color: index.isEven
            ? AppTheme.getCardBackground(context)
            : (isDark
            ? Colors.white.withOpacity(0.02)
            : const Color(0xFFFAFAFA)),
        border: Border(
          bottom: BorderSide(
              color: AppTheme.getBorderColor(context), width: 1),
        ),
      ),
      child: Row(
        children: [
          // Étudiant
          SizedBox(
            width: cols.etudiant,
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(paiement.etudiantNomComplet,
                  style: TextStyle(fontWeight: FontWeight.w600,
                      color: AppTheme.getTextPrimary(context), fontSize: 14),
                  maxLines: 1, overflow: TextOverflow.ellipsis),
              const SizedBox(height: 3),
              Text(paiement.matricule ?? 'N/A',
                  style: TextStyle(fontSize: 12,
                      color: AppTheme.getTextSecondary(context))),
              if (paiement.centreNom != null)
                Text(l10n.centerRoom(paiement.centreNom!, paiement.numeroChambre ?? 'N/A'),
                    style: TextStyle(fontSize: 11,
                        color: AppTheme.getTextTertiary(context)),
                    maxLines: 1, overflow: TextOverflow.ellipsis),
            ]),
          ),
          // Montant
          SizedBox(
            width: cols.montant,
            child: Text('${_formatMontant(paiement.montant, l10n)} F',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14,
                    color: paiement.montant > 0
                        ? const Color(0xFF10B981)
                        : const Color(0xFFEF4444))),
          ),
          // Statut
          SizedBox(
            width: cols.statut,
            child: Align(
              alignment: Alignment.centerLeft,
              child: _StatusBadge(
                label: _getStatutLabel(paiement.statut, l10n),
                color: _getStatutColor(paiement.statut),
                isDark: isDark,
              ),
            ),
          ),
          // Mode
          SizedBox(
            width: cols.mode,
            child: Text(_getModeLabel(paiement.modePaiement, l10n),
                style: TextStyle(color: AppTheme.getTextSecondary(context),
                    fontSize: 13),
                maxLines: 1, overflow: TextOverflow.ellipsis),
          ),
          // Date
          SizedBox(
            width: cols.date,
            child: Text(
              paiement.datePaiement != null
                  ? DateFormat('dd/MM/yy HH:mm',
                  l10n.locale.languageCode)
                  .format(paiement.datePaiement!)
                  : 'N/A',
              style: TextStyle(color: AppTheme.getTextSecondary(context),
                  fontSize: 13),
            ),
          ),
          // Actions
          SizedBox(
            width: cols.actions,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                IconButton(
                  onPressed: () =>
                      _showPaiementDetails(paiement, provider, l10n),
                  icon: Icon(Icons.visibility_outlined, size: 18,
                      color: AppTheme.getTextSecondary(context)),
                  tooltip: l10n.viewDetails,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
                const SizedBox(width: 8),
                PopupMenuButton<String>(
                  icon: Icon(Icons.more_vert, size: 18,
                      color: AppTheme.getTextSecondary(context)),
                  color: AppTheme.getCardBackground(context),
                  itemBuilder: (_) => _buildActionMenu(paiement, l10n),
                  onSelected: (v) =>
                      _handleAction(v, paiement, provider, l10n),
                  padding: EdgeInsets.zero,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // FILTRES & STATS (inchangés dans leur logique)
  // ══════════════════════════════════════════════════════════════════════════

  Widget _buildFloatingFiltersBar(bool isDark, AppLocalizations l10n) {
    final isWide = MediaQuery.of(context).size.width > 1100;
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
            borderSide: BorderSide(color: AppTheme.getBorderColor(context))),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: AppTheme.getBorderColor(context))),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(
                color: Theme.of(context).colorScheme.primary, width: 2)),
        filled: true,
        fillColor:
        isDark ? Colors.grey.shade900.withOpacity(0.3) : Colors.grey.shade50,
        contentPadding:
        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
            borderSide: BorderSide(color: AppTheme.getBorderColor(context))),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: AppTheme.getBorderColor(context))),
        filled: true,
        fillColor:
        isDark ? Colors.grey.shade900.withOpacity(0.3) : Colors.grey.shade50,
        contentPadding:
        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        isDense: true,
      ),
      dropdownColor: AppTheme.getCardBackground(context),
      items: ['TOUS', 'EN_ATTENTE', 'CONFIRME', 'ECHEC']
          .map((v) => DropdownMenuItem(
        value: v,
        child: Text(_getStatutLabel(v, l10n),
            style: TextStyle(
                fontSize: 14,
                color: AppTheme.getTextPrimary(context))),
      ))
          .toList(),
      onChanged: (v) {
        setState(() => _selectedStatut = v!);
        _applyFilter('statut', v == 'TOUS' ? null : v);
      },
      style: TextStyle(color: AppTheme.getTextPrimary(context)),
    );
  }

  Widget _buildModeDropdown(bool isDark, AppLocalizations l10n) {
    return DropdownButtonFormField<String>(
      value: _selectedMode,
      decoration: InputDecoration(
        labelText: l10n.mode,
        labelStyle: TextStyle(color: AppTheme.getTextSecondary(context)),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: AppTheme.getBorderColor(context))),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: AppTheme.getBorderColor(context))),
        filled: true,
        fillColor:
        isDark ? Colors.grey.shade900.withOpacity(0.3) : Colors.grey.shade50,
        contentPadding:
        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        isDense: true,
      ),
      dropdownColor: AppTheme.getCardBackground(context),
      items: ['TOUS', 'ORANGE_MONEY', 'MOOV_MONEY', 'ESPECES', 'VIREMENT']
          .map((v) => DropdownMenuItem(
        value: v,
        child: Text(_getModeLabel(v, l10n),
            style: TextStyle(
                fontSize: 14,
                color: AppTheme.getTextPrimary(context))),
      ))
          .toList(),
      onChanged: (v) {
        setState(() => _selectedMode = v!);
        _applyFilter('mode_paiement', v == 'TOUS' ? null : v);
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
              color: Theme.of(context).colorScheme.primary),
          tooltip: _showFilters ? l10n.hideFilters : l10n.moreFilters,
        ),
        IconButton(
          onPressed: _resetFilters,
          icon: Icon(Icons.refresh, color: AppTheme.getTextSecondary(context)),
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
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8)),
          ),
          child: Text(l10n.refresh,
              style: const TextStyle(color: Colors.white)),
        ),
      ],
    );
  }

  Widget _buildQuickStats(bool isDark, AppLocalizations l10n) {
    return Consumer<PaiementAdminProvider>(
      builder: (context, provider, _) {
        final stats = provider.statistiques ?? {};
        final confirmes  = int.tryParse(stats['confirmes']   ?? '0') ?? 0;
        final enAttente  = int.tryParse(stats['en_attente']  ?? '0') ?? 0;
        final echecs     = int.tryParse(stats['echecs']      ?? '0') ?? 0;
        final total      = confirmes + enAttente + echecs;
        final taux       = total > 0 ? (confirmes / total * 100) : 0.0;
        final montantTot =
            (double.tryParse(stats['total_confirme']  ?? '0') ?? 0) +
                (double.tryParse(stats['total_en_attente']?? '0') ?? 0) +
                (double.tryParse(stats['total_echec']     ?? '0') ?? 0);

        final sw   = MediaQuery.of(context).size.width;
        final isW  = (sw - (sw > 900 ? 220 : 0)) > 700;

        final cards = [
          _StatData(l10n.totalPayments, '$total',
              const Color(0xFF3B82F6), Icons.payments),
          _StatData(l10n.totalAmount,
              '${_formatMontant(montantTot, l10n)} F',
              const Color(0xFF10B981), Icons.account_balance_wallet),
          _StatData(l10n.pending, '$enAttente',
              const Color(0xFFF59E0B), Icons.hourglass_empty),
          _StatData(l10n.successRate,
              '${taux.toStringAsFixed(1)}%',
              const Color(0xFF8B5CF6), Icons.trending_up),
        ];

        return Container(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
          color: isDark
              ? Colors.grey.shade900.withOpacity(0.5)
              : const Color(0xFFF1F5F9),
          child: isW
              ? Row(children: cards
              .map((d) => Expanded(
            child: Padding(
              padding: EdgeInsets.only(
                  right: d != cards.last ? 16 : 0),
              child: _buildStatCard(d, isDark),
            ),
          ))
              .toList())
              : Column(children: [
            Row(children: [
              Expanded(child: _buildStatCard(cards[0], isDark)),
              const SizedBox(width: 12),
              Expanded(child: _buildStatCard(cards[1], isDark)),
            ]),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(child: _buildStatCard(cards[2], isDark)),
              const SizedBox(width: 12),
              Expanded(child: _buildStatCard(cards[3], isDark)),
            ]),
          ]),
        );
      },
    );
  }

  Widget _buildStatCard(_StatData d, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.getCardBackground(context),
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.1 : 0.05),
              blurRadius: 8)
        ],
      ),
      child: Row(children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
              color: d.color.withOpacity(isDark ? 0.2 : 0.1),
              borderRadius: BorderRadius.circular(8)),
          child: Icon(d.icon, color: d.color, size: 22),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(d.value,
                style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: d.color)),
            Text(d.label,
                style: TextStyle(
                    fontSize: 12,
                    color: AppTheme.getTextSecondary(context))),
          ]),
        ),
      ]),
    );
  }

  Widget _buildFiltersCard(bool isDark, AppLocalizations l10n) {
    return Container(
      margin: const EdgeInsets.fromLTRB(24, 0, 24, 12),
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
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.getTextPrimary(context))),
          const Spacer(),
          TextButton.icon(
            onPressed: () => setState(() => _showFilters = false),
            icon: Icon(Icons.close, size: 16,
                color: AppTheme.getTextSecondary(context)),
            label: Text(l10n.close,
                style: TextStyle(color: AppTheme.getTextSecondary(context))),
          ),
        ]),
        const SizedBox(height: 14),
        Row(children: [
          Expanded(child: _datePickerField(
              label: l10n.startDate,
              selected: _selectedDateFrom,
              isDark: isDark, l10n: l10n,
              onPick: (d) => setState(() => _selectedDateFrom = d))),
          const SizedBox(width: 16),
          Expanded(child: _datePickerField(
              label: l10n.endDate,
              selected: _selectedDateTo,
              isDark: isDark, l10n: l10n,
              onPick: (d) => setState(() => _selectedDateTo = d))),
          const SizedBox(width: 16),
          ElevatedButton.icon(
            onPressed: _applyAllFilters,
            icon: const Icon(Icons.check, size: 16, color: Colors.white),
            label: Text(l10n.apply,
                style: const TextStyle(color: Colors.white)),
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.primary,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
          ),
        ]),
      ]),
    );
  }

  Widget _datePickerField({
    required String label,
    required DateTime? selected,
    required bool isDark,
    required AppLocalizations l10n,
    required void Function(DateTime) onPick,
  }) {
    return InkWell(
      onTap: () async {
        final d = await showDatePicker(
          context: context,
          initialDate: selected ?? DateTime.now(),
          firstDate:   DateTime(2020),
          lastDate:    DateTime.now(),
        );
        if (d != null) onPick(d);
      },
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: AppTheme.getTextSecondary(context)),
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: AppTheme.getBorderColor(context))),
          enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: AppTheme.getBorderColor(context))),
          filled: true,
          fillColor: isDark
              ? Colors.grey.shade900.withOpacity(0.3)
              : Colors.grey.shade50,
          suffixIcon: Icon(Icons.calendar_today, size: 16,
              color: AppTheme.getTextSecondary(context)),
        ),
        child: Text(
          selected != null
              ? DateFormat('dd/MM/yyyy', l10n.locale.languageCode)
              .format(selected)
              : l10n.select,
          style: TextStyle(
              color: selected != null
                  ? AppTheme.getTextPrimary(context)
                  : AppTheme.getTextSecondary(context)),
        ),
      ),
    );
  }

  // ── Pagination ──────────────────────────────────────────────────────────

  Widget _buildPagination(
      PaiementAdminProvider p, bool isDark, AppLocalizations l10n) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withOpacity(0.02)
            : const Color(0xFFF8FAFC),
        border: Border(top: BorderSide(color: AppTheme.getBorderColor(context))),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(l10n.totalPaymentsCount(p.totalItems),
              style: TextStyle(
                  color: AppTheme.getTextSecondary(context), fontSize: 13)),
          Row(children: [
            IconButton(
              onPressed: p.currentPage > 1 ? p.loadPreviousPage : null,
              icon: const Icon(Icons.chevron_left),
              color: p.currentPage > 1
                  ? Theme.of(context).colorScheme.primary
                  : AppTheme.getTextTertiary(context),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                  color: AppTheme.getCardBackground(context),
                  borderRadius: BorderRadius.circular(6),
                  border:
                  Border.all(color: AppTheme.getBorderColor(context))),
              child: Text(l10n.pageOf(p.currentPage, p.totalPages),
                  style: TextStyle(
                      color: AppTheme.getTextPrimary(context),
                      fontWeight: FontWeight.w600,
                      fontSize: 13)),
            ),
            IconButton(
              onPressed: p.currentPage < p.totalPages ? p.loadNextPage : null,
              icon: const Icon(Icons.chevron_right),
              color: p.currentPage < p.totalPages
                  ? Theme.of(context).colorScheme.primary
                  : AppTheme.getTextTertiary(context),
            ),
          ]),
        ],
      ),
    );
  }

  // ── États vides / erreur ────────────────────────────────────────────────

  Widget _buildCenteredState({required Widget child, required bool isDark}) {
    return Container(
      decoration: BoxDecoration(
          color: AppTheme.getCardBackground(context),
          borderRadius: BorderRadius.circular(12)),
      child: Center(child: child),
    );
  }

  Widget _buildEmptyState(bool isDark, AppLocalizations l10n) {
    return _buildCenteredState(
      isDark: isDark,
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Icon(Icons.payments_outlined, size: 64,
            color: AppTheme.getTextTertiary(context)),
        const SizedBox(height: 16),
        Text(l10n.noPaymentsFound,
            style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppTheme.getTextSecondary(context))),
        const SizedBox(height: 8),
        Text(l10n.adjustFiltersOrWait,
            style:
            TextStyle(color: AppTheme.getTextTertiary(context))),
        const SizedBox(height: 20),
        ElevatedButton(
          onPressed: _resetFilters,
          style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Colors.white),
          child: Text(l10n.resetFilters),
        ),
      ]),
    );
  }

  Widget _buildErrorWidget(String error, bool isDark, AppLocalizations l10n) {
    return _buildCenteredState(
      isDark: isDark,
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Icon(Icons.error_outline, size: 48, color: Colors.red.shade400),
        const SizedBox(height: 12),
        Text(l10n.loadingError,
            style: TextStyle(
                fontWeight: FontWeight.w600, color: Colors.red.shade400)),
        const SizedBox(height: 8),
        Text(error,
            textAlign: TextAlign.center,
            style: TextStyle(
                color: isDark ? Colors.red.shade300 : const Color(0xFF991B1B))),
        const SizedBox(height: 20),
        ElevatedButton(
          onPressed: _refreshData,
          style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade400,
              foregroundColor: Colors.white),
          child: Text(l10n.retry),
        ),
      ]),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // UTILITAIRES
  // ══════════════════════════════════════════════════════════════════════════

  String _getStatutLabel(String s, AppLocalizations l10n) {
    switch (s) {
      case 'EN_ATTENTE': return l10n.pendingStatus;
      case 'CONFIRME':   return l10n.confirmedStatus;
      case 'ECHEC':      return l10n.failedStatus;
      case 'TOUS':       return l10n.all;
      default:           return s;
    }
  }

  Color _getStatutColor(String s) {
    switch (s) {
      case 'EN_ATTENTE': return const Color(0xFFF59E0B);
      case 'CONFIRME':   return const Color(0xFF10B981);
      case 'ECHEC':      return const Color(0xFFEF4444);
      default:           return const Color(0xFF64748B);
    }
  }

  String _getModeLabel(String m, AppLocalizations l10n) {
    switch (m) {
      case 'ORANGE_MONEY': return l10n.orangeMoney;
      case 'MOOV_MONEY':   return l10n.moovMoney;
      case 'ESPECES':      return l10n.cash;
      case 'VIREMENT':     return l10n.transfer;
      case 'TOUS':         return l10n.all;
      default:             return m;
    }
  }

  // ── Actions filtres ─────────────────────────────────────────────────────

  Future<void> _applySearch(String q) async =>
      Provider.of<PaiementAdminProvider>(context, listen: false)
          .searchPaiements(q);

  Future<void> _applyFilter(String k, dynamic v) async =>
      Provider.of<PaiementAdminProvider>(context, listen: false)
          .applyFilter(k, v);

  Future<void> _applyAllFilters() async {
    final p = Provider.of<PaiementAdminProvider>(context, listen: false);
    await p.applyMultipleFilters({
      'statut':        _selectedStatut,
      'mode_paiement': _selectedMode,
      'search':        _searchController.text,
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
      _selectedStatut    = 'TOUS';
      _selectedMode      = 'TOUS';
      _selectedDateFrom  = null;
      _selectedDateTo    = null;
    });
    await Provider.of<PaiementAdminProvider>(context, listen: false)
        .resetFilters();
  }

  Future<void> _refreshData() async =>
      Provider.of<PaiementAdminProvider>(context, listen: false)
          .loadPaiements();

  // ── Actions paiements ────────────────────────────────────────────────────

  List<PopupMenuEntry<String>> _buildActionMenu(
      Paiement p, AppLocalizations l10n) {
    return [
      PopupMenuItem(
        value: 'details',
        child: Row(children: [
          Icon(Icons.info_outline, size: 17,
              color: AppTheme.getTextSecondary(context)),
          const SizedBox(width: 8),
          Text(l10n.fullDetails,
              style: TextStyle(color: AppTheme.getTextPrimary(context))),
        ]),
      ),
      if (p.statut == 'EN_ATTENTE') ...[
        PopupMenuItem(
          value: 'confirmer',
          child: Row(children: [
            const Icon(Icons.check_circle, size: 17,
                color: Color(0xFF10B981)),
            const SizedBox(width: 8),
            Text(l10n.confirmPayment,
                style: TextStyle(color: AppTheme.getTextPrimary(context))),
          ]),
        ),
        PopupMenuItem(
          value: 'rejeter',
          child: Row(children: [
            const Icon(Icons.cancel, size: 17, color: Color(0xFFEF4444)),
            const SizedBox(width: 8),
            Text(l10n.markAsFailed,
                style: TextStyle(color: AppTheme.getTextPrimary(context))),
          ]),
        ),
      ],
      const PopupMenuDivider(),
      PopupMenuItem(
        value: 'export',
        child: Row(children: [
          Icon(Icons.download, size: 17,
              color: AppTheme.getTextSecondary(context)),
          const SizedBox(width: 8),
          Text(l10n.exportReceipt,
              style: TextStyle(color: AppTheme.getTextPrimary(context))),
        ]),
      ),
    ];
  }

  Future<void> _handleAction(String action, Paiement p,
      PaiementAdminProvider provider, AppLocalizations l10n) async {
    switch (action) {
      case 'details':   _showPaiementDetails(p, provider, l10n); break;
      case 'confirmer': await _confirmPaiement(p.id.toString(), provider, l10n); break;
      case 'rejeter':   await _rejectPaiement(p.id.toString(), provider, l10n); break;
      case 'export':    _exportReceipt(p, l10n); break;
    }
  }

  void _showPaiementDetails(
      Paiement p, PaiementAdminProvider provider, AppLocalizations l10n) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
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
                const Divider(height: 24),
                SingleChildScrollView(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _detailItem(l10n.reference,
                            p.referenceTransaction ?? 'N/A'),
                        _detailItem(l10n.student,    p.etudiantNomComplet),
                        if (p.matricule != null)
                          _detailItem(l10n.matricule, p.matricule!),
                        _detailItem(l10n.center,  p.centreNom ?? 'N/A'),
                        _detailItem(l10n.room,    p.numeroChambre ?? 'N/A'),
                        _detailItem(l10n.amount,
                            '${_formatMontant(p.montant, l10n)} FCFA'),
                        _detailItem(l10n.status,
                            _getStatutLabel(p.statut, l10n)),
                        _detailItem(l10n.mode,
                            _getModeLabel(p.modePaiement, l10n)),
                        _detailItem(l10n.paymentDate,
                            p.datePaiement != null
                                ? DateFormat('dd/MM/yyyy HH:mm',
                                l10n.locale.languageCode)
                                .format(p.datePaiement!)
                                : l10n.notDefined),
                      ]),
                ),
                const Divider(height: 24),
                Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: Text(l10n.close,
                              style: TextStyle(
                                  color:
                                  AppTheme.getTextSecondary(context)))),
                      if (p.statut == 'EN_ATTENTE') ...[
                        const SizedBox(width: 12),
                        ElevatedButton(
                            onPressed: () {
                              Navigator.pop(context);
                              _confirmPaiement(
                                  p.id.toString(), provider, l10n);
                            },
                            style: ElevatedButton.styleFrom(
                                backgroundColor:
                                Theme.of(context).colorScheme.primary,
                                foregroundColor: Colors.white),
                            child: Text(l10n.confirm)),
                      ],
                    ]),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _detailItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label,
            style: TextStyle(
                fontSize: 11,
                color: AppTheme.getTextSecondary(context),
                fontWeight: FontWeight.w500)),
        const SizedBox(height: 3),
        Text(value,
            style: TextStyle(
                fontSize: 15, color: AppTheme.getTextPrimary(context))),
      ]),
    );
  }

  Future<void> _confirmPaiement(String id, PaiementAdminProvider p,
      AppLocalizations l10n) async {
    final ctrl = TextEditingController();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    try {
      final comment = await showDialog<String>(
        context: context,
        builder: (_) => Dialog(
          backgroundColor: AppTheme.getCardBackground(context),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Text(l10n.confirmPaymentTitle,
                  style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.getTextPrimary(context))),
              const SizedBox(height: 12),
              Text(l10n.confirmPaymentQuestion,
                  style: TextStyle(
                      color: AppTheme.getTextSecondary(context))),
              const SizedBox(height: 16),
              TextField(
                  controller: ctrl,
                  decoration: InputDecoration(
                      labelText: l10n.optionalComment,
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8))),
                  maxLines: 2),
              const SizedBox(height: 20),
              Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: Text(l10n.cancel)),
                    const SizedBox(width: 12),
                    ElevatedButton(
                        onPressed: () =>
                            Navigator.pop(context, ctrl.text),
                        style: ElevatedButton.styleFrom(
                            backgroundColor:
                            Theme.of(context).colorScheme.primary,
                            foregroundColor: Colors.white),
                        child: Text(l10n.confirm)),
                  ]),
            ]),
          ),
        ),
      );
      if (comment == null) return;
      await p.updateStatutPaiement(
          paiementId: id,
          nouveauStatut: 'CONFIRME',
          raison: comment.isNotEmpty ? comment : null);
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
      ctrl.dispose();
    }
  }

  Future<void> _rejectPaiement(String id, PaiementAdminProvider p,
      AppLocalizations l10n) async {
    final ctrl = TextEditingController();
    try {
      final raison = await showDialog<String>(
        context: context,
        builder: (_) => Dialog(
          backgroundColor: AppTheme.getCardBackground(context),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Text(l10n.markAsFailedTitle,
                  style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.getTextPrimary(context))),
              const SizedBox(height: 12),
              Text(l10n.indicateFailureReason,
                  style: TextStyle(
                      color: AppTheme.getTextSecondary(context))),
              const SizedBox(height: 16),
              TextField(
                  controller: ctrl,
                  decoration: InputDecoration(
                      labelText: l10n.reason,
                      hintText: l10n.failureReasonHint,
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8))),
                  maxLines: 2),
              const SizedBox(height: 20),
              Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: Text(l10n.cancel)),
                    const SizedBox(width: 12),
                    ElevatedButton(
                        onPressed: () =>
                            Navigator.pop(context, ctrl.text),
                        style: ElevatedButton.styleFrom(
                            backgroundColor:
                            Theme.of(context).colorScheme.primary,
                            foregroundColor: Colors.white),
                        child: Text(l10n.validate)),
                  ]),
            ]),
          ),
        ),
      );
      if (raison == null) return;
      await p.updateStatutPaiement(
          paiementId: id,
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
      ctrl.dispose();
    }
  }

  void _exportReceipt(Paiement p, AppLocalizations l10n) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(l10n.exportReceiptFor(p.referenceTransaction ?? '')),
        behavior: SnackBarBehavior.floating));
  }

  Future<void> _exportPaiements(AppLocalizations l10n) async {
    final provider = Provider.of<PaiementAdminProvider>(context, listen: false);
    if (provider.paiements.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(l10n.noPaymentsToExport),
          backgroundColor: const Color(0xFFF59E0B),
          behavior: SnackBarBehavior.floating));
      return;
    }
    final format = await showDialog<String>(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: AppTheme.getCardBackground(context),
        shape:
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Text(l10n.exportPayments,
                style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.getTextPrimary(context))),
            const SizedBox(height: 12),
            Text(l10n.chooseExportFormat,
                style:
                TextStyle(color: AppTheme.getTextSecondary(context))),
            const SizedBox(height: 20),
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              TextButton(
                  onPressed: () => Navigator.pop(context, 'pdf'),
                  child: const Row(children: [
                    Icon(Icons.picture_as_pdf, color: Colors.red),
                    SizedBox(width: 6),
                    Text('PDF')
                  ])),
              const SizedBox(width: 12),
              TextButton(
                  onPressed: () => Navigator.pop(context, 'excel'),
                  child: const Row(children: [
                    Icon(Icons.table_chart, color: Colors.green),
                    SizedBox(width: 6),
                    Text('Excel')
                  ])),
            ]),
            const SizedBox(height: 12),
            TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(l10n.cancel,
                    style: TextStyle(
                        color: AppTheme.getTextSecondary(context)))),
          ]),
        ),
      ),
    );
    if (format != null && mounted) {
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ExportPreviewScreen(
              format: format,
              paiements: provider.paiements,
              filters: provider.filters),
        ),
      );
    }
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// Widgets auxiliaires
// ══════════════════════════════════════════════════════════════════════════════

/// Dimensions des colonnes du tableau.
class _TableCols {
  final double total;
  late final double etudiant;
  late final double montant;
  late final double statut;
  late final double mode;
  late final double date;
  late final double actions;

  _TableCols(this.total) {
    etudiant = total * 0.22;
    montant  = total * 0.16;
    statut   = total * 0.16;
    mode     = total * 0.18;
    date     = total * 0.18;
    actions  = total * 0.10;
  }
}

/// Données d'une carte statistique.
class _StatData {
  final String label, value;
  final Color color;
  final IconData icon;
  const _StatData(this.label, this.value, this.color, this.icon);
}

/// Badge de statut.
class _StatusBadge extends StatelessWidget {
  final String label;
  final Color color;
  final bool isDark;
  const _StatusBadge({required this.label, required this.color, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(isDark ? 0.2 : 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(isDark ? 0.4 : 0.3)),
      ),
      child: Text(label,
          style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: color)),
    );
  }
}

/// Bouton icône de navigation (nav bar).
class _NavIconButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final Color color;
  final bool isDark;
  final VoidCallback onPressed;
  const _NavIconButton({
    required this.icon, required this.tooltip, required this.color,
    required this.isDark, required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(6),
        child: Container(
          width: 30, height: 30,
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Icon(icon, size: 18, color: color),
        ),
      ),
    );
  }
}

/// Barre de progression de scroll horizontal.
class _HScrollProgressBar extends StatelessWidget {
  final double progress; // 0..1
  final Color color;
  final bool isDark;
  const _HScrollProgressBar({required this.progress, required this.color, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 120,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Scroll',
            style: TextStyle(
              fontSize: 9,
              letterSpacing: 0.8,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white30 : Colors.black26,
            ),
          ),
          const SizedBox(height: 3),
          ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 4,
              backgroundColor: isDark ? Colors.white12 : Colors.black.withOpacity(0.08),
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
        ],
      ),
    );
  }
}