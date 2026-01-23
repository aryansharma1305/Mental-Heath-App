import '../models/question.dart';

class AssessmentQuestions {

  static const List<String> standardOptions = [
    'None - Not at all',
    'Slight - Rare, less than a day or two',
    'Mild - Several days',
    'Moderate - More than half the days',
    'Severe - Nearly every day',
  ];
  static List<Question> getStandardQuestions() {
    return [
      Question(
        text: 'Little interest or pleasure in doing things?',
        type: QuestionType.multipleChoice,
        options: standardOptions,
        required: true,
        category: 'I. Depression',
        order: 1,
      ),
      Question(
        text: 'Feeling down, depressed, or hopeless?',
        type: QuestionType.multipleChoice,
        options: standardOptions,
        required: true,
        category: 'I. Depression',
        order: 2,
      ),
      
      Question(
        text: 'Feeling more irritated, grouchy, or angry than usual?',
        type: QuestionType.multipleChoice,
        options: standardOptions,
        required: true,
        category: 'II. Anger',
        order: 3,
      ),
      Question(
        text: 'Sleeping less than usual, but still have a lot of energy?',
        type: QuestionType.multipleChoice,
        options: standardOptions,
        required: true,
        category: 'III. Mania',
        order: 4,
      ),
      Question(
        text: 'Starting lots more projects than usual or doing more risky things than usual?',
        type: QuestionType.multipleChoice,
        options: standardOptions,
        required: true,
        category: 'III. Mania',
        order: 5,
      ),
      
      // Domain IV: Anxiety (Questions 6-8)
      Question(
        text: 'Feeling nervous, anxious, frightened, worried, or on edge?',
        type: QuestionType.multipleChoice,
        options: standardOptions,
        required: true,
        category: 'IV. Anxiety',
        order: 6,
      ),
      Question(
        text: 'Feeling panic or being frightened?',
        type: QuestionType.multipleChoice,
        options: standardOptions,
        required: true,
        category: 'IV. Anxiety',
        order: 7,
      ),
      Question(
        text: 'Avoiding situations that make you anxious?',
        type: QuestionType.multipleChoice,
        options: standardOptions,
        required: true,
        category: 'IV. Anxiety',
        order: 8,
      ),
      
      Question(
        text: 'Unexplained aches and pains (e.g., head, back, joints, abdomen, legs)?',
        type: QuestionType.multipleChoice,
        options: standardOptions,
        required: true,
        category: 'V. Somatic Symptoms',
        order: 9,
      ),
      Question(
        text: 'Feeling that your illnesses are not being taken seriously enough?',
        type: QuestionType.multipleChoice,
        options: standardOptions,
        required: true,
        category: 'V. Somatic Symptoms',
        order: 10,
      ),
    
      Question(
        text: 'Thoughts of actually hurting yourself?',
        type: QuestionType.multipleChoice,
        options: standardOptions,
        required: true,
        category: 'VI. Suicidal Ideation',
        order: 11,
      ),
      
      Question(
        text: 'Hearing things other people couldn\'t hear, such as voices even when no one was around?',
        type: QuestionType.multipleChoice,
        options: standardOptions,
        required: true,
        category: 'VII. Psychosis',
        order: 12,
      ),
      Question(
        text: 'Feeling that someone could hear your thoughts, or that you could hear what another person was thinking?',
        type: QuestionType.multipleChoice,
        options: standardOptions,
        required: true,
        category: 'VII. Psychosis',
        order: 13,
      ),
    
      Question(
        text: 'Problems with sleep that affected your sleep quality over all?',
        type: QuestionType.multipleChoice,
        options: standardOptions,
        required: true,
        category: 'VIII. Sleep Problems',
        order: 14,
      ),
      
      Question(
        text: 'Problems with memory (e.g., learning new information) or with location (e.g., finding your way home)?',
        type: QuestionType.multipleChoice,
        options: standardOptions,
        required: true,
        category: 'IX. Memory',
        order: 15,
      ),
      
      Question(
        text: 'Unpleasant thoughts, urges, or images that repeatedly enter your mind?',
        type: QuestionType.multipleChoice,
        options: standardOptions,
        required: true,
        category: 'X. Repetitive Thoughts',
        order: 16,
      ),
      Question(
        text: 'Feeling driven to perform certain behaviors or mental acts over and over again?',
        type: QuestionType.multipleChoice,
        options: standardOptions,
        required: true,
        category: 'X. Repetitive Thoughts',
        order: 17,
      ),
      
      // Domain XI: Dissociation (Question 18)
      Question(
        text: 'Feeling detached or distant from yourself, your body, your physical surroundings, or your memories?',
        type: QuestionType.multipleChoice,
        options: standardOptions,
        required: true,
        category: 'XI. Dissociation',
        order: 18,
      ),
      
      // Domain XII: Personality Functioning (Questions 19-20)
      Question(
        text: 'Not knowing who you really are or what you want out of life?',
        type: QuestionType.multipleChoice,
        options: standardOptions,
        required: true,
        category: 'XII. Personality Functioning',
        order: 19,
      ),
      Question(
        text: 'Not feeling close to other people or enjoying your relationships with them?',
        type: QuestionType.multipleChoice,
        options: standardOptions,
        required: true,
        category: 'XII. Personality Functioning',
        order: 20,
      ),
      
      // Domain XIII: Substance Use (Questions 21-23)
      Question(
        text: 'Drinking at least 4 drinks of any kind of alcohol in a single day?',
        type: QuestionType.multipleChoice,
        options: standardOptions,
        required: true,
        category: 'XIII. Substance Use',
        order: 21,
      ),
      Question(
        text: 'Smoking any cigarettes, a cigar, or pipe, or using snuff or chewing tobacco?',
        type: QuestionType.multipleChoice,
        options: standardOptions,
        required: true,
        category: 'XIII. Substance Use',
        order: 22,
      ),
      Question(
        text: 'Using any of the following medicines ON YOUR OWN, that is, without a doctor\'s prescription, in greater amounts or longer than prescribed (e.g., painkillers like Vicodin, stimulants like Ritalin or Adderall, sedatives or tranquilizers like sleeping pills or Valium, or drugs like marijuana, cocaine or crack, club drugs like ecstasy, hallucinogens like LSD, heroin, inhalants or solvents like glue, or methamphetamine like speed)?',
        type: QuestionType.multipleChoice,
        options: standardOptions,
        required: true,
        category: 'XIII. Substance Use',
        order: 23,
      ),
    ];
  }

