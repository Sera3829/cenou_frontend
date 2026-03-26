// lib/utils/html_utils.dart
// Classe utilitaire pour les opérations HTML (web uniquement)

import 'package:flutter/foundation.dart' show kIsWeb;

// Import conditionnel des implémentations
import 'web_html_platform.dart' if (dart.library.io) 'stub_html_platform.dart' as platform;

/// Classe utilitaire pour les opérations spécifiques au web.
///
/// Fournit des méthodes de téléchargement de fichiers, d'ouverture d'URL
/// et de prévisualisation HTML. Les appels sur des plateformes non-web
/// affichent un message d'avertissement dans la console.
class HtmlUtils {
  /// Télécharge un fichier depuis l'application web.
  ///
  /// [bytes] : contenu binaire du fichier.
  /// [fileName] : nom du fichier à télécharger.
  /// [mimeType] : type MIME du fichier (ex: 'application/pdf').
  static void downloadFile({
    required List<int> bytes,
    required String fileName,
    required String mimeType,
  }) {
    if (!kIsWeb) {
      print('Telechargement disponible uniquement sur web');
      return;
    }

    platform.downloadFile(bytes: bytes, fileName: fileName, mimeType: mimeType);
  }

  /// Ouvre une URL dans un nouvel onglet du navigateur.
  ///
  /// [url] : URL à ouvrir.
  static void openInNewTab(String url) {
    if (!kIsWeb) {
      print('Ouverture d\'onglet disponible uniquement sur web');
      return;
    }

    platform.openInNewTab(url);
  }

  /// Affiche le contenu HTML dans un nouvel onglet.
  ///
  /// [htmlContent] : code HTML à prévisualiser.
  static void previewHtml(String htmlContent) {
    if (!kIsWeb) {
      print('Previsualisation HTML disponible uniquement sur web');
      return;
    }

    platform.previewHtml(htmlContent);
  }
}