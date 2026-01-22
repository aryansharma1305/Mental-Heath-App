import '../models/question.dart';

/// Mental Capacity Assessment Questions
/// Based on the Mental Capacity Act principles
class AssessmentQuestions {
  
  /// The 13 standard Mental Capacity Assessment questions
  /// Each has 5 multiple choice options
  static List<Question> getStandardQuestions() {
    return [
      // Question 1: Understanding
      Question(
        text: 'Does the person understand the information relevant to the decision?',
        type: QuestionType.multipleChoice,
        options: [
          'Fully understands all relevant information',
          'Understands most of the relevant information',
          'Partial understanding with some gaps',
          'Limited understanding of relevant information',
          'Cannot understand the relevant information',
        ],
        required: true,
        category: 'Understanding',
        order: 1,
      ),
      
      // Question 2: Retaining Information
      Question(
        text: 'Can the person retain the information long enough to make the decision?',
        type: QuestionType.multipleChoice,
        options: [
          'Retains information fully throughout the decision-making process',
          'Retains most information with minor lapses',
          'Retains information for a limited time',
          'Has difficulty retaining information',
          'Cannot retain the information at all',
        ],
        required: true,
        category: 'Retaining',
        order: 2,
      ),
      
      // Question 3: Using Information
      Question(
        text: 'Can the person use or weigh the information as part of the decision-making process?',
        type: QuestionType.multipleChoice,
        options: [
          'Can fully use and weigh all relevant information',
          'Can use and weigh most information effectively',
          'Shows some ability to use and weigh information',
          'Limited ability to use or weigh information',
          'Cannot use or weigh the information',
        ],
        required: true,
        category: 'Using Information',
        order: 3,
      ),
      
      // Question 4: Communicating Decision
      Question(
        text: 'Can the person communicate their decision (by any means)?',
        type: QuestionType.multipleChoice,
        options: [
          'Can clearly communicate decision by speech/writing/other means',
          'Can communicate decision with some support',
          'Can communicate decision with significant assistance',
          'Has difficulty communicating decision clearly',
          'Cannot communicate their decision by any means',
        ],
        required: true,
        category: 'Communication',
        order: 4,
      ),
      
      // Question 5: Appreciation of Consequences
      Question(
        text: 'Does the person appreciate the consequences of making or not making the decision?',
        type: QuestionType.multipleChoice,
        options: [
          'Fully appreciates all potential consequences',
          'Appreciates most consequences',
          'Partial appreciation of consequences',
          'Limited appreciation of consequences',
          'Does not appreciate the consequences',
        ],
        required: true,
        category: 'Appreciation',
        order: 5,
      ),
      
      // Question 6: Consistency
      Question(
        text: 'Is the person\'s decision consistent with their known values and beliefs?',
        type: QuestionType.multipleChoice,
        options: [
          'Decision is fully consistent with known values/beliefs',
          'Decision is mostly consistent',
          'Some inconsistency with known values/beliefs',
          'Decision appears inconsistent with values/beliefs',
          'Unable to determine or clearly inconsistent',
        ],
        required: true,
        category: 'Consistency',
        order: 6,
      ),
      
      // Question 7: Influence of Mental Disorder
      Question(
        text: 'Is there an impairment or disturbance in the functioning of the mind or brain?',
        type: QuestionType.multipleChoice,
        options: [
          'No impairment or disturbance identified',
          'Minor impairment that does not affect decision-making',
          'Moderate impairment that may affect decision-making',
          'Significant impairment affecting decision-making',
          'Severe impairment preventing decision-making',
        ],
        required: true,
        category: 'Mental Impairment',
        order: 7,
      ),
      
      // Question 8: Timing
      Question(
        text: 'Is this the right time to assess capacity for this decision?',
        type: QuestionType.multipleChoice,
        options: [
          'Optimal time - person is at their best',
          'Good time - person is reasonably alert and focused',
          'Acceptable time with some limitations',
          'Suboptimal time - assessment may need to be repeated',
          'Not appropriate time - defer assessment',
        ],
        required: true,
        category: 'Timing',
        order: 8,
      ),
      
      // Question 9: Support Provided
      Question(
        text: 'Has all practicable support been provided to help the person make the decision?',
        type: QuestionType.multipleChoice,
        options: [
          'All practicable support has been provided',
          'Most support options have been explored',
          'Some support has been provided',
          'Limited support has been offered',
          'No additional support has been provided',
        ],
        required: true,
        category: 'Support',
        order: 9,
      ),
      
      // Question 10: Risk Awareness
      Question(
        text: 'Does the person understand the risks involved in the decision?',
        type: QuestionType.multipleChoice,
        options: [
          'Fully understands all risks',
          'Understands most significant risks',
          'Partial understanding of risks',
          'Limited understanding of risks',
          'Does not understand the risks',
        ],
        required: true,
        category: 'Risk Awareness',
        order: 10,
      ),
      
      // Question 11: Alternatives Considered
      Question(
        text: 'Has the person been presented with and understood alternative options?',
        type: QuestionType.multipleChoice,
        options: [
          'All alternatives presented and understood',
          'Most alternatives presented and understood',
          'Some alternatives presented with partial understanding',
          'Limited alternatives discussed',
          'No alternatives presented or not understood',
        ],
        required: true,
        category: 'Alternatives',
        order: 11,
      ),
      
      // Question 12: Fluctuating Capacity
      Question(
        text: 'Is the person\'s capacity likely to fluctuate or improve?',
        type: QuestionType.multipleChoice,
        options: [
          'Capacity is stable and unlikely to change',
          'Capacity may improve with time/treatment',
          'Capacity fluctuates - may need reassessment',
          'Capacity is declining',
          'Cannot determine fluctuation pattern',
        ],
        required: true,
        category: 'Fluctuation',
        order: 12,
      ),
      
      // Question 13: Overall Capacity Determination
      Question(
        text: 'Based on the assessment, what is the overall capacity determination?',
        type: QuestionType.multipleChoice,
        options: [
          'Has capacity for this decision',
          'Lacks capacity for this decision',
          'Fluctuating capacity - reassessment needed',
          'Requires further specialist assessment',
          'Unable to complete assessment at this time',
        ],
        required: true,
        category: 'Overall Determination',
        order: 13,
      ),
    ];
  }

