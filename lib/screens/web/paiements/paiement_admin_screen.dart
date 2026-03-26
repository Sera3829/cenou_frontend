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

/// Écran d'administration des paiements.
///
/// Permet de consulter, filtrer, exporter et gérer les paiements étudiants.
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

  /// Formate un montant avec séparateur de milliers.
  String _formatMontant(double montant) {
    final formatter = NumberFormat('#,##0', 'fr_FR');
    return formatter.format(montant);
  }

  /// Charge les données initiales (paiements et statistiques).
  Future<void> _loadInitialData() async {
    final provider = Provider.of<PaiementAdminProvider>(context, listen: false);
    await provider.loadPaiements();
    await provider.loadStatistiques();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return DashboardLayout(
      selectedIndex: 1,
      child: Column(
        children: [
          _buildFloatingFiltersBar(isDark),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  _buildQuickStats(isDark),
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    height: _showFilters ? null : 0,
                    child: _showFilters ? _buildFiltersCard(isDark) : const SizedBox.shrink(),
                  ),
                  _buildPaiementsList(isDark),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Barre flottante des filtres principaux (recherche, statut, mode).
  Widget _buildFloatingFiltersBar(bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
      decoration: BoxDecoration(
        color: AppTheme.getTopBarBackground(context),
        border: Border(
          bottom: BorderSide(color: AppTheme.getBorderColor(context), width: 1),
        ),
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
                hintText: 'Rechercher un étudiant, référence...',
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
            ),
          ),

          const SizedBox(width: 12),

          SizedBox(
            width: 180,
            child: DropdownButtonFormField<String>(
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
                fillColor: isDark ? Colors.grey.shade900.withOpacity(0.3) : Colors.grey.shade50,
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                isDense: true,
              ),
              dropdownColor: AppTheme.getCardBackground(context),
              items: [
                'TOUS',
                'EN_ATTENTE',
                'CONFIRME',
                'ECHEC',
              ].map((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(
                    _getStatutLabel(value),
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
            ),
          ),

          const SizedBox(width: 12),

          SizedBox(
            width: 180,
            child: DropdownButtonFormField<String>(
              value: _selectedMode,
              decoration: InputDecoration(
                labelText: 'Mode',
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
              items: [
                'TOUS',
                'ORANGE_MONEY',
                'MOOV_MONEY',
                'ESPECES',
                'VIREMENT',
              ].map((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(
                    _getModeLabel(value),
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
            ),
          ),

          const SizedBox(width: 12),

          OutlinedButton.icon(
            onPressed: () {
              setState(() {
                _showFilters = !_showFilters;
              });
            },
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
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
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
            onPressed: _exportPaiements,
            icon: Icon(Icons.download, size: 18, color: Theme.of(context).colorScheme.primary),
            label: Text(
              'Exporter',
              style: TextStyle(color: Theme.of(context).colorScheme.primary),
            ),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              side: BorderSide(color: Theme.of(context).colorScheme.primary.withOpacity(0.5)),
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
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Section des indicateurs rapides (statistiques).
  Widget _buildQuickStats(bool isDark) {
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
        final echecs = int.tryParse(stats['echecs'] ?? '0') ?? 0;

        final tauxReussite = totalPaiements > 0
            ? ((confirmes / totalPaiements) * 100)
            : 0;

        return Container(
          padding: const EdgeInsets.all(24),
          color: isDark ? Colors.grey.shade900.withOpacity(0.5) : const Color(0xFFF1F5F9),
          child: Row(
            children: [
              _buildStatCard(
                label: 'Total Paiements',
                value: '$totalPaiements',
                color: const Color(0xFF3B82F6),
                icon: Icons.payments,
                isDark: isDark,
              ),
              const SizedBox(width: 16),
              _buildStatCard(
                label: 'Montant Total',
                value: '${_formatMontant(montantTotal)} F',
                color: const Color(0xFF10B981),
                icon: Icons.account_balance_wallet,
                isDark: isDark,
              ),
              const SizedBox(width: 16),
              _buildStatCard(
                label: 'En Attente',
                value: '$enAttente',
                color: const Color(0xFFF59E0B),
                icon: Icons.hourglass_empty,
                isDark: isDark,
              ),
              const SizedBox(width: 16),
              _buildStatCard(
                label: 'Taux Réussite',
                value: '${tauxReussite.toStringAsFixed(1)}%',
                color: const Color(0xFF8B5CF6),
                icon: Icons.trending_up,
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
      ),
    );
  }

  /// Carte des filtres avancés (dates).
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
                'Filtres avancés',
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
                  'Fermer',
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
                      labelText: 'Date début',
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
                          ? DateFormat('dd/MM/yyyy').format(_selectedDateFrom!)
                          : 'Sélectionner',
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
                      labelText: 'Date fin',
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
                          ? DateFormat('dd/MM/yyyy').format(_selectedDateTo!)
                          : 'Sélectionner',
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
                label: const Text('Appliquer', style: TextStyle(color: Colors.white)),
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

  /// Liste des paiements avec en‑tête et pagination.
  Widget _buildPaiementsList(bool isDark) {
    return Consumer<PaiementAdminProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading && provider.paiements.isEmpty) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(48.0),
              child: CircularProgressIndicator(),
            ),
          );
        }

        if (provider.error != null && provider.paiements.isEmpty) {
          return _buildErrorWidget(provider.error!, isDark);
        }

        if (provider.paiements.isEmpty) {
          return _buildEmptyState(isDark);
        }

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
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: isDark ? Colors.grey.shade900.withOpacity(0.5) : const Color(0xFFF8FAFC),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(12),
                    topRight: Radius.circular(12),
                  ),
                  border: Border(
                    bottom: BorderSide(color: AppTheme.getBorderColor(context), width: 1),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: Text(
                        'Étudiant',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppTheme.getTextPrimary(context),
                          fontSize: 13,
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: Text(
                        'Montant',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppTheme.getTextPrimary(context),
                          fontSize: 13,
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: Text(
                        'Statut',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppTheme.getTextPrimary(context),
                          fontSize: 13,
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: Text(
                        'Mode',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppTheme.getTextPrimary(context),
                          fontSize: 13,
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: Text(
                        'Date',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppTheme.getTextPrimary(context),
                          fontSize: 13,
                        ),
                      ),
                    ),
                    const SizedBox(width: 100),
                  ],
                ),
              ),

              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: provider.paiements.length,
                itemBuilder: (context, index) {
                  final paiement = provider.paiements[index];
                  return _buildPaiementRow(paiement, provider, index, isDark);
                },
              ),

              _buildPagination(provider, isDark),
            ],
          ),
        );
      },
    );
  }

  /// Ligne d’un paiement dans la liste.
  Widget _buildPaiementRow(Paiement paiement, PaiementAdminProvider provider,
      int index, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: index.isEven ? AppTheme.getCardBackground(context)
            : (isDark ? Colors.grey.shade900.withOpacity(0.3) : const Color(0xFFFAFAFA)),
        border: Border(
          bottom: BorderSide(color: AppTheme.getBorderColor(context), width: 1),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 3,
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
                ),
                const SizedBox(height: 4),
                Text(
                  paiement.matricule ?? 'N/A',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppTheme.getTextSecondary(context),
                  ),
                ),
                if (paiement.centreNom != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    '${paiement.centreNom} - Ch. ${paiement.numeroChambre ?? "N/A"}',
                    style: TextStyle(
                      fontSize: 11,
                      color: AppTheme.getTextTertiary(context),
                    ),
                  ),
                ],
              ],
            ),
          ),

          Expanded(
            flex: 2,
            child: Text(
              '${_formatMontant(paiement.montant)} F',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 15,
                color: paiement.montant > 0
                    ? const Color(0xFF10B981)
                    : const Color(0xFFEF4444),
              ),
            ),
          ),

          Expanded(
            flex: 2,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: _getStatutColor(paiement.statut).withOpacity(isDark ? 0.2 : 0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: _getStatutColor(paiement.statut).withOpacity(isDark ? 0.4 : 0.3),
                  width: 1,
                ),
              ),
              child: Text(
                _getStatutLabel(paiement.statut),
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: _getStatutColor(paiement.statut),
                ),
              ),
            ),
          ),

          Expanded(
            flex: 2,
            child: Text(
              _getModeLabel(paiement.modePaiement),
              style: TextStyle(
                color: AppTheme.getTextSecondary(context),
                fontSize: 13,
              ),
            ),
          ),

          Expanded(
            flex: 2,
            child: Text(
              DateFormat('dd/MM/yy HH:mm').format(paiement.datePaiement as DateTime),
              style: TextStyle(
                color: AppTheme.getTextSecondary(context),
                fontSize: 13,
              ),
            ),
          ),

          SizedBox(
            width: 100,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                IconButton(
                  onPressed: () => _showPaiementDetails(paiement, provider),
                  icon: Icon(Icons.visibility_outlined, size: 20, color: AppTheme.getTextSecondary(context)),
                  tooltip: 'Voir détails',
                ),
                PopupMenuButton<String>(
                  icon: Icon(Icons.more_vert, size: 20, color: AppTheme.getTextSecondary(context)),
                  color: AppTheme.getCardBackground(context),
                  surfaceTintColor: AppTheme.getCardBackground(context),
                  itemBuilder: (context) => _buildActionMenu(paiement),
                  onSelected: (value) =>
                      _handleAction(value, paiement, provider),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Menu contextuel pour un paiement.
  List<PopupMenuEntry<String>> _buildActionMenu(Paiement paiement) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return [
      PopupMenuItem<String>(
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
      if (paiement.statut == 'EN_ATTENTE') ...[
        PopupMenuItem<String>(
          value: 'confirmer',
          child: Row(
            children: [
              Icon(Icons.check_circle, size: 18, color: const Color(0xFF10B981)),
              const SizedBox(width: 8),
              Text(
                'Confirmer le paiement',
                style: TextStyle(color: AppTheme.getTextPrimary(context)),
              ),
            ],
          ),
        ),
        PopupMenuItem<String>(
          value: 'rejeter',
          child: Row(
            children: [
              Icon(Icons.cancel, size: 18, color: const Color(0xFFEF4444)),
              const SizedBox(width: 8),
              Text(
                'Marquer comme échec',
                style: TextStyle(color: AppTheme.getTextPrimary(context)),
              ),
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
            Text(
              'Exporter reçu',
              style: TextStyle(color: AppTheme.getTextPrimary(context)),
            ),
          ],
        ),
      ),
    ];
  }

  /// Barre de pagination.
  Widget _buildPagination(PaiementAdminProvider provider, bool isDark) {
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
            'Total: ${provider.totalItems} paiements',
            style: TextStyle(
              color: AppTheme.getTextSecondary(context),
              fontSize: 13,
            ),
          ),
          Row(
            children: [
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
              Icons.payments_outlined,
              size: 80,
              color: AppTheme.getTextTertiary(context),
            ),
            const SizedBox(height: 24),
            Text(
              'Aucun paiement trouvé',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppTheme.getTextSecondary(context),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Ajustez vos filtres ou attendez de nouveaux paiements',
              style: TextStyle(
                color: AppTheme.getTextTertiary(context),
              ),
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

  /// Affichage en cas d’erreur de chargement.
  Widget _buildErrorWidget(String error, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(24),
      margin: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? Colors.red.shade900.withOpacity(0.1) : const Color(0xFFFEF2F2),
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

  // ==================== UTILITAIRES D’AFFICHAGE ====================

  String _getStatutLabel(String statut) {
    switch (statut) {
      case 'EN_ATTENTE':
        return 'En attente';
      case 'CONFIRME':
        return 'Confirmé';
      case 'ECHEC':
        return 'Échec';
      case 'TOUS':
        return 'Tous';
      default:
        return statut;
    }
  }

  Color _getStatutColor(String statut) {
    switch (statut) {
      case 'EN_ATTENTE':
        return const Color(0xFFF59E0B);
      case 'CONFIRME':
        return const Color(0xFF10B981);
      case 'ECHEC':
        return const Color(0xFFEF4444);
      default:
        return const Color(0xFF64748B);
    }
  }

  String _getModeLabel(String mode) {
    switch (mode) {
      case 'ORANGE_MONEY':
        return 'Orange Money';
      case 'MOOV_MONEY':
        return 'Moov Money';
      case 'ESPECES':
        return 'Espèces';
      case 'VIREMENT':
        return 'Virement';
      case 'TOUS':
        return 'Tous';
      default:
        return mode;
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
      'date_from': _selectedDateFrom != null
          ? DateFormat('yyyy-MM-dd').format(_selectedDateFrom!)
          : null,
      'date_to': _selectedDateTo != null
          ? DateFormat('yyyy-MM-dd').format(_selectedDateTo!)
          : null,
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

  void _showPaiementDetails(Paiement paiement, PaiementAdminProvider provider) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showDialog(
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
                'Détails du paiement',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.getTextPrimary(context),
                ),
              ),
              const SizedBox(height: 16),
              SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildDetailItem('Référence', paiement.referenceTransaction ?? 'N/A'),
                    _buildDetailItem('Étudiant', paiement.etudiantNomComplet),
                    if (paiement.matricule != null)
                      _buildDetailItem('Matricule', paiement.matricule!),
                    _buildDetailItem('Centre', paiement.centreNom ?? 'N/A'),
                    _buildDetailItem('Chambre', paiement.numeroChambre ?? 'N/A'),
                    if (paiement.typeChambre != null)
                      _buildDetailItem('Type chambre', paiement.typeChambre!),
                    _buildDetailItem('Type paiement', paiement.typePaiement ?? 'Loyer'),
                    _buildDetailItem('Montant', '${_formatMontant(paiement.montant)} FCFA'),
                    _buildDetailItem('Statut', _getStatutLabel(paiement.statut)),
                    _buildDetailItem('Mode', _getModeLabel(paiement.modePaiement)),
                    _buildDetailItem('Date paiement',
                        paiement.datePaiement != null
                            ? DateFormat('dd/MM/yyyy HH:mm').format(paiement.datePaiement!)
                            : 'Non définie'),
                    if (paiement.dateEcheance != null)
                      _buildDetailItem('Date échéance',
                          DateFormat('dd/MM/yyyy').format(paiement.dateEcheance!)),
                    if (paiement.prixMensuel != null)
                      _buildDetailItem('Prix mensuel',
                          '${_formatMontant(paiement.prixMensuel!)} FCFA'),
                    if (paiement.centreVille != null)
                      _buildDetailItem('Ville', paiement.centreVille!),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(
                      'Fermer',
                      style: TextStyle(color: AppTheme.getTextSecondary(context)),
                    ),
                  ),
                  if (paiement.statut == 'EN_ATTENTE') ...[
                    const SizedBox(width: 12),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        _confirmPaiement(paiement.id.toString(), provider);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Confirmer'),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
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
            style: TextStyle(
              fontSize: 16,
              color: AppTheme.getTextPrimary(context),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleAction(String action, Paiement paiement,
      PaiementAdminProvider provider) async {
    switch (action) {
      case 'details':
        _showPaiementDetails(paiement, provider);
        break;
      case 'confirmer':
        await _confirmPaiement(paiement.id.toString(), provider);
        break;
      case 'rejeter':
        await _rejectPaiement(paiement.id.toString(), provider);
        break;
      case 'export':
        _exportReceipt(paiement);
        break;
    }
  }

  /// Confirme un paiement après validation.
  Future<void> _confirmPaiement(String paiementId,
      PaiementAdminProvider provider) async {
    final commentaireController = TextEditingController();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    try {
      final commentaire = await showDialog<String>(
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
                  'Confirmer le paiement',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.getTextPrimary(context),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Êtes-vous sûr de vouloir confirmer ce paiement ?',
                  style: TextStyle(color: AppTheme.getTextSecondary(context)),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: commentaireController,
                  decoration: InputDecoration(
                    labelText: 'Commentaire (optionnel)',
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
                      borderSide: BorderSide(color: Theme.of(context).colorScheme.primary, width: 2),
                    ),
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
                        Navigator.pop(context, commentaireController.text);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Confirmer'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );

      if (commentaire == null) return;

      await provider.updateStatutPaiement(
        paiementId: paiementId,
        nouveauStatut: 'CONFIRME',
        raison: commentaire.isNotEmpty ? commentaire : null,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Paiement confirmé avec succès'),
            backgroundColor: const Color(0xFF10B981),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: $e'),
            backgroundColor: const Color(0xFFEF4444),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      commentaireController.dispose();
    }
  }

  /// Marque un paiement comme échec avec une raison.
  Future<void> _rejectPaiement(String paiementId,
      PaiementAdminProvider provider) async {
    final raisonController = TextEditingController();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    try {
      final raison = await showDialog<String>(
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
                  'Marquer comme échec',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.getTextPrimary(context),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Veuillez indiquer la raison de l\'échec :',
                  style: TextStyle(color: AppTheme.getTextSecondary(context)),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: raisonController,
                  decoration: InputDecoration(
                    labelText: 'Raison',
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
                      borderSide: BorderSide(color: Theme.of(context).colorScheme.primary, width: 2),
                    ),
                    hintText: 'Ex: Transaction expirée, montant incorrect...',
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
                        Navigator.pop(context, raisonController.text);
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

      if (raison == null) return;

      await provider.updateStatutPaiement(
        paiementId: paiementId,
        nouveauStatut: 'ECHEC',
        raison: raison.isNotEmpty ? raison : null,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Paiement marqué comme échec'),
            backgroundColor: const Color(0xFFEF4444),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: $e'),
            backgroundColor: const Color(0xFFEF4444),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      raisonController.dispose();
    }
  }

  void _exportReceipt(Paiement paiement) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Export du reçu pour ${paiement.referenceTransaction}'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // ==================== EXPORT ====================

  Future<void> _exportPaiements() async {
    final provider = Provider.of<PaiementAdminProvider>(context, listen: false);

    if (provider.paiements.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Aucun paiement à exporter'),
          backgroundColor: Color(0xFFF59E0B),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final format = await showDialog<String>(
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
                'Exporter les paiements',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.getTextPrimary(context),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Choisissez le format d\'export :',
                style: TextStyle(color: AppTheme.getTextSecondary(context)),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context, 'pdf'),
                    child: const Row(
                      children: [
                        Icon(Icons.picture_as_pdf, color: Colors.red),
                        SizedBox(width: 8),
                        Text('PDF'),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  TextButton(
                    onPressed: () => Navigator.pop(context, 'excel'),
                    child: const Row(
                      children: [
                        Icon(Icons.table_chart, color: Colors.green),
                        SizedBox(width: 8),
                        Text('Excel'),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  TextButton(
                    onPressed: () => Navigator.pop(context, 'word'),
                    child: const Row(
                      children: [
                        Icon(Icons.description, color: Colors.blue),
                        SizedBox(width: 8),
                        Text('Word'),
                      ],
                    ),
                  ),
                ],
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
                ],
              ),
            ],
          ),
        ),
      ),
    );

    if (format != null) {
      try {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Génération $format en cours...'),
            duration: const Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
          ),
        );

        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) =>
                ExportPreviewScreen(
                  format: format,
                  paiements: provider.paiements,
                  filters: provider.filters,
                ),
          ),
        );
      } catch (e) {
        print('Erreur export $format: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Erreur lors de l\'export: $e'),
              backgroundColor: const Color(0xFFEF4444),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    }
  }

  Future<void> _exportPdfBackend(PaiementAdminProvider provider) async {
    if (!kIsWeb) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Export PDF disponible uniquement sur web'),
          backgroundColor: Color(0xFFF59E0B),
        ),
      );
      return;
    }

    try {
      print('Demande génération PDF backend...');

      final filters = <String, dynamic>{
        'format': 'pdf',
        'periode': 'personnalisee',
      };

      if (_selectedDateFrom != null) {
        filters['date_debut'] = DateFormat('yyyy-MM-dd').format(_selectedDateFrom!);
      }
      if (_selectedDateTo != null) {
        filters['date_fin'] = DateFormat('yyyy-MM-dd').format(_selectedDateTo!);
      }

      if (_selectedStatut != 'TOUS') {
        filters['statut'] = _selectedStatut;
      }
      if (_selectedMode != 'TOUS') {
        filters['mode_paiement'] = _selectedMode;
      }

      print('Payload PDF envoyé: $filters');

      final response = await provider.apiService.post(
        '/api/rapports/financier',
        body: filters,
      );

      print('Réponse reçue du backend');

      if (response is http.Response && response.statusCode == 200) {
        final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
        final filename = 'rapport_paiements_$timestamp.pdf';

        HtmlUtils.downloadFile(
          bytes: response.bodyBytes,
          fileName: filename,
          mimeType: 'application/pdf',
        );

        print('PDF téléchargé: $filename');

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('PDF téléchargé avec succès'),
              backgroundColor: Color(0xFF10B981),
              duration: Duration(seconds: 3),
            ),
          );
        }
      } else if (response is Map<String, dynamic> && response['success'] == true) {
        if (response['file_url'] != null) {
          HtmlUtils.openInNewTab(response['file_url']);

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('PDF ouvert dans un nouvel onglet'),
                backgroundColor: Color(0xFF10B981),
                duration: Duration(seconds: 3),
              ),
            );
          }
        }
      }
    } catch (e) {
      print('Erreur export PDF backend: $e');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de l\'export PDF: $e'),
            backgroundColor: const Color(0xFFEF4444),
          ),
        );
      }
    }
  }

  String _generateCsvContent(List<Paiement> paiements) {
    final buffer = StringBuffer();

    buffer.writeln(
        'Référence,Étudiant,Matricule,Centre,Chambre,Montant,Statut,Mode,Date');

    for (final p in paiements) {
      final dateStr = p.datePaiement != null
          ? DateFormat('dd/MM/yyyy HH:mm').format(p.datePaiement!)
          : 'N/A';

      buffer.writeln([
        '"${p.referenceTransaction ?? 'N/A'}"',
        '"${p.etudiantNomComplet}"',
        '"${p.matricule ?? 'N/A'}"',
        '"${p.centreNom ?? 'N/A'}"',
        '"${p.numeroChambre ?? 'N/A'}"',
        '${_formatMontant(p.montant)}',
        '"${_getStatutLabel(p.statut)}"',
        '"${_getModeLabel(p.modePaiement)}"',
        '"$dateStr"',
      ].join(','));
    }

    return buffer.toString();
  }

  Future<void> _exportCsvLocal(PaiementAdminProvider provider) async {
    if (!kIsWeb) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Export CSV disponible uniquement sur web'),
          backgroundColor: Color(0xFFF59E0B),
        ),
      );
      return;
    }

    try {
      if (mounted) {
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ExportPreviewScreen(
              format: 'csv',
              paiements: provider.paiements,
              filters: provider.filters,
            ),
          ),
        );
      }
    } catch (e) {
      print('Erreur export CSV: $e');

      try {
        final csvContent = _generateCsvContent(provider.paiements);
        final bytes = utf8.encode(csvContent);
        final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());

        HtmlUtils.downloadFile(
          bytes: bytes,
          fileName: 'paiements_$timestamp.csv',
          mimeType: 'text/csv',
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('CSV exporté avec succès'),
              backgroundColor: Color(0xFF10B981),
            ),
          );
        }
      } catch (fallbackError) {
        print('Erreur fallback CSV: $fallbackError');

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Erreur lors de l\'export CSV: $fallbackError'),
              backgroundColor: const Color(0xFFEF4444),
            ),
          );
        }
      }
    }
  }
}