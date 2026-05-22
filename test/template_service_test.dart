// ignore_for_file: avoid_print

import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_sqlcipher/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:mental_capacity_assessment/models/assessment.dart';
import 'package:mental_capacity_assessment/models/assessment_template.dart';
import 'package:mental_capacity_assessment/models/consent_basis.dart';
import 'package:mental_capacity_assessment/services/template_service.dart';
import 'package:mental_capacity_assessment/services/database_service.dart';

// ── Test helpers ──────────────────────────────────────────────────────────

AssessmentTemplate _makeTemplate({
  String id = 'test-id-1',
  String name = 'Ward round',
  String assessmentType = 'MHCA',
  String? clinician = 'Dr. Test',
  String? consentBasis,
  int useCount = 0,
}) {
  return AssessmentTemplate(
    id: id,
    name: name,
    assessmentType: assessmentType,
    defaultClinician: clinician,
    defaultConsentBasis: consentBasis,
    useCount: useCount,
  );
}

Assessment _makeAssessment({
  String clinician = 'Dr. Smith',
  String purpose = 'Treatment',
}) {
  return Assessment(
    patientId: 'patient-001',
    patientName: 'Alice Johnson',
    assessmentDate: DateTime.now(),
    assessorName: clinician,
    assessorRole: 'Consultant',
    decisionContext: purpose,
    responses: const {'gate': 'No'},
    overallCapacity: 'Has capacity',
    recommendations: 'Follow up in 3 months',
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
    consentRecordedBy: clinician,
  );
}

// ── Main ──────────────────────────────────────────────────────────────────

