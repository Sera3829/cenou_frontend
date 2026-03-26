import 'package:flutter/material.dart';
import '../screens/auth/login_screen.dart';
import '../screens/home/home_screen.dart';
import '../screens/web/auth/admin_login_screen.dart';
import '../screens/web/dashboard/dashboard_screen.dart';
import '../screens/web/signalements/SignalementAdminScreen.dart';
import '../utils/platform_detector.dart';

class AppRoutes {
  static Route<dynamic> generateRoute(RouteSettings settings) {
    // Détecter si on est sur web/mobile
    final bool isWeb = PlatformDetector.isWeb;

    switch (settings.name) {
    // Routes principales (détection automatique)
      case '/':
        return MaterialPageRoute(
          builder: (_) => isWeb
              ? const AdminLoginScreen()  // Web: login admin
              : const LoginScreen(),      // Mobile: login normal
        );

    // Routes admin (web seulement)
      case '/admin/login':
        return MaterialPageRoute(builder: (_) => const AdminLoginScreen());

      case '/admin/dashboard':
        return MaterialPageRoute(builder: (_) => const DashboardScreen());

      case '/admin/signalements':
        return MaterialPageRoute(builder: (_) => const SignalementAdminScreen());


    // Routes mobile
      case '/mobile/home':
        return MaterialPageRoute(builder: (_) => const HomeScreen());

    // 404
      default:
        return MaterialPageRoute(
          builder: (_) => Scaffold(
            body: Center(
              child: Text('Page non trouvée: ${settings.name}'),
            ),
          ),
        );
    }
  }
}