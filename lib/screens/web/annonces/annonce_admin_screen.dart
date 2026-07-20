// screens/web/annonces/annonce_admin_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cenou_mobile/providers/web/annonce_admin_provider.dart';
import 'package:cenou_mobile/config/theme.dart';
import 'package:cenou_mobile/widgets/skeleton/skeletons.dart';
import 'package:cenou_mobile/widgets/admin/admin_states.dart';
import 'package:cenou_mobile/widgets/admin/admin_confirm_dialog.dart';
import '../dashboard/dashboard_layout.dart';
import '../../../l10n/app_localizations.dart';
import 'dialogs/send_annonce_dialog.dart';
import 'widgets/annonce_card.dart';
import 'widgets/annonce_stats.dart';

/// Écran d'administration des annonces (coquille : composition + wiring).
class AnnonceAdminScreen extends StatefulWidget {
  const AnnonceAdminScreen({Key? key}) : super(key: key);

  @override
  State<AnnonceAdminScreen> createState() => _AnnonceAdminScreenState();
}

class _AnnonceAdminScreenState extends State<AnnonceAdminScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadData());
  }

  Future<void> _loadData() =>
      Provider.of<AnnonceAdminProvider>(context, listen: false).loadData();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return DashboardLayout(
      selectedIndex: 4,
      child: Column(
        children: [
          _buildActionBar(context, l10n),
          Expanded(
            child: Consumer<AnnonceAdminProvider>(
              builder: (context, provider, _) {
                if (provider.isLoading && provider.annonces.isEmpty) {
                  return const SkeletonAnnonceList();
                }
                if (provider.error != null && provider.annonces.isEmpty) {
                  return AdminErrorState(
                    error: provider.error!,
                    title: l10n.loadingError,
                    retryLabel: l10n.retry,
                    onRetry: _loadData,
                  );
                }
                return Column(
                  children: [
                    AnnonceStats(annonces: provider.annonces, l10n: l10n),
                    Expanded(
                      child: provider.annonces.isEmpty
                          ? AdminEmptyState(
                              icon: Icons.announcement_outlined,
                              title: l10n.noAnnouncementsSent,
                              subtitle: l10n.sendFirstAnnouncement,
                              actions: [
                                ElevatedButton.icon(
                                  onPressed: () => _showSendAnnonceDialog(l10n),
                                  icon: const Icon(Icons.send, color: Colors.white),
                                  label: Text(l10n.createAnnouncement,
                                      style: const TextStyle(color: Colors.white)),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Theme.of(context).colorScheme.primary,
                                  ),
                                ),
                              ],
                            )
                          : RefreshIndicator(
                              onRefresh: _loadData,
                              child: ListView.separated(
                                padding: const EdgeInsets.fromLTRB(32, 0, 32, 24),
                                physics: const AlwaysScrollableScrollPhysics(),
                                itemCount: provider.annonces.length,
                                separatorBuilder: (_, __) => const SizedBox(height: 16),
                                itemBuilder: (context, index) {
                                  final annonce = provider.annonces[index];
                                  return AnnonceCard(
                                    annonce: annonce,
                                    l10n: l10n,
                                    onDelete: () => _deleteAnnonce(annonce.id, provider, l10n),
                                  );
                                },
                              ),
                            ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionBar(BuildContext context, AppLocalizations l10n) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
      decoration: BoxDecoration(
        color: AppTheme.getTopBarBackground(context),
        border: Border(bottom: BorderSide(color: AppTheme.getBorderColor(context), width: 1)),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4, offset: const Offset(0, 2)),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l10n.announcementsAndNotifications,
                    style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.getTextPrimary(context))),
                const SizedBox(height: 4),
                Text(l10n.sendImportantNotificationsToStudents,
                    style: TextStyle(color: AppTheme.getTextSecondary(context))),
              ],
            ),
          ),
          IconButton(
            onPressed: _loadData,
            icon: Icon(Icons.refresh, color: AppTheme.getTextSecondary(context)),
            tooltip: l10n.refresh,
          ),
          const SizedBox(width: 12),
          ElevatedButton.icon(
            onPressed: () => _showSendAnnonceDialog(l10n),
            icon: const Icon(Icons.send, size: 18, color: Colors.white),
            label: Text(l10n.newAnnouncement, style: const TextStyle(color: Colors.white)),
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.primary,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
        ],
      ),
    );
  }

  void _showSendAnnonceDialog(AppLocalizations l10n) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => SendAnnonceDialog(l10n: l10n),
    );
  }

  Future<void> _deleteAnnonce(
      int annonceId, AnnonceAdminProvider provider, AppLocalizations l10n) async {
    final confirm = await showAdminConfirmDialog(
      context,
      title: l10n.deleteAnnouncement,
      message: l10n.confirmDeleteAnnouncement,
      isCritical: true,
      l10n: l10n,
    );
    if (confirm != true) return;
    try {
      await provider.deleteAnnonce(annonceId);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(l10n.announcementDeletedSuccess),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
      ));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('${l10n.error}: $e'),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ));
    }
  }
}
