// lib/utils/web_html_platform.dart
// Implémentation réelle pour la plateforme web

import 'dart:html' as html;

/// Télécharge un fichier sur le web.
///
/// [bytes] : contenu binaire du fichier.
/// [fileName] : nom du fichier à télécharger.
/// [mimeType] : type MIME du fichier.
void downloadFile({
  required List<int> bytes,
  required String fileName,
  required String mimeType,
}) {
  try {
    final blob = html.Blob([bytes], mimeType);
    final url = html.Url.createObjectUrlFromBlob(blob);

    final anchor = html.AnchorElement()
      ..href = url
      ..download = fileName
      ..style.display = 'none';

    html.document.body?.append(anchor);
    anchor.click();

    // Nettoyage
    Future.delayed(const Duration(milliseconds: 100), () {
      anchor.remove();
      html.Url.revokeObjectUrl(url);
    });

    print('Fichier telecharge: $fileName');
  } catch (e) {
    print('Erreur lors du telechargement: $e');
    rethrow;
  }
}

/// Ouvre une URL dans un nouvel onglet.
///
/// [url] : URL à ouvrir.
void openInNewTab(String url) {
  try {
    html.window.open(url, '_blank');
  } catch (e) {
    print('Erreur lors de l\'ouverture de l\'onglet: $e');
  }
}

/// Affiche du contenu HTML dans un nouvel onglet.
///
/// [htmlContent] : contenu HTML à prévisualiser.
void previewHtml(String htmlContent) {
  try {
    final blob = html.Blob([htmlContent], 'text/html');
    final url = html.Url.createObjectUrlFromBlob(blob);

    html.window.open(url, '_blank');

    // Nettoyage
    Future.delayed(const Duration(seconds: 1), () {
      html.Url.revokeObjectUrl(url);
    });
  } catch (e) {
    print('Erreur lors de la previsualisation: $e');
  }
}