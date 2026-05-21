import 'dart:convert';

import 'assessment_recommendations.dart';
import 'consent_basis.dart';
import 'risk_level.dart';

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
  final AssessmentRecommendations structuredRecommendations;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? status; // 'pending', 'reviewed', 'completed'
  final String? reviewedBy; // UUID of reviewer
  final DateTime? reviewedAt;
  final String? doctorNotes; // Doctor's review notes
  final int? templateId; // Assessment template ID
  final String? assessorUserId; // UUID of the doctor who created the assessment
  final bool isSynced; // Local sync status
  final RiskLevel riskLevel;
  final ConsentBasis? consentBasis;
  final String? consentNotes;
  final DateTime? consentRecordedAt;
  final String? consentRecordedBy;
  final String assessmentStatus; // 'active', 'refused', 'completed'

  bool get isRefused => assessmentStatus == 'refused';

  /// Generate anonymised ID for privacy-compliant reporting
  String get anonymisedId {
    final hash = (id ?? DateTime.now().millisecondsSinceEpoch)
        .toString()
        .hashCode
        .abs()
        .toRadixString(36)
        .toUpperCase()
        .padLeft(6, '0');
    return 'MCA-$hash';
  }

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
    AssessmentRecommendations? structuredRecommendations,
    required this.createdAt,
    required this.updatedAt,
    this.status,
    this.reviewedBy,
    this.reviewedAt,
    this.doctorNotes,
    this.templateId,
    this.assessorUserId,
    this.isSynced = false,
    this.riskLevel = RiskLevel.low,
    this.consentBasis,
    this.consentNotes,
    this.consentRecordedAt,
    this.consentRecordedBy,
    String? assessmentStatus,
  }) : structuredRecommendations =
           structuredRecommendations ??
           AssessmentRecommendations.fromStorage(null),
       assessmentStatus =
           assessmentStatus ??
           (status == 'completed' || status == 'refused' ? status! : 'active');

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'patient_id': patientId,
      'patient_name': patientName,
      'assessment_date': assessmentDate.toIso8601String(),
      'assessor_name': assessorName,
      'assessor_role': assessorRole,
      'decision_context': decisionContext,
      'responses': jsonEncode(responses),
      'overall_capacity': overallCapacity,
      'recommendations': recommendations,
      'recommendations_json': structuredRecommendations.toStorageJson(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'status': status ?? 'pending',
      'reviewed_by': reviewedBy,
      'reviewed_at': reviewedAt?.toIso8601String(),
      'doctor_notes': doctorNotes,
      'template_id': templateId,
      'assessor_user_id': assessorUserId,
      'is_synced': isSynced ? 1 : 0,
      'risk_level': riskLevel.name,
      'consent_basis': consentBasis?.name,
      'consent_notes': consentNotes,
      'consent_recorded_at': consentRecordedAt?.toIso8601String(),
      'consent_recorded_by': consentRecordedBy,
      'assessment_status': assessmentStatus,
    };
  }

  factory Assessment.fromMap(Map<String, dynamic> map) {
    final now = DateTime.now();

    return Assessment(
      id: map['id'],
      patientId: map['patient_id'] ?? '',
      patientName: map['patient_name'] ?? '',
      assessmentDate: _parseDate(map['assessment_date']) ?? now,
      assessorName: map['assessor_name'] ?? '',
      assessorRole: map['assessor_role'] ?? '',
      decisionContext: map['decision_context'] ?? '',
      responses: _parseResponses(map['responses']),
      overallCapacity: map['overall_capacity'] ?? '',
      recommendations: map['recommendations'] ?? '',
      structuredRecommendations: AssessmentRecommendations.fromStorage(
        map['recommendations_json'],
      ),
      createdAt: _parseDate(map['created_at']) ?? now,
      updatedAt: _parseDate(map['updated_at']) ?? now,
      status: map['status'] as String?,
      reviewedBy: map['reviewed_by'] as String?,
      reviewedAt: _parseDate(map['reviewed_at']),
      doctorNotes: map['doctor_notes'] as String?,
      templateId: map['template_id'] as int?,
      assessorUserId: map['assessor_user_id'] as String?,
      isSynced: map['is_synced'] == 1,
      riskLevel: riskLevelFromString(map['risk_level'] as String?),
      consentBasis: consentBasisFromString(map['consent_basis'] as String?),
      consentNotes: map['consent_notes'] as String?,
      consentRecordedAt: _parseDate(map['consent_recorded_at']),
      consentRecordedBy: map['consent_recorded_by'] as String?,
      assessmentStatus:
          map['assessment_status']?.toString() ??
          (map['status'] == 'completed' || map['status'] == 'refused'
              ? map['status'].toString()
              : 'active'),
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
    AssessmentRecommendations? structuredRecommendations,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? status,
    String? reviewedBy,
    DateTime? reviewedAt,
    String? doctorNotes,
    int? templateId,
    String? assessorUserId,
    bool? isSynced,
    RiskLevel? riskLevel,
    ConsentBasis? consentBasis,
    String? consentNotes,
    DateTime? consentRecordedAt,
    String? consentRecordedBy,
    String? assessmentStatus,
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
      structuredRecommendations:
          structuredRecommendations ?? this.structuredRecommendations,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      status: status ?? this.status,
      reviewedBy: reviewedBy ?? this.reviewedBy,
      reviewedAt: reviewedAt ?? this.reviewedAt,
      doctorNotes: doctorNotes ?? this.doctorNotes,
      templateId: templateId ?? this.templateId,
      assessorUserId: assessorUserId ?? this.assessorUserId,
      isSynced: isSynced ?? this.isSynced,
      riskLevel: riskLevel ?? this.riskLevel,
      consentBasis: consentBasis ?? this.consentBasis,
      consentNotes: consentNotes ?? this.consentNotes,
      consentRecordedAt: consentRecordedAt ?? this.consentRecordedAt,
      consentRecordedBy: consentRecordedBy ?? this.consentRecordedBy,
      assessmentStatus: assessmentStatus ?? this.assessmentStatus,
    );
  }

  static Map<String, dynamic> _parseResponses(dynamic responsesData) {
    if (responsesData is Map) {
      final responses = Map<String, dynamic>.from(responsesData);
      final raw = responses['raw'];
      if (responses.length == 1 && raw is String) {
        try {
          final decodedRaw = jsonDecode(raw);
          if (decodedRaw is Map) {
            return Map<String, dynamic>.from(decodedRaw);
          }
        } catch (_) {
          // Keep the original raw value below.
        }
      }
      return responses;
    } else if (responsesData is String) {
      try {
        final decoded = jsonDecode(responsesData);
        if (decoded is Map) {
          return Map<String, dynamic>.from(decoded);
        }
        return {'raw': decoded};
      } catch (e) {
        return {'raw': responsesData};
      }
    }
    return {'raw': responsesData.toString()};
  }

  static DateTime? _parseDate(dynamic value) {
    if (value is DateTime) return value;
    if (value is String && value.isNotEmpty) {
      return DateTime.tryParse(value);
    }
    return null;
  }
}
