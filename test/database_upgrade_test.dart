import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:mental_capacity_assessment/services/database_service.dart';

void main() {
  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    sqfliteFfiInit();
  });

  tearDown(() {
    DatabaseService.resetForTesting();
  });

  test('fresh database includes current audit log schema', () async {
    DatabaseService.overrideFactoryForTesting(databaseFactoryFfi);

    final db = await DatabaseService().database;
    final tables = await db.rawQuery(
      "SELECT name FROM sqlite_master WHERE type = 'table' AND name = ?",
      ['audit_logs'],
    );
    final columns = await db.rawQuery('PRAGMA table_info(audit_logs)');

    expect(tables, isNotEmpty);
    expect(columns.map((c) => c['name']), containsAll(['action', 'metadata']));
  });

  test(
    'version 10 database upgrades to version 11 without data loss',
    () async {
      final dir = await Directory.systemTemp.createTemp('mca_upgrade_test_');
      final dbPath = p.join(dir.path, 'legacy_v10.db');

      try {
        final legacyDb = await databaseFactoryFfi.openDatabase(
          dbPath,
          options: OpenDatabaseOptions(
            version: 10,
            onCreate: (db, version) async {
              await db.execute('''
              CREATE TABLE patients(
                patient_id TEXT PRIMARY KEY,
                display_name TEXT NOT NULL,
                created_at TEXT NOT NULL,
                updated_at TEXT NOT NULL,
                assessment_count INTEGER DEFAULT 0
              )
            ''');
              await db.execute('''
              CREATE TABLE assessments(
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                patient_id TEXT NOT NULL,
                patient_name TEXT NOT NULL,
                assessment_date TEXT NOT NULL,
                assessor_name TEXT NOT NULL,
                assessor_role TEXT NOT NULL,
                decision_context TEXT NOT NULL,
                responses TEXT NOT NULL,
                overall_capacity TEXT NOT NULL,
                recommendations TEXT,
                recommendations_json TEXT,
                status TEXT DEFAULT 'pending',
                is_synced INTEGER DEFAULT 0,
                risk_level TEXT DEFAULT 'low',
                consent_basis TEXT,
                consent_notes TEXT,
                consent_recorded_at TEXT,
                consent_recorded_by TEXT,
                assessment_status TEXT DEFAULT 'active',
                prior_assessment_id INTEGER,
                countersignature_status TEXT,
                amendment_note TEXT,
                created_at TEXT NOT NULL,
                updated_at TEXT NOT NULL
              )
            ''');
              await db.insert('assessments', {
                'patient_id': 'legacy-patient',
                'patient_name': 'Legacy Patient',
                'assessment_date': DateTime(2026, 1, 1).toIso8601String(),
                'assessor_name': 'Dr Legacy',
                'assessor_role': 'Doctor',
                'decision_context': 'DSM-5 Assessment',
                'responses': '{}',
                'overall_capacity': 'Mild symptoms',
                'recommendations': '',
                'created_at': DateTime(2026, 1, 1).toIso8601String(),
                'updated_at': DateTime(2026, 1, 1).toIso8601String(),
              });
            },
          ),
        );
        await legacyDb.close();

        DatabaseService.overrideFactoryForTesting(databaseFactoryFfi);
        DatabaseService.overrideDatabasePathForTesting(dbPath);

        final upgradedDb = await DatabaseService().database;
        final tables = await upgradedDb.rawQuery(
          "SELECT name FROM sqlite_master WHERE type = 'table' AND name = ?",
          ['audit_logs'],
        );
        final assessments = await upgradedDb.query('assessments');

        expect(tables, isNotEmpty);
        expect(assessments, hasLength(1));
        expect(assessments.first['patient_id'], 'legacy-patient');
      } finally {
        await dir.delete(recursive: true);
      }
    },
  );
}
