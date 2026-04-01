import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../screens/web/auth/admin_login_screen.dart';

class AdminGuard extends StatelessWidget {
  final Widget child;
  const AdminGuard({Key? key, required this.child}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, auth, _) {
        // Pendant la vérification du token, afficher un spinner
        if (auth.isLoading) {
          return const Scaffold(
            backgroundColor: Color(0xFF1a237e),
            body: Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            ),
          );
        }

        // Vérifier l'authentification et le rôle
        if (auth.isAuthenticated && (auth.isAdmin || auth.isGestionnaire)) {
          return child;
        }

        // Sinon, rediriger vers l'écran de connexion
        return const AdminLoginScreen();
      },
    );
  }
}