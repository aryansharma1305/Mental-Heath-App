// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Tamil (`ta`).
class AppLocalizationsTa extends AppLocalizations {
  AppLocalizationsTa([String locale = 'ta']) : super(locale);

  @override
  String get appTitle => 'மைண்ட் கேர்';

  @override
  String get doctorWelcome => 'வணக்கம், மருத்துவர்';

  @override
  String get patientInfo => 'நோயாளி தகவல்';

  @override
  String get startAssessment => 'மதிப்பீட்டைத் தொடங்கவும்';

  @override
  String get dsm5Title => 'DSM-5 மதிப்பீடு';

  @override
  String get dsm5Subtitle => 'குறுக்கு வெட்டு அறிகுறி அளவீடு';

  @override
  String get anonymisedId => 'அடையாளம் மறைக்கப்பட்ட நோயாளி ஐடி';

  @override
  String get enterIdHint => 'ஐடியை உள்ளிடவும் (பெயர்கள் இல்லை)';

  @override
  String get recentActivity => 'சமீபத்திய செயல்பாடு';

  @override
  String get newAssessment => 'புதிய மதிப்பீடு';

  @override
  String get viewAll => 'அனைத்தையும் பார்';

  @override
  String get home => 'முகப்பு';

  @override
  String get profile => 'விவரக்குறிப்பு';

  @override
  String get assessmentTitle => 'DSM-5 மதிப்பீடு';

  @override
  String get assessmentSubtitle => 'குறுக்கு வெட்டு அறிகுறி அளவீடு';

  @override
  String get patientInfoTitle => 'நோயாளி தகவல்';

  @override
  String get patientInfoSubtitle => 'தொடங்க விவரங்களை உள்ளிடவும்';

  @override
  String get enterIdLabel => 'அடையாளம் மறைக்கப்பட்ட நோயாளி ஐடி';

  @override
  String get dsm5Info =>
      'DSM-5 குறுக்கு வெட்டு அளவீடு: 13 உளவியல் களங்களில் 23 கேள்விகள்';

  @override
  String get pastTwoWeeks =>
      'கடந்த இரண்டு (2) வாரங்களில், நீங்கள் எவ்வளவு பாதிக்கப்பட்டீர்கள்:';

  @override
  String get previous => 'முந்தைய';

  @override
  String get done => 'முடிந்தது';

  @override
  String get newAssessmentButton => 'புதிய';

  @override
  String get assessmentComplete => 'மதிப்பீடு முடிந்தது';

  @override
  String get scoreLabel => 'மதிப்பெண்';

  @override
  String get level2Recommended => 'நிலை 2 மதிப்பீடு பரிந்துரைக்கப்படுகிறது';

  @override
  String get domainBreakdown => 'கள முறிவு';

  @override
  String get criticalAlertTitle => 'முக்கிய எச்சரிக்கை';

  @override
  String get criticalAlertMessage =>
      'நோயாளி தனக்குத்தானே தீங்கு விளைவிக்கும் எண்ணங்களைப் புகாரளித்துள்ளார். உடனடி மருத்துவ மதிப்பீடு பரிந்துரைக்கப்படுகிறது.';

  @override
  String get errorLoadingAssessments => 'மதிப்பீடுகளை ஏற்றுவதில் பிழை';

  @override
  String get acknowledged => 'ஏற்றுக்கொள்ளப்பட்டது';

  @override
  String get allAssessments => 'அனைத்து மதிப்பீடுகளும்';

  @override
  String get searchHint => 'பெயர், ஐடி அல்லது மதிப்பீட்டாளர் மூலம் தேடவும்...';

  @override
  String get noAssessmentsFound => 'மதிப்பீடுகள் எதுவும் காணப்படவில்லை';

  @override
  String get noAssessmentsYet => 'இதுவரை மதிப்பீடுகள் இல்லை';

  @override
  String get adjustSearchTerms => 'உங்கள் தேடல் சொற்களை மாற்ற முயற்சிக்கவும்';

  @override
  String get createFirstAssessment => 'உங்கள் முதல் மதிப்பீட்டை உருவாக்கவும்';

  @override
  String get sortByDateNewest => 'தேதி அடிப்படையில் வரிசைப்படுத்து (புதியது)';

  @override
  String get sortByDateOldest => 'தேதி அடிப்படையில் வரிசைப்படுத்து (பழையது)';

  @override
  String get sortByNameAZ => 'பெயர் அடிப்படையில் வரிசைப்படுத்து (A-Z)';

  @override
  String get sortByNameZA => 'பெயர் அடிப்படையில் வரிசைப்படுத்து (Z-A)';

  @override
  String assessmentsCount(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count மதிப்பீடுகள்',
      one: '1 மதிப்பீடு',
    );
    return '$_temp0';
  }

  @override
  String get statusPending => 'நிலுவையில்';

  @override
  String get statusReviewed => 'மதிப்பாய்வு செய்யப்பட்டது';

  @override
  String get statusCompleted => 'முடிந்தது';

  @override
  String get statusUnknown => 'தெரியாத';

  @override
  String get capacityCapable => 'இந்த முடிவுக்கு திறன் உள்ளது';

  @override
  String get capacityIncapable => 'இந்த முடிவுக்கு திறன் இல்லை';

  @override
  String get capacityFluctuating => 'மாறுபடும் திறன் - மறுமதிப்பீடு தேவை';
}
