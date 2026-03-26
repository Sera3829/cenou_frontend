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

    // Routes spécifiques au web
    if (isWeb) {
      routes.addAll({
        '/admin/login': (context) => const AdminLoginScreen(),
        '/admin/dashboard': (context) => const DashboardScreen(),
        '/admin/paiements': (context) => const PaiementAdminScreen(),
        '/admin/signalements': (context) => const SignalementAdminScreen(),
        '/admin/utilisateurs': (context) => const UserAdminScreen(),
        '/admin/rapports': (context) => const RapportsScreen(),
        '/admin/annonces': (context) => const AnnonceAdminScreen(),
        '/admin/settings': (context) => SettingsAdminScreen(
          onThemeChanged: (theme) => _updateTheme(theme),
        ),
        '/admin/export-preview': (context) {
          final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>?;
          return ExportPreviewScreen(
            format: args?['format'] ?? 'pdf',
            paiements: args?['paiements'] ?? [],
            filters: args?['filters'] ?? {},
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
  Widget build(BuildContext context) {
    if (!_initialized) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (PlatformDetector.isWeb || PlatformDetector.isDesktop) {
      return const WebAuthWrapper();
    } else {
      return const MobileAuthWrapper();
    }
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

        final authProvider = context.read<AuthProvider>();

        if (authProvider.isAuthenticated &&
            (authProvider.isAdmin || authProvider.isGestionnaire)) {
          return const DashboardScreen();
        }

        return const AdminLoginScreen();
      },
    );
  }
}

class MobileAuthWrapper extends StatefulWidget {
  const MobileAuthWrapper({Key? key}) : super(key: key);

  @override
  State<MobileAuthWrapper> createState() => _MobileAuthWrapperState();
}

class _MobileAuthWrapperState extends State<MobileAuthWrapper> {
  final NotificationService _notificationService = NotificationService();
  bool _authChecked = false;
  bool _isAuthenticated = false;

  @override
  void initState() {
    super.initState();
    _initializeAuth();
  }

  /// Initialise l'authentification et, si connecté, le service de notifications.
  Future<void> _initializeAuth() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    await authProvider.initAuth();

    if (authProvider.isAuthenticated) {
      await _notificationService.initialize();
    }

    setState(() {
      _authChecked = true;
      _isAuthenticated = authProvider.isAuthenticated;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_authChecked) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_isAuthenticated) {
      return const HomeScreen();
    }

    return const LoginScreen();
  }
}