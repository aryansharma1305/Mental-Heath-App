import 'package:flutter/foundation.dart';
import 'package:sqflite_sqlcipher/sqflite.dart';
import 'package:uuid/uuid.dart';

import '../models/assessment.dart';
import '../models/assessment_template.dart';
import 'database_service.dart';

/// CRUD and usage-tracking service for workflow-preset templates.
///
/// Storage is device-local SQLite only — templates are clinician preferences,
/// not clinical records, so no Supabase sync is required in v1.
class TemplateService {
  static final TemplateService instance = TemplateService._();
  TemplateService._();

  // ── Queries ───────────────────────────────────────────────────────────────

  /// Returns all templates for [assessmentType], sorted by use_count DESC
  /// then name ASC so the most-used templates surface first.
  Future<List<AssessmentTemplate>> getTemplates(String assessmentType) async {
    final db = await DatabaseService().database;
    final maps = await db.query(
      'assessment_templates',
      where: 'assessment_type = ?',
      whereArgs: [assessmentType],
      orderBy: 'use_count DESC, name ASC',
    );
    return maps.map(AssessmentTemplate.fromMap).toList();
  }

  /// Returns all templates across all assessment types, sorted by use_count
  /// DESC then name ASC, grouped implicitly by assessment_type.
  Future<List<AssessmentTemplate>> getAllTemplates() async {
    final db = await DatabaseService().database;
    final maps = await db.query(
      'assessment_templates',
      orderBy: 'assessment_type ASC, use_count DESC, name ASC',
    );
    return maps.map(AssessmentTemplate.fromMap).toList();
  }

  /// Returns a single template by [id], or null if not found.
  Future<AssessmentTemplate?> getTemplate(String id) async {
    final db = await DatabaseService().database;
    final maps = await db.query(
      'assessment_templates',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (maps.isEmpty) return null;
    return AssessmentTemplate.fromMap(maps.first);
  }

  // ── Mutations ─────────────────────────────────────────────────────────────

  /// Inserts or replaces a template.  Pass a template with a new [uuid] id to
  /// create, or the existing id to update (all fields replaced).
  Future<void> saveTemplate(AssessmentTemplate template) async {
    final db = await DatabaseService().database;
    await db.insert(
      'assessment_templates',
      template.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    debugPrint('TemplateService: saved template "${template.name}" (${template.id})');
  }

  /// Permanently deletes the template with [id].
  Future<void> deleteTemplate(String id) async {
    final db = await DatabaseService().database;
    await db.delete('assessment_templates', where: 'id = ?', whereArgs: [id]);
    debugPrint('TemplateService: deleted template $id');
  }

  /// Increments [use_count] and updates [last_used_at] for the given template.
  /// Call this immediately after a clinician starts an assessment using the
  /// template — keeps sort order clinically meaningful over time.
  ///
  /// Fire-and-forget: failures are logged but never rethrown.
  Future<void> recordUsage(String id) async {
    try {
      final db = await DatabaseService().database;
      await db.rawUpdate(
        '''
        UPDATE assessment_templates
        SET use_count    = use_count + 1,
            last_used_at = ?
        WHERE id = ?
        ''',
        [DateTime.now().toIso8601String(), id],
      );
    } catch (e) {
      debugPrint('TemplateService: recordUsage failed for $id — $e');
    }
  }

  // ── Factory ───────────────────────────────────────────────────────────────

  /// Creates an [AssessmentTemplate] from a completed [assessment].
  ///
  /// Deliberately excludes: patient identity, clinical scores, risk level, and
  /// consent notes.  The resulting template is GDPR-safe and contains only
  /// clinician workflow preferences.
  AssessmentTemplate fromAssessment(
    Assessment assessment,
    String templateName, {
    String? description,
  }) {
    return AssessmentTemplate.fromAssessment(
      a: assessment,
      templateName: templateName,
      id: const Uuid().v4(),
      description: description,
    );
  }

  // ── Convenience ───────────────────────────────────────────────────────────

  /// Creates a blank template pre-set for [assessmentType] with a UUID id.
  AssessmentTemplate createBlank(String assessmentType) {
    return AssessmentTemplate(
      id: const Uuid().v4(),
      name: '',
      assessmentType: assessmentType,
      createdAt: DateTime.now(),
    );
  }
}
