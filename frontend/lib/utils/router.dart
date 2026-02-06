import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../screens/splash/splash_screen.dart';
import '../screens/onboarding/onboarding_screen.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/signup_screen.dart';
import '../screens/auth/forgot_password_screen.dart';
import '../screens/language/language_selection_screen.dart';
import '../screens/home/home_container_screen.dart';
import '../screens/organization/organization_dashboard_screen.dart';
import '../screens/family/add_post_screen.dart';
import '../screens/family/family_shell_screen.dart';
import '../screens/family/family_member_dashboard_screen.dart';
import '../screens/family/family_feed_screen.dart';
import '../screens/family/family_families_screen.dart';
import '../screens/family/family_group_chat_screen.dart';
import '../screens/family/family_market_screen.dart';
import '../screens/family/matching_game_screen.dart';
import '../screens/family/shape_sorting_screen.dart';
import '../screens/family/star_tracer_screen.dart';
import '../screens/profile/profile_screen.dart';
import 'constants.dart';

String? _redirect(BuildContext context, GoRouterState state) {
  final auth = Provider.of<AuthProvider>(context, listen: false);
  final isAuth = auth.isAuthenticated;
  final location = state.uri.path;
  final role = auth.user?.role;

  // Routes publiques (pas de JWT requis)
  final isPublic = AppConstants.publicRoutes.any((r) => location == r);

  if (!isAuth) {
    if (!isPublic) return AppConstants.loginRoute;
    return null;
  }

  // Utilisateur connecté : redirection selon la route et le rôle
  if (location == AppConstants.loginRoute || location == AppConstants.signupRoute) {
    if (AppConstants.isFamilyRole(role)) return AppConstants.familyDashboardRoute;
    if (AppConstants.isOrganizationLeaderRole(role)) return AppConstants.organizationDashboardRoute;
    return AppConstants.homeRoute;
  }

  // Rediriger /home vers le bon tableau de bord selon le rôle (famille → dashboard)
  if (location == AppConstants.homeRoute && AppConstants.isFamilyRole(role)) {
    return AppConstants.familyDashboardRoute;
  }

  // Protéger les routes famille : seul le rôle "family" peut y accéder
  if (location.startsWith(AppConstants.familyRoute) && !AppConstants.isFamilyRole(role)) {
    if (AppConstants.isOrganizationLeaderRole(role)) return AppConstants.organizationDashboardRoute;
    return AppConstants.homeRoute;
  }

  return null;
}

GoRouter createAppRouter(AuthProvider authProvider) {
  return GoRouter(
    initialLocation: AppConstants.splashRoute,
    refreshListenable: authProvider,
    redirect: _redirect,
    routes: [
    GoRoute(
      path: AppConstants.splashRoute,
      builder: (context, state) => const SplashScreen(),
    ),
    GoRoute(
      path: AppConstants.languageSelectionRoute,
      builder: (context, state) => const LanguageSelectionScreen(),
    ),
    GoRoute(
      path: AppConstants.onboardingRoute,
      builder: (context, state) => const OnboardingScreen(),
    ),
    GoRoute(
      path: AppConstants.loginRoute,
      builder: (context, state) => const LoginScreen(),
    ),
    GoRoute(
      path: AppConstants.signupRoute,
      builder: (context, state) => const SignupScreen(),
    ),
    GoRoute(
      path: AppConstants.forgotPasswordRoute,
      builder: (context, state) => const ForgotPasswordScreen(),
    ),
    GoRoute(
      path: AppConstants.homeRoute,
      builder: (context, state) => const HomeContainerScreen(),
    ),
    GoRoute(
      path: AppConstants.organizationDashboardRoute,
      builder: (context, state) => const OrganizationDashboardScreen(),
    ),
    // Secteur Famille : shell avec bottom nav (Feed, Families, +, Market, Profile)
    GoRoute(
      path: AppConstants.familyRoute,
      redirect: (_, state) {
        final path = state.uri.path;
        if (path == AppConstants.familyRoute || path == '${AppConstants.familyRoute}/') {
          return AppConstants.familyDashboardRoute;
        }
        return null;
      },
      routes: [
        GoRoute(
          path: 'create-post',
          builder: (context, state) => const AddPostScreen(),
        ),
        GoRoute(
          path: 'matching-game',
          builder: (context, state) => const MatchingGameScreen(),
        ),
        GoRoute(
          path: 'shape-sorting',
          builder: (context, state) => const ShapeSortingScreen(),
        ),
        GoRoute(
          path: 'star-tracer',
          builder: (context, state) => const StarTracerScreen(),
        ),
        GoRoute(
          path: 'group-chat',
          builder: (context, state) {
            final name = state.uri.queryParameters['name'] ?? 'Family Group';
            final members = int.tryParse(state.uri.queryParameters['members'] ?? '5') ?? 5;
            final id = state.uri.queryParameters['id'];
            return FamilyGroupChatScreen(
              groupName: name,
              memberCount: members,
              groupId: id?.isEmpty == true ? null : id,
            );
          },
        ),
        StatefulShellRoute.indexedStack(
          builder: (context, state, navigationShell) => FamilyShellScreen(
            navigationShell: navigationShell,
          ),
          branches: [
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: 'dashboard',
                  builder: (context, state) => const FamilyMemberDashboardScreen(),
                ),
              ],
            ),
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: 'feed',
                  builder: (context, state) => const FamilyFeedScreen(),
                ),
              ],
            ),
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: 'families',
                  builder: (context, state) => const FamilyFamiliesScreen(),
                ),
              ],
            ),
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: 'market',
                  builder: (context, state) => const FamilyMarketScreen(),
                ),
              ],
            ),
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: 'profile',
                  builder: (context, state) => const ProfileScreen(),
                ),
              ],
            ),
          ],
        ),
      ],
    ),
  ],
  );
}
