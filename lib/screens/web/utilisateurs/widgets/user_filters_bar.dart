import 'package:flutter/material.dart';
import 'package:cenou_mobile/config/theme.dart';
import 'package:cenou_mobile/l10n/app_localizations.dart';
import 'package:cenou_mobile/screens/web/utilisateurs/utils/user_display.dart';

/// Barre de recherche + filtres (rôle, statut) + actions (nouveau, rafraîchir).
/// Sans état propre : l'écran conserve la sélection et fournit les callbacks.
class UserFiltersBar extends StatelessWidget {
  final TextEditingController searchController;
  final String selectedRole;
  final String selectedStatut;
  final bool showFilters;
  final AppLocalizations l10n;
  final ValueChanged<String> onSearch;
  final ValueChanged<String> onRoleChanged;
  final ValueChanged<String> onStatutChanged;
  final VoidCallback onToggleFilters;
  final VoidCallback onReset;
  final VoidCallback onRefresh;
  final VoidCallback onNewUser;

  const UserFiltersBar({
    super.key,
    required this.searchController,
    required this.selectedRole,
    required this.selectedStatut,
    required this.showFilters,
    required this.l10n,
    required this.onSearch,
    required this.onRoleChanged,
    required this.onStatutChanged,
    required this.onToggleFilters,
    required this.onReset,
    required this.onRefresh,
    required this.onNewUser,
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
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4, offset: const Offset(0, 2)),
        ],
      ),
      child: isWide
          ? Row(
              children: [
                Expanded(flex: 3, child: _searchField(context, isDark)),
                const SizedBox(width: 12),
                SizedBox(width: 160, child: _roleDropdown(context, isDark)),
                const SizedBox(width: 12),
                SizedBox(width: 160, child: _statutDropdown(context, isDark)),
                const SizedBox(width: 12),
                _actionButtons(context),
              ],
            )
          : Column(
              children: [
                _searchField(context, isDark),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(child: _roleDropdown(context, isDark)),
                    const SizedBox(width: 8),
                    Expanded(child: _statutDropdown(context, isDark)),
                    const SizedBox(width: 8),
                    _actionButtons(context),
                  ],
                ),
              ],
            ),
    );
  }

  Widget _searchField(BuildContext context, bool isDark) {
    return TextField(
      controller: searchController,
      decoration: InputDecoration(
        hintText: l10n.searchUserHint,
        hintStyle: TextStyle(color: AppTheme.getTextSecondary(context)),
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
      onSubmitted: onSearch,
      style: TextStyle(color: AppTheme.getTextPrimary(context)),
    );
  }

  Widget _roleDropdown(BuildContext context, bool isDark) {
    return DropdownButtonFormField<String>(
      value: selectedRole,
      decoration: _dropdownDecoration(context, l10n.role, isDark),
      dropdownColor: AppTheme.getCardBackground(context),
      items: ['TOUS', 'ETUDIANT', 'GESTIONNAIRE', 'ADMIN'].map((item) {
        return DropdownMenuItem(
          value: item,
          child: Text(userRoleLabel(item, l10n),
              style: TextStyle(fontSize: 14, color: AppTheme.getTextPrimary(context))),
        );
      }).toList(),
      onChanged: (value) => onRoleChanged(value!),
      style: TextStyle(color: AppTheme.getTextPrimary(context)),
    );
  }

  Widget _statutDropdown(BuildContext context, bool isDark) {
    return DropdownButtonFormField<String>(
      value: selectedStatut,
      decoration: _dropdownDecoration(context, l10n.status, isDark),
      dropdownColor: AppTheme.getCardBackground(context),
      items: ['TOUS', 'ACTIF', 'INACTIF', 'SUSPENDU'].map((item) {
        return DropdownMenuItem(
          value: item,
          child: Text(userStatutLabel(item, l10n),
              style: TextStyle(fontSize: 14, color: AppTheme.getTextPrimary(context))),
        );
      }).toList(),
      onChanged: (value) => onStatutChanged(value!),
      style: TextStyle(color: AppTheme.getTextPrimary(context)),
    );
  }

  InputDecoration _dropdownDecoration(BuildContext context, String label, bool isDark) {
    return InputDecoration(
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
    );
  }

  Widget _actionButtons(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
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
        ElevatedButton.icon(
          onPressed: onNewUser,
          icon: const Icon(Icons.add, size: 18, color: Colors.white),
          label: Text(l10n.newUser, style: const TextStyle(color: Colors.white)),
          style: ElevatedButton.styleFrom(
            backgroundColor: Theme.of(context).colorScheme.primary,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        ),
        const SizedBox(width: 8),
        ElevatedButton(
          onPressed: onRefresh,
          style: ElevatedButton.styleFrom(
            backgroundColor: Theme.of(context).colorScheme.primary,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
          child: Text(l10n.refresh, style: const TextStyle(color: Colors.white)),
        ),
      ],
    );
  }
}
