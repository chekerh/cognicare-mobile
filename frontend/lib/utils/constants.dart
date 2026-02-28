class AppConstants {
  // API Configuration
  /// URL du backend - MODE LOCAL (pour tester sans Render)
  static const String productionBaseUrl =
      'https://cognicare-mobile-h4ct.onrender.com';

  /// Par défaut l'app utilise localhost. Pour Render : changez en 'https://cognicare-mobile-h4ct.onrender.com'
  static String get baseUrl {
    const raw = String.fromEnvironment(
      'BASE_URL',
      defaultValue:
          'https://cognicare-mobile-h4ct.onrender.com', // Render (production team) — pour revenir en local: --dart-define=BASE_URL=http://127.0.0.1:3000
    );
    final fromEnv = raw.endsWith('/') ? raw.substring(0, raw.length - 1) : raw;
    return fromEnv;
  }

  // API Endpoints
  static const String signupEndpoint = '/api/v1/auth/signup';
  static const String loginEndpoint = '/api/v1/auth/login';
  static const String profileEndpoint = '/api/v1/auth/profile';
  static const String updateProfileEndpoint = '/api/v1/auth/profile';
  static const String uploadProfilePictureEndpoint =
      '/api/v1/auth/upload-profile-picture';
  static const String authPresenceEndpoint = '/api/v1/auth/presence';
  static const String familyMembersEndpoint = '/api/v1/auth/family-members';
  static String familyMemberEndpoint(String id) =>
      '/api/v1/auth/family-members/$id';

  /// List other family users for starting conversations (GET). Requires JWT.
  static const String usersFamiliesEndpoint = '/api/v1/users/families';

  /// Presence of another user (GET). Requires JWT.
  static String userPresenceEndpoint(String userId) =>
      '/api/v1/users/$userId/presence';

  // Community (feed) endpoints
  static const String communityPostsEndpoint = '/api/v1/community/posts';
  static const String communityPostLikeStatusEndpoint =
      '/api/v1/community/posts/like-status';
  static const String communityUploadPostImageEndpoint =
      '/api/v1/community/upload-post-image';

  // Marketplace
  static const String marketplaceProductsEndpoint =
      '/api/v1/marketplace/products';
  static const String marketplaceMyProductsEndpoint =
      '/api/v1/marketplace/products/mine';
  static String marketplaceProductByIdEndpoint(String id) =>
      '/api/v1/marketplace/products/$id';
  static String marketplaceProductReviewsEndpoint(String id) =>
      '/api/v1/marketplace/products/$id/reviews';
  static const String marketplaceUploadImageEndpoint =
      '/api/v1/marketplace/products/upload-image';

  // Healthcare cabinets (carte Tunisie — cabinets réels hors app)
  static const String healthcareCabinetsEndpoint = '/api/v1/healthcare-cabinets';

  // Donations (Le Cercle du Don)
  static const String donationsEndpoint = '/api/v1/donations';
  static const String donationsUploadImageEndpoint =
      '/api/v1/donations/upload-image';

  // Conversations / Chat
  static const String conversationsInboxEndpoint =
      '/api/v1/conversations/inbox';
  static const String conversationsByParticipantEndpoint =
      '/api/v1/conversations/by-participant';
  static const String conversationsUploadEndpoint =
      '/api/v1/conversations/upload';
  static String conversationsMessagesEndpoint(String id) =>
      '/api/v1/conversations/$id/messages';
  static String conversationsSettingsEndpoint(String id) =>
      '/api/v1/conversations/$id/settings';
  static String conversationsMediaEndpoint(String id) =>
      '/api/v1/conversations/$id/media';
  static String conversationsSearchEndpoint(String id, String q) =>
      '/api/v1/conversations/$id/search?q=${Uri.encodeComponent(q)}';
  static const String usersMeBlockedEndpoint = '/api/v1/users/me/blocked';
  static const String usersMeBlockEndpoint = '/api/v1/users/me/block';
  static String usersMeUnblockEndpoint(String userId) =>
      '/api/v1/users/me/block/$userId';

  // Availabilities (bénévoles)
  static const String availabilitiesEndpoint = '/api/v1/availabilities';
  static const String availabilitiesForFamiliesEndpoint =
      '/api/v1/availabilities/for-families';

  // Children (family profile)
  static const String childrenEndpoint = '/api/v1/children';
  static const String organizationChildrenEndpoint =
      '/api/v1/organization/my-organization/children';
  static const String organizationChildrenWithPlansEndpoint =
      '/api/v1/organization/my-organization/children-with-plans';

  // Volunteers (application + documents)
  static const String volunteerApplicationEndpoint =
      '/api/v1/volunteers/application/me';
  static const String volunteerDocumentsEndpoint =
      '/api/v1/volunteers/application/documents';
  static String volunteerDocumentDeleteEndpoint(int index) =>
      '/api/v1/volunteers/application/documents/$index';
  static const String volunteerCompleteCertificationEndpoint =
      '/api/v1/volunteers/application/complete-certification';
  static const String volunteerCertificationTestEndpoint =
      '/api/v1/volunteers/certification-test';
  static const String volunteerCertificationTestSubmitEndpoint =
      '/api/v1/volunteers/certification-test/submit';
  static const String volunteerCertificationTestInsightsEndpoint =
      '/api/v1/volunteers/certification-test/insights';
  static const String volunteerMyTasksEndpoint = '/api/v1/volunteers/my-tasks';
  static const String volunteerApplicationsAdminEndpoint =
      '/api/v1/volunteers/applications';
  static String volunteerApplicationAdminEndpoint(String id) =>
      '/api/v1/volunteers/applications/$id';
  static String volunteerApplicationReviewEndpoint(String id) =>
      '/api/v1/volunteers/applications/$id/review';

  // Courses (for denied volunteers)
  static const String coursesEndpoint = '/api/v1/courses';
  static String courseEnrollEndpoint(String id) => '/api/v1/courses/$id/enroll';
  static const String coursesMyEnrollmentsEndpoint =
      '/api/v1/courses/my-enrollments';
  static String courseEnrollmentProgressEndpoint(String id) =>
      '/api/v1/courses/enrollments/$id/progress';

  /// Admin: list course enrollments (optional userId filter).
  static const String coursesAdminEnrollmentsEndpoint =
      '/api/v1/courses/admin/enrollments';

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

  // Progress AI (recommendations for specialists)
  static String progressAiChildRecommendationsEndpoint(String childId,
      {String? planType, String? summaryLength, String? focusPlanTypes}) {
    final q = <String>[];
    if (planType != null && planType.isNotEmpty) {
      q.add('planType=${Uri.encodeComponent(planType)}');
    }
    if (summaryLength != null && summaryLength.isNotEmpty) {
      q.add('summaryLength=${Uri.encodeComponent(summaryLength)}');
    }
    if (focusPlanTypes != null && focusPlanTypes.isNotEmpty) {
      q.add('focusPlanTypes=${Uri.encodeComponent(focusPlanTypes)}');
    }
    final suffix = q.isEmpty ? '' : '?${q.join('&')}';
    return '/api/v1/progress-ai/child/$childId/recommendations$suffix';
  }

  static String progressAiFeedbackEndpoint(String recommendationId) =>
      '/api/v1/progress-ai/recommendations/$recommendationId/feedback';
  static const String progressAiAdminSummaryEndpoint =
      '/api/v1/progress-ai/admin/summary';
  static String progressAiOrgSpecialistSummaryEndpoint(String specialistId) =>
      '/api/v1/progress-ai/org/specialist/$specialistId/summary';
  static const String progressAiPreferencesEndpoint =
      '/api/v1/progress-ai/preferences';
  static String progressAiRequestParentFeedbackEndpoint(String childId) =>
      '/api/v1/progress-ai/child/$childId/request-parent-feedback';
  static String progressAiParentSummaryEndpoint(String childId,
          {String period = 'week'}) =>
      '/api/v1/progress-ai/child/$childId/parent-summary?period=$period';
  static String progressAiParentFeedbackEndpoint(String childId) =>
      '/api/v1/progress-ai/child/$childId/parent-feedback';
  static const String progressAiActivitySuggestionsEndpoint =
      '/api/v1/progress-ai/activity-suggestions';

  // Specialized plans (PECS, TEACCH, Skill Tracker, Activity) – for specialists
  static String specializedPlansByChildEndpoint(String childId) =>
      '/api/v1/specialized-plans/child/$childId';
  static String specializedPlansProgressSummaryEndpoint(String childId) =>
      '/api/v1/specialized-plans/child/$childId/progress-summary';

  /// Tableau d'engagement (temps de jeu, activités, badges)
  static const String engagementDashboardEndpoint =
      '/api/v1/engagement/dashboard';
  static String engagementDashboardUrl([String? childId]) => childId == null ||
          childId.isEmpty
      ? engagementDashboardEndpoint
      : '$engagementDashboardEndpoint?childId=${Uri.encodeComponent(childId)}';

  /// Returns a full URL for an image from the API (profile pics, post images).
  /// If [pathOrUrl] is empty, returns ''. If it already starts with 'http', returns as-is.
  /// Otherwise prefixes with [baseUrl] (e.g. /uploads/profiles/xxx → http://host/uploads/profiles/xxx).
  static String fullImageUrl(String pathOrUrl) {
    if (pathOrUrl.isEmpty) return '';
    if (pathOrUrl.startsWith('http')) return pathOrUrl;
    final base = baseUrl.endsWith('/')
        ? baseUrl.substring(0, baseUrl.length - 1)
        : baseUrl;
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
  static const String familyCreateGroupRoute = '/family/create-group';
  static const String familyPrivateChatRoute = '/family/private-chat';
  static const String familyConversationSettingsRoute =
      '/family/conversation-settings';
  static const String familyThemeSelectionRoute = '/family/theme-selection';
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
  static const String familyAddProductRoute = '/family/add-product';
  static const String familyPatientRecordRoute = '/family/patient-record';
  static const String familyNotificationsRoute = '/family/notifications';
  static const String familyExpertBookingRoute = '/family/expert-booking';
  static const String familyExpertBookingConfirmationRoute =
      '/family/expert-booking-confirmation';
  static const String familyExpertAppointmentsRoute =
      '/family/expert-appointments';
  static const String familyCommunityMemberProfileRoute =
      '/family/community-member-profile';
  static const String familyEngagementDashboardRoute =
      '/family/engagement-dashboard';
  static const String familyCartRoute = '/family/cart';
  static const String familyCheckoutRoute = '/family/checkout';
  static const String familyOrderConfirmationRoute =
      '/family/order-confirmation';

  // PayPal
  static const String paypalCreateOrderEndpoint = '/api/v1/paypal/create-order';
  static String paypalOrderStatusEndpoint(String orderId) =>
      '/api/v1/paypal/order-status?orderId=$orderId';

  // Notifications (feed centre de notifications)
  static const String notificationsEndpoint = '/api/v1/notifications';
  static String notificationMarkReadEndpoint(String id) =>
      '/api/v1/notifications/$id/read';
  static const String notificationsReadAllEndpoint =
      '/api/v1/notifications/read-all';
  static const String familyChildProfileSetupRoute =
      '/family/child-profile-setup';
  static const String familyVolunteerProfileRoute = '/family/volunteer-profile';
  static const String familyChildModeRoute = '/family/child-mode';
  static const String familyChildDashboardRoute = '/family/child-dashboard';
  static const String familyChildProgressRoute = '/family/child-progress';
  static const String familyCreateSecurityCodeRoute =
      '/family/create-security-code';
  static const String familyStickerBookRoute = '/family/sticker-book';
  static const String familyGameSuccessRoute = '/family/game-success';
  static const String familyGamesSelectionRoute = '/family/games';
  static const String familyChildDailyRoutineRoute =
      '/family/child-daily-routine';
  static const String familyChildProgressSummaryRoute =
      '/family/child-progress-summary';
  static const String familyCreateReminderRoute = '/family/create-reminder';
  static const String familyMedicineVerificationRoute =
      '/family/medicine-verification';
  static const String familyReminderNotificationRoute =
      '/family/reminder-notification';
  static const String familySettingsRoute = '/family/settings';

  // Volunteer sector routes (JWT-protected, role: volunteer)
  static const String volunteerRoute = '/volunteer';
  static const String volunteerDashboardRoute = '/volunteer/dashboard';
  static const String volunteerAgendaRoute = '/volunteer/agenda';
  static const String volunteerMissionsRoute = '/volunteer/missions';
  static const String volunteerMissionItineraryRoute =
      '/volunteer/mission-itinerary';
  static const String volunteerTaskAcceptedRoute = '/volunteer/task-accepted';
  static const String volunteerNotificationsRoute = '/volunteer/notifications';
  static const String volunteerMessagesRoute = '/volunteer/messages';
  static const String volunteerFamilyChatRoute = '/volunteer/family-chat';
  static const String volunteerPrivateChatRoute = '/volunteer/private-chat';
  static const String volunteerProfileRoute = '/volunteer/profile';
  static const String volunteerMissionReportRoute = '/volunteer/mission-report';
  static const String volunteerOfferHelpRoute = '/volunteer/offer-help';
  static const String volunteerNewAvailabilityRoute =
      '/volunteer/new-availability';
  static const String volunteerApplicationRoute = '/volunteer/application';
  static const String volunteerCertificationTestRoute =
      '/volunteer/certification-test';
  static const String volunteerFormationsRoute = '/volunteer/formations';
  static const String coursesRoute = '/volunteer/courses';
  static const String specialistRoute = '/specialist';
  static const String specialistDashboardRoute = '/specialist/dashboard';

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
  static const String healthcareProtocolEditorRoute =
      '/healthcare/protocol-editor';
  static const String healthcareConsultationRoute = '/healthcare/consultation';
  static String healthcareProgressAiRecommendationsRoute(String childId) =>
      '/healthcare/ai-recommendations/$childId';

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
  static bool isVolunteerRole(String? role) =>
      role?.toLowerCase() == 'volunteer';
  static bool isOrganizationLeaderRole(String? role) =>
      role?.toLowerCase() == 'organization_leader';
  static bool isHealthcareRole(String? role) {
    if (role == null) return false;
    final r = role.toLowerCase();
    return r == 'healthcare' || r == 'professional' || r == 'doctor';
  }

  static bool isSpecialistRole(String? role) {
    if (role == null) return false;
    final r = role.toLowerCase();
    return r == 'psychologist' ||
        r == 'speech_therapist' ||
        r == 'occupational_therapist' ||
        r == 'volunteer' ||
        r == 'other';
  }
}
