import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../models/user.dart' as app_models;
import '../models/user_role.dart';
import '../models/assessment.dart';
import '../models/question.dart';
import '../models/patient_profile.dart';

class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  final String _baseUrl = 'https://mental-capacity-api-gugloo.fly.dev';

  // Helper for HTTP requests
  Future<dynamic> _get(String path, {Map<String, String>? queryParams}) async {
    try {
      var uri = Uri.parse('$_baseUrl$path');
      if (queryParams != null) {
        uri = uri.replace(queryParameters: queryParams);
      }
      final response = await http.get(uri);
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return jsonDecode(response.body);
      }
      return null;
    } catch (e) {
      debugPrint('ApiService GET error on $path: $e');
      return null;
    }
  }

  Future<dynamic> _post(String path, Map<String, dynamic> body) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl$path'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      );
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return jsonDecode(response.body);
      }
      return null;
    } catch (e) {
      debugPrint('ApiService POST error on $path: $e');
      return null;
    }
  }

  Future<dynamic> _put(String path, Map<String, dynamic> body) async {
    try {
      final response = await http.put(
        Uri.parse('$_baseUrl$path'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      );
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return jsonDecode(response.body);
      }
      return null;
    } catch (e) {
      debugPrint('ApiService PUT error on $path: $e');
      return null;
    }
  }

  Future<bool> _delete(String path) async {
    try {
      final response = await http.delete(Uri.parse('$_baseUrl$path'));
      return response.statusCode >= 200 && response.statusCode < 300;
    } catch (e) {
      debugPrint('ApiService DELETE error on $path: $e');
      return false;
    }
  }

  // ========== USER OPERATIONS ==========

  Future<app_models.User?> getUserById(String id) async {
    final data = await _get('/api/users/$id');
    if (data == null) return null;
    return app_models.User.fromMap(data);
  }

  Future<app_models.User?> getUserByUsername(String username) async {
    final data = await _get('/api/users', queryParams: {'username': username});
    if (data == null || (data is List && data.isEmpty)) return null;
    if (data is List) return app_models.User.fromMap(data.first);
    return app_models.User.fromMap(data);
  }

  Future<app_models.User> createUser({
    required String username,
    required String email,
    required String fullName,
    required UserRole role,
    String? department,
    String? passwordHash,
  }) async {
    final data = await _post('/api/users', {
      'username': username,
      'email': email,
      'full_name': fullName,
      'role': role.name,
      'department': department,
      'password_hash': passwordHash,
    });
    if (data == null) throw Exception('Failed to create user on API');
    return app_models.User.fromMap(data);
  }

  Future<void> updateUser(app_models.User user) async {
    await _put('/api/users/${user.id}', user.toMap());
  }

  // ========== QUESTION OPERATIONS ==========

  Future<List<Question>> getActiveQuestions() async {
    final data = await _get('/api/questions', queryParams: {'active': 'true'});
    if (data == null) return [];
    return (data as List).map((e) => Question.fromMap(e)).toList();
  }

  Future<List<Question>> getAllQuestions() async {
    final data = await _get('/api/questions');
    if (data == null) return [];
    return (data as List).map((e) => Question.fromMap(e)).toList();
  }

  Future<int?> addQuestion(Question question) async {
    final map = question.toMap();
    map.remove('id');
    final data = await _post('/api/questions', map);
    return data?['id'] as int?;
  }

  Future<void> updateQuestion(Question question) async {
    if (question.id == null) return;
    await _put('/api/questions/${question.id}', question.toMap());
  }

  Future<void> deleteQuestion(int id) async {
    await _delete('/api/questions/$id');
  }

  Future<void> saveQuestionResponse({
    required int templateId,
    required int questionId,
    required String patientUserId,
    required String answer,
  }) async {
    await _post('/api/question_responses', {
      'template_id': templateId,
      'question_id': questionId,
      'patient_user_id': patientUserId,
      'answer': answer,
    });
  }

  // ========== ASSESSMENT OPERATIONS ==========

  Future<int?> insertAssessment(Assessment assessment, {String? assessorUserId}) async {
    final map = {
      'patient_id': assessment.patientId,
      'patient_name': assessment.patientName,
      'assessment_date': assessment.assessmentDate.toIso8601String(),
      'assessor_name': assessment.assessorName,
      'assessor_role': assessment.assessorRole,
      'assessor_user_id': assessorUserId ?? assessment.assessorUserId,
      'decision_context': assessment.decisionContext,
      'responses': assessment.responses,
      'overall_capacity': assessment.overallCapacity,
      'recommendations': assessment.recommendations,
      'recommendations_json': assessment.structuredRecommendations.toJson(),
      'risk_level': assessment.riskLevel.name,
      'consent_basis': assessment.consentBasis?.name,
      'consent_notes': assessment.consentNotes,
      'consent_recorded_at': assessment.consentRecordedAt?.toIso8601String(),
      'consent_recorded_by': assessment.consentRecordedBy,
      'assessment_status': assessment.assessmentStatus,
      'prior_assessment_id': assessment.priorAssessmentId,
      'status': assessment.status ?? 'pending',
    };
    
    final data = await _post('/api/assessments', map);
    return data?['id'] as int?;
  }

  Future<List<Assessment>> getAllAssessments() async {
    final data = await _get('/api/assessments');
    if (data == null) return [];
    return (data as List).map((e) => Assessment.fromMap(e)).toList();
  }

  Future<void> updateAssessment(Assessment assessment) async {
    if (assessment.id == null) return;
    final map = {
      'patient_id': assessment.patientId,
      'patient_name': assessment.patientName,
      'assessment_date': assessment.assessmentDate.toIso8601String(),
      'assessor_name': assessment.assessorName,
      'assessor_role': assessment.assessorRole,
      'decision_context': assessment.decisionContext,
      'responses': assessment.responses,
      'overall_capacity': assessment.overallCapacity,
      'recommendations': assessment.recommendations,
      'recommendations_json': assessment.structuredRecommendations.toJson(),
      'risk_level': assessment.riskLevel.name,
      'consent_basis': assessment.consentBasis?.name,
      'consent_notes': assessment.consentNotes,
      'consent_recorded_at': assessment.consentRecordedAt?.toIso8601String(),
      'consent_recorded_by': assessment.consentRecordedBy,
      'assessment_status': assessment.assessmentStatus,
      'prior_assessment_id': assessment.priorAssessmentId,
      'status': assessment.status ?? 'pending',
      'reviewed_by': assessment.reviewedBy,
      'reviewed_at': assessment.reviewedAt?.toIso8601String(),
      'doctor_notes': assessment.doctorNotes,
      'template_id': assessment.templateId,
      'updated_at': DateTime.now().toIso8601String(),
    };
    await _put('/api/assessments/${assessment.id}', map);
  }

  Future<void> reviewAssessment({
    required int assessmentId,
    required String reviewerId,
    required String status,
    String? doctorNotes,
  }) async {
    await _put('/api/assessments/$assessmentId', {
      'status': status,
      'reviewed_by': reviewerId,
      'reviewed_at': DateTime.now().toIso8601String(),
      'doctor_notes': doctorNotes,
      'updated_at': DateTime.now().toIso8601String(),
    });
  }

  Future<void> addDoctorNotes({
    required int assessmentId,
    required String reviewerId,
    required String notes,
  }) async {
    await _put('/api/assessments/$assessmentId', {
      'doctor_notes': notes,
      'reviewed_by': reviewerId,
      'reviewed_at': DateTime.now().toIso8601String(),
      'status': 'reviewed',
      'updated_at': DateTime.now().toIso8601String(),
    });
  }

  Future<List<Assessment>> getAssessmentsByStatus(String status) async {
    final data = await _get('/api/assessments', queryParams: {'status': status});
    if (data == null) return [];
    return (data as List).map((e) => Assessment.fromMap(e)).toList();
  }

  Future<List<Assessment>> getAssessmentsForReview() async {
    final data = await _get('/api/assessments', queryParams: {'review': 'true'});
    if (data == null) return [];
    return (data as List).map((e) => Assessment.fromMap(e)).toList();
  }

  Future<List<Assessment>> getPendingAssessments() async {
    return getAssessmentsByStatus('pending');
  }

  Future<List<Assessment>> getAssessmentsByPatientId(String patientUserId) async {
    final data = await _get('/api/assessments', queryParams: {'patient_user_id': patientUserId});
    if (data == null) return [];
    return (data as List).map((e) => Assessment.fromMap(e)).toList();
  }

  Future<List<Assessment>> getAssessmentsByAssessorId(String assessorUserId) async {
    final data = await _get('/api/assessments', queryParams: {'assessor_user_id': assessorUserId});
    if (data == null) return [];
    return (data as List).map((e) => Assessment.fromMap(e)).toList();
  }

  Future<List<Assessment>> getUnassignedAssessments() async {
    final data = await _get('/api/assessments', queryParams: {'unassigned': 'true'});
    if (data == null) return [];
    return (data as List).map((e) => Assessment.fromMap(e)).toList();
  }

  // ========== TEMPLATES ==========

  Future<List<Map<String, dynamic>>> getAllTemplates() async {
    final data = await _get('/api/templates');
    if (data == null) return [];
    return (data as List).cast<Map<String, dynamic>>();
  }

  Future<Map<String, dynamic>?> getTemplateWithQuestions(int templateId) async {
    final data = await _get('/api/templates/$templateId');
    if (data == null) return null;
    
    // Parse the inner questions list to Question objects
    final parsed = Map<String, dynamic>.from(data);
    if (parsed['questions'] != null) {
      final List qs = parsed['questions'];
      parsed['questions'] = qs.map((q) => Question.fromMap(q)).toList();
    }
    return parsed;
  }

  Future<int?> createTemplate(String name, String? description) async {
    final data = await _post('/api/templates', {
      'name': name,
      'description': description,
      'is_active': true,
    });
    return data?['id'] as int?;
  }

  Future<void> updateTemplate(int templateId, String name, String? description) async {
    await _put('/api/templates/$templateId', {
      'name': name,
      'description': description,
      'updated_at': DateTime.now().toIso8601String(),
    });
  }

  Future<void> deleteTemplate(int templateId) async {
    await _delete('/api/templates/$templateId');
  }

  Future<void> addQuestionToTemplate(int templateId, int questionId, int orderIndex) async {
    await _post('/api/templates/$templateId/questions', {
      'question_id': questionId,
      'order_index': orderIndex,
    });
  }

  Future<void> removeQuestionFromTemplate(int templateId, int questionId) async {
    await _delete('/api/templates/$templateId/questions/$questionId');
  }

  Future<void> updateTemplateQuestionOrder(int templateId, List<int> questionIds) async {
    await _put('/api/templates/$templateId/questions/order', {
      'question_ids': questionIds,
    });
  }

  // ========== PATIENTS ==========

  Future<void> upsertPatient(PatientProfile patient) async {
    await _post('/api/patients', patient.toMap());
  }

  // NOTE: Real-time subscriptions are not currently supported by the REST API backend.
  // We recommend using a polling approach or relying on manual pull-to-refresh
  // if real-time syncing is strictly necessary in a specific screen.
}
