import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:orange_quality_checker/screens/home_screen.dart';
import 'package:orange_quality_checker/screens/history_screen.dart';
import 'package:orange_quality_checker/screens/settings_screen.dart';
import 'package:orange_quality_checker/screens/scan_result_screen.dart';
import 'package:orange_quality_checker/screens/scan_detail_screen.dart';
import 'package:orange_quality_checker/screens/model_details_screen.dart';
import 'package:orange_quality_checker/screens/orange_classifier_screen.dart';
import 'package:orange_quality_checker/screens/not_found_screen.dart';
import 'package:orange_quality_checker/screens/model_test_screen.dart';
import 'package:orange_quality_checker/screens/test_data_screen.dart';
import 'package:orange_quality_checker/screens/color_detector_screen.dart';
import 'package:orange_quality_checker/providers/app_provider.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    const ProviderScope(
      child: MyApp(),
    ),
  );
}

final _router = GoRouter(
  initialLocation: '/color-detector',
  errorBuilder: (context, state) => const NotFoundScreen(),
  routes: [
    ShellRoute(
      builder: (context, state, child) {
        return MainShell(child: child);
      },
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => const HomeScreen(),
        ),
        GoRoute(
          path: '/history',
          builder: (context, state) => const HistoryScreen(),
        ),
        GoRoute(
          path: '/settings',
          builder: (context, state) => const SettingsScreen(),
        ),
        GoRoute(
          path: '/color-detector',
          builder: (context, state) => const ColorDetectorScreen(),
        ),
      ],
    ),
    GoRoute(
      path: '/scan-result',
      builder: (context, state) => const ScanResultScreen(),
    ),
    GoRoute(
      path: '/scan-detail/:id',
      builder: (context, state) {
        final id = state.pathParameters['id'] ?? '';
        return ScanDetailScreen(scanId: id);
      },
    ),
    GoRoute(
      path: '/model-details/:id',
      builder: (context, state) {
        final id = state.pathParameters['id'] ?? '';
        return ModelDetailsScreen(modelId: id);
      },
    ),
    GoRoute(
      path: '/orange-classifier',
      builder: (context, state) => const OrangeClassifierScreen(),
    ),
    GoRoute(
      path: '/model-test',
      builder: (context, state) => const ModelTestScreen(),
    ),
    GoRoute(
      path: '/test-data',
      builder: (context, state) => const TestDataScreen(),
    ),
  ],
);

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    
    return MaterialApp.router(
      title: 'Orange Quality Checker',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.deepPurple,
          brightness: Brightness.light,
        ),
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.deepPurple,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      themeMode: themeMode,
      routerConfig: _router,
    );
  }
}

class MainShell extends StatelessWidget {
  final Widget child;
  
  const MainShell({super.key, required this.child});
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      body: child,
      bottomNavigationBar: NavigationBar(
        backgroundColor: const Color(0xFF1E1E1E),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.camera_alt_outlined),
            selectedIcon: Icon(Icons.camera_alt),
            label: 'Detector',
          ),
          NavigationDestination(
            icon: Icon(Icons.history_outlined),
            selectedIcon: Icon(Icons.history),
            label: 'History',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
        onDestinationSelected: (index) {
          switch (index) {
            case 0:
              context.go('/color-detector');
              break;
            case 1:
              context.go('/history');
              break;
            case 2:
              context.go('/settings');
              break;
          }
        },
        selectedIndex: _calculateSelectedIndex(context),
        labelBehavior: NavigationDestinationLabelBehavior.onlyShowSelected,
        indicatorColor: Colors.orange.shade700.withOpacity(0.4),
      ),
    );
  }
  
  int _calculateSelectedIndex(BuildContext context) {
    final String location = GoRouterState.of(context).matchedLocation;
    if (location == '/color-detector') {
      return 0;
    }
    if (location == '/history') {
      return 1;
    }
    if (location == '/settings') {
      return 2;
    }
    return 0;
  }
}
