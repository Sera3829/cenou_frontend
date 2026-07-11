# CENOU Frontend — Cenou Room

Application **Flutter** du système Cenou Room (CENOU — Burkina Faso) : une seule base de code pour deux interfaces.

| Interface | Cible | Utilisateurs |
|---|---|---|
| 📱 **App mobile** (Android/iOS) | Étudiants | Paiement des loyers, signalements avec photos, annonces, notifications |
| 🖥️ **Dashboard web** | Admins & gestionnaires | Statistiques, gestion des étudiants, paiements, signalements, rapports PDF/Excel |

- **Web (production)** : https://cenoufrontend.vercel.app — déploiement automatique à chaque push sur `main`
- **APK Android** : [Cenou.Room.apk (v1.0.0)](https://github.com/Sera3829/cenou_frontend/releases/download/v1.0.0/Cenou.Room.apk)
- **Backend associé** : [cenou_backend](https://github.com/Sera3829/cenou_backend) (https://cenou-backend.onrender.com)

## Démarrage rapide

Prérequis : [Flutter SDK](https://docs.flutter.dev/get-started/install) (canal **stable**).

```bash
git clone https://github.com/Sera3829/cenou_frontend.git
cd cenou_frontend
flutter pub get

# App mobile (émulateur ou appareil connecté)
flutter run

# Dashboard web
flutter run -d chrome
```

L'URL de l'API est définie dans [`lib/config/app_config.dart`](lib/config/app_config.dart) (`apiBaseUrl`). Par défaut : le backend de production sur Render.

## Builds

```bash
flutter build apk --release      # Android → build/app/outputs/flutter-apk/
flutter build web --release      # Web     → build/web/
```

## Déploiement web (Vercel)

Chaque push sur `main` déclenche automatiquement :

1. [`build.sh`](build.sh) — clone Flutter (branche **stable** épinglée) puis `flutter build web --release`
2. Publication de `build/web` (configuré dans [`vercel.json`](vercel.json), avec les rewrites SPA et les en-têtes COOP/COEP)

Le build complet prend ~3 minutes. En cas d'échec, Vercel conserve la version précédente en ligne (visible dans l'onglet *Deployments* du dashboard Vercel).

> La page d'accueil (`web/index.html`) est une landing personnalisée : elle oriente les admins/gestionnaires vers le dashboard et propose le téléchargement de l'APK aux étudiants.

## Structure du projet

```
lib/
├── config/          # AppConfig (URL API, timeouts), routes, thème
├── l10n/            # internationalisation (français / anglais)
├── models/          # modèles de données (+ models/admin/ pour le web)
├── providers/       # état global Provider (+ providers/web/ pour le dashboard)
├── screens/         # écrans mobile (auth, paiements, signalements, profil…)
│   └── web/         # écrans dashboard (statistiques, utilisateurs, rapports…)
├── services/        # ApiService (HTTP + JWT), storage sécurisé, notifications, exports
├── utils/           # helpers responsive, validation, plateforme
└── widgets/         # composants réutilisables (AdminGuard, boutons, champs…)
```

## Points d'architecture

- **Détection de plateforme** : sur le web, l'app charge le dashboard admin (protégé par `AdminGuard` + rôle vérifié côté serveur) ; sur mobile, le parcours étudiant.
- **Token JWT** stocké dans `flutter_secure_storage` (jamais en clair) ; déconnexion automatique sur 401.
- **Mode hors-ligne** : cache local (paiements, signalements, annonces) avec TTL d'une heure via `shared_preferences`.
- **Cloisonnement** : un gestionnaire ne voit que les données de son centre — appliqué par le backend, aucune configuration côté client.
- Les logs (`print`) ne sont émis qu'en mode debug (`kDebugMode`).

## Paiements (état actuel)

Le flux Orange Money / Moov Money est **simulé** en attendant l'intégration CinetPay : l'app initie le paiement (`/api/paiements/initier`) puis peut le confirmer via `/api/paiements/:id/simuler`. Le branchement CinetPay remplacera cette étape par la page de paiement réelle de l'opérateur.
