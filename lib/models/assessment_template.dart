import 'dart:convert';

import 'assessment.dart';
import 'consent_basis.dart';

/// A workflow preset that pre-fills non-clinical context fields when starting
/// a new assessment.  Templates never store patient identity, clinical scores,
/// risk levels, or contemporaneous consent notes.
class AssessmentTemplate {
  /// UUID v4 — stable across edits so notifications and usage tracking survive
  /// template renames.
  final String id;

  final String name;
  final String? description;

  /// Matches the assessment type string used in the app.
  /// 'MHCA' | 'DSM5' | 'Capacity'
  final String assessmentType;

  /// Pre-fills the "recorded by / doctor name" field.
  final String? defaultClinician;

  /// Suggests a consent basis — clinician can still override at the gate.
  final String? defaultConsentBasis; // ConsentBasis.name or null

  /// Starter text injected into the clinical context / purpose note.
  final String? contextualNote;

  /// Default value for the follow-up recommended checkbox.
  final bool followUpRecommendedDefault;

  /// Extensible key-value store for future fields without a schema migration.
  /// Currently used for: {'defaultPurpose': 'Treatment'}.
  final Map<String, dynamic> metadata;

  final DateTime createdAt;
  final DateTime? lastUsedAt;

  /// Incremented each time a clinician starts an assessment with this template.
  /// Used as the primary sort key so the most useful templates surface first.
  final int useCount;

  AssessmentTemplate({
    required this.id,
    required this.name,
    this.description,
    required this.assessmentType,
    this.defaultClinician,
    this.defaultConsentBasis,
    this.contextualNote,
    this.followUpRecommendedDefault = false,
    Map<String, dynamic>? metadata,
    DateTime? createdAt,
    this.lastUsedAt,
    this.useCount = 0,
  })  : metadata = metadata ?? const {},
        createdAt = createdAt ?? DateTime.now();

  // ── Serialisation ────────────────────────────────────────────────────────

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'assessment_type': assessmentType,
      'default_clinician': defaultClinician,
      'default_consent_basis': defaultConsentBasis,
      'contextual_note': contextualNote,
      'follow_up_recommended_default': followUpRecommendedDefault ? 1 : 0,
      'metadata': metadata.isEmpty ? null : jsonEncode(metadata),
      'created_at': createdAt.toIso8601String(),
      'last_used_at': lastUsedAt?.toIso8601String(),
      'use_count': useCount,
    };
  }

  factory AssessmentTemplate.fromMap(Map<String, dynamic> map) {
    Map<String, dynamic> meta = {};
    if (map['metadata'] != null) {
      try {
        meta = jsonDecode(map['metadata'] as String) as Map<String, dynamic>;
      } catch (_) {
        // Corrupt metadata — silently ignore, don't crash the app.
      }
    }
    return AssessmentTemplate(
      id: map['id'] as String,
      name: map['name'] as String? ?? '',
      description: map['description'] as String?,
      assessmentType: map['assessment_type'] as String? ?? 'MHCA',
      defaultClinician: map['default_clinician'] as String?,
      defaultConsentBasis: map['default_consent_basis'] as String?,
      contextualNote: map['contextual_note'] as String?,
      followUpRecommendedDefault:
          (map['follow_up_recommended_default'] as int? ?? 0) == 1,
      metadata: meta,
      createdAt: map['created_at'] != null
          ? DateTime.parse(map['created_at'] as String)
          : DateTime.now(),
      lastUsedAt: map['last_used_at'] != null
          ? DateTime.parse(map['last_used_at'] as String)
          : null,
      useCount: map['use_count'] as int? ?? 0,
    );
  }

  // ── Convenience accessors ────────────────────────────────────────────────

  /// Returns the typed ConsentBasis, or null if not set / unrecognised.
  ConsentBasis? get consentBasis =>
      defaultConsentBasis != null
          ? consentBasisFromString(defaultConsentBasis)
          : null;

  String? get defaultPurpose => metadata['defaultPurpose'] as String?;

  // ── Factory — create from a completed assessment ─────────────────────────

  /// Copies ONLY safe, non-clinical, non-patient fields from [a].
  /// Patient identity, clinical scores, and risk level are deliberately
  /// excluded — templates are workflow presets, not clinical snapshots.
  static AssessmentTemplate fromAssessment({
    required Assessment a,
    required String templateName,
    required String id,
    String? description,
  }) {
    return AssessmentTemplate(
      id: id,
      name: templateName,
      description: description,
      assessmentType: 'MHCA',
      defaultClinician: a.consentRecordedBy,
      defaultConsentBasis: a.consentBasis?.name,
      contextualNote: null, // never copy clinical notes
      followUpRecommendedDefault:
          a.structuredRecommendations.followUpRecommended,
      metadata: {
        if (a.decisionContext.isNotEmpty)
          'defaultPurpose': a.decisionContext.split('|').first.trim(),
      },
      createdAt: DateTime.now(),
      useCount: 0,
    );
  }

  // ── Copy-with ────────────────────────────────────────────────────────────

  AssessmentTemplate copyWith({
    String? id,
    String? name,
    String? description,
    String? assessmentType,
    String? defaultClinician,
    String? defaultConsentBasis,
    String? contextualNote,
    bool? followUpRecommendedDefault,
    Map<String, dynamic>? metadata,
    DateTime? createdAt,
    DateTime? lastUsedAt,
    int? useCount,
  }) {
    return AssessmentTemplate(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      assessmentType: assessmentType ?? this.assessmentType,
      defaultClinician: defaultClinician ?? this.defaultClinician,
      defaultConsentBasis: defaultConsentBasis ?? this.defaultConsentBasis,
      contextualNote: contextualNote ?? this.contextualNote,
      followUpRecommendedDefault:
          followUpRecommendedDefault ?? this.followUpRecommendedDefault,
      metadata: metadata ?? this.metadata,
      createdAt: createdAt ?? this.createdAt,
      lastUsedAt: lastUsedAt ?? this.lastUsedAt,
      useCount: useCount ?? this.useCount,
    );
  }
}