  /// Get capacity options for the final determination
  static List<String> getCapacityOptions() {
    return [
      'Has capacity for this decision',
      'Lacks capacity for this decision',
      'Fluctuating capacity - reassessment needed',
      'Requires further specialist assessment',
      'Unable to complete assessment at this time',
    ];
  }

  /// Calculate capacity score based on responses
  /// Returns a map with score details
  static Map<String, dynamic> calculateCapacityScore(Map<String, dynamic> responses) {
    int totalScore = 0;
    int maxScore = 0;
    Map<String, int> categoryScores = {};
    
    for (var entry in responses.entries) {
      final answer = entry.value as String;
      final question = getStandardQuestions().firstWhere(
        (q) => q.questionId == entry.key,
        orElse: () => getStandardQuestions().first,
      );
      
      // Score: first option = 4, last option = 0
      final options = question.options ?? [];
      final index = options.indexOf(answer);
      final score = index >= 0 ? (4 - index) : 0;
      
      totalScore += score;
      maxScore += 4;
      
      final category = question.category ?? 'Unknown';
      categoryScores[category] = (categoryScores[category] ?? 0) + score;
    }
    
    final percentage = maxScore > 0 ? (totalScore / maxScore * 100) : 0.0;
    
    return {
      'totalScore': totalScore,
      'maxScore': maxScore,
      'percentage': percentage,
      'categoryScores': categoryScores,
    };
  }

  /// Get capacity determination based on score percentage
  static String getCapacityDetermination(double percentage) {
    if (percentage >= 80) {
      return 'Has capacity for this decision';
    } else if (percentage >= 60) {
      return 'Partial capacity - may need support';
    } else if (percentage >= 40) {
      return 'Fluctuating capacity - reassessment needed';
    } else {
      return 'Lacks capacity for this decision';
    }
  }

  /// Get recommendations based on capacity score
  static List<String> getRecommendations(double percentage, Map<String, int> categoryScores) {
    List<String> recommendations = [];
    
    if (percentage < 80) {
      // Check weak categories
      categoryScores.forEach((category, score) {
        if (score < 3) {
          switch (category) {
            case 'Understanding':
              recommendations.add('Provide information in simpler format or different modality');
              break;
            case 'Retaining':
              recommendations.add('Use memory aids or written information');
              break;
            case 'Using Information':
              recommendations.add('Allow more time for processing information');
              break;
            case 'Communication':
              recommendations.add('Consider alternative communication methods');
              break;
            case 'Support':
              recommendations.add('Explore additional support options');
              break;
            case 'Timing':
              recommendations.add('Reassess at a more optimal time');
              break;
          }
        }
      });
    }
    
    if (percentage < 60) {
      recommendations.add('Consider specialist assessment');
      recommendations.add('Document reasons for capacity determination');
    }
    
    if (recommendations.isEmpty) {
      recommendations.add('Continue with decision-making process');
    }
    
    return recommendations;
  }
}
