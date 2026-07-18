import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../config/theme.dart';
import '../../../l10n/app_localizations.dart';
import '../../../models/admin/message_interne.dart';
import '../../../providers/web/messagerie_provider.dart';
import 'compose_message_dialog.dart';

/// Panneau latéral (endDrawer) de la messagerie interne du staff.
class MessageriePanel extends StatefulWidget {
  const MessageriePanel({Key? key}) : super(key: key);

  @override
  State<MessageriePanel> createState() => _MessageriePanelState();
}

class _MessageriePanelState extends State<MessageriePanel> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<MessagerieProvider>().loadInbox();
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Drawer(
      width: 420,
      backgroundColor: AppTheme.getCardBackground(context),
      child: SafeArea(
        child: Column(children: [
          _header(context, l10n),
          _actions(context, l10n),
          Divider(height: 1, color: AppTheme.getBorderColor(context)),
          Expanded(child: _list(context, l10n)),
        ]),
      ),
    );
  }

  Widget _header(BuildContext context, AppLocalizations l10n) {
    return Consumer<MessagerieProvider>(builder: (context, p, _) {
      return Container(
        padding: const EdgeInsets.fromLTRB(20, 16, 12, 16),
        child: Row(children: [
          Container(
            padding: const EdgeInsets.all(9),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10)),
            child: const Icon(Icons.forum_rounded, color: AppTheme.primaryColor, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Text(l10n.messagerie, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold,
                  color: AppTheme.getTextPrimary(context))),
              if (p.unreadCount > 0) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppTheme.errorColor, borderRadius: BorderRadius.circular(20)),
                  child: Text('${p.unreadCount}',
                      style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                ),
              ],
            ]),
            Text(l10n.messagerieSubtitle,
                style: TextStyle(fontSize: 12, color: AppTheme.getTextSecondary(context))),
          ])),
          IconButton(
            onPressed: () => context.read<MessagerieProvider>().loadInbox(),
            icon: Icon(Icons.refresh_rounded, color: AppTheme.getTextSecondary(context)),
            tooltip: l10n.refresh,
          ),
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: Icon(Icons.close_rounded, color: AppTheme.getTextSecondary(context)),
            tooltip: l10n.close,
          ),
        ]),
      );
    });
  }

  Widget _actions(BuildContext context, AppLocalizations l10n) {
    return Consumer<MessagerieProvider>(builder: (context, p, _) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        child: Row(children: [
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () => _compose(context, l10n),
              icon: const Icon(Icons.add_rounded, size: 18),
              label: Text(l10n.newMessage),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor, foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 13),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
          if (p.unreadCount > 0) ...[
            const SizedBox(width: 8),
            IconButton(
              onPressed: () => p.marquerToutLu(),
              icon: const Icon(Icons.done_all_rounded),
              color: AppTheme.primaryColor,
              tooltip: l10n.markAllRead,
              style: IconButton.styleFrom(
                side: BorderSide(color: AppTheme.getBorderColor(context)),
              ),
            ),
          ],
        ]),
      );
    });
  }

  Widget _list(BuildContext context, AppLocalizations l10n) {
    return Consumer<MessagerieProvider>(builder: (context, p, _) {
      if (p.isLoading && p.messages.isEmpty) {
        return const Center(child: CircularProgressIndicator());
      }
      if (p.messages.isEmpty) {
        return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(Icons.mark_email_read_outlined, size: 60, color: AppTheme.getTextTertiary(context)),
          const SizedBox(height: 14),
          Text(l10n.noMessagesYet, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600,
              color: AppTheme.getTextSecondary(context))),
          const SizedBox(height: 6),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(l10n.noMessagesHint, textAlign: TextAlign.center,
                style: TextStyle(color: AppTheme.getTextTertiary(context))),
          ),
        ]));
      }
      return ListView.separated(
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: p.messages.length,
        separatorBuilder: (_, __) => Divider(height: 1, indent: 16, endIndent: 16,
            color: AppTheme.getBorderColor(context)),
        itemBuilder: (context, i) => _tile(context, p, p.messages[i], l10n),
      );
    });
  }

  Widget _tile(BuildContext context, MessagerieProvider p, MessageInterne m, AppLocalizations l10n) {
    return InkWell(
      onTap: () {
        if (!m.lu) p.marquerLu(m.id);
        _openMessage(context, m, l10n);
      },
      child: Container(
        color: m.lu ? Colors.transparent : AppTheme.primaryColor.withOpacity(0.04),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(
            padding: const EdgeInsets.all(9),
            decoration: BoxDecoration(
              color: m.porteeColor.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
            child: Icon(m.porteeIcon, color: m.porteeColor, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Expanded(child: Text(m.titre, maxLines: 1, overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 14,
                      fontWeight: m.lu ? FontWeight.w500 : FontWeight.bold,
                      color: AppTheme.getTextPrimary(context)))),
              if (!m.lu) Container(width: 8, height: 8, margin: const EdgeInsets.only(left: 6),
                  decoration: const BoxDecoration(color: AppTheme.primaryColor, shape: BoxShape.circle)),
            ]),
            const SizedBox(height: 3),
            Text(m.contenu, maxLines: 2, overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 13, color: AppTheme.getTextSecondary(context), height: 1.35)),
            const SizedBox(height: 8),
            Row(children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: m.porteeColor.withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
                child: Text(m.porteeLabel, style: TextStyle(fontSize: 11,
                    fontWeight: FontWeight.w600, color: m.porteeColor)),
              ),
              const Spacer(),
              Text(_when(m.createdAt, l10n),
                  style: TextStyle(fontSize: 11, color: AppTheme.getTextTertiary(context))),
            ]),
          ])),
        ]),
      ),
    );
  }

  void _openMessage(BuildContext context, MessageInterne m, AppLocalizations l10n) {
    showDialog(context: context, builder: (_) => Dialog(
      backgroundColor: AppTheme.getCardBackground(context),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                Container(
                  padding: const EdgeInsets.all(9),
                  decoration: BoxDecoration(
                    color: m.porteeColor.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
                  child: Icon(m.porteeIcon, color: m.porteeColor, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(child: Text(m.porteeLabel, style: TextStyle(fontSize: 13,
                    fontWeight: FontWeight.w600, color: m.porteeColor))),
                Text(DateFormat('dd/MM/yyyy HH:mm', l10n.locale.languageCode).format(m.createdAt),
                    style: TextStyle(fontSize: 12, color: AppTheme.getTextTertiary(context))),
              ]),
              const SizedBox(height: 16),
              Text(m.titre, style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold,
                  color: AppTheme.getTextPrimary(context))),
              if (m.expediteur != null) ...[
                const SizedBox(height: 6),
                Text('${l10n.msgFrom} ${m.expediteur}',
                    style: TextStyle(fontSize: 13, color: AppTheme.getTextSecondary(context))),
              ],
              const SizedBox(height: 16),
              Text(m.contenu, style: TextStyle(fontSize: 15, height: 1.5,
                  color: AppTheme.getTextPrimary(context))),
              const SizedBox(height: 24),
              Align(alignment: Alignment.centerRight, child: TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(l10n.close),
              )),
            ]),
        ),
      ),
    ));
  }

  Future<void> _compose(BuildContext context, AppLocalizations l10n) async {
    final sent = await showDialog<bool>(
      context: context, builder: (_) => ComposeMessageDialog(l10n: l10n));
    if (sent == true && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(l10n.msgSent), backgroundColor: AppTheme.successColor,
        behavior: SnackBarBehavior.floating));
    }
  }

  String _when(DateTime dt, AppLocalizations l10n) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 1) return 'maintenant';
    if (diff.inMinutes < 60) return 'il y a ${diff.inMinutes} min';
    if (diff.inHours < 24 && now.day == dt.day) {
      return DateFormat('HH:mm', l10n.locale.languageCode).format(dt);
    }
    if (diff.inDays < 7) return DateFormat('EEE HH:mm', l10n.locale.languageCode).format(dt);
    return DateFormat('dd/MM/yyyy', l10n.locale.languageCode).format(dt);
  }
}
