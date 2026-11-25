import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'screens/alert_screen.dart';
import 'screens/home_screen.dart';
import 'screens/map_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/stations_screen.dart';
import 'services/location_service.dart';
import 'services/notification_service.dart';
import 'services/weather_service.dart';
import 'state/app_state.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  final notifications = NotificationService();
  await notifications.init();

  runApp(
    ChangeNotifierProvider(
      create: (_) => AppState(
        prefs: prefs,
        notifications: notifications,
        location: LocationService(),
        weather: WeatherService(prefs),
      ),
      child: const FloodSenseApp(),
    ),
  );
}

class FloodSenseApp extends StatelessWidget {
  const FloodSenseApp({super.key});

  @override
  Widget build(BuildContext context) {
    final scale = context.select<AppState, double>((a) => a.textScale);
    return MaterialApp(
      title: 'FloodSense',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.build(),
      // Apply the in-app text size on top of the phone's own setting.
      builder: (context, child) {
        final mq = MediaQuery.of(context);
        final combined = (mq.textScaler.scale(16) / 16 * scale).clamp(1.0, 2.0);
        return MediaQuery(
          data: mq.copyWith(textScaler: TextScaler.linear(combined)),
          child: child!,
        );
      },
      home: const HomeShell(),
    );
  }
}

/// Bottom navigation + the listener that pops up flood alerts.
class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _tab = 0;
  Route<void>? _alertRoute;
  late final AppState _app;

  @override
  void initState() {
    super.initState();
    _app = context.read<AppState>();
    _app.addListener(_maybeShowAlert);
    WidgetsBinding.instance.addPostFrameCallback((_) => _app.initPermissionsAndTracking());
  }

  @override
  void dispose() {
    _app.removeListener(_maybeShowAlert);
    super.dispose();
  }

  void _maybeShowAlert() {
    if (_app.pendingAlert == null) return;
    final event = _app.takePendingAlert()!;
    final route = MaterialPageRoute<void>(
      fullscreenDialog: true,
      builder: (_) => AlertScreen(event: event, s: _app.s),
    );
    final nav = Navigator.of(context);
    // A newer alert replaces one still on top (e.g. Warning -> Danger),
    // so the user never has to dismiss a stack of old alerts.
    final open = _alertRoute;
    final replace = open != null && open.isCurrent;
    final shown = replace ? nav.pushReplacement(route) : nav.push(route);
    _alertRoute = route;
    shown.then((_) {
      if (identical(_alertRoute, route)) _alertRoute = null;
    });
  }

  void _goHome() => setState(() => _tab = 0);

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>().s;
    return Scaffold(
      body: IndexedStack(index: _tab, children: [
        HomeScreen(onChangeStation: () => setState(() => _tab = 1)),
        StationsScreen(onChosen: _goHome),
        MapScreen(onChosen: _goHome),
        const SettingsScreen(),
      ]),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tab,
        onDestinationSelected: (i) => setState(() => _tab = i),
        destinations: [
          NavigationDestination(
              icon: const Icon(Icons.home_outlined), selectedIcon: const Icon(Icons.home_rounded), label: s.navHome),
          NavigationDestination(
              icon: const Icon(Icons.list_alt_outlined), selectedIcon: const Icon(Icons.list_alt_rounded), label: s.navStations),
          NavigationDestination(
              icon: const Icon(Icons.map_outlined), selectedIcon: const Icon(Icons.map_rounded), label: s.navMap),
          NavigationDestination(
              icon: const Icon(Icons.settings_outlined), selectedIcon: const Icon(Icons.settings_rounded), label: s.navSettings),
        ],
      ),
    );
  }
}
