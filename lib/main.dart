import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:universal_platform/universal_platform.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'l10n/app_localizations.dart';
import 'services/api_service.dart';
import 'widgets/admin_guard.dart';
import 'package:local_auth/local_auth.dart';
import 'screens/auth/biometric_lock_screen.dart';

// Import communs
import 'config/theme.dart';
import 'providers/auth_provider.dart';
import 'providers/signalement_provider.dart';
import 'providers/paiement_provider.dart';
import 'providers/web/annonce_admin_provider.dart';
import 'providers/web/rapport_provider.dart';
import 'screens/auth/login_screen.dart';
import 'screens/home/home_screen.dart';
import 'screens/notifications/annonce_details_screen.dart';
import 'screens/notifications/notifications_screen.dart';
import 'screens/settings/settings_screen.dart';
import 'screens/web/settings/settings_admin_screen.dart';
import 'services/notification_service.dart';
import 'services/preference_service.dart';
import 'services/language_service.dart';
import 'services/connectivity_service.dart';
import 'providers/notification_provider.dart';

/// Imports conditionnels pour la plateforme web.
import 'providers/web/paiement_admin_provider.dart' if (dart.library.html) 'providers/web/paiement_admin_provider.dart';
import 'providers/web/signalement_admin_provider.dart' if (dart.library.html) 'providers/web/signalement_admin_provider.dart';
import 'providers/web/UserAdminProvider.dart' if (dart.library.html) 'providers/web/UserAdminProvider.dart';
import 'screens/web/annonces/annonce_admin_screen.dart' if (dart.library.html) 'screens/web/annonces/annonce_admin_screen.dart';
import 'screens/web/auth/admin_login_screen.dart' if (dart.library.html) 'screens/web/auth/admin_login_screen.dart';
import 'screens/web/dashboard/dashboard_screen.dart' if (dart.library.html) 'screens/web/dashboard/dashboard_screen.dart';
import 'screens/web/paiements/paiement_admin_screen.dart' if (dart.library.html) 'screens/web/paiements/paiement_admin_screen.dart';
import 'screens/web/signalements/SignalementAdminScreen.dart' if (dart.library.html) 'screens/web/signalements/SignalementAdminScreen.dart';
import 'screens/web/utilisateurs/User_Admin_Screen.dart' if (dart.library.html) 'screens/web/utilisateurs/User_Admin_Screen.dart';
import 'screens/web/paiements/export_preview_screen.dart' if (dart.library.html) 'screens/web/paiements/export_preview_screen.dart';
import 'screens/web/rapports/rapports_screen.dart' if (dart.library.html) 'screens/web/rapports/rapports_screen.dart';

/// Gestionnaire de notifications en arrière‑plan.
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  print('Notification background: ${message.notification?.title}');
}

/// Détecteur de plateforme.
class PlatformDetector {
  static bool get isMobile => !kIsWeb && (UniversalPlatform.isAndroid || UniversalPlatform.isIOS);
  static bool get isWeb => kIsWeb;
  static bool get isDesktop => !kIsWeb && (UniversalPlatform.isWindows || UniversalPlatform.isMacOS || UniversalPlatform.isLinux);
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialisation des services
  final apiService = ApiService();
  await apiService.init();
  final preferenceService = PreferenceService();
  await preferenceService.init();

  await dotenv.load(fileName: ".env");

  try {
    await Firebase.initializeApp();
    print('Firebase initialise');
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  } catch (e) {
    print('Erreur lors de l\'initialisation de Firebase: $e');
  }

  runApp(const CenouApp());
}

class CenouApp extends StatefulWidget {
  const CenouApp({Key? key}) : super(key: key);

  @override
  State<CenouApp> createState() => _CenouAppState();
}

class _CenouAppState extends State<CenouApp> {
  final LanguageService _languageService = LanguageService();
  String _currentTheme = 'system';
  late final ConnectivityService _connectivityService;

  @override
  void initState() {
    super.initState();
    _connectivityService = ConnectivityService();
    _initialize();
  }

