class PatientProfile {
  final String patientId;
  final String displayName;
  final String? demographicsJson;
  final String? clinicalSummary;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? lastAssessmentAt;
  final int assessmentCount;

  const PatientProfile({
    required this.patientId,
    required this.displayName,
    this.demographicsJson,
    this.clinicalSummary,
    required this.createdAt,
    required this.updatedAt,
    this.lastAssessmentAt,
    this.assessmentCount = 0,
  });

  Map<String, dynamic> toMap() {
    return {
      'patient_id': patientId,
      'display_name': displayName,
      'demographics_json': demographicsJson,
      'clinical_summary': clinicalSummary,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'last_assessment_at': lastAssessmentAt?.toIso8601String(),
      'assessment_count': assessmentCount,
    };
  }

  factory PatientProfile.fromMap(Map<String, dynamic> map) {
    final now = DateTime.now();
    return PatientProfile(
      patientId: (map['patient_id'] ?? '').toString(),
      displayName: (map['display_name'] ?? map['patient_id'] ?? 'Unknown')
          .toString(),
      demographicsJson: map['demographics_json'] as String?,
      clinicalSummary: map['clinical_summary'] as String?,
      createdAt: _parseDate(map['created_at']) ?? now,
      updatedAt: _parseDate(map['updated_at']) ?? now,
      lastAssessmentAt: _parseDate(map['last_assessment_at']),
      assessmentCount:
          int.tryParse((map['assessment_count'] ?? 0).toString()) ?? 0,
    );
  }

  PatientProfile copyWith({
    String? patientId,
    String? displayName,
    String? demographicsJson,
    String? clinicalSummary,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? lastAssessmentAt,
    int? assessmentCount,
  }) {
    return PatientProfile(
      patientId: patientId ?? this.patientId,
      displayName: displayName ?? this.displayName,
      demographicsJson: demographicsJson ?? this.demographicsJson,
      clinicalSummary: clinicalSummary ?? this.clinicalSummary,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      lastAssessmentAt: lastAssessmentAt ?? this.lastAssessmentAt,
      assessmentCount: assessmentCount ?? this.assessmentCount,
    );
  }

  static DateTime? _parseDate(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    return DateTime.tryParse(value.toString());
  }
}
