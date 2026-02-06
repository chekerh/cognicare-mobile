class AppConstants {
  // API Configuration
  // Sur simulateur: défaut 127.0.0.1. Sur appareil réel: flutter run --dart-define=BASE_URL=http://VOTRE_IP:3000
  static const String baseUrl = String.fromEnvironment(
    'BASE_URL',
    defaultValue: 'http://127.0.0.1:3000',
  );

  // API Endpoints
  static const String signupEndpoint = '/api/v1/auth/signup';
  static const String loginEndpoint = '/api/v1/auth/login';
  static const String profileEndpoint = '/api/v1/auth/profile';
  static const String updateProfileEndpoint = '/api/v1/auth/profile';
  static const String uploadProfilePictureEndpoint = '/api/v1/auth/upload-profile-picture';

  // Community (feed) endpoints
  static const String communityPostsEndpoint = '/api/v1/community/posts';
  static const String communityPostLikeStatusEndpoint = '/api/v1/community/posts/like-status';
  static const String communityUploadPostImageEndpoint = '/api/v1/community/upload-post-image';

  // Storage Keys
  static const String jwtTokenKey = 'jwt_token';
  static const String userDataKey = 'user_data';

  // Route Names
  static const String splashRoute = '/splash';
  static const String languageSelectionRoute = '/language-selection';
  static const String onboardingRoute = '/onboarding';
  static const String loginRoute = '/login';
  static const String signupRoute = '/signup';
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
  static const String familyMarketRoute = '/family/market';
  static const String familyProfileRoute = '/family/profile';
  static const String familyCreatePostRoute = '/family/create-post';
  static const String familyMatchingGameRoute = '/family/matching-game';
  static const String familyShapeSortingRoute = '/family/shape-sorting';
  static const String familyStarTracerRoute = '/family/star-tracer';
  static const String familyProductDetailRoute = '/family/product-detail';

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
  static bool isOrganizationLeaderRole(String? role) =>
      role?.toLowerCase() == 'organization_leader';
}