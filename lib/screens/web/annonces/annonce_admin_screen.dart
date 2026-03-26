// screens/web/annonces/annonce_admin_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cenou_mobile/providers/web/annonce_admin_provider.dart';
import 'package:cenou_mobile/models/admin/annonce.dart';
import 'package:intl/intl.dart';
import 'package:cenou_mobile/config/theme.dart';
import '../dashboard/dashboard_screen.dart';

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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return DashboardLayout(
      selectedIndex: 4,
      child: Column(
        children: [
          _buildActionBar(isDark),
          Expanded(child: _buildMainContent(isDark)),
        ],
      ),
    );
  }

  /// Construit le contenu principal.
  Widget _buildMainContent(bool isDark) {
    return Consumer<AnnonceAdminProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading && provider.annonces.isEmpty) {
          return Center(
            child: CircularProgressIndicator(color: Theme.of(context).colorScheme.primary),
          );
        }

        if (provider.error != null && provider.annonces.isEmpty) {
          return _buildErrorWidget(provider.error!, isDark);
        }

        return _buildContentLayout(provider, isDark);
      },
    );
  }

  /// Barre d'actions supérieure.
  Widget _buildActionBar(bool isDark) {
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
                  'Annonces & Notifications',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.getTextPrimary(context),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Envoyez des notifications importantes aux étudiants',
                  style: TextStyle(color: AppTheme.getTextSecondary(context)),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: _loadData,
            icon: Icon(Icons.refresh, color: AppTheme.getTextSecondary(context)),
            tooltip: 'Actualiser',
          ),
          const SizedBox(width: 12),
          ElevatedButton.icon(
            onPressed: () => _showSendAnnonceDialog(),
            icon: Icon(Icons.send, size: 18, color: Colors.white),
            label: const Text('Nouvelle annonce', style: TextStyle(color: Colors.white)),
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
  Widget _buildContentLayout(AnnonceAdminProvider provider, bool isDark) {
    return Column(
      children: [
        _buildStatsSection(provider, isDark),
        Expanded(
          child: _buildContentSection(provider, isDark),
        ),
      ],
    );
  }

  /// Section des statistiques.
  Widget _buildStatsSection(AnnonceAdminProvider provider, bool isDark) {
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
          _buildStatItem('Total', '${stats['total']}', Colors.blue, isDark),
          _buildStatItem('Générale', '${stats['generale']}', Colors.green, isDark),
          _buildStatItem('Par centre', '${stats['centre']}', Colors.orange, isDark),
          _buildStatItem('Étudiants', '${stats['etudiants']}', Colors.purple, isDark),
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
  Widget _buildContentSection(AnnonceAdminProvider provider, bool isDark) {
    if (provider.annonces.isEmpty) {
      return _buildEmptyState(isDark);
    }

    return _buildAnnoncesList(provider, isDark);
  }

  /// Liste des annonces.
  Widget _buildAnnoncesList(AnnonceAdminProvider provider, bool isDark) {
    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(32, 0, 32, 24),
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: provider.annonces.length,
        separatorBuilder: (context, index) => const SizedBox(height: 16),
        itemBuilder: (context, index) {
          final annonce = provider.annonces[index];
          return _buildAnnonceCard(annonce, provider, isDark);
        },
      ),
    );
  }

  /// Carte d'une annonce.
  Widget _buildAnnonceCard(Annonce annonce, AnnonceAdminProvider provider, bool isDark) {
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
                  DateFormat('dd/MM/yyyy HH:mm').format(annonce.createdAt),
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
                  '${annonce.totalDestinataires} destinataire(s)',
                  style: TextStyle(color: AppTheme.getTextTertiary(context), fontSize: 13),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () => _showDeleteDialog(annonce.id, provider, isDark),
                  icon: Icon(Icons.delete_outline, size: 20),
                  color: Colors.red.shade400,
                  tooltip: 'Supprimer',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// État lorsque la liste est vide.
  Widget _buildEmptyState(bool isDark) {
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
                'Aucune annonce envoyée',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.getTextSecondary(context),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Envoyez votre première annonce aux étudiants',
                style: TextStyle(color: AppTheme.getTextTertiary(context)),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () => _showSendAnnonceDialog(),
                icon: Icon(Icons.send, color: Colors.white),
                label: const Text('Créer une annonce', style: TextStyle(color: Colors.white)),
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
  Widget _buildErrorWidget(String error, bool isDark) {
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
                'Erreur de chargement',
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
                child: const Text('Réessayer'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Affiche le dialogue d'envoi d'annonce.
  void _showSendAnnonceDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const SendAnnonceDialog(),
    );
  }

  /// Affiche la boîte de dialogue de confirmation de suppression.
  void _showDeleteDialog(int annonceId, AnnonceAdminProvider provider, bool isDark) {
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
                'Supprimer l\'annonce',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.getTextPrimary(context),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Voulez-vous vraiment supprimer cette annonce ?',
                style: TextStyle(color: AppTheme.getTextSecondary(context)),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(
                      'Annuler',
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
                          const SnackBar(
                            content: Text('Annonce supprimée avec succès'),
                            backgroundColor: Colors.green,
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Erreur: $e'),
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
                    child: const Text('Supprimer'),
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
  const SendAnnonceDialog({Key? key}) : super(key: key);

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
            _buildHeader(),
            _buildStepIndicator(isDark),
            Expanded(child: _buildStepContent(provider, isDark)),
            _buildFooter(provider, isDark),
          ],
        ),
      ),
    );
  }

  /// En‑tête du dialogue.
  Widget _buildHeader() {
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
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Nouvelle annonce',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Envoyez une notification aux étudiants',
                  style: TextStyle(color: Colors.white70, fontSize: 13),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.close, color: Colors.white),
            tooltip: 'Fermer',
          ),
        ],
      ),
    );
  }

  /// Indicateur de progression.
  Widget _buildStepIndicator(bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey.shade900.withOpacity(0.3) : Colors.grey.shade50,
        border: Border(bottom: BorderSide(color: AppTheme.getBorderColor(context))),
      ),
      child: Row(
        children: [
          _buildStepItem(0, 'Message', Icons.edit_note, isDark),
          _buildStepConnector(0, isDark),
          _buildStepItem(1, 'Destinataires', Icons.people, isDark),
          _buildStepConnector(1, isDark),
          _buildStepItem(2, 'Résumé', Icons.check_circle_outline, isDark),
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
  Widget _buildStepContent(AnnonceAdminProvider provider, bool isDark) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(32),
      child: Form(
        key: _formKey,
        child: _currentStep == 0
            ? _buildStep1Message(isDark)
            : _currentStep == 1
            ? _buildStep2Destinataires(provider, isDark)
            : _buildStep3Resume(provider, isDark),
      ),
    );
  }

  /// Étape 1 : Saisie du message.
  Widget _buildStep1Message(bool isDark) {
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
                    'Rédigez votre message',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.getTextPrimary(context),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Soyez clair et concis pour une meilleure lecture',
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
            labelText: 'Titre de l\'annonce *',
            labelStyle: TextStyle(color: AppTheme.getTextSecondary(context)),
            hintText: 'Ex: Coupure d\'eau programmée ce soir',
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
              return 'Le titre est requis';
            }
            if (value.trim().length < 5) {
              return 'Le titre doit contenir au moins 5 caractères';
            }
            return null;
          },
        ),
        const SizedBox(height: 24),
        TextFormField(
          controller: _contenuController,
          decoration: InputDecoration(
            labelText: 'Contenu du message *',
            labelStyle: TextStyle(color: AppTheme.getTextSecondary(context)),
            hintText: 'Rédigez le contenu détaillé de votre annonce...',
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
              return 'Le contenu est requis';
            }
            if (value.trim().length < 10) {
              return 'Le contenu doit contenir au moins 10 caractères';
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
                  'Conseil : Rédigez un titre accrocheur et un message clair pour maximiser l\'engagement',
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
  Widget _buildStep2Destinataires(AnnonceAdminProvider provider, bool isDark) {
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
                    'Choisissez les destinataires',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.getTextPrimary(context),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Sélectionnez qui recevra cette annonce',
                    style: TextStyle(color: AppTheme.getTextSecondary(context), fontSize: 14),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 32),
        _buildTypeSelector(isDark),
        const SizedBox(height: 24),
        if (_selectedType == 'CENTRE_SPECIFIQUE') _buildCentreSelector(provider, isDark),
        if (_selectedType == 'ETUDIANTS') _buildAdvancedUserSelector(provider, isDark),
        const SizedBox(height: 24),
        _buildDestinatairesPreview(provider, isDark),
      ],
    );
  }

  /// Étape 3 : Résumé avant envoi.
  Widget _buildStep3Resume(AnnonceAdminProvider provider, bool isDark) {
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
                    'Vérifiez et envoyez',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.getTextPrimary(context),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Vérifiez les informations avant l\'envoi',
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
                    'Aperçu du message',
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
                    'Destinataires',
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
                      _getDestinataireDescription(provider),
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
                    'Vous allez envoyer $destinataireCount notifications. Cette action est irréversible.',
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
  Widget _buildFooter(AnnonceAdminProvider provider, bool isDark) {
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
              label: const Text('Retour'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              ),
            ),
          const Spacer(),
          OutlinedButton(
            onPressed: _isSending ? null : () => Navigator.pop(context),
            child: const Text('Annuler'),
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
                if (_validateCurrentStep()) {
                  setState(() => _currentStep++);
                }
              } else {
                _sendAnnonce();
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
                  ? 'Envoi en cours...'
                  : _currentStep < 2
                  ? 'Suivant'
                  : 'Envoyer l\'annonce',
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
  Widget _buildTypeSelector(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Type d\'annonce',
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
          segments: const [
            ButtonSegment<String>(
              value: 'TOUS',
              label: Text('Générale'),
              icon: Icon(Icons.public),
            ),
            ButtonSegment<String>(
              value: 'CENTRE_SPECIFIQUE',
              label: Text('Par centre'),
              icon: Icon(Icons.location_city),
            ),
            ButtonSegment<String>(
              value: 'ETUDIANTS',
              label: Text('Personnalisée'),
              icon: Icon(Icons.person),
            ),
          ],
        ),
      ],
    );
  }

  /// Sélecteur de centre.
  Widget _buildCentreSelector(AnnonceAdminProvider provider, bool isDark) {
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
                'Aucun centre disponible. Vérifiez la connexion.',
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
          'Sélectionner un centre',
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
            hintText: 'Choisissez un centre',
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
              return 'Veuillez sélectionner un centre';
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
                    'Centre: ${provider.centres.firstWhere((c) => c.id == _selectedCentreId).nom}',
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
  Widget _buildAdvancedUserSelector(AnnonceAdminProvider provider, bool isDark) {
    final filteredEtudiants = _getFilteredEtudiants(provider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Sélectionner les destinataires',
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
        _buildSearchAndFilters(provider, isDark),
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
                      ? 'Aucun étudiant ne correspond à votre recherche'
                      : 'Aucun étudiant disponible',
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
                  '${etudiant['matricule']} • ${etudiant['centre']}',
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
  Widget _buildSearchAndFilters(AnnonceAdminProvider provider, bool isDark) {
    final filteredEtudiants = _getFilteredEtudiants(provider);

    return Column(
      children: [
        TextField(
          controller: _searchController,
          decoration: InputDecoration(
            hintText: 'Rechercher par nom ou matricule...',
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
                  labelText: 'Filtrer par centre',
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
                      'Tous les centres',
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
              label: Text('Tout',
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
              label: Text('Aucun', style: TextStyle(color: Colors.red)),
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
  Widget _buildDestinatairesPreview(AnnonceAdminProvider provider, bool isDark) {
    String message = '';
    Color color = Colors.grey;
    IconData icon = Icons.info_outline;
    int count = 0;

    if (_selectedType == 'TOUS') {
      count = provider.etudiants.length;
      message = 'Envoi à tous les étudiants ($count)';
      color = Colors.blue;
      icon = Icons.public;
    } else if (_selectedType == 'CENTRE_SPECIFIQUE' && _selectedCentreId != null) {
      final centre = provider.centres.firstWhere((c) => c.id == _selectedCentreId);
      count = provider.etudiants.where((e) => e['centre'] == centre.nom).length;
      message = 'Envoi au centre: ${centre.nom} ($count étudiant(s))';
      color = Colors.green;
      icon = Icons.location_city;
    } else if (_selectedType == 'ETUDIANTS') {
      count = _selectedUserIds.length;
      message = 'Envoi à $count étudiant(s) sélectionné(s)';
      color = count > 0 ? Colors.purple : Colors.grey;
      icon = Icons.people;
    } else {
      message = 'Sélectionnez les destinataires';
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
                    '$count notification(s) seront envoyées',
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
  bool _validateCurrentStep() {
    if (_currentStep == 0) {
      return _formKey.currentState!.validate();
    } else if (_currentStep == 1) {
      if (_selectedType == 'CENTRE_SPECIFIQUE' && _selectedCentreId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Veuillez sélectionner un centre'),
            backgroundColor: Colors.red,
          ),
        );
        return false;
      }
      if (_selectedType == 'ETUDIANTS' && _selectedUserIds.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Veuillez sélectionner au moins un étudiant'),
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
  String _getDestinataireDescription(AnnonceAdminProvider provider) {
    if (_selectedType == 'TOUS') {
      return 'Tous les étudiants';
    } else if (_selectedType == 'CENTRE_SPECIFIQUE' && _selectedCentreId != null) {
      final centre = provider.centres.firstWhere((c) => c.id == _selectedCentreId);
      return 'Centre : ${centre.nom}';
    } else if (_selectedType == 'ETUDIANTS') {
      return '${_selectedUserIds.length} étudiant(s) sélectionné(s)';
    }
    return '';
  }

  /// Envoie l'annonce via le provider.
  Future<void> _sendAnnonce() async {
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
                  'Annonce envoyée à ${_getDestinataireCount(provider)} destinataire(s)',
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
          content: Text('Erreur: ${e.toString()}'),
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