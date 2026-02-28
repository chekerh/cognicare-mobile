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
  AppLocalizations(String locale)
      : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

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
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
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
  String get phoneLabel;
  String get roleLabel;
  String get loginButton;
  String get signupButton;
  String get createAccountLink;
  String get alreadyHaveAccountLink;
  String get termsAgreement;
  String get acceptTerms;
  String get fullNameLabel;

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
  String get emailNotVerifiedError;
  String get noAccountYet;
  String get forgotPasswordQuestion;

  /// Roles
  String get roleFamily;
  String get roleDoctor;
  String get roleVolunteer;
  String get roleOrganizationLeader;
  String get staffManagement;
  String get totalStaff;
  String get addStaffMember;
  String get welcomeBack;

  /// Profile
  String get profileTitle;
  String get accountInformation;
  String get accountSettings;
  String get emailInfo;
  String get phoneInfo;
  String get memberSince;
  String get notProvided;
  String get changePassword;
  String get chatCamera;
  String get chatGallery;

  String get groupNameRequired;
  String get noConversationSelected;
  String get closeLabel;
  String get blockLabel;
  String get contactBlocked;
  String get cannotDeleteConversation;
  String get deleteConversationTitle;
  String get deleteConversationDesc;
  String get deleteLabel;
  String get conversationDeleted;
  String get pleaseAddChildProfileFirst;
  String get noOtherFamilyToAdd;
  String get voiceMessageReadError;
  String get recordingStartError;
  String get recordingError;

  String get genderBoy;
  String get genderGirl;
  String get genderOther;
  String get sensitivityLow;
  String get sensitivityMedium;
  String get sensitivityHigh;
  String get medCareSpeechTherapist;
  String get medCarePsychomotorTherapist;
  String get medCareOccupationalTherapist;
  String get medCarePediatrician;

  // Specialized Screens
  String get createPostTitle;
  String get postEmptyError;
  String get postSharedSuccess;
  String get postHintText;
  String get postActionGallery;
  String get postActionFeeling;
  String get postActionLocation;
  String get postActionLifeEvent;
  String get postButton;

  String get tagMilestone;
  String get tagTip;
  String get tagQuestion;
  String get tagFeeling;

  String get defaultRoleParent;
  String get defaultDiagnosisMildAutism;
  String get defaultJourneyText;
  String get tagSpeechTherapy;
  String get tagEmotionalSupport;
  String get tagSensoryActivities;
  String get tagSchoolInclusion;
  String get categoryLabel;
  String get privateMessageAction;
  String get followAction;
  String get sectionJourney;
  String get sectionMainTopics;
  String get statsPosts;
  String get statsFollowers;
  String get statsHelps;

  String get engagementDashboardTitle;
  String get playtimeTodayLabel;
  String get minutesShortLabel;
  String get goalLabel;
  String get recentActivitiesTitle;
  String get seeAllAction;
  String get noActivityToday;
  String get engagementBadgesTitle;
  String get noBadgesYet;

  String get featureComingSoonVoice;
  String get featureComingSoonPhoto;

  String get clinicalPatientRecordTitle;
  String get clinicalAgeLabel;
  String get clinicalDiagnosisLabel;
  String get clinicalDiagnosisAutism;
  String get clinicalTabAnalytics;
  String get clinicalTabNotes;
  String get clinicalTabHardware;
  String get clinicalObservationsTitle;
  String get clinicalSyncActive;
  String get clinicalDeviceHealth;
  String get clinicalDeviceConnected;
  String get clinicalBatteryLife;
  String get clinicalBatteryHealthy;
  String get clinicalSignalStrength;
  String get clinicalSignalUnit;
  String get clinicalSignalExcellent;
  String get clinicalSleepCycles;
  String get clinicalDeepSleep;
  String get clinicalPast24h;
  String get clinicalLightSleepTag;
  String get clinicalDeepSleepTag;
  String get clinicalHrvVariability;
  String get clinicalHrvUnit;
  String get clinicalHrvAvg;
  String get clinicalDayMon;
  String get clinicalDayWed;
  String get clinicalDayFri;
  String get clinicalDayToday;
  String get clinicalCpuTemp;
  String get clinicalLatency;
  String get clinicalDataRate;
  String get clinicalUptime;
  String get clinicalW1;
  String get clinicalW2;
  String get clinicalCurrent;
  String get clinicalCognitiveProgress;

  /// Share fallback title for donations
  String get donationShareFallbackTitle;

  /// Share footer for donations
  String get donationShareFooter;

  /// Report button label
  String get reportLabel;


  String get january;
  String get february;
  String get march;
  String get april;
  String get may;
  String get june;
  String get july;
  String get august;
  String get september;
  String get october;
  String get november;
  String get december;

  String get monShort;
  String get tueShort;
  String get wedShort;
  String get thuShort;
  String get friShort;
  String get satShort;
  String get sunShort;

  String get donationFormTitleHint;
  String get donationFormDescriptionHint;

  // Remaining Family Screens
  String get volunteerAvailableSlots;
  String volunteerBookingConfirmed(String name);
  String get volunteerConfirmBooking;

  String get chatConversationNotLoaded;
  String get chatMicPermissionRequired;
  String get chatReconnect;
  String get chatRetry;
  String get chatCallRefused;
  String get chatCallMissed;
  String get chatCallEnded;
  String chatCallDuration(String duration);
  String get chatCallback;

  String get convSettingsTitle;
  String get convSettingsAddMember;
  String get convSettingsSearchMember;
  String get convSettingsAdded;
  String get convSettingsAdd;
  String get convSettingsMembers;
  String get convSettingsRemoveMember;
  String get convSettingsQuitGroup;
  String get convSettingsOnlyAdminCannotLeave;
  String convSettingsRemoveConfirmTitle(String name);
  String convSettingsRemoveConfirmContent(String name);
  String get convSettingsCancel;
  String get convSettingsRemove;
  String get convSettingsQuitConfirmTitle;
  String get convSettingsQuitConfirmContent;
  String get convSettingsQuit;

  String get createGroupTitle;
  String get createGroupSubject;
  String get createGroupMembers;
  String get createGroupSearchMember;
  String get createGroupAdded;
  String get createGroupAdd;
  String get createGroupSubjectEmpty;
  String get createGroupSelectMembers;
  String get createGroupCreate;

  String get notificationsNoNotifications;

  String get childDashboardChangeProfile;
  String get childDashboardStartGame;
  String get childDashboardProgress;
  String get childDashboardAchievements;
  String get childProfileSetupTitle;
  String get childProfileName;
  String get childProfileAge;
  String get childProfileSpecialNeeds;
  String get childProfileCreate;
  String get childProgressTitle;
  String get childProgressRecentActivity;
  String get childProgressTotalTime;
  String get childProgressGamesPlayed;
  String get childModeLock;
  String get childModeExit;
  String get changeEmail;
  String get changeLanguage;
  String get changePhone;
  String get logout;
  String get logoutConfirmTitle;
  String get logoutConfirmMessage;
  String get cancel;
  String get delete;
  String get errorLoadingProfile;
  String get retry;
  String get sessionExpiredReconnect;
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

  /// Marketplace
  String get marketplaceTitle;
  String get marketplaceSubtitle;
  String get allItems;
  String get supplements;
  String get sensory;
  String get motorSkills;
  String get cognitive;
  String get recommendedFor;
  String get seeAll;
  String get newArrivals;
  String get buyNow;
  String get quickBuy;
  String get stockAvailable;
  String get outOfStock;

  /// Product Detail
  String get productDetails;
  String get keyBenefits;
  String get communityReviews;
  String get addToCart;
  String get buyOnPartnerSite;
  String get productAddedToCart;
  String get anxietyReduction;
  String get improvesSleepQuality;

  /// Healthcare Professional Dashboard
  String get aiHealthInsights;
  String get updatedTodayAt;
  String get aiSmartSummary;
  String get healthMetricCards;
  String get focusScore;
  String get socialReaction;
  String get motorSkillsTitle;
  String get calmState;
  String get suggestedBy;
  String get nextMilestoneTarget;
  String get adjustGameDifficulty;
  String get messageDoctor;

  /// Navigation
  String get tableau;
  String get parents;
  String get messages;
  String get profil;
  String get home;
  String get games;
  String get insights;
  String get shop;
  String get therapy;
  String get noPatientsYet;
  String get patientsListWillAppear;
  String get noMessagesYet;
  String get conversationsWillAppear;
  String get community;
  String get donations;
  String get mapTab;
  String get experts;
  String get healthcare;
  String get leCercleDuDon;
  String get jeDonne;
  String get jeRecherche;
  String get all;
  String get mobility;
  String get earlyLearning;
  String get clothing;
  String get proposeDonation;
  String get veryGoodCondition;
  String get goodCondition;
  String get likeNew;
  String get donation;
  String get recherche;
  String get details;
  String get donatedBy;
  String get contactDonor;
  String get distanceFromYou;
  String get searchDonationsHint;
  String get donationProposedSuccess;
  String get donationFormTitle;
  String get donationFormDescription;
  String get donationFormCategory;
  String get donationFormCondition;
  String get donationFormLocation;
  String get donationFormSubmit;
  String get donationFormTitleRequired;
  String get donationFormDescriptionRequired;
  String get donationFormLocationRequired;
  String get familyChat;
  String get open;
  String get shareExperiencePlaceholder;

  String get fromMarketplace;
  String get viewAll;
  String get noPostsYet;
  String get tapToShare;
  String get hoursAgo;
  String get minAgo;
  String get deletePost;
  String get deletePostConfirm;
  String get postDeleted;
  String get editPost;
  String get postUpdated;
  String get editPostTitle;
  String get save;
  String get comments;
  String get likes;
  String get share;
  String get keepGoing;
  String get level;
  String get tracingProgress;
  String get stars;
  String get hint;
  String get starTracer;
  String get congratulationsLeo;
  String completedAllLevels(int maxLevel);
  String get next;
  String traceLevel(String levelName);
  String get writeComment;
  String get weightedBlanket;
  String get noiseCancelling;
  String get visualTimer;

  /// Family profile (HTML design)
  String get monProfil;
  String get familyCaregiver;
  String get myFamily;
  String get quickSettings;
  String get childMode;
  String get dataSharing;
  String get familyNotifications;
  String get simplifiedInterfaceActive;
  String get syncWithRelatives;
  String get importantActivityAlerts;
  String get engagement;
  String get activitiesThisWeek;
  String get addMember;

  /// Child mode (emotion selection)
  String get howDoYouFeelToday;
  String get tapTheFriendThatLooksLikeYou;
  String get happy;
  String get sad;
  String get angry;
  String get tired;
  String get silly;
  String get helpLeoSpeakHisMind;

  /// Child dashboard (after emotion selection)
  String get greetingWhenHappy;
  String get greetingWhenSad;
  String get greetingWhenAngry;
  String get greetingWhenTired;
  String get greetingWhenSilly;
  String get childDashboardDefaultGreeting;
  String get childDashboardPlay;
  String get childDashboardMyProgress;
  String get myProgress;
  String get bravo;
  String get almostThere;
  String get childDashboardMyGifts;
  String get childDashboardLongPress;
  String get securityCode;
  String get manageChildModeExitCode;
  String get createYourSecurityCode;
  String get securityCodeRequiredToExitChildMode;
  String get confirm;
  String get securityCodeCreated;
  String get parentCode;
  String get enterCodeToExitChildMode;
  String get incorrectCode;
  String get chooseAGame;
  String get gameMatchPairs;
  String get gameShapeSorting;
  String get gameBasketSort;
  String get homeForObjects;
  String get dragItemToBasket;
  String get food;
  String get toys;
  String get tryAgain;

  /// Sticker book (rewards)
  String get myStickerBook;
  String get fantasticJob;
  String youEarnedStickersToday(int count);
  String get nextReward;
  String get superHeroPack;
  String justXMoreTasksToGo(int count);
  String get rewardReached;
  String get superHeroPackUnlocked;
  String get unlockedAnimalFriends;
  String get comingSoon;
  String get stickerLeoTheLion;
  String get stickerHappyHippo;
  String get stickerBraveBear;
  String get stickerSmartyPaws;
  String get stickerSortingChamp;
  String get stickerMemoryMaster;
  String get stickerPatternPro;
  String get stickerFocusStar;
  String get stickerComingSoon;
  String completeXMoreTasksToUnlock(int count);

  /// Game success (Bravo + sticker earned)
  String get youSucceededTheGame;
  String get stickerWon;
  String get addToMyCollection;
  String get playAgain;

  /// Gamification feedback & milestones
  String get greatJobLevelComplete;
  String get keepGoingAlmostThere;
  String milestoneLevelsCompleted(int count);
  String get myBadges;
  String get totalPointsLabel;

  /// Healthcare professional profile
  String get myPatients;
  String get lastAppointment;
  String get yesterday;
  String get clinicSettings;
  String get consultationHours;
  String get consultationHoursValue;
  String get teleconsultationSettings;
  String get teleconsultationSettingsValue;
  String get prescriptionTemplates;
  String get prescriptionTemplatesValue;
  String get myAccount;
  String get securityAndPrivacy;
  String get helpAndSupport;
  String get verifiedByOrder;
  String get patientsStat;
  String get todayStat;
  String get ratingStat;

  /// Child profile setup (after signup)
  String get childProfileTitle;
  String get childProfileConfigTitle;
  String get childProfileConfigSubtitle;
  String get childProfileIdentityLabel;
  String get childProfileFirstNameHint;
  String get childProfileYears;
  String get childProfileNameRequired;
  String get childProfileMedicalCareLabel;
  String get childProfileMedicationsLabel;
  String get childProfileMedicationsHint;
  String get childProfileSensitivitiesLabel;
  String get childProfileSensitivityLoudNoises;
  String get childProfileSensitivityLight;
  String get childProfileSensitivityTexture;
  String get childProfileSpecialNotesLabel;
  String get childProfileSpecialNotesHint;
  String get childProfileSleepLabel;
  String get childProfileTarget;
  String get childProfileSaveButton;
  String get childProfileEncryptedNote;
  String get childProfileSaved;
  String get childProfileAddLabel;
  String get childProfileSkipButton;
  String get childProfileCompleteLaterLabel;
  String get childProfileAlertTitle;
  String get childProfileAlertMessage;
  String get childProfileAlertCompleteButton;
  String get childProfileAlertLaterButton;

  /// Volunteer profile completion pop-up
  String get volunteerProfileAlertTitle;
  String get volunteerProfileAlertMessage;
  String get volunteerProfileAlertCompleteButton;
  String get volunteerProfileAlertLaterButton;
  String get volunteerTrainingLockedTitle;
  String get volunteerTrainingLockedMessage;
  String get volunteerTrainingLockedGoToFormations;

  /// Donation chat
  String get schedulePickup;
  String get itemReceived;
  String get writeMessage;
  String get todayLabel;

  /// Expert booking
  String get expertBookingTitle;
  String get expertBookingAvailableSlots;
  String get expertBookingConsultationType;
  String get expertBookingVideoCall;
  String get expertBookingInPerson;
  String get expertBookingConfirmButton;
  String get expertBookingConfirmationTitle;
  String get expertBookingConfirmedTitle;
  String get expertBookingConfirmedSubtitle;
  String get expertBookingSpecialistLabel;
  String get expertBookingDateTimeLabel;
  String get expertBookingModeLabel;
  String get expertBookingAddToCalendar;
  String get expertBookingViewAppointments;
  String get atLabel;
  String get expertAppointmentsTitle;
  String get expertAppointmentsUpcoming;
  String get expertAppointmentsPast;
  String get expertAppointmentsConfirmed;
  String get expertAppointmentsPending;
  String get expertAppointmentsJoinCall;
  String get expertAppointmentsViewItinerary;
  String get expertAppointmentsAppointmentDetails;

  /// Routine Screen
  String get routineTitle;
  String get noTasksToday;
  String get noTasksDescription;
  String get addTasksButton;
  String get taskDeleted;
  String get taskDeleteError;
  String get settingsComingSoon;
  String get confirmDeleteTitle;
  String confirmDeleteMessage(String taskTitle);
  String get unspecifiedTime;
  String get verificationInProgress;

  /// Encouragement messages
  String get encouragementHydrated;
  String get encouragementMeal;
  String get encouragementMedication;
  String get encouragementHygiene;
  String get encouragementHomework;
  String get encouragementDefault;

  /// Create Reminder Screen
  String get addTasksViewTitle;
  String get routineDailySubtitle;
  String selectTaskFor(String childName);
  String get dailyTasksHeader;
  String get customTaskTitle;
  String get customTaskDescription;
  String get newTaskTitle;
  String configureTask(String taskTitle);
  String get taskNameLabel;
  String get notificationTimesHeader;
  String get addTimeButton;
  String get confirmAndCreateButton;
  String get taskNameRequired;
  String taskAddedSuccess(String taskTitle);

  /// Task Template Titles & Descriptions
  String get templateBrushTeethTitle;
  String get templateBrushTeethDesc;
  String get templateTakeMedicineTitle;
  String get templateWashFaceTitle;
  String get templateWashFaceDesc;
  String get templateGetDressedTitle;
  String get templateGetDressedDesc;
  String get templateEatBreakfastTitle;
  String get templateEatBreakfastDesc;
  String get templateDrinkWaterTitle;
  String get templatePackBagTitle;
  String get templatePackBagDesc;
  String get templateDoHomeworkTitle;
  String get templateDoHomeworkDesc;

  /// Medicine Verification Screen
  String get medicineVerificationTitle;
  String get photoSelectionError;
  String get photoRequiredError;
  String get analysisComplete;
  String get verificationSuccessMsg;
  String get verificationUncertainMsg;
  String get verificationInvalidMsg;
  String get verifyingStatus;
  String get verificationByPhotoHeader;
  String get medicineVerificationInstructions;
  String get stepPrepareMedicine;
  String get stepTakeWithWater;
  String get stepTakeSelfie;
  String get validateIntakeButton;
  String get verificationFailedTitle;
  String get verificationUncertainTitle;
  String get verificationInvalidTitle;
  String get verificationUnknownStatus;
  String get defaultAiReasoning;
  String get labelMedicineRead;
  String get labelDosage;
  String get labelExpiration;
  String get notDetected;
  String get notVisible;
  String get confirmAndCloseButton;
  String get understoodAndCloseButton;
  String get cameraLabel;
  String get galleryLabel;
  String get retakeButton;

  /// Family Dashboard
  String helloUser(Object userName);
  String get familyMemberRole;
  String get playWithLeo;

  String get progressSummary;

  String get progressSummaryDesc;
  String get launchPlayTherapy;
  String get routineAndReminders;
  String get viewChildDailyTasks;
  String get dailyProgress;
  String childAgeLabel(Object name, Object age);
  String starsNeededForChallenge(Object count);
  String newMessagesCount(Object count);
  String get medicalTracking;
  String get nextAppointmentLabel;
  String get volunteersLabel;
  String get askForHelp;
  String get noVolunteersAvailable;
  String get retryButton;

  /// Themes
  String get themeTitle;
  String get doneButton;
  String get createWithAi;
  String get importImage;
  String featureComingSoon(Object feature);

  /// Volunteer Module
  String get volunteerLabel;
  String get impactPoints;
  String get mySkills;
  String get healthcareProfessionalsLabel;
  String get myPlanning;
  String get agendaLabel;
  String get formationsLabel;
  String get missionsLabel;
  String get detailsLabel;
  String get messageLabel;
  String get noPatientsFound;
  String get nextIntervention;
  String nextInterventionWith(Object date, Object time, Object name);
  String get roleDoctorLabel;
  String get rolePsychologistLabel;
  String get roleSpeechTherapistLabel;
  String get roleOccupationalTherapistLabel;
  String get contactExpertSubtitle;
  String get rendezVousTab;
  String get historiqueTab;
  String get yourImpact;
  String levelLabel(Object level);
  String nextBadgeLabel(Object badge);
  String get hoursLabel;
  String get merciLabel;
  String get searchVolunteerHint;
  String get allFilter;
  String get dailyTasksFilter;
  String get creativeWorkshopFilter;
  String get verifiedVolunteer;
  String reviewsLabel(Object count);
  String get requestHelpButton;
  String get yourWeek;
  String get noMissionsHistory;
  String get statusConfirmed;
  String get statusPending;
  String get statusCancelled;
  String get missionHomework;
  String get missionEscort;
  String get missionVisit;
  String get monthLabel;
  String weekLabel(Object count);
  String plannedMissionsCount(Object count);
  String missionsCount(Object count);
  String get missionReportLabel;
  String get offerHelpLabel;
  String get newAvailabilityLabel;
  String get endOfdayLabel;
  String get noOtherEventsLabel;
  String get volunteerServiceHub;
  String get developSkillsSubtitle;
  String get formationInProgress;
  String get noFormationInProgress;
  String get catalogueLabel;
  String get filterLabel;
  String get beginnerLevel;
  String get intermediateLevel;
  String get advancedLevel;
  String get myCertifications;
  String moduleProgressLabel(Object current, Object total, Object label);
  String completedPercent(Object percent);
  String get verifiedAccountLabel;
  String get verifiedLabel;
  String get availabilityLabel;
  String get activeForMissionsLabel;
  String get volunteerApplicationLabel;
  String get badgesAndImpactLabel;
  String get seeAllLabel;
  String get viewAllLabel;
  String get hoursOfServiceLabel;
  String get successfulMissionsLabel;
  String get aboutMeLabel;
  String get profileUpdatedSuccess;
  String get chooseFromGallery;
  String get takePhoto;
  String get myProfileLabel;
  String get volunteerProfileTitle;
  String get taskAcceptedLabel;
  String taskAcceptedMessage(Object volunteer, Object family);
  String get missionTypeLabel;
  String get beneficiaryLabel;
  String get plannedScheduleLabel;
  String get viewItineraryLabel;
  String get toDefineLabel;
  String get backToHomeLabel;
  String get sendMessageLabel;
  String get familyLabel;
  String get healthcareProfessionalLabel;
  String helloDr(Object name);
  String get clinicalOverviewIALabel;
  String get clinicalSummaryIALabel;
  String get seeDetailsLabel;
  String get myPatientsLabel;
  String get medicalReportsLabel;
  String get consultationsLabel;
  String get nextConsultationLabel;
  String todayAtTime(Object time);
  String get telemedicineLabel;
  String get startCallLabel;
  String get tableauLabel;
  String get reportsLabel;
  String get patientsLabel;
  String get healthcareSpaceLabel;
  String get searchPatientHint;
  String get followedPatientsLabel;
  String activePatientsCount(Object count);
  String get clinicalNotesLabel;
  String get aiAnalysisLabel;
  String get sessionPlannerLabel;
  String get aiInsightsLabel;
  String get gameSessionLabel;
  String get clinicalCheckupLabel;
  String get noSessionScheduledLabel;
  String recommendedForPatient(Object name);
  String get addToSessionLabel;
  String get consultationInProgressLabel;
  String get liveLabel;
  String get sharedWhiteboardLabel;
  String get collaborativeCareBoardLabel;
  String ageLabel(Object age);
  String get multidisciplinaryTeamLabel;
  String get inviteProLabel;
  String get timelineLabel;
  String get filesLabel;
  String get goalsLabel;
  String get secureTeamChatLabel;
  String get updatedLabel;
  String get searchHint;
  String get marketSearchHint;
  String get noMessagesLabel;
  String get noMessagesFamilyMessage;
  String get noMessagesVolunteerMessage;
  String get messagesLabel;
  String get reportsDescription;
  String get aiComparativeAnalysisLabel;
  String get aiComparativeAnalysisSubtitle;
  String get medicalReportsSubtitle;
  String get lastAiSummariesLabel;
  String get lastAiSummariesSubtitle;
  String get comparisonModeLabel;
  String get editLabel;
  String get cognitiveMetricsLabel;
  String get aggregatedData30Days;
  String get memoryLabel;
  String get focusLabel;
  String get motorLabel;
  String get aiPredictionsEvolution;
  String get groupAnalysisLabel;
  String get exportAnalysisLabel;
  String get protocolEditorLabel;
  String drLabel(Object name);
  String get patientLabelWithColon;
  String get mainObjectiveLabel;
  String get weeklyPlanningLabel;
  String get mondayLabel;
  String get tuesdayLabel;
  String get wednesdayLabel;
  String get thursdayLabel;
  String get fridayLabel;
  String get saturdayLabel;
  String get sundayLabel;
  String sessionParamsTitle(Object name);
  String get clinicalDifficultyLabel;
  String get beginnerLabel;
  String get expertLabel;
  String get frequencyLabel;
  String get durationMinLabel;
  String get oncePerDay;
  String get twicePerDay;
  String get smartLibraryLabel;
  String get clinicallyValidatedLabel;
  String get visualMemoryLabel;
  String get fineMotorSkillsLabel;
  String get oculomotorCoordinationLabel;
  String get socialLabel;
  String get emotionsLabel;
  String get attentionLabel;
  String get neuroLabel;
  String levelWithCount(Object count);
  String get childPsychiatristLabel;
  String get orgLeaderLabel;
  String get profilePicUpdated;
  String get passwordUpdatedReconnect;
  String get emailUpdatedReconnect;
  String get phoneUpdated;
  String get settingsTitle;
  String get profilePhotoLabel;
  String get changeProfilePhotoLabel;
  String get chooseFromGalleryLabel;
  String get takePhotoLabel;
  String get currentPasswordLabel;
  String get confirmNewPasswordLabel;
  String get passwordChangedSuccess;
  String get verificationEmailSent;
  String get currentPasswordRequired;
  String get newPasswordRequired;
  String get verifyEmailChangeTitle;
  String enterCodeSentTo(Object email);
  String get verificationCodeSent;
  String get failedToSendCode;
  String get enterVerificationCode;
  String get failedToVerifyCode;
  String get memberAdded;
  String get enrollmentSuccess;
  String get qualifyingCoursesTitle;
  String get qualificationOnlyFilter;
  String get myEnrollmentsTitle;
  String get noEnrollmentsMessage;
  String get completedStatus;
  String get inProgressStatus;
  String get availableCoursesTitle;
  String get noAvailableCoursesMessage;
  String get enrolledLabel;
  String get enrollButton;
  String get defaultCourseTitle;
  String get fileNotAccessibleTitle;
  String get fileNotAccessibleMessage;
  String get checkPermissionsSuggestion;
  String get copyFileSuggestion;
  String get restartAppSuggestion;
  String get fileNotFoundTitle;
  String get fileNotFoundMessage;
  String get checkFileExistsSuggestion;
  String get selectOtherFileSuggestion;
  String get invalidFileTypeTitle;
  String invalidFileTypeMessage(Object extension);
  String get allowedFormatsMessage;
  String get convertFileSuggestion;
  String get useScannerSuggestion;
  String get fileTooLargeTitle;
  String fileTooLargeMessage(Object fileSizeMB);
  String get compressImageSuggestion;
  String get reduceResolutionSuggestion;
  String get usePdfCompressorSuggestion;
  String get retakePhotoSuggestion;
  String get documentUploadSuccess;
  String get connectionErrorTitle;
  String get connectionErrorMessage;
  String get checkInternetSuggestion;
  String get retryLaterSuggestion;
  String get contactSupportSuggestion;
  String get uploadErrorTitle;
  String get possibleSolutionsLabel;
  String get volunteerApplicationTitle;
  String get acceptedFileTypesHint;
  String get uploadInProgressStatus;
  String get applicationApprovedMessage;
  String get applicationDeniedTitle;
  String get applicationDeniedFollowUp;
  String get depositedDocumentsTitle;
  String documentWithIndex(Object index);
  String get identityDocumentLabel;
  String get certificateDocumentLabel;
  String get otherDocumentLabel;
  String get homeworkHelp;
  String get outdoorAccompaniment;
  String get courtesyVisit;
  String get medicalTransport;
  String get creativeWorkshop;
  String get dailyTasks;
  String get speechTherapyHelp;
  String get reading;
  String get physiotherapy;
  String get outdoorActivities;
  String get creativeArts;
  String get superHelperBadge;
  String get orthophonyFilter;
  String get toDefine;
  String get dobLabel;
  String get tdah;
  String get artTherapy;
  String get readingSession;
  String get parkOuting;
  String get autism;
  String get gentleCommunication;
  String get mobilitySkill;
  String get expertBadge;
  String get altruistBadge;
  String get mentorBadge;
  String get volunteerBio;
  String get nonVerbalCommunication;
  String get sensoryCrisisManagement;
  String get adaptedPlayActivities;
  String get mentorLevel1;
  String get socialInclusion;
  String get cognitiveExpert;
  String get introModule;
  String get foundationModule;
  String get practiceModule;
  String get socialInteractionsModule;
  String get conclusionModule;
  String get missionLabel;
  String get itineraryLabel;
  String get instructionsLabel;
  String get startNavigationLabel;
  String get contactFamilyLabel;
  String get missionReportSummaryLabel;
  String get missionReportSummaryHint;
  String get childMoodLabel;
  String get moodHappy;
  String get moodCalm;
  String get moodAnxious;
  String get completedActivitiesLabel;
  String get gamesAndEntertainment;
  String get stroll;
  String get notesForParentsLabel;
  String get notesForParentsHint;
  String get reportSentMessage;
  String get sendReportButton;
  
  // Volunteer Chat & Messages
  String get messagesTitle;
  String get familiesTab;
  String get healthcareTab;
  String get noFamilyMessages;
  String get noHealthcareMessages;
  String get notConnectedError;
  String get voiceMessageError;
  String get micPermissionError;
  String get voiceMessage;
  String get photoLabel;
  String get missedCallLabel;
  String get voiceCallLabel;
  String get videoCallLabel;
  String get callBackLabel;
  String get imageNotAvailable;
  String get callEnded;
  String get callSummary;
  String get callConnectionFailed;
  String get callNoAnswer;
  String get callRinging;
  String get callConnecting;
  String get incomingVideoCall;
  String get incomingVoiceCall;
  String get declineCall;
  String get acceptCall;
  String get callMic;
  String get callMuteOff;
  String get callCamera;
  String get callCameraOff;
  String get callSpeaker;
  String get callEarpiece;
  String get callTranscriptionOn;
  String get callTranscriptionOff;
  String get yourMessageHint;
  String get typingIndicator;
  String get bravoLabel;
  
  // Theme Names
  String get themeAmour;
  String get themeValentines;
  String get themeSimpsons;
  String get themeFootball;
  String get themeBrat;
  String get themeLoveYou;
  String get themeCoolCrew;
  String get themeWinter;
  String get themeShapeFriends;

  // Games strings
  String get wellDone;
  String wrongShapeAttemptsRemaining(int attempts);
  String get outOfAttemptsTitle;
  String get outOfAttemptsDesc;
  String get nextGame;
  String levelXOfY(int current, int max);
  String get matchTheShapes;
  String get dragAShape;
  String get soundOn;
  String get nextShape;
  String levelX(int level);
  String get followLinesWithFinger;
  String get traceToBlueDot;

  // Family feed & shell specific
  String get navFeed;
  String get navChats;
  String get navMarket;
  String get navProfile;
  String get noDonationsYet;
  String get searchProfessionalHint;
  String get filterAll;
  String get filterSpeechTherapists;
  String get filterChildPsychiatrists;
  String get filterOccupationalTherapists;
  String get doctor;
  String get psychologist;
  String get speechTherapist;
  String get occupationalTherapist;
  String get noProfessionalsYet;
  String get momCheckOutToy;
  String get cogniCarePost;
  String get onlyEditOwnPosts;
  String get noProductsYet;
  String get bookConsultation;
  
  // Market & Families specific
  String get tabFamilies;
  String get tabVolunteers;
  String get tabHealthcare;
  String get conversationsTitle;
  String get searchFamilyFriends;
  String get noOtherFamiliesYet;
  String get familiesToContact;
  String get volunteersToContact;
  String get noHealthcareConversations;
  String get failedToOpenConversation;
  String get noProductsForCategory;

  // Cart & Checkout
  String get cartEmptyTitle;
  String get cartEmptyDesc;
  String get checkoutTitle;
  String get step2Of3;
  String get shippingAddress;
  String get shippingAddressLabel;
  String get paymentMethodLabel;
  String get orderTotalLabel;
  String get placeOrderButton;
  String get viewBoutique;
  String get yourCart;
  String get step1Of3;
  String get applyPromoCode;
  String get subtotal;
  String get shipping;
  String get free;
  String get total;
  String get proceedToCheckout;
  
  String get fillAllFieldsCard;
  String get cartIsEmpty;
  String get failedToOpenPayPal;
  String get paymentConfirmed;
  String orderDesc(String orderId, String amount);
  String paymentNotFinalized(String status);
  String get streetAddress;
  String get city;
  String get zipCode;
  String get paymentMethod;
  String get card;
  String get applePay;
  String get payPal;
  String get cardNumber;
  String get expiryDate;
  String get cvv;
  String get confirmAndPay;
  String get paypalPaymentTitle;
  String get paypalPaymentDesc;
  String get verifyPayment;

  // Order Confirmation
  String get orderConfirmedTitle;
  String orderPreparing(String orderId);
  String get trackMyOrder;
  String get returnToStore;
  String get estimatedDelivery;

  // Product Detail
  String get weightedBlanketDesc;
  String get writeReview;
  String get noReviewsYet;
  String get reviewWithoutComment;
  String get ratingLabel;
  String get commentOptional;
  String get shareYourExperience;
  String get publishLabel;
  String get reviewPublished;

  // Add Product
  String get pleaseAddProductPhoto;
  String get productPublishedSuccess;
  String get sellProductTitle;
  String get productTitleLabel;
  String get productTitleHint;
  String get requiredField;
  String get priceLabel;
  String get priceHint;
  String get descriptionLabel;
  String get descriptionHint;
  String get publishProduct;
  String get productPhotoLabel;
  String get clickToAddPhoto;

  // Donations Details & Propose
  String get viewItineraryGoogleMaps;
  String get loadingMapLabel;
  String get donationDefaultDonor;
  String get donationAll;
  String get donationMobility;
  String get donationEarlyLearning;
  String get donationClothing;
  String get donationLikeNew;
  String get donationGoodCondition;
  String get donationAddressNotFound;
  String get donationAddPhotos;
  String get donationClickToAddPhotos;
  String donationUpToPhotos(int count);
  String get donationFurniture;
  String get donationToys;
  String get donationConditionNew;
  String get donationAllAges;
  String get donationAge0_2;
  String get donationAge3_5;
  String get donationAge6_9;
  String get donationAge10_12;
  String get donationAge12Plus;
  String get donationSuitableAgeTitle;
  String get donationSuitableAgeOptional;
  String get donationSensoryBenefits;
  String get donationPickupLocation;
  String get donationTapToViewMap;
  String get publishDonationButton;
  String get selectCategory;
  String get itemConditionTitle;

  // Volunteer Notifications
  String get notificationsTitle;
  String get markAllAsRead;
  String get timeAgoJustNow;
  String timeAgoMinutes(int n);
  String timeAgoHours(int n);
  String get yesterdayLabel;
  String timeAgoDays(int n);
  String get noUnreadUpdates;
  String get oneUnreadUpdate;
  String unreadUpdatesCount(int n);
  String get notifTypeHealthAlert;
  String get notifTypeAchievement;
  String get notifTypeFamilyMessage;
  String get notifTypeHealthUpdate;
  String get notifTypePaymentConfirmed;
  String get notifTypeRoutine;
  String get aboutSectionLabel;
  String get verifiedSkillsLabel;
  String get defaultVolunteerAboutText;
  String get notifUrgentTitle;
  String get notifUrgentDesc;
  String get notifMsgTitle;
  String get notifMsgDesc;
  String get notifReminderTitle;
  String get notifReminderDesc;
  String get notifScheduleTitle;
  String get notifScheduleDesc;
  String get notifNewMissionTitle;
  String get notifNewMissionDesc;
  String get justNow;

  // Volunteer New Availability
  String get newAvailabilityTitle;
  String get selectDatesLabel;
  String get selectMultipleDatesHint;
  String get timeRangeLabel;
  String get startTimeLabel;
  String get endTimeLabel;
  String get recurrenceLabel;
  String get weeklyLabel;
  String get biweeklyLabel;
  String get saveAvailabilityButton;
  String get savingAvailability;
  String get selectOneDateAtLeast;
  String get availabilitySaved;

  // Volunteer Offer Help
  String get offerHelpTitle;
  String get offerHelpSubtitle;
  String get helpTypeLabel;
  String get groceriesLabel;
  String get transportLabel;
  String get childcareLabel;
  String get otherLabel;
  String get whenLabel;
  String get dateLabel;
  String get todayValueLabel;
  String get timeLabel;
  String get asapLabel;
  String get customMessageLabel;
  String get offerHelpMessageHint;
  String get broadcastOfferButton;
  String get offerBroadcastedMessage;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['ar', 'en', 'fr'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ar':
      return AppLocalizationsAr();
    case 'en':
      return AppLocalizationsEn();
    case 'fr':
      return AppLocalizationsFr();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
