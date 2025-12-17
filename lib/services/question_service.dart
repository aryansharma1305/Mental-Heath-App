import '../models/question.dart';
import 'database_service.dart';

class QuestionService {
  final DatabaseService _databaseService = DatabaseService();

  // Get all active questions ordered by order_index
  Future<List<Question>> getActiveQuestions() async {
    final db = await _databaseService.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'questions',
      where: 'is_active = ?',
      whereArgs: [1],
      orderBy: 'order_index ASC, created_at ASC',
    );
    return maps.map((map) => Question.fromMap(map)).toList();
  }

  // Get all questions (including inactive) for admin
  Future<List<Question>> getAllQuestions() async {
    final db = await _databaseService.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'questions',
      orderBy: 'order_index ASC, created_at ASC',
    );
    return maps.map((map) => Question.fromMap(map)).toList();
  }

  // Get question by ID
  Future<Question?> getQuestion(int id) async {
    final db = await _databaseService.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'questions',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isNotEmpty) {
      return Question.fromMap(maps.first);
    }
    return null;
  }

  // Add new question (Admin only)
  Future<int> addQuestion(Question question) async {
    final db = await _databaseService.database;
    return await db.insert('questions', question.toMap());
  }

  // Update question (Admin only)
  Future<int> updateQuestion(Question question) async {
    final db = await _databaseService.database;
    final updatedQuestion = question.copyWith(updatedAt: DateTime.now());
    return await db.update(
      'questions',
      updatedQuestion.toMap(),
      where: 'id = ?',
      whereArgs: [question.id],
    );
  }

  // Delete question (Admin only) - soft delete by setting is_active = 0
  Future<int> deleteQuestion(int id) async {
    final db = await _databaseService.database;
    return await db.update(
      'questions',
      {
        'is_active': 0,
        'updated_at': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Reorder questions (Admin only)
  Future<void> reorderQuestions(List<int> questionIds) async {
    final db = await _databaseService.database;
    final batch = db.batch();
    
    for (int i = 0; i < questionIds.length; i++) {
      batch.update(
        'questions',
        {
          'order_index': i,
          'updated_at': DateTime.now().toIso8601String(),
        },
        where: 'id = ?',
        whereArgs: [questionIds[i]],
      );
    }
    
    await batch.commit(noResult: true);
  }

  // Get questions by category
  Future<List<Question>> getQuestionsByCategory(String category) async {
    final db = await _databaseService.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'questions',
      where: 'category = ? AND is_active = ?',
      whereArgs: [category, 1],
      orderBy: 'order_index ASC',
    );
    return maps.map((map) => Question.fromMap(map)).toList();
  }

  // Initialize default questions if none exist
  Future<void> initializeDefaultQuestions(String adminUserId) async {
    final existingQuestions = await getAllQuestions();
    if (existingQuestions.isNotEmpty) return;

    final defaultQuestions = [
      Question(
        text: 'Do you understand what decision needs to be made?',
        type: QuestionType.yesNo,
        required: true,
        category: 'Understanding',
        order: 1,
        createdBy: adminUserId,
      ),
      Question(
        text: 'Can you explain the decision in your own words?',
        type: QuestionType.textInput,
        required: true,
        category: 'Understanding',
        order: 2,
        createdBy: adminUserId,
      ),
      Question(
        text: 'Do you understand the consequences of this decision?',
        type: QuestionType.yesNo,
        required: true,
        category: 'Understanding',
        order: 3,
        createdBy: adminUserId,
      ),
      Question(
        text: 'Can you remember the information relevant to this decision?',
        type: QuestionType.yesNo,
        required: true,
        category: 'Retention',
        order: 4,
        createdBy: adminUserId,
      ),
      Question(
        text: 'How confident are you in making this decision?',
        type: QuestionType.scale,
        options: ['1', '2', '3', '4', '5'],
        required: true,
        category: 'Decision Making',
        order: 5,
        createdBy: adminUserId,
      ),
    ];

    for (final question in defaultQuestions) {
      await addQuestion(question);
    }
  }
}

