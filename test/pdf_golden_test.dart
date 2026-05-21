import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:mental_capacity_assessment/models/assessment.dart';
import 'package:mental_capacity_assessment/models/assessment_recommendations.dart';
import 'package:mental_capacity_assessment/models/consent_basis.dart';
import 'package:mental_capacity_assessment/models/patient_profile.dart';
import 'package:mental_capacity_assessment/models/risk_level.dart';
import 'package:mental_capacity_assessment/services/pdf/pdf_refusal_builder.dart';
import 'package:mental_capacity_assessment/services/pdf/pdf_report_builder.dart';

void main() {
  const shouldUpdateGoldens = bool.fromEnvironment(
    'UPDATE_PDF_GOLDENS',
    defaultValue: false,
  );

  group('PDF golden tests', () {
    test('full report matches golden', () async {
      final bytes = await _fullReportBytes(includeTrend: true);
      await _expectGolden(
        bytes,
        'test/goldens/full_report.pdf',
        shouldUpdateGoldens,
      );
    });

    test('refusal report matches golden', () async {
      final bytes = await PdfRefusalBuilder().buildRefusalRecord(
        _mockRefusalAssessment(),
      );
      await _expectGolden(
        bytes,
        'test/goldens/refusal_report.pdf',
        shouldUpdateGoldens,
      );
    });

    test('full report without trend section matches golden', () async {
      final bytes = await _fullReportBytes(includeTrend: false);
      await _expectGolden(
        bytes,
        'test/goldens/full_report_no_trend.pdf',
        shouldUpdateGoldens,
      );
    });
  });
}

Future<List<int>> _fullReportBytes({required bool includeTrend}) {
  final current = _mockCompletedAssessment(
    id: 2,
    date: DateTime.utc(2026, 5, 22, 10, 30),
    priorAssessmentId: includeTrend ? 1 : null,
    riskLevel: RiskLevel.high,
  );
  final prior = includeTrend
      ? _mockCompletedAssessment(
          id: 1,
          date: DateTime.utc(2026, 4, 22, 10, 30),
          riskLevel: RiskLevel.moderate,
        )
      : null;
  return PdfReportBuilder().buildFullReport(
    assessment: current,
    patient: _mockPatientProfile(),
    priorAssessment: prior,
    clinicalNote: 'Patient reports worsening symptoms over the past month.',
    generatedAt: DateTime.utc(2026, 5, 22, 12),
  );
}

Future<void> _expectGolden(List<int> bytes, String path, bool update) async {
  final file = File(path);
  if (update) {
    await file.parent.create(recursive: true);
    await file.writeAsBytes(bytes);
  }

  expect(
    await file.exists(),
    isTrue,
    reason: 'Run with --dart-define=UPDATE_PDF_GOLDENS=true to create $path.',
  );
  expect(_normalisePdf(bytes), _normalisePdf(await file.readAsBytes()));
}

List<int> _normalisePdf(List<int> bytes) {
  final text = String.fromCharCodes(bytes);
  final normalised = text.replaceAll(
    RegExp(r'/ID\[[^\]]+\]'),
    '/ID[<PDF_GOLDEN_ID><PDF_GOLDEN_ID>]',
  );
  return normalised.codeUnits;
}

PatientProfile _mockPatientProfile() {
  final now = DateTime.utc(2026, 5, 22);
  return PatientProfile(
    patientId: 'P001',
    displayName: 'Anonymised Patient P001',
    createdAt: now,
    updatedAt: now,
    assessmentCount: 2,
  );
}

Assessment _mockCompletedAssessment({
  required int id,
  required DateTime date,
  int? priorAssessmentId,
  RiskLevel riskLevel = RiskLevel.moderate,
}) {
  const recommendations = AssessmentRecommendations(
    followUpRecommended: true,
    referToSpecialist: true,
    freeText: 'Review after medication adjustment.',
  );
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
      'q3': 'Mild - Several days',
    },
    overallCapacity: 'Moderate symptoms',
    recommendations: recommendations.toLegacySummary(),
    structuredRecommendations: recommendations,
    createdAt: date,
    updatedAt: date,
    status: 'completed',
    assessmentStatus: 'completed',
    consentBasis: ConsentBasis.consentObtained,
    consentNotes: 'Patient agreed to proceed.',
    consentRecordedAt: date,
    consentRecordedBy: 'Dr Report',
    riskLevel: riskLevel,
    priorAssessmentId: priorAssessmentId,
  );
}

Assessment _mockRefusalAssessment() {
  final date = DateTime.utc(2026, 5, 22, 9, 15);
  return Assessment(
    id: 3,
    patientId: 'P002',
    patientName: 'Anonymised',
    assessmentDate: date,
    assessorName: 'Dr Refusal',
    assessorRole: 'doctor',
    decisionContext: 'DSM-5 Consent Refusal',
    responses: const {},
    overallCapacity: 'Consent refused',
    recommendations: 'No clinical assessment data was collected.',
    createdAt: date,
    updatedAt: date,
    status: 'refused',
    assessmentStatus: 'refused',
    consentBasis: ConsentBasis.refused,
    consentNotes: 'Patient declined to participate today.',
    consentRecordedAt: date,
    consentRecordedBy: 'Dr Refusal',
    riskLevel: RiskLevel.moderate,
  );
}
