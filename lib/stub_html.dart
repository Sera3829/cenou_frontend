// stub_html.dart - Version corrigée

// Import conditionnel pour le web
export 'dart:html' if (dart.library.io) 'stub_html.dart';

// Stub pour les plateformes non-web
class HtmlStub {
  // Pour le Blob
  dynamic Blob(List data, [String? mimeType]) => _BlobStub();

  // Pour window
  dynamic get window => _WindowStub();

  // Pour Url (qui dans dart:html est window.Url)
  dynamic get Url => _UrlStub();

  // Pour document
  dynamic get document => _DocumentStub();
}

class _BlobStub {
  const _BlobStub();
}

class _UrlStub {
  String createObjectUrlFromBlob(dynamic blob) => '';
  void revokeObjectUrl(String url) {}
}

class _WindowStub {
  dynamic get Url => _UrlStub();
  void open(String url, String target) {
    print('Stub: window.open($url, $target)');
  }
}

class _DocumentStub {
  dynamic get body => _BodyStub();
}

class _BodyStub {
  void append(dynamic element) {}
  void removeChild(dynamic element) {}
}

// Variable globale pour l'instance
final html = HtmlStub();