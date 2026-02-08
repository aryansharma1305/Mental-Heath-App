import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_hi.dart';
import 'app_localizations_ta.dart';

// ignore_for_file: type=lint

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
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
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
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
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
    Locale('hi'),
    Locale('ta'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'MindCare'**
  String get appTitle;

  /// No description provided for @doctorWelcome.
  ///
  /// In en, this message translates to:
  /// **'Welcome, Doctor'**
  String get doctorWelcome;

  /// No description provided for @patientInfo.
  ///
  /// In en, this message translates to:
  /// **'Patient Information'**
  String get patientInfo;

  /// No description provided for @startAssessment.
  ///
  /// In en, this message translates to:
  /// **'Start Assessment'**
  String get startAssessment;

  /// No description provided for @dsm5Title.
  ///
  /// In en, this message translates to:
  /// **'DSM-5 Assessment'**
  String get dsm5Title;

  /// No description provided for @dsm5Subtitle.
  ///
  /// In en, this message translates to:
  /// **'Cross-Cutting Symptom Measure'**
  String get dsm5Subtitle;

  /// No description provided for @anonymisedId.
  ///
  /// In en, this message translates to:
  /// **'Anonymised Patient ID'**
  String get anonymisedId;

  /// No description provided for @enterIdHint.
  ///
  /// In en, this message translates to:
  /// **'Enter anonymous ID (no names)'**
  String get enterIdHint;

  /// No description provided for @recentActivity.
  ///
  /// In en, this message translates to:
  /// **'Recent Activity'**
  String get recentActivity;

  /// No description provided for @newAssessment.
  ///
  /// In en, this message translates to:
  /// **'New Assessment'**
  String get newAssessment;

  /// No description provided for @viewAll.
  ///
  /// In en, this message translates to:
  /// **'View All'**
  String get viewAll;

  /// No description provided for @home.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get home;

  /// No description provided for @profile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profile;

  /// No description provided for @assessmentTitle.
  ///
  /// In en, this message translates to:
  /// **'DSM-5 Assessment'**
  String get assessmentTitle;

  /// No description provided for @assessmentSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Cross-Cutting Symptom Measure'**
  String get assessmentSubtitle;

  /// No description provided for @patientInfoTitle.
  ///
  /// In en, this message translates to:
  /// **'Patient Information'**
  String get patientInfoTitle;

  /// No description provided for @patientInfoSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Enter details to begin'**
  String get patientInfoSubtitle;

  /// No description provided for @enterIdLabel.
  ///
  /// In en, this message translates to:
  /// **'Anonymised Patient ID'**
  String get enterIdLabel;

  /// No description provided for @dsm5Info.
  ///
  /// In en, this message translates to:
  /// **'DSM-5 Cross-Cutting Measure: 23 questions across 13 psychiatric domains'**
  String get dsm5Info;

  /// No description provided for @pastTwoWeeks.
  ///
  /// In en, this message translates to:
  /// **'During the past TWO (2) WEEKS, how much have you been bothered by:'**
  String get pastTwoWeeks;

  /// No description provided for @previous.
  ///
  /// In en, this message translates to:
  /// **'Previous'**
  String get previous;

  /// No description provided for @done.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get done;

  /// No description provided for @newAssessmentButton.
  ///
  /// In en, this message translates to:
  /// **'New'**
  String get newAssessmentButton;

  /// No description provided for @assessmentComplete.
  ///
  /// In en, this message translates to:
  /// **'Assessment Complete'**
  String get assessmentComplete;

  /// No description provided for @scoreLabel.
  ///
  /// In en, this message translates to:
  /// **'Score'**
  String get scoreLabel;

  /// No description provided for @level2Recommended.
  ///
  /// In en, this message translates to:
  /// **'Level 2 Assessment Recommended'**
  String get level2Recommended;

  /// No description provided for @domainBreakdown.
  ///
  /// In en, this message translates to:
  /// **'Domain Breakdown'**
  String get domainBreakdown;

  /// No description provided for @criticalAlertTitle.
  ///
  /// In en, this message translates to:
  /// **'Critical Alert'**
  String get criticalAlertTitle;

  /// No description provided for @criticalAlertMessage.
  ///
  /// In en, this message translates to:
  /// **'Patient has reported thoughts of self-harm. Immediate clinical assessment is recommended.'**
  String get criticalAlertMessage;

  /// No description provided for @errorLoadingAssessments.
  ///
  /// In en, this message translates to:
  /// **'Error loading assessments'**
  String get errorLoadingAssessments;

  /// No description provided for @acknowledged.
  ///
  /// In en, this message translates to:
  /// **'Acknowledged'**
  String get acknowledged;

  /// No description provided for @allAssessments.
  ///
  /// In en, this message translates to:
  /// **'All Assessments'**
  String get allAssessments;

  /// No description provided for @searchHint.
  ///
  /// In en, this message translates to:
  /// **'Search by patient name, ID, or assessor...'**
  String get searchHint;

  /// No description provided for @noAssessmentsFound.
  ///
  /// In en, this message translates to:
  /// **'No assessments found'**
  String get noAssessmentsFound;

  /// No description provided for @noAssessmentsYet.
  ///
  /// In en, this message translates to:
  /// **'No assessments yet'**
  String get noAssessmentsYet;

  /// No description provided for @adjustSearchTerms.
  ///
  /// In en, this message translates to:
  /// **'Try adjusting your search terms'**
  String get adjustSearchTerms;

  /// No description provided for @createFirstAssessment.
  ///
  /// In en, this message translates to:
  /// **'Create your first assessment'**
  String get createFirstAssessment;

  /// No description provided for @sortByDateNewest.
  ///
  /// In en, this message translates to:
  /// **'Sort by Date (Newest)'**
  String get sortByDateNewest;

  /// No description provided for @sortByDateOldest.
  ///
  /// In en, this message translates to:
  /// **'Sort by Date (Oldest)'**
  String get sortByDateOldest;

  /// No description provided for @sortByNameAZ.
  ///
  /// In en, this message translates to:
  /// **'Sort by Name (A-Z)'**
  String get sortByNameAZ;

  /// No description provided for @sortByNameZA.
  ///
  /// In en, this message translates to:
  /// **'Sort by Name (Z-A)'**
  String get sortByNameZA;

  /// No description provided for @assessmentsCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 assessment} other{{count} assessments}}'**
  String assessmentsCount(num count);

  /// No description provided for @statusPending.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get statusPending;

  /// No description provided for @statusReviewed.
  ///
  /// In en, this message translates to:
  /// **'Reviewed'**
  String get statusReviewed;

  /// No description provided for @statusCompleted.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get statusCompleted;

  /// No description provided for @statusUnknown.
  ///
  /// In en, this message translates to:
  /// **'Unknown'**
  String get statusUnknown;

  /// No description provided for @capacityCapable.
  ///
  /// In en, this message translates to:
  /// **'Has capacity for this decision'**
  String get capacityCapable;

  /// No description provided for @capacityIncapable.
  ///
  /// In en, this message translates to:
  /// **'Lacks capacity for this decision'**
  String get capacityIncapable;

  /// No description provided for @capacityFluctuating.
  ///
  /// In en, this message translates to:
  /// **'Fluctuating capacity - reassessment needed'**
  String get capacityFluctuating;
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
      <String>['en', 'hi', 'ta'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'hi':
      return AppLocalizationsHi();
    case 'ta':
      return AppLocalizationsTa();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
