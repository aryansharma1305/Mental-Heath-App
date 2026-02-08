// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'MindCare';

  @override
  String get doctorWelcome => 'Welcome, Doctor';

  @override
  String get patientInfo => 'Patient Information';

  @override
  String get startAssessment => 'Start Assessment';

  @override
  String get dsm5Title => 'DSM-5 Assessment';

  @override
  String get dsm5Subtitle => 'Cross-Cutting Symptom Measure';

  @override
  String get anonymisedId => 'Anonymised Patient ID';

  @override
  String get enterIdHint => 'Enter anonymous ID (no names)';

  @override
  String get recentActivity => 'Recent Activity';

  @override
  String get newAssessment => 'New Assessment';

  @override
  String get viewAll => 'View All';

  @override
  String get home => 'Home';

  @override
  String get profile => 'Profile';

  @override
  String get assessmentTitle => 'DSM-5 Assessment';

  @override
  String get assessmentSubtitle => 'Cross-Cutting Symptom Measure';

  @override
  String get patientInfoTitle => 'Patient Information';

  @override
  String get patientInfoSubtitle => 'Enter details to begin';

  @override
  String get enterIdLabel => 'Anonymised Patient ID';

  @override
  String get dsm5Info =>
      'DSM-5 Cross-Cutting Measure: 23 questions across 13 psychiatric domains';

  @override
  String get pastTwoWeeks =>
      'During the past TWO (2) WEEKS, how much have you been bothered by:';

  @override
  String get previous => 'Previous';

  @override
  String get done => 'Done';

  @override
  String get newAssessmentButton => 'New';

  @override
  String get assessmentComplete => 'Assessment Complete';

  @override
  String get scoreLabel => 'Score';

  @override
  String get level2Recommended => 'Level 2 Assessment Recommended';

  @override
  String get domainBreakdown => 'Domain Breakdown';

  @override
  String get criticalAlertTitle => 'Critical Alert';

  @override
  String get criticalAlertMessage =>
      'Patient has reported thoughts of self-harm. Immediate clinical assessment is recommended.';

  @override
  String get errorLoadingAssessments => 'Error loading assessments';

  @override
  String get acknowledged => 'Acknowledged';

  @override
  String get allAssessments => 'All Assessments';

  @override
  String get searchHint => 'Search by patient name, ID, or assessor...';

  @override
  String get noAssessmentsFound => 'No assessments found';

  @override
  String get noAssessmentsYet => 'No assessments yet';

  @override
  String get adjustSearchTerms => 'Try adjusting your search terms';

  @override
  String get createFirstAssessment => 'Create your first assessment';

  @override
  String get sortByDateNewest => 'Sort by Date (Newest)';

  @override
  String get sortByDateOldest => 'Sort by Date (Oldest)';

  @override
  String get sortByNameAZ => 'Sort by Name (A-Z)';

  @override
  String get sortByNameZA => 'Sort by Name (Z-A)';

  @override
  String assessmentsCount(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count assessments',
      one: '1 assessment',
    );
    return '$_temp0';
  }

  @override
  String get statusPending => 'Pending';

  @override
  String get statusReviewed => 'Reviewed';

  @override
  String get statusCompleted => 'Completed';

  @override
  String get statusUnknown => 'Unknown';

  @override
  String get capacityCapable => 'Has capacity for this decision';

  @override
  String get capacityIncapable => 'Lacks capacity for this decision';

  @override
  String get capacityFluctuating =>
      'Fluctuating capacity - reassessment needed';
}
