class AppConstants {
  // API Configuration
  static const String baseUrl = 'http://localhost:3000'; // Change to your backend URL

  // API Endpoints
  static const String signupEndpoint = '/api/v1/auth/signup';
  static const String loginEndpoint = '/api/v1/auth/login';
  static const String profileEndpoint = '/api/v1/auth/profile';

  // Storage Keys
  static const String jwtTokenKey = 'jwt_token';
  static const String userDataKey = 'user_data';

  // Route Names
  static const String splashRoute = '/splash';
  static const String onboardingRoute = '/onboarding';
  static const String loginRoute = '/login';
  static const String signupRoute = '/signup';
  static const String homeRoute = '/home';
}