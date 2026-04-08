// screens/web/annonces/annonce_admin_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cenou_mobile/providers/web/annonce_admin_provider.dart';
import 'package:cenou_mobile/models/admin/annonce.dart';
import 'package:intl/intl.dart';
import 'package:cenou_mobile/config/theme.dart';
import '../dashboard/dashboard_screen.dart';
import '../../../l10n/app_localizations.dart';

/// Écran d'administration des annonces.
class AnnonceAdminScreen extends StatefulWidget {
  const AnnonceAdminScreen({Key? key}) : super(key: key);

  @override
  State<AnnonceAdminScreen> createState() => _AnnonceAdminScreenState();
}

class _AnnonceAdminScreenState extends State<AnnonceAdminScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  /// Charge les données initiales via le provider.
  Future<void> _loadData() async {
    final provider = Provider.of<AnnonceAdminProvider>(context, listen: false);
    await provider.loadData();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return DashboardLayout(
      selectedIndex: 4,
      child: Column(
        children: [
          _buildActionBar(isDark, l10n),
          Expanded(child: _buildMainContent(isDark, l10n)),
        ],
      ),
    );
  }

  /// Construit le contenu principal.
  Widget _buildMainContent(bool isDark, AppLocalizations l10n) {
    return Consumer<AnnonceAdminProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading && provider.annonces.isEmpty) {
          return Center(
            child: CircularProgressIndicator(color: Theme.of(context).colorScheme.primary),
          );
        }

        if (provider.error != null && provider.annonces.isEmpty) {
          return _buildErrorWidget(provider.error!, isDark, l10n);
        }

        return _buildContentLayout(provider, isDark, l10n);
      },
    );
  }

  /// Barre d'actions supérieure.
  Widget _buildActionBar(bool isDark, AppLocalizations l10n) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
      decoration: BoxDecoration(
        color: AppTheme.getTopBarBackground(context),
        border: Border(bottom: BorderSide(color: AppTheme.getBorderColor(context), width: 1)),
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.announcementsAndNotifications,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.getTextPrimary(context),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  l10n.sendImportantNotificationsToStudents,
                  style: TextStyle(color: AppTheme.getTextSecondary(context)),
                ),
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
            icon: Icon(Icons.send, size: 18, color: Colors.white),
            label: Text(l10n.newAnnouncement, style: const TextStyle(color: Colors.white)),
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.primary,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Disposition principale avec les statistiques et la liste.
  Widget _buildContentLayout(AnnonceAdminProvider provider, bool isDark, AppLocalizations l10n) {
    return Column(
      children: [
        _buildStatsSection(provider, isDark, l10n),
        Expanded(
          child: _buildContentSection(provider, isDark, l10n),
        ),
      ],
    );
  }

  /// Section des statistiques.
  Widget _buildStatsSection(AnnonceAdminProvider provider, bool isDark, AppLocalizations l10n) {
    final stats = {
      'total': provider.annonces.length,
      'generale': provider.annonces.where((a) => a.cible == 'TOUS').length,
      'centre': provider.annonces.where((a) => a.cible == 'CENTRE_SPECIFIQUE').length,
      'etudiants': provider.annonces.where((a) => a.cible == 'ETUDIANTS').length,
    };

    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
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
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildStatItem(l10n.total, '${stats['total']}', Colors.blue, isDark),
          _buildStatItem(l10n.generalAnnouncement, '${stats['generale']}', Colors.green, isDark),
          _buildStatItem(l10n.byCenter, '${stats['centre']}', Colors.orange, isDark),
          _buildStatItem(l10n.students, '${stats['etudiants']}', Colors.purple, isDark),
        ],
      ),
    );
  }

  /// Élément individuel de statistique.
  Widget _buildStatItem(String label, String value, Color color, bool isDark) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withOpacity(isDark ? 0.2 : 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: AppTheme.getTextSecondary(context),
          ),
        ),
      ],
    );
  }

  /// Contenu principal (liste ou état vide).
  Widget _buildContentSection(AnnonceAdminProvider provider, bool isDark, AppLocalizations l10n) {
    if (provider.annonces.isEmpty) {
      return _buildEmptyState(isDark, l10n);
    }

    return _buildAnnoncesList(provider, isDark, l10n);
  }

  /// Liste des annonces.
  Widget _buildAnnoncesList(AnnonceAdminProvider provider, bool isDark, AppLocalizations l10n) {
    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(32, 0, 32, 24),
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: provider.annonces.length,
        separatorBuilder: (context, index) => const SizedBox(height: 16),
        itemBuilder: (context, index) {
          final annonce = provider.annonces[index];
          return _buildAnnonceCard(annonce, provider, isDark, l10n);
        },
      ),
    );
  }

  /// Carte d'une annonce.
  Widget _buildAnnonceCard(Annonce annonce, AnnonceAdminProvider provider, bool isDark, AppLocalizations l10n) {
    return Card(
      elevation: isDark ? 4 : 2,
      color: AppTheme.getCardBackground(context),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: annonce.typeColor.withOpacity(isDark ? 0.2 : 0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                        color: annonce.typeColor.withOpacity(isDark ? 0.4 : 0.3)
                    ),
                  ),
                  child: Text(
                    annonce.typeLabel,
                    style: TextStyle(
                      color: annonce.typeColor,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ),
                const Spacer(),
                Text(
                  DateFormat('dd/MM/yyyy HH:mm', l10n.locale.languageCode).format(annonce.createdAt),
                  style: TextStyle(
                    color: AppTheme.getTextTertiary(context),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              annonce.titre,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppTheme.getTextPrimary(context),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              annonce.contenu,
              style: TextStyle(
                color: AppTheme.getTextSecondary(context),
                fontSize: 14,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.group, size: 16, color: AppTheme.getTextTertiary(context)),
                const SizedBox(width: 6),
                Text(
                  annonce.summary,
                  style: TextStyle(color: AppTheme.getTextTertiary(context), fontSize: 13),
                ),
                const SizedBox(width: 8),
                Icon(Icons.person, size: 16, color: AppTheme.getTextTertiary(context)),
                const SizedBox(width: 4),
                Text(
                  l10n.destinatairesCount(annonce.totalDestinataires),
                  style: TextStyle(color: AppTheme.getTextTertiary(context), fontSize: 13),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () => _showDeleteDialog(annonce.id, provider, isDark, l10n),
                  icon: Icon(Icons.delete_outline, size: 20),
                  color: Colors.red.shade400,
                  tooltip: l10n.delete,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// État lorsque la liste est vide.
  Widget _buildEmptyState(bool isDark, AppLocalizations l10n) {
    return Center(
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                  Icons.announcement_outlined,
                  size: 80,
                  color: AppTheme.getTextTertiary(context)
              ),
              const SizedBox(height: 16),
              Text(
                l10n.noAnnouncementsSent,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.getTextSecondary(context),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                l10n.sendFirstAnnouncement,
                style: TextStyle(color: AppTheme.getTextTertiary(context)),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () => _showSendAnnonceDialog(l10n),
                icon: Icon(Icons.send, color: Colors.white),
                label: Text(l10n.createAnnouncement, style: const TextStyle(color: Colors.white)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Affichage en cas d'erreur de chargement.
  Widget _buildErrorWidget(String error, bool isDark, AppLocalizations l10n) {
    return Center(
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 64, color: Colors.red.shade400),
              const SizedBox(height: 16),
              Text(
                l10n.loadingError,
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
                onPressed: _loadData,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red.shade400,
                  foregroundColor: Colors.white,
                ),
                child: Text(l10n.retry),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Affiche le dialogue d'envoi d'annonce.
  void _showSendAnnonceDialog(AppLocalizations l10n) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => SendAnnonceDialog(l10n: l10n),
    );
  }

  /// Affiche la boîte de dialogue de confirmation de suppression.
  void _showDeleteDialog(int annonceId, AnnonceAdminProvider provider, bool isDark, AppLocalizations l10n) {
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
                l10n.deleteAnnouncement,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.getTextPrimary(context),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                l10n.confirmDeleteAnnouncement,
                style: TextStyle(color: AppTheme.getTextSecondary(context)),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(
                      l10n.cancel,
                      style: TextStyle(color: AppTheme.getTextSecondary(context)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: () async {
                      Navigator.pop(context);
                      try {
                        await provider.deleteAnnonce(annonceId);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(l10n.announcementDeletedSuccess),
                            backgroundColor: Colors.green,
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('${l10n.error}: $e'),
                            backgroundColor: Colors.red,
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                    ),
                    child: Text(l10n.delete),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ==================== DIALOGUE D'ENVOI OPTIMISÉ ====================

/// Dialogue d'envoi d'une nouvelle annonce.
class SendAnnonceDialog extends StatefulWidget {
  final AppLocalizations l10n;
  const SendAnnonceDialog({Key? key, required this.l10n}) : super(key: key);

  @override
  State<SendAnnonceDialog> createState() => _SendAnnonceDialogProState();
}

class _SendAnnonceDialogProState extends State<SendAnnonceDialog> {
  final _formKey = GlobalKey<FormState>();
  final _titreController = TextEditingController();
  final _contenuController = TextEditingController();
  final _searchController = TextEditingController();

  // État
  int _currentStep = 0;
  String _selectedType = 'TOUS';
  int? _selectedCentreId;
  List<int> _selectedUserIds = [];
  String? _centreFilter;
  String _searchQuery = '';
  bool _isSending = false;

  @override
  void dispose() {
    _titreController.dispose();
    _contenuController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<AnnonceAdminProvider>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final l10n = widget.l10n;

    return Dialog(
      backgroundColor: AppTheme.getCardBackground(context),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 900,
          maxHeight: MediaQuery.of(context).size.height * 0.85,
        ),
        child: Column(
          children: [
            _buildHeader(l10n),
            _buildStepIndicator(isDark, l10n),
            Expanded(child: _buildStepContent(provider, isDark, l10n)),
            _buildFooter(provider, isDark, l10n),
          ],
        ),
      ),
    );
  }

  /// En‑tête du dialogue.
  Widget _buildHeader(AppLocalizations l10n) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Theme.of(context).colorScheme.primary,
            Theme.of(context).colorScheme.primary.withOpacity(0.8),
          ],
        ),
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
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.campaign, color: Colors.white, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.newAnnouncement,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  l10n.sendNotificationToStudents,
                  style: const TextStyle(color: Colors.white70, fontSize: 13),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.close, color: Colors.white),
            tooltip: l10n.close,
          ),
        ],
      ),
    );
  }

  /// Indicateur de progression.
  Widget _buildStepIndicator(bool isDark, AppLocalizations l10n) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey.shade900.withOpacity(0.3) : Colors.grey.shade50,
        border: Border(bottom: BorderSide(color: AppTheme.getBorderColor(context))),
      ),
      child: Row(
        children: [
          _buildStepItem(0, l10n.message, Icons.edit_note, isDark),
          _buildStepConnector(0, isDark),
          _buildStepItem(1, l10n.recipients, Icons.people, isDark),
          _buildStepConnector(1, isDark),
          _buildStepItem(2, l10n.summary, Icons.check_circle_outline, isDark),
        ],
      ),
    );
  }

  /// Élément individuel du stepper.
  Widget _buildStepItem(int step, String label, IconData icon, bool isDark) {
    final isActive = _currentStep == step;
    final isCompleted = _currentStep > step;
    final color = isCompleted
        ? Colors.green
        : isActive
        ? Theme.of(context).colorScheme.primary
        : AppTheme.getTextTertiary(context);

    return Expanded(
      child: Column(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: isCompleted
                  ? Colors.green
                  : isActive
                  ? Theme.of(context).colorScheme.primary
                  : isDark
                  ? Colors.grey.shade800
                  : Colors.grey.shade200,
              shape: BoxShape.circle,
            ),
            child: Icon(
              isCompleted ? Icons.check : icon,
              color: isCompleted || isActive ? Colors.white : AppTheme.getTextTertiary(context),
              size: 20,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  /// Connecteur entre les étapes.
  Widget _buildStepConnector(int step, bool isDark) {
    final isCompleted = _currentStep > step;
    return Expanded(
      flex: 2,
      child: Container(
        height: 2,
        margin: const EdgeInsets.only(bottom: 30),
        color: isCompleted
            ? Colors.green
            : isDark
            ? Colors.grey.shade700
            : Colors.grey.shade300,
      ),
    );
  }

  /// Contenu de l'étape courante.
  Widget _buildStepContent(AnnonceAdminProvider provider, bool isDark, AppLocalizations l10n) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(32),
      child: Form(
        key: _formKey,
        child: _currentStep == 0
            ? _buildStep1Message(isDark, l10n)
            : _currentStep == 1
            ? _buildStep2Destinataires(provider, isDark, l10n)
            : _buildStep3Resume(provider, isDark, l10n),
      ),
    );
  }

  /// Étape 1 : Saisie du message.
  Widget _buildStep1Message(bool isDark, AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(Icons.edit_note, color: Theme.of(context).colorScheme.primary),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.writeYourMessage,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.getTextPrimary(context),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    l10n.beClearAndConcise,
                    style: TextStyle(color: AppTheme.getTextSecondary(context), fontSize: 14),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 32),
        TextFormField(
          controller: _titreController,
          decoration: InputDecoration(
            labelText: l10n.announcementTitle,
            labelStyle: TextStyle(color: AppTheme.getTextSecondary(context)),
            hintText: l10n.titleExample,
            hintStyle: TextStyle(color: AppTheme.getTextTertiary(context)),
            prefixIcon: Icon(Icons.title, color: Theme.of(context).colorScheme.primary),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppTheme.getBorderColor(context)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppTheme.getBorderColor(context)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Theme.of(context).colorScheme.primary, width: 2),
            ),
            filled: true,
            fillColor: isDark ? Colors.grey.shade900.withOpacity(0.3) : Colors.grey.shade50,
          ),
          maxLength: 100,
          style: TextStyle(color: AppTheme.getTextPrimary(context), fontSize: 16),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return l10n.titleRequired;
            }
            if (value.trim().length < 5) {
              return l10n.titleMinLength;
            }
            return null;
          },
        ),
        const SizedBox(height: 24),
        TextFormField(
          controller: _contenuController,
          decoration: InputDecoration(
            labelText: l10n.messageContent,
            labelStyle: TextStyle(color: AppTheme.getTextSecondary(context)),
            hintText: l10n.writeDetailedContent,
            hintStyle: TextStyle(color: AppTheme.getTextTertiary(context)),
            alignLabelWithHint: true,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppTheme.getBorderColor(context)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppTheme.getBorderColor(context)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Theme.of(context).colorScheme.primary, width: 2),
            ),
            filled: true,
            fillColor: isDark ? Colors.grey.shade900.withOpacity(0.3) : Colors.grey.shade50,
          ),
          maxLines: 8,
          minLines: 6,
          maxLength: 500,
          style: TextStyle(color: AppTheme.getTextPrimary(context), fontSize: 15, height: 1.5),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return l10n.contentRequired;
            }
            if (value.trim().length < 10) {
              return l10n.contentMinLength;
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.blue.withOpacity(isDark ? 0.2 : 0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.blue.withOpacity(0.3)),
          ),
          child: Row(
            children: [
              Icon(Icons.lightbulb_outline, color: Colors.blue, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  l10n.writingTip,
                  style: TextStyle(color: Colors.blue.shade700, fontSize: 13),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Étape 2 : Sélection des destinataires.
  Widget _buildStep2Destinataires(AnnonceAdminProvider provider, bool isDark, AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(Icons.people, color: Theme.of(context).colorScheme.primary),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.chooseRecipients,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.getTextPrimary(context),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    l10n.selectWhoWillReceive,
                    style: TextStyle(color: AppTheme.getTextSecondary(context), fontSize: 14),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 32),
        _buildTypeSelector(isDark, l10n),
        const SizedBox(height: 24),
        if (_selectedType == 'CENTRE_SPECIFIQUE') _buildCentreSelector(provider, isDark, l10n),
        if (_selectedType == 'ETUDIANTS') _buildAdvancedUserSelector(provider, isDark, l10n),
        const SizedBox(height: 24),
        _buildDestinatairesPreview(provider, isDark, l10n),
      ],
    );
  }

  /// Étape 3 : Résumé avant envoi.
  Widget _buildStep3Resume(AnnonceAdminProvider provider, bool isDark, AppLocalizations l10n) {
    final destinataireCount = _getDestinataireCount(provider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.check_circle, color: Colors.green),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.verifyAndSend,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.getTextPrimary(context),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    l10n.verifyInfoBeforeSending,
                    style: TextStyle(color: AppTheme.getTextSecondary(context), fontSize: 14),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 32),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: isDark ? Colors.grey.shade900.withOpacity(0.3) : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppTheme.getBorderColor(context)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.message, color: Theme.of(context).colorScheme.primary, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    l10n.messagePreview,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppTheme.getTextPrimary(context),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                _titreController.text.trim(),
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.getTextPrimary(context),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                _contenuController.text.trim(),
                style: TextStyle(
                  fontSize: 14,
                  color: AppTheme.getTextSecondary(context),
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.blue.withOpacity(isDark ? 0.2 : 0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.blue.withOpacity(0.3)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.people, color: Colors.blue, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    l10n.recipients,
                    style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue.shade700),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.blue,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '$destinataireCount',
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _getDestinataireDescription(provider, l10n),
                      style: TextStyle(color: Colors.blue.shade700, fontSize: 14),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        if (destinataireCount > 100)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.orange.withOpacity(isDark ? 0.2 : 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.orange.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                Icon(Icons.warning_amber, color: Colors.orange, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    l10n.massNotificationWarning(destinataireCount),
                    style: TextStyle(color: Colors.orange.shade700, fontSize: 13),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  /// Pied de dialogue (boutons).
  Widget _buildFooter(AnnonceAdminProvider provider, bool isDark, AppLocalizations l10n) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey.shade900.withOpacity(0.5) : Colors.grey.shade50,
        border: Border(top: BorderSide(color: AppTheme.getBorderColor(context))),
      ),
      child: Row(
        children: [
          if (_currentStep > 0)
            OutlinedButton.icon(
              onPressed: _isSending ? null : () => setState(() => _currentStep--),
              icon: const Icon(Icons.arrow_back, size: 18),
              label: Text(l10n.back),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              ),
            ),
          const Spacer(),
          OutlinedButton(
            onPressed: _isSending ? null : () => Navigator.pop(context),
            child: Text(l10n.cancel),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            ),
          ),
          const SizedBox(width: 12),
          ElevatedButton.icon(
            onPressed: _isSending
                ? null
                : () {
              if (_currentStep < 2) {
                if (_validateCurrentStep(l10n)) {
                  setState(() => _currentStep++);
                }
              } else {
                _sendAnnonce(l10n);
              }
            },
            icon: _isSending
                ? const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
            )
                : Icon(
              _currentStep < 2 ? Icons.arrow_forward : Icons.send,
              size: 18,
              color: Colors.white,
            ),
            label: Text(
              _isSending
                  ? l10n.sendingInProgress
                  : _currentStep < 2
                  ? l10n.next
                  : l10n.sendAnnouncement,
              style: const TextStyle(color: Colors.white, fontSize: 15),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.primary,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            ),
          ),
        ],
      ),
    );
  }

  /// Sélecteur de type d'annonce.
  Widget _buildTypeSelector(bool isDark, AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.announcementType,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: AppTheme.getTextPrimary(context),
          ),
        ),
        const SizedBox(height: 12),
        SegmentedButton<String>(
          selected: {_selectedType},
          onSelectionChanged: (Set<String> newSelection) {
            setState(() {
              _selectedType = newSelection.first;
              _selectedCentreId = null;
              _selectedUserIds.clear();
              _centreFilter = null;
              _searchQuery = '';
              _searchController.clear();
            });
          },
          style: SegmentedButton.styleFrom(
            backgroundColor: isDark ? Colors.grey.shade900.withOpacity(0.3) : Colors.grey.shade100,
            selectedBackgroundColor: Theme.of(context).colorScheme.primary,
            selectedForegroundColor: Colors.white,
          ),
          segments: [
            ButtonSegment<String>(
              value: 'TOUS',
              label: Text(l10n.generalAnnouncement),
              icon: const Icon(Icons.public),
            ),
            ButtonSegment<String>(
              value: 'CENTRE_SPECIFIQUE',
              label: Text(l10n.byCenter),
              icon: const Icon(Icons.location_city),
            ),
            ButtonSegment<String>(
              value: 'ETUDIANTS',
              label: Text(l10n.custom),
              icon: const Icon(Icons.person),
            ),
          ],
        ),
      ],
    );
  }

  /// Sélecteur de centre.
  Widget _buildCentreSelector(AnnonceAdminProvider provider, bool isDark, AppLocalizations l10n) {
    if (provider.centres.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.orange.withOpacity(isDark ? 0.2 : 0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.orange.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            Icon(Icons.warning, color: Colors.orange),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                l10n.noCentersAvailable,
                style: TextStyle(color: Colors.orange),
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.selectCenter,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: AppTheme.getTextPrimary(context),
          ),
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<int>(
          value: _selectedCentreId,
          decoration: InputDecoration(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: AppTheme.getBorderColor(context)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: AppTheme.getBorderColor(context)),
            ),
            hintText: l10n.chooseCenter,
            hintStyle: TextStyle(color: AppTheme.getTextSecondary(context)),
            prefixIcon: Icon(Icons.location_city, color: AppTheme.getTextSecondary(context)),
            filled: true,
            fillColor: isDark ? Colors.grey.shade900.withOpacity(0.3) : Colors.grey.shade50,
          ),
          dropdownColor: AppTheme.getCardBackground(context),
          items: provider.centres
              .map((centre) => DropdownMenuItem<int>(
            value: centre.id,
            child: Text(
              centre.nom,
              style: TextStyle(color: AppTheme.getTextPrimary(context)),
            ),
          ))
              .toList(),
          onChanged: (value) {
            setState(() {
              _selectedCentreId = value;
            });
          },
          style: TextStyle(color: AppTheme.getTextPrimary(context)),
          validator: (value) {
            if (_selectedType == 'CENTRE_SPECIFIQUE' && value == null) {
              return l10n.pleaseSelectCenter;
            }
            return null;
          },
        ),
        if (_selectedCentreId != null) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(isDark ? 0.2 : 0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.green.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.green, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    l10n.selectedCenter(
                        provider.centres.firstWhere((c) => c.id == _selectedCentreId).nom),
                    style: TextStyle(
                      color: Colors.green,
                      fontWeight: FontWeight.w500,
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  /// Sélecteur avancé d'étudiants.
  Widget _buildAdvancedUserSelector(AnnonceAdminProvider provider, bool isDark, AppLocalizations l10n) {
    final filteredEtudiants = _getFilteredEtudiants(provider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              l10n.selectRecipients,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: AppTheme.getTextPrimary(context),
              ),
            ),
            const Spacer(),
            Chip(
              label: Text(
                '${_selectedUserIds.length}',
                style: TextStyle(
                  color: _selectedUserIds.isEmpty
                      ? AppTheme.getTextSecondary(context)
                      : Colors.white,
                ),
              ),
              backgroundColor: _selectedUserIds.isEmpty
                  ? AppTheme.getBorderColor(context)
                  : Colors.green,
            ),
          ],
        ),
        const SizedBox(height: 12),
        _buildSearchAndFilters(provider, isDark, l10n),
        const SizedBox(height: 12),
        Container(
          height: 250,
          decoration: BoxDecoration(
            border: Border.all(color: AppTheme.getBorderColor(context)),
            borderRadius: BorderRadius.circular(8),
          ),
          child: filteredEtudiants.isEmpty
              ? Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.search_off,
                    size: 48, color: AppTheme.getTextTertiary(context)),
                const SizedBox(height: 12),
                Text(
                  _searchQuery.isNotEmpty
                      ? l10n.noStudentMatchesSearch
                      : l10n.noStudentsAvailable,
                  style: TextStyle(color: AppTheme.getTextSecondary(context)),
                ),
              ],
            ),
          )
              : ListView.builder(
            itemCount: filteredEtudiants.length,
            itemBuilder: (context, index) {
              final etudiant = filteredEtudiants[index];
              final isSelected = _selectedUserIds.contains(etudiant['id']);

              return CheckboxListTile(
                value: isSelected,
                onChanged: (value) {
                  setState(() {
                    if (value == true) {
                      _selectedUserIds.add(etudiant['id']);
                    } else {
                      _selectedUserIds.remove(etudiant['id']);
                    }
                  });
                },
                title: Text(
                  etudiant['nom'],
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                    color: AppTheme.getTextPrimary(context),
                  ),
                ),
                subtitle: Text(
                  l10n.studentInfo(etudiant['matricule'], etudiant['centre']),
                  style: TextStyle(
                      fontSize: 12, color: AppTheme.getTextSecondary(context)),
                ),
                controlAffinity: ListTileControlAffinity.leading,
                activeColor: Theme.of(context).colorScheme.primary,
              );
            },
          ),
        ),
      ],
    );
  }

  /// Barre de recherche et filtres.
  Widget _buildSearchAndFilters(AnnonceAdminProvider provider, bool isDark, AppLocalizations l10n) {
    final filteredEtudiants = _getFilteredEtudiants(provider);

    return Column(
      children: [
        TextField(
          controller: _searchController,
          decoration: InputDecoration(
            hintText: l10n.searchByNameOrMatricule,
            hintStyle: TextStyle(color: AppTheme.getTextTertiary(context)),
            prefixIcon: Icon(Icons.search, color: AppTheme.getTextSecondary(context)),
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
            suffixIcon: _searchQuery.isNotEmpty
                ? IconButton(
              icon: Icon(Icons.clear, color: AppTheme.getTextSecondary(context)),
              onPressed: () {
                setState(() {
                  _searchController.clear();
                  _searchQuery = '';
                });
              },
            )
                : null,
          ),
          onChanged: (value) {
            setState(() {
              _searchQuery = value;
            });
          },
          style: TextStyle(color: AppTheme.getTextPrimary(context)),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: DropdownButtonFormField<String>(
                value: _centreFilter,
                decoration: InputDecoration(
                  labelText: l10n.filterByCenter,
                  labelStyle: TextStyle(color: AppTheme.getTextSecondary(context)),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: AppTheme.getBorderColor(context)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: AppTheme.getBorderColor(context)),
                  ),
                  prefixIcon: Icon(Icons.filter_list, color: AppTheme.getTextSecondary(context)),
                  filled: true,
                  fillColor: isDark ? Colors.grey.shade900.withOpacity(0.3) : Colors.grey.shade50,
                ),
                dropdownColor: AppTheme.getCardBackground(context),
                items: [
                  DropdownMenuItem<String>(
                    value: null,
                    child: Text(
                      l10n.allCenters,
                      style: TextStyle(color: AppTheme.getTextPrimary(context)),
                    ),
                  ),
                  ...provider.centres.map((centre) => DropdownMenuItem<String>(
                    value: centre.nom,
                    child: Text(
                      centre.nom,
                      style: TextStyle(color: AppTheme.getTextPrimary(context)),
                    ),
                  )),
                ],
                onChanged: (value) {
                  setState(() {
                    _centreFilter = value;
                  });
                },
                style: TextStyle(color: AppTheme.getTextPrimary(context)),
              ),
            ),
            const SizedBox(width: 12),
            OutlinedButton.icon(
              onPressed: () {
                setState(() {
                  _selectedUserIds = filteredEtudiants.map((e) => e['id'] as int).toList();
                });
              },
              icon: Icon(Icons.select_all,
                  size: 18, color: Theme.of(context).colorScheme.primary),
              label: Text(l10n.all,
                  style: TextStyle(color: Theme.of(context).colorScheme.primary)),
              style: OutlinedButton.styleFrom(
                side: BorderSide(
                    color: Theme.of(context).colorScheme.primary.withOpacity(0.3)),
              ),
            ),
            const SizedBox(width: 8),
            OutlinedButton.icon(
              onPressed: () => setState(() => _selectedUserIds.clear()),
              icon: Icon(Icons.clear_all, size: 18, color: Colors.red),
              label: Text(l10n.none, style: TextStyle(color: Colors.red)),
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: Colors.red.withOpacity(0.3)),
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// Aperçu des destinataires.
  Widget _buildDestinatairesPreview(AnnonceAdminProvider provider, bool isDark, AppLocalizations l10n) {
    String message = '';
    Color color = Colors.grey;
    IconData icon = Icons.info_outline;
    int count = 0;

    if (_selectedType == 'TOUS') {
      count = provider.etudiants.length;
      message = l10n.sendToAllStudents(count);
      color = Colors.blue;
      icon = Icons.public;
    } else if (_selectedType == 'CENTRE_SPECIFIQUE' && _selectedCentreId != null) {
      final centre = provider.centres.firstWhere((c) => c.id == _selectedCentreId);
      count = provider.etudiants.where((e) => e['centre'] == centre.nom).length;
      message = l10n.sendToCenter(centre.nom, count);
      color = Colors.green;
      icon = Icons.location_city;
    } else if (_selectedType == 'ETUDIANTS') {
      count = _selectedUserIds.length;
      message = l10n.sendToSelectedStudents(count);
      color = count > 0 ? Colors.purple : Colors.grey;
      icon = Icons.people;
    } else {
      message = l10n.selectRecipients;
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(isDark ? 0.2 : 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(isDark ? 0.4 : 0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  message,
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.w500,
                    fontSize: 14,
                  ),
                ),
                if (count > 0) ...[
                  const SizedBox(height: 4),
                  Text(
                    l10n.notificationsWillBeSent(count),
                    style: TextStyle(color: color.withOpacity(0.7), fontSize: 12),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Filtre les étudiants selon la recherche et le centre.
  List<Map<String, dynamic>> _getFilteredEtudiants(AnnonceAdminProvider provider) {
    return provider.etudiants.where((etudiant) {
      final matchesSearch = _searchQuery.isEmpty ||
          etudiant['nom'].toString().toLowerCase().contains(_searchQuery.toLowerCase()) ||
          etudiant['matricule'].toString().toLowerCase().contains(_searchQuery.toLowerCase());

      final matchesCentre = _centreFilter == null || etudiant['centre'] == _centreFilter;

      return matchesSearch && matchesCentre;
    }).toList();
  }

  /// Valide l'étape courante.
  bool _validateCurrentStep(AppLocalizations l10n) {
    if (_currentStep == 0) {
      return _formKey.currentState!.validate();
    } else if (_currentStep == 1) {
      if (_selectedType == 'CENTRE_SPECIFIQUE' && _selectedCentreId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.pleaseSelectCenter),
            backgroundColor: Colors.red,
          ),
        );
        return false;
      }
      if (_selectedType == 'ETUDIANTS' && _selectedUserIds.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.pleaseSelectAtLeastOneStudent),
            backgroundColor: Colors.red,
          ),
        );
        return false;
      }
    }
    return true;
  }

  /// Nombre de destinataires.
  int _getDestinataireCount(AnnonceAdminProvider provider) {
    if (_selectedType == 'TOUS') {
      return provider.etudiants.length;
    } else if (_selectedType == 'CENTRE_SPECIFIQUE' && _selectedCentreId != null) {
      final centre = provider.centres.firstWhere((c) => c.id == _selectedCentreId);
      return provider.etudiants.where((e) => e['centre'] == centre.nom).length;
    } else if (_selectedType == 'ETUDIANTS') {
      return _selectedUserIds.length;
    }
    return 0;
  }

  /// Description des destinataires.
  String _getDestinataireDescription(AnnonceAdminProvider provider, AppLocalizations l10n) {
    if (_selectedType == 'TOUS') {
      return l10n.allStudents;
    } else if (_selectedType == 'CENTRE_SPECIFIQUE' && _selectedCentreId != null) {
      final centre = provider.centres.firstWhere((c) => c.id == _selectedCentreId);
      return l10n.centerColon(centre.nom);
    } else if (_selectedType == 'ETUDIANTS') {
      return l10n.selectedStudentsCount(_selectedUserIds.length);
    }
    return '';
  }

  /// Envoie l'annonce via le provider.
  Future<void> _sendAnnonce(AppLocalizations l10n) async {
    final provider = Provider.of<AnnonceAdminProvider>(context, listen: false);

    setState(() => _isSending = true);

    try {
      await provider.sendAnnonce(
        titre: _titreController.text.trim(),
        contenu: _contenuController.text.trim(),
        cible: _selectedType,
        centreId: _selectedType == 'CENTRE_SPECIFIQUE' ? _selectedCentreId : null,
        userIds:
        _selectedType == 'ETUDIANTS' && _selectedUserIds.isNotEmpty ? _selectedUserIds : null,
        statut: 'PUBLIE',
      );

      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.white),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  l10n.announcementSentTo(_getDestinataireCount(provider)),
                ),
              ),
            ],
          ),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${l10n.error}: ${e.toString()}'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isSending = false);
      }
    }
  }
}