// lib/utils/html_stub.dart
// Stub pour les plateformes non-web (Android, iOS, etc.)

/// Classe stub pour Blob
class Blob {
  Blob(List<dynamic> blobParts, [String? type]);
}

/// Classe stub pour AnchorElement
class AnchorElement {
  String? href;
  String? download;
  CSSStyleDeclaration style = CSSStyleDeclaration();

  void click() {}
  void remove() {}
  void setAttribute(String name, String value) {}
}

/// Classe stub pour CSSStyleDeclaration
class CSSStyleDeclaration {
  String? display;
}

/// Classe stub pour Url
class Url {
  static String createObjectUrlFromBlob(Blob blob) => '';
  static void revokeObjectUrl(String url) {}
}

/// Classe stub pour Window
class Window {
  void open(String url, String target) {
    print('window.open non disponible sur mobile');
  }
}

/// Classe stub pour Body
class Body {
  void append(dynamic element) {}
}

/// Classe stub pour Document
class Document {
  Body? get body => Body();
}

/// Instances globales
final Window window = Window();
final Document document = Document();