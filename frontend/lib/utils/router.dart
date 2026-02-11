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
import '../screens/family/family_private_chat_screen.dart';
import '../screens/family/family_market_screen.dart';
import '../screens/family/matching_game_screen.dart';
import '../screens/family/shape_sorting_screen.dart';
import '../screens/family/star_tracer_screen.dart';
import '../screens/family/basket_sort_screen.dart';
import '../screens/family/donation_detail_screen.dart';
import '../screens/family/donation_chat_screen.dart';
import '../screens/family/expert_booking_screen.dart';
import '../screens/family/expert_booking_confirmation_screen.dart';
import '../screens/family/expert_appointments_screen.dart';
import '../screens/family/propose_donation_screen.dart';
import '../screens/family/product_detail_screen.dart';
import '../screens/family/clinical_patient_record_screen.dart';
import '../screens/family/family_notifications_screen.dart';
import '../screens/family/cart_screen.dart';
import '../screens/family/checkout_screen.dart';
import '../screens/family/order_confirmation_screen.dart';
import '../screens/family/child_mode_screen.dart';
import '../screens/family/child_dashboard_screen.dart';
import '../screens/family/child_progress_screen.dart';
import '../screens/family/child_profile_setup_screen.dart';
import '../screens/family/community_member_profile_screen.dart';
import '../screens/family/engagement_dashboard_screen.dart';
import '../screens/family/family_volunteer_profile_screen.dart';
import '../screens/volunteer/volunteer_dashboard_screen.dart';
import '../screens/volunteer/volunteer_shell_screen.dart';
import '../screens/volunteer/volunteer_agenda_screen.dart';
import '../screens/volunteer/volunteer_messages_screen.dart';
import '../screens/volunteer/volunteer_missions_screen.dart';
import '../screens/volunteer/volunteer_mission_itinerary_screen.dart';
import '../screens/volunteer/volunteer_task_accepted_screen.dart';
import '../screens/volunteer/volunteer_notifications_screen.dart';
import '../screens/volunteer/volunteer_family_chat_screen.dart';
import '../screens/volunteer/volunteer_profile_screen.dart';
import '../screens/volunteer/volunteer_mission_report_screen.dart';
import '../screens/volunteer/volunteer_offer_help_screen.dart';
import '../screens/volunteer/volunteer_new_availability_screen.dart';
import '../screens/healthcare/healthcare_shell_screen.dart';
import '../screens/healthcare/healthcare_dashboard_screen.dart';
import '../screens/healthcare/healthcare_patients_screen.dart';
import '../screens/healthcare/healthcare_reports_screen.dart';
import '../screens/healthcare/healthcare_messages_screen.dart';
import '../screens/healthcare/healthcare_care_board_screen.dart';
import '../screens/healthcare/healthcare_planner_screen.dart';
import '../screens/healthcare/healthcare_comparative_screen.dart';
import '../screens/healthcare/healthcare_protocol_editor_screen.dart';
import '../screens/healthcare/healthcare_consultation_screen.dart';
import '../screens/profile/healthcare_profile_screen.dart';
import '../screens/family/create_security_code_screen.dart';
import '../screens/family/sticker_book_screen.dart';
import '../screens/family/game_success_screen.dart';
import '../screens/family/games_selection_screen.dart';
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
    if (AppConstants.isVolunteerRole(role)) return AppConstants.volunteerDashboardRoute;
    if (AppConstants.isOrganizationLeaderRole(role)) return AppConstants.organizationDashboardRoute;
    if (AppConstants.isHealthcareRole(role)) return AppConstants.healthcareDashboardRoute;
    return AppConstants.homeRoute;
  }

  // Rediriger /home vers le bon tableau de bord selon le rôle
  if (location == AppConstants.homeRoute) {
    if (AppConstants.isFamilyRole(role)) return AppConstants.familyDashboardRoute;
    if (AppConstants.isHealthcareRole(role)) return AppConstants.healthcareDashboardRoute;
  }

  // Protéger les routes famille : seul le rôle "family" peut y accéder
  if (location.startsWith(AppConstants.familyRoute) && !AppConstants.isFamilyRole(role)) {
    if (AppConstants.isVolunteerRole(role)) return AppConstants.volunteerDashboardRoute;
    if (AppConstants.isOrganizationLeaderRole(role)) return AppConstants.organizationDashboardRoute;
    return AppConstants.homeRoute;
  }

  // Protéger les routes bénévole : seul le rôle "volunteer" peut y accéder
  if (location.startsWith(AppConstants.volunteerRoute) && !AppConstants.isVolunteerRole(role)) {
    if (AppConstants.isFamilyRole(role)) return AppConstants.familyDashboardRoute;
    if (AppConstants.isOrganizationLeaderRole(role)) return AppConstants.organizationDashboardRoute;
    if (AppConstants.isHealthcareRole(role)) return AppConstants.healthcareDashboardRoute;
    return AppConstants.homeRoute;
  }

  // Protéger les routes healthcare : seul le rôle "healthcare" / "professional" peut y accéder
  if (location.startsWith(AppConstants.healthcareRoute) && !AppConstants.isHealthcareRole(role)) {
    if (AppConstants.isFamilyRole(role)) return AppConstants.familyDashboardRoute;
    if (AppConstants.isVolunteerRole(role)) return AppConstants.volunteerDashboardRoute;
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
    // Secteur Bénévole : shell avec bottom nav (Accueil, Agenda, Messages, Profil)
    GoRoute(
      path: AppConstants.volunteerRoute,
      redirect: (_, state) {
        final path = state.uri.path;
        if (path == AppConstants.volunteerRoute || path == '${AppConstants.volunteerRoute}/') {
          return AppConstants.volunteerDashboardRoute;
        }
        return null;
      },
      routes: [
        GoRoute(
          path: 'family-chat',
          builder: (context, state) => VolunteerFamilyChatScreen.fromState(state),
        ),
        GoRoute(
          path: 'mission-report',
          builder: (context, state) => const VolunteerMissionReportScreen(),
        ),
        GoRoute(
          path: 'offer-help',
          builder: (context, state) => const VolunteerOfferHelpScreen(),
        ),
        GoRoute(
          path: 'new-availability',
          builder: (context, state) => const VolunteerNewAvailabilityScreen(),
        ),
        StatefulShellRoute.indexedStack(
          builder: (context, state, navigationShell) => VolunteerShellScreen(
            navigationShell: navigationShell,
          ),
          branches: [
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: 'dashboard',
                  builder: (context, state) => const VolunteerDashboardScreen(),
                ),
              ],
            ),
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: 'agenda',
                  builder: (context, state) => const VolunteerAgendaScreen(),
                ),
              ],
            ),
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: 'missions',
                  builder: (context, state) => const VolunteerMissionsScreen(),
                ),
                GoRoute(
                  path: 'mission-itinerary',
                  builder: (context, state) => VolunteerMissionItineraryScreen.fromState(state),
                ),
                GoRoute(
                  path: 'task-accepted',
                  builder: (context, state) => VolunteerTaskAcceptedScreen.fromState(state),
                ),
                GoRoute(
                  path: 'notifications',
                  builder: (context, state) => const VolunteerNotificationsScreen(),
                ),
              ],
            ),
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: 'messages',
                  builder: (context, state) => const VolunteerMessagesScreen(),
                ),
              ],
            ),
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: 'profile',
                  builder: (context, state) => const VolunteerProfileScreen(),
                ),
              ],
            ),
          ],
        ),
      ],
    ),
    // Secteur Healthcare : shell avec une seule navbar (Tableau, Patients, Rapports, Messages, Profil)
    GoRoute(
      path: AppConstants.healthcareRoute,
      redirect: (_, state) {
        final path = state.uri.path;
        if (path == AppConstants.healthcareRoute || path == '${AppConstants.healthcareRoute}/') {
          return AppConstants.healthcareDashboardRoute;
        }
        return null;
      },
      routes: [
        GoRoute(
          path: 'care-board',
          builder: (context, state) => HealthcareCareBoardScreen.fromState(state),
        ),
        GoRoute(
          path: 'planner',
          builder: (context, state) => const HealthcarePlannerScreen(),
        ),
        GoRoute(
          path: 'comparative',
          builder: (context, state) => HealthcareComparativeScreen.fromState(state),
        ),
        GoRoute(
          path: 'protocol-editor',
          builder: (context, state) => HealthcareProtocolEditorScreen.fromState(state),
        ),
        GoRoute(
          path: 'consultation',
          builder: (context, state) => HealthcareConsultationScreen.fromState(state),
        ),
        StatefulShellRoute.indexedStack(
          builder: (context, state, navigationShell) => HealthcareShellScreen(
            navigationShell: navigationShell,
          ),
          branches: [
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: 'patients',
                  builder: (context, state) => const HealthcarePatientsScreen(),
                ),
              ],
            ),
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: 'reports',
                  builder: (context, state) => const HealthcareReportsScreen(),
                ),
              ],
            ),
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: 'dashboard',
                  builder: (context, state) => const HealthcareDashboardScreen(),
                ),
              ],
            ),
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: 'messages',
                  builder: (context, state) => const HealthcareMessagesScreen(),
                ),
              ],
            ),
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: 'profile',
                  builder: (context, state) => const HealthcareProfileScreen(),
                ),
              ],
            ),
          ],
        ),
      ],
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
          path: 'basket-sort',
          builder: (context, state) => const BasketSortScreen(),
        ),
        GoRoute(
          path: 'donation-detail',
          builder: (context, state) => DonationDetailScreen.fromState(state),
        ),
        GoRoute(
          path: 'donation-chat',
          builder: (context, state) => DonationChatScreen.fromState(state),
        ),
        GoRoute(
          path: 'expert-booking',
          builder: (context, state) => ExpertBookingScreen.fromState(state),
        ),
        GoRoute(
          path: 'expert-booking-confirmation',
          builder: (context, state) => ExpertBookingConfirmationScreen.fromState(state),
        ),
        GoRoute(
          path: 'expert-appointments',
          builder: (context, state) => const ExpertAppointmentsScreen(),
        ),
        GoRoute(
          path: 'community-member-profile',
          builder: (context, state) => CommunityMemberProfileScreen.fromState(state),
        ),
        GoRoute(
          path: 'engagement-dashboard',
          builder: (context, state) => const EngagementDashboardScreen(),
        ),
        GoRoute(
          path: 'propose-donation',
          builder: (context, state) => const ProposeDonationScreen(),
        ),
        GoRoute(
          path: 'child-profile-setup',
          builder: (context, state) => const ChildProfileSetupScreen(),
        ),
        GoRoute(
          path: 'product-detail',
          builder: (context, state) {
            final extra = state.extra as Map<String, dynamic>?;
            if (extra == null) {
              return const Scaffold(
                body: Center(child: Text('Produit non trouvé')),
              );
            }
            return ProductDetailScreen(
              productId: extra['productId'] as String,
              title: extra['title'] as String,
              price: extra['price'] as String,
              imageUrl: extra['imageUrl'] as String,
              description: extra['description'] as String,
              badge: extra['badge'] as String?,
              badgeColor: extra['badgeColorValue'] != null
                  ? Color(extra['badgeColorValue'] as int)
                  : null,
            );
          },
        ),
        GoRoute(
          path: 'patient-record',
          builder: (context, state) => const ClinicalPatientRecordScreen(),
        ),
        GoRoute(
          path: 'notifications',
          builder: (context, state) => const FamilyNotificationsScreen(),
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
        GoRoute(
          path: 'private-chat',
          builder: (context, state) {
            final id = state.uri.queryParameters['id'] ?? '';
            final name = state.uri.queryParameters['name'] ?? 'Person';
            final imageUrl = state.uri.queryParameters['imageUrl'];
            return FamilyPrivateChatScreen(
              personId: id,
              personName: name,
              personImageUrl: imageUrl?.isEmpty == true ? null : imageUrl,
            );
          },
        ),
        GoRoute(
          path: 'volunteer-profile',
          builder: (context, state) => FamilyVolunteerProfileScreen.fromState(state),
        ),
        GoRoute(
          path: 'cart',
          builder: (context, state) => const CartScreen(),
        ),
        GoRoute(
          path: 'checkout',
          builder: (context, state) => const CheckoutScreen(),
        ),
        GoRoute(
          path: 'child-mode',
          builder: (context, state) => const ChildModeScreen(),
        ),
        GoRoute(
          path: 'child-dashboard',
          builder: (context, state) {
            final extra = state.extra as Map<String, dynamic>?;
            final emotion = extra?['emotion'] as String?;
            return ChildDashboardScreen(selectedEmotion: emotion);
          },
        ),
        GoRoute(
          path: 'child-progress',
          builder: (context, state) => const ChildProgressScreen(),
        ),
        GoRoute(
          path: 'sticker-book',
          builder: (context, state) => const StickerBookScreen(),
        ),
        GoRoute(
          path: 'game-success',
          builder: (context, state) {
            final extra = state.extra as Map<String, dynamic>?;
            final stickerIndex = extra?['stickerIndex'] as int? ?? 0;
            final gameRoute = extra?['gameRoute'] as String?;
            return GameSuccessScreen(stickerIndex: stickerIndex, gameRoute: gameRoute);
          },
        ),
        GoRoute(
          path: 'games',
          builder: (context, state) => const GamesSelectionScreen(),
        ),
        GoRoute(
          path: 'create-security-code',
          builder: (context, state) => const CreateSecurityCodeScreen(),
        ),
        GoRoute(
          path: 'order-confirmation',
          builder: (context, state) {
            final extra = state.extra as Map<String, dynamic>?;
            final orderId = extra?['orderId']?.toString() ?? '12345';
            final address = extra?['address']?.toString() ?? '15 Rue de la Paix, 75002 Paris, France';
            return OrderConfirmationScreen(
              orderId: orderId,
              address: address,
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
