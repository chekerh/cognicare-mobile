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
import '../screens/family/create_group_screen.dart';
import '../screens/family/conversation_settings_screen.dart';
import '../screens/family/theme_selection_screen.dart';
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
import '../screens/family/add_product_screen.dart';
import '../screens/family/product_detail_screen.dart';
import '../screens/family/integration_order_form_screen.dart';
import '../models/healthcare_cabinet.dart';
import '../screens/family/cabinet_route_screen.dart';
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
import '../screens/family/child_daily_routine_screen.dart';
import '../screens/family/child_progress_summary_screen.dart';
import '../screens/family/create_reminder_screen.dart';
import '../screens/family/family_calendar_screen.dart';
import '../screens/family/medicine_verification_screen.dart';
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
import '../screens/volunteer/volunteer_application_screen.dart';
import '../screens/volunteer/volunteer_courses_screen.dart';
import '../screens/volunteer/volunteer_formations_hub_screen.dart';
import '../screens/volunteer/volunteer_certification_test_screen.dart';
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
import '../screens/healthcare/progress_ai_recommendations_screen.dart';
import '../screens/profile/healthcare_profile_screen.dart';
import '../screens/profile/settings_screen.dart';
import '../screens/family/create_security_code_screen.dart';
import '../screens/family/sticker_book_screen.dart';
import '../screens/family/game_success_screen.dart';
import '../screens/family/games_selection_screen.dart';
import '../screens/profile/profile_screen.dart';
import '../screens/call/call_screen.dart';
import '../services/call_service.dart';
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

  // Route d'appel : la famille peut initier ; bénévoles et autres doivent pouvoir ouvrir
  // l'écran pour recevoir un appel entrant. Pas de redirection pour /call.
  if (location == AppConstants.callRoute) return null;

  // Utilisateur connecté : redirection selon la route et le rôle
  if (location == AppConstants.loginRoute ||
      location == AppConstants.signupRoute) {
    if (AppConstants.isFamilyRole(role)) {
      return AppConstants.familyDashboardRoute;
    }
    if (AppConstants.isVolunteerRole(role)) {
      return AppConstants.volunteerFormationsRoute;
    }
    if (AppConstants.isOrganizationLeaderRole(role)) {
      return AppConstants.organizationDashboardRoute;
    }
    if (AppConstants.isHealthcareRole(role)) {
      return AppConstants.healthcareDashboardRoute;
    }
    if (AppConstants.isSpecialistRole(role)) {
      return AppConstants.volunteerFormationsRoute;
    }
    return AppConstants.homeRoute;
  }

  // Rediriger /home vers le bon tableau de bord selon le rôle
  if (location == AppConstants.homeRoute) {
    if (AppConstants.isFamilyRole(role)) {
      return AppConstants.familyDashboardRoute;
    }
    if (AppConstants.isHealthcareRole(role)) {
      return AppConstants.healthcareDashboardRoute;
    }
    if (AppConstants.isSpecialistRole(role)) {
      return AppConstants.volunteerDashboardRoute;
    }
  }

  // Protéger les routes famille : seul le rôle "family" peut y accéder
  if (location.startsWith(AppConstants.familyRoute) &&
      !AppConstants.isFamilyRole(role)) {
    if (AppConstants.isVolunteerRole(role)) {
      return AppConstants.volunteerDashboardRoute;
    }
    if (AppConstants.isOrganizationLeaderRole(role)) {
      return AppConstants.organizationDashboardRoute;
    }
    return AppConstants.homeRoute;
  }

  // Protéger les routes bénévole : seul le rôle "volunteer" OU specialist peut y accéder
  if (location.startsWith(AppConstants.volunteerRoute) &&
      !AppConstants.isVolunteerRole(role) &&
      !AppConstants.isSpecialistRole(role)) {
    if (AppConstants.isFamilyRole(role)) {
      return AppConstants.familyDashboardRoute;
    }
    if (AppConstants.isOrganizationLeaderRole(role)) {
      return AppConstants.organizationDashboardRoute;
    }
    if (AppConstants.isHealthcareRole(role)) {
      return AppConstants.healthcareDashboardRoute;
    }
    return AppConstants.homeRoute;
  }

  // Protéger les routes healthcare : seul le rôle "healthcare" / "professional" peut y accéder
  if (location.startsWith(AppConstants.healthcareRoute) &&
      !AppConstants.isHealthcareRole(role)) {
    if (AppConstants.isFamilyRole(role)) {
      return AppConstants.familyDashboardRoute;
    }
    if (AppConstants.isVolunteerRole(role)) {
      return AppConstants.volunteerDashboardRoute;
    }
    if (AppConstants.isOrganizationLeaderRole(role)) {
      return AppConstants.organizationDashboardRoute;
    }
    if (AppConstants.isHealthcareRole(role)) {
      return AppConstants.healthcareDashboardRoute;
    }
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
        path: AppConstants.callRoute,
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          if (extra != null) {
            return CallScreen(
              channelId: extra['channelId'] as String? ?? '',
              remoteUserId: extra['remoteUserId'] as String? ?? '',
              remoteUserName: extra['remoteUserName'] as String? ?? 'Appelant',
              remoteImageUrl: extra['remoteImageUrl'] as String?,
              isVideo: extra['isVideo'] as bool? ?? false,
              isIncoming: extra['isIncoming'] as bool? ?? false,
              incomingCall: extra['incomingCall'] as IncomingCall?,
            );
          }
          final q = state.uri.queryParameters;
          return CallScreen(
            channelId: q['channelId'] ?? '',
            remoteUserId: q['remoteUserId'] ?? '',
            remoteUserName: q['remoteUserName'] ?? 'Appelant',
            remoteImageUrl: q['remoteImageUrl'],
            isVideo: q['isVideo'] == 'true',
            isIncoming: q['isIncoming'] == 'true',
            incomingCall: null,
          );
        },
      ),
      GoRoute(
        path: AppConstants.homeRoute,
        builder: (context, state) => const HomeContainerScreen(),
      ),
      GoRoute(
        path: AppConstants.organizationDashboardRoute,
        builder: (context, state) => const OrganizationDashboardScreen(),
      ),
      // Secteur Bénévole : shell avec bottom nav (Accueil, Agenda, Formations, Messages, Profil)
      GoRoute(
        path: AppConstants.volunteerRoute,
        redirect: (_, state) {
          final path = state.uri.path;
          if (path == AppConstants.volunteerRoute ||
              path == '${AppConstants.volunteerRoute}/') {
            return AppConstants.volunteerFormationsRoute;
          }
          return null;
        },
        routes: [
          GoRoute(
            path: 'family-chat',
            builder: (context, state) =>
                VolunteerFamilyChatScreen.fromState(state),
          ),
          GoRoute(
            path: 'private-chat',
            builder: (context, state) {
              final id = state.uri.queryParameters['id'] ?? '';
              final name = state.uri.queryParameters['name'] ?? 'Person';
              final imageUrl = state.uri.queryParameters['imageUrl'];
              final conversationId =
                  state.uri.queryParameters['conversationId'];
              return FamilyPrivateChatScreen(
                personId: id,
                personName: name,
                personImageUrl: imageUrl?.isEmpty == true ? null : imageUrl,
                conversationId:
                    conversationId?.isEmpty == true ? null : conversationId,
              );
            },
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
          GoRoute(
            path: 'application',
            builder: (context, state) => const VolunteerApplicationScreen(),
          ),
          GoRoute(
            path: 'certification-test',
            builder: (context, state) =>
                const VolunteerCertificationTestScreen(),
          ),
          GoRoute(
            path: 'courses',
            builder: (context, state) => const VolunteerCoursesScreen(),
          ),
          GoRoute(
            path: 'missions',
            builder: (context, state) => const VolunteerMissionsScreen(),
          ),
          GoRoute(
            path: 'mission-itinerary',
            builder: (context, state) =>
                VolunteerMissionItineraryScreen.fromState(state),
          ),
          GoRoute(
            path: 'task-accepted',
            builder: (context, state) =>
                VolunteerTaskAcceptedScreen.fromState(state),
          ),
          GoRoute(
            path: 'notifications',
            builder: (context, state) => const VolunteerNotificationsScreen(),
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
                    builder: (context, state) =>
                        const VolunteerDashboardScreen(),
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
                    path: 'formations',
                    builder: (context, state) =>
                        const VolunteerFormationsHubScreen(),
                  ),
                ],
              ),
              StatefulShellBranch(
                routes: [
                  GoRoute(
                    path: 'messages',
                    builder: (context, state) =>
                        const VolunteerMessagesScreen(),
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
          if (path == AppConstants.healthcareRoute ||
              path == '${AppConstants.healthcareRoute}/') {
            return AppConstants.healthcareDashboardRoute;
          }
          return null;
        },
        routes: [
          GoRoute(
            path: 'care-board',
            builder: (context, state) =>
                HealthcareCareBoardScreen.fromState(state),
          ),
          GoRoute(
            path: 'planner',
            builder: (context, state) => const HealthcarePlannerScreen(),
          ),
          GoRoute(
            path: 'comparative',
            builder: (context, state) =>
                HealthcareComparativeScreen.fromState(state),
          ),
          GoRoute(
            path: 'protocol-editor',
            builder: (context, state) =>
                HealthcareProtocolEditorScreen.fromState(state),
          ),
          GoRoute(
            path: 'consultation',
            builder: (context, state) =>
                HealthcareConsultationScreen.fromState(state),
          ),
          GoRoute(
            path: 'ai-recommendations/:childId',
            builder: (context, state) {
              final childId = state.pathParameters['childId'] ?? '';
              final extra = state.extra as Map<String, dynamic>?;
              return ProgressAiRecommendationsScreen(
                childId: childId,
                childName: extra?['childName'] as String?,
              );
            },
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
                    builder: (context, state) =>
                        const HealthcarePatientsScreen(),
                  ),
                ],
              ),
              StatefulShellBranch(
                routes: [
                  GoRoute(
                    path: 'reports',
                    builder: (context, state) =>
                        const HealthcareReportsScreen(),
                  ),
                ],
              ),
              StatefulShellBranch(
                routes: [
                  GoRoute(
                    path: 'dashboard',
                    builder: (context, state) =>
                        const HealthcareDashboardScreen(),
                  ),
                ],
              ),
              StatefulShellBranch(
                routes: [
                  GoRoute(
                    path: 'messages',
                    builder: (context, state) =>
                        const HealthcareMessagesScreen(),
                  ),
                ],
              ),
              StatefulShellBranch(
                routes: [
                  GoRoute(
                    path: 'profile',
                    builder: (context, state) =>
                        const HealthcareProfileScreen(),
                  ),
                ],
              ),
            ],
          ),
          GoRoute(
            path: 'chat',
            builder: (context, state) {
              final extra = state.extra as Map<String, String?>?;
              return FamilyPrivateChatScreen(
                personId: extra?['id'] ?? '',
                personName: extra?['name'] ?? 'Conversation',
                personImageUrl: extra?['imageUrl'],
                conversationId: extra?['conversationId'],
              );
            },
          ),
        ],
      ),
      // Secteur Famille : shell avec bottom nav (Feed, Families, +, Market, Profile)
      GoRoute(
        path: AppConstants.familyRoute,
        redirect: (_, state) {
          final path = state.uri.path;
          if (path == AppConstants.familyRoute ||
              path == '${AppConstants.familyRoute}/') {
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
            builder: (context, state) {
              final extra = state.extra as Map<String, dynamic>?;
              final inSequence = extra?['inSequence'] as bool? ?? false;
              return MatchingGameScreen(inSequence: inSequence);
            },
          ),
          GoRoute(
            path: 'shape-sorting',
            builder: (context, state) {
              final extra = state.extra as Map<String, dynamic>?;
              final inSequence = extra?['inSequence'] as bool? ?? false;
              return ShapeSortingScreen(inSequence: inSequence);
            },
          ),
          GoRoute(
            path: 'star-tracer',
            builder: (context, state) {
              final extra = state.extra as Map<String, dynamic>?;
              final inSequence = extra?['inSequence'] as bool? ?? false;
              return StarTracerScreen(inSequence: inSequence);
            },
          ),
          GoRoute(
            path: 'basket-sort',
            builder: (context, state) {
              final extra = state.extra as Map<String, dynamic>?;
              final inSequence = extra?['inSequence'] as bool? ?? false;
              return BasketSortScreen(inSequence: inSequence);
            },
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
            builder: (context, state) =>
                ExpertBookingConfirmationScreen.fromState(state),
          ),
          GoRoute(
            path: 'expert-appointments',
            builder: (context, state) => const ExpertAppointmentsScreen(),
          ),
          GoRoute(
            path: 'community-member-profile',
            builder: (context, state) =>
                CommunityMemberProfileScreen.fromState(state),
          ),
          GoRoute(
            path: 'engagement-dashboard',
            builder: (context, state) => EngagementDashboardScreen(
              childId: state.uri.queryParameters['childId'],
            ),
          ),
          GoRoute(
            path: 'propose-donation',
            builder: (context, state) => const ProposeDonationScreen(),
          ),
          GoRoute(
            path: 'add-product',
            builder: (context, state) => const AddProductScreen(),
          ),
          GoRoute(
            path: 'child-profile-setup',
            builder: (context, state) => const ChildProfileSetupScreen(),
          ),
          GoRoute(
            path: 'cabinet-route',
            builder: (context, state) {
              final extra = state.extra as Map<String, dynamic>?;
              if (extra == null || extra['cabinet'] == null) {
                return const Scaffold(
                  body: Center(child: Text('Cabinet non trouvé')),
                );
              }
              return CabinetRouteScreen(
                cabinet: extra['cabinet'] as HealthcareCabinet,
              );
            },
          ),
          GoRoute(
            path: 'integration-order',
            builder: (context, state) {
              return IntegrationOrderFormScreen.fromState(state);
            },
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
                externalUrl: extra['externalUrl'] as String?,
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
              final members =
                  int.tryParse(state.uri.queryParameters['members'] ?? '5') ??
                      5;
              final id = state.uri.queryParameters['id'];
              final isGroup = state.uri.queryParameters['isGroup'] == '1';
              return FamilyGroupChatScreen(
                groupName: name,
                memberCount: members,
                groupId: id?.isEmpty == true ? null : id,
                isGroup: isGroup,
              );
            },
          ),
          GoRoute(
            path: 'create-group',
            builder: (context, state) => const CreateGroupScreen(),
          ),
          GoRoute(
            path: 'private-chat',
            builder: (context, state) {
              final id = state.uri.queryParameters['id'] ?? '';
              final name = state.uri.queryParameters['name'] ?? 'Person';
              final imageUrl = state.uri.queryParameters['imageUrl'];
              final conversationId =
                  state.uri.queryParameters['conversationId'];
              return FamilyPrivateChatScreen(
                personId: id,
                personName: name,
                personImageUrl: imageUrl?.isEmpty == true ? null : imageUrl,
                conversationId:
                    conversationId?.isEmpty == true ? null : conversationId,
              );
            },
          ),
          GoRoute(
            path: 'theme-selection',
            builder: (context, state) => const ThemeSelectionScreen(),
          ),
          GoRoute(
            path: 'conversation-settings',
            builder: (context, state) {
              final title =
                  state.uri.queryParameters['title'] ?? 'Conversation';
              final conversationId =
                  state.uri.queryParameters['conversationId'];
              final personId = state.uri.queryParameters['personId'];
              final groupId = state.uri.queryParameters['groupId'];
              final isGroup = state.uri.queryParameters['isGroup'] == '1';
              final personImageUrl =
                  state.uri.queryParameters['personImageUrl'];
              final memberCount = int.tryParse(
                      state.uri.queryParameters['memberCount'] ?? '0') ??
                  0;
              return ConversationSettingsScreen(
                title: title,
                conversationId:
                    conversationId?.isEmpty == true ? null : conversationId,
                personId: personId?.isEmpty == true ? null : personId,
                groupId: groupId?.isEmpty == true ? null : groupId,
                isGroup: isGroup,
                personImageUrl:
                    personImageUrl?.isEmpty == true ? null : personImageUrl,
                memberCount: memberCount,
              );
            },
          ),
          GoRoute(
            path: 'volunteer-profile',
            builder: (context, state) =>
                FamilyVolunteerProfileScreen.fromState(state),
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
              final milestoneMessage = extra?['milestoneMessage'] as String?;
              return GameSuccessScreen(
                stickerIndex: stickerIndex,
                gameRoute: gameRoute,
                milestoneMessage: milestoneMessage,
              );
            },
          ),
          GoRoute(
            path: 'games',
            builder: (context, state) => const GamesSelectionScreen(),
          ),
          GoRoute(
            path: 'child-daily-routine',
            builder: (context, state) {
              final extra = state.extra as Map<String, dynamic>?;
              final childId = extra?['childId'] as String? ?? '';
              return ChildDailyRoutineScreen(childId: childId);
            },
          ),
          GoRoute(
            path: 'child-progress-summary',
            builder: (context, state) {
              final extra = state.extra as Map<String, dynamic>?;
              final childId = extra?['childId'] as String? ?? '';
              final childName = extra?['childName'] as String?;
              return ChildProgressSummaryScreen(
                childId: childId,
                childName: childName,
              );
            },
          ),
          GoRoute(
            path: 'create-reminder',
            builder: (context, state) {
              final extra = state.extra as Map<String, dynamic>?;
              return CreateReminderScreen(
                childId: extra?['childId'] as String? ?? '',
                childName: extra?['childName'] as String? ?? 'Enfant',
              );
            },
          ),
          GoRoute(
            path: 'calendar',
            builder: (context, state) => const FamilyCalendarScreen(),
          ),
          GoRoute(
            path: 'medicine-verification',
            builder: (context, state) {
              final extra = state.extra as Map<String, dynamic>?;
              return MedicineVerificationScreen(
                reminderId: extra?['reminderId'] as String? ?? '',
                taskTitle: extra?['taskTitle'] as String? ?? 'Take Medicine',
                taskDescription: extra?['taskDescription'] as String?,
              );
            },
          ),
          GoRoute(
            path: 'settings',
            builder: (context, state) => const SettingsScreen(),
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
              final address = extra?['address']?.toString() ??
                  '15 Rue de la Paix, 75002 Paris, France';
              final imageUrl = extra?['imageUrl']?.toString();
              return OrderConfirmationScreen(
                orderId: orderId,
                address: address,
                imageUrl: imageUrl,
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
                    builder: (context, state) =>
                        const FamilyMemberDashboardScreen(),
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
