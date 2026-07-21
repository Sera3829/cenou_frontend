import 'package:flutter/material.dart';
import '../../../l10n/app_localizations.dart';

// ──────────────────────────────────────────────────────────────
// Barre de navigation du bas
// ──────────────────────────────────────────────────────────────

class BottomNav extends StatelessWidget {
  final int currentIndex;
  final int unreadCount;
  final bool isDark;
  final ValueChanged<int> onTap;

  const BottomNav({
    super.key,
    required this.currentIndex,
    required this.unreadCount,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Container(
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.2 : 0.1),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
        child: BottomNavigationBar(
          currentIndex: currentIndex,
          onTap: onTap,
          type: BottomNavigationBarType.fixed,
          selectedItemColor: Theme.of(context).colorScheme.primary,
          unselectedItemColor:
          isDark ? Colors.grey.shade400 : Colors.grey[600],
          backgroundColor:
          isDark ? const Color(0xFF1E1E1E) : Colors.white,
          selectedLabelStyle: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 11,
          ),
          unselectedLabelStyle: const TextStyle(fontSize: 11),
          items: [
            BottomNavigationBarItem(
              icon: const Icon(Icons.home_outlined, size: 24),
              activeIcon: const Icon(Icons.home_rounded, size: 26),
              label: l10n.navHome,
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.payment_outlined, size: 24),
              activeIcon: const Icon(Icons.payment_rounded, size: 26),
              label: l10n.navPayments,
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.report_problem_outlined, size: 24),
              activeIcon: const Icon(Icons.report_problem_rounded, size: 26),
              label: l10n.navReports,
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.person_outline_rounded, size: 24),
              activeIcon: const Icon(Icons.person_rounded, size: 26),
              label: l10n.navProfile,
            ),
          ],
        ),
      ),
    );
  }
}
