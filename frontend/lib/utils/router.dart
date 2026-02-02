import 'package:go_router/go_router.dart';
import '../screens/splash/splash_screen.dart';
import '../screens/onboarding/onboarding_screen.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/signup_screen.dart';
import '../screens/auth/forgot_password_screen.dart';
import '../screens/language/language_selection_screen.dart';
import '../screens/home/home_container_screen.dart';
import 'constants.dart';

final GoRouter appRouter = GoRouter(
  initialLocation: AppConstants.splashRoute,
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
  ],
);