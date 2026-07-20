import 'package:flutter/material.dart';
import 'package:cenou_mobile/config/theme.dart';
import 'package:cenou_mobile/l10n/app_localizations.dart';
import 'package:cenou_mobile/screens/web/paiements/utils/paiement_display.dart';

/// Barre de recherche + filtres (statut, mode) + actions (export, rafraîchir).
class PaiementFiltersBar extends StatelessWidget {
  final TextEditingController searchController;
  final String selectedStatut;
  final String selectedMode;
  final bool showFilters;
  final AppLocalizations l10n;
  final ValueChanged<String> onSearch;
  final ValueChanged<String> onStatutChanged;
  final ValueChanged<String> onModeChanged;
  final VoidCallback onToggleFilters;
  final VoidCallback onReset;
  final VoidCallback onExport;
  final VoidCallback onRefresh;

  const PaiementFiltersBar({
    super.key,
    required this.searchController,
    required this.selectedStatut,
    required this.selectedMode,
    required this.showFilters,
    required this.l10n,
    required this.onSearch,
    required this.onStatutChanged,
    required this.onModeChanged,
    required this.onToggleFilters,
    required this.onReset,
    required this.onExport,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isWide = MediaQuery.of(context).size.width > 1100;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      decoration: BoxDecoration(
        color: AppTheme.getTopBarBackground(context),
        border: Border(bottom: BorderSide(color: AppTheme.getBorderColor(context))),
      ),
      child: isWide
          ? Row(children: [
              Expanded(flex: 3, child: _searchField(context, isDark)),
              const SizedBox(width: 12),
              SizedBox(width: 160, child: _statutDropdown(context, isDark)),
              const SizedBox(width: 12),
              SizedBox(width: 160, child: _modeDropdown(context, isDark)),
              const SizedBox(width: 12),
              _buttons(context),
            ])
          : Column(children: [
              _searchField(context, isDark),
              const SizedBox(height: 8),
              Row(children: [
                Expanded(child: _statutDropdown(context, isDark)),
                const SizedBox(width: 8),
                Expanded(child: _modeDropdown(context, isDark)),
                const SizedBox(width: 8),
                _buttons(context),
              ]),
            ]),
    );
  }

  Widget _searchField(BuildContext context, bool isDark) {
    return TextField(
      controller: searchController,
      decoration: InputDecoration(
        hintText: l10n.searchStudentReference,
        prefixIcon: Icon(Icons.search, size: 20, color: AppTheme.getTextSecondary(context)),
        suffixIcon: searchController.text.isNotEmpty
            ? IconButton(
                icon: Icon(Icons.clear, size: 20, color: AppTheme.getTextSecondary(context)),
                onPressed: () {
                  searchController.clear();
                  onSearch('');
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
            borderSide: BorderSide(color: Theme.of(context).colorScheme.primary, width: 2)),
        filled: true,
        fillColor: isDark ? Colors.grey.shade900.withOpacity(0.3) : Colors.grey.shade50,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        isDense: true,
        hintStyle: TextStyle(color: AppTheme.getTextSecondary(context)),
      ),
      onSubmitted: onSearch,
      style: TextStyle(color: AppTheme.getTextPrimary(context)),
    );
  }

  Widget _statutDropdown(BuildContext context, bool isDark) {
    return DropdownButtonFormField<String>(
      value: selectedStatut,
      decoration: _decoration(context, l10n.status, isDark),
      dropdownColor: AppTheme.getCardBackground(context),
      items: ['TOUS', 'EN_ATTENTE', 'CONFIRME', 'ECHEC']
          .map((v) => DropdownMenuItem<String>(
                value: v,
                child: Text(paiementStatutLabel(v, l10n),
                    style: TextStyle(fontSize: 14, color: AppTheme.getTextPrimary(context))),
              ))
          .toList(),
      onChanged: (value) => onStatutChanged(value!),
      style: TextStyle(color: AppTheme.getTextPrimary(context)),
    );
  }

  Widget _modeDropdown(BuildContext context, bool isDark) {
    return DropdownButtonFormField<String>(
      value: selectedMode,
      decoration: _decoration(context, l10n.mode, isDark),
      dropdownColor: AppTheme.getCardBackground(context),
      items: ['TOUS', 'ORANGE_MONEY', 'MOOV_MONEY', 'ESPECES', 'VIREMENT']
          .map((v) => DropdownMenuItem<String>(
                value: v,
                child: Text(paiementModeLabel(v, l10n),
                    style: TextStyle(fontSize: 14, color: AppTheme.getTextPrimary(context))),
              ))
          .toList(),
      onChanged: (value) => onModeChanged(value!),
      style: TextStyle(color: AppTheme.getTextPrimary(context)),
    );
  }

  InputDecoration _decoration(BuildContext context, String label, bool isDark) {
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(color: AppTheme.getTextSecondary(context)),
      border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: AppTheme.getBorderColor(context))),
      enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: AppTheme.getBorderColor(context))),
      filled: true,
      fillColor: isDark ? Colors.grey.shade900.withOpacity(0.3) : Colors.grey.shade50,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      isDense: true,
    );
  }

  Widget _buttons(BuildContext context) {
    return Row(mainAxisSize: MainAxisSize.min, children: [
      IconButton(
        onPressed: onToggleFilters,
        icon: Icon(showFilters ? Icons.filter_list_off : Icons.filter_list,
            color: Theme.of(context).colorScheme.primary),
        tooltip: showFilters ? l10n.hideFilters : l10n.moreFilters,
      ),
      IconButton(
        onPressed: onReset,
        icon: Icon(Icons.refresh, color: AppTheme.getTextSecondary(context)),
        tooltip: l10n.reset,
      ),
      IconButton(
        onPressed: onExport,
        icon: Icon(Icons.download, color: Theme.of(context).colorScheme.primary),
        tooltip: l10n.export,
      ),
      ElevatedButton(
        onPressed: onRefresh,
        style: ElevatedButton.styleFrom(
          backgroundColor: Theme.of(context).colorScheme.primary,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        child: Text(l10n.refresh, style: const TextStyle(color: Colors.white)),
      ),
    ]);
  }
}
