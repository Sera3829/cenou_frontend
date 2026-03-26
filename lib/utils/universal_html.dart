// lib/utils/universal_html.dart
// Import conditionnel qui choisit automatiquement entre web et stub

export 'html_web.dart' if (dart.library.io) 'html_stub.dart';