import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_fr.dart';
import 'app_localizations_ar.dart';

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure the following is an entry in your pubspec.yaml:
/// ```yaml
/// flutter:
///   generate: true
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu of the Value field.
/// This list should be consistent with the languages listed in the
/// AppLocalizations.supportedLocales property.
abstract class AppLocalizations {
  AppLocalizations(String locale) : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate = _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates = <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('fr'),
    Locale('ar')
  ];

  /// App title
  String get appTitle;

  /// Splash screen
  String get splashTagline;

  /// Onboarding
  String get onboardingWelcomeTitle;
  String get onboardingWelcomeDescription;
  String get onboardingFeaturesTitle;
  String get onboardingFeaturesDescription;
  String get onboardingAccessibilityTitle;
  String get onboardingAccessibilityDescription;
  String get onboardingStartButton;

  /// Authentication
  String get loginTitle;
  String get loginSubtitle;
  String get signupTitle;
  String get signupSubtitle;
  String get emailLabel;
  String get passwordLabel;
  String get confirmPasswordLabel;
  String get fullNameLabel;
  String get phoneLabel;
  String get roleLabel;
  String get loginButton;
  String get signupButton;
  String get createAccountLink;
  String get alreadyHaveAccountLink;
  String get termsAgreement;
  String get acceptTerms;

  /// Navigation
  String get nextButton;
  String get skipButton;
  String get backButton;

  /// Validation messages
  String get emailRequired;
  String get emailInvalid;
  String get passwordRequired;
  String get passwordTooShort;
  String get confirmPasswordRequired;
  String get passwordsDontMatch;
  String get fullNameRequired;
  String get phoneInvalid;
  String get termsRequired;

  /// Error messages
  String get networkError;
  String get invalidCredentials;
  String get emailAlreadyExists;
  String get unknownError;
  String get signupSuccess;

  /// Roles
  String get roleFamily;
  String get roleDoctor;
  String get roleVolunteer;

  /// Profile
  String get profileTitle;
  String get accountInformation;
  String get accountSettings;
  String get emailInfo;
  String get phoneInfo;
  String get memberSince;
  String get notProvided;
  String get changePassword;
  String get changeEmail;
  String get changeLanguage;
  String get logout;
  String get logoutConfirmTitle;
  String get logoutConfirmMessage;
  String get cancel;
  String get errorLoadingProfile;
  String get retry;
  String get selectLanguage;
  String get languageChanged;
  String get welcomeToApp;
  String get selectLanguageDescription;
  String get resetPasswordTitle;
  String get enterEmailStepTitle;
  String get enterEmailStepSubtitle;
  String get codeSentSuccess;
  String get verifyCodeStepTitle;
  String get checkEmailStepSubtitle;
  String get codeVerifiedSuccess;
  String get createNewPasswordStepTitle;
  String get createNewPasswordStepSubtitle;
  String get passwordResetSuccess;
  String get resendCodeButton;
  String get verificationCodeLabel;
  String get newPasswordLabel;
  String get sendCodeButton;
  String get verifyCodeButton;
  String get emailVerifiedMessage;
  String get codeSentButton;
  String get verifyButton;
  String get resendButton;
  String get codeInvalid;
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>['ar', 'en', 'fr'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {

  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ar': return AppLocalizationsAr();
    case 'en': return AppLocalizationsEn();
    case 'fr': return AppLocalizationsFr();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.'
  );
}