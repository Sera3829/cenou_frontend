import 'dart:async';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/notification_provider.dart';
import '../../services/connectivity_service.dart';
import '../paiements/paiements_list_screen.dart';
import '../signalements/signalements_list_screen.dart';
import '../notifications/notifications_screen.dart';
import '../profile/profile_screen.dart';
import 'home_tab.dart';
import 'widgets/bottom_nav.dart';

/// Écran principal avec navigation par onglets — responsive mobile/tablette.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  int _currentIndex = 0;
  int _unreadCount = 0;
  Timer? _timer;
  StreamSubscription<RemoteMessage>? _foregroundSubscription;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final conn = Provider.of<ConnectivityService>(context, listen: false);
      conn.addListener(_onConnectivityChanged);
      Provider.of<NotificationProvider>(context, listen: false).loadNotifications();
    });
    _loadUnreadCount();
    _startPeriodicRefresh();
    _listenToForegroundNotifications();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    try {
      final conn = Provider.of<ConnectivityService>(context, listen: false);
      conn.removeListener(_onConnectivityChanged);
    } catch (_) {}
    _timer?.cancel();
    _foregroundSubscription?.cancel();
    super.dispose();
  }

  void _onConnectivityChanged() {
    final conn = Provider.of<ConnectivityService>(context, listen: false);
    if (conn.isOnline) {
      Provider.of<NotificationProvider>(context, listen: false).loadNotifications();
      _loadUnreadCount();

      // La session a pu être ouverte hors ligne sur la seule foi du jeton
      // local : le retour du réseau est le moment de la faire confirmer.
      final auth = Provider.of<AuthProvider>(context, listen: false);
      if (auth.sessionNonVerifiee) auth.refreshUser();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _loadUnreadCount();
  }

  void _startPeriodicRefresh() {
    _timer = Timer.periodic(const Duration(seconds: 30), (_) => _loadUnreadCount());
  }

  void _listenToForegroundNotifications() {
    _foregroundSubscription = FirebaseMessaging.onMessage.listen((_) => _loadUnreadCount());
  }

  Future<void> _loadUnreadCount() async {
    try {
      final count = await Provider.of<NotificationProvider>(context, listen: false)
          .getUnreadCount();
      if (mounted) setState(() => _unreadCount = count);
    } catch (_) {}
  }

  List<Widget> _getScreens() {
    return [
      HomeTab(
        unreadCount: _unreadCount,
        onNotificationTap: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const NotificationsScreen()),
          );
          _loadUnreadCount();
        },
      ),
      const PaiementsListScreen(),
      const SignalementsListScreen(),
      const ProfileScreen(),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _getScreens(),
      ),
      bottomNavigationBar: BottomNav(
        currentIndex: _currentIndex,
        unreadCount: _unreadCount,
        isDark: isDark,
        onTap: (i) => setState(() => _currentIndex = i),
      ),
    );
  }
}
