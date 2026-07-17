/// Informations de version de l'application.
///
/// Les valeurs sont injectées au moment du build via --dart-define
/// (voir build.sh pour le web et .github/workflows/release-apk.yml pour
/// l'APK). Comme chaque push déclenche un build, la date de mise à jour
/// reflète toujours le dernier déploiement — plus rien n'est codé en dur.
///
/// En build local (sans --dart-define), on retombe sur des valeurs neutres.
class AppVersion {
  /// Version sémantique, ex. "1.1.0". Injectée à partir de pubspec au build.
  static const String version =
      String.fromEnvironment('APP_VERSION', defaultValue: '1.0.0');

  /// Date du build au format ISO (YYYY-MM-DD), injectée au moment du build.
  static const String _buildDateRaw =
      String.fromEnvironment('BUILD_DATE', defaultValue: '');

  /// Hash court du commit déployé, injecté au moment du build.
  static const String commit =
      String.fromEnvironment('GIT_SHA', defaultValue: '');

  /// Y a-t-il une date de build injectée ?
  static bool get hasBuildDate => _buildDateRaw.isNotEmpty;

  /// Date de dernière mise à jour formatée JJ/MM/AAAA, ou null si build local.
  static String? get lastUpdate {
    if (_buildDateRaw.isEmpty) return null;
    try {
      final d = DateTime.parse(_buildDateRaw);
      final jj = d.day.toString().padLeft(2, '0');
      final mm = d.month.toString().padLeft(2, '0');
      return '$jj/$mm/${d.year}';
    } catch (_) {
      return _buildDateRaw;
    }
  }
}