  /// Get the response options
  static List<String> getResponseOptions() {
    return standardOptions;
  }

  /// Calculate domain scores based on responses
  /// Returns map with total score, domain scores, and severity
  static Map<String, dynamic> calculateCapacityScore(Map<String, dynamic> responses) {
    int totalScore = 0;
    int maxScore = 0;
    Map<String, int> domainScores = {};
    Map<String, int> domainMaxScores = {};
    
    final questions = getStandardQuestions();
    
    for (var entry in responses.entries) {
      final answer = entry.value as String;
      final question = questions.firstWhere(
        (q) => q.questionId == entry.key,
        orElse: () => questions.first,
      );
      
      // Score: None=0, Slight=1, Mild=2, Moderate=3, Severe=4
      final options = question.options ?? standardOptions;
      final index = options.indexOf(answer);
      final score = index >= 0 ? index : 0;
      
      totalScore += score;
      maxScore += 4;
      
      final domain = question.category ?? 'Unknown';
      domainScores[domain] = (domainScores[domain] ?? 0) + score;
      domainMaxScores[domain] = (domainMaxScores[domain] ?? 0) + 4;
    }
    
    final percentage = maxScore > 0 ? (totalScore / maxScore * 100) : 0.0;
    
    // Calculate domain percentages
    Map<String, double> domainPercentages = {};
    domainScores.forEach((domain, score) {
      final maxForDomain = domainMaxScores[domain] ?? 4;
      domainPercentages[domain] = (score / maxForDomain) * 100;
    });
    
    return {
      'totalScore': totalScore,
      'maxScore': maxScore,
      'percentage': percentage,
      'categoryScores': domainScores,
      'domainMaxScores': domainMaxScores,
      'domainPercentages': domainPercentages,
    };
  }

  /// Get overall severity based on score percentage
  static String getCapacityDetermination(double percentage) {
    if (percentage < 10) {
      return 'No significant symptoms';
    } else if (percentage < 25) {
      return 'Mild symptoms - Consider further monitoring';
    } else if (percentage < 50) {
      return 'Moderate symptoms - Further evaluation recommended';
    } else if (percentage < 75) {
      return 'Significant symptoms - Clinical evaluation needed';
    } else {
      return 'Severe symptoms - Urgent clinical attention required';
    }
  }

