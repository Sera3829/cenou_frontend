import 'package:flutter/foundation.dart' show kIsWeb;

/// Note : L'ordre des imports doit être maintenu pour garantir la résolution des dépendances.
import 'package:cenou_mobile/providers/web/paiement_admin_provider.dart';
import 'package:cenou_mobile/providers/web/signalement_admin_provider.dart';
import 'package:cenou_mobile/providers/web/UserAdminProvider.dart';
import 'package:cenou_mobile/screens/web/auth/admin_login_screen.dart';
import 'package:cenou_mobile/screens/web/dashboard/dashboard_screen.dart';
import 'package:cenou_mobile/screens/web/paiements/paiement_admin_screen.dart';
import 'package:cenou_mobile/screens/web/signalements/SignalementAdminScreen.dart';
import 'package:cenou_mobile/screens/web/utilisateurs/User_Admin_Screen.dart';
import 'package:cenou_mobile/screens/web/paiements/export_preview_screen.dart';

/// Factory dédiée à l'instanciation des providers pour la plateforme Web.
class WebProviders {
  /// Initialise le provider de gestion des paiements si l'exécution est sur le Web.
  static dynamic createPaiementAdminProvider() {
    if (kIsWeb) {
      return _createWebProvider('paiement_admin');
    }
    return null;
  }

  /// Initialise le provider de gestion des signalements si l'exécution est sur le Web.
  static dynamic createSignalementAdminProvider() {
    if (kIsWeb) {
      return _createWebProvider('signalement_admin');
    }
    return null;
  }

  /// Initialise le provider de gestion des utilisateurs si l'exécution est sur le Web.
  static dynamic createUserAdminProvider() {
    if (kIsWeb) {
      return _createWebProvider('user_admin');
    }
    return null;
  }

  /// Méthode interne pour l'instanciation dynamique des services Web.
  /// L'appel à cette fonction est restreint à l'environnement Web.
  static dynamic _createWebProvider(String type) {
    switch (type) {
      case 'paiement_admin':
        return PaiementAdminProvider();
      case 'signalement_admin':
        return SignalementAdminProvider();
      case 'user_admin':
        return UserAdminProvider();
      default:
        return null;
    }
  }
}

/// Factory dédiée au routage et à la distribution des écrans Web.
class WebScreens {
  /// Retourne le widget correspondant à la route spécifiée, avec injection optionnelle d'arguments.
  /// Cette méthode retourne [null] si la plateforme d'exécution n'est pas le Web.
  static dynamic getScreen(String route, {Map<String, dynamic>? arguments}) {
    if (!kIsWeb) return null;

    switch (route) {
      case '/admin/login':
        return const AdminLoginScreen();
      case '/admin/dashboard':
        return const DashboardScreen();
      case '/admin/paiement-admin':
        return const PaiementAdminScreen();
      case '/admin/signalements':
        return const SignalementAdminScreen();
      case '/admin/utilisateurs':
        return const UserAdminScreen();
      case '/admin/export-preview':
        if (arguments != null) {
          return ExportPreviewScreen(
            format: arguments['format'],
            paiements: arguments['paiements'],
            filters: arguments['filters'],
          );
        }
        return null;
      default:
        return null;
    }
  }
}