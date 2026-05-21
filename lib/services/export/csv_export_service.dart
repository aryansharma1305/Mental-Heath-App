import 'dart:io';

import 'package:csv/csv.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';

import '../../models/assessment.dart';
import '../../models/clinical_note.dart';
import '../../models/patient_profile.dart';
import '../../models/risk_level.dart';
import '../assessment_questions.dart';

class CsvExportService {
  static String buildCsv(
    List<Assessment> assessments,
    Map<String, PatientProfile> patients, {
    Map<int, List<ClinicalNote>> notesByAssessment = const {},
  }) {
    final rows = <List<String>>[_headers()];
    for (final assessment in assessments) {
      rows.add(
        _row(
          assessment,
          patients[assessment.patientId],
          notesByAssessment[assessment.id] ?? const [],
        ),
      );
    }
    return csv.encode(rows);
  }

  static Future<File> writeCsvFile({
    required String filePrefix,
    required List<Assessment> assessments,
    required Map<String, PatientProfile> patients,
    Map<int, List<ClinicalNote>> notesByAssessment = const {},
  }) async {
    final csv = buildCsv(
      assessments,
      patients,
      notesByAssessment: notesByAssessment,
    );
    final dir = await getTemporaryDirectory();
    final stamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
    final safePrefix = filePrefix.replaceAll(RegExp(r'[^A-Za-z0-9_-]'), '_');
    final file = File('${dir.path}/${safePrefix}_$stamp.csv');
    await file.writeAsString(csv);
    return file;
  }

  static List<String> _headers() => [
    'Assessment ID',
    'Patient ID',
    'Patient Name',
    'Date',
    'Type',
    'Status',
    'Assessment Status',
    'Consent Basis',
    'Consent Notes',
    'DSM5 Total',
    'Triggered Domains',
    'Capacity Found',
    'Risk Level',
    'Recommendations',
    'Clinical Notes',
    'Clinician',
    'Prior Assessment ID',
  ];

  static List<String> _row(
    Assessment assessment,
    PatientProfile? patient,
    List<ClinicalNote> notes,
  ) {
    final isDsm5 = assessment.decisionContext.toLowerCase().contains('dsm-5');
    final domainScores = isDsm5
        ? AssessmentQuestions.calculateDomainHighestScores(assessment.responses)
        : <String, int>{};
    final triggeredDomains = isDsm5
        ? AssessmentQuestions.getDomainsRequiringFollowUp(domainScores)
        : <String>[];
    final totalScore = isDsm5
        ? AssessmentQuestions.calculateTotalScore(assessment.responses)
        : null;

    return [
      assessment.id?.toString() ?? '',
      assessment.patientId,
      patient?.displayName ?? assessment.patientName,
      assessment.assessmentDate.toIso8601String(),
      assessment.decisionContext,
      assessment.status ?? '',
      assessment.assessmentStatus,
      assessment.consentBasis?.name ?? '',
      assessment.consentNotes ?? '',
      totalScore?.toString() ?? '',
      triggeredDomains.join('; '),
      _capacityFound(assessment),
      assessment.riskLevel.label,
      _recommendationsSummary(assessment),
      notes.map((note) => note.note).join(' | '),
      assessment.consentRecordedBy ?? assessment.assessorName,
      assessment.priorAssessmentId?.toString() ?? '',
    ];
  }

  static String _recommendationsSummary(Assessment assessment) {
    final structured = assessment.structuredRecommendations.toSummary();
    if (structured.isNotEmpty) return structured;
    return assessment.recommendations;
  }

  static String _capacityFound(Assessment assessment) {
    if (assessment.decisionContext.toLowerCase().contains('dsm-5')) return '';
    final finding = assessment.overallCapacity.toLowerCase();
    if (finding.contains('lacks') || finding.contains('needs 100% support')) {
      return 'No';
    }
    if (finding.contains('has capacity')) return 'Yes';
    return '';
  }
}
