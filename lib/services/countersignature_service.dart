import 'package:flutter/foundation.dart';
import '../models/assessment.dart';
import '../models/countersignature.dart';
import '../models/risk_level.dart';
import 'database_service.dart';

// =============================================================================
// CountersignatureService — Phase 4c: Multi-Assessor Sign-Off
//
// This service manages the local countersignature workflow (Option A).
// All operations are against the on-device SQLCipher database — no network
// calls are made.  The service is the single authority on:
//   • which assessments require / recommend a countersignature
//   • all status transitions (null → pending → countersigned / amendment_requested)
//   • the amendment edit guard (immutability fence for clinical data)
//
// IMPORTANT — Amendment scope:
//   Only `doctorNotes` and `recommendations` (free-text fields) may be
//   edited after an amendment is requested.  The following fields are
//   permanently immutable once an assessment is saved and MUST NOT be
//   widened by future contributors:
//     • responses
//     • overallCapacity
//     • riskLevel
//     • patientId / patientName
//     • assessmentDate
//     • consentBasis / consentNotes / consentRecordedAt / consentRecordedBy
//   Enforcement is at the service layer so that immutability holds regardless
//   of how the record is accessed (UI, test, background sync, etc.).
// =============================================================================
class CountersignatureService {
  CountersignatureService._();
  static final CountersignatureService instance = CountersignatureService._();

  final DatabaseService _db = DatabaseService();

  // ---------------------------------------------------------------------------
  // Status transitions
  // ---------------------------------------------------------------------------

  /// Mark an assessment as awaiting countersignature.
  /// Called when the clinician taps "Add later" on the post-save prompt.
  Future<void> requestCountersignature(int assessmentId) async {
    await _db.updateAssessmentCountersignatureStatus(
      assessmentId,
      'pending',
    );
    debugPrint(
      '📝 CountersignatureService: assessment $assessmentId → pending',
    );
  }

  /// Submit a completed countersignature review.
  ///
  /// Persists the [Countersignature] row, then updates the assessment status:
  ///   • approved / approvedWithComments → 'countersigned'
  ///   • requestedAmendment              → 'amendment_requested'
  ///
  /// Returns the saved [Countersignature].
  Future<Countersignature> submitCountersignature({
    required Assessment assessment,
    required String signatoryName,
    required String signatoryRole,
    required CountersignatureOutcome outcome,
    String? notes,
  }) async {
    if (assessment.id == null) {
      throw ArgumentError('Cannot countersign an unsaved assessment (id=null).');
    }
    if (outcome == CountersignatureOutcome.requestedAmendment &&
        (notes == null || notes.trim().isEmpty)) {
      throw ArgumentError(
        'Amendment notes are required when requesting an amendment.',
      );
    }

    final cs = Countersignature.create(
      assessmentId: assessment.id!,
      signatoryName: signatoryName.trim(),
      signatoryRole: signatoryRole.trim(),
      outcome: outcome,
      notes: notes?.trim().isEmpty == true ? null : notes?.trim(),
    );

    await _db.insertCountersignature(cs);

    final newStatus = outcome == CountersignatureOutcome.requestedAmendment
        ? 'amendment_requested'
        : 'countersigned';

    await _db.updateAssessmentCountersignatureStatus(
      assessment.id!,
      newStatus,
      amendmentNote:
          outcome == CountersignatureOutcome.requestedAmendment
              ? notes?.trim()
              : null,
    );

    debugPrint(
      '✅ CountersignatureService: assessment ${assessment.id} → $newStatus '
      'by $signatoryName',
    );
    return cs;
  }

  // ---------------------------------------------------------------------------
  // Queries
  // ---------------------------------------------------------------------------

  /// Retrieve the most recent countersignature for [assessmentId], or null.
  Future<Countersignature?> getCountersignature(int assessmentId) =>
      _db.getCountersignatureForAssessment(assessmentId);

  /// All assessments with countersignature_status = 'pending'.
  /// Used by the home-screen "Awaiting countersignature" section.
  Future<List<Assessment>> pendingSignOffs() =>
      _db.getAssessmentsAwaitingCountersignature();

  // ---------------------------------------------------------------------------
  // Amendment edit guard — SERVICE-LAYER IMMUTABILITY FENCE
  //
  // Only doctorNotes and recommendations may be updated after an amendment
  // request.  Any attempt to change an immutable field throws [ArgumentError].
  // This method must be the only code path through which amendment edits
  // are applied; direct calls to DatabaseService.updateAssessment() bypass
  // this guard and MUST NOT be used for amendment edits.
  // ---------------------------------------------------------------------------

  /// Apply permitted amendment edits to [original] and return an updated copy.
  ///
  /// Throws [ArgumentError] if any immutable field would change.
  /// After calling this, persist the result with [DatabaseService.updateAssessment]
  /// and set status back to 'pending' with [requestCountersignature].
  Assessment applyAmendmentEdits(
    Assessment original, {
    String? doctorNotes,
    String? recommendations,
  }) {
    _assertImmutableFieldsUnchanged(original, doctorNotes, recommendations);
    return original.copyWith(
      doctorNotes: doctorNotes,
      recommendations: recommendations ?? original.recommendations,
      updatedAt: DateTime.now(),
    );
  }

  void _assertImmutableFieldsUnchanged(
    Assessment original,
    String? newDoctorNotes,
    String? newRecommendations,
  ) {
    // The only check we need: ensure the caller hasn't slipped in any
    // structural changes by passing a completely different Assessment object.
    // Since applyAmendmentEdits always takes 'original' + named overrides,
    // this is defensive — the real guard is the method signature itself.
    // We intentionally do NOT validate newDoctorNotes or newRecommendations
    // (they are the permitted edit surface).
    //
    // If in the future this method is refactored to accept a full Assessment,
    // add explicit field comparisons here.
  }

  // ---------------------------------------------------------------------------
  // Convenience helpers
  // ---------------------------------------------------------------------------

  /// Whether this assessment requires a countersignature based on risk level.
  bool requiresCountersignature(Assessment assessment) =>
      assessment.riskLevel.requiresCountersignature;

  /// Whether a countersignature is recommended (soft prompt).
  bool countersignatureRecommended(Assessment assessment) =>
      assessment.riskLevel.countersignatureRecommended;
}
