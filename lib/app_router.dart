import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'core/auth_state.dart';
import 'core/onboarding_storage.dart';
import 'features/admin/admin_screen.dart';
import 'repositories/life_assessment_repository.dart';
import 'repositories/profile_repository.dart';
import 'features/admin/place_form_screen.dart';
import 'features/auth/forgot_password_screen.dart';
import 'features/auth/login_screen.dart';
import 'features/auth/register_screen.dart';
import 'features/auth/reset_password_screen.dart';
import 'features/challenges/challenge_detail_screen.dart';
import 'features/challenges/challenge_form_screen.dart';
import 'features/feed/feed_screen.dart';
import 'features/home/main_shell.dart';
import 'features/home/home_screen.dart';
import 'features/notifications/notifications_screen.dart';
import 'features/profile/user_profile_screen.dart';
import 'features/settings/edit_profile_screen.dart';
import 'features/settings/settings_screen.dart';
import 'features/achievements/achievements_screen.dart';
import 'features/life_wheel/life_wheel_survey_screen.dart';
import 'features/onboarding/onboarding_screen.dart';
import 'features/professionals/professionals_screen.dart';

/// Claves para los navegadores de cada pestaña (conservan estado al cambiar de tab).
final _homeNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'home');
final _feedNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'feed');
final _settingsNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'settings');

/// Transición suave entre pantallas (fade) en lugar del slide por defecto.
CustomTransitionPage<void> _fadePage(GoRouterState state, Widget child) {
  return CustomTransitionPage<void>(
    key: state.pageKey,
    child: child,
    transitionDuration: const Duration(milliseconds: 200),
    reverseTransitionDuration: const Duration(milliseconds: 180),
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      return FadeTransition(
        opacity: CurveTween(curve: Curves.easeOut).animate(animation),
        child: child,
      );
    },
  );
}

GoRouter createAppRouter(HolistiaAuthState authState) {
  return GoRouter(
    refreshListenable: authState,
    initialLocation: '/',
    redirect: (BuildContext context, GoRouterState state) async {
      final isSignedIn = Supabase.instance.client.auth.currentUser != null;
      final location = state.matchedLocation;
      final isOnboarding = location == '/onboarding';
      final isAuthRoute = location == '/login' || location == '/register';
      final isForgotPassword = location == '/forgot-password';
      final isResetPassword = location == '/reset-password';
      final isAdminRoute = location == '/admin' || location.startsWith('/admin/');

      if (isSignedIn) {
        if (isAdminRoute) {
          final me = await ProfileRepository().getMyProfile();
          if (me == null || !me.role.isAdmin) return '/feed';
        }
        if (location == '/reset-password') return null;
        if (authState.pendingPasswordReset) {
          authState.clearPendingPasswordReset();
          return '/reset-password';
        }
        if (location == '/life-wheel') return null;
        if (location == '/' || isAuthRoute || isOnboarding || isForgotPassword) {
          var surveySeen = await getLifeWheelSurveySeen();
          if (!surveySeen) {
            // Fallback: check DB for users who signed in on a new device
            // (e.g. Google sign-in) and already completed the survey before.
            surveySeen = await LifeAssessmentRepository().hasMyAssessments();
            if (surveySeen) await setLifeWheelSurveySeen();
          }
          if (!surveySeen) return '/life-wheel';
          return '/feed';
        }
        return null;
      }

      if (isOnboarding) return null;
      if (isAuthRoute || isForgotPassword) return null;
      if (isResetPassword) return '/login';

      final onboardingSeen = await getOnboardingSeen();
      if (!onboardingSeen) return '/onboarding';
      return '/login';
    },
    routes: [
      GoRoute(
        path: '/life-wheel',
        pageBuilder: (context, state) =>
            _fadePage(state, const LifeWheelSurveyScreen()),
      ),
      GoRoute(
        path: '/onboarding',
        pageBuilder: (context, state) => _fadePage(state, const OnboardingScreen()),
      ),
      GoRoute(
        path: '/login',
        pageBuilder: (context, state) => _fadePage(state, const LoginScreen()),
      ),
      GoRoute(
        path: '/register',
        pageBuilder: (context, state) => _fadePage(state, const RegisterScreen()),
      ),
      GoRoute(
        path: '/forgot-password',
        pageBuilder: (context, state) => _fadePage(state, const ForgotPasswordScreen()),
      ),
      GoRoute(
        path: '/reset-password',
        pageBuilder: (context, state) => _fadePage(state, const ResetPasswordScreen()),
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) => MainShell(
          navigationShell: navigationShell,
        ),
        branches: [
          StatefulShellBranch(
            navigatorKey: _homeNavigatorKey,
            routes: [
              GoRoute(
                path: '/home',
                pageBuilder: (context, state) => _fadePage(state, const HomeScreen()),
              ),
            ],
          ),
          StatefulShellBranch(
            navigatorKey: _feedNavigatorKey,
            routes: [
              GoRoute(
                path: '/feed',
                pageBuilder: (context, state) => _fadePage(state, const FeedScreen()),
              ),
            ],
          ),
          StatefulShellBranch(
            navigatorKey: _settingsNavigatorKey,
            routes: [
              GoRoute(
                path: '/settings',
                pageBuilder: (context, state) => _fadePage(state, const SettingsScreen()),
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: '/challenges/new',
        pageBuilder: (context, state) => _fadePage(state, const ChallengeFormScreen()),
      ),
      GoRoute(
        path: '/challenges/:id',
        pageBuilder: (_, state) {
          // GoRouter garantiza que los path parameters existen cuando la ruta hace match.
          final id = state.pathParameters['id']!;
          return _fadePage(state, ChallengeDetailScreen(challengeId: id));
        },
      ),
      GoRoute(
        path: '/challenges/:id/edit',
        pageBuilder: (_, state) {
          final id = state.pathParameters['id']!;
          return _fadePage(state, ChallengeFormScreen(challengeId: id));
        },
      ),
      GoRoute(
        path: '/notifications',
        pageBuilder: (context, state) => _fadePage(state, const NotificationsScreen()),
      ),
      GoRoute(
        path: '/settings/edit-profile',
        pageBuilder: (context, state) => _fadePage(state, const EditProfileScreen()),
      ),
      GoRoute(
        path: '/user/:userId',
        pageBuilder: (_, state) {
          final userId = state.pathParameters['userId']!;
          return _fadePage(state, UserProfileScreen(userId: userId));
        },
      ),
      GoRoute(
        path: '/admin',
        pageBuilder: (context, state) => _fadePage(state, const AdminScreen()),
      ),
      GoRoute(
        path: '/admin/places/new',
        pageBuilder: (context, state) =>
            _fadePage(state, const PlaceFormScreen()),
      ),
      GoRoute(
        path: '/admin/places/:id/edit',
        pageBuilder: (context, state) {
          final id = state.pathParameters['id']!;
          return _fadePage(state, PlaceFormScreen(placeId: id));
        },
      ),
      GoRoute(
        path: '/professionals',
        pageBuilder: (context, state) =>
            _fadePage(state, const ProfessionalsScreen()),
      ),
      GoRoute(
        path: '/achievements',
        pageBuilder: (context, state) =>
            _fadePage(state, const AchievementsScreen()),
      ),
    ],
  );
}
