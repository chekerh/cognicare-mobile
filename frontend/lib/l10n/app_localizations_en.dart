import 'app_localizations.dart';

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'CogniCare';

  @override
  String get splashTagline => 'A personalized path to cognitive progress';

  @override
  String get onboardingWelcomeTitle => 'Welcome to CogniCare';

  @override
  String get onboardingWelcomeDescription => 'Your journey to better cognitive health starts here. We provide personalized care and support for your cognitive development.';

  @override
  String get onboardingFeaturesTitle => 'Personalized Features';

  @override
  String get onboardingFeaturesDescription => 'Access tailored exercises, track your progress, and connect with healthcare professionals who understand your needs.';

  @override
  String get onboardingAccessibilityTitle => 'Accessible for Everyone';

  @override
  String get onboardingAccessibilityDescription => 'Our app is designed with accessibility in mind, supporting multiple languages and ensuring everyone can benefit from cognitive care.';

  @override
  String get onboardingStartButton => 'Get Started';

  @override
  String get loginTitle => 'Welcome Back';

  @override
  String get loginSubtitle => 'Sign in to continue your cognitive journey';

  @override
  String get signupTitle => 'Create Account';

  @override
  String get signupSubtitle => 'Join CogniCare to start your personalized cognitive care journey';

  @override
  String get emailLabel => 'Email';

  @override
  String get passwordLabel => 'Password';

  @override
  String get confirmPasswordLabel => 'Confirm Password';

  @override
  String get fullNameLabel => 'Full Name';

  @override
  String get phoneLabel => 'Phone (Optional)';

  @override
  String get roleLabel => 'I am a';

  @override
  String get loginButton => 'Login';

  @override
  String get signupButton => 'Create Account';

  @override
  String get createAccountLink => 'Create an account';

  @override
  String get alreadyHaveAccountLink => 'Already have an account?';

  @override
  String get termsAgreement => 'I agree to the Terms of Service and Privacy Policy';

  @override
  String get acceptTerms => 'Accept Terms';

  @override
  String get nextButton => 'Next';

  @override
  String get skipButton => 'Skip';

  @override
  String get backButton => 'Back';

  @override
  String get emailRequired => 'Email is required';

  @override
  String get emailInvalid => 'Please enter a valid email address';

  @override
  String get passwordRequired => 'Password is required';

  @override
  String get passwordTooShort => 'Password must be at least 6 characters';

  @override
  String get confirmPasswordRequired => 'Please confirm your password';

  @override
  String get passwordsDontMatch => 'Passwords do not match';

  @override
  String get fullNameRequired => 'Full name is required';

  @override
  String get phoneInvalid => 'Please enter a valid phone number';

  @override
  String get termsRequired => 'You must accept the terms and conditions';

  @override
  String get networkError => 'Network error. Please check your connection and try again.';

  @override
  String get invalidCredentials => 'Invalid email or password';

  @override
  String get emailAlreadyExists => 'An account with this email already exists';

  @override
  String get unknownError => 'An unexpected error occurred. Please try again.';

  @override
  String get roleFamily => 'Family Member';

  @override
  String get roleDoctor => 'Healthcare Professional';

  @override
  String get roleVolunteer => 'Volunteer';
}