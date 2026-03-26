// Service UNIQUEMENT pour le web - n'utilise PAS de packages mobiles
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import '../models/paiement.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../utils/html_utils.dart';

/// Service d'exportation pour le web, générant des rapports en HTML et
/// communiquant avec le backend pour les exports PDF/Excel/Word.
class WebExportService {
  static final DateFormat _dateFormat = DateFormat('dd/MM/yyyy HH:mm');
  static final DateFormat _fileDateFormat = DateFormat('yyyyMMdd_HHmmss');
  static final NumberFormat _currencyFormat = NumberFormat('#,##0', 'fr_FR');

  /// Génère un aperçu HTML des paiements pour visualisation avant export.
  ///
  /// [paiements] : liste des paiements à afficher.
  /// [format] : format d'export souhaité (pdf, excel, word).
  static String generatePreviewHtml(List<Paiement> paiements, String format) {
    final buffer = StringBuffer();

    buffer.writeln('''
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>Aperçu Rapport</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 30px; }
        .header { text-align: center; margin-bottom: 30px; border-bottom: 2px solid #3498db; padding-bottom: 20px; }
        .header h1 { color: #2c3e50; }
        .info { background: #f8f9fa; padding: 15px; border-radius: 5px; margin-bottom: 20px; }
        .stats-grid { display: grid; grid-template-columns: repeat(4, 1fr); gap: 15px; margin-bottom: 30px; }
        .stat-card { background: white; border: 1px solid #dee2e6; border-radius: 8px; padding: 20px; text-align: center; box-shadow: 0 2px 4px rgba(0,0,0,0.1); }
        .stat-value { font-size: 24px; font-weight: bold; color: #3498db; }
        .stat-label { color: #6c757d; font-size: 14px; margin-top: 5px; }
        table { width: 100%; border-collapse: collapse; margin-top: 20px; }
        th { background-color: #3498db; color: white; padding: 12px; text-align: left; }
        td { padding: 10px; border-bottom: 1px solid #dee2e6; }
        .footer { margin-top: 40px; text-align: center; color: #6c757d; font-size: 12px; }
        .actions { margin-top: 30px; text-align: center; }
        .btn { padding: 10px 20px; border: none; border-radius: 5px; cursor: pointer; font-size: 14px; margin: 0 10px; }
        .btn-primary { background: #3498db; color: white; }
        .btn-secondary { background: #6c757d; color: white; }
        .status-confirmed { background: #d4edda; color: #155724; padding: 4px 8px; border-radius: 4px; }
        .status-pending { background: #fff3cd; color: #856404; padding: 4px 8px; border-radius: 4px; }
        .status-failed { background: #f8d7da; color: #721c24; padding: 4px 8px; border-radius: 4px; }
    </style>
</head>
<body>
    <div class="header">
        <h1>Rapport des Paiements CENOU</h1>
        <p>Généré le ${DateFormat('dd/MM/yyyy à HH:mm').format(DateTime.now())}</p>
        <p>Format: ${format.toUpperCase()}</p>
    </div>

    <div class="info">
        <p><strong>Note:</strong> Ceci est un aperçu du rapport. Le fichier final sera généré par le serveur.</p>
    </div>
''');

    // Statistiques
    final total = paiements.length;
    final confirmes = paiements.where((p) => p.isConfirme).length;
    final enAttente = paiements.where((p) => p.statut == 'EN_ATTENTE').length;
    final montantTotal = paiements
        .where((p) => p.isConfirme)
        .fold(0.0, (sum, p) => sum + p.montant);

    buffer.writeln('''
    <div class="stats-grid">
        <div class="stat-card">
            <div class="stat-value">$total</div>
            <div class="stat-label">Total Paiements</div>
        </div>
        <div class="stat-card">
            <div class="stat-value">$confirmes</div>
            <div class="stat-label">Confirmés</div>
        </div>
        <div class="stat-card">
            <div class="stat-value">$enAttente</div>
            <div class="stat-label">En Attente</div>
        </div>
        <div class="stat-card">
            <div class="stat-value">${_currencyFormat.format(montantTotal)}</div>
            <div class="stat-label">Montant Total (FCFA)</div>
        </div>
    </div>

    <h2>Détails des Paiements</h2>
     <table>
        <thead>
             <tr>
                <th>Étudiant</th>
                <th>Matricule</th>
                <th>Montant</th>
                <th>Statut</th>
                <th>Mode</th>
                <th>Date</th>
             </tr>
        </thead>
        <tbody>
''');

    // Données (limitées pour l'aperçu)
    for (final paiement in paiements.take(20)) {
      final statusClass = _getStatusClass(paiement.statut);

      buffer.writeln('''
             <tr>
                 <td>${_escapeHtml(paiement.etudiantNomComplet)}</td>
                 <td>${_escapeHtml(paiement.matricule ?? '')}</td>
                 <td>${_currencyFormat.format(paiement.montant)} FCFA</td>
                 <td><span class="$statusClass">${_getStatutLabel(paiement.statut)}</span></td>
                 <td>${_getModeLabel(paiement.modePaiement)}</td>
                 <td>${paiement.datePaiement != null ? _dateFormat.format(paiement.datePaiement!) : ''}</td>
             </tr>
''');
    }

    if (paiements.length > 20) {
      buffer.writeln('''
             <tr>
                <td colspan="6" style="text-align: center; font-style: italic; padding: 20px;">
                    ... et ${paiements.length - 20} autres paiements
                 </td>
             </tr>
''');
    }

    buffer.writeln('''
        </tbody>
     </table>

    <div class="footer">
        <p>Document généré par le Dashboard CENOU Admin</p>
        <p>© ${DateTime.now().year} CENOU - Tous droits réservés</p>
    </div>

    <div class="actions">
        <button class="btn btn-primary" onclick="window.print()">Imprimer l'aperçu</button>
        <button class="btn btn-secondary" onclick="window.close()">Fermer</button>
    </div>
</body>
</html>
''');

    return buffer.toString();
  }

