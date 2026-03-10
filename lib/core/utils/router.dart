import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/loading/loading_screen.dart';
import '../../features/onboarding/screens/onboarding_screen.dart';
import '../../features/home/screens/home_screen.dart';
import '../../features/session/screens/active_mode_screen.dart';
import '../../features/session/screens/session_summary_screen.dart';
import '../../features/session/screens/shorts_block_screen.dart';
import '../../features/settings/screens/settings_screen.dart';

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/loading',
    routes: [
      GoRoute(path: '/loading', builder: (_, __) => const LoadingScreen()),
      GoRoute(path: '/onboarding', builder: (_, __) => const OnboardingScreen()),
      GoRoute(path: '/home', builder: (_, __) => const HomeScreen()),
      GoRoute(path: '/active', builder: (_, __) => const ActiveModeScreen()),
      GoRoute(
        path: '/summary',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>;
          return SessionSummaryScreen(
            durationMinutes: extra['durationMinutes'] as int,
            blockedCount: extra['blockedCount'] as int,
          );
        },
      ),
      GoRoute(path: '/shorts-block', builder: (_, __) => const ShortsBlockScreen()),
      GoRoute(path: '/settings', builder: (_, __) => const SettingsScreen()),
    ],
  );
});
