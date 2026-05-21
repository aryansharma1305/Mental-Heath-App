class ClinicalNote {
  final int? id;
  final String patientId;
  final int? assessmentId;
  final String note;
  final String authorName;
  final String? authorUserId;
  final DateTime createdAt;
  final DateTime updatedAt;

  const ClinicalNote({
    this.id,
    required this.patientId,
    this.assessmentId,
    required this.note,
    required this.authorName,
    this.authorUserId,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'patient_id': patientId,
      'assessment_id': assessmentId,
      'note': note,
      'author_name': authorName,
      'author_user_id': authorUserId,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory ClinicalNote.fromMap(Map<String, dynamic> map) {
    final now = DateTime.now();
    return ClinicalNote(
      id: map['id'] as int?,
      patientId: (map['patient_id'] ?? '').toString(),
      assessmentId: map['assessment_id'] as int?,
      note: (map['note'] ?? '').toString(),
      authorName: (map['author_name'] ?? 'Unknown').toString(),
      authorUserId: map['author_user_id'] as String?,
      createdAt: _parseDate(map['created_at']) ?? now,
      updatedAt: _parseDate(map['updated_at']) ?? now,
    );
  }

  static DateTime? _parseDate(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    return DateTime.tryParse(value.toString());
  }
}
