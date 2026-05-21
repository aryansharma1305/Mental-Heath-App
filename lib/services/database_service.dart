import 'package:flutter/foundation.dart';
import 'package:sqflite_sqlcipher/sqflite.dart';
import 'package:path/path.dart';
import '../models/assessment.dart';
import '../models/clinical_note.dart';
import '../models/consent_basis.dart';
import '../models/consent_record.dart';
import '../models/patient_profile.dart';
import '../models/risk_level.dart';
import '../models/user.dart';
import 'database_encryption_migration_service.dart';
import 'encryption_service.dart';
import 'risk_stratification_service.dart';
import 'supabase_service.dart';

class DatabaseService {
  static Database? _database;
  static const String _databaseName = 'mental_capacity_assessments.db';
  static const int _databaseVersion = 6;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), _databaseName);
    final key = await EncryptionService().getDatabaseKey();
    await const DatabaseEncryptionMigrationService().migrateIfNeeded(path, key);
    return await openDatabase(
      path,
      password: key,
      version: _databaseVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    // Assessments table
    await db.execute('''
      CREATE TABLE patients(
        patient_id TEXT PRIMARY KEY,
        display_name TEXT NOT NULL,
        demographics_json TEXT,
        clinical_summary TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        last_assessment_at TEXT,
        assessment_count INTEGER DEFAULT 0
      )
    ''');

    await db.execute('''
      CREATE TABLE assessments(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        patient_id TEXT NOT NULL,
        patient_name TEXT NOT NULL,
        patient_user_id TEXT,
        assessment_date TEXT NOT NULL,
        assessor_name TEXT NOT NULL,
        assessor_role TEXT NOT NULL,
        assessor_user_id TEXT,
        decision_context TEXT NOT NULL,
        responses TEXT NOT NULL,
        overall_capacity TEXT NOT NULL,
        recommendations TEXT,
        status TEXT DEFAULT 'pending',
        reviewed_by TEXT,
        reviewed_at TEXT,
        doctor_notes TEXT,
        template_id INTEGER,
        is_synced INTEGER DEFAULT 0,
        risk_level TEXT DEFAULT 'low',
        consent_basis TEXT,
        consent_notes TEXT,
        consent_recorded_at TEXT,
        consent_recorded_by TEXT,
        assessment_status TEXT DEFAULT 'active',
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE clinical_notes(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        patient_id TEXT NOT NULL,
        assessment_id INTEGER,
        note TEXT NOT NULL,
        author_name TEXT NOT NULL,
        author_user_id TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        FOREIGN KEY (patient_id) REFERENCES patients(patient_id),
        FOREIGN KEY (assessment_id) REFERENCES assessments(id) ON DELETE SET NULL
      )
    ''');

    // Users table with roles
    await db.execute('''
      CREATE TABLE users(
        id TEXT PRIMARY KEY,
        username TEXT UNIQUE NOT NULL,
        email TEXT UNIQUE NOT NULL,
        full_name TEXT NOT NULL,
        role TEXT NOT NULL,
        department TEXT,
        password_hash TEXT,
        is_active INTEGER DEFAULT 1,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');

    // Questions table for admin management
    await db.execute('''
      CREATE TABLE questions(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        question_text TEXT NOT NULL,
        question_type TEXT NOT NULL,
        options TEXT,
        required INTEGER DEFAULT 1,
        category TEXT,
        order_index INTEGER DEFAULT 0,
        is_active INTEGER DEFAULT 1,
        created_by TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');

    // Question responses table
    await db.execute('''
      CREATE TABLE question_responses(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        assessment_id INTEGER NOT NULL,
        question_id INTEGER NOT NULL,
        answer TEXT NOT NULL,
        created_at TEXT NOT NULL,
        FOREIGN KEY (assessment_id) REFERENCES assessments(id),
        FOREIGN KEY (question_id) REFERENCES questions(id)
      )
    ''');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // Add new columns for version 2
      try {
        await db.execute(
          'ALTER TABLE assessments ADD COLUMN patient_user_id TEXT',
        );
        await db.execute(
          'ALTER TABLE assessments ADD COLUMN assessor_user_id TEXT',
        );
        await db.execute(
          'ALTER TABLE assessments ADD COLUMN status TEXT DEFAULT "pending"',
        );
        await db.execute('ALTER TABLE assessments ADD COLUMN reviewed_by TEXT');
        await db.execute('ALTER TABLE assessments ADD COLUMN reviewed_at TEXT');

        await db.execute('''
          CREATE TABLE IF NOT EXISTS questions(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            question_text TEXT NOT NULL,
            question_type TEXT NOT NULL,
            options TEXT,
            required INTEGER DEFAULT 1,
            category TEXT,
            order_index INTEGER DEFAULT 0,
            is_active INTEGER DEFAULT 1,
            created_by TEXT,
            created_at TEXT NOT NULL,
            updated_at TEXT NOT NULL
          )
        ''');

        await db.execute('''
          CREATE TABLE IF NOT EXISTS question_responses(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            assessment_id INTEGER NOT NULL,
            question_id INTEGER NOT NULL,
            answer TEXT NOT NULL,
            created_at TEXT NOT NULL,
            FOREIGN KEY (assessment_id) REFERENCES assessments(id),
            FOREIGN KEY (question_id) REFERENCES questions(id)
          )
        ''');
      } catch (e) {
        // Columns might already exist
      }
    }

    if (oldVersion < 3) {
      try {
        await db.execute(
          'ALTER TABLE assessments ADD COLUMN is_synced INTEGER DEFAULT 0',
        );
      } catch (e) {
        // Column might already exist
      }
    }

    if (oldVersion < 4) {
      await _createPatientTables(db);
      await _backfillPatientsFromAssessments(db);
    }

    if (oldVersion < 5) {
      await _ensureRiskLevelColumn(db);
      await _backfillRiskLevels(db);
    }

    if (oldVersion < 6) {
      await _ensureConsentColumns(db);
    }
  }

  Future<void> _ensureRiskLevelColumn(Database db) async {
    try {
      await db.execute(
        'ALTER TABLE assessments ADD COLUMN risk_level TEXT DEFAULT "low"',
      );
    } catch (e) {
      // Column might already exist.
    }
  }

  Future<void> _ensureConsentColumns(Database db) async {
    for (final statement in [
      'ALTER TABLE assessments ADD COLUMN consent_basis TEXT',
      'ALTER TABLE assessments ADD COLUMN consent_notes TEXT',
      'ALTER TABLE assessments ADD COLUMN consent_recorded_at TEXT',
      'ALTER TABLE assessments ADD COLUMN consent_recorded_by TEXT',
      'ALTER TABLE assessments ADD COLUMN assessment_status TEXT DEFAULT "active"',
    ]) {
      try {
        await db.execute(statement);
      } catch (e) {
        // Column might already exist.
      }
    }
  }

  Future<void> _createPatientTables(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS patients(
        patient_id TEXT PRIMARY KEY,
        display_name TEXT NOT NULL,
        demographics_json TEXT,
        clinical_summary TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        last_assessment_at TEXT,
        assessment_count INTEGER DEFAULT 0
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS clinical_notes(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        patient_id TEXT NOT NULL,
        assessment_id INTEGER,
        note TEXT NOT NULL,
        author_name TEXT NOT NULL,
        author_user_id TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        FOREIGN KEY (patient_id) REFERENCES patients(patient_id),
        FOREIGN KEY (assessment_id) REFERENCES assessments(id) ON DELETE SET NULL
      )
    ''');
  }

  Future<void> _backfillPatientsFromAssessments(Database db) async {
    final rows = await db.rawQuery('''
      SELECT
        patient_id,
        COALESCE(NULLIF(patient_name, ''), patient_id) AS display_name,
        MIN(created_at) AS created_at,
        MAX(assessment_date) AS last_assessment_at,
        COUNT(*) AS assessment_count
      FROM assessments
      WHERE patient_id IS NOT NULL AND patient_id != ''
      GROUP BY patient_id
    ''');

    final now = DateTime.now().toIso8601String();
    for (final row in rows) {
      await db.insert('patients', {
        'patient_id': row['patient_id'],
        'display_name': row['display_name'],
        'created_at': row['created_at'] ?? now,
        'updated_at': now,
        'last_assessment_at': row['last_assessment_at'],
        'assessment_count': row['assessment_count'] ?? 0,
      }, conflictAlgorithm: ConflictAlgorithm.ignore);
    }
  }

  Future<void> _backfillRiskLevels(Database db) async {
    final rows = await db.query('assessments');
    for (final row in rows) {
      final assessment = Assessment.fromMap(row);
      final riskLevel = RiskStratificationService.computeForAssessment(
        assessment,
      );
      await db.update(
        'assessments',
        {'risk_level': riskLevel.name},
        where: 'id = ?',
        whereArgs: [assessment.id],
      );
    }
  }

  Future<int> insertAssessment(Assessment assessment) async {
    final db = await database;
    try {
      _validateAssessmentForInsert(assessment);
      final assessmentWithRisk = assessment.copyWith(
        riskLevel: assessment.isRefused
            ? assessment.riskLevel
            : RiskStratificationService.computeForAssessment(assessment),
      );

      await upsertPatientFromAssessment(assessmentWithRisk);

      // 1. Insert locally first (offline-first)
      final id = await db.insert('assessments', assessmentWithRisk.toMap());
      await _refreshPatientAssessmentStats(
        db,
        assessmentWithRisk.patientId,
        assessmentWithRisk.assessmentDate,
      );

      // 2. Try to sync to Supabase if available
      try {
        if (SupabaseService.isAvailable) {
          final supabaseId = await SupabaseService().insertAssessment(
            assessmentWithRisk,
          );
          if (supabaseId != null) {
            // Update local record to synced
            await db.update(
              'assessments',
              {'is_synced': 1},
              where: 'id = ?',
              whereArgs: [id],
            );
          }
        }
      } catch (e) {
        // Silent failure for sync - will be picked up by background sync later
        debugPrint('Sync failed: $e');
      }

      return id;
    } catch (e) {
      debugPrint('Insert failed: $e');
      rethrow;
    }
  }

  Future<Assessment> saveRefusalRecord({
    required String patientId,
    required String patientName,
    required String assessmentType,
    required ConsentRecord consent,
    required bool emergencyContext,
  }) async {
    consent.validate();
    if (consent.basis != ConsentBasis.refused) {
      throw ArgumentError('saveRefusalRecord requires ConsentBasis.refused.');
    }

    final now = DateTime.now();
    final assessment = Assessment(
      patientId: patientId,
      patientName: patientName,
      assessmentDate: now,
      assessorName: consent.recordedBy,
      assessorRole: 'Clinician',
      decisionContext: '$assessmentType Consent Refusal',
      responses: const {},
      overallCapacity: 'Consent refused',
      recommendations: 'No clinical assessment data was collected.',
      createdAt: now,
      updatedAt: now,
      status: 'refused',
      assessmentStatus: 'refused',
      consentBasis: ConsentBasis.refused,
      consentNotes: consent.notes,
      consentRecordedAt: consent.recordedAt,
      consentRecordedBy: consent.recordedBy,
      riskLevel: emergencyContext ? RiskLevel.critical : RiskLevel.moderate,
      isSynced: false,
    );

    final id = await insertAssessment(assessment);
    return assessment.copyWith(id: id);
  }

  void _validateAssessmentForInsert(Assessment assessment) {
    if (assessment.consentBasis == ConsentBasis.refused) {
      if (assessment.assessmentStatus != 'refused') {
        throw ArgumentError(
          'Refused consent records must be saved as refused.',
        );
      }
      if (assessment.consentNotes == null ||
          assessment.consentNotes!.trim().isEmpty) {
        throw ArgumentError('Refused consent records require notes.');
      }
      if (assessment.responses.isNotEmpty) {
        throw ArgumentError(
          'Refused consent records cannot contain assessment responses.',
        );
      }
    }
  }

  Future<void> upsertPatientFromAssessment(Assessment assessment) async {
    if (assessment.patientId.trim().isEmpty) return;

    final db = await database;
    final now = DateTime.now().toIso8601String();
    final displayName = assessment.patientName.trim().isEmpty
        ? assessment.patientId.trim()
        : assessment.patientName.trim();

    await db.insert('patients', {
      'patient_id': assessment.patientId.trim(),
      'display_name': displayName,
      'created_at': assessment.createdAt.toIso8601String(),
      'updated_at': now,
      'last_assessment_at': assessment.assessmentDate.toIso8601String(),
      'assessment_count': 0,
    }, conflictAlgorithm: ConflictAlgorithm.ignore);

    await db.update(
      'patients',
      {
        'display_name': displayName,
        'updated_at': now,
        'last_assessment_at': assessment.assessmentDate.toIso8601String(),
      },
      where: 'patient_id = ?',
      whereArgs: [assessment.patientId.trim()],
    );
  }

  Future<void> _refreshPatientAssessmentStats(
    Database db,
    String patientId,
    DateTime fallbackLastAssessment,
  ) async {
    if (patientId.trim().isEmpty) return;

    final stats = await db.rawQuery(
      '''
      SELECT COUNT(*) AS assessment_count, MAX(assessment_date) AS last_assessment_at
      FROM assessments
      WHERE patient_id = ?
      ''',
      [patientId.trim()],
    );

    final row = stats.isNotEmpty ? stats.first : <String, Object?>{};
    await db.update(
      'patients',
      {
        'assessment_count': row['assessment_count'] ?? 0,
        'last_assessment_at':
            row['last_assessment_at'] ??
            fallbackLastAssessment.toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      },
      where: 'patient_id = ?',
      whereArgs: [patientId.trim()],
    );
  }

  Future<void> syncPendingAssessments() async {
    final db = await database;
    try {
      debugPrint('SYNC: Starting syncPendingAssessments...');

      if (!SupabaseService.isAvailable) {
        debugPrint('SYNC: Supabase is NOT available. Skipping sync.');
        return;
      }

      // Get all unsynced assessments
      final List<Map<String, dynamic>> maps = await db.query(
        'assessments',
        where: 'is_synced = 0 OR is_synced IS NULL',
      );

      debugPrint('SYNC: Found ${maps.length} unsynced assessments');

      for (var map in maps) {
        final assessment = Assessment.fromMap(map);
        try {
          debugPrint('SYNC: Attempting to sync assessment ${assessment.id}...');
          final supabaseId = await SupabaseService().insertAssessment(
            assessment,
          );

          if (supabaseId != null) {
            debugPrint(
              'SYNC: Assessment ${assessment.id} synced to Supabase (ID: $supabaseId)',
            );
            await db.update(
              'assessments',
              {'is_synced': 1},
              where: 'id = ?',
              whereArgs: [assessment.id],
            );
          } else {
            debugPrint(
              'SYNC: Failed to sync assessment ${assessment.id} - Insert returned null',
            );
          }
        } catch (e) {
          debugPrint('SYNC: Exception syncing assessment ${assessment.id}: $e');
        }
      }
    } catch (e) {
      debugPrint('SYNC: Critical Error: $e');
    }
  }

  Future<List<Assessment>> getAllAssessments() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'assessments',
      orderBy: 'assessment_date DESC',
    );
    return List.generate(maps.length, (i) => Assessment.fromMap(maps[i]));
  }

  Future<List<PatientProfile>> getAllPatients() async {
    final db = await database;
    final maps = await db.query(
      'patients',
      orderBy: 'last_assessment_at DESC, updated_at DESC',
    );
    return maps.map(PatientProfile.fromMap).toList();
  }

  Future<PatientProfile?> getPatient(String patientId) async {
    final db = await database;
    final maps = await db.query(
      'patients',
      where: 'patient_id = ?',
      whereArgs: [patientId],
      limit: 1,
    );
    if (maps.isEmpty) return null;
    return PatientProfile.fromMap(maps.first);
  }

  Future<int> upsertPatient(PatientProfile patient) async {
    final db = await database;
    return db.insert(
      'patients',
      patient.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<Assessment>> getAssessmentsByPatientCode(String patientId) async {
    final db = await database;
    final maps = await db.query(
      'assessments',
      where: 'patient_id = ?',
      whereArgs: [patientId],
      orderBy: 'assessment_date DESC',
    );
    return maps.map(Assessment.fromMap).toList();
  }

  Future<Map<String, RiskLevel>> getWorstRiskLevelsByPatient() async {
    final db = await database;
    final rows = await db.query(
      'assessments',
      columns: ['patient_id', 'risk_level'],
    );
    final riskByPatient = <String, RiskLevel>{};
    for (final row in rows) {
      final patientId = (row['patient_id'] ?? '').toString();
      if (patientId.isEmpty) continue;
      final risk = riskLevelFromString(row['risk_level'] as String?);
      final existing = riskByPatient[patientId];
      if (existing == null || risk.priority > existing.priority) {
        riskByPatient[patientId] = risk;
      }
    }
    return riskByPatient;
  }

  Future<List<ClinicalNote>> getClinicalNotesForPatient(
    String patientId,
  ) async {
    final db = await database;
    final maps = await db.query(
      'clinical_notes',
      where: 'patient_id = ?',
      whereArgs: [patientId],
      orderBy: 'created_at DESC',
    );
    return maps.map(ClinicalNote.fromMap).toList();
  }

  Future<int> insertClinicalNote(ClinicalNote note) async {
    final db = await database;
    return db.insert('clinical_notes', note.toMap());
  }

  Future<Assessment?> getAssessment(int id) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'assessments',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isNotEmpty) {
      return Assessment.fromMap(maps.first);
    }
    return null;
  }

  Future<int> updateAssessment(Assessment assessment) async {
    final db = await database;
    final existing = assessment.id == null
        ? null
        : await getAssessment(assessment.id!);
    if (existing?.assessmentStatus == 'refused') {
      throw StateError('Refused assessment records are locked.');
    }
    return await db.update(
      'assessments',
      assessment.toMap(),
      where: 'id = ?',
      whereArgs: [assessment.id],
    );
  }

  Future<int> deleteAssessment(int id) async {
    final db = await database;
    final assessment = await getAssessment(id);
    final deleted = await db.transaction((txn) async {
      await txn.update(
        'clinical_notes',
        {'assessment_id': null, 'updated_at': DateTime.now().toIso8601String()},
        where: 'assessment_id = ?',
        whereArgs: [id],
      );
      return txn.delete('assessments', where: 'id = ?', whereArgs: [id]);
    });

    if (assessment != null) {
      await _refreshPatientAssessmentStats(
        db,
        assessment.patientId,
        assessment.assessmentDate,
      );
    }
    return deleted;
  }

  Future<List<Assessment>> searchAssessments(String query) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'assessments',
      where: 'patient_name LIKE ? OR patient_id LIKE ?',
      whereArgs: ['%$query%', '%$query%'],
      orderBy: 'assessment_date DESC',
    );
    return List.generate(maps.length, (i) => Assessment.fromMap(maps[i]));
  }

  // User management methods
  Future<int> insertUser(User user) async {
    final db = await database;
    return await db.insert('users', user.toMap());
  }

  Future<User?> getUserByUsername(String username) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'users',
      where: 'username = ?',
      whereArgs: [username],
    );
    if (maps.isNotEmpty) {
      return User.fromMap(maps.first);
    }
    return null;
  }

  Future<User?> getUserById(String id) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'users',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isNotEmpty) {
      return User.fromMap(maps.first);
    }
    return null;
  }

  Future<String?> getPasswordHash(String username) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'users',
      columns: ['password_hash'],
      where: 'username = ?',
      whereArgs: [username],
    );
    if (maps.isNotEmpty) {
      return maps.first['password_hash'] as String?;
    }
    return null;
  }

  Future<void> savePasswordHash(String username, String passwordHash) async {
    final db = await database;
    await db.update(
      'users',
      {'password_hash': passwordHash},
      where: 'username = ?',
      whereArgs: [username],
    );
  }

  Future<List<Assessment>> getAssessmentsByPatientId(
    String patientUserId,
  ) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'assessments',
      where: 'patient_user_id = ?',
      whereArgs: [patientUserId],
      orderBy: 'assessment_date DESC',
    );
    return List.generate(maps.length, (i) => Assessment.fromMap(maps[i]));
  }

  Future<List<Assessment>> getPendingAssessments() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'assessments',
      where: 'status = ?',
      whereArgs: ['pending'],
      orderBy: 'assessment_date DESC',
    );
    return List.generate(maps.length, (i) => Assessment.fromMap(maps[i]));
  }

  Future<List<Assessment>> getAssessmentsByAssessorId(
    String assessorUserId,
  ) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'assessments',
      where: 'assessor_user_id = ?',
      whereArgs: [assessorUserId],
      orderBy: 'assessment_date DESC',
    );
    return List.generate(maps.length, (i) => Assessment.fromMap(maps[i]));
  }

  Future<List<Assessment>> getUnassignedAssessments() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'assessments',
      where: 'assessor_user_id IS NULL OR assessor_user_id = ?',
      whereArgs: [''],
      orderBy: 'assessment_date DESC',
    );
    return List.generate(maps.length, (i) => Assessment.fromMap(maps[i]));
  }
}
