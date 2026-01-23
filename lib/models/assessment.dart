class Assessment {
  final int? id;
  final String patientId;
  final String patientName;
  final DateTime assessmentDate;
  final String assessorName;
  final String assessorRole;
  final String decisionContext;
  final Map<String, dynamic> responses;
  final String overallCapacity;
  final String recommendations;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? status; // 'pending', 'reviewed', 'completed'
  final String? reviewedBy; // UUID of reviewer
  final DateTime? reviewedAt;
  final String? doctorNotes; // Doctor's review notes
  final int? templateId; // Assessment template ID
  final String? assessorUserId; // UUID of the doctor who created the assessment

  Assessment({
    this.id,
    required this.patientId,
    required this.patientName,
    required this.assessmentDate,
    required this.assessorName,
    required this.assessorRole,
    required this.decisionContext,
    required this.responses,
    required this.overallCapacity,
    required this.recommendations,
    required this.createdAt,
    required this.updatedAt,
    this.status,
    this.reviewedBy,
    this.reviewedAt,
    this.doctorNotes,
    this.templateId,
    this.assessorUserId,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'patient_id': patientId,
      'patient_name': patientName,
      'assessment_date': assessmentDate.toIso8601String(),
      'assessor_name': assessorName,
      'assessor_role': assessorRole,
      'decision_context': decisionContext,
      'responses': responses, // JSONB in Supabase
      'overall_capacity': overallCapacity,
      'recommendations': recommendations,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'status': status ?? 'pending',
      'reviewed_by': reviewedBy,
      'reviewed_at': reviewedAt?.toIso8601String(),
      'doctor_notes': doctorNotes,
      'template_id': templateId,
      'assessor_user_id': assessorUserId,
    };
  }

  factory Assessment.fromMap(Map<String, dynamic> map) {
    return Assessment(
      id: map['id'],
      patientId: map['patient_id'] ?? '',
      patientName: map['patient_name'] ?? '',
      assessmentDate: DateTime.parse(map['assessment_date']),
      assessorName: map['assessor_name'] ?? '',
      assessorRole: map['assessor_role'] ?? '',
      decisionContext: map['decision_context'] ?? '',
      responses: _parseResponses(map['responses']),
      overallCapacity: map['overall_capacity'] ?? '',
      recommendations: map['recommendations'] ?? '',
      createdAt: DateTime.parse(map['created_at']),
      updatedAt: DateTime.parse(map['updated_at']),
      status: map['status'] as String?,
      reviewedBy: map['reviewed_by'] as String?,
      reviewedAt: map['reviewed_at'] != null ? DateTime.parse(map['reviewed_at']) : null,
      doctorNotes: map['doctor_notes'] as String?,
      templateId: map['template_id'] as int?,
      assessorUserId: map['assessor_user_id'] as String?,
    );
  }

  Assessment copyWith({
    int? id,
    String? patientId,
    String? patientName,
    DateTime? assessmentDate,
    String? assessorName,
    String? assessorRole,
    String? decisionContext,
    Map<String, dynamic>? responses,
    String? overallCapacity,
    String? recommendations,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? status,
    String? reviewedBy,
    DateTime? reviewedAt,
    String? doctorNotes,
    int? templateId,
    String? assessorUserId,
  }) {
    return Assessment(
      id: id ?? this.id,
      patientId: patientId ?? this.patientId,
      patientName: patientName ?? this.patientName,
      assessmentDate: assessmentDate ?? this.assessmentDate,
      assessorName: assessorName ?? this.assessorName,
      assessorRole: assessorRole ?? this.assessorRole,
      decisionContext: decisionContext ?? this.decisionContext,
      responses: responses ?? this.responses,
      overallCapacity: overallCapacity ?? this.overallCapacity,
      recommendations: recommendations ?? this.recommendations,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      status: status ?? this.status,
      reviewedBy: reviewedBy ?? this.reviewedBy,
      reviewedAt: reviewedAt ?? this.reviewedAt,
      doctorNotes: doctorNotes ?? this.doctorNotes,
      templateId: templateId ?? this.templateId,
      assessorUserId: assessorUserId ?? this.assessorUserId,
    );
  }

  static Map<String, dynamic> _parseResponses(dynamic responsesData) {
    if (responsesData is Map) {
      return Map<String, dynamic>.from(responsesData);
    } else if (responsesData is String) {
      try {
        // Try to parse as JSON string
        return {'raw': responsesData};
      } catch (e) {
        return {'raw': responsesData};
      }
    }
    return {'raw': responsesData.toString()};
  }
}