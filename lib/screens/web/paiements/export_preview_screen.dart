import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cenou_mobile/models/paiement.dart';
import 'package:cenou_mobile/providers/web/paiement_admin_provider.dart';
import 'package:intl/intl.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:cenou_mobile/config/theme.dart';
import '../../../utils/html_utils.dart';

/// Écran de prévisualisation avant l’export d’un rapport de paiements.
///
/// Affiche un aperçu des données et permet de générer le fichier final
/// au format demandé (PDF, CSV, Excel, etc.).
class ExportPreviewScreen extends StatefulWidget {
  final String format;
  final List<Paiement> paiements;
  final Map<String, dynamic>? filters;

  const ExportPreviewScreen({
    super.key,
    required this.format,
    required this.paiements,
    this.filters,
  });

  @override
  State<ExportPreviewScreen> createState() => _ExportPreviewScreenState();
}

class _ExportPreviewScreenState extends State<ExportPreviewScreen> {
  bool _isGenerating = false;
  String? _error;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: AppTheme.getDashboardBackground(context),
      appBar: AppBar(
        title: Text(
          'Aperçu Export ${widget.format.toUpperCase()}',
          style: TextStyle(color: AppTheme.getTextPrimary(context)),
        ),
        backgroundColor: AppTheme.getTopBarBackground(context),
        iconTheme: IconThemeData(color: AppTheme.getTextPrimary(context)),
        actions: [
          if (!_isGenerating) ...[
            IconButton(
              icon: Icon(Icons.download, color: AppTheme.getTextPrimary(context)),
              onPressed: _generateAndDownload,
              tooltip: 'Générer et télécharger',
            ),
            IconButton(
              icon: Icon(Icons.share, color: AppTheme.getTextPrimary(context)),
              onPressed: _sharePreview,
              tooltip: 'Partager',
            ),
          ],
        ],
      ),
      body: _buildContent(isDark),
    );
  }

  /// Construit le contenu principal de l’écran.
  Widget _buildContent(bool isDark) {
    if (_isGenerating) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: Theme.of(context).colorScheme.primary),
            const SizedBox(height: 20),
            Text(
              'Génération en cours...',
              style: TextStyle(color: AppTheme.getTextPrimary(context)),
            ),
            Text(
              'Veuillez patienter',
              style: TextStyle(color: AppTheme.getTextSecondary(context)),
            ),
          ],
        ),
      );
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error, size: 64, color: Colors.red.shade400),
            const SizedBox(height: 20),
            Text(
              'Erreur',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppTheme.getTextPrimary(context),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Text(
                _error!,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: isDark ? Colors.red.shade300 : Colors.red.shade600,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Colors.white,
              ),
              child: const Text('Retour'),
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(isDark),
          const SizedBox(height: 20),
          _buildStats(isDark),
          const SizedBox(height: 20),
          _buildPreview(isDark),
          const SizedBox(height: 30),
          _buildActionButtons(),
        ],
      ),
    );
  }

  /// Section d’en‑tête du rapport (titre, format, date, filtres).
  Widget _buildHeader(bool isDark) {
    return Card(
      color: AppTheme.getCardBackground(context),
      elevation: isDark ? 4 : 2,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  _getFormatIcon(widget.format),
                  size: 40,
                  color: _getFormatColor(widget.format),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Rapport des Paiements CENOU',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.getTextPrimary(context),
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        'Format: ${widget.format.toUpperCase()}',
                        style: TextStyle(
                          color: _getFormatColor(widget.format),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Généré le ${DateFormat('dd/MM/yyyy à HH:mm').format(DateTime.now())}',
                        style: TextStyle(color: AppTheme.getTextSecondary(context)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 15),
            if (widget.filters != null && widget.filters!.isNotEmpty) ...[
              Divider(color: AppTheme.getBorderColor(context)),
              Text(
                'Filtres appliqués:',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: AppTheme.getTextPrimary(context),
                ),
              ),
              const SizedBox(height: 5),
              Text(
                _formatFilters(widget.filters!),
                style: TextStyle(color: AppTheme.getTextSecondary(context)),
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// Affichage des indicateurs statistiques du rapport.
  Widget _buildStats(bool isDark) {
    final total = widget.paiements.length;
    final confirmes = widget.paiements.where((p) => p.isConfirme).length;
    final enAttente = widget.paiements.where((p) => p.statut == 'EN_ATTENTE').length;
    final montantTotal = widget.paiements
        .where((p) => p.isConfirme)
        .fold(0.0, (sum, p) => sum + p.montant);

    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 4,
      crossAxisSpacing: 15,
      mainAxisSpacing: 15,
      children: [
        _buildStatCard('Total Paiements', '$total', Colors.blue, isDark),
        _buildStatCard('Confirmés', '$confirmes', Colors.green, isDark),
        _buildStatCard('En Attente', '$enAttente', Colors.orange, isDark),
        _buildStatCard(
          'Montant Total',
          '${NumberFormat('#,##0').format(montantTotal)} FCFA',
          Colors.purple,
          isDark,
        ),
      ],
    );
  }

  /// Carte d’un indicateur statistique.
  Widget _buildStatCard(String label, String value, Color color, bool isDark) {
    return Card(
      elevation: isDark ? 4 : 2,
      color: AppTheme.getCardBackground(context),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              value,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                color: AppTheme.getTextSecondary(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Tableau de prévisualisation des données (10 premiers paiements).
  Widget _buildPreview(bool isDark) {
    return Card(
      color: AppTheme.getCardBackground(context),
      elevation: isDark ? 4 : 2,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Aperçu des données',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppTheme.getTextPrimary(context),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              '${widget.paiements.length} paiements trouvés',
              style: TextStyle(color: AppTheme.getTextSecondary(context)),
            ),
            const SizedBox(height: 20),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                columnSpacing: 20,
                headingRowColor: MaterialStateProperty.resolveWith<Color?>(
                      (Set<MaterialState> states) {
                    return isDark ? Colors.grey.shade900 : const Color(0xFFF8FAFC);
                  },
                ),
                columns: [
                  DataColumn(
                    label: Text(
                      'Étudiant',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppTheme.getTextPrimary(context),
                      ),
                    ),
                  ),
                  DataColumn(
                    label: Text(
                      'Montant',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppTheme.getTextPrimary(context),
                      ),
                    ),
                    numeric: true,
                  ),
                  DataColumn(
                    label: Text(
                      'Statut',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppTheme.getTextPrimary(context),
                      ),
                    ),
                  ),
                  DataColumn(
                    label: Text(
                      'Mode',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppTheme.getTextPrimary(context),
                      ),
                    ),
                  ),
                  DataColumn(
                    label: Text(
                      'Date',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppTheme.getTextPrimary(context),
                      ),
                    ),
                  ),
                ],
                rows: widget.paiements.take(10).map((paiement) {
                  return DataRow(cells: [
                    DataCell(Text(
                      paiement.etudiantNomComplet,
                      style: TextStyle(color: AppTheme.getTextPrimary(context)),
                    )),
                    DataCell(Text(
                      '${NumberFormat('#,##0').format(paiement.montant)} FCFA',
                      style: TextStyle(color: AppTheme.getTextPrimary(context)),
                    )),
                    DataCell(
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: _getStatusColor(paiement.statut).withOpacity(isDark ? 0.2 : 0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: _getStatusColor(paiement.statut).withOpacity(isDark ? 0.4 : 0.3),
                          ),
                        ),
                        child: Text(
                          _getStatutLabel(paiement.statut),
                          style: TextStyle(
                            color: _getStatusColor(paiement.statut),
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    DataCell(Text(
                      _getModeLabel(paiement.modePaiement),
                      style: TextStyle(color: AppTheme.getTextPrimary(context)),
                    )),
                    DataCell(Text(
                      paiement.datePaiement != null
                          ? DateFormat('dd/MM/yy HH:mm').format(paiement.datePaiement!)
                          : '',
                      style: TextStyle(color: AppTheme.getTextPrimary(context)),
                    )),
                  ]);
                }).toList(),
              ),
            ),
            if (widget.paiements.length > 10)
              Padding(
                padding: const EdgeInsets.only(top: 20),
                child: Text(
                  '... et ${widget.paiements.length - 10} autres paiements',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontStyle: FontStyle.italic,
                    color: AppTheme.getTextSecondary(context),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  /// Boutons d’action : retour, génération, aperçu complet.
  Widget _buildActionButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        ElevatedButton.icon(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          label: const Text('Retour', style: TextStyle(color: Colors.white)),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.grey[600],
            padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
        const SizedBox(width: 20),
        ElevatedButton.icon(
          onPressed: _generateAndDownload,
          icon: Icon(Icons.download, color: Colors.white),
          label: Text(
            'Générer et télécharger',
            style: const TextStyle(color: Colors.white),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: _getFormatColor(widget.format),
            padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
        const SizedBox(width: 20),
        ElevatedButton.icon(
          onPressed: _openPreviewInBrowser,
          icon: const Icon(Icons.visibility, color: Colors.white),
          label: const Text('Voir l\'aperçu complet', style: TextStyle(color: Colors.white)),
          style: ElevatedButton.styleFrom(
            backgroundColor: Theme.of(context).colorScheme.primary,
            padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
      ],
    );
  }

  /// Lance la génération et le téléchargement du fichier.
  Future<void> _generateAndDownload() async {
    if (!kIsWeb) {
      _showError('Export disponible uniquement sur web');
      return;
    }

    setState(() {
      _isGenerating = true;
      _error = null;
    });

    try {
      final provider = Provider.of<PaiementAdminProvider>(context, listen: false);

      switch (widget.format.toLowerCase()) {
        case 'pdf':
          await provider.exportPdfBackend(widget.filters ?? {});
          break;

        case 'csv':
          await provider.exportCsvLocal(widget.paiements);
          break;

        case 'excel':
        case 'word':
          _showError('Format ${widget.format} pas encore disponible.\nVeuillez utiliser PDF ou CSV pour le moment.');
          return;

        default:
          _showError('Format non supporté: ${widget.format}');
          return;
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ ${widget.format.toUpperCase()} généré avec succès'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
            behavior: SnackBarBehavior.floating,
          ),
        );

        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted) {
            Navigator.pop(context);
          }
        });
      }
    } catch (e) {
      print('❌ Erreur génération: $e');
      _showError('Erreur lors de la génération: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isGenerating = false;
        });
      }
    }
  }

  /// Affiche une boîte de dialogue de partage (fonctionnalité à venir).
  void _sharePreview() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

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
                'Partager le rapport',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.getTextPrimary(context),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Cette fonctionnalité est en cours de développement.',
                style: TextStyle(color: AppTheme.getTextSecondary(context)),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(
                      'OK',
                      style: TextStyle(color: AppTheme.getTextSecondary(context)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Ouvre un aperçu complet dans un nouvel onglet du navigateur.
  void _openPreviewInBrowser() {
    if (!kIsWeb) {
      print('⚠️ Prévisualisation non disponible sur mobile');
      return;
    }

    final htmlContent = _generateHtmlPreview();
    HtmlUtils.previewHtml(htmlContent);
  }

  /// Génère le code HTML de l’aperçu.
  String _generateHtmlPreview() {
    final buffer = StringBuffer();

    buffer.write('''
      <!DOCTYPE html>
      <html>
      <head>
        <meta charset="UTF-8">
        <title>Aperçu Rapport Paiements</title>
        <style>
          body {
            font-family: Arial, sans-serif;
            margin: 20px;
            background-color: #f5f5f5;
          }
          .container {
            background: white;
            padding: 30px;
            border-radius: 10px;
            max-width: 1200px;
            margin: 0 auto;
          }
          h1 {
            color: #333;
            border-bottom: 3px solid #1E3A8A;
            padding-bottom: 10px;
          }
          table {
            width: 100%;
            border-collapse: collapse;
            margin-top: 20px;
          }
          th, td {
            padding: 12px;
            text-align: left;
            border-bottom: 1px solid #ddd;
          }
          th {
            background-color: #1E3A8A;
            color: white;
          }
          tr:hover {
            background-color: #f5f5f5;
          }
          .stat {
            display: inline-block;
            padding: 15px;
            margin: 10px;
            background: #f0f9ff;
            border-radius: 8px;
            border-left: 4px solid #1E3A8A;
          }
          .confirme { color: green; }
          .en-attente { color: orange; }
          .echec { color: red; }
        </style>
      </head>
      <body>
        <div class="container">
          <h1>Rapport des Paiements CENOU</h1>
          <p>Généré le ${DateFormat('dd/MM/yyyy à HH:mm').format(DateTime.now())}</p>
          
          <div class="stats">
            <div class="stat">
              <strong>Total:</strong> ${widget.paiements.length} paiements
            </div>
            <div class="stat">
              <strong>Montant Total:</strong> ${NumberFormat('#,##0').format(widget.paiements.fold(0.0, (sum, p) => sum + p.montant))} FCFA
            </div>
          </div>
          
          <table>
            <thead>
              <tr>
                <th>Étudiant</th>
                <th>Montant</th>
                <th>Statut</th>
                <th>Mode</th>
                <th>Date</th>
              </tr>
            </thead>
            <tbody>
    ''');

    for (final paiement in widget.paiements) {
      buffer.write('''
         <tr>
           <td>${paiement.etudiantNomComplet}</td>
           <td>${NumberFormat('#,##0').format(paiement.montant)} FCFA</td>
          <td class="${paiement.statut.toLowerCase()}">${_getStatutLabel(paiement.statut)}</td>
           <td>${_getModeLabel(paiement.modePaiement)}</td>
           <td>${paiement.datePaiement != null ? DateFormat('dd/MM/yy HH:mm').format(paiement.datePaiement!) : ''}</td>
         </tr>
      ''');
    }

    buffer.write('''
            </tbody>
          </table>
        </div>
      </body>
      </html>
    ''');

    return buffer.toString();
  }

  /// Affiche un message d’erreur.
  void _showError(String message) {
    setState(() {
      _error = message;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('❌ $message'),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  /// Retourne l’icône associée au format d’export.
  IconData _getFormatIcon(String format) {
    switch (format.toLowerCase()) {
      case 'pdf': return Icons.picture_as_pdf;
      case 'excel': return Icons.table_chart;
      case 'word': return Icons.description;
      case 'csv': return Icons.grid_on;
      default: return Icons.insert_drive_file;
    }
  }

  /// Retourne la couleur associée au format d’export.
  Color _getFormatColor(String format) {
    switch (format.toLowerCase()) {
      case 'pdf': return Colors.red;
      case 'excel': return Colors.green;
      case 'word': return Colors.blue;
      case 'csv': return Colors.orange;
      default: return Theme.of(context).colorScheme.primary;
    }
  }

  /// Retourne la couleur associée au statut d’un paiement.
  Color _getStatusColor(String statut) {
    switch (statut) {
      case 'CONFIRME': return Colors.green;
      case 'EN_ATTENTE': return Colors.orange;
      case 'ECHEC': return Colors.red;
      default: return Colors.grey;
    }
  }

  /// Retourne le libellé lisible d’un statut.
  String _getStatutLabel(String statut) {
    switch (statut) {
      case 'EN_ATTENTE': return 'En attente';
      case 'CONFIRME': return 'Confirmé';
      case 'ECHEC': return 'Échec';
      default: return statut;
    }
  }

  /// Retourne le libellé lisible d’un mode de paiement.
  String _getModeLabel(String mode) {
    switch (mode) {
      case 'ORANGE_MONEY': return 'Orange Money';
      case 'MOOV_MONEY': return 'Moov Money';
      case 'ESPECES': return 'Espèces';
      case 'VIREMENT': return 'Virement';
      default: return mode;
    }
  }

  /// Formate les filtres pour l’affichage.
  String _formatFilters(Map<String, dynamic> filters) {
    final List<String> filtersText = [];

    if (filters['statut'] != null && filters['statut'] != 'TOUS') {
      filtersText.add('Statut: ${_getStatutLabel(filters['statut'])}');
    }

    if (filters['mode_paiement'] != null && filters['mode_paiement'] != 'TOUS') {
      filtersText.add('Mode: ${_getModeLabel(filters['mode_paiement'])}');
    }

    if (filters['date_from'] != null) {
      filtersText.add('À partir du: ${filters['date_from']}');
    }

    if (filters['date_to'] != null) {
      filtersText.add('Jusqu\'au: ${filters['date_to']}');
    }

    if (filters['search'] != null && filters['search'].toString().isNotEmpty) {
      filtersText.add('Recherche: "${filters['search']}"');
    }

    return filtersText.join(', ');
  }
}