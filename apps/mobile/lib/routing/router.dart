import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/api/api_client.dart';
import '../features/auth/screens/login_screen.dart';
import '../features/auth/screens/otp_screen.dart';
import '../features/onboarding/screens/onboarding_screen.dart';
import '../features/profile/screens/profile_setup_screen.dart';
import '../features/scan/screens/home_screen.dart';
import '../features/scan/screens/scan_screen.dart';
import '../features/scan/screens/analyzing_screen.dart';
import '../features/result/screens/result_screen.dart';
import '../features/result/screens/ingredients_screen.dart';
import '../features/history/screens/history_screen.dart';
import '../features/settings/screens/about_screen.dart';
import '../features/settings/screens/feedback_screen.dart';
import '../features/settings/screens/paywall_screen.dart';
import '../features/settings/screens/privacy_screen.dart';
import '../features/settings/screens/settings_screen.dart';
import '../features/settings/screens/terms_screen.dart';
import '../features/history/screens/favourites_screen.dart';

// Cached profile check — null = unknown, true = complete, false = needs setup
final profileCompleteProvider = StateProvider<bool?>((ref) => null);

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/onboarding',
    redirect: (context, state) async {
      final session = Supabase.instance.client.auth.currentSession;
      final isAuth = session != null;
      final loc = state.matchedLocation;

      final isPublicRoute = loc.startsWith('/auth') ||
          loc == '/onboarding' ||
          loc == '/profile/setup';

      if (!isAuth && !isPublicRoute) return '/auth/login';
      if (isAuth && loc == '/auth/login') return '/home';

      // After login, check if user has completed profile setup
      if (isAuth && !isPublicRoute) {
        final cached = ref.read(profileCompleteProvider);
        if (cached == null) {
          try {
            await ref.read(apiClientProvider).getMe();
            ref.read(profileCompleteProvider.notifier).state = true;
          } catch (_) {
            ref.read(profileCompleteProvider.notifier).state = false;
            return '/profile/setup';
          }
        } else if (cached == false) {
          return '/profile/setup';
        }
      }

      // Reset profile cache on sign out
      if (!isAuth) {
        ref.read(profileCompleteProvider.notifier).state = null;
      }

      return null;
    },
    routes: [
      GoRoute(path: '/onboarding',     builder: (_, __) => const OnboardingScreen()),
      GoRoute(path: '/auth/login',     builder: (_, __) => const LoginScreen()),
      GoRoute(path: '/auth/otp',       builder: (_, __) => const OtpScreen()),
      GoRoute(path: '/profile/setup',  builder: (_, __) => const ProfileSetupScreen()),
      GoRoute(path: '/home',           builder: (_, __) => const HomeScreen()),
      GoRoute(path: '/scan',           builder: (_, __) => const ScanScreen()),
      GoRoute(path: '/scan/analyzing', builder: (_, __) => const AnalyzingScreen()),
      GoRoute(
        path: '/result/:id',
        builder: (_, state) => ResultScreen(productId: state.pathParameters['id']!),
        routes: [
          GoRoute(
            path: 'ingredients',
            builder: (_, state) => IngredientsScreen(productId: state.pathParameters['id']!),
          ),
        ],
      ),
      GoRoute(path: '/history',  builder: (_, __) => const HistoryScreen()),
      GoRoute(path: '/paywall',     builder: (_, __) => const PaywallScreen()),
      GoRoute(path: '/settings',    builder: (_, __) => const SettingsScreen()),
      GoRoute(path: '/privacy',     builder: (_, __) => const PrivacyScreen()),
      GoRoute(path: '/terms',       builder: (_, __) => const TermsScreen()),
      GoRoute(path: '/about',       builder: (_, __) => const AboutScreen()),
      GoRoute(path: '/feedback',    builder: (_, __) => const FeedbackScreen()),
      GoRoute(path: '/favourites',  builder: (_, __) => const FavouritesScreen()),
    ],
    errorBuilder: (context, state) => const HomeScreen(),
  );
});
