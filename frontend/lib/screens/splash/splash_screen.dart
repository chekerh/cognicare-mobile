import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../l10n/app_localizations.dart';
import '../../providers/auth_provider.dart';
import '../../services/auth_service.dart';
import '../../utils/constants.dart';
import '../../utils/theme.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  Timer? _navigationTimer;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    _animationController.forward();

    // Navigate after a 2 second splash and check auth status
    _navigationTimer = Timer(const Duration(seconds: 2), () {
      _checkAuthAndNavigate();
    });
  }

  Future<void> _checkAuthAndNavigate() async {
    if (!mounted) return;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final router = GoRouter.of(context);

    try {
      // Safety: if anything takes too long, go to login
      await _checkAuthAndNavigateImpl(authProvider, router)
          .timeout(const Duration(seconds: 15));
    } catch (e) {
      // Timeout or error: ensure we never stay stuck on splash
      if (mounted) {
        try {
          await authProvider.logout();
        } catch (_) {}
        if (mounted) router.go(AppConstants.loginRoute);
      }
    }
  }

  Future<void> _checkAuthAndNavigateImpl(
    AuthProvider authProvider,
    GoRouter router,
  ) async {
    if (!mounted) return;

    final hasStoredAuth = await authProvider.loadStoredAuth();

    if (hasStoredAuth) {
      try {
        final authService = AuthService();
        final user = await authService.getProfile();

        if (mounted) {
          authProvider.updateUser(user);
          if (AppConstants.isFamilyRole(user.role)) {
            router.go(AppConstants.familyDashboardRoute);
          } else if (AppConstants.isOrganizationLeaderRole(user.role)) {
            router.go(AppConstants.organizationDashboardRoute);
          } else if (AppConstants.isVolunteerRole(user.role)) {
            router.go(AppConstants.volunteerDashboardRoute);
          } else {
            router.go(AppConstants.homeRoute);
          }
        }
      } catch (e) {
        if (mounted) {
          await authProvider.logout();
          router.go(AppConstants.loginRoute);
        }
      }
    } else {
      if (mounted) {
        final prefs = await SharedPreferences.getInstance();
        if (!mounted) return;
        final onboardingComplete = prefs.getBool('onboarding_complete') ?? false;
        if (!onboardingComplete) {
          router.go(AppConstants.onboardingRoute);
        } else {
          router.go(AppConstants.loginRoute);
        }
      }
    }
  }

  @override
  void dispose() {
    _navigationTimer?.cancel();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: AppTheme.primary,
      body: Center(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Logo placeholder (you can replace with actual logo)
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(60),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.psychology,
                  size: 60,
                  color: AppTheme.primary,
                ),
              ),
              const SizedBox(height: 32),
              // App title
              Text(
                localizations.appTitle,
                style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 16),
              // Tagline
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Text(
                  localizations.splashTagline,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: Colors.white.withOpacity(0.9),
                        fontWeight: FontWeight.w300,
                      ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}