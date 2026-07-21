import 'package:flutter/material.dart';
import '../../../l10n/app_localizations.dart';

/// Liste des types de problèmes signalables, avec leur description.
void showProblemTypesDialog(BuildContext context, AppLocalizations l10n) {
  final isDark = Theme.of(context).brightness == Brightness.dark;
  final problems = [
    {'type': l10n.plumbing, 'desc': l10n.plumbingDesc},
    {'type': l10n.electricity, 'desc': l10n.electricityDesc},
    {'type': l10n.roofing, 'desc': l10n.roofingDesc},
    {'type': l10n.locks, 'desc': l10n.locksDesc},
    {'type': l10n.furniture, 'desc': l10n.furnitureDesc},
    {'type': l10n.other, 'desc': l10n.otherDesc},
  ];

  showDialog(
    context: context,
    builder: (context) => Dialog(
      backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Icon(Icons.info_rounded,
                  color: Theme.of(context).colorScheme.primary, size: 24),
              const SizedBox(width: 12),
              Text(l10n.problemTypesTitle,
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white : Colors.black87)),
            ]),
            const SizedBox(height: 16),
            Text(l10n.availableCategories,
                style: TextStyle(
                    fontSize: 13,
                    color: isDark ? Colors.grey.shade400 : Colors.grey,
                    fontWeight: FontWeight.w500)),
            const SizedBox(height: 14),
            ...problems.map((p) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                            margin: const EdgeInsets.only(top: 5),
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.primary,
                                shape: BoxShape.circle)),
                        const SizedBox(width: 12),
                        Expanded(
                            child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                              Text(p['type']!,
                                  style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: isDark
                                          ? Colors.white
                                          : Colors.black87)),
                              const SizedBox(height: 2),
                              Text(p['desc']!,
                                  style: TextStyle(
                                      fontSize: 12,
                                      color: isDark
                                          ? Colors.grey.shade400
                                          : Colors.grey[600])),
                            ])),
                      ]),
                )),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: Text(l10n.understood),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
