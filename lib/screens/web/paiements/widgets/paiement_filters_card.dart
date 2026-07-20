import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cenou_mobile/config/theme.dart';
import 'package:cenou_mobile/l10n/app_localizations.dart';

/// Carte de filtres avancés paiements : plage de dates + bouton Appliquer.
class PaiementFiltersCard extends StatelessWidget {
  final DateTime? selectedDateFrom;
  final DateTime? selectedDateTo;
  final AppLocalizations l10n;
  final ValueChanged<DateTime> onDateFrom;
  final ValueChanged<DateTime> onDateTo;
  final VoidCallback onApply;
  final VoidCallback onClose;

  const PaiementFiltersCard({
    super.key,
    required this.selectedDateFrom,
    required this.selectedDateTo,
    required this.l10n,
    required this.onDateFrom,
    required this.onDateTo,
    required this.onApply,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.fromLTRB(24, 0, 24, 24),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.getCardBackground(context),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(isDark ? 0.1 : 0.05), blurRadius: 10),
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
            onPressed: onClose,
            icon: Icon(Icons.close, size: 16, color: AppTheme.getTextSecondary(context)),
            label:
                Text(l10n.close, style: TextStyle(color: AppTheme.getTextSecondary(context))),
          ),
        ]),
        const SizedBox(height: 16),
        Row(children: [
          Expanded(child: _datePicker(context, isDark, l10n.startDate, selectedDateFrom, onDateFrom)),
          const SizedBox(width: 16),
          Expanded(child: _datePicker(context, isDark, l10n.endDate, selectedDateTo, onDateTo)),
          const SizedBox(width: 16),
          ElevatedButton.icon(
            onPressed: onApply,
            icon: const Icon(Icons.check, size: 18, color: Colors.white),
            label: Text(l10n.apply, style: const TextStyle(color: Colors.white)),
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.primary,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
        ]),
      ]),
    );
  }

  Widget _datePicker(BuildContext context, bool isDark, String label, DateTime? value,
      ValueChanged<DateTime> onPicked) {
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
          labelStyle: TextStyle(color: AppTheme.getTextSecondary(context)),
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: AppTheme.getBorderColor(context))),
          enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: AppTheme.getBorderColor(context))),
          filled: true,
          fillColor: isDark ? Colors.grey.shade900.withOpacity(0.3) : Colors.grey.shade50,
          suffixIcon:
              Icon(Icons.calendar_today, size: 18, color: AppTheme.getTextSecondary(context)),
        ),
        child: Text(
          value != null ? DateFormat('dd/MM/yyyy', l10n.locale.languageCode).format(value) : l10n.select,
          style: TextStyle(
              color: value != null
                  ? AppTheme.getTextPrimary(context)
                  : AppTheme.getTextSecondary(context)),
        ),
      ),
    );
  }
}
