import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:image/image.dart' as img;
import 'package:http_parser/http_parser.dart';
import '../models/signalement.dart';
import 'api_service.dart';
import '../config/app_config.dart';

/// Convertit un fichier image au format JPEG.
///
/// [file] : fichier source à convertir.
/// Retourne le fichier converti, ou le fichier original en cas d'échec.
Future<File> convertToJpeg(File file) async {
  final bytes = await file.readAsBytes();

  final image = img.decodeImage(bytes);
  if (image == null) return file;

  final jpgBytes = img.encodeJpg(image, quality: 85);

  final newPath = file.path.replaceAll(RegExp(r'\.\w+$'), '.jpg');
  final newFile = File(newPath);

  await newFile.writeAsBytes(jpgBytes);
  return newFile;
}

/// Service de gestion des signalements.
class SignalementService {
  final ApiService _apiService = ApiService();

  /// Récupère la liste de tous les signalements de l'utilisateur connecté.
  Future<List<Signalement>> getSignalements() async {
    try {
      final response = await _apiService.get('/api/signalements');
      final List<dynamic> data = response['signalements'] as List<dynamic>;
      return data.map((json) => Signalement.fromJson(json)).toList();
    } catch (e) {
      print('Erreur getSignalements: $e');
      rethrow;
    }
  }

  /// Récupère un signalement spécifique par son identifiant.
  Future<Signalement> getSignalementById(int id) async {
    try {
      final response = await _apiService.get('/api/signalements/$id');
      return Signalement.fromJson(response['signalement']);
    } catch (e) {
      print('Erreur getSignalementById: $e');
      rethrow;
    }
  }

  /// Crée un nouveau signalement avec photos.
  ///
  /// [typeProbleme] : type de problème (plomberie, électricité, etc.).
  /// [description] : description détaillée.
  /// [photos] : liste des fichiers photo.
  Future<Signalement> creerSignalement({
    required String typeProbleme,
    required String description,
    required List<File> photos,
  }) async {
    try {
      // Préparer les fichiers
      List<http.MultipartFile> files = [];
      for (var photo in photos) {
        final jpegFile = await convertToJpeg(photo);

        final file = await http.MultipartFile.fromPath(
          'photos',
          jpegFile.path,
          filename: jpegFile.path.split('/').last,
          contentType: MediaType('image', 'jpeg'),
        );

        files.add(file);
      }

      // Envoyer la requête
      final response = await _apiService.postMultipart(
        '/api/signalements',
        fields: {
          'type_probleme': typeProbleme,
          'description': description,
        },
        files: files,
      );

      return Signalement.fromJson(response['signalement']);
    } catch (e) {
      print('Erreur creerSignalement: $e');
      rethrow;
    }
  }

  /// Construit l'URL complète d'une photo associée à un signalement.
  ///
  /// [signalementId] : identifiant du signalement (non utilisé, conservé pour compatibilité).
  /// [photoIndex] : index de la photo dans la liste.
  /// [photos] : liste des chemins de photos.
  String getPhotoUrl(int signalementId, int photoIndex, List<String> photos) {
    try {
      if (photoIndex < 0 || photoIndex >= photos.length) {
        return '';
      }

      final path = photos[photoIndex];
      print('Photo path original: $path');

      // Méthode robuste pour extraire le nom de fichier
      String filename = '';

      // Si c'est un chemin Windows avec backslashes
      if (path.contains('\\')) {
        final parts = path.split('\\');
        filename = parts.last;
        print('Chemin Windows detecte');
      }
      // Si c'est un chemin Unix avec forward slashes
      else if (path.contains('/')) {
        final parts = path.split('/');
        filename = parts.last;
        print('Chemin Unix detecte');
      }
      // Si c'est juste un nom de fichier
      else {
        filename = path;
        print('Nom de fichier simple');
      }

      print('Nom de fichier extrait: $filename');

      // Construire l'URL correcte
      final fullUrl = '${AppConfig.staticBaseUrl}/uploads/signalements/$filename';

      print('URL complete: $fullUrl');

      return fullUrl;
    } catch (e) {
      print('Erreur dans getPhotoUrl: $e');
      return '';
    }
  }
}