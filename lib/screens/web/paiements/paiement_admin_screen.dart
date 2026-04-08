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

/// Ecran d'administration des paiements.
class PaiementAdminScreen extends StatefulWidget {
  const PaiementAdminScreen({Key? key}) : super(key: key);

  @override
  State<PaiementAdminScreen> createState() => _PaiementAdminScreenState();
}

class _PaiementAdminScreenState extends State<PaiementAdminScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedStatut = 'TOUS';
  String _selectedMode = 'TOUS';
  DateTime? _selectedDateFrom;
  DateTime? _selectedDateTo;
  bool _showFilters = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadInitialData();
    });
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

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return DashboardLayout(
      selectedIndex: 1,
      child: Column(
        children: [
          _buildFloatingFiltersBar(isDark, l10n),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  _buildQuickStats(isDark, l10n),
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    height: _showFilters ? null : 0,
                    child: _showFilters ? _buildFiltersCard(isDark, l10n) : const SizedBox.shrink(),
                  ),
                  _buildPaiementsList(isDark, l10n),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ==================== BARRE DE FILTRES RESPONSIVE ====================

  Widget _buildFloatingFiltersBar(bool isDark, AppLocalizations l10n) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isWide = screenWidth > 1100;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      decoration: BoxDecoration(
        color: AppTheme.getTopBarBackground(context),
        border: Border(bottom: BorderSide(color: AppTheme.getBorderColor(context))),
      ),
      child: isWide
          ? Row(
        children: [
          Expanded(flex: 3, child: _buildSearchField(isDark, l10n)),
          const SizedBox(width: 12),
          SizedBox(width: 160, child: _buildStatutDropdown(isDark, l10n)),
          const SizedBox(width: 12),
          SizedBox(width: 160, child: _buildModeDropdown(isDark, l10n)),
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
              Expanded(child: _buildModeDropdown(isDark, l10n)),
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
        hintText: l10n.searchStudentReference,
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
        fillColor: isDark ? Colors.grey.shade900.withOpacity(0.3) : Colors.grey.shade50,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        isDense: true,
      ),
      dropdownColor: AppTheme.getCardBackground(context),
      items: ['TOUS', 'EN_ATTENTE', 'CONFIRME', 'ECHEC'].map((String value) {
        return DropdownMenuItem<String>(
          value: value,
          child: Text(
            _getStatutLabel(value, l10n),
            style: TextStyle(fontSize: 14, color: AppTheme.getTextPrimary(context)),
          ),
        );
      }).toList(),
      onChanged: (value) {
        setState(() {
          _selectedStatut = value!;
        });
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
      items: ['TOUS', 'ORANGE_MONEY', 'MOOV_MONEY', 'ESPECES', 'VIREMENT'].map((String value) {
        return DropdownMenuItem<String>(
          value: value,
          child: Text(
            _getModeLabel(value, l10n),
            style: TextStyle(fontSize: 14, color: AppTheme.getTextPrimary(context)),
          ),
        );
      }).toList(),
      onChanged: (value) {
        setState(() {
          _selectedMode = value!;
        });
        _applyFilter('mode_paiement', value == 'TOUS' ? null : value);
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
          icon: Icon(Icons.refresh, color: AppTheme.getTextSecondary(context)),
          tooltip: l10n.reset,
        ),
        IconButton(
          onPressed: () => _exportPaiements(l10n),
          icon: Icon(Icons.download, color: Theme.of(context).colorScheme.primary),
          tooltip: l10n.export,
        ),
        ElevatedButton(
          onPressed: _refreshData,
          style: ElevatedButton.styleFrom(
            backgroundColor: Theme.of(context).colorScheme.primary,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
          child: Text(l10n.refresh, style: const TextStyle(color: Colors.white)),
        ),
      ],
    );
  }

  // ==================== STATISTIQUES RESPONSIVES ====================

  Widget _buildQuickStats(bool isDark, AppLocalizations l10n) {
    return Consumer<PaiementAdminProvider>(
      builder: (context, provider, child) {
        final stats = provider.statistiques ?? {};

        final totalPaiements = (int.tryParse(stats['confirmes'] ?? '0') ?? 0) +
            (int.tryParse(stats['en_attente'] ?? '0') ?? 0) +
            (int.tryParse(stats['echecs'] ?? '0') ?? 0);

        final montantTotal = (double.tryParse(stats['total_confirme'] ?? '0') ?? 0) +
            (double.tryParse(stats['total_en_attente'] ?? '0') ?? 0) +
            (double.tryParse(stats['total_echec'] ?? '0') ?? 0);

        final enAttente = int.tryParse(stats['en_attente'] ?? '0') ?? 0;
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
          color: isDark ? Colors.grey.shade900.withOpacity(0.5) : const Color(0xFFF1F5F9),
          child: isWide
              ? Row(
            children: [
              Expanded(child: _buildStatCard(
                label: l10n.totalPayments,
                value: '$totalPaiements',
                color: const Color(0xFF3B82F6),
                icon: Icons.payments,
                isDark: isDark,
              )),
              const SizedBox(width: 16),
              Expanded(child: _buildStatCard(
                label: l10n.totalAmount,
                value: '${_formatMontant(montantTotal, l10n)} F',
                color: const Color(0xFF10B981),
                icon: Icons.account_balance_wallet,
                isDark: isDark,
              )),
              const SizedBox(width: 16),
              Expanded(child: _buildStatCard(
                label: l10n.pending,
                value: '$enAttente',
                color: const Color(0xFFF59E0B),
                icon: Icons.hourglass_empty,
                isDark: isDark,
              )),
              const SizedBox(width: 16),
              Expanded(child: _buildStatCard(
                label: l10n.successRate,
                value: '${tauxReussite.toStringAsFixed(1)}%',
                color: const Color(0xFF8B5CF6),
                icon: Icons.trending_up,
                isDark: isDark,
              )),
            ],
          )
              : Column(
            children: [
              Row(
                children: [
                  Expanded(child: _buildStatCard(
                    label: l10n.total,
                    value: '$totalPaiements',
                    color: const Color(0xFF3B82F6),
                    icon: Icons.payments,
                    isDark: isDark,
                  )),
                  const SizedBox(width: 12),
                  Expanded(child: _buildStatCard(
                    label: l10n.amount,
                    value: '${_formatMontant(montantTotal, l10n)} F',
                    color: const Color(0xFF10B981),
                    icon: Icons.account_balance_wallet,
                    isDark: isDark,
                  )),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(child: _buildStatCard(
                    label: l10n.pending,
                    value: '$enAttente',
                    color: const Color(0xFFF59E0B),
                    icon: Icons.hourglass_empty,
                    isDark: isDark,
                  )),
                  const SizedBox(width: 12),
                  Expanded(child: _buildStatCard(
                    label: l10n.rate,
                    value: '${tauxReussite.toStringAsFixed(1)}%',
                    color: const Color(0xFF8B5CF6),
                    icon: Icons.trending_up,
                    isDark: isDark,
                  )),
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
                onPressed: () {
                  setState(() {
                    _showFilters = false;
                  });
                },
                icon: Icon(Icons.close, size: 16, color: AppTheme.getTextSecondary(context)),
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
                child: InkWell(
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: _selectedDateFrom ?? DateTime.now(),
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
                    if (date != null) {
                      setState(() {
                        _selectedDateFrom = date;
                      });
                    }
                  },
                  child: InputDecorator(
                    decoration: InputDecoration(
                      labelText: l10n.startDate,
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
                      _selectedDateFrom != null
                          ? DateFormat('dd/MM/yyyy', l10n.locale.languageCode).format(_selectedDateFrom!)
                          : l10n.select,
                      style: TextStyle(
                        color: _selectedDateFrom != null
                            ? AppTheme.getTextPrimary(context)
                            : AppTheme.getTextSecondary(context),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: InkWell(
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: _selectedDateTo ?? DateTime.now(),
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
                    if (date != null) {
                      setState(() {
                        _selectedDateTo = date;
                      });
                    }
                  },
                  child: InputDecorator(
                    decoration: InputDecoration(
                      labelText: l10n.endDate,
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
                      _selectedDateTo != null
                          ? DateFormat('dd/MM/yyyy', l10n.locale.languageCode).format(_selectedDateTo!)
                          : l10n.select,
                      style: TextStyle(
                        color: _selectedDateTo != null
                            ? AppTheme.getTextPrimary(context)
                            : AppTheme.getTextSecondary(context),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              ElevatedButton.icon(
                onPressed: _applyAllFilters,
                icon: Icon(Icons.check, size: 18, color: Colors.white),
                label: Text(l10n.apply, style: const TextStyle(color: Colors.white)),
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

  // ==================== LISTE DES PAIEMENTS ====================

  Widget _buildPaiementsList(bool isDark, AppLocalizations l10n) {
    return Consumer<PaiementAdminProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading && provider.paiements.isEmpty) {
          return const Center(child: Padding(padding: EdgeInsets.all(48.0), child: CircularProgressIndicator()));
        }
        if (provider.error != null && provider.paiements.isEmpty) {
          return _buildErrorWidget(provider.error!, isDark, l10n);
        }
        if (provider.paiements.isEmpty) {
          return _buildEmptyState(isDark, l10n);
        }

        final screenWidth = MediaQuery.of(context).size.width;
        final sidebarWidth = screenWidth > 900 ? 220.0 : 0.0;
        final availableWidth = screenWidth - sidebarWidth - 48; // 48 = margins (24*2)

        final tableWidth = availableWidth > 700 ? availableWidth : 700.0;

        final colEtudiant = tableWidth * 0.22;
        final colMontant  = tableWidth * 0.16;
        final colStatut   = tableWidth * 0.16;
        final colMode     = tableWidth * 0.18;
        final colDate     = tableWidth * 0.18;
        final colActions  = tableWidth * 0.10;

        return Container(
          margin: const EdgeInsets.fromLTRB(24, 0, 24, 24),
          decoration: BoxDecoration(
            color: AppTheme.getCardBackground(context),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(isDark ? 0.1 : 0.05), blurRadius: 10)],
          ),
          child: Column(
            children: [
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: SizedBox(
                  width: tableWidth,
                  child: Column(
                    children: [
                      // En-tête
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                        decoration: BoxDecoration(
                          color: isDark ? Colors.grey.shade900.withOpacity(0.5) : const Color(0xFFF8FAFC),
                          borderRadius: const BorderRadius.only(topLeft: Radius.circular(12), topRight: Radius.circular(12)),
                          border: Border(bottom: BorderSide(color: AppTheme.getBorderColor(context), width: 1)),
                        ),
                        child: Row(
                          children: [
                            SizedBox(width: colEtudiant, child: _headerText(l10n.student)),
                            SizedBox(width: colMontant,  child: _headerText(l10n.amount)),
                            SizedBox(width: colStatut,   child: _headerText(l10n.status)),
                            SizedBox(width: colMode,     child: _headerText(l10n.mode)),
                            SizedBox(width: colDate,     child: _headerText(l10n.date)),
                            SizedBox(width: colActions,  child: _headerText(l10n.actions)),
                          ],
                        ),
                      ),
                      // Lignes
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: provider.paiements.length,
                        itemBuilder: (context, index) {
                          return _buildPaiementRow(
                            provider.paiements[index], provider, index, isDark, l10n,
                            colEtudiant: colEtudiant,
                            colMontant: colMontant,
                            colStatut: colStatut,
                            colMode: colMode,
                            colDate: colDate,
                            colActions: colActions,
                          );
                        },
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
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: index.isEven
            ? AppTheme.getCardBackground(context)
            : (isDark ? Colors.grey.shade900.withOpacity(0.3) : const Color(0xFFFAFAFA)),
        border: Border(bottom: BorderSide(color: AppTheme.getBorderColor(context), width: 1)),
      ),
      child: Row(
        children: [
          // Etudiant
          SizedBox(
            width: colEtudiant,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  paiement.etudiantNomComplet,
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
                  paiement.matricule ?? 'N/A',
                  style: TextStyle(fontSize: 12, color: AppTheme.getTextSecondary(context)),
                ),
                if (paiement.centreNom != null)
                  Text(
                    l10n.centerRoom(paiement.centreNom!, paiement.numeroChambre ?? "N/A"),
                    style: TextStyle(fontSize: 11, color: AppTheme.getTextTertiary(context)),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
          // Montant
          SizedBox(
            width: colMontant,
            child: Text(
              '${_formatMontant(paiement.montant, l10n)} F',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: paiement.montant > 0 ? const Color(0xFF10B981) : const Color(0xFFEF4444),
              ),
            ),
          ),
          // Statut - avec badge auto-ajusté, aligné à gauche
          SizedBox(
            width: colStatut,
            child: Align(
              alignment: Alignment.centerLeft,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: _getStatutColor(paiement.statut).withOpacity(isDark ? 0.2 : 0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: _getStatutColor(paiement.statut).withOpacity(isDark ? 0.4 : 0.3),
                  ),
                ),
                child: Text(
                  _getStatutLabel(paiement.statut, l10n),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: _getStatutColor(paiement.statut),
                  ),
                ),
              ),
            ),
          ),
          // Mode
          SizedBox(
            width: colMode,
            child: Text(
              _getModeLabel(paiement.modePaiement, l10n),
              style: TextStyle(color: AppTheme.getTextSecondary(context), fontSize: 13),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          // Date
          SizedBox(
            width: colDate,
            child: Text(
              paiement.datePaiement != null
                  ? DateFormat('dd/MM/yy HH:mm', l10n.locale.languageCode).format(paiement.datePaiement!)
                  : 'N/A',
              style: TextStyle(color: AppTheme.getTextSecondary(context), fontSize: 13),
            ),
          ),
          // Actions
          SizedBox(
            width: colActions,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                IconButton(
                  onPressed: () => _showPaiementDetails(paiement, provider, l10n),
                  icon: Icon(Icons.visibility_outlined, size: 20, color: AppTheme.getTextSecondary(context)),
                  tooltip: l10n.viewDetails,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
                const SizedBox(width: 8),
                PopupMenuButton<String>(
                  icon: Icon(Icons.more_vert, size: 20, color: AppTheme.getTextSecondary(context)),
                  color: AppTheme.getCardBackground(context),
                  surfaceTintColor: AppTheme.getCardBackground(context),
                  itemBuilder: (context) => _buildActionMenu(paiement, l10n),
                  onSelected: (value) => _handleAction(value, paiement, provider, l10n),
                  padding: EdgeInsets.zero,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<PopupMenuEntry<String>> _buildActionMenu(Paiement paiement, AppLocalizations l10n) {
    return [
      PopupMenuItem<String>(
        value: 'details',
        child: Row(
          children: [
            Icon(Icons.info_outline, size: 18, color: AppTheme.getTextSecondary(context)),
            const SizedBox(width: 8),
            Text(l10n.fullDetails, style: TextStyle(color: AppTheme.getTextPrimary(context))),
          ],
        ),
      ),
      if (paiement.statut == 'EN_ATTENTE') ...[
        PopupMenuItem<String>(
          value: 'confirmer',
          child: Row(
            children: [
              Icon(Icons.check_circle, size: 18, color: const Color(0xFF10B981)),
              const SizedBox(width: 8),
              Text(l10n.confirmPayment, style: TextStyle(color: AppTheme.getTextPrimary(context))),
            ],
          ),
        ),
        PopupMenuItem<String>(
          value: 'rejeter',
          child: Row(
            children: [
              Icon(Icons.cancel, size: 18, color: const Color(0xFFEF4444)),
              const SizedBox(width: 8),
              Text(l10n.markAsFailed, style: TextStyle(color: AppTheme.getTextPrimary(context))),
            ],
          ),
        ),
      ],
      const PopupMenuDivider(),
      PopupMenuItem<String>(
        value: 'export',
        child: Row(
          children: [
            Icon(Icons.download, size: 18, color: AppTheme.getTextSecondary(context)),
            const SizedBox(width: 8),
            Text(l10n.exportReceipt, style: TextStyle(color: AppTheme.getTextPrimary(context))),
          ],
        ),
      ),
    ];
  }

  Widget _buildPagination(PaiementAdminProvider provider, bool isDark, AppLocalizations l10n) {
    return Container(
      padding: const EdgeInsets.all(20),
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
            l10n.totalPaymentsCount(provider.totalItems),
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
                  l10n.pageOf(provider.currentPage, provider.totalPages),
                  style: TextStyle(color: AppTheme.getTextPrimary(context), fontWeight: FontWeight.w500),
                ),
              ),
              IconButton(
                onPressed: provider.currentPage < provider.totalPages ? provider.loadNextPage : null,
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
            Icon(Icons.payments_outlined, size: 80, color: AppTheme.getTextTertiary(context)),
            const SizedBox(height: 24),
            Text(
              l10n.noPaymentsFound,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: AppTheme.getTextSecondary(context)),
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
        color: isDark ? Colors.red.shade900.withOpacity(0.1) : const Color(0xFFFEF2F2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isDark ? Colors.red.shade800 : const Color(0xFFFECACA)),
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 48, color: Colors.red.shade400),
            const SizedBox(height: 16),
            Text(
              l10n.loadingError,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.red.shade400),
            ),
            const SizedBox(height: 8),
            Text(
              error,
              textAlign: TextAlign.center,
              style: TextStyle(color: isDark ? Colors.red.shade300 : const Color(0xFF991B1B)),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _refreshData,
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red.shade400, foregroundColor: Colors.white),
              child: Text(l10n.retry),
            ),
          ],
        ),
      ),
    );
  }

  // ==================== UTILITAIRES D'AFFICHAGE ====================

  String _getStatutLabel(String statut, AppLocalizations l10n) {
    switch (statut) {
      case 'EN_ATTENTE': return l10n.pendingStatus;
      case 'CONFIRME': return l10n.confirmedStatus;
      case 'ECHEC': return l10n.failedStatus;
      case 'TOUS': return l10n.all;
      default: return statut;
    }
  }

  Color _getStatutColor(String statut) {
    switch (statut) {
      case 'EN_ATTENTE': return const Color(0xFFF59E0B);
      case 'CONFIRME': return const Color(0xFF10B981);
      case 'ECHEC': return const Color(0xFFEF4444);
      default: return const Color(0xFF64748B);
    }
  }

  String _getModeLabel(String mode, AppLocalizations l10n) {
    switch (mode) {
      case 'ORANGE_MONEY': return l10n.orangeMoney;
      case 'MOOV_MONEY': return l10n.moovMoney;
      case 'ESPECES': return l10n.cash;
      case 'VIREMENT': return l10n.transfer;
      case 'TOUS': return l10n.all;
      default: return mode;
    }
  }

  // ==================== ACTIONS SUR LES FILTRES ====================

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
    Map<String, dynamic> filterData = {
      'statut': _selectedStatut,
      'mode_paiement': _selectedMode,
      'search': _searchController.text,
      'date_from': _selectedDateFrom != null ? DateFormat('yyyy-MM-dd').format(_selectedDateFrom!) : null,
      'date_to': _selectedDateTo != null ? DateFormat('yyyy-MM-dd').format(_selectedDateTo!) : null,
    };
    await provider.applyMultipleFilters(filterData);
  }

  Future<void> _resetFilters() async {
    setState(() {
      _searchController.clear();
      _selectedStatut = 'TOUS';
      _selectedMode = 'TOUS';
      _selectedDateFrom = null;
      _selectedDateTo = null;
    });
    final provider = Provider.of<PaiementAdminProvider>(context, listen: false);
    await provider.resetFilters();
  }

  Future<void> _refreshData() async {
    final provider = Provider.of<PaiementAdminProvider>(context, listen: false);
    await provider.loadPaiements();
  }

  // ==================== ACTIONS SUR LES PAIEMENTS ====================

  void _showPaiementDetails(Paiement paiement, PaiementAdminProvider provider, AppLocalizations l10n) {
    showDialog(
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
                Text(l10n.paymentDetails,
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold,
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
                      if (paiement.typeChambre != null) _buildDetailItem(l10n.roomType, paiement.typeChambre!, l10n),
                      _buildDetailItem(l10n.paymentType, paiement.typePaiement ?? l10n.rent, l10n),
                      _buildDetailItem(l10n.amount, '${_formatMontant(paiement.montant, l10n)} FCFA', l10n),
                      _buildDetailItem(l10n.status, _getStatutLabel(paiement.statut, l10n), l10n),
                      _buildDetailItem(l10n.mode, _getModeLabel(paiement.modePaiement, l10n), l10n),
                      _buildDetailItem(l10n.paymentDate, paiement.datePaiement != null
                          ? DateFormat('dd/MM/yyyy HH:mm', l10n.locale.languageCode).format(paiement.datePaiement!) : l10n.notDefined, l10n),
                      if (paiement.dateEcheance != null)
                        _buildDetailItem(l10n.dueDate, DateFormat('dd/MM/yyyy', l10n.locale.languageCode).format(paiement.dateEcheance!), l10n),
                      if (paiement.prixMensuel != null)
                        _buildDetailItem(l10n.monthlyPrice, '${_formatMontant(paiement.prixMensuel!, l10n)} FCFA', l10n),
                      if (paiement.centreVille != null) _buildDetailItem(l10n.city, paiement.centreVille!, l10n),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text(l10n.close, style: TextStyle(color: AppTheme.getTextSecondary(context))),
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
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDetailItem(String label, String value, AppLocalizations l10n) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(fontSize: 12, color: AppTheme.getTextSecondary(context), fontWeight: FontWeight.w500)),
          const SizedBox(height: 4),
          Text(value, style: TextStyle(fontSize: 16, color: AppTheme.getTextPrimary(context))),
        ],
      ),
    );
  }

  Future<void> _handleAction(String action, Paiement paiement, PaiementAdminProvider provider, AppLocalizations l10n) async {
    switch (action) {
      case 'details': _showPaiementDetails(paiement, provider, l10n); break;
      case 'confirmer': await _confirmPaiement(paiement.id.toString(), provider, l10n); break;
      case 'rejeter': await _rejectPaiement(paiement.id.toString(), provider, l10n); break;
      case 'export': _exportReceipt(paiement, l10n); break;
    }
  }

  Future<void> _confirmPaiement(String paiementId, PaiementAdminProvider provider, AppLocalizations l10n) async {
    final commentaireController = TextEditingController();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    try {
      final commentaire = await showDialog<String>(
        context: context,
        builder: (context) => Dialog(
          backgroundColor: AppTheme.getCardBackground(context),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Container(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l10n.confirmPaymentTitle, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.getTextPrimary(context))),
                const SizedBox(height: 16),
                Text(l10n.confirmPaymentQuestion, style: TextStyle(color: AppTheme.getTextSecondary(context))),
                const SizedBox(height: 16),
                TextField(
                  controller: commentaireController,
                  decoration: InputDecoration(
                    labelText: l10n.optionalComment,
                    labelStyle: TextStyle(color: AppTheme.getTextSecondary(context)),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: AppTheme.getBorderColor(context))),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: AppTheme.getBorderColor(context))),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Theme.of(context).colorScheme.primary, width: 2)),
                    filled: true,
                    fillColor: isDark ? Colors.grey.shade900.withOpacity(0.3) : Colors.grey.shade50,
                  ),
                  maxLines: 3,
                  style: TextStyle(color: AppTheme.getTextPrimary(context)),
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(onPressed: () => Navigator.pop(context), child: Text(l10n.cancel, style: TextStyle(color: AppTheme.getTextSecondary(context)))),
                    const SizedBox(width: 12),
                    ElevatedButton(
                      onPressed: () => Navigator.pop(context, commentaireController.text),
                      style: ElevatedButton.styleFrom(backgroundColor: Theme.of(context).colorScheme.primary, foregroundColor: Colors.white),
                      child: Text(l10n.confirm),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );
      if (commentaire == null) return;
      await provider.updateStatutPaiement(paiementId: paiementId, nouveauStatut: 'CONFIRME', raison: commentaire.isNotEmpty ? commentaire : null);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.paymentConfirmedSuccess), backgroundColor: const Color(0xFF10B981), behavior: SnackBarBehavior.floating));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${l10n.error}: $e'), backgroundColor: const Color(0xFFEF4444), behavior: SnackBarBehavior.floating));
      }
    } finally {
      commentaireController.dispose();
    }
  }

  Future<void> _rejectPaiement(String paiementId, PaiementAdminProvider provider, AppLocalizations l10n) async {
    final raisonController = TextEditingController();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    try {
      final raison = await showDialog<String>(
        context: context,
        builder: (context) => Dialog(
          backgroundColor: AppTheme.getCardBackground(context),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Container(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l10n.markAsFailedTitle, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.getTextPrimary(context))),
                const SizedBox(height: 16),
                Text(l10n.indicateFailureReason, style: TextStyle(color: AppTheme.getTextSecondary(context))),
                const SizedBox(height: 16),
                TextField(
                  controller: raisonController,
                  decoration: InputDecoration(
                    labelText: l10n.reason,
                    labelStyle: TextStyle(color: AppTheme.getTextSecondary(context)),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: AppTheme.getBorderColor(context))),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: AppTheme.getBorderColor(context))),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Theme.of(context).colorScheme.primary, width: 2)),
                    hintText: l10n.failureReasonHint,
                    hintStyle: TextStyle(color: AppTheme.getTextTertiary(context)),
                    filled: true,
                    fillColor: isDark ? Colors.grey.shade900.withOpacity(0.3) : Colors.grey.shade50,
                  ),
                  maxLines: 3,
                  style: TextStyle(color: AppTheme.getTextPrimary(context)),
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(onPressed: () => Navigator.pop(context), child: Text(l10n.cancel, style: TextStyle(color: AppTheme.getTextSecondary(context)))),
                    const SizedBox(width: 12),
                    ElevatedButton(
                      onPressed: () => Navigator.pop(context, raisonController.text),
                      style: ElevatedButton.styleFrom(backgroundColor: Theme.of(context).colorScheme.primary, foregroundColor: Colors.white),
                      child: Text(l10n.validate),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );
      if (raison == null) return;
      await provider.updateStatutPaiement(paiementId: paiementId, nouveauStatut: 'ECHEC', raison: raison.isNotEmpty ? raison : null);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.paymentMarkedAsFailed), backgroundColor: const Color(0xFFEF4444), behavior: SnackBarBehavior.floating));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${l10n.error}: $e'), backgroundColor: const Color(0xFFEF4444), behavior: SnackBarBehavior.floating));
      }
    } finally {
      raisonController.dispose();
    }
  }

  void _exportReceipt(Paiement paiement, AppLocalizations l10n) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.exportReceiptFor(paiement.referenceTransaction ?? '')), behavior: SnackBarBehavior.floating));
  }

  // ==================== EXPORT ====================

  Future<void> _exportPaiements(AppLocalizations l10n) async {
    final provider = Provider.of<PaiementAdminProvider>(context, listen: false);
    if (provider.paiements.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.noPaymentsToExport), backgroundColor: const Color(0xFFF59E0B), behavior: SnackBarBehavior.floating));
      return;
    }
    final format = await showDialog<String>(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: AppTheme.getCardBackground(context),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l10n.exportPayments, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.getTextPrimary(context))),
              const SizedBox(height: 16),
              Text(l10n.chooseExportFormat, style: TextStyle(color: AppTheme.getTextSecondary(context))),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  TextButton(onPressed: () => Navigator.pop(context, 'pdf'), child: Row(children: const [Icon(Icons.picture_as_pdf, color: Colors.red), SizedBox(width: 8), Text('PDF')])),
                  const SizedBox(width: 16),
                  TextButton(onPressed: () => Navigator.pop(context, 'excel'), child: Row(children: const [Icon(Icons.table_chart, color: Colors.green), SizedBox(width: 8), Text('Excel')])),
                  const SizedBox(width: 16),
                  TextButton(onPressed: () => Navigator.pop(context, 'word'), child: Row(children: const [Icon(Icons.description, color: Colors.blue), SizedBox(width: 8), Text('Word')])),
                ],
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(onPressed: () => Navigator.pop(context), child: Text(l10n.cancel, style: TextStyle(color: AppTheme.getTextSecondary(context)))),
                ],
              ),
            ],
          ),
        ),
      ),
    );
    if (format != null) {
      try {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.generatingFormat(format.toUpperCase())), duration: const Duration(seconds: 2), behavior: SnackBarBehavior.floating));
        await Navigator.push(context, MaterialPageRoute(builder: (context) => ExportPreviewScreen(format: format, paiements: provider.paiements, filters: provider.filters)));
      } catch (e) {
        print('Erreur export $format: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${l10n.exportError}: $e'), backgroundColor: const Color(0xFFEF4444), behavior: SnackBarBehavior.floating));
        }
      }
    }
  }

  Future<void> _exportPdfBackend(PaiementAdminProvider provider) async {
    if (!kIsWeb) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Export PDF disponible uniquement sur web'), backgroundColor: Color(0xFFF59E0B)));
      return;
    }
    try {
      print('Demande generation PDF backend...');
      final filters = <String, dynamic>{'format': 'pdf', 'periode': 'personnalisee'};
      if (_selectedDateFrom != null) filters['date_debut'] = DateFormat('yyyy-MM-dd').format(_selectedDateFrom!);
      if (_selectedDateTo != null) filters['date_fin'] = DateFormat('yyyy-MM-dd').format(_selectedDateTo!);
      if (_selectedStatut != 'TOUS') filters['statut'] = _selectedStatut;
      if (_selectedMode != 'TOUS') filters['mode_paiement'] = _selectedMode;
      print('Payload PDF envoye: $filters');
      final response = await provider.apiService.post('/api/rapports/financier', body: filters);
      print('Reponse recue du backend');
      if (response is http.Response && response.statusCode == 200) {
        final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
        final filename = 'rapport_paiements_$timestamp.pdf';
        HtmlUtils.downloadFile(bytes: response.bodyBytes, fileName: filename, mimeType: 'application/pdf');
        print('PDF telecharge: $filename');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('PDF telecharge avec succes'), backgroundColor: Color(0xFF10B981), duration: Duration(seconds: 3)));
        }
      } else if (response is Map<String, dynamic> && response['success'] == true) {
        if (response['file_url'] != null) {
          HtmlUtils.openInNewTab(response['file_url']);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('PDF ouvert dans un nouvel onglet'), backgroundColor: Color(0xFF10B981), duration: Duration(seconds: 3)));
          }
        }
      }
    } catch (e) {
      print('Erreur export PDF backend: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur lors de l\'export PDF: $e'), backgroundColor: const Color(0xFFEF4444)));
      }
    }
  }

  String _generateCsvContent(List<Paiement> paiements, AppLocalizations l10n) {
    final buffer = StringBuffer();
    buffer.writeln('${l10n.reference},${l10n.student},${l10n.matricule},${l10n.center},${l10n.room},${l10n.amount},${l10n.status},${l10n.mode},${l10n.date}');
    for (final p in paiements) {
      final dateStr = p.datePaiement != null ? DateFormat('dd/MM/yyyy HH:mm', l10n.locale.languageCode).format(p.datePaiement!) : 'N/A';
      buffer.writeln([
        '"${p.referenceTransaction ?? 'N/A'}"',
        '"${p.etudiantNomComplet}"',
        '"${p.matricule ?? 'N/A'}"',
        '"${p.centreNom ?? 'N/A'}"',
        '"${p.numeroChambre ?? 'N/A'}"',
        '${_formatMontant(p.montant, l10n)}',
        '"${_getStatutLabel(p.statut, l10n)}"',
        '"${_getModeLabel(p.modePaiement, l10n)}"',
        '"$dateStr"',
      ].join(','));
    }
    return buffer.toString();
  }

  Future<void> _exportCsvLocal(PaiementAdminProvider provider) async {
    if (!kIsWeb) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Export CSV disponible uniquement sur web'), backgroundColor: Color(0xFFF59E0B)));
      return;
    }
    try {
      if (mounted) {
        await Navigator.push(context, MaterialPageRoute(builder: (context) => ExportPreviewScreen(format: 'csv', paiements: provider.paiements, filters: provider.filters)));
      }
    } catch (e) {
      print('Erreur export CSV: $e');
      try {
        final csvContent = _generateCsvContent(provider.paiements, AppLocalizations.of(context));
        final bytes = utf8.encode(csvContent);
        final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
        HtmlUtils.downloadFile(bytes: bytes, fileName: 'paiements_$timestamp.csv', mimeType: 'text/csv');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('CSV exporte avec succes'), backgroundColor: Color(0xFF10B981)));
        }
      } catch (fallbackError) {
        print('Erreur fallback CSV: $fallbackError');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur lors de l\'export CSV: $fallbackError'), backgroundColor: const Color(0xFFEF4444)));
        }
      }
    }
  }
}