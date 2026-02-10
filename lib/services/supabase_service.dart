import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user.dart' as app_models;
import '../models/user_role.dart';
import '../models/assessment.dart';
import '../models/question.dart';
import '../models/assessment_template.dart';

class SupabaseService {
  // Get Supabase client (following official pattern)
  static SupabaseClient? get client {
    try {
      if (Supabase.instance.isInitialized) {
        return Supabase.instance.client;
      }
      print('❌ SupabaseService: Supabase.instance is NOT initialized');
      return null;
    } catch (e) {
      print('❌ SupabaseService: Error getting client: $e');
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
    
    // Create insert map WITHOUT id field (PostgreSQL will auto-generate it via SERIAL)
    // Explicitly build the map without id to avoid any null issues
    final insertMap = <String, dynamic>{
      'question_text': question.text,
      'question_type': question.type.name,
      'options': question.options != null ? question.options!.join('|||') : null,
      'required': question.required,
      'category': question.category,
      'order_index': question.order,
      'is_active': question.isActive,
      'created_by': question.createdBy,
      'created_at': question.createdAt.toIso8601String(),
      'updated_at': question.updatedAt.toIso8601String(),
    };
    
    // Debug: Verify id is NOT in the map
    debugPrint('🔵 Inserting question - Map keys: ${insertMap.keys}');
    debugPrint('🔵 Inserting question - Has id key? ${insertMap.containsKey('id')}');
    
    final response = await client!
        .from('questions')
        .insert(insertMap)
        .select()
        .single();
    
    debugPrint('✅ Question inserted successfully with id: ${response['id']}');
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
  
  Future<int?> insertAssessment(Assessment assessment, {String? assessorUserId}) async {
    if (!isAvailable) {
      throw Exception('Supabase is not available');
    }
    try {
      final response = await client!
        .from('assessments')
        .insert({
          'patient_id': assessment.patientId,
          'patient_name': assessment.patientName,
          // 'patient_user_id': assessment.patientId, // Removed: patientId is TEXT, patient_user_id requires UUID
          'assessment_date': assessment.assessmentDate.toIso8601String(),
          'assessor_name': assessment.assessorName,
          'assessor_role': assessment.assessorRole,
          'assessor_user_id': assessorUserId ?? assessment.assessorUserId, // Use actual user ID
          'decision_context': assessment.decisionContext,
          'responses': assessment.responses,
          'overall_capacity': assessment.overallCapacity,
          'recommendations': assessment.recommendations,
          'status': 'pending',
        })
        .select()
        .single();
    
    return response['id'] as int;
    } catch (e) {
      return null;
    }
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
          'status': assessment.status ?? 'pending',
          'reviewed_by': assessment.reviewedBy,
          'reviewed_at': assessment.reviewedAt?.toIso8601String(),
          'doctor_notes': assessment.doctorNotes,
          'template_id': assessment.templateId,
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('id', assessment.id!);
  }

  // ========== DOCTOR REVIEW OPERATIONS ==========
  
  Future<void> reviewAssessment({
    required int assessmentId,
    required String reviewerId,
    required String status, // 'reviewed' or 'completed'
    String? doctorNotes,
  }) async {
    if (!isAvailable) return;
    
    await client!
        .from('assessments')
        .update({
          'status': status,
          'reviewed_by': reviewerId,
          'reviewed_at': DateTime.now().toIso8601String(),
          'doctor_notes': doctorNotes,
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('id', assessmentId);
  }

  Future<void> addDoctorNotes({
    required int assessmentId,
    required String reviewerId,
    required String notes,
  }) async {
    if (!isAvailable) return;
    
    await client!
        .from('assessments')
        .update({
          'doctor_notes': notes,
          'reviewed_by': reviewerId,
          'reviewed_at': DateTime.now().toIso8601String(),
          'status': 'reviewed',
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('id', assessmentId);
  }

  Future<List<Assessment>> getAssessmentsByStatus(String status) async {
    if (!isAvailable) return [];
    try {
      final response = await client!
          .from('assessments')
          .select()
          .eq('status', status)
          .order('assessment_date', ascending: false);
      
      return (response as List)
          .map((item) => Assessment.fromMap(item))
          .toList();
    } catch (e) {
      debugPrint('Error getting assessments by status: $e');
      return [];
    }
  }

  Future<List<Assessment>> getAssessmentsForReview() async {
    if (!isAvailable) return [];
    try {
      final response = await client!
          .from('assessments')
          .select()
          .inFilter('status', ['pending', 'reviewed'])
          .order('assessment_date', ascending: false);
      
      return (response as List)
          .map((item) => Assessment.fromMap(item))
          .toList();
    } catch (e) {
      debugPrint('Error getting assessments for review: $e');
      return [];
    }
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

  Future<List<Assessment>> getAssessmentsByAssessorId(String assessorUserId) async {
    if (!isAvailable) return [];
    try {
      final response = await client!
          .from('assessments')
          .select()
          .eq('assessor_user_id', assessorUserId)
          .order('assessment_date', ascending: false);
      
      return (response as List)
          .map((item) => Assessment.fromMap(item))
          .toList();
    } catch (e) {
      debugPrint('Error getting assessments by assessor ID: $e');
      return [];
    }
  }

  Future<List<Assessment>> getUnassignedAssessments() async {
    if (!isAvailable) return [];
    try {
      final response = await client!
          .from('assessments')
          .select()
          .or('assessor_user_id.is.null,assessor_user_id.eq.')
          .order('assessment_date', ascending: false);
      
      return (response as List)
          .map((item) => Assessment.fromMap(item))
          .toList();
    } catch (e) {
      debugPrint('Error getting unassigned assessments: $e');
      return [];
    }
  }

  // ========== ASSESSMENT TEMPLATES ==========
  
  Future<List<AssessmentTemplate>> getAllTemplates() async {
    if (!isAvailable) return [];
    try {
      final response = await client!
          .from('assessment_templates')
          .select()
          .eq('is_active', true)
          .order('created_at', ascending: false);
      
      return (response as List)
          .map((item) => AssessmentTemplate.fromMap(item))
          .toList();
    } catch (e) {
      debugPrint('Error getting templates: $e');
      return [];
    }
  }
  
  Future<AssessmentTemplate?> getTemplateWithQuestions(int templateId) async {
    if (!isAvailable) return null;
    try {
      // Get template
      final templateResponse = await client!
          .from('assessment_templates')
          .select()
          .eq('id', templateId)
          .single();
      
      final template = AssessmentTemplate.fromMap(templateResponse);
      
      // Get questions for this template
      final questionsResponse = await client!
          .from('assessment_template_questions')
          .select('''
            question_id,
            order_index,
            questions (*)
          ''')
          .eq('template_id', templateId)
          .order('order_index', ascending: true);
      
      final questions = <Question>[];
      for (var item in questionsResponse) {
        if (item['questions'] != null) {
          questions.add(Question.fromMap(item['questions']));
        }
      }
      
      return template.copyWith(questions: questions);
    } catch (e) {
      debugPrint('Error getting template with questions: $e');
      return null;
    }
  }
  
  Future<int> createTemplate(AssessmentTemplate template) async {
    if (!isAvailable) {
      throw Exception('Supabase is not available');
    }
    
    final insertMap = <String, dynamic>{
      'name': template.name,
      'description': template.description,
      'is_active': template.isActive,
      'created_by': template.createdBy,
    };
    
    final response = await client!
        .from('assessment_templates')
        .insert(insertMap)
        .select()
        .single();
    
    return response['id'] as int;
  }
  
  Future<void> updateTemplate(AssessmentTemplate template) async {
    if (!isAvailable || template.id == null) return;
    
    final updateMap = <String, dynamic>{
      'name': template.name,
      'description': template.description,
      'is_active': template.isActive,
      'updated_at': DateTime.now().toIso8601String(),
    };
    
    await client!
        .from('assessment_templates')
        .update(updateMap)
        .eq('id', template.id!);
  }
  
  Future<void> deleteTemplate(int templateId) async {
    if (!isAvailable) return;
    await client!
        .from('assessment_templates')
        .update({'is_active': false})
        .eq('id', templateId);
  }
  
  Future<void> addQuestionToTemplate(int templateId, int questionId, int orderIndex) async {
    if (!isAvailable) return;
    
    await client!
        .from('assessment_template_questions')
        .insert({
          'template_id': templateId,
          'question_id': questionId,
          'order_index': orderIndex,
        });
  }
  
  Future<void> removeQuestionFromTemplate(int templateId, int questionId) async {
    if (!isAvailable) return;
    
    await client!
        .from('assessment_template_questions')
        .delete()
        .eq('template_id', templateId)
        .eq('question_id', questionId);
  }
  
  Future<void> updateTemplateQuestionOrder(int templateId, List<int> questionIds) async {
    if (!isAvailable) return;
    
    // Delete all existing links
    await client!
        .from('assessment_template_questions')
        .delete()
        .eq('template_id', templateId);
    
    // Re-insert with new order
    for (int i = 0; i < questionIds.length; i++) {
      await client!
          .from('assessment_template_questions')
          .insert({
            'template_id': templateId,
            'question_id': questionIds[i],
            'order_index': i,
          });
    }
  }
  
  // ========== QUESTION RESPONSES ==========
  
  Future<void> saveQuestionResponse({
    required int templateId,
    required int questionId,
    required String patientUserId,
    required String answer,
    int? assessmentId,
  }) async {
    if (!isAvailable) return;
    
    final insertMap = <String, dynamic>{
      'template_id': templateId,
      'question_id': questionId,
      'patient_user_id': patientUserId,
      'answer': answer,
    };
    
    if (assessmentId != null) {
      insertMap['assessment_id'] = assessmentId;
    }
    
    await client!
        .from('question_responses')
        .insert(insertMap);
  }
  
  Future<List<Map<String, dynamic>>> getQuestionResponses({
    int? templateId,
    String? patientUserId,
    int? assessmentId,
  }) async {
    if (!isAvailable) return [];
    
    try {
      var query = client!.from('question_responses').select('''
        *,
        questions (*),
        assessment_templates (name, description)
      ''');
      
      if (templateId != null) {
        query = query.eq('template_id', templateId);
      }
      if (patientUserId != null) {
        query = query.eq('patient_user_id', patientUserId);
      }
      if (assessmentId != null) {
        query = query.eq('assessment_id', assessmentId);
      }
      
      final response = await query.order('created_at', ascending: false);
      return (response as List).cast<Map<String, dynamic>>();
    } catch (e) {
      debugPrint('Error getting question responses: $e');
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

