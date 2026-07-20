import 'package:flutter/material.dart';
import 'package:cenou_mobile/config/theme.dart';
import 'package:cenou_mobile/l10n/app_localizations.dart';
import 'package:cenou_mobile/models/admin/admin_user.dart';
import 'package:cenou_mobile/services/api_service.dart';

/// Dialogue d'envoi d'une annonce ciblée à un étudiant précis.
Future<void> showSendAnnonceToUserDialog(
    BuildContext context, AdminUser user, AppLocalizations l10n) async {
  final titreController = TextEditingController();
  final contenuController = TextEditingController();
  bool isSending = false;
  final isDark = Theme.of(context).brightness == Brightness.dark;

  await showDialog(
    context: context,
    builder: (context) => StatefulBuilder(
      builder: (context, setState) => Dialog(
        backgroundColor: AppTheme.getCardBackground(context),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: 550,
            maxHeight: MediaQuery.of(context).size.height * 0.8,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: isDark ? Colors.grey.shade900.withOpacity(0.5) : const Color(0xFFF8FAFC),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFF3B82F6).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.send, color: Color(0xFF3B82F6), size: 24),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(l10n.sendAnnouncement,
                              style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.getTextPrimary(context))),
                          const SizedBox(height: 4),
                          Text('${l10n.sendAnnouncementTo}: ${user.prenom} ${user.nom}',
                              style: TextStyle(
                                  fontSize: 14, color: AppTheme.getTextSecondary(context))),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: isSending ? null : () => Navigator.pop(context),
                      icon: Icon(Icons.close, color: AppTheme.getTextSecondary(context)),
                    ),
                  ],
                ),
              ),
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      TextField(
                        controller: titreController,
                        decoration: InputDecoration(
                          labelText: l10n.title,
                          labelStyle: TextStyle(color: AppTheme.getTextSecondary(context)),
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(color: AppTheme.getBorderColor(context))),
                          enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(color: AppTheme.getBorderColor(context))),
                          focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(
                                  color: Theme.of(context).colorScheme.primary, width: 2)),
                          filled: true,
                          fillColor:
                              isDark ? Colors.grey.shade900.withOpacity(0.3) : Colors.grey.shade50,
                        ),
                        maxLength: 100,
                        style: TextStyle(color: AppTheme.getTextPrimary(context)),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: contenuController,
                        decoration: InputDecoration(
                          labelText: l10n.message,
                          labelStyle: TextStyle(color: AppTheme.getTextSecondary(context)),
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(color: AppTheme.getBorderColor(context))),
                          enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(color: AppTheme.getBorderColor(context))),
                          focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(
                                  color: Theme.of(context).colorScheme.primary, width: 2)),
                          alignLabelWithHint: true,
                          filled: true,
                          fillColor:
                              isDark ? Colors.grey.shade900.withOpacity(0.3) : Colors.grey.shade50,
                        ),
                        maxLines: 6,
                        maxLength: 500,
                        style: TextStyle(color: AppTheme.getTextPrimary(context)),
                      ),
                    ],
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: isDark ? Colors.grey.shade900.withOpacity(0.5) : const Color(0xFFF8FAFC),
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(16),
                    bottomRight: Radius.circular(16),
                  ),
                  border: Border(top: BorderSide(color: AppTheme.getBorderColor(context))),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: isSending ? null : () => Navigator.pop(context),
                      child: Text(l10n.cancel,
                          style: TextStyle(color: AppTheme.getTextSecondary(context))),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton.icon(
                      onPressed: isSending
                          ? null
                          : () async {
                              if (titreController.text.trim().isEmpty ||
                                  contenuController.text.trim().isEmpty) {
                                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                                  content: Text(l10n.fillAllFields),
                                  backgroundColor: Colors.orange,
                                  behavior: SnackBarBehavior.floating,
                                ));
                                return;
                              }
                              setState(() => isSending = true);
                              try {
                                final apiService = ApiService();
                                await apiService.post('/api/annonces/send', body: {
                                  'titre': titreController.text.trim(),
                                  'contenu': contenuController.text.trim(),
                                  'cible': 'ETUDIANTS',
                                  'user_ids': [user.id],
                                  'statut': 'PUBLIE',
                                });
                                Navigator.pop(context);
                                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                                  content: Text(
                                      '${l10n.announcementSentToUser} ${user.prenom} ${user.nom}'),
                                  backgroundColor: const Color(0xFF10B981),
                                  behavior: SnackBarBehavior.floating,
                                ));
                              } catch (e) {
                                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                                  content: Text('${l10n.error}: $e'),
                                  backgroundColor: const Color(0xFFEF4444),
                                  behavior: SnackBarBehavior.floating,
                                ));
                              } finally {
                                setState(() => isSending = false);
                              }
                            },
                      icon: isSending
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : const Icon(Icons.send, size: 18, color: Colors.white),
                      label: Text(isSending ? l10n.sending : l10n.send,
                          style: const TextStyle(color: Colors.white)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
  titreController.dispose();
  contenuController.dispose();
}
