// lib/utils/stub_html_platform.dart
// Stub vide pour les plateformes non-web (mobile, desktop)

/// Télécharger un fichier (stub pour mobile)
void downloadFile({
  required List<int> bytes,
  required String fileName,
  required String mimeType,
}) {
  print('⚠️ Téléchargement non disponible sur mobile');
}

/// Ouvrir URL dans nouvel onglet (stub pour mobile)
void openInNewTab(String url) {
  print('⚠️ Ouverture d\'onglet non disponible sur mobile');
}

/// Prévisualiser HTML (stub pour mobile)
void previewHtml(String htmlContent) {
  print('⚠️ Prévisualisation HTML non disponible sur mobile');
}