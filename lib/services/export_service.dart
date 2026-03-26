// lib/services/export_service.dart
import 'dart:convert';
import 'dart:io';
import 'package:csv/csv.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../models/paiement.dart';

/// Service d'exportation des données de paiement aux formats PDF, CSV et Excel.
class ExportService {
  static final DateFormat _dateFormat = DateFormat('dd/MM/yyyy HH:mm');
  static final DateFormat _fileDateFormat = DateFormat('yyyyMMdd_HHmmss');
  static final NumberFormat _currencyFormat = NumberFormat('#,##0', 'fr_FR');

  /// Exporte la liste des paiements au format PDF.
  ///
  /// Le document inclut un en-tête, les métadonnées, les statistiques,
  /// un tableau des paiements et un pied de page.
  ///
  /// [titre] : titre personnalisé du rapport.
  /// [filtres] : dictionnaire des filtres appliqués pour affichage.
  static Future<File> exportToPdf(List<Paiement> paiements, {
    String? titre,
    Map<String, dynamic>? filtres,
  }) async {
    final pdf = pw.Document();

    // Construction du document PDF
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(20),
        build: (pw.Context context) => [
          // Titre principal
          pw.Header(
            level: 0,
            child: pw.Text(
              titre ?? 'Rapport des Paiements CENOU',
              style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold),
            ),
          ),

          // Métadonnées de génération
          pw.Paragraph(
            text: 'Généré le: ${DateFormat('dd/MM/yyyy à HH:mm').format(DateTime.now())}',
          ),

          // Affichage des filtres s'ils existent
          if (filtres != null && filtres.isNotEmpty) ...[
            pw.SizedBox(height: 10),
            pw.Text('Filtres appliqués:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
            pw.Text(_formatFilters(filtres)),
          ],

          pw.SizedBox(height: 20),

          // Section des statistiques
          _buildStatsSection(paiements),

          pw.SizedBox(height: 20),

          // Tableau des paiements
          _buildPaiementsTable(paiements),

          pw.SizedBox(height: 30),

          // Pied de page
          pw.Footer(
            title: pw.Column(
              children: [
                pw.Divider(),
                pw.Text(
                  'Document généré par le Dashboard CENOU Admin',
                  style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey),
                ),
              ],
            ),
          ),
        ],
      ),
    );

    // Sauvegarde du fichier dans le répertoire des documents
    final directory = await getApplicationDocumentsDirectory();
    final fileName = 'paiements_cenou_${_fileDateFormat.format(DateTime.now())}.pdf';
    final file = File('${directory.path}/$fileName');

    await file.writeAsBytes(await pdf.save());
    return file;
  }

  /// Exporte la liste des paiements au format CSV.
  static Future<File> exportToCsv(List<Paiement> paiements) async {
    // Définition des en-têtes du fichier CSV
    final List<List<dynamic>> rows = [
      [
        'ID',
        'Étudiant',
        'Matricule',
        'Montant (FCFA)',
        'Statut',
        'Mode de Paiement',
        'Date Paiement',
        'Date Échéance',
        'Référence',
        'Centre',
        'Chambre',
      ],
    ];

    // Remplissage des lignes de données
    for (final paiement in paiements) {
      rows.add([
        paiement.id,
        '${paiement.nom ?? ""} ${paiement.prenom ?? ""}'.trim(),
        paiement.matricule ?? '',
        paiement.montant,
        _getStatutLabel(paiement.statut),
        _getModeLabel(paiement.modePaiement),
        paiement.datePaiement != null ? _dateFormat.format(paiement.datePaiement!) : '',
        paiement.dateEcheance != null ? DateFormat('dd/MM/yyyy').format(paiement.dateEcheance!) : '',
        paiement.referenceTransaction ?? '',
        paiement.centreNom ?? '',
        paiement.numeroChambre ?? '',
      ]);
    }

    // Conversion en chaîne CSV
    final csvData = const ListToCsvConverter().convert(rows);

    // Écriture du fichier
    final directory = await getApplicationDocumentsDirectory();
    final fileName = 'paiements_cenou_${_fileDateFormat.format(DateTime.now())}.csv';
    final file = File('${directory.path}/$fileName');

    await file.writeAsString(csvData, encoding: utf8);
    return file;
  }

  /// Exporte la liste des paiements au format Excel (fichier .xlsx).
  ///
  /// Cette méthode génère un fichier CSV puis le renomme en .xlsx.
  static Future<File> exportToExcel(List<Paiement> paiements) async {
    final csvFile = await exportToCsv(paiements);

    // Renommage du fichier CSV en .xlsx
    final excelFile = File('${csvFile.path.replaceAll('.csv', '.xlsx')}');
    await excelFile.writeAsBytes(await csvFile.readAsBytes());

    // Suppression du fichier CSV temporaire
    await csvFile.delete();

    return excelFile;
  }

  // ==================== WIDGETS PDF ====================

  /// Construit la section des statistiques (total, confirmés, en attente, montant total).
  static pw.Widget _buildStatsSection(List<Paiement> paiements) {
    final total = paiements.length;
    final confirmes = paiements.where((p) => p.isConfirme).length;
    final enAttente = paiements.where((p) => p.statut == 'EN_ATTENTE').length;
    final montantTotal = paiements
        .where((p) => p.isConfirme)
        .fold(0.0, (sum, p) => sum + p.montant);

    return pw.Container(
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey300),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
      ),
      padding: const pw.EdgeInsets.all(12),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
        children: [
          _buildStatCard('Total Paiements', '$total'),
          _buildStatCard('Confirmés', '$confirmes'),
          _buildStatCard('En Attente', '$enAttente'),
          _buildStatCard('Montant Total', '${_currencyFormat.format(montantTotal)} FCFA'),
        ],
      ),
    );
  }

  /// Génère une carte de statistique individuelle.
  static pw.Widget _buildStatCard(String label, String value) {
    return pw.Column(
      children: [
        pw.Text(
          value,
          style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
        ),
        pw.SizedBox(height: 4),
        pw.Text(
          label,
          style: pw.TextStyle(fontSize: 10, color: PdfColors.grey600),
        ),
      ],
    );
  }

  /// Construit le tableau des paiements dans le PDF.
  static pw.Widget _buildPaiementsTable(List<Paiement> paiements) {
    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey300),
      columnWidths: {
        0: const pw.FlexColumnWidth(1),
        1: const pw.FlexColumnWidth(2),
        2: const pw.FlexColumnWidth(1),
        3: const pw.FlexColumnWidth(1.5),
        4: const pw.FlexColumnWidth(1.5),
      },
      children: [
        // Ligne d'en-tête
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: PdfColors.grey100),
          children: [
            _buildTableCell('Étudiant', isHeader: true),
            _buildTableCell('Montant', isHeader: true),
            _buildTableCell('Statut', isHeader: true),
            _buildTableCell('Mode', isHeader: true),
            _buildTableCell('Date', isHeader: true),
          ],
        ),

        // Lignes de données
        ...paiements.map((paiement) => pw.TableRow(
          children: [
            _buildTableCell('${paiement.prenom ?? ""} ${paiement.nom ?? ""}'.trim()),
            _buildTableCell('${_currencyFormat.format(paiement.montant)} FCFA'),
            _buildTableCell(_getStatutLabel(paiement.statut)),
            _buildTableCell(_getModeLabel(paiement.modePaiement)),
            _buildTableCell(paiement.datePaiement != null
                ? _dateFormat.format(paiement.datePaiement!)
                : ''),
          ],
        )).toList(),
      ],
    );
  }

  /// Génère une cellule de tableau pour le PDF.
  static pw.Widget _buildTableCell(String text, {bool isHeader = false}) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(8),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontWeight: isHeader ? pw.FontWeight.bold : pw.FontWeight.normal,
          fontSize: isHeader ? 11 : 10,
        ),
      ),
    );
  }

  // ==================== UTILITAIRES ====================

  /// Formate les filtres pour les afficher dans le rapport.
  static String _formatFilters(Map<String, dynamic> filtres) {
    final List<String> filtersText = [];

    if (filtres['statut'] != null && filtres['statut'] != 'TOUS') {
      filtersText.add('Statut: ${_getStatutLabel(filtres['statut'])}');
    }

    if (filtres['mode_paiement'] != null && filtres['mode_paiement'] != 'TOUS') {
      filtersText.add('Mode: ${_getModeLabel(filtres['mode_paiement'])}');
    }

    if (filtres['date_from'] != null) {
      filtersText.add('À partir du: ${filtres['date_from']}');
    }

    if (filtres['date_to'] != null) {
      filtersText.add('Jusqu\'au: ${filtres['date_to']}');
    }

    if (filtres['search'] != null && filtres['search'].toString().isNotEmpty) {
      filtersText.add('Recherche: "${filtres['search']}"');
    }

    return filtersText.join(', ');
  }

  /// Convertit un code de statut en libellé lisible.
  static String _getStatutLabel(String statut) {
    switch (statut) {
      case 'EN_ATTENTE': return 'En attente';
      case 'CONFIRME': return 'Confirmé';
      case 'ECHEC': return 'Échec';
      default: return statut;
    }
  }

  /// Convertit un code de mode de paiement en libellé lisible.
  static String _getModeLabel(String mode) {
    switch (mode) {
      case 'ORANGE_MONEY': return 'Orange Money';
      case 'MOOV_MONEY': return 'Moov Money';
      case 'ESPECES': return 'Espèces';
      case 'VIREMENT': return 'Virement';
      default: return mode;
    }
  }
}