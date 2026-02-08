import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/assessment.dart';
import '../models/question.dart';
import '../models/user.dart';
import 'supabase_service.dart';

class DatabaseService {
  static Database? _database;
  static const String _databaseName = 'mental_capacity_assessments.db';
  static const int _databaseVersion = 3;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), _databaseName);
    return await openDatabase(
      path,
      version: _databaseVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    // Assessments table
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
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
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
        await db.execute('ALTER TABLE assessments ADD COLUMN patient_user_id TEXT');
        await db.execute('ALTER TABLE assessments ADD COLUMN assessor_user_id TEXT');
        await db.execute('ALTER TABLE assessments ADD COLUMN status TEXT DEFAULT "pending"');
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
        await db.execute('ALTER TABLE assessments ADD COLUMN is_synced INTEGER DEFAULT 0');
      } catch (e) {
        // Column might already exist
      }
    }
  }

  Future<int> insertAssessment(Assessment assessment) async {
    final db = await database;
    try {
      // 1. Insert locally first (offline-first)
      final id = await db.insert('assessments', assessment.toMap());
      
      // 2. Try to sync to Supabase if available
      try {
        if (SupabaseService.isAvailable) {
          final supabaseId = await SupabaseService().insertAssessment(assessment);
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
        print('Sync failed: $e');
      }
      
      return id;
    } catch (e) {
      print('Insert failed: $e');
      return -1;
    }
  }

  Future<void> syncPendingAssessments() async {
    final db = await database;
    try {
      if (!SupabaseService.isAvailable) return;

      // Get all unsynced assessments
      final List<Map<String, dynamic>> maps = await db.query(
        'assessments',
        where: 'is_synced = 0 OR is_synced IS NULL',
      );

      for (var map in maps) {
        final assessment = Assessment.fromMap(map);
        try {
          await SupabaseService().insertAssessment(assessment);
          await db.update(
            'assessments',
            {'is_synced': 1},
            where: 'id = ?',
            whereArgs: [assessment.id],
          );
        } catch (e) {
          print('Failed to sync assessment ${assessment.id}: $e');
        }
      }
    } catch (e) {
      print('Sync Error: $e');
    }
  }

  Future<List<Assessment>> getAllAssessments() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('assessments',
        orderBy: 'assessment_date DESC');
    return List.generate(maps.length, (i) => Assessment.fromMap(maps[i]));
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
    return await db.update(
      'assessments',
      assessment.toMap(),
      where: 'id = ?',
      whereArgs: [assessment.id],
    );
  }

  Future<int> deleteAssessment(int id) async {
    final db = await database;
    return await db.delete(
      'assessments',
      where: 'id = ?',
      whereArgs: [id],
    );
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

  Future<List<Assessment>> getAssessmentsByPatientId(String patientUserId) async {
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

  Future<List<Assessment>> getAssessmentsByAssessorId(String assessorUserId) async {
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