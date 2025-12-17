import '../models/question.dart';

class AssessmentQuestions {
  static List<Question> getStandardQuestions() {
    return [
      // Patient Information
      Question(
        text: 'Patient Age',
        type: QuestionType.textInput,
        required: true,
        category: 'Patient Information',
        order: 1,
      ),
      Question(
        text: 'Relevant Diagnosis/Condition',
        type: QuestionType.textInput,
        required: false,
        category: 'Patient Information',
        order: 2,
      ),
      
      // Understanding
      Question(
        text: 'Does the person understand the information relevant to the decision?',
        type: QuestionType.yesNo,
        required: true,
        category: 'Understanding',
        order: 3,
      ),
      Question(
        text: 'Evidence for understanding assessment:',
        type: QuestionType.textInput,
        required: true,
        category: 'Understanding',
        order: 4,
      ),
      
      // Retention
      Question(
        text: 'Can the person retain the information?',
        type: QuestionType.yesNo,
        required: true,
        category: 'Retention',
        order: 5,
      ),
      Question(
        text: 'How long can they retain the information?',
        type: QuestionType.multipleChoice,
        options: ['Immediately only', 'Short term (minutes)', 'Medium term (hours)', 'Long term (days+)'],
        required: true,
        category: 'Retention',
        order: 6,
      ),
      
      // Using/Weighing Information
      Question(
        text: 'Can the person use or weigh the information as part of decision-making?',
        type: QuestionType.yesNo,
        required: true,
        category: 'Using Information',
        order: 7,
      ),
      Question(
        text: 'Evidence of ability to weigh information:',
        type: QuestionType.textInput,
        required: true,
        category: 'Using Information',
        order: 8,
      ),
      
      // Communication
      Question(
        text: 'Can the person communicate their decision?',
        type: QuestionType.yesNo,
        required: true,
        category: 'Communication',
        order: 9,
      ),
      Question(
        text: 'Method of communication used:',
        type: QuestionType.multipleChoice,
        options: ['Verbal', 'Written', 'Sign language', 'Gestures', 'Technology assisted', 'Other'],
        required: true,
        category: 'Communication',
        order: 10,
      ),
      
      // Additional Factors
      Question(
        text: 'Is there evidence of fluctuating capacity?',
        type: QuestionType.yesNo,
        required: true,
        category: 'Additional Factors',
        order: 11,
      ),
      Question(
        text: 'What support was provided to maximize capacity?',
        type: QuestionType.textInput,
        required: true,
        category: 'Additional Factors',
        order: 12,
      ),
      Question(
        text: 'Is this decision considered unwise by others?',
        type: QuestionType.yesNo,
        required: false,
        category: 'Additional Factors',
        order: 13,
      ),
    ];
  }

  static List<String> getCapacityOptions() {
    return [
      'Has capacity for this decision',
      'Lacks capacity for this decision',
      'Fluctuating capacity - reassessment needed',
      'Unable to determine - further assessment required'
    ];
  }
}
