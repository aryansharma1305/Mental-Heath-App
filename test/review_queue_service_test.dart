import 'package:flutter_test/flutter_test.dart';
import 'package:mental_capacity_assessment/models/assessment.dart';
import 'package:mental_capacity_assessment/models/assessment_recommendations.dart';
import 'package:mental_capacity_assessment/models/risk_level.dart';
import 'package:mental_capacity_assessment/services/review_queue_service.dart';

void main() {
  test('queues latest high risk assessment without follow-up checkbox', () {
    final now = DateTime.now();
    final old = _assessment(
      id: 1,
      patientId: 'P001',
      risk: RiskLevel.high,
      createdAt: now.subtract(const Duration(days: 30)),
    );
    final latest = _assessment(
      id: 2,
      patientId: 'P001',
      risk: RiskLevel.high,
      createdAt: now.subtract(const Duration(days: 1)),
    );

    final queue = ReviewQueueService().buildQueue([old, latest]);

    expect(queue, hasLength(1));
    expect(queue.single.assessment.id, 2);
    expect(queue.single.reason, contains('High risk'));
  });

  test('excludes low risk assessment without follow-up recommendation', () {
    final assessment = _assessment(
      id: 1,
      patientId: 'P002',
      risk: RiskLevel.low,
      followUpRecommended: false,
      createdAt: DateTime.now().subtract(const Duration(days: 120)),
    );

    expect(ReviewQueueService().buildQueue([assessment]), isEmpty);
  });

  test('summary counts overdue critical and refusal records', () {
    final now = DateTime.now();
    final critical = _assessment(
      id: 1,
      patientId: 'P003',
      risk: RiskLevel.critical,
      createdAt: now.subtract(const Duration(days: 10)),
    );
    final refused = _assessment(
      id: 2,
      patientId: 'P004',
      risk: RiskLevel.moderate,
      refused: true,
      createdAt: now.subtract(const Duration(days: 40)),
    );

    final summary = ReviewQueueService().summary([critical, refused]);

    expect(summary.total, 2);
    expect(summary.overdue, 2);
    expect(summary.critical, 1);
    expect(summary.refusals, 1);
  });
}

Assessment _assessment({
  required int id,
  required String patientId,
  required RiskLevel risk,
  required DateTime createdAt,
  bool followUpRecommended = false,
  bool refused = false,
}) {
  return Assessment(
    id: id,
    patientId: patientId,
    patientName: 'Anonymised',
    assessmentDate: createdAt,
    assessorName: 'Dr Queue',
    assessorRole: 'Doctor',
    decisionContext: 'DSM-5 Assessment',
    responses: const {},
    overallCapacity: 'Recorded',
    recommendations: '',
    structuredRecommendations: AssessmentRecommendations(
      followUpRecommended: followUpRecommended,
    ),
    createdAt: createdAt,
    updatedAt: createdAt,
    riskLevel: risk,
    assessmentStatus: refused ? 'refused' : 'completed',
  );
}
