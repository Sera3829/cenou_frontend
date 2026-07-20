import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cenou_mobile/config/theme.dart';
import 'package:cenou_mobile/l10n/app_localizations.dart';
import 'package:cenou_mobile/models/admin/admin_user.dart';
import 'package:cenou_mobile/providers/auth_provider.dart';
import 'package:cenou_mobile/providers/web/user_admin_provider.dart';
import 'package:cenou_mobile/widgets/admin/admin_confirm_dialog.dart';
import 'package:cenou_mobile/screens/web/utilisateurs/utils/user_display.dart';
import 'package:cenou_mobile/screens/web/utilisateurs/dialogs/user_detail_dialog.dart';
import 'package:cenou_mobile/screens/web/utilisateurs/dialogs/user_form_dialog.dart';
import 'package:cenou_mobile/screens/web/utilisateurs/dialogs/user_annonce_dialog.dart';

/// Tableau responsive des utilisateurs (en-tête + lignes + menu d'actions).
class UserTable extends StatelessWidget {
  final UserAdminProvider provider;
  final AppLocalizations l10n;
  const UserTable({super.key, required this.provider, required this.l10n});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.fromLTRB(24, 0, 24, 24),
      decoration: BoxDecoration(
        color: AppTheme.getCardBackground(context),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(isDark ? 0.1 : 0.05), blurRadius: 10),
        ],
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final w = constraints.maxWidth;
          final showDate = w >= 1000;
          final showMatricule = w >= 760;

          return Column(
            children: [
              // En-tête
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                decoration: BoxDecoration(
                  color: isDark ? Colors.grey.shade900.withOpacity(0.5) : const Color(0xFFF8FAFC),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(12),
                    topRight: Radius.circular(12),
                  ),
                  border: Border(
                      bottom: BorderSide(color: AppTheme.getBorderColor(context), width: 1)),
                ),
                child: Row(
                  children: [
                    Expanded(flex: 26, child: _headerText(context, l10n.user)),
                    if (showMatricule)
                      Expanded(flex: 14, child: _headerText(context, l10n.matricule)),
                    Expanded(flex: 15, child: _headerText(context, l10n.role)),
                    Expanded(flex: 15, child: _headerText(context, l10n.status)),
                    if (showDate)
                      Expanded(flex: 16, child: _headerText(context, l10n.dateCreation)),
                    SizedBox(width: 132, child: _headerText(context, l10n.actions)),
                  ],
                ),
              ),
              // Lignes
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: provider.users.length,
                itemBuilder: (context, index) => _row(
                  context,
                  provider.users[index],
                  index,
                  showMatricule: showMatricule,
                  showDate: showDate,
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _headerText(BuildContext context, String text) {
    return Text(
      text,
      style: TextStyle(
          fontWeight: FontWeight.bold, color: AppTheme.getTextPrimary(context), fontSize: 13),
    );
  }

  Widget _row(BuildContext context, AdminUser user, int index,
      {required bool showMatricule, required bool showDate}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        color: index.isEven
            ? AppTheme.getCardBackground(context)
            : (isDark ? Colors.grey.shade900.withOpacity(0.3) : const Color(0xFFFAFAFA)),
        border: Border(bottom: BorderSide(color: AppTheme.getBorderColor(context), width: 1)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Utilisateur
          Expanded(
            flex: 26,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('${user.prenom} ${user.nom}',
                    style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: AppTheme.getTextPrimary(context),
                        fontSize: 14),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
                const SizedBox(height: 3),
                Text(user.email,
                    style: TextStyle(fontSize: 12, color: AppTheme.getTextSecondary(context)),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
                const SizedBox(height: 2),
                Text(user.telephone,
                    style: TextStyle(fontSize: 11, color: AppTheme.getTextTertiary(context))),
                if (user.centreNom != null) ...[
                  const SizedBox(height: 2),
                  Text(user.centreNom!,
                      style: TextStyle(fontSize: 11, color: AppTheme.getTextTertiary(context)),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                ],
              ],
            ),
          ),
          // Matricule
          if (showMatricule)
            Expanded(
              flex: 14,
              child: Text(user.matricule,
                  style: TextStyle(color: AppTheme.getTextSecondary(context), fontSize: 13),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis),
            ),
          // Rôle
          Expanded(
            flex: 15,
            child: Align(
              alignment: Alignment.centerLeft,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: userRoleColor(user.role).withOpacity(isDark ? 0.2 : 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                      color: userRoleColor(user.role).withOpacity(isDark ? 0.4 : 0.3), width: 1),
                ),
                child: Text(userRoleLabel(user.role, l10n),
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: userRoleColor(user.role))),
              ),
            ),
          ),
          // Statut
          Expanded(
            flex: 15,
            child: Align(
              alignment: Alignment.centerLeft,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: userStatutColor(user.statut).withOpacity(isDark ? 0.2 : 0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                      color: userStatutColor(user.statut).withOpacity(isDark ? 0.5 : 0.4),
                      width: 1.5),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                          color: userStatutColor(user.statut), shape: BoxShape.circle),
                    ),
                    const SizedBox(width: 6),
                    Text(userStatutLabel(user.statut, l10n),
                        style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: userStatutColor(user.statut))),
                  ],
                ),
              ),
            ),
          ),
          // Date création
          if (showDate)
            Expanded(
              flex: 16,
              child: Text(formatUserDate(user.createdAt, l10n),
                  style: TextStyle(color: AppTheme.getTextSecondary(context), fontSize: 13)),
            ),
          // Actions
          SizedBox(
            width: 132,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                IconButton(
                  onPressed: () => showUserDetailsDialog(context, user, l10n,
                      onEdit: () => showEditUserDialog(context, user, provider, l10n)),
                  icon: Icon(Icons.visibility_outlined,
                      size: 20, color: AppTheme.getTextSecondary(context)),
                  tooltip: l10n.viewDetails,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
                const SizedBox(width: 12),
                IconButton(
                  onPressed: () => showEditUserDialog(context, user, provider, l10n),
                  icon: const Icon(Icons.edit_outlined, size: 20, color: Color(0xFF3B82F6)),
                  tooltip: l10n.edit,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
                const SizedBox(width: 12),
                PopupMenuButton<String>(
                  icon: Icon(Icons.more_vert, size: 20, color: AppTheme.getTextSecondary(context)),
                  color: AppTheme.getCardBackground(context),
                  surfaceTintColor: AppTheme.getCardBackground(context),
                  itemBuilder: (context) => _actionMenu(context, user),
                  onSelected: (value) => _handleAction(context, value, user),
                  padding: EdgeInsets.zero,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<PopupMenuEntry<String>> _actionMenu(BuildContext context, AdminUser user) {
    final isAdmin = Provider.of<AuthProvider>(context, listen: false).isAdmin;
    return [
      PopupMenuItem(
        value: 'details',
        child: Row(children: [
          Icon(Icons.info_outline, size: 18, color: AppTheme.getTextSecondary(context)),
          const SizedBox(width: 8),
          Text(l10n.fullDetails, style: TextStyle(color: AppTheme.getTextPrimary(context))),
        ]),
      ),
      if (user.role == 'ETUDIANT')
        PopupMenuItem(
          value: 'send_annonce',
          child: Row(children: [
            const Icon(Icons.send, size: 18, color: Color(0xFF3B82F6)),
            const SizedBox(width: 8),
            Text(l10n.sendAnnouncement, style: TextStyle(color: AppTheme.getTextPrimary(context))),
          ]),
        ),
      PopupMenuItem(
        value: 'edit',
        child: Row(children: [
          const Icon(Icons.edit, size: 18, color: Color(0xFF3B82F6)),
          const SizedBox(width: 8),
          Text(l10n.edit, style: TextStyle(color: AppTheme.getTextPrimary(context))),
        ]),
      ),
      if (user.isActive) ...[
        PopupMenuItem(
          value: 'desactiver',
          child: Row(children: [
            const Icon(Icons.pause_circle, size: 18, color: Color(0xFFF59E0B)),
            const SizedBox(width: 8),
            Text(l10n.deactivate, style: TextStyle(color: AppTheme.getTextPrimary(context))),
          ]),
        ),
        if (isAdmin || user.role != 'ADMIN')
          PopupMenuItem(
            value: 'suspendre',
            child: Row(children: [
              const Icon(Icons.block, size: 18, color: Color(0xFFEF4444)),
              const SizedBox(width: 8),
              Text(l10n.suspend, style: TextStyle(color: AppTheme.getTextPrimary(context))),
            ]),
          ),
      ] else if (user.statut == 'INACTIF' || user.statut == 'SUSPENDU') ...[
        PopupMenuItem(
          value: 'reactiver',
          child: Row(children: [
            const Icon(Icons.play_arrow, size: 18, color: Color(0xFF10B981)),
            const SizedBox(width: 8),
            Text(l10n.reactivate, style: TextStyle(color: AppTheme.getTextPrimary(context))),
          ]),
        ),
      ],
      if (isAdmin) ...[
        const PopupMenuDivider(),
        PopupMenuItem(
          value: 'supprimer',
          child: Row(children: [
            const Icon(Icons.delete, size: 18, color: Color(0xFFEF4444)),
            const SizedBox(width: 8),
            Text(l10n.delete, style: TextStyle(color: Colors.red.shade700)),
          ]),
        ),
      ],
    ];
  }

  Future<void> _handleAction(BuildContext context, String action, AdminUser user) async {
    switch (action) {
      case 'details':
        showUserDetailsDialog(context, user, l10n,
                      onEdit: () => showEditUserDialog(context, user, provider, l10n));
        break;
      case 'edit':
        showEditUserDialog(context, user, provider, l10n);
        break;
      case 'send_annonce':
        showSendAnnonceToUserDialog(context, user, l10n);
        break;
      case 'desactiver':
        await _updateStatus(context, user, 'INACTIF');
        break;
      case 'suspendre':
        await _updateStatus(context, user, 'SUSPENDU');
        break;
      case 'reactiver':
        await _updateStatus(context, user, 'ACTIF');
        break;
      case 'supprimer':
        await _deleteUser(context, user);
        break;
    }
  }

  Future<void> _updateStatus(BuildContext context, AdminUser user, String nouveauStatut) async {
    try {
      final confirm = await showAdminConfirmDialog(
        context,
        title: l10n.confirmModification,
        message: l10n.confirmStatusChange(userStatutLabel(nouveauStatut, l10n)),
        l10n: l10n,
      );
      if (confirm == true) {
        await provider.updateUserStatus(user.id, nouveauStatut);
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(l10n.userStatusUpdated(userStatutLabel(nouveauStatut, l10n))),
          backgroundColor: userStatutColor(nouveauStatut),
          behavior: SnackBarBehavior.floating,
        ));
      }
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('${l10n.error}: $e'),
        backgroundColor: const Color(0xFFEF4444),
        behavior: SnackBarBehavior.floating,
      ));
    }
  }

  Future<void> _deleteUser(BuildContext context, AdminUser user) async {
    try {
      final confirm = await showAdminConfirmDialog(
        context,
        title: l10n.confirmDeletion,
        message: l10n.confirmDeleteUser,
        isCritical: true,
        l10n: l10n,
      );
      if (confirm == true) {
        await provider.deleteUser(user.id);
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(l10n.userDeleted),
          backgroundColor: const Color(0xFF10B981),
          behavior: SnackBarBehavior.floating,
        ));
      }
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('${l10n.error}: $e'),
        backgroundColor: const Color(0xFFEF4444),
        behavior: SnackBarBehavior.floating,
      ));
    }
  }
}
