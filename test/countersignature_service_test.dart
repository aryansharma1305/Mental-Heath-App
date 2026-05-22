import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:mental_capacity_assessment/models/assessment.dart';
import 'package:mental_capacity_assessment/models/countersignature.dart';
import 'package:mental_capacity_assessment/models/risk_level.dart';
import 'package:mental_capacity_assessment/services/countersignature_service.dart';
import 'package:mental_capacity_assessment/services/database_service.dart';

// =============================================================================
// countersignature_service_test.dart
//
// Uses sqflite_common_ffi (in-memory) via DatabaseService.overrideFactoryForTesting.
// DatabaseService._initDatabase() short-circuits to the FFI factory when
// _testFactory is set, bypassing sqflite_sqlcipher's platform channel entirely.
// =============================================================================
void main() {
  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    sqfliteFfiInit();
    DatabaseService.overrideFactoryForTesting(databaseFactoryFfi);
  });

  setUp(() async {
    DatabaseService.resetForTesting();
    DatabaseService.overrideFactoryForTesting(databaseFactoryFfi);
  });

  tearDown(() async {
    DatabaseService.resetForTesting();
  });

  // -------------------------------------------------------------------------
  // Helpers
  // -------------------------------------------------------------------------

  Future<Assessment> _insertHighRiskAssessment() async {
    final db = DatabaseService();
    final a = Assessment(
      patientId: 'P001',
      patientName: 'Test Patient',
      assessmentDate: DateTime.now(),
      assessorName: 'Dr Test',
      assessorRole: 'Consultant',
      decisionContext: 'MHCA Treatment Capacity',
      responses: const {},
      overallCapacity: 'Lacks capacity',
      recommendations: 'Refer to safeguarding.',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      riskLevel: RiskLevel.high,
      assessmentStatus: 'completed',
    );
    final id = await db.insertAssessment(a);
    return a.copyWith(id: id);
  }

  Future<Assessment> _insertLowRiskAssessment() async {
    final db = DatabaseService();
    final a = Assessment(
      patientId: 'P002',
      patientName: 'Low Risk Patient',
      assessmentDate: DateTime.now(),
      assessorName: 'Dr Low',
      assessorRole: 'Registrar',
      decisionContext: 'DSM-5 Assessment',
      responses: const {},
      overallCapacity: 'Has capacity',
      recommendations: '',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      riskLevel: RiskLevel.low,
      assessmentStatus: 'completed',
    );
    final id = await db.insertAssessment(a);
    return a.copyWith(id: id);
  }

  // -------------------------------------------------------------------------
  // SignOffRequirement extension
  // -------------------------------------------------------------------------

  group('SignOffRequirement extension', () {
    test('critical risk requires countersignature', () {
      expect(RiskLevel.critical.requiresCountersignature, isTrue);
    });

    test('high risk requires countersignature', () {
      expect(RiskLevel.high.requiresCountersignature, isTrue);
    });

    test('moderate risk does NOT require but recommends', () {
      expect(RiskLevel.moderate.requiresCountersignature, isFalse);
      expect(RiskLevel.moderate.countersignatureRecommended, isTrue);
    });

    test('low risk neither requires nor recommends', () {
      expect(RiskLevel.low.requiresCountersignature, isFalse);
      expect(RiskLevel.low.countersignatureRecommended, isFalse);
    });
  });

  // -------------------------------------------------------------------------
  // Countersignature model
  // -------------------------------------------------------------------------

  group('Countersignature model', () {
    test('factory create generates UUID id', () {
      final cs = Countersignature.create(
        assessmentId: 42,
        signatoryName: 'Dr Second',
        signatoryRole: 'Consultant',
        outcome: CountersignatureOutcome.approved,
      );
      expect(cs.id, isNotEmpty);
      expect(cs.assessmentId, equals(42));
    });

    test('toMap / fromMap round-trip', () {
      final cs = Countersignature.create(
        assessmentId: 1,
        signatoryName: 'Dr Round',
        signatoryRole: 'Registrar',
        outcome: CountersignatureOutcome.approvedWithComments,
        notes: 'Small concerns noted.',
      );
      final map = cs.toMap();
      final restored = Countersignature.fromMap(map);
      expect(restored.id, equals(cs.id));
      expect(restored.signatoryName, equals('Dr Round'));
      expect(restored.outcome, equals(CountersignatureOutcome.approvedWithComments));
      expect(restored.notes, equals('Small concerns noted.'));
    });

    test('outcome label returns correct string', () {
      expect(CountersignatureOutcome.approved.label, equals('Approved'));
      expect(
        CountersignatureOutcome.requestedAmendment.label,
        equals('Request amendment'),
      );
    });
  });

  // -------------------------------------------------------------------------
  // Status transitions
  // -------------------------------------------------------------------------

  group('CountersignatureService — status transitions', () {
    test('requestCountersignature sets status to pending', () async {
      final a = await _insertHighRiskAssessment();
      await CountersignatureService.instance.requestCountersignature(a.id!);
      final updated = await DatabaseService().getAssessment(a.id!);
      expect(updated?.countersignatureStatus, equals('pending'));
    });

    test('submit approved sets status to countersigned', () async {
      final a = await _insertHighRiskAssessment();
      await CountersignatureService.instance.requestCountersignature(a.id!);
      await CountersignatureService.instance.submitCountersignature(
        assessment: (await DatabaseService().getAssessment(a.id!))!,
        signatoryName: 'Dr Second',
        signatoryRole: 'Consultant',
        outcome: CountersignatureOutcome.approved,
      );
      final updated = await DatabaseService().getAssessment(a.id!);
      expect(updated?.countersignatureStatus, equals('countersigned'));
    });

    test('submit approvedWithComments also sets status to countersigned', () async {
      final a = await _insertHighRiskAssessment();
      await CountersignatureService.instance.requestCountersignature(a.id!);
      await CountersignatureService.instance.submitCountersignature(
        assessment: (await DatabaseService().getAssessment(a.id!))!,
        signatoryName: 'Dr Comment',
        signatoryRole: 'Registrar',
        outcome: CountersignatureOutcome.approvedWithComments,
        notes: 'Minor concern.',
      );
      final updated = await DatabaseService().getAssessment(a.id!);
      expect(updated?.countersignatureStatus, equals('countersigned'));
    });

    test('submit requestedAmendment sets status to amendment_requested', () async {
      final a = await _insertHighRiskAssessment();
      await CountersignatureService.instance.requestCountersignature(a.id!);
      await CountersignatureService.instance.submitCountersignature(
        assessment: (await DatabaseService().getAssessment(a.id!))!,
        signatoryName: 'Dr Amend',
        signatoryRole: 'Consultant',
        outcome: CountersignatureOutcome.requestedAmendment,
        notes: 'Please clarify recommendations.',
      );
      final updated = await DatabaseService().getAssessment(a.id!);
      expect(updated?.countersignatureStatus, equals('amendment_requested'));
    });

    test('submit requestedAmendment persists amendmentNote', () async {
      final a = await _insertHighRiskAssessment();
      await CountersignatureService.instance.requestCountersignature(a.id!);
      await CountersignatureService.instance.submitCountersignature(
        assessment: (await DatabaseService().getAssessment(a.id!))!,
        signatoryName: 'Dr A',
        signatoryRole: 'Consultant',
        outcome: CountersignatureOutcome.requestedAmendment,
        notes: 'Clarify the capacity finding.',
      );
      final updated = await DatabaseService().getAssessment(a.id!);
      expect(updated?.amendmentNote, equals('Clarify the capacity finding.'));
    });

    test('requestedAmendment without notes throws ArgumentError', () async {
      final a = await _insertHighRiskAssessment();
      expect(
        () => CountersignatureService.instance.submitCountersignature(
          assessment: a,
          signatoryName: 'Dr A',
          signatoryRole: 'Consultant',
          outcome: CountersignatureOutcome.requestedAmendment,
          notes: null,
        ),
        throwsArgumentError,
      );
    });

    test('submitting for unsaved assessment throws ArgumentError', () {
      final unsaved = Assessment(
        patientId: 'X',
        patientName: 'X',
        assessmentDate: DateTime.now(),
        assessorName: 'Dr X',
        assessorRole: 'Consultant',
        decisionContext: 'Test',
        responses: const {},
        overallCapacity: 'N/A',
        recommendations: '',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      expect(
        () => CountersignatureService.instance.submitCountersignature(
          assessment: unsaved,
          signatoryName: 'Dr B',
          signatoryRole: 'Consultant',
          outcome: CountersignatureOutcome.approved,
        ),
        throwsArgumentError,
      );
    });
  });

  // -------------------------------------------------------------------------
  // Queries
  // -------------------------------------------------------------------------

  group('CountersignatureService — queries', () {
    test('getCountersignature returns null before any sign-off', () async {
      final a = await _insertHighRiskAssessment();
      final cs = await CountersignatureService.instance.getCountersignature(a.id!);
      expect(cs, isNull);
    });

    test('getCountersignature returns record after sign-off', () async {
      final a = await _insertHighRiskAssessment();
      await CountersignatureService.instance.requestCountersignature(a.id!);
      await CountersignatureService.instance.submitCountersignature(
        assessment: (await DatabaseService().getAssessment(a.id!))!,
        signatoryName: 'Dr Verify',
        signatoryRole: 'Consultant',
        outcome: CountersignatureOutcome.approved,
      );
      final cs = await CountersignatureService.instance.getCountersignature(a.id!);
      expect(cs, isNotNull);
      expect(cs!.signatoryName, equals('Dr Verify'));
      expect(cs.outcome, equals(CountersignatureOutcome.approved));
    });

    test('pendingSignOffs returns only pending assessments', () async {
      final high = await _insertHighRiskAssessment();
      final low = await _insertLowRiskAssessment();

      await CountersignatureService.instance.requestCountersignature(high.id!);
      // low is not set to pending

      final pending = await CountersignatureService.instance.pendingSignOffs();
      expect(pending.map((a) => a.id), contains(high.id));
      expect(pending.map((a) => a.id), isNot(contains(low.id)));
    });

    test('pendingSignOffs excludes countersigned assessments', () async {
      final a = await _insertHighRiskAssessment();
      await CountersignatureService.instance.requestCountersignature(a.id!);
      await CountersignatureService.instance.submitCountersignature(
        assessment: (await DatabaseService().getAssessment(a.id!))!,
        signatoryName: 'Dr Done',
        signatoryRole: 'Consultant',
        outcome: CountersignatureOutcome.approved,
      );
      final pending = await CountersignatureService.instance.pendingSignOffs();
      expect(pending.map((a) => a.id), isNot(contains(a.id)));
    });
  });

  // -------------------------------------------------------------------------
  // Amendment guard
  // -------------------------------------------------------------------------

  group('CountersignatureService — amendment guard', () {
    test('applyAmendmentEdits updates doctorNotes and recommendations', () async {
      final a = await _insertHighRiskAssessment();
      final updated = CountersignatureService.instance.applyAmendmentEdits(
        a,
        doctorNotes: 'Reviewed — capacity maintained.',
        recommendations: 'Continue monitoring.',
      );
      expect(updated.doctorNotes, equals('Reviewed — capacity maintained.'));
      expect(updated.recommendations, equals('Continue monitoring.'));
    });

    test('applyAmendmentEdits preserves all immutable fields', () async {
      final a = await _insertHighRiskAssessment();
      final updated = CountersignatureService.instance.applyAmendmentEdits(
        a,
        doctorNotes: 'New notes',
      );
      // All immutable clinical fields must be unchanged.
      expect(updated.patientId, equals(a.patientId));
      expect(updated.patientName, equals(a.patientName));
      expect(updated.overallCapacity, equals(a.overallCapacity));
      expect(updated.responses, equals(a.responses));
      expect(updated.riskLevel, equals(a.riskLevel));
      expect(updated.assessmentDate, equals(a.assessmentDate));
    });
  });

  // -------------------------------------------------------------------------
  // Convenience helpers
  // -------------------------------------------------------------------------

  group('CountersignatureService — convenience helpers', () {
    test('requiresCountersignature delegates to RiskLevel extension', () async {
      final high = await _insertHighRiskAssessment();
      final low = await _insertLowRiskAssessment();
      expect(
        CountersignatureService.instance.requiresCountersignature(high),
        isTrue,
      );
      expect(
        CountersignatureService.instance.requiresCountersignature(low),
        isFalse,
      );
    });

    test('countersignatureRecommended true for moderate+', () {
      final moderate = Assessment(
        patientId: 'M',
        patientName: 'M',
        assessmentDate: DateTime.now(),
        assessorName: 'Dr M',
        assessorRole: 'Consultant',
        decisionContext: 'Test',
        responses: const {},
        overallCapacity: 'N/A',
        recommendations: '',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        riskLevel: RiskLevel.moderate,
      );
      expect(
        CountersignatureService.instance.countersignatureRecommended(moderate),
        isTrue,
      );
    });
  });
}
