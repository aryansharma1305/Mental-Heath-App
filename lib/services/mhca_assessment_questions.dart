/// MHCA Treatment Capacity Assessment Questions Service
/// 
/// Digitized version of the SRM Medical College Hospital
/// "Capacity Assessment for Treatment decisions including Admission"
/// form, per Mental Healthcare Act (MHCA) 2017, Sections 102/103.

class MHCAAssessmentQuestions {
  // ========== PURPOSE OPTIONS ==========
  static const List<String> purposeOptions = [
    'Admission',
    'Treatment',
    'Advance Directive',
    'Any Other',
  ];

  // ========== RESPONSE OPTIONS ==========
  static const List<String> yesNoOptions = ['Yes', 'No'];
  static const List<String> yesNoCannotOptions = ['Yes', 'No', 'Cannot assess'];
  static const List<String> advanceDirectiveOptions = ['Present', 'Absent'];

  // ========== SECTION DEFINITIONS ==========

  /// Gate question: Obvious Lack of Capacity
  static Map<String, dynamic> getGateQuestion() {
    return {
      'id': 'gate',
      'section': 'Obvious Lack of Capacity',
      'text': 'Is he/she in a condition, that one cannot have any kind of '
          'meaningful conversation with him/her (such as being violent, '
          'excited, catatonic, stuporous, delirious, under alcohol or '
          'substance intoxication/severe withdrawal, or any other)?',
      'type': 'yesNo',
      'options': yesNoOptions,
      'note': 'If yes, then go to 4. If no, then go to 1.',
    };
  }

  /// Section 1: Understanding
  static List<Map<String, dynamic>> getSection1Questions() {
    return [
      {
        'id': '1a',
        'section': '1. Understanding',
        'label': 'A',
        'text': 'Is the individual oriented to time, place and person?',
        'type': 'yesNoCannotAssess',
        'options': yesNoCannotOptions,
        'hasExplanation': true,
      },
      {
        'id': '1b',
        'section': '1. Understanding',
        'label': 'B',
        'text': 'Has he/she been provided relevant information about mental '
            'healthcare and treatment pertaining to the illness in question?',
        'type': 'yesNo',
        'options': yesNoOptions,
        'hasExplanation': true,
        'explanationHint': 'If no, provide explanation',
      },
      {
        'id': '1c',
        'section': '1. Understanding',
        'label': 'C',
        'text': 'Is he/she able to follow simple commands like '
            '(i) show your tongue (ii) close your eyes?',
        'type': 'yesNoCannotAssess',
        'options': yesNoCannotOptions,
        'hasExplanation': true,
      },
      {
        'id': '1d',
        'section': '1. Understanding',
        'label': 'D',
        'text': 'Does he/she acknowledge that he has a mental illness?',
        'type': 'yesNoCannotAssess',
        'options': yesNoCannotOptions,
        'hasExplanation': true,
      },
    ];
  }

  /// Section 2: Appreciating foreseeable consequences
  static List<Map<String, dynamic>> getSection2Questions() {
    return [
      {
        'id': '2a',
        'section': '2. Appreciating',
        'label': 'A',
        'text': 'Does the individual agree to receive treatment '
            'suggested by the treating team?',
        'type': 'yesNoCannotAssess',
        'options': yesNoCannotOptions,
        'hasExplanation': true,
        'branchNote':
            'If yes, go to 2B. If no, go to 2C. If cannot assess, go to 3.',
      },
      {
        'id': '2b',
        'section': '2. Appreciating',
        'label': 'B',
        'text': 'Does he/she explain why he/she has agreed to receive treatment?',
        'type': 'yesNoCannotAssess',
        'options': ['Yes', 'No', 'Cannot assess'],
        'hasExplanation': true,
        'showWhen': {'2a': 'Yes'}, // Only show when 2A = Yes
      },
      {
        'id': '2c',
        'section': '2. Appreciating',
        'label': 'C',
        'text':
            'Does he/she explain why he/she does not agree to receive treatment?',
        'type': 'yesNoCannotAssess',
        'options': ['Yes', 'No', 'Cannot assess'],
        'hasExplanation': true,
        'showWhen': {'2a': 'No'}, // Only show when 2A = No
      },
    ];
  }

