import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';
import '../models/paiement.dart';

class ReceiptPdfService {
  /// Génère le document PDF du reçu de paiement.
  ///
  /// [studentName]       : nom complet de l'étudiant (depuis AuthProvider)
  /// [studentMatricule]  : matricule (depuis AuthProvider)
  static Future<pw.Document> generateReceipt(
      Paiement paiement, {
        String studentName = '',
        String studentMatricule = '',
      }) async {
    final pdf = pw.Document();
    final dateFormat = DateFormat('dd/MM/yyyy à HH:mm', 'fr_FR');
    final currencyFormat = NumberFormat('#,###', 'fr_FR');

    final font     = await PdfGoogleFonts.robotoRegular();
    final fontBold = await PdfGoogleFonts.robotoBold();

    // Résoudre le nom : priorité AuthProvider, fallback champs modèle
    final displayName = studentName.isNotEmpty
        ? studentName
        : [paiement.prenom, paiement.nom]
        .where((s) => s != null && s.isNotEmpty)
        .join(' ');

    final displayMatricule = studentMatricule.isNotEmpty
        ? studentMatricule
        : (paiement.matricule ?? '');

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Padding(
            padding: const pw.EdgeInsets.all(32),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                // ── En-tête ────────────────────────────────────────────
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text('CENOU',
                            style: pw.TextStyle(
                                font: fontBold,
                                fontSize: 24,
                                color: PdfColors.blue900)),
                        pw.SizedBox(height: 4),
                        pw.Text('Reçu de paiement',
                            style: pw.TextStyle(
                                font: font,
                                fontSize: 14,
                                color: PdfColors.grey700)),
                      ],
                    ),
                    pw.Container(
                      padding: const pw.EdgeInsets.all(12),
                      decoration: pw.BoxDecoration(
                        border: pw.Border.all(color: PdfColors.grey300),
                        borderRadius: pw.BorderRadius.circular(8),
                      ),
                      child: pw.Text(
                        paiement.statut,
                        style: pw.TextStyle(
                          font: fontBold,
                          fontSize: 14,
                          color: paiement.isConfirme
                              ? PdfColors.green700
                              : (paiement.isEchec
                              ? PdfColors.red700
                              : PdfColors.orange700),
                        ),
                      ),
                    ),
                  ],
                ),
                pw.SizedBox(height: 24),

                // ── Détails de la transaction ──────────────────────────
                _buildSectionHeader('Détails de la transaction', fontBold),
                pw.SizedBox(height: 12),
                _buildInfoRow('Référence',
                    paiement.referenceTransaction ?? 'N/A', font, fontBold),
                _buildInfoRow(
                  'Date de paiement',
                  paiement.datePaiement != null
                      ? dateFormat.format(paiement.datePaiement!)
                      : '—',
                  font,
                  fontBold,
                ),
                _buildInfoRow(
                  'Mode de paiement',
                  paiement.modePaiement.replaceAll('_', ' '),
                  font,
                  fontBold,
                ),
                pw.SizedBox(height: 16),

                // ── Montant ────────────────────────────────────────────
                _buildSectionHeader('Montant', fontBold),
                pw.SizedBox(height: 12),
                pw.Container(
                  padding: const pw.EdgeInsets.all(16),
                  decoration: pw.BoxDecoration(
                    color: PdfColors.grey100,
                    borderRadius: pw.BorderRadius.circular(8),
                  ),
                  child: pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text('Total payé',
                          style: pw.TextStyle(font: font, fontSize: 14)),
                      pw.Text(
                        '${currencyFormat.format(paiement.montant)} FCFA',
                        style: pw.TextStyle(
                            font: fontBold,
                            fontSize: 18,
                            color: PdfColors.blue900),
                      ),
                    ],
                  ),
                ),
                pw.SizedBox(height: 16),

                // ── Informations locataire ─────────────────────────────
                _buildSectionHeader('Informations locataire', fontBold),
                pw.SizedBox(height: 12),

                // Nom — priorité au nom résolu
                if (displayName.isNotEmpty)
                  _buildInfoRow('Locataire', displayName, font, fontBold),
                if (displayMatricule.isNotEmpty)
                  _buildInfoRow('Matricule', displayMatricule, font, fontBold),
                if (paiement.nomCentre != null && paiement.nomCentre!.isNotEmpty)
                  _buildInfoRow('Centre', paiement.nomCentre!, font, fontBold),
                if (paiement.numeroChambre != null &&
                    paiement.numeroChambre!.isNotEmpty)
                  _buildInfoRow('Chambre',
                      'Ch. ${paiement.numeroChambre!}', font, fontBold),
                if (paiement.dateEcheance != null)
                  _buildInfoRow(
                    'Échéance',
                    DateFormat('dd/MM/yyyy').format(paiement.dateEcheance!),
                    font,
                    fontBold,
                  ),

                pw.SizedBox(height: 32),

                // ── Pied de page ───────────────────────────────────────
                pw.Divider(),
                pw.SizedBox(height: 8),
                pw.Center(
                  child: pw.Text(
                    'Ce reçu est généré automatiquement et fait office de preuve de paiement.',
                    style: pw.TextStyle(
                        font: font, fontSize: 10, color: PdfColors.grey600),
                    textAlign: pw.TextAlign.center,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
    return pdf;
  }

  static pw.Widget _buildSectionHeader(String title, pw.Font fontBold) {
    return pw.Text(title,
        style: pw.TextStyle(
            font: fontBold, fontSize: 16, color: PdfColors.blue900));
  }

  static pw.Widget _buildInfoRow(
      String label, String value, pw.Font font, pw.Font fontBold) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 4),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.SizedBox(
            width: 140,
            child: pw.Text('$label :',
                style: pw.TextStyle(
                    font: font, fontSize: 12, color: PdfColors.grey700)),
          ),
          pw.Expanded(
            child: pw.Text(value,
                style: pw.TextStyle(
                    font: fontBold, fontSize: 12, color: PdfColors.black)),
          ),
        ],
      ),
    );
  }

  /// Sauvegarde le PDF dans le dossier temporaire et retourne le fichier.
  static Future<File> savePdfToTemp(pw.Document pdf, String fileName) async {
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/$fileName');
    await file.writeAsBytes(await pdf.save());
    return file;
  }

  /// Sauvegarde le PDF dans le dossier Downloads (Android) ou Documents (iOS).
  /// Retourne le chemin du fichier sauvegardé.
  static Future<String> savePdfToDownloads(
      pw.Document pdf, String fileName) async {
    final bytes = await pdf.save();

    if (Platform.isAndroid) {
      // path_provider >= 2.0.6 : getDownloadsDirectory() disponible
      Directory? dir;
      try {
        dir = await getDownloadsDirectory();
      } catch (_) {
        dir = null;
      }
      // Fallback : dossier externe de l'app (visible dans Fichiers)
      dir ??= await getExternalStorageDirectory();
      // Dernier fallback : documents internes
      dir ??= await getApplicationDocumentsDirectory();

      final file = File('${dir!.path}/$fileName');
      await file.writeAsBytes(bytes);
      return file.path;
    } else {
      // iOS : dossier Documents (accessible via l'app Fichiers)
      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/$fileName');
      await file.writeAsBytes(bytes);
      return file.path;
    }
  }

  /// Ouvre le PDF avec le viewer système (impression/aperçu).
  static Future<void> openPdfFile(File file) async {
    await Printing.layoutPdf(
      onLayout: (_) async => file.readAsBytesSync(),
    );
  }
}