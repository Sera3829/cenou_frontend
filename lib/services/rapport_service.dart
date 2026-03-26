// rapport_service.dart - VERSION WEB CORRIGÉE
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../config/app_config.dart';
import '../providers/auth_provider.dart';
import '../services/storage_service.dart';
import '../utils/html_utils.dart';

/// Service de génération et téléchargement des rapports.
class RapportService {
  static final String _baseUrl = AppConfig.apiBaseUrl;

  /// Récupère le jeton d'authentification depuis le stockage.
  static Future<String?> _getToken() async {
    try {
      final storageService = StorageService();
      return await storageService.getToken();
    } catch (e) {
      print('Erreur lors de la recuperation du token: $e');
      return null;
    }
  }

  /// Vérifie que l'utilisateur dispose des droits administrateur ou gestionnaire.
  static bool _checkPermissions(BuildContext context) {
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      return authProvider.isAdmin || authProvider.isGestionnaire;
    } catch (e) {
      print('Erreur lors de la verification des permissions: $e');
      return false;
    }
  }

  /// Déclenche le téléchargement d'un fichier dans un environnement web.
  ///
  /// [bytes] : contenu du fichier.
  /// [fileName] : nom du fichier.
  /// [format] : extension (pdf, excel, etc.).
  static void _downloadFileWeb(List<int> bytes, String fileName, String format) {
    // Déterminer le type MIME en fonction du format
    String mimeType;
    switch (format.toLowerCase()) {
      case 'pdf':
        mimeType = 'application/pdf';
        break;
      case 'excel':
      case 'xlsx':
        mimeType = 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet';
        break;
      case 'word':
      case 'docx':
        mimeType = 'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
        break;
      case 'csv':
        mimeType = 'text/csv';
        break;
      default:
        mimeType = 'application/octet-stream';
    }

    print('Telechargement: $fileName ($mimeType)');
    print('Taille: ${(bytes.length / 1024).toStringAsFixed(2)} KB');

    HtmlUtils.downloadFile(
      bytes: bytes,
      fileName: fileName,
      mimeType: mimeType,
    );
  }

  /// Génère un nom de fichier basé sur le type, le format et éventuellement la période.
  static String _generateFileName(String type, String format, {String? periode}) {
    final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
    final extension = format.toLowerCase() == 'excel' ? 'xlsx' : format.toLowerCase();

    String baseName = 'rapport_${type}_$timestamp';
    if (periode != null && periode.isNotEmpty) {
      baseName += '_$periode';
    }

    return '$baseName.$extension';
  }

  /// Génère et télécharge un rapport financier.
  ///
  /// [context] : contexte de l'interface.
  /// [format] : format souhaité (pdf, excel, csv).
  /// [periode] : période prédéfinie (mois, trimestre, etc.).
  /// [centreId] : identifiant du centre (optionnel).
  /// [dateDebut] : date de début de la plage.
  /// [dateFin] : date de fin de la plage.
  static Future<void> genererRapportFinancier({
    required BuildContext context,
    required String format,
    String? periode,
    int? centreId,
    DateTime? dateDebut,
    DateTime? dateFin,
  }) async {
    try {
      // Vérifier les permissions
      if (!_checkPermissions(context)) {
        throw Exception('Accès non autorisé.');
      }

      // Récupérer le token
      final token = await _getToken();
      if (token == null) throw Exception('Non authentifié');

      // Construire la requête
      final url = Uri.parse('$_baseUrl/api/rapports/financier');
      final body = <String, dynamic>{'format': format};

      if (periode != null) body['periode'] = periode;
      if (centreId != null) body['centre_id'] = centreId;
      if (dateDebut != null) {
        body['date_debut'] = DateFormat('yyyy-MM-dd').format(dateDebut);
      }
      if (dateFin != null) {
        body['date_fin'] = DateFormat('yyyy-MM-dd').format(dateFin);
      }

      print('Generation du rapport financier: $format');
      print('Payload: $body');

      // Envoyer la requête
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode(body),
      );

      print('Statut de la reponse: ${response.statusCode}');

      if (response.statusCode == 200) {
        // Générer un nom de fichier cohérent
        String fileName = _generateFileName('financier', format, periode: periode);

        // Extraire le nom depuis l'en-tête si fourni
        final contentDisposition = response.headers['content-disposition'];
        if (contentDisposition != null) {
          final match = RegExp(r'filename="?([^";\n]+)"?').firstMatch(contentDisposition);
          if (match != null && match.groupCount >= 1) {
            String? extractedName = match.group(1)?.trim();
            if (extractedName != null && extractedName.isNotEmpty) {
              fileName = extractedName;
            }
          }
        }

        print('Telechargement: $fileName');

        // Télécharger avec le bon type MIME
        _downloadFileWeb(response.bodyBytes, fileName, format);

        // Afficher un message de succès
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Rapport telecharge: $fileName'),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      } else {
        // Gérer l'erreur
        String errorMessage = 'Erreur ${response.statusCode}';
        try {
          final errorData = json.decode(response.body);
          errorMessage = errorData['error'] ?? errorData['message'] ?? errorMessage;
        } catch (_) {
          errorMessage = response.body;
        }

        throw Exception(errorMessage);
      }
    } catch (e) {
      print('Erreur lors de la generation du rapport financier: $e');

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }

      rethrow;
    }
  }

  /// Génère et télécharge un rapport d'occupation.
  ///
  /// [context] : contexte de l'interface.
  /// [format] : format souhaité (pdf, excel, csv).
  /// [centreId] : identifiant du centre (optionnel).
  static Future<void> genererRapportOccupation({
    required BuildContext context,
    required String format,
    int? centreId,
  }) async {
    try {
      // Vérifier les permissions
      if (!_checkPermissions(context)) {
        throw Exception('Accès non autorisé.');
      }

      final token = await _getToken();
      if (token == null) throw Exception('Non authentifié');

      final url = Uri.parse('$_baseUrl/api/rapports/occupation');
      final body = <String, dynamic>{'format': format};
      if (centreId != null) body['centre_id'] = centreId;

      print('Generation du rapport d\'occupation: $format');

      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode(body),
      );

      print('Statut de la reponse: ${response.statusCode}');

      if (response.statusCode == 200) {
        // Générer un nom de fichier cohérent
        String fileName = _generateFileName('occupation', format);

        final contentDisposition = response.headers['content-disposition'];
        if (contentDisposition != null) {
          final match = RegExp(r'filename="?([^";\n]+)"?').firstMatch(contentDisposition);
          if (match != null && match.groupCount >= 1) {
            String? extractedName = match.group(1)?.trim();
            if (extractedName != null && extractedName.isNotEmpty) {
              fileName = extractedName;
            }
          }
        }

        print('Telechargement: $fileName');

        // Télécharger avec le bon type MIME
        _downloadFileWeb(response.bodyBytes, fileName, format);

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Rapport telecharge: $fileName'),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      } else {
        String errorMessage = 'Erreur ${response.statusCode}';
        try {
          final errorData = json.decode(response.body);
          errorMessage = errorData['error'] ?? errorData['message'] ?? errorMessage;
        } catch (_) {
          errorMessage = response.body;
        }

        throw Exception(errorMessage);
      }
    } catch (e) {
      print('Erreur lors de la generation du rapport d\'occupation: $e');

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }

      rethrow;
    }
  }
}