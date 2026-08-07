import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:mental_capacity_assessment/models/assessment.dart';
import 'package:mental_capacity_assessment/models/consent_basis.dart';
import 'package:mental_capacity_assessment/models/consent_record.dart';
import 'package:mental_capacity_assessment/models/risk_level.dart';
import 'package:mental_capacity_assessment/services/database_service.dart';

void main() {
  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    sqfliteFfiInit();
  });

  setUp(() {
    DatabaseService.resetForTesting();
    DatabaseService.overrideFactoryForTesting(databaseFactoryFfi);
  });

  tearDown(() {
    DatabaseService.resetForTesting();
  });

  test('insertAssessment writes assessment_created audit log', () async {
    final db = DatabaseService();
    final now = DateTime.now();

    final id = await db.insertAssessment(
      Assessment(
        patientId: 'audit-patient-1',
        patientName: 'Audit Patient',
        assessmentDate: now,
        assessorName: 'Dr Audit',
        assessorRole: 'Doctor',
        decisionContext: 'DSM-5 Assessment',
        responses: const {'q1': 1},
        overallCapacity: 'Mild symptoms',
        recommendations: '',
        createdAt: now,
        updatedAt: now,
        riskLevel: RiskLevel.low,
        assessmentStatus: 'completed',
      ),
    );

    final logs = await db.getAuditLogsForPatient('audit-patient-1');
    expect(logs, hasLength(1));
    expect(logs.first.action, 'assessment_created');
    expect(logs.first.entityId, '$id');
    expect(logs.first.metadata['decision_context'], 'DSM-5 Assessment');
  });

  test('saveRefusalRecord writes refusal_record_created audit log', () async {
    final db = DatabaseService();

    await db.saveRefusalRecord(
      patientId: 'audit-patient-2',
      patientName: 'Refusal Patient',
      assessmentType: 'DSM-5',
      consent: ConsentRecord(
        basis: ConsentBasis.refused,
        notes: 'Patient declined assessment.',
        recordedAt: DateTime.now(),
        recordedBy: 'Dr Audit',
      ),
      emergencyContext: true,
    );

    final logs = await db.getAuditLogsForPatient('audit-patient-2');
    expect(logs, hasLength(1));
    expect(logs.first.action, 'refusal_record_created');
    expect(logs.first.metadata['risk_level'], RiskLevel.critical.name);
    expect(logs.first.metadata['assessment_status'], 'refused');
  });
}
