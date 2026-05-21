import '../models/assessment.dart';
import '../models/risk_level.dart';
import 'assessment_questions.dart';

class RiskStratificationService {
  /// Compute and store the risk level at assessment-save time.
  ///
  /// Displays must use the persisted value, because thresholds may evolve and
  /// historical records need to preserve their original clinical classification.
  static RiskLevel compute({
    required int dsm5TotalScore,
    required List<String> triggeredLevel2Domains,
    required bool capacityFound,
    required bool mhcaCompleted,
    required bool isEmergencyBasis,
  }) {
    if (isEmergencyBasis) return RiskLevel.critical;
    if (!capacityFound && mhcaCompleted && triggeredLevel2Domains.length >= 2) {
      return RiskLevel.critical;
    }

    if (mhcaCompleted && !capacityFound) return RiskLevel.high;
    if (dsm5TotalScore >= 32) return RiskLevel.high;
    if (triggeredLevel2Domains.length >= 3) return RiskLevel.high;

    if (dsm5TotalScore >= 16) return RiskLevel.moderate;
    if (triggeredLevel2Domains.isNotEmpty) return RiskLevel.moderate;

    return RiskLevel.low;
  }

  static RiskLevel computeForAssessment(
    Assessment assessment, {
    bool isEmergencyBasis = false,
  }) {
    final context = assessment.decisionContext.toLowerCase();
    final outcome = assessment.overallCapacity.toLowerCase();
    final isDsm5 = context.contains('dsm-5') || context.contains('dsm5');

    final dsm5TotalScore = isDsm5
        ? AssessmentQuestions.calculateTotalScore(assessment.responses)
        : 0;
    final computedDsm5Domains = isDsm5
        ? AssessmentQuestions.getDomainsNeedingLevel2(assessment.responses)
        : <String>[];
    final triggeredLevel2Domains =
        computedDsm5Domains.isNotEmpty || !context.contains('level 2')
        ? computedDsm5Domains
        : _domainsFromRecommendations(assessment.recommendations);

    final hasCapacitySignal =
        outcome.contains('has capacity') ||
        outcome.contains('lacks capacity') ||
        outcome.contains('needs 100%');
    final mhcaCompleted = context.contains('mhca') || hasCapacitySignal;
    final capacityFound =
        outcome.contains('has capacity') &&
        !outcome.contains('lacks capacity') &&
        !outcome.contains('needs 100%');

    return compute(
      dsm5TotalScore: dsm5TotalScore,
      triggeredLevel2Domains: triggeredLevel2Domains,
      capacityFound: capacityFound,
      mhcaCompleted: mhcaCompleted,
      isEmergencyBasis: isEmergencyBasis,
    );
  }

  static List<String> _domainsFromRecommendations(String recommendations) {
    return recommendations
        .split(',')
        .map((domain) => domain.trim())
        .where((domain) => domain.isNotEmpty)
        .toList();
  }
}