  /// Get severity interpretation based on total score
  static String getSeverityInterpretation(int totalScore) {
    if (totalScore <= 10) {
      return 'Minimal symptoms';
    } else if (totalScore <= 25) {
      return 'Mild symptoms';
    } else if (totalScore <= 45) {
      return 'Moderate symptoms';
    } else if (totalScore <= 65) {
      return 'Moderately severe symptoms';
    } else {
      return 'Severe symptoms';
    }
  }

  /// Get capacity options for overall assessment
  static List<String> getCapacityOptions() {
    return [
      'Has capacity for this decision',
      'Lacks capacity for this decision',
      'Fluctuating capacity - reassessment needed',
      'Unable to determine - further evaluation required',
    ];
  }

  /// Calculate domain scores from responses
  static Map<String, int> calculateDomainScores(Map<String, dynamic> responses) {
    Map<String, int> domainScores = {};
    final questions = getStandardQuestions();
    
    for (var entry in responses.entries) {
      final answer = entry.value.toString();
      final question = questions.firstWhere(
        (q) => q.questionId == entry.key,
        orElse: () => questions.first,
      );
      
      final options = question.options ?? standardOptions;
      final index = options.indexOf(answer);
      final score = index >= 0 ? index : 0;
      
      final domain = question.category ?? 'Unknown';
      domainScores[domain] = (domainScores[domain] ?? 0) + score;
    }
    
    return domainScores;
  }

  /// Get domains requiring follow-up based on scores
  static List<String> getDomainsRequiringFollowUp(Map<String, int> domainScores) {
    List<String> flaggedDomains = [];
    
    domainScores.forEach((domain, score) {
      // Flag if score is >= 2 (Mild or higher) for most domains
      // For Suicidal Ideation, flag if score >= 1
      if (domain.contains('Suicidal') && score >= 1) {
        flaggedDomains.add(domain);
      } else if (score >= 2) {
        flaggedDomains.add(domain);
      }
    });
    
    return flaggedDomains;
  }

  /// Get clinical recommendations based on domain scores
  static List<String> getRecommendations(double percentage, Map<String, int> domainScores) {
    List<String> recommendations = [];
    domainScores.forEach((domain, score) {
      if (domain.contains('Suicidal') && score >= 1) {
        recommendations.add('CRITICAL: Assess for suicide risk immediately');
      } else if (domain.contains('Psychosis') && score >= 2) {
        recommendations.add('Consider psychiatric evaluation for psychotic symptoms');
      } else if (domain.contains('Depression') && score >= 4) {
        recommendations.add('Screen for depressive disorder (PHQ-9 recommended)');
      } else if (domain.contains('Anxiety') && score >= 4) {
        recommendations.add('Screen for anxiety disorder (GAD-7 recommended)');
      } else if (domain.contains('Mania') && score >= 2) {
        recommendations.add('Screen for bipolar disorder');
      } else if (domain.contains('Substance') && score >= 1) {
        recommendations.add('Assess substance use patterns');
      } else if (domain.contains('Sleep') && score >= 2) {
        recommendations.add('Evaluate sleep disturbances');
      }
    });
    
    // General recommendations based on overall score
    if (percentage >= 50) {
      recommendations.add('Comprehensive psychiatric evaluation recommended');
    } else if (percentage >= 25) {
      recommendations.add('Consider follow-up assessment in 2-4 weeks');
    }
    
    if (recommendations.isEmpty) {
      recommendations.add('Continue routine monitoring');
    }
    
    return recommendations;
  }

  /// Get domains requiring Level 2 assessment
  static List<String> getDomainsNeedingLevel2(Map<String, dynamic> responses) {
    List<String> domainsNeedingLevel2 = [];
    
    final questions = getStandardQuestions();
    Map<String, int> domainHighestScores = {};
    
    for (var entry in responses.entries) {
      final answer = entry.value as String;
      final question = questions.firstWhere(
        (q) => q.questionId == entry.key,
        orElse: () => questions.first,
      );
      
      final options = question.options ?? standardOptions;
      final index = options.indexOf(answer);
      final score = index >= 0 ? index : 0;
      
      final domain = question.category ?? 'Unknown';
      if (score > (domainHighestScores[domain] ?? 0)) {
        domainHighestScores[domain] = score;
      }
    }
    
    // Threshold is typically "Mild" (2) or higher for most domains
    // "Slight" (1) for Suicidal Ideation
    domainHighestScores.forEach((domain, highestScore) {
      if (domain.contains('Suicidal') && highestScore >= 1) {
        domainsNeedingLevel2.add(domain);
      } else if (highestScore >= 2) {
        domainsNeedingLevel2.add(domain);
      }
    });
    
    return domainsNeedingLevel2;
  }
}
