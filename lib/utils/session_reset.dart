import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';
import '../providers/notification_provider.dart';
import '../providers/web/messagerie_provider.dart';

/// Vide l'état en mémoire des providers liés à l'utilisateur, pour éviter toute
/// fuite de données d'une session à l'autre (déconnexion → reconnexion).
///
/// À appeler juste avant `AuthProvider.logout()`. Chaque reset est protégé :
/// un provider non enregistré sur la plateforme courante (ex. MessagerieProvider,
/// web uniquement) est simplement ignoré.
void resetUserSession(BuildContext context) {
  void safe(void Function() fn) {
    try {
      fn();
    } catch (_) {
      // Provider absent sur cette plateforme : rien à réinitialiser.
    }
  }

  safe(() => context.read<NotificationProvider>().reset());
  safe(() => context.read<MessagerieProvider>().reset());
}