void main() {
  late TemplateService service;

  setUpAll(() {
    // Use in-memory SQLite for tests.
    sqfliteFfiInit();
    DatabaseService.overrideFactoryForTesting(databaseFactoryFfi);
  });

  setUp(() async {
    // Reset and re-initialise the DB singleton for each test.
    DatabaseService.resetForTesting();
    DatabaseService.overrideFactoryForTesting(databaseFactoryFfi);
    service = TemplateService.instance;
    // Clear all templates before each test.
    final db = await DatabaseService().database;
    await db.delete('assessment_templates');
  });


  // ── getTemplates ──────────────────────────────────────────────────────

  group('getTemplates', () {
    test('returns empty list for unknown type', () async {
      final result = await service.getTemplates('DSM5');
      expect(result, isEmpty);
    });

    test('returns only templates matching the assessment type', () async {
      await service.saveTemplate(_makeTemplate(id: 't1', assessmentType: 'MHCA'));
      await service.saveTemplate(_makeTemplate(id: 't2', assessmentType: 'DSM5'));

      final mhca = await service.getTemplates('MHCA');
      expect(mhca.length, 1);
      expect(mhca.first.assessmentType, 'MHCA');

      final dsm = await service.getTemplates('DSM5');
      expect(dsm.length, 1);
      expect(dsm.first.assessmentType, 'DSM5');
    });

    test('sorts by use_count DESC then name ASC', () async {
      await service.saveTemplate(
        _makeTemplate(id: 'a', name: 'Alpha', useCount: 1),
      );
      await service.saveTemplate(
        _makeTemplate(id: 'b', name: 'Beta', useCount: 10),
      );
      await service.saveTemplate(
        _makeTemplate(id: 'c', name: 'Gamma', useCount: 0),
      );

      final result = await service.getTemplates('MHCA');
      expect(result[0].name, 'Beta');   // highest useCount
      expect(result[1].name, 'Alpha');  // useCount=1 > 0, alpha before gamma
      expect(result[2].name, 'Gamma');  // lowest useCount
    });
  });

  // ── saveTemplate / getTemplate ────────────────────────────────────────

  group('saveTemplate', () {
    test('persists and getTemplate retrieves by id', () async {
      final template = _makeTemplate(id: 'save-1', name: 'Emergency review');
      await service.saveTemplate(template);

      final fetched = await service.getTemplate('save-1');
      expect(fetched, isNotNull);
      expect(fetched!.name, 'Emergency review');
      expect(fetched.defaultClinician, 'Dr. Test');
    });

    test('upsert: second save updates the record', () async {
      final original = _makeTemplate(id: 'up-1', name: 'Original');
      await service.saveTemplate(original);

      final updated = original.copyWith(name: 'Updated name');
      await service.saveTemplate(updated);

      final result = await service.getTemplate('up-1');
      expect(result!.name, 'Updated name');
    });

    test('getTemplate returns null for missing id', () async {
      final result = await service.getTemplate('no-such-id');
      expect(result, isNull);
    });
  });

  // ── recordUsage ───────────────────────────────────────────────────────

  group('recordUsage', () {
    test('increments use_count and sets last_used_at', () async {
      final template = _makeTemplate(id: 'usage-1', useCount: 0);
      await service.saveTemplate(template);

      await service.recordUsage('usage-1');

      final updated = await service.getTemplate('usage-1');
      expect(updated!.useCount, 1);
      expect(updated.lastUsedAt, isNotNull);
    });

    test('increments use_count cumulatively', () async {
      final template = _makeTemplate(id: 'usage-2', useCount: 5);
      await service.saveTemplate(template);

      await service.recordUsage('usage-2');
      await service.recordUsage('usage-2');

      final updated = await service.getTemplate('usage-2');
      expect(updated!.useCount, 7);
    });

    test('does not throw for missing id', () async {
      // recordUsage is fire-and-forget — should not throw.
      await expectLater(
        service.recordUsage('ghost-id'),
        completes,
      );
    });
  });

  // ── deleteTemplate ────────────────────────────────────────────────────

  group('deleteTemplate', () {
    test('removes template from DB', () async {
      await service.saveTemplate(_makeTemplate(id: 'del-1'));
      await service.deleteTemplate('del-1');

      final result = await service.getTemplate('del-1');
      expect(result, isNull);
    });

    test('does not affect other templates', () async {
      await service.saveTemplate(_makeTemplate(id: 'keep-1', name: 'Keep me'));
      await service.saveTemplate(_makeTemplate(id: 'del-2', name: 'Delete me'));

      await service.deleteTemplate('del-2');

      final kept = await service.getTemplate('keep-1');
      expect(kept, isNotNull);
      expect(kept!.name, 'Keep me');
    });
  });

  // ── fromAssessment ────────────────────────────────────────────────────

  group('fromAssessment', () {
    test('copies clinician name (consentRecordedBy)', () async {
      final assessment = _makeAssessment(clinician: 'Dr. Copy');
      final template = service.fromAssessment(assessment, 'My template');

      expect(template.defaultClinician, 'Dr. Copy');
    });

    test('does NOT copy patient name', () async {
      final assessment = _makeAssessment();
      final template = service.fromAssessment(assessment, 'Safe template');

      // Template must not contain patient identity.
      expect(template.name, 'Safe template');
      // The template model has no patient name field — verify the assessment's
      // patient name is not reachable via the template object at all.
      final map = template.toMap();
      expect(map.containsKey('patient_name'), isFalse);
    });

    test('does NOT copy clinical responses', () async {
      final assessment = _makeAssessment();
      final template = service.fromAssessment(assessment, 'No scores');

      // AssessmentTemplate has no responses field.
      final map = template.toMap();
      expect(map.containsKey('responses'), isFalse);
    });

    test('assigns a fresh UUID each call', () async {
      final a = _makeAssessment();
      final t1 = service.fromAssessment(a, 'T1');
      final t2 = service.fromAssessment(a, 'T2');
      expect(t1.id, isNot(t2.id));
    });

    test('copies purpose from decisionContext', () async {
      final a = _makeAssessment(purpose: 'Admission');
      final template = service.fromAssessment(a, 'Admission template');

      // defaultPurpose is extracted from decisionContext via metadata.
      expect(template.defaultPurpose, 'Admission');
    });
  });

  // ── AssessmentTemplate model ──────────────────────────────────────────

  group('AssessmentTemplate serialisation', () {
    test('round-trips through toMap / fromMap', () {
      final original = AssessmentTemplate(
        id: 'rt-1',
        name: 'Round trip',
        assessmentType: 'MHCA',
        defaultClinician: 'Dr. Round',
        defaultConsentBasis: ConsentBasis.consentObtained.name,
        contextualNote: 'Ward 3',
        followUpRecommendedDefault: true,
        metadata: {'defaultPurpose': 'Treatment'},
        useCount: 7,
        createdAt: DateTime(2026, 1, 15),
      );

      final restored = AssessmentTemplate.fromMap(original.toMap());

      expect(restored.id, 'rt-1');
      expect(restored.name, 'Round trip');
      expect(restored.defaultClinician, 'Dr. Round');
      expect(restored.consentBasis, ConsentBasis.consentObtained);
      expect(restored.contextualNote, 'Ward 3');
      expect(restored.followUpRecommendedDefault, isTrue);
      expect(restored.defaultPurpose, 'Treatment');
      expect(restored.useCount, 7);
    });

    test('fromMap handles corrupt metadata gracefully', () {
      final map = {
        'id': 'bad-meta',
        'name': 'Bad meta',
        'assessment_type': 'MHCA',
        'follow_up_recommended_default': 0,
        'created_at': DateTime.now().toIso8601String(),
        'use_count': 0,
        'metadata': 'THIS IS NOT JSON {{{',
      };
      // Should not throw.
      final template = AssessmentTemplate.fromMap(map);
      expect(template.metadata, isEmpty);
    });

    test('consentBasis returns null for unrecognised string', () {
      final template = AssessmentTemplate(
        id: 'cb-bad',
        name: 'Test',
        assessmentType: 'MHCA',
        defaultConsentBasis: 'not_a_real_basis',
      );
      expect(template.consentBasis, isNull);
    });
  });
}
