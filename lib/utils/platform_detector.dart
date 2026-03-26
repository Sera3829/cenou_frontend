import 'package:universal_platform/universal_platform.dart';

class PlatformDetector {
  static bool get isMobile => UniversalPlatform.isAndroid || UniversalPlatform.isIOS;
  static bool get isWeb => UniversalPlatform.isWeb;
  static bool get isDesktop => UniversalPlatform.isWindows || UniversalPlatform.isMacOS || UniversalPlatform.isLinux;

  static bool get isAdminDashboard => isWeb || isDesktop;

  static String get platformName {
    if (isWeb) return 'Web';
    if (UniversalPlatform.isAndroid) return 'Android';
    if (UniversalPlatform.isIOS) return 'iOS';
    if (UniversalPlatform.isWindows) return 'Windows';
    if (UniversalPlatform.isMacOS) return 'macOS';
    if (UniversalPlatform.isLinux) return 'Linux';
    return 'Unknown';
  }

  static bool get isTablet {
    if (!isMobile) return false;
    /// Logique pour détecter tablette
    return false;
  }
}