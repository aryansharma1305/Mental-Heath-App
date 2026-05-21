import 'package:flutter_test/flutter_test.dart';
import 'package:mental_capacity_assessment/models/assessment.dart';
import 'package:mental_capacity_assessment/models/assessment_recommendations.dart';
import 'package:mental_capacity_assessment/models/clinical_note.dart';
import 'package:mental_capacity_assessment/models/consent_basis.dart';
import 'package:mental_capacity_assessment/models/patient_profile.dart';
import 'package:mental_capacity_assessment/models/risk_level.dart';
import 'package:mental_capacity_assessment/services/export/csv_export_service.dart';

void main() {
  test('builds flat CSV with clinical governance fields', () {
    final now = DateTime.utc(2026, 5, 22, 10, 30);
    final assessment = Assessment(
      id: 12,
      patientId: 'P001',
      patientName: 'Anonymised',
      assessmentDate: now,
      assessorName: 'Dr Export',
      assessorRole: 'doctor',
      decisionContext: 'DSM-5 Assessment',
      responses: const {
        'q1': 'Mild - Several days',
        'q2': 'Moderate - More than half the days',
      },
      overallCapacity: 'Moderate symptoms',
      recommendations: 'legacy summary',
      structuredRecommendations: const AssessmentRecommendations(
        followUpRecommended: true,
        referToSpecialist: true,
        freeText: 'Review in 2 weeks.',
      ),
      createdAt: now,
      updatedAt: now,
      status: 'completed',
      assessmentStatus: 'completed',
      consentBasis: ConsentBasis.consentObtained,
      consentNotes: 'Patient agreed.',
      consentRecordedAt: now,
      consentRecordedBy: 'Dr Export',
      riskLevel: RiskLevel.high,
      priorAssessmentId: 7,
    );
    final patient = PatientProfile(
      patientId: 'P001',
      displayName: 'Anonymised',
      createdAt: now,
      updatedAt: now,
    );
    final note = ClinicalNote(
      patientId: 'P001',
      assessmentId: 12,
      note: 'Clinical context note.',
      authorName: 'Dr Export',
      createdAt: now,
      updatedAt: now,
    );

    final csv = CsvExportService.buildCsv(
      [assessment],
      {'P001': patient},
      notesByAssessment: {
        12: [note],
      },
    );

    expect(csv, contains('Assessment ID'));
    expect(csv, contains('P001'));
    expect(csv, contains('Follow-up recommended; Refer to specialist'));
    expect(csv, contains('Clinical context note.'));
    expect(csv, contains('High'));
    expect(csv, contains('7'));
  });
}
