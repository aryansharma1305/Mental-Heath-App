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
    };
  }

  factory Assessment.fromMap(Map<String, dynamic> map) {
    return Assessment(
      id: map['id'],
      patientId: map['patient_id'],
      patientName: map['patient_name'],
      assessmentDate: DateTime.parse(map['assessment_date']),
      assessorName: map['assessor_name'],
      assessorRole: map['assessor_role'],
      decisionContext: map['decision_context'],
      responses: _parseResponses(map['responses']),
      overallCapacity: map['overall_capacity'],
      recommendations: map['recommendations'],
      createdAt: DateTime.parse(map['created_at']),
      updatedAt: DateTime.parse(map['updated_at']),
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