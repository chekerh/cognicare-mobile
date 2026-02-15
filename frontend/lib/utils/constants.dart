class AppConstants {
  // API Configuration
  /// URL du backend utilisée par défaut (sans --dart-define). Modifie ici si tu changes d'hébergeur.
  static const String productionBaseUrl = 'https://cognicare-mobile-h4ct.onrender.com';
  /// Par défaut l'app utilise productionBaseUrl. Pour le dev local : flutter run --dart-define=BASE_URL=http://127.0.0.1:3000
  static String get baseUrl {
    const raw = String.fromEnvironment(
      'BASE_URL',
      defaultValue: 'https://cognicare-mobile-h4ct.onrender.com',
    );
    final fromEnv = raw.endsWith('/') ? raw.substring(0, raw.length - 1) : raw;
    return fromEnv;
  }

  // API Endpoints
  static const String signupEndpoint = '/api/v1/auth/signup';
  static const String loginEndpoint = '/api/v1/auth/login';
  static const String profileEndpoint = '/api/v1/auth/profile';
  static const String updateProfileEndpoint = '/api/v1/auth/profile';
  static const String uploadProfilePictureEndpoint = '/api/v1/auth/upload-profile-picture';
  static const String authPresenceEndpoint = '/api/v1/auth/presence';
  static const String familyMembersEndpoint = '/api/v1/auth/family-members';
  static String familyMemberEndpoint(String id) => '/api/v1/auth/family-members/$id';

  /// Presence of another user (GET). Requires JWT.
  static String userPresenceEndpoint(String userId) => '/api/v1/users/$userId/presence';

  // Community (feed) endpoints
  static const String communityPostsEndpoint = '/api/v1/community/posts';
  static const String communityPostLikeStatusEndpoint = '/api/v1/community/posts/like-status';
  static const String communityUploadPostImageEndpoint = '/api/v1/community/upload-post-image';

  // Marketplace
  static const String marketplaceProductsEndpoint = '/api/v1/marketplace/products';

  // Donations (Le Cercle du Don)
  static const String donationsEndpoint = '/api/v1/donations';
  static const String donationsUploadImageEndpoint = '/api/v1/donations/upload-image';

  // Conversations / Chat
  static const String conversationsInboxEndpoint = '/api/v1/conversations/inbox';
  static const String conversationsByParticipantEndpoint = '/api/v1/conversations/by-participant';
  static const String conversationsUploadEndpoint = '/api/v1/conversations/upload';
  static String conversationsMessagesEndpoint(String id) => '/api/v1/conversations/$id/messages';

  // Availabilities (bénévoles)
  static const String availabilitiesEndpoint = '/api/v1/availabilities';
  static const String availabilitiesForFamiliesEndpoint = '/api/v1/availabilities/for-families';

  // Children (family profile)
  static const String childrenEndpoint = '/api/v1/children';

  // Volunteers (application + documents)
  static const String volunteerApplicationEndpoint = '/api/v1/volunteers/application/me';
  static const String volunteerDocumentsEndpoint = '/api/v1/volunteers/application/documents';
  static String volunteerDocumentDeleteEndpoint(int index) =>
      '/api/v1/volunteers/application/documents/$index';
  static const String volunteerApplicationsAdminEndpoint = '/api/v1/volunteers/applications';
  static String volunteerApplicationAdminEndpoint(String id) =>
      '/api/v1/volunteers/applications/$id';
  static String volunteerApplicationReviewEndpoint(String id) =>
      '/api/v1/volunteers/applications/$id/review';

  // Courses (for denied volunteers)
  static const String coursesEndpoint = '/api/v1/courses';
  static String courseEnrollEndpoint(String id) => '/api/v1/courses/$id/enroll';
  static const String coursesMyEnrollmentsEndpoint = '/api/v1/courses/my-enrollments';
  static String courseEnrollmentProgressEndpoint(String id) =>
      '/api/v1/courses/enrollments/$id/progress';
  /// Admin: list course enrollments (optional userId filter).
  static const String coursesAdminEnrollmentsEndpoint = '/api/v1/courses/admin/enrollments';

  // Nutrition & Reminders
  static const String nutritionPlansEndpoint = '/api/v1/nutrition/plans';
  static String nutritionPlansByChildEndpoint(String childId) =>
      '/api/v1/nutrition/plans/child/$childId';
  static String nutritionPlanEndpoint(String planId) =>
      '/api/v1/nutrition/plans/$planId';
  static const String remindersEndpoint = '/api/v1/reminders';
  static String remindersByChildEndpoint(String childId) =>
      '/api/v1/reminders/child/$childId';
  static String todayRemindersByChildEndpoint(String childId) =>
      '/api/v1/reminders/child/$childId/today';
  static String reminderEndpoint(String reminderId) =>
      '/api/v1/reminders/$reminderId';
  static const String completeTaskEndpoint = '/api/v1/reminders/complete';
  static String reminderStatsEndpoint(String childId, {int days = 7}) =>
      '/api/v1/reminders/child/$childId/stats?days=$days';

  /// Tableau d'engagement (temps de jeu, activités, badges)
  static const String engagementDashboardEndpoint = '/api/v1/engagement/dashboard';
  static String engagementDashboardUrl([String? childId]) =>
      childId == null || childId.isEmpty
          ? engagementDashboardEndpoint
          : '$engagementDashboardEndpoint?childId=${Uri.encodeComponent(childId)}';

  /// Returns a full URL for an image from the API (profile pics, post images).
  /// If [pathOrUrl] is empty, returns ''. If it already starts with 'http', returns as-is.
  /// Otherwise prefixes with [baseUrl] (e.g. /uploads/profiles/xxx → http://host/uploads/profiles/xxx).
  static String fullImageUrl(String pathOrUrl) {
    if (pathOrUrl.isEmpty) return '';
    if (pathOrUrl.startsWith('http')) return pathOrUrl;
    final base = baseUrl.endsWith('/') ? baseUrl.substring(0, baseUrl.length - 1) : baseUrl;
    return pathOrUrl.startsWith('/') ? '$base$pathOrUrl' : '$base/$pathOrUrl';
  }

  // Storage Keys
  static const String jwtTokenKey = 'jwt_token';
  static const String userDataKey = 'user_data';

  // Route Names
  static const String splashRoute = '/splash';
  static const String languageSelectionRoute = '/language-selection';
  static const String onboardingRoute = '/onboarding';
  static const String loginRoute = '/login';
  static const String signupRoute = '/signup';
  static const String callRoute = '/call';
  static const String forgotPasswordRoute = '/forgot-password';
  static const String homeRoute = '/home';
  static const String organizationDashboardRoute = '/organization-dashboard';
  static const String staffManagementRoute = '/organization/staff';

  // Family sector routes (JWT-protected, role: family)
  static const String familyRoute = '/family';
  static const String familyDashboardRoute = '/family/dashboard';
  static const String familyFeedRoute = '/family/feed';
  static const String familyFamiliesRoute = '/family/families';
  static const String familyGroupChatRoute = '/family/group-chat';
  static const String familyPrivateChatRoute = '/family/private-chat';
  static const String familyMarketRoute = '/family/market';
  static const String familyProfileRoute = '/family/profile';
  static const String familyCreatePostRoute = '/family/create-post';
  static const String familyMatchingGameRoute = '/family/matching-game';
  static const String familyShapeSortingRoute = '/family/shape-sorting';
  static const String familyStarTracerRoute = '/family/star-tracer';
  static const String familyBasketSortRoute = '/family/basket-sort';
  static const String familyDonationDetailRoute = '/family/donation-detail';
  static const String familyDonationChatRoute = '/family/donation-chat';
  static const String familyProposeDonationRoute = '/family/propose-donation';
  static const String familyProductDetailRoute = '/family/product-detail';
  static const String familyPatientRecordRoute = '/family/patient-record';
  static const String familyNotificationsRoute = '/family/notifications';
  static const String familyExpertBookingRoute = '/family/expert-booking';
  static const String familyExpertBookingConfirmationRoute = '/family/expert-booking-confirmation';
  static const String familyExpertAppointmentsRoute = '/family/expert-appointments';
  static const String familyCommunityMemberProfileRoute = '/family/community-member-profile';
  static const String familyEngagementDashboardRoute = '/family/engagement-dashboard';
  static const String familyCartRoute = '/family/cart';
  static const String familyCheckoutRoute = '/family/checkout';
  static const String familyOrderConfirmationRoute = '/family/order-confirmation';
  static const String familyChildProfileSetupRoute = '/family/child-profile-setup';
  static const String familyVolunteerProfileRoute = '/family/volunteer-profile';
  static const String familyChildModeRoute = '/family/child-mode';
  static const String familyChildDashboardRoute = '/family/child-dashboard';
  static const String familyChildProgressRoute = '/family/child-progress';
  static const String familyCreateSecurityCodeRoute = '/family/create-security-code';
  static const String familyStickerBookRoute = '/family/sticker-book';
  static const String familyGameSuccessRoute = '/family/game-success';
  static const String familyGamesSelectionRoute = '/family/games';
  static const String familyChildDailyRoutineRoute = '/family/child-daily-routine';
  static const String familyCreateReminderRoute = '/family/create-reminder';
  static const String familyMedicineVerificationRoute = '/family/medicine-verification';
  static const String familyReminderNotificationRoute = '/family/reminder-notification';
  static const String familySettingsRoute = '/family/settings';

  // Volunteer sector routes (JWT-protected, role: volunteer)
  static const String volunteerRoute = '/volunteer';
  static const String volunteerDashboardRoute = '/volunteer/dashboard';
  static const String volunteerAgendaRoute = '/volunteer/agenda';
  static const String volunteerMissionsRoute = '/volunteer/missions';
  static const String volunteerMissionItineraryRoute = '/volunteer/mission-itinerary';
  static const String volunteerTaskAcceptedRoute = '/volunteer/task-accepted';
  static const String volunteerNotificationsRoute = '/volunteer/notifications';
  static const String volunteerMessagesRoute = '/volunteer/messages';
  static const String volunteerFamilyChatRoute = '/volunteer/family-chat';
  static const String volunteerPrivateChatRoute = '/volunteer/private-chat';
  static const String volunteerProfileRoute = '/volunteer/profile';
  static const String volunteerMissionReportRoute = '/volunteer/mission-report';
  static const String volunteerOfferHelpRoute = '/volunteer/offer-help';
  static const String volunteerNewAvailabilityRoute = '/volunteer/new-availability';
  static const String volunteerApplicationRoute = '/volunteer/application';
  static const String volunteerFormationsRoute = '/volunteer/formations';
  static const String coursesRoute = '/volunteer/courses';

  // Healthcare professional sector routes (JWT-protected, role: healthcare)
  static const String healthcareRoute = '/healthcare';
  static const String healthcareDashboardRoute = '/healthcare/dashboard';
  static const String healthcarePatientsRoute = '/healthcare/patients';
  static const String healthcareReportsRoute = '/healthcare/reports';
  static const String healthcareMessagesRoute = '/healthcare/messages';
  static const String healthcareProfileRoute = '/healthcare/profile';
  static const String healthcareCareBoardRoute = '/healthcare/care-board';
  static const String healthcarePlannerRoute = '/healthcare/planner';
  static const String healthcareComparativeRoute = '/healthcare/comparative';
  static const String healthcareProtocolEditorRoute = '/healthcare/protocol-editor';
  static const String healthcareConsultationRoute = '/healthcare/consultation';

  // Public routes (no JWT required)
  static const List<String> publicRoutes = [
    splashRoute,
    languageSelectionRoute,
    onboardingRoute,
    loginRoute,
    signupRoute,
    forgotPasswordRoute,
  ];

  /// Comparaison insensible à la casse (backend peut renvoyer "family", "Family", "FAMILY").
  static bool isFamilyRole(String? role) => role?.toLowerCase() == 'family';
  static bool isVolunteerRole(String? role) => role?.toLowerCase() == 'volunteer';
  static bool isOrganizationLeaderRole(String? role) =>
      role?.toLowerCase() == 'organization_leader';
  static bool isHealthcareRole(String? role) {
    if (role == null) return false;
    final r = role.toLowerCase();
    return r == 'healthcare' || r == 'professional' || r == 'doctor';
  }
}