  /// Envoie une demande au backend pour générer le fichier d'export.
  ///
  /// [paiements] : liste des paiements à exporter.
  /// [format] : format d'export (pdf, excel, word).
  /// [apiEndpoint] : URL du point d'accès backend.
  /// [filters] : filtres appliqués (optionnels).
  static Future<void> exportViaBackend({
    required List<Paiement> paiements,
    required String format, // 'pdf', 'excel', 'word'
    required String apiEndpoint,
    Map<String, dynamic>? filters,
  }) async {
    try {
      print('Envoi demande au backend pour format: $format');

      // Préparer les données
      final payload = {
        'format': format,
        'data': paiements.map((p) => p.toJson()).toList(),
        'filters': filters ?? {},
        'options': {
          'title': 'Rapport des Paiements CENOU',
          'date_generation': DateTime.now().toIso8601String(),
          'total_paiements': paiements.length,
          'total_montant': paiements.fold(0.0, (sum, p) => sum + p.montant),
        },
      };

      // Envoyer la requête
      final response = await http.post(
        Uri.parse(apiEndpoint),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/octet-stream',
        },
        body: json.encode(payload),
      );

      if (response.statusCode == 200) {
        // Télécharger le fichier
        HtmlUtils.downloadFile(
          bytes: response.bodyBytes,
          fileName: 'paiements_cenou_${_fileDateFormat.format(DateTime.now())}.${_getFileExtension(format)}',
          mimeType: _getMimeType(format),
        );
        print('Fichier $format genere avec succes');
      } else {
        throw Exception('Erreur serveur: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('Erreur export backend: $e');
      rethrow;
    }
  }

  /// Télécharge un fichier directement depuis le client web.
  ///
  /// [bytes] : contenu binaire du fichier.
  /// [fileName] : nom du fichier à télécharger.
  /// [mimeType] : type MIME du fichier.
  static void downloadFile({
    required List<int> bytes,
    required String fileName,
    required String mimeType,
  }) {
    HtmlUtils.downloadFile(
      bytes: bytes,
      fileName: fileName,
      mimeType: mimeType,
    );
  }

  // ==================== UTILITAIRES ====================

  /// Retourne l'extension de fichier correspondant au format.
  static String _getFileExtension(String format) {
    switch (format.toLowerCase()) {
      case 'pdf': return 'pdf';
      case 'excel': return 'xlsx';
      case 'word': return 'docx';
      case 'csv': return 'csv';
      default: return format;
    }
  }

  /// Retourne le type MIME correspondant au format.
  static String _getMimeType(String format) {
    switch (format.toLowerCase()) {
      case 'pdf': return 'application/pdf';
      case 'excel': return 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet';
      case 'word': return 'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
      case 'csv': return 'text/csv';
      default: return 'application/octet-stream';
    }
  }

  /// Échappe les caractères spéciaux HTML.
  static String _escapeHtml(String text) {
    return text
        .replaceAll('&', '&amp;')
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;')
        .replaceAll('"', '&quot;')
        .replaceAll("'", '&#39;');
  }

  /// Retourne le libellé du statut.
  static String _getStatutLabel(String statut) {
    switch (statut) {
      case 'EN_ATTENTE': return 'En attente';
      case 'CONFIRME': return 'Confirmé';
      case 'ECHEC': return 'Échec';
      default: return statut;
    }
  }

  /// Retourne le libellé du mode de paiement.
  static String _getModeLabel(String mode) {
    switch (mode) {
      case 'ORANGE_MONEY': return 'Orange Money';
      case 'MOOV_MONEY': return 'Moov Money';
      case 'ESPECES': return 'Espèces';
      case 'VIREMENT': return 'Virement';
      default: return mode;
    }
  }

  /// Retourne la classe CSS pour le statut.
  static String _getStatusClass(String statut) {
    switch (statut) {
      case 'CONFIRME': return 'status-confirmed';
      case 'EN_ATTENTE': return 'status-pending';
      case 'ECHEC': return 'status-failed';
      default: return '';
    }
  }
}