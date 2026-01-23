import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Language types supported by the app
enum AppLanguage {
  english('English', 'en'),
  hindi('हिंदी', 'hi'),
  tamil('தமிழ்', 'ta');

  final String displayName;
  final String code;
  const AppLanguage(this.displayName, this.code);
}

/// Service to manage language selection and translations
class LanguageService extends ChangeNotifier {
  static final LanguageService _instance = LanguageService._internal();
  factory LanguageService() => _instance;
  LanguageService._internal();

  AppLanguage _currentLanguage = AppLanguage.english;
  AppLanguage get currentLanguage => _currentLanguage;

  /// Initialize language from stored preference
  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final code = prefs.getString('app_language') ?? 'en';
    _currentLanguage = AppLanguage.values.firstWhere(
      (l) => l.code == code,
      orElse: () => AppLanguage.english,
    );
    notifyListeners();
  }

  /// Set the current language
  Future<void> setLanguage(AppLanguage language) async {
    _currentLanguage = language;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('app_language', language.code);
    notifyListeners();
  }

  /// Get translated string
  String translate(String key) {
    return _translations[_currentLanguage.code]?[key] ?? 
           _translations['en']?[key] ?? 
           key;
  }

  /// Translation map
  static final Map<String, Map<String, String>> _translations = {
    'en': {
      // App strings
      'app_title': 'Mental Capacity Assessment',
      'welcome_back': 'Welcome back,',
      'new_assessment': 'New Assessment',
      'start_assessment': 'Start Assessment',
      'history': 'History',
      'analytics': 'Analytics',
      'today': 'Today',
      'week': 'This Week',
      'total': 'Total',
      'patient_info': 'Patient Information',
      'enter_details': 'Enter details to begin assessment',
      'patient_name': 'Patient Name',
      'enter_full_name': 'Enter full name',
      'age': 'Age',
      'years': 'Years',
      'sex': 'Sex',
      'male': 'Male',
      'female': 'Female',
      'previous': 'Previous',
      'next': 'Next',
      'submit': 'Submit',
      'done': 'Done',
      'assessment_complete': 'Assessment Complete',
      'determination': 'Determination',
      'recommendations': 'Recommendations',
      'new_assessment_btn': 'New Assessment',
      'select_response': 'Please select a response',
      'question': 'Question',
      'of': 'of',
      'settings': 'Settings',
      'language': 'Language',
      'select_language': 'Select Language',
      'has_capacity': 'Has capacity for this decision',
      'lacks_capacity': 'Lacks capacity for this decision',
      'partial_capacity': 'Partial capacity - may need support',
      'fluctuating': 'Fluctuating capacity - reassessment needed',

      // Questions
      'q1': 'Does the person understand the information relevant to the decision?',
      'q1_o1': 'Fully understands all relevant information',
      'q1_o2': 'Understands most of the relevant information',
      'q1_o3': 'Partial understanding with some gaps',
      'q1_o4': 'Limited understanding of relevant information',
      'q1_o5': 'Cannot understand the relevant information',

      'q2': 'Can the person retain the information long enough to make the decision?',
      'q2_o1': 'Retains information fully throughout the decision-making process',
      'q2_o2': 'Retains most information with minor lapses',
      'q2_o3': 'Retains information for a limited time',
      'q2_o4': 'Has difficulty retaining information',
      'q2_o5': 'Cannot retain the information at all',

      'q3': 'Can the person use or weigh the information as part of the decision-making process?',
      'q3_o1': 'Can fully use and weigh all relevant information',
      'q3_o2': 'Can use and weigh most information effectively',
      'q3_o3': 'Shows some ability to use and weigh information',
      'q3_o4': 'Limited ability to use or weigh information',
      'q3_o5': 'Cannot use or weigh the information',

      'q4': 'Can the person communicate their decision (by any means)?',
      'q4_o1': 'Can clearly communicate decision by speech/writing/other means',
      'q4_o2': 'Can communicate decision with some support',
      'q4_o3': 'Can communicate decision with significant assistance',
      'q4_o4': 'Has difficulty communicating decision clearly',
      'q4_o5': 'Cannot communicate their decision by any means',

      'q5': 'Does the person appreciate the consequences of making or not making the decision?',
      'q5_o1': 'Fully appreciates all potential consequences',
      'q5_o2': 'Appreciates most consequences',
      'q5_o3': 'Partial appreciation of consequences',
      'q5_o4': 'Limited appreciation of consequences',
      'q5_o5': 'Does not appreciate the consequences',

      'q6': 'Is the person\'s decision consistent with their known values and beliefs?',
      'q6_o1': 'Decision is fully consistent with known values/beliefs',
      'q6_o2': 'Decision is mostly consistent',
      'q6_o3': 'Some inconsistency with known values/beliefs',
      'q6_o4': 'Decision appears inconsistent with values/beliefs',
      'q6_o5': 'Unable to determine or clearly inconsistent',

      'q7': 'Is there an impairment or disturbance in the functioning of the mind or brain?',
      'q7_o1': 'No impairment or disturbance identified',
      'q7_o2': 'Minor impairment that does not affect decision-making',
      'q7_o3': 'Moderate impairment that may affect decision-making',
      'q7_o4': 'Significant impairment affecting decision-making',
      'q7_o5': 'Severe impairment preventing decision-making',

      'q8': 'Is this the right time to assess capacity for this decision?',
      'q8_o1': 'Optimal time - person is at their best',
      'q8_o2': 'Good time - person is reasonably alert and focused',
      'q8_o3': 'Acceptable time with some limitations',
      'q8_o4': 'Suboptimal time - assessment may need to be repeated',
      'q8_o5': 'Not appropriate time - defer assessment',

      'q9': 'Has all practicable support been provided to help the person make the decision?',
      'q9_o1': 'All practicable support has been provided',
      'q9_o2': 'Most support options have been explored',
      'q9_o3': 'Some support has been provided',
      'q9_o4': 'Limited support has been offered',
      'q9_o5': 'No additional support has been provided',

      'q10': 'Does the person understand the risks involved in the decision?',
      'q10_o1': 'Fully understands all risks',
      'q10_o2': 'Understands most significant risks',
      'q10_o3': 'Partial understanding of risks',
      'q10_o4': 'Limited understanding of risks',
      'q10_o5': 'Does not understand the risks',

      'q11': 'Has the person been presented with and understood alternative options?',
      'q11_o1': 'All alternatives presented and understood',
      'q11_o2': 'Most alternatives presented and understood',
      'q11_o3': 'Some alternatives presented with partial understanding',
      'q11_o4': 'Limited alternatives discussed',
      'q11_o5': 'No alternatives presented or not understood',

      'q12': 'Is the person\'s capacity likely to fluctuate or improve?',
      'q12_o1': 'Capacity is stable and unlikely to change',
      'q12_o2': 'Capacity may improve with time/treatment',
      'q12_o3': 'Capacity fluctuates - may need reassessment',
      'q12_o4': 'Capacity is declining',
      'q12_o5': 'Cannot determine fluctuation pattern',

      'q13': 'Based on the assessment, what is the overall capacity determination?',
      'q13_o1': 'Has capacity for this decision',
      'q13_o2': 'Lacks capacity for this decision',
      'q13_o3': 'Fluctuating capacity - reassessment needed',
      'q13_o4': 'Requires further specialist assessment',
      'q13_o5': 'Unable to complete assessment at this time',

      // Categori
      'cat_understanding': 'Understanding',
      'cat_retaining': 'Retaining',
      'cat_using': 'Using Information',
      'cat_communication': 'Communication',
      'cat_appreciation': 'Appreciation',
      'cat_consistency': 'Consistency',
      'cat_impairment': 'Mental Impairment',
      'cat_timing': 'Timing',
      'cat_support': 'Support',
      'cat_risk': 'Risk Awareness',
      'cat_alternatives': 'Alternatives',
      'cat_fluctuation': 'Fluctuation',
      'cat_determination': 'Overall Determination',
    },

    'hi': {
      // App strings - Hindi
      'app_title': 'मानसिक क्षमता मूल्यांकन',
      'welcome_back': 'वापस स्वागत है,',
      'new_assessment': 'नया मूल्यांकन',
      'start_assessment': 'मूल्यांकन शुरू करें',
      'history': 'इतिहास',
      'analytics': 'विश्लेषण',
      'today': 'आज',
      'week': 'इस सप्ताह',
      'total': 'कुल',
      'patient_info': 'रोगी की जानकारी',
      'enter_details': 'मूल्यांकन शुरू करने के लिए विवरण दर्ज करें',
      'patient_name': 'रोगी का नाम',
      'enter_full_name': 'पूरा नाम दर्ज करें',
      'age': 'आयु',
      'years': 'वर्ष',
      'sex': 'लिंग',
      'male': 'पुरुष',
      'female': 'महिला',
      'previous': 'पिछला',
      'next': 'अगला',
      'submit': 'जमा करें',
      'done': 'पूर्ण',
      'assessment_complete': 'मूल्यांकन पूर्ण',
      'determination': 'निर्धारण',
      'recommendations': 'सिफारिशें',
      'new_assessment_btn': 'नया मूल्यांकन',
      'select_response': 'कृपया एक प्रतिक्रिया चुनें',
      'question': 'प्रश्न',
      'of': 'का',
      'settings': 'सेटिंग्स',
      'language': 'भाषा',
      'select_language': 'भाषा चुनें',
      'has_capacity': 'इस निर्णय के लिए क्षमता है',
      'lacks_capacity': 'इस निर्णय के लिए क्षमता नहीं है',
      'partial_capacity': 'आंशिक क्षमता - सहायता की आवश्यकता हो सकती है',
      'fluctuating': 'अस्थिर क्षमता - पुनर्मूल्यांकन की आवश्यकता',

      // Questions - Hindi
      'q1': 'क्या व्यक्ति निर्णय से संबंधित जानकारी को समझता है?',
      'q1_o1': 'सभी प्रासंगिक जानकारी को पूरी तरह समझता है',
      'q1_o2': 'अधिकांश प्रासंगिक जानकारी को समझता है',
      'q1_o3': 'कुछ कमियों के साथ आंशिक समझ',
      'q1_o4': 'प्रासंगिक जानकारी की सीमित समझ',
      'q1_o5': 'प्रासंगिक जानकारी को समझने में असमर्थ',

      'q2': 'क्या व्यक्ति निर्णय लेने के लिए पर्याप्त समय तक जानकारी याद रख सकता है?',
      'q2_o1': 'निर्णय लेने की प्रक्रिया में पूरी तरह से जानकारी याद रखता है',
      'q2_o2': 'मामूली चूक के साथ अधिकांश जानकारी याद रखता है',
      'q2_o3': 'सीमित समय के लिए जानकारी याद रखता है',
      'q2_o4': 'जानकारी याद रखने में कठिनाई होती है',
      'q2_o5': 'जानकारी बिल्कुल याद नहीं रख सकता',

      'q3': 'क्या व्यक्ति निर्णय लेने की प्रक्रिया में जानकारी का उपयोग या विचार कर सकता है?',
      'q3_o1': 'सभी प्रासंगिक जानकारी का पूर्ण उपयोग और विचार कर सकता है',
      'q3_o2': 'अधिकांश जानकारी का प्रभावी ढंग से उपयोग और विचार कर सकता है',
      'q3_o3': 'जानकारी के उपयोग और विचार की कुछ क्षमता दिखाता है',
      'q3_o4': 'जानकारी के उपयोग या विचार की सीमित क्षमता',
      'q3_o5': 'जानकारी का उपयोग या विचार नहीं कर सकता',

      'q4': 'क्या व्यक्ति अपना निर्णय (किसी भी माध्यम से) संप्रेषित कर सकता है?',
      'q4_o1': 'बोलकर/लिखकर/अन्य माध्यमों से स्पष्ट रूप से निर्णय संप्रेषित कर सकता है',
      'q4_o2': 'कुछ सहायता से निर्णय संप्रेषित कर सकता है',
      'q4_o3': 'महत्वपूर्ण सहायता से निर्णय संप्रेषित कर सकता है',
      'q4_o4': 'निर्णय को स्पष्ट रूप से संप्रेषित करने में कठिनाई',
      'q4_o5': 'किसी भी माध्यम से अपना निर्णय संप्रेषित नहीं कर सकता',

      'q5': 'क्या व्यक्ति निर्णय लेने या न लेने के परिणामों की सराहना करता है?',
      'q5_o1': 'सभी संभावित परिणामों की पूर्ण सराहना करता है',
      'q5_o2': 'अधिकांश परिणामों की सराहना करता है',
      'q5_o3': 'परिणामों की आंशिक सराहना',
      'q5_o4': 'परिणामों की सीमित सराहना',
      'q5_o5': 'परिणामों की सराहना नहीं करता',

      'q6': 'क्या व्यक्ति का निर्णय उनके ज्ञात मूल्यों और विश्वासों के अनुरूप है?',
      'q6_o1': 'निर्णय ज्ञात मूल्यों/विश्वासों के साथ पूरी तरह अनुरूप है',
      'q6_o2': 'निर्णय अधिकतर अनुरूप है',
      'q6_o3': 'ज्ञात मूल्यों/विश्वासों के साथ कुछ असंगति',
      'q6_o4': 'निर्णय मूल्यों/विश्वासों के साथ असंगत प्रतीत होता है',
      'q6_o5': 'निर्धारित करने में असमर्थ या स्पष्ट रूप से असंगत',

      'q7': 'क्या मन या मस्तिष्क की कार्यप्रणाली में कोई दोष या गड़बड़ी है?',
      'q7_o1': 'कोई दोष या गड़बड़ी नहीं पहचानी गई',
      'q7_o2': 'मामूली दोष जो निर्णय लेने को प्रभावित नहीं करता',
      'q7_o3': 'मध्यम दोष जो निर्णय लेने को प्रभावित कर सकता है',
      'q7_o4': 'निर्णय लेने को प्रभावित करने वाला महत्वपूर्ण दोष',
      'q7_o5': 'निर्णय लेने को रोकने वाला गंभीर दोष',

      'q8': 'क्या यह इस निर्णय के लिए क्षमता का मूल्यांकन करने का सही समय है?',
      'q8_o1': 'सर्वोत्तम समय - व्यक्ति अपने सर्वश्रेष्ठ में है',
      'q8_o2': 'अच्छा समय - व्यक्ति उचित रूप से सतर्क और केंद्रित है',
      'q8_o3': 'कुछ सीमाओं के साथ स्वीकार्य समय',
      'q8_o4': 'उपयुक्त समय नहीं - मूल्यांकन को दोहराने की आवश्यकता हो सकती है',
      'q8_o5': 'उचित समय नहीं - मूल्यांकन स्थगित करें',

      'q9': 'क्या व्यक्ति को निर्णय लेने में मदद करने के लिए सभी व्यावहारिक सहायता प्रदान की गई है?',
      'q9_o1': 'सभी व्यावहारिक सहायता प्रदान की गई है',
      'q9_o2': 'अधिकांश सहायता विकल्पों का पता लगाया गया है',
      'q9_o3': 'कुछ सहायता प्रदान की गई है',
      'q9_o4': 'सीमित सहायता की पेशकश की गई है',
      'q9_o5': 'कोई अतिरिक्त सहायता प्रदान नहीं की गई',

      'q10': 'क्या व्यक्ति निर्णय में शामिल जोखिमों को समझता है?',
      'q10_o1': 'सभी जोखिमों को पूरी तरह समझता है',
      'q10_o2': 'अधिकांश महत्वपूर्ण जोखिमों को समझता है',
      'q10_o3': 'जोखिमों की आंशिक समझ',
      'q10_o4': 'जोखिमों की सीमित समझ',
      'q10_o5': 'जोखिमों को नहीं समझता',

      'q11': 'क्या व्यक्ति को वैकल्पिक विकल्प प्रस्तुत किए गए हैं और उन्हें समझाया गया है?',
      'q11_o1': 'सभी विकल्प प्रस्तुत और समझाए गए',
      'q11_o2': 'अधिकांश विकल्प प्रस्तुत और समझाए गए',
      'q11_o3': 'आंशिक समझ के साथ कुछ विकल्प प्रस्तुत किए गए',
      'q11_o4': 'सीमित विकल्पों पर चर्चा की गई',
      'q11_o5': 'कोई विकल्प प्रस्तुत नहीं किया गया या समझ में नहीं आया',

      'q12': 'क्या व्यक्ति की क्षमता में उतार-चढ़ाव होने या सुधार होने की संभावना है?',
      'q12_o1': 'क्षमता स्थिर है और बदलने की संभावना नहीं है',
      'q12_o2': 'समय/उपचार के साथ क्षमता में सुधार हो सकता है',
      'q12_o3': 'क्षमता में उतार-चढ़ाव होता है - पुनर्मूल्यांकन की आवश्यकता हो सकती है',
      'q12_o4': 'क्षमता में गिरावट हो रही है',
      'q12_o5': 'उतार-चढ़ाव पैटर्न निर्धारित नहीं कर सकते',

      'q13': 'मूल्यांकन के आधार पर, समग्र क्षमता निर्धारण क्या है?',
      'q13_o1': 'इस निर्णय के लिए क्षमता है',
      'q13_o2': 'इस निर्णय के लिए क्षमता नहीं है',
      'q13_o3': 'अस्थिर क्षमता - पुनर्मूल्यांकन की आवश्यकता',
      'q13_o4': 'आगे विशेषज्ञ मूल्यांकन की आवश्यकता',
      'q13_o5': 'इस समय मूल्यांकन पूरा करने में असमर्थ',

      // Categories - Hindi
      'cat_understanding': 'समझ',
      'cat_retaining': 'धारण',
      'cat_using': 'जानकारी का उपयोग',
      'cat_communication': 'संवाद',
      'cat_appreciation': 'सराहना',
      'cat_consistency': 'निरंतरता',
      'cat_impairment': 'मानसिक दोष',
      'cat_timing': 'समय',
      'cat_support': 'सहायता',
      'cat_risk': 'जोखिम जागरूकता',
      'cat_alternatives': 'विकल्प',
      'cat_fluctuation': 'उतार-चढ़ाव',
      'cat_determination': 'समग्र निर्धारण',
    },

    'ta': {
      // App strings - Tamil
      'app_title': 'மனநல திறன் மதிப்பீடு',
      'welcome_back': 'மீண்டும் வரவேற்கிறோம்,',
      'new_assessment': 'புதிய மதிப்பீடு',
      'start_assessment': 'மதிப்பீட்டைத் தொடங்கு',
      'history': 'வரலாறு',
      'analytics': 'பகுப்பாய்வு',
      'today': 'இன்று',
      'week': 'இந்த வாரம்',
      'total': 'மொத்தம்',
      'patient_info': 'நோயாளி தகவல்',
      'enter_details': 'மதிப்பீட்டைத் தொடங்க விவரங்களை உள்ளிடவும்',
      'patient_name': 'நோயாளி பெயர்',
      'enter_full_name': 'முழு பெயரை உள்ளிடவும்',
      'age': 'வயது',
      'years': 'ஆண்டுகள்',
      'sex': 'பாலினம்',
      'male': 'ஆண்',
      'female': 'பெண்',
      'previous': 'முந்தைய',
      'next': 'அடுத்து',
      'submit': 'சமர்ப்பி',
      'done': 'முடிந்தது',
      'assessment_complete': 'மதிப்பீடு முடிந்தது',
      'determination': 'தீர்மானம்',
      'recommendations': 'பரிந்துரைகள்',
      'new_assessment_btn': 'புதிய மதிப்பீடு',
      'select_response': 'ஒரு பதிலைத் தேர்ந்தெடுக்கவும்',
      'question': 'கேள்வி',
      'of': '/',
      'settings': 'அமைப்புகள்',
      'language': 'மொழி',
      'select_language': 'மொழியைத் தேர்ந்தெடுக்கவும்',
      'has_capacity': 'இந்த முடிவுக்கான திறன் உள்ளது',
      'lacks_capacity': 'இந்த முடிவுக்கான திறன் இல்லை',
      'partial_capacity': 'பகுதி திறன் - ஆதரவு தேவைப்படலாம்',
      'fluctuating': 'மாறுபடும் திறன் - மறுமதிப்பீடு தேவை',

      // Questions - Tamil
      'q1': 'முடிவுக்கு தொடர்புடைய தகவல்களை நபர் புரிந்துகொள்கிறாரா?',
      'q1_o1': 'அனைத்து தொடர்புடைய தகவல்களையும் முழுமையாக புரிந்துகொள்கிறார்',
      'q1_o2': 'பெரும்பாலான தொடர்புடைய தகவல்களைப் புரிந்துகொள்கிறார்',
      'q1_o3': 'சில குறைபாடுகளுடன் பகுதி புரிதல்',
      'q1_o4': 'தொடர்புடைய தகவல்களின் குறைந்த புரிதல்',
      'q1_o5': 'தொடர்புடைய தகவல்களைப் புரிந்துகொள்ள இயலாது',

      'q2': 'முடிவெடுக்க போதுமான நேரம் தகவலை நினைவில் வைத்திருக்க முடியுமா?',
      'q2_o1': 'முடிவெடுக்கும் செயல்முறை முழுவதும் தகவலை முழுமையாக நினைவில் வைத்திருக்கிறார்',
      'q2_o2': 'சிறு தவறுகளுடன் பெரும்பாலான தகவலை நினைவில் வைத்திருக்கிறார்',
      'q2_o3': 'குறைந்த நேரத்திற்கு தகவலை நினைவில் வைத்திருக்கிறார்',
      'q2_o4': 'தகவலை நினைவில் வைத்திருப்பதில் சிரமம்',
      'q2_o5': 'தகவலை நினைவில் வைத்திருக்க இயலாது',

      'q3': 'முடிவெடுக்கும் செயல்முறையின் பகுதியாக தகவலைப் பயன்படுத்த அல்லது எடைபோட முடியுமா?',
      'q3_o1': 'அனைத்து தொடர்புடைய தகவல்களையும் முழுமையாக பயன்படுத்தவும் எடைபோடவும் முடியும்',
      'q3_o2': 'பெரும்பாலான தகவல்களை திறம்பட பயன்படுத்தவும் எடைபோடவும் முடியும்',
      'q3_o3': 'தகவலைப் பயன்படுத்தவும் எடைபோடவும் சில திறன் காட்டுகிறார்',
      'q3_o4': 'தகவலைப் பயன்படுத்த அல்லது எடைபோட குறைந்த திறன்',
      'q3_o5': 'தகவலைப் பயன்படுத்த அல்லது எடைபோட இயலாது',

      'q4': 'நபர் தங்கள் முடிவை (எந்த வழியிலும்) தெரிவிக்க முடியுமா?',
      'q4_o1': 'பேச்சு/எழுத்து/பிற வழிகளில் முடிவை தெளிவாக தெரிவிக்க முடியும்',
      'q4_o2': 'சில ஆதரவுடன் முடிவை தெரிவிக்க முடியும்',
      'q4_o3': 'குறிப்பிடத்தக்க உதவியுடன் முடிவை தெரிவிக்க முடியும்',
      'q4_o4': 'முடிவை தெளிவாக தெரிவிப்பதில் சிரமம்',
      'q4_o5': 'எந்த வழியிலும் முடிவை தெரிவிக்க இயலாது',

      'q5': 'முடிவெடுப்பது அல்லது எடுக்காததன் விளைவுகளை நபர் உணர்கிறாரா?',
      'q5_o1': 'அனைத்து சாத்தியமான விளைவுகளையும் முழுமையாக உணர்கிறார்',
      'q5_o2': 'பெரும்பாலான விளைவுகளை உணர்கிறார்',
      'q5_o3': 'விளைவுகளின் பகுதி உணர்வு',
      'q5_o4': 'விளைவுகளின் குறைந்த உணர்வு',
      'q5_o5': 'விளைவுகளை உணரவில்லை',

      'q6': 'நபரின் முடிவு அவர்களின் அறியப்பட்ட மதிப்புகள் மற்றும் நம்பிக்கைகளுடன் ஒத்துப்போகிறதா?',
      'q6_o1': 'முடிவு அறியப்பட்ட மதிப்புகள்/நம்பிக்கைகளுடன் முழுமையாக ஒத்துப்போகிறது',
      'q6_o2': 'முடிவு பெரும்பாலும் ஒத்துப்போகிறது',
      'q6_o3': 'அறியப்பட்ட மதிப்புகள்/நம்பிக்கைகளுடன் சில முரண்பாடு',
      'q6_o4': 'முடிவு மதிப்புகள்/நம்பிக்கைகளுடன் முரண்படுவதாகத் தெரிகிறது',
      'q6_o5': 'தீர்மானிக்க இயலாது அல்லது தெளிவாக முரண்படுகிறது',

      'q7': 'மன அல்லது மூளை செயல்பாட்டில் குறைபாடு அல்லது தடங்கல் உள்ளதா?',
      'q7_o1': 'குறைபாடு அல்லது தடங்கல் எதுவும் கண்டறியப்படவில்லை',
      'q7_o2': 'முடிவெடுப்பதை பாதிக்காத சிறிய குறைபாடு',
      'q7_o3': 'முடிவெடுப்பதை பாதிக்கக்கூடிய மிதமான குறைபாடு',
      'q7_o4': 'முடிவெடுப்பதை பாதிக்கும் குறிப்பிடத்தக்க குறைபாடு',
      'q7_o5': 'முடிவெடுப்பதைத் தடுக்கும் கடுமையான குறைபாடு',

      'q8': 'இந்த முடிவுக்கான திறனை மதிப்பிட இது சரியான நேரமா?',
      'q8_o1': 'சிறந்த நேரம் - நபர் அவர்களின் சிறந்த நிலையில் உள்ளார்',
      'q8_o2': 'நல்ல நேரம் - நபர் நியாயமான அளவில் விழிப்பாகவும் கவனமாகவும் உள்ளார்',
      'q8_o3': 'சில வரம்புகளுடன் ஏற்றுக்கொள்ளக்கூடிய நேரம்',
      'q8_o4': 'உகந்த நேரம் அல்ல - மதிப்பீடு மீண்டும் செய்யப்பட வேண்டும்',
      'q8_o5': 'பொருத்தமான நேரம் அல்ல - மதிப்பீட்டை ஒத்திவைக்கவும்',

      'q9': 'முடிவெடுக்க நபருக்கு உதவ அனைத்து நடைமுறை ஆதரவும் வழங்கப்பட்டுள்ளதா?',
      'q9_o1': 'அனைத்து நடைமுறை ஆதரவும் வழங்கப்பட்டுள்ளது',
      'q9_o2': 'பெரும்பாலான ஆதரவு விருப்பங்கள் ஆராயப்பட்டுள்ளன',
      'q9_o3': 'சில ஆதரவு வழங்கப்பட்டுள்ளது',
      'q9_o4': 'குறைந்த ஆதரவு வழங்கப்பட்டுள்ளது',
      'q9_o5': 'கூடுதல் ஆதரவு எதுவும் வழங்கப்படவில்லை',

      'q10': 'முடிவில் உள்ள அபாயங்களை நபர் புரிந்துகொள்கிறாரா?',
      'q10_o1': 'அனைத்து அபாயங்களையும் முழுமையாக புரிந்துகொள்கிறார்',
      'q10_o2': 'பெரும்பாலான முக்கிய அபாயங்களைப் புரிந்துகொள்கிறார்',
      'q10_o3': 'அபாயங்களின் பகுதி புரிதல்',
      'q10_o4': 'அபாயங்களின் குறைந்த புரிதல்',
      'q10_o5': 'அபாயங்களைப் புரிந்துகொள்ளவில்லை',

      'q11': 'நபருக்கு மாற்று விருப்பங்கள் வழங்கப்பட்டு புரிந்திருக்கிறதா?',
      'q11_o1': 'அனைத்து மாற்றுகளும் வழங்கப்பட்டு புரிந்துகொள்ளப்பட்டன',
      'q11_o2': 'பெரும்பாலான மாற்றுகள் வழங்கப்பட்டு புரிந்துகொள்ளப்பட்டன',
      'q11_o3': 'பகுதி புரிதலுடன் சில மாற்றுகள் வழங்கப்பட்டன',
      'q11_o4': 'குறைந்த மாற்றுகள் விவாதிக்கப்பட்டன',
      'q11_o5': 'மாற்றுகள் எதுவும் வழங்கப்படவில்லை அல்லது புரிந்துகொள்ளவில்லை',

      'q12': 'நபரின் திறன் மாறவோ அல்லது மேம்படவோ வாய்ப்புள்ளதா?',
      'q12_o1': 'திறன் நிலையானது மற்றும் மாற வாய்ப்பில்லை',
      'q12_o2': 'நேரம்/சிகிச்சையுடன் திறன் மேம்படலாம்',
      'q12_o3': 'திறன் மாறுபடுகிறது - மறுமதிப்பீடு தேவைப்படலாம்',
      'q12_o4': 'திறன் குறைந்து வருகிறது',
      'q12_o5': 'மாறுபாட்டு முறையை தீர்மானிக்க இயலாது',

      'q13': 'மதிப்பீட்டின் அடிப்படையில், ஒட்டுமொத்த திறன் தீர்மானம் என்ன?',
      'q13_o1': 'இந்த முடிவுக்கான திறன் உள்ளது',
      'q13_o2': 'இந்த முடிவுக்கான திறன் இல்லை',
      'q13_o3': 'மாறுபடும் திறன் - மறுமதிப்பீடு தேவை',
      'q13_o4': 'மேலும் நிபுணர் மதிப்பீடு தேவை',
      'q13_o5': 'இந்த நேரத்தில் மதிப்பீட்டை முடிக்க இயலவில்லை',

      // Categories - Tamil
      'cat_understanding': 'புரிதல்',
      'cat_retaining': 'நினைவில் வைத்தல்',
      'cat_using': 'தகவல் பயன்பாடு',
      'cat_communication': 'தகவல் தொடர்பு',
      'cat_appreciation': 'மதிப்பீடு',
      'cat_consistency': 'நிலைத்தன்மை',
      'cat_impairment': 'மன குறைபாடு',
      'cat_timing': 'நேரம்',
      'cat_support': 'ஆதரவு',
      'cat_risk': 'ஆபத்து விழிப்புணர்வு',
      'cat_alternatives': 'மாற்றுகள்',
      'cat_fluctuation': 'மாறுபாடு',
      'cat_determination': 'ஒட்டுமொத்த தீர்மானம்',
    },
  };
}
