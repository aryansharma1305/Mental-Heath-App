import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:mental_capacity_assessment/models/assessment.dart';
import 'package:mental_capacity_assessment/models/clinical_note.dart';
import 'package:mental_capacity_assessment/models/patient_profile.dart';
import 'package:mental_capacity_assessment/services/assessment_questions.dart';

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
}
