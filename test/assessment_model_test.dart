import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:mental_capacity_assessment/models/assessment.dart';
import 'package:mental_capacity_assessment/models/assessment_recommendations.dart';
import 'package:mental_capacity_assessment/models/clinical_note.dart';
import 'package:mental_capacity_assessment/models/consent_basis.dart';
import 'package:mental_capacity_assessment/models/consent_record.dart';
import 'package:mental_capacity_assessment/models/patient_profile.dart';
import 'package:mental_capacity_assessment/models/risk_level.dart';
import 'package:mental_capacity_assessment/services/assessment_questions.dart';
import 'package:mental_capacity_assessment/services/encryption_service.dart';
import 'package:mental_capacity_assessment/services/risk_stratification_service.dart';

void main() {
  group('Assessment model parsing', () {
    test('decodes JSON response strings from storage', () {
      final questionId =
          AssessmentQuestions.getStandardQuestions().first.questionId;
      final assessment = Assessment.fromMap({
        'id': 1,
        'patient_id': 'P001',
        'patient_name': 'Anonymised',
        'assessment_date': 'bad-date',
        'assessor_name': 'Doctor',
        'assessor_role': 'doctor',
        'decision_context': 'DSM-5 Assessment',
        'responses': jsonEncode({questionId: 'Mild - Several days'}),
        'overall_capacity': 'Mild symptoms',
        'recommendations': '',
        'created_at': 'bad-date',
        'updated_at': 'bad-date',
        'is_synced': 0,
      });

      expect(assessment.responses[questionId], 'Mild - Several days');
      expect(assessment.assessmentDate, isA<DateTime>());
    });

    test('recovers raw JSON maps left by older malformed records', () {
      final questionId =
          AssessmentQuestions.getStandardQuestions().first.questionId;
      final assessment = Assessment.fromMap({
        'id': 1,
        'patient_id': 'P001',
        'patient_name': 'Anonymised',
        'assessment_date': DateTime.now().toIso8601String(),
        'assessor_name': 'Doctor',
        'assessor_role': 'doctor',
        'decision_context': 'DSM-5 Assessment',
        'responses': {
          'raw': jsonEncode({questionId: 'Moderate - More than half the days'}),
        },
        'overall_capacity': 'Mild symptoms',
        'recommendations': '',
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
        'is_synced': 0,
      });

      expect(
        assessment.responses[questionId],
        'Moderate - More than half the days',
      );
    });
  });

  group('DSM-5 scoring', () {
    test('uses stable question IDs for built-in questions', () {
      final questions = AssessmentQuestions.getStandardQuestions();

      expect(questions.first.questionId, 'q1');
      expect(questions.last.questionId, 'q23');
    });

    test('follow-up thresholds use highest item score in each domain', () {
      final questions = AssessmentQuestions.getStandardQuestions();
      final depressionQuestions = questions
          .where((q) => q.category == 'I. Depression')
          .toList();
      final responses = {
        depressionQuestions[0].questionId:
            'Slight - Rare, less than a day or two',
        depressionQuestions[1].questionId:
            'Slight - Rare, less than a day or two',
      };

      final summedScores = AssessmentQuestions.calculateDomainScores(responses);
      final highestScores = AssessmentQuestions.calculateDomainHighestScores(
        responses,
      );
      final flagged = AssessmentQuestions.getDomainsRequiringFollowUp(
        highestScores,
      );

      expect(summedScores['I. Depression'], 2);
      expect(highestScores['I. Depression'], 1);
      expect(flagged, isNot(contains('I. Depression')));
    });

    test('falls back by response order for older unstable keys', () {
      final options = AssessmentQuestions.standardOptions;
      final responses = <String, dynamic>{};

      for (
        var i = 0;
        i < AssessmentQuestions.getStandardQuestions().length;
        i++
      ) {
        responses['legacy_$i'] = options[0];
      }
      responses['legacy_10'] = options[1];

      final highestScores = AssessmentQuestions.calculateDomainHighestScores(
        responses,
      );
      final flagged = AssessmentQuestions.getDomainsRequiringFollowUp(
        highestScores,
      );

      expect(highestScores['VI. Suicidal Ideation'], 1);
      expect(flagged, contains('VI. Suicidal Ideation'));
    });
  });

  group('Patient profile foundation', () {
    test('patient profiles parse persisted stats safely', () {
      final patient = PatientProfile.fromMap({
        'patient_id': 'P001',
        'display_name': 'Anonymised',
        'created_at': 'bad-date',
        'updated_at': DateTime.now().toIso8601String(),
        'last_assessment_at': DateTime.now().toIso8601String(),
        'assessment_count': '3',
      });

      expect(patient.patientId, 'P001');
      expect(patient.displayName, 'Anonymised');
      expect(patient.assessmentCount, 3);
      expect(patient.createdAt, isA<DateTime>());
    });

    test('clinical notes keep patient and assessment linkage', () {
      final now = DateTime.now();
      final note = ClinicalNote(
        id: 7,
        patientId: 'P001',
        assessmentId: 42,
        note: 'Capacity discussion included family collateral.',
        authorName: 'Dr Smith',
        createdAt: now,
        updatedAt: now,
      );

      final parsed = ClinicalNote.fromMap(note.toMap());

      expect(parsed.patientId, 'P001');
      expect(parsed.assessmentId, 42);
      expect(parsed.note, contains('family collateral'));
    });
  });

  group('Risk stratification', () {
    test('stores and parses risk level on assessment records', () {
      final assessment = Assessment.fromMap({
        'id': 1,
        'patient_id': 'P001',
        'patient_name': 'Anonymised',
        'assessment_date': DateTime.now().toIso8601String(),
        'assessor_name': 'Doctor',
        'assessor_role': 'doctor',
        'decision_context': 'DSM-5 Assessment',
        'responses': '{}',
        'overall_capacity': 'Minimal symptoms',
        'recommendations': '',
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
        'risk_level': 'high',
        'is_synced': 0,
      });

      expect(assessment.riskLevel, RiskLevel.high);
      expect(assessment.toMap()['risk_level'], 'high');
    });

    test('marks elevated DSM-5 total score as moderate', () {
      expect(
        RiskStratificationService.compute(
          dsm5TotalScore: 16,
          triggeredLevel2Domains: const [],
          capacityFound: true,
          mhcaCompleted: false,
        ),
        RiskLevel.moderate,
      );
    });

    test('marks MHCA no-capacity outcome as high', () {
      final assessment = _assessmentWith(
        responses: const {},
        decisionContext: 'MHCA Treatment Capacity',
        overallCapacity:
            'Needs 100% support from nominated representative in making treatment decisions including admission',
      );

      expect(
        RiskStratificationService.computeForAssessment(assessment),
        RiskLevel.high,
      );
    });

    test('emergency basis overrides to critical', () {
      expect(
        RiskStratificationService.compute(
          dsm5TotalScore: 0,
          triggeredLevel2Domains: const [],
          capacityFound: true,
          mhcaCompleted: false,
          consentBasis: ConsentBasis.lacksCapacityEmergency,
        ),
        RiskLevel.critical,
      );
    });
  });

  group('Consent recording', () {
    test('parses and stores consent basis on assessment records', () {
      final now = DateTime.now();
      final assessment =
          _assessmentWith(
            responses: const {},
            decisionContext: 'DSM-5 Assessment',
            overallCapacity: 'Minimal symptoms',
          ).copyWith(
            consentBasis: ConsentBasis.consentObtained,
            consentNotes: 'Patient agreed to proceed.',
            consentRecordedAt: now,
            consentRecordedBy: 'Dr Consent',
            assessmentStatus: 'completed',
          );

      final parsed = Assessment.fromMap(assessment.toMap());

      expect(parsed.consentBasis, ConsentBasis.consentObtained);
      expect(parsed.consentRecordedBy, 'Dr Consent');
      expect(parsed.assessmentStatus, 'completed');
    });

    test('refusal consent record requires notes', () {
      final record = ConsentRecord(
        basis: ConsentBasis.refused,
        recordedAt: DateTime.now(),
        recordedBy: 'Dr Consent',
      );

      expect(record.validate, throwsArgumentError);
    });

    test('refused assessment is locked and moderate by default', () {
      final now = DateTime.now();
      final assessment = Assessment(
        patientId: 'P001',
        patientName: 'Anonymised',
        assessmentDate: now,
        assessorName: 'Dr Consent',
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
        consentNotes: 'Patient declined today.',
        consentRecordedAt: now,
        consentRecordedBy: 'Dr Consent',
      );

      expect(assessment.isRefused, isTrue);
      expect(
        RiskStratificationService.computeForAssessment(assessment),
        RiskLevel.moderate,
      );
    });
  });

  group('Assessment recommendations', () {
    test(
      'stores structured recommendations as JSON while keeping text summary',
      () {
        const recommendations = AssessmentRecommendations(
          followUpRecommended: true,
          referToSpecialist: true,
          freeText: 'Repeat assessment after medication review.',
        );
        final assessment = _assessmentWith(
          responses: const {},
          decisionContext: 'DSM-5 Assessment',
          overallCapacity: 'Moderate symptoms',
          recommendations: recommendations.toLegacySummary(),
          structuredRecommendations: recommendations,
        );

        final mapped = assessment.toMap();
        final parsed = Assessment.fromMap(mapped);

        expect(mapped['recommendations'], contains('Follow-up'));
        expect(mapped['recommendations_json'], isA<String>());
        expect(parsed.structuredRecommendations.followUpRecommended, isTrue);
        expect(parsed.structuredRecommendations.referToSpecialist, isTrue);
        expect(parsed.structuredRecommendations.noFurtherAction, isFalse);
        expect(
          parsed.structuredRecommendations.freeText,
          contains('medication'),
        );
      },
    );

    test('parses legacy recommendation text as free text fallback', () {
      final recommendations = AssessmentRecommendations.fromStorage(
        'Continue routine monitoring',
      );

      expect(recommendations.freeText, 'Continue routine monitoring');
      expect(recommendations.toLegacySummary(), 'Continue routine monitoring');
    });
  });

  group('Encryption key generation', () {
    test('generates a 32-byte url-safe database key', () {
      final key = EncryptionService.generateKey();

      expect(key, isNotEmpty);
      expect(key, isNot(contains('+')));
      expect(key, isNot(contains('/')));
      expect(base64Url.decode(key), hasLength(32));
    });
  });
}

Assessment _assessmentWith({
  required Map<String, dynamic> responses,
  required String decisionContext,
  required String overallCapacity,
  String recommendations = '',
  AssessmentRecommendations? structuredRecommendations,
}) {
  final now = DateTime.now();
  return Assessment(
    patientId: 'P001',
    patientName: 'Anonymised',
    assessmentDate: now,
    assessorName: 'Doctor',
    assessorRole: 'doctor',
    decisionContext: decisionContext,
    responses: responses,
    overallCapacity: overallCapacity,
    recommendations: recommendations,
    structuredRecommendations: structuredRecommendations,
    createdAt: now,
    updatedAt: now,
  );
}