  /// Initialise les services de langue et de thème.
  Future<void> _initialize() async {
    await _languageService.loadLocale();
    final preferenceService = PreferenceService();
    _currentTheme = await preferenceService.getPreferredTheme();
    setState(() {});
  }

  /// Met à jour le thème de l'application.
  void _updateTheme(String theme) {
    setState(() {
      _currentTheme = theme;
    });
  }

  @override
  Widget build(BuildContext context) {
    final bool isWeb = PlatformDetector.isWeb;
    final String appTitle = isWeb ? 'Dashboard CENOU Admin' : 'CENOU Mobile';

    return MultiProvider(
      providers: [
        // Services
        ChangeNotifierProvider(create: (_) => _languageService),

        // Providers communs
        ChangeNotifierProvider.value(value: _connectivityService),

        ChangeNotifierProvider(create: (_) => AuthProvider()),

        // Providers métier avec dépendance à la connectivité
        ChangeNotifierProvider(
          create: (_) => PaiementProvider(_connectivityService),
        ),
        ChangeNotifierProvider(
          create: (_) => SignalementProvider(_connectivityService),
        ),
        ChangeNotifierProvider(
          create: (_) => NotificationProvider(_connectivityService),
        ),

        // Providers web (uniquement sur navigateur)
        if (isWeb) ...[
          ChangeNotifierProvider(create: (_) => PaiementAdminProvider()),
          ChangeNotifierProvider(create: (_) => SignalementAdminProvider()),
          ChangeNotifierProvider(create: (_) => UserAdminProvider()),
          ChangeNotifierProvider(create: (_) => AnnonceAdminProvider()),
          ChangeNotifierProvider(create: (_) => RapportProvider()),
        ],
      ],

      child: Builder(
        builder: (context) {
          final languageService = context.watch<LanguageService>();

          return MaterialApp(
            title: appTitle,
            theme: isWeb ? _buildWebTheme() : _getTheme(_currentTheme),
            darkTheme: isWeb ? _buildWebDarkTheme() : AppTheme.darkTheme,
            themeMode: _getThemeMode(_currentTheme),

            // Configuration des locales
            locale: languageService.locale,
            supportedLocales: const [
              Locale('fr', 'FR'),
              Locale('en', 'US'),
            ],
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],

            debugShowCheckedModeBanner: false,
            home: const PlatformWrapper(),
            routes: _buildRoutes(isWeb, _updateTheme),
          );
        },
      ),
    );
  }

  /// Construit la map des routes en fonction de la plateforme.
  Map<String, WidgetBuilder> _buildRoutes(bool isWeb, Function(String) updateTheme) {
    final routes = <String, WidgetBuilder>{
      // Routes communes (mobile + web)
      '/login': (context) => const LoginScreen(),
      '/home': (context) => const HomeScreen(),
      '/settings': (context) => SettingsScreen(
        onThemeChanged: (theme) => updateTheme(theme),
      ),
      '/notifications': (context) => const NotificationsScreen(),
      '/annonce-details': (context) => const AnnonceDetailsScreen(annonceId: 0),
    };

    // Routes spécifiques au web (avec protection AdminGuard)
    if (isWeb) {
      routes.addAll({
        '/admin/login': (context) => const AdminLoginScreen(),
        '/admin/dashboard': (context) => const AdminGuard(child: DashboardScreen()),
        '/admin/paiements': (context) => const AdminGuard(child: PaiementAdminScreen()),
        '/admin/signalements': (context) => const AdminGuard(child: SignalementAdminScreen()),
        '/admin/utilisateurs': (context) => const AdminGuard(child: UserAdminScreen()),
        '/admin/rapports': (context) => const AdminGuard(child: RapportsScreen()),
        '/admin/annonces': (context) => const AdminGuard(child: AnnonceAdminScreen()),
        '/admin/settings': (context) => AdminGuard(
          child: SettingsAdminScreen(onThemeChanged: (theme) => _updateTheme(theme)),
        ),
        '/admin/export-preview': (context) {
          final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>?;
          return AdminGuard(
            child: ExportPreviewScreen(
              format: args?['format'] ?? 'pdf',
              paiements: args?['paiements'] ?? [],
              filters: args?['filters'] ?? {},
            ),
          );
        },
      });
    }

    return routes;
  }

  /// Retourne le thème correspondant au mode choisi.
  ThemeData _getTheme(String themeMode) {
    switch (themeMode) {
      case 'dark':
        return AppTheme.darkTheme;
      case 'light':
        return AppTheme.lightTheme;
      default:
        return AppTheme.lightTheme;
    }
  }

  /// Retourne le mode de thème (clair/sombre/système).
  ThemeMode _getThemeMode(String themeMode) {
    switch (themeMode) {
      case 'dark':
        return ThemeMode.dark;
      case 'light':
        return ThemeMode.light;
      default:
        return ThemeMode.system;
    }
  }

  /// Thème Material 3 pour le tableau de bord web (mode clair).
  ThemeData _buildWebTheme() {
    return ThemeData(
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF1E3A8A),
        brightness: Brightness.light,
      ),
      useMaterial3: true,
      fontFamily: 'Inter',
      cardTheme: const CardThemeData(
        elevation: 1,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(12)),
        ),
      ),
      inputDecorationTheme: const InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(10)),
        ),
        filled: true,
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF1E3A8A),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      ),
    );
  }

  /// Thème Material 3 pour le tableau de bord web (mode sombre).
  ThemeData _buildWebDarkTheme() {
    return ThemeData(
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF1E3A8A),
        brightness: Brightness.dark,
      ),
      useMaterial3: true,
      fontFamily: 'Inter',
      cardTheme: const CardThemeData(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(12)),
        ),
      ),
      inputDecorationTheme: const InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(10)),
        ),
        filled: true,
        fillColor: Color(0xFF2D2D2D),
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF1E3A8A),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      ),
    );
  }
}

