import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';
import '../providers/notification_provider.dart';
import '../providers/paiement_provider.dart';
import '../providers/signalement_provider.dart';
import '../providers/web/messagerie_provider.dart';
import '../providers/web/paiement_admin_provider.dart';
import '../providers/web/signalement_admin_provider.dart';
import '../providers/web/user_admin_provider.dart';
import '../providers/web/centre_admin_provider.dart';
import '../providers/web/annonce_admin_provider.dart';
import '../providers/web/rapport_provider.dart';

/// Vide l'état en mémoire de TOUS les providers liés à l'utilisateur, pour
/// éviter toute fuite de données d'une session à l'autre (déconnexion →
/// reconnexion, ou session expirée sans déconnexion explicite).
///
/// À appeler à la déconnexion et à la connexion réussie. Chaque reset est
/// protégé : un provider non enregistré sur la plateforme courante (les
/// providers web n'existent pas sur mobile, et inversement) est simplement
/// ignoré.
void resetUserSession(BuildContext context) {
  void safe(void Function() fn) {
    try {
      fn();
    } catch (_) {
      // Provider absent sur cette plateforme : rien à réinitialiser.
    }
  }

  // Commun / mobile
  safe(() => context.read<NotificationProvider>().reset());
  safe(() => context.read<PaiementProvider>().reset());
  safe(() => context.read<SignalementProvider>().reset());

  // Espace admin (web)
  safe(() => context.read<MessagerieProvider>().reset());
  safe(() => context.read<PaiementAdminProvider>().reset());
  safe(() => context.read<SignalementAdminProvider>().reset());
  safe(() => context.read<UserAdminProvider>().reset());
  safe(() => context.read<CentreAdminProvider>().reset());
  safe(() => context.read<AnnonceAdminProvider>().reset());
  safe(() => context.read<RapportProvider>().reset());
}
