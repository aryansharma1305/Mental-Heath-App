import 'package:flutter_test/flutter_test.dart';
import 'package:mental_capacity_assessment/models/assessment.dart';
import 'package:mental_capacity_assessment/models/assessment_recommendations.dart';
import 'package:mental_capacity_assessment/models/consent_basis.dart';
import 'package:mental_capacity_assessment/models/risk_level.dart';
import 'package:mental_capacity_assessment/services/pdf/pdf_refusal_builder.dart';
import 'package:mental_capacity_assessment/services/pdf/pdf_report_builder.dart';

void main() {
  test('builds a full PDF report with trend-capable inputs', () async {
    final now = DateTime.now();
    final prior = _assessment(now.subtract(const Duration(days: 20)), id: 1);
    final current = _assessment(
      now,
      id: 2,
      priorAssessmentId: 1,
      riskLevel: RiskLevel.high,
      recommendations: const AssessmentRecommendations(
        followUpRecommended: true,
        referToSpecialist: true,
      ),
    );

    final bytes = await PdfReportBuilder().buildFullReport(
      assessment: current,
      priorAssessment: prior,
      clinicalNote: 'Patient reports worsening symptoms.',
    );

    expect(bytes, isNotEmpty);
    expect(bytes.length, greaterThan(1000));
  });

  test('builds a refusal PDF record', () async {
    final now = DateTime.now();
    final refused = Assessment(
      id: 3,
      patientId: 'P001',
      patientName: 'Anonymised',
      assessmentDate: now,
      assessorName: 'Dr Refusal',
      assessorRole: 'doctor',
      decisionContext: 'DSM-5 Consent Refusal',
      responses: const {},
      overallCapacity: 'Consent refused',
      recommendations: 'No clinical assessment data was collected.',
      createdAt: now,
      updatedAt: now,
      status: 'refused',
      assessmentStatus: 'refused',
      consentBasis: ConsentBasis.refused,
      consentNotes: 'Patient declined to proceed.',
      consentRecordedAt: now,
      consentRecordedBy: 'Dr Refusal',
      riskLevel: RiskLevel.moderate,
    );

    final bytes = await PdfRefusalBuilder().buildRefusalRecord(refused);

    expect(bytes, isNotEmpty);
    expect(bytes.length, greaterThan(1000));
  });
}

Assessment _assessment(
  DateTime date, {
  required int id,
  int? priorAssessmentId,
  RiskLevel riskLevel = RiskLevel.moderate,
  AssessmentRecommendations recommendations = const AssessmentRecommendations(),
}) {
  return Assessment(
    id: id,
    patientId: 'P001',
    patientName: 'Anonymised',
    assessmentDate: date,
    assessorName: 'Dr Report',
    assessorRole: 'doctor',
    decisionContext: 'DSM-5 Assessment',
    responses: const {
      'q1': 'Mild - Several days',
      'q2': 'Moderate - More than half the days',
    },
    overallCapacity: 'Moderate symptoms',
    recommendations: recommendations.toLegacySummary(),
    structuredRecommendations: recommendations,
    createdAt: date,
    updatedAt: date,
    status: 'completed',
    assessmentStatus: 'completed',
    consentBasis: ConsentBasis.consentObtained,
    consentRecordedAt: date,
    consentRecordedBy: 'Dr Report',
    riskLevel: riskLevel,
    priorAssessmentId: priorAssessmentId,
  );
}
