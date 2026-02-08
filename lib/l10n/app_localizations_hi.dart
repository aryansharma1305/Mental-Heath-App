// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Hindi (`hi`).
class AppLocalizationsHi extends AppLocalizations {
  AppLocalizationsHi([String locale = 'hi']) : super(locale);

  @override
  String get appTitle => 'மைண்ட் கேர்';

  @override
  String get doctorWelcome => 'नमस्ते, डॉक्टर';

  @override
  String get patientInfo => 'रोगी की जानकारी';

  @override
  String get startAssessment => 'मूल्यांकन शुरू करें';

  @override
  String get dsm5Title => 'DSM-5 मूल्यांकन';

  @override
  String get dsm5Subtitle => 'क्रॉस-कटिंग लक्षण उपाय';

  @override
  String get anonymisedId => 'अज्ञात रोगी आईडी';

  @override
  String get enterIdHint => 'आईडी दर्ज करें (कोई नाम नहीं)';

  @override
  String get recentActivity => 'हाल की गतिविधि';

  @override
  String get newAssessment => 'नया मूल्यांकन';

  @override
  String get viewAll => 'सभी देखें';

  @override
  String get home => 'होम';

  @override
  String get profile => 'प्रोफाइल';

  @override
  String get assessmentTitle => 'DSM-5 मूल्यांकन';

  @override
  String get assessmentSubtitle => 'क्रॉस-कटिंग लक्षण उपाय';

  @override
  String get patientInfoTitle => 'रोगी की जानकारी';

  @override
  String get patientInfoSubtitle => 'शुरू करने के लिए विवरण दर्ज करें';

  @override
  String get enterIdLabel => 'अज्ञात रोगी आईडी';

  @override
  String get dsm5Info =>
      'DSM-5 क्रॉस-कटिंग उपाय: 13 मनोरोग डोमेन में 23 प्रश्न';

  @override
  String get pastTwoWeeks =>
      'पिछले दो (2) सप्ताहों के दौरान, आप कितना परेशान रहे हैं:';

  @override
  String get previous => 'पिछला';

  @override
  String get done => 'हो गया';

  @override
  String get newAssessmentButton => 'नया';

  @override
  String get assessmentComplete => 'मूल्यांकन पूरा हुआ';

  @override
  String get scoreLabel => 'स्कोर';

  @override
  String get level2Recommended => 'स्तर 2 मूल्यांकन अनुशंसित';

  @override
  String get domainBreakdown => 'डोमेन ब्रेकडाउन';

  @override
  String get criticalAlertTitle => 'गंभीर चेतावनी';

  @override
  String get criticalAlertMessage =>
      'रोगी ने आत्म-नुकसान के विचारों की सूचना दी है। तत्काल नैदानिक मूल्यांकन की सिफारिश की जाती है।';

  @override
  String get errorLoadingAssessments => 'मूल्यांकन लोड करने में त्रुटि';

  @override
  String get acknowledged => 'स्वीकार किया';

  @override
  String get allAssessments => 'सभी मूल्यांकन';

  @override
  String get searchHint =>
      'रोगी का नाम, आईडी, या मूल्यांकनकर्ता द्वारा खोजें...';

  @override
  String get noAssessmentsFound => 'कोई मूल्यांकन नहीं मिला';

  @override
  String get noAssessmentsYet => 'अभी तक कोई मूल्यांकन नहीं';

  @override
  String get adjustSearchTerms =>
      'अपनी खोज शर्तों को समायोजित करने का प्रयास करें';

  @override
  String get createFirstAssessment => 'अपना पहला मूल्यांकन बनाएं';

  @override
  String get sortByDateNewest => 'दिनांक के अनुसार क्रमबद्ध करें (नवीनतम)';

  @override
  String get sortByDateOldest => 'दिनांक के अनुसार क्रमबद्ध करें (पुराना)';

  @override
  String get sortByNameAZ => 'नाम के अनुसार क्रमबद्ध करें (A-Z)';

  @override
  String get sortByNameZA => 'नाम के अनुसार क्रमबद्ध करें (Z-A)';

  @override
  String assessmentsCount(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count मूल्यांकन',
      one: '1 मूल्यांकन',
    );
    return '$_temp0';
  }

  @override
  String get statusPending => 'लंबित';

  @override
  String get statusReviewed => 'समीक्षा की गई';

  @override
  String get statusCompleted => 'पूरा हुआ';

  @override
  String get statusUnknown => 'अज्ञात';

  @override
  String get capacityCapable => 'इस निर्णय के लिए क्षमता है';

  @override
  String get capacityIncapable => 'इस निर्णय के लिए क्षमता का अभाव है';

  @override
  String get capacityFluctuating =>
      'उतार-चढ़ाव वाली क्षमता - पुनर्मूल्यांकन की आवश्यकता है';
}
