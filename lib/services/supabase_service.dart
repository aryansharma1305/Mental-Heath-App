import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user.dart' as app_models;
import '../models/user_role.dart';
import '../models/assessment.dart';
import '../models/question.dart';

class SupabaseService {
  // Get Supabase client (following official pattern)
  static SupabaseClient? get client {
    try {
      if (Supabase.instance.isInitialized) {
        return Supabase.instance.client;
      }
      return null;
    } catch (e) {
      return null;
    }
  }
  
  // Check if Supabase is available
  static bool get isAvailable {
    try {
      return Supabase.instance.isInitialized && client != null;
    } catch (e) {
      return false;
    }
  }

  // ========== USER OPERATIONS ==========
  
  Future<app_models.User?> getUserById(String id) async {
    if (!isAvailable) return null;
    try {
      final response = await client!
          .from('users')
          .select()
          .eq('id', id)
          .single();
      
      return app_models.User.fromMap(response);
    } catch (e) {
      return null;
    }
  }

  Future<app_models.User?> getUserByUsername(String username) async {
    if (!isAvailable) return null;
    try {
      final response = await client!
          .from('users')
          .select()
          .eq('username', username)
          .single();
      
      return app_models.User.fromMap(response as Map<String, dynamic>);
    } catch (e) {
      return null;
    }
  }

  Future<app_models.User> createUser({
    required String username,
    required String email,
    required String fullName,
    required UserRole role,
    String? department,
    String? passwordHash,
  }) async {
    if (!isAvailable) {
      throw Exception('Supabase is not available');
    }
    
    final response = await client!
        .from('users')
        .insert({
          'username': username,
          'email': email,
          'full_name': fullName,
          'role': role.name,
          'department': department,
          'password_hash': passwordHash,
        })
        .select()
        .single();
    
    return app_models.User.fromMap(response as Map<String, dynamic>);
  }

  Future<void> updateUser(app_models.User user) async {
    if (!isAvailable) return;
    await client!
        .from('users')
        .update(user.toMap())
        .eq('id', user.id);
  }

  // ========== QUESTION OPERATIONS ==========
  
  Future<List<Question>> getActiveQuestions() async {
    if (!isAvailable) return [];
    try {
      final response = await client!
          .from('questions')
          .select()
          .eq('is_active', true)
          .order('order_index', ascending: true);
      
      return (response as List)
          .map((item) => Question.fromMap(item))
          .toList();
    } catch (e) {
      return [];
    }
  }

  Future<List<Question>> getAllQuestions() async {
    if (!isAvailable) return [];
    try {
      final response = await client!
          .from('questions')
          .select()
          .order('order_index', ascending: true);
      
      return (response as List)
          .map((item) => Question.fromMap(item))
          .toList();
    } catch (e) {
      return [];
    }
  }

  Future<int> addQuestion(Question question) async {
    if (!isAvailable) {
      throw Exception('Supabase is not available');
    }
    final response = await client!
        .from('questions')
        .insert(question.toMap())
        .select()
        .single();
    
    return response['id'] as int;
  }

  Future<void> updateQuestion(Question question) async {
    if (!isAvailable || question.id == null) return;
    await client!
        .from('questions')
        .update(question.toMap())
        .eq('id', question.id!);
  }

  Future<void> deleteQuestion(int id) async {
    if (!isAvailable) return;
    await client!
        .from('questions')
        .update({'is_active': false})
        .eq('id', id);
  }

  // ========== ASSESSMENT OPERATIONS ==========
  
  Future<int> insertAssessment(Assessment assessment) async {
    if (!isAvailable) {
      throw Exception('Supabase is not available');
    }
    final response = await client!
        .from('assessments')
        .insert({
          'patient_id': assessment.patientId,
          'patient_name': assessment.patientName,
          'patient_user_id': assessment.patientId,
          'assessment_date': assessment.assessmentDate.toIso8601String(),
          'assessor_name': assessment.assessorName,
          'assessor_role': assessment.assessorRole,
          'assessor_user_id': assessment.assessorName, // Update with actual user ID
          'decision_context': assessment.decisionContext,
          'responses': assessment.responses,
          'overall_capacity': assessment.overallCapacity,
          'recommendations': assessment.recommendations,
          'status': 'pending',
        })
        .select()
        .single();
    
    return response['id'] as int;
  }

  Future<List<Assessment>> getAllAssessments() async {
    if (!isAvailable) return [];
    try {
      final response = await client!
          .from('assessments')
          .select()
          .order('assessment_date', ascending: false);
      
      return (response as List)
          .map((item) => Assessment.fromMap(item))
          .toList();
    } catch (e) {
      return [];
    }
  }

  Future<Assessment?> getAssessment(int id) async {
    if (!isAvailable) return null;
    try {
      final response = await client!
          .from('assessments')
          .select()
          .eq('id', id)
          .single();
      
      return Assessment.fromMap(response);
    } catch (e) {
      return null;
    }
  }

  Future<void> updateAssessment(Assessment assessment) async {
    if (!isAvailable) return;
    await client!
        .from('assessments')
        .update({
          'patient_id': assessment.patientId,
          'patient_name': assessment.patientName,
          'assessment_date': assessment.assessmentDate.toIso8601String(),
          'assessor_name': assessment.assessorName,
          'assessor_role': assessment.assessorRole,
          'decision_context': assessment.decisionContext,
          'responses': assessment.responses,
          'overall_capacity': assessment.overallCapacity,
          'recommendations': assessment.recommendations,
          'status': 'reviewed',
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('id', assessment.id!);
  }

  Future<List<Assessment>> getPendingAssessments() async {
    if (!isAvailable) return [];
    try {
      final response = await client!
          .from('assessments')
          .select()
          .eq('status', 'pending')
          .order('assessment_date', ascending: false);
      
      return (response as List)
          .map((item) => Assessment.fromMap(item))
          .toList();
    } catch (e) {
      return [];
    }
  }

  Future<List<Assessment>> getAssessmentsByPatientId(String patientUserId) async {
    if (!isAvailable) return [];
    try {
      final response = await client!
          .from('assessments')
          .select()
          .eq('patient_user_id', patientUserId)
          .order('assessment_date', ascending: false);
      
      return (response as List)
          .map((item) => Assessment.fromMap(item))
          .toList();
    } catch (e) {
      return [];
    }
  }

  // ========== REAL-TIME SUBSCRIPTIONS ==========
  
  RealtimeChannel? subscribeToAssessments(Function(Map<String, dynamic>) callback) {
    if (!isAvailable) return null;
    return client!
        .channel('assessments')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'assessments',
          callback: (payload) => callback(payload.newRecord),
        )
        .subscribe();
  }
}