  /// Section 3: Communicating the decision
  static List<Map<String, dynamic>> getSection3Questions() {
    return [
      {
        'id': '3a',
        'section': '3. Communicating',
        'label': 'A',
        'text': 'Is the individual able to communicate his/her decision '
            'by means of speech, writing, expression, gesture or any other means?',
        'type': 'yesNoCannotAssess',
        'options': yesNoCannotOptions,
        'hasExplanation': true,
      },
    ];
  }

  /// Section 4: Final Determination
  static Map<String, dynamic> getSection4() {
    return {
      'id': 'determination',
      'section': '4. Final Determination',
      'text': 'Based on the examination and relevant history, behavioural '
          'observation, clinical findings and mental status examination '
          'findings noted in the medical records, I believe that the patient:',
      'options': [
        'a. Has capacity for treatment decisions including admission',
        'b. Needs 100% support from his/her nominated representative '
            'in making treatment decisions including admission',
      ],
    };
  }

  /// Section 5: Patient consent (if determination = a)
  static Map<String, dynamic> getSection5() {
    return {
      'id': 'patient_consent',
      'section': '5. Patient Consent',
      'text': 'I agree to make decisions in respect of my mental healthcare '
          'and treatment.',
      'showWhen': {'determination': 'a'},
      'requiresSignature': true,
    };
  }

  /// Section 6: Nominated representative consent (if determination = b)
  static Map<String, dynamic> getSection6() {
    return {
      'id': 'representative_consent',
      'section': '6. Nominated Representative Consent',
      'text': 'I, the nominated representative, agree to make decisions '
          'with respect of his/her treatment.',
      'showWhen': {'determination': 'b'},
      'requiresSignature': true,
      'requiresRepresentativeName': true,
    };
  }

  // ========== ALL QUESTIONS (flattened) ==========
  static List<Map<String, dynamic>> getAllQuestions() {
    return [
      getGateQuestion(),
      ...getSection1Questions(),
      ...getSection2Questions(),
      ...getSection3Questions(),
      getSection4(),
    ];
  }

  // ========== SCORING HELPERS ==========

  /// Determine if the assessment shows capacity 
  static String getDetermination(Map<String, dynamic> responses) {
    // If obvious lack of capacity
    if (responses['gate'] == 'Yes') {
      return 'Needs 100% support from nominated representative '
          'in making treatment decisions including admission';
    }

    // Check Section 4 determination if directly selected
    final det = responses['determination'];
    if (det == 'a') {
      return 'Has capacity for treatment decisions including admission';
    } else if (det == 'b') {
      return 'Needs 100% support from nominated representative '
          'in making treatment decisions including admission';
    }

    return 'Assessment incomplete';
  }

  /// Generate summary of assessment
  static Map<String, dynamic> generateSummary(Map<String, dynamic> responses) {
    final gateAnswer = responses['gate'] ?? 'Not answered';
    final determination = getDetermination(responses);

    // Count section responses
    int answeredCount = 0;
    int totalQuestions = 0;

    for (var q in getAllQuestions()) {
      final qId = q['id'] as String;
      if (responses.containsKey(qId)) answeredCount++;
      totalQuestions++;
    }

    return {
      'gate_answer': gateAnswer,
      'skipped_to_section4': gateAnswer == 'Yes',
      'determination': determination,
      'answered_count': answeredCount,
      'total_questions': totalQuestions,
      'section_1_complete': _isSectionComplete(responses, ['1a', '1b', '1c', '1d']),
      'section_2_complete': _isSectionComplete(responses, ['2a']),
      'section_3_complete': _isSectionComplete(responses, ['3a']),
      'section_4_complete': responses.containsKey('determination'),
    };
  }

  static bool _isSectionComplete(
      Map<String, dynamic> responses, List<String> questionIds) {
    return questionIds.every((id) => responses.containsKey(id));
  }
}