// ==================== WRAPPERS POUR L'AUTHENTIFICATION ====================

class PlatformWrapper extends StatefulWidget {
  const PlatformWrapper({Key? key}) : super(key: key);

  @override
  State<PlatformWrapper> createState() => _PlatformWrapperState();
}

class _PlatformWrapperState extends State<PlatformWrapper> {
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  /// Initialise la localisation et attend que le service de langue soit prêt.
  Future<void> _initialize() async {
    await Future.delayed(const Duration(milliseconds: 100));

    try {
      final languageService = Provider.of<LanguageService>(context, listen: false);
      await initializeDateFormatting(languageService.locale.languageCode, null);
    } catch (e) {
      await initializeDateFormatting('fr_FR', null);
    }

    setState(() => _initialized = true);
  }

  @override
  @override
  Widget build(BuildContext context) {
    if (!_initialized) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    // 🔒 Sur le web, bloquer les navigateurs mobiles
    if (PlatformDetector.isWeb) {
      final screenWidth = MediaQuery.of(context).size.width;
      final screenHeight = MediaQuery.of(context).size.height;

      // Détection mobile : écran étroit ET hauteur > largeur (portrait)
      // Un PC avec fenêtre réduite aura rarement hauteur > largeur
      final isMobileBrowser = screenWidth < 768 && screenHeight > screenWidth;

      if (isMobileBrowser) {
        return const MobileBlockScreen();
      }
      return const WebAuthWrapper();
    }

    return const MobileAuthWrapper();
  }
}

class WebAuthWrapper extends StatelessWidget {
  const WebAuthWrapper({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: context.read<AuthProvider>().checkAuthStatus(),
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Scaffold(
            backgroundColor: Color(0xFF1a237e),
            body: Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            ),
          );
        }

        // Consumer pour réagir aux changements d'état en temps réel
        return Consumer<AuthProvider>(
          builder: (context, auth, _) {
            if (auth.isAuthenticated &&
                (auth.isAdmin || auth.isGestionnaire)) {
              return const DashboardScreen();
            }
            return const AdminLoginScreen();
          },
        );
      },
    );
  }
}

class MobileAuthWrapper extends StatefulWidget {
  const MobileAuthWrapper({Key? key}) : super(key: key);

  @override
  State<MobileAuthWrapper> createState() => _MobileAuthWrapperState();
}

class _MobileAuthWrapperState extends State<MobileAuthWrapper>
    with WidgetsBindingObserver {

  final NotificationService _notificationService = NotificationService();
  final PreferenceService    _prefService        = PreferenceService();
  final LocalAuthentication  _localAuth          = LocalAuthentication();

  bool _authChecked     = false;
  bool _isAuthenticated = false;

  // Contrôle l'affichage de l'écran de verrouillage biométrique
  bool _showBiometricLock = false;

  // Mémorise quand l'app est passée en arrière-plan
  DateTime? _backgroundedAt;

  // Délai minimal avant de demander la biométrie au retour (15 s)
  static const Duration _lockDelay = Duration(seconds: 15);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeAuth();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  // ── Cycle de vie de l'app ─────────────────────────────────────────────

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      _backgroundedAt = DateTime.now();
    }

    if (state == AppLifecycleState.resumed) {
      _onAppResumed();
    }
  }

  Future<void> _onAppResumed() async {
    if (!_isAuthenticated) return;

    // Pas de biométrie si l'app est restée en avant-plan moins de _lockDelay
    final bg = _backgroundedAt;
    if (bg != null &&
        DateTime.now().difference(bg) < _lockDelay) {
      return;
    }

    // Vérifier que la biométrie est activée dans les préfs
    final biometricEnabled = await _prefService.getBiometricEnabled();
    if (!biometricEnabled) return;

    // Vérifier que le device supporte encore la biométrie
    final canCheck    = await _localAuth.canCheckBiometrics;
    final isSupported = await _localAuth.isDeviceSupported();
    if (!canCheck || !isSupported) return;

    if (mounted) {
      setState(() => _showBiometricLock = true);
    }
  }

  // ── Initialisation ─────────────────────────────────────────────────────

  Future<void> _initializeAuth() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    await authProvider.initAuth();

    if (authProvider.isAuthenticated) {
      await _notificationService.initialize();
    }

    if (mounted) {
      setState(() {
        _authChecked     = true;
        _isAuthenticated = authProvider.isAuthenticated;
      });
    }
  }

  // ── Build ───────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    if (!_authChecked) {
      return const Scaffold(
          body: Center(child: CircularProgressIndicator()));
    }

    return Consumer<AuthProvider>(
      builder: (context, auth, _) {
        // Pas connecté → Login
        if (!auth.isAuthenticated) {
          _isAuthenticated    = false;
          _showBiometricLock  = false;
          return const LoginScreen();
        }

        _isAuthenticated = true;

        // Connecté mais verrouillé → BiometricLockScreen
        if (_showBiometricLock) {
          return BiometricLockScreen(
            onSuccess: () {
              if (mounted) setState(() => _showBiometricLock = false);
            },
            onFallback: () {
              // logout() est appelé dans BiometricLockScreen avant onFallback
              if (mounted) setState(() => _showBiometricLock = false);
            },
          );
        }

        // Connecté et déverrouillé → HomeScreen
        return const HomeScreen();
      },
    );
  }
}

class MobileBlockScreen extends StatelessWidget {
  const MobileBlockScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1a237e),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.desktop_windows_rounded,
                color: Colors.white,
                size: 80,
              ),
              const SizedBox(height: 24),
              const Text(
                'Application réservée aux ordinateurs',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Ce tableau de bord CENOU est uniquement accessible depuis un ordinateur. Veuillez utiliser l\'application mobile CENOU.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.8),
                  fontSize: 15,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 40),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white.withOpacity(0.3)),
                ),
                child: const Text(
                  '📱 Téléchargez l\'application CENOU Mobile',
                  style: TextStyle(color: Colors.white, fontSize: 13),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}