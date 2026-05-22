import 'package:uuid/uuid.dart';

// ---------------------------------------------------------------------------
// CountersignatureOutcome — what the countersignatory decided.
// ---------------------------------------------------------------------------
enum CountersignatureOutcome {
  approved,
  approvedWithComments,
  requestedAmendment;

  String get label => switch (this) {
        CountersignatureOutcome.approved => 'Approved',
        CountersignatureOutcome.approvedWithComments =>
          'Approved with comments',
        CountersignatureOutcome.requestedAmendment => 'Request amendment',
      };
}

CountersignatureOutcome countersignatureOutcomeFromString(String? value) {
  return CountersignatureOutcome.values.firstWhere(
    (o) => o.name == value,
    orElse: () => CountersignatureOutcome.approved,
  );
}

// ---------------------------------------------------------------------------
// Countersignature — a second clinician's structured sign-off on one record.
//
// This is a LOCAL-ONLY record (Option A). It is stored in the on-device
// SQLCipher database and is not cryptographically verified against a server
// identity. The clinical value is:
//   1. Two named clinicians are documented on the record.
//   2. The countersignatory must authenticate on the device (credential
//      re-entry) to prove they have authorised app access.
//
// This limitation is intentional and should be documented clearly to
// clinical governance teams. Option B (Supabase-backed, account-verified)
// can be layered on top in a future phase.
// ---------------------------------------------------------------------------
class Countersignature {
  final String id; // UUID
  final int assessmentId; // FK → assessments.id
  final String signatoryName;
  final String signatoryRole; // "Consultant", "Registrar", etc.
  final DateTime signedAt;
  final CountersignatureOutcome outcome;
  final String? notes; // required if outcome == requestedAmendment

  const Countersignature({
    required this.id,
    required this.assessmentId,
    required this.signatoryName,
    required this.signatoryRole,
    required this.signedAt,
    required this.outcome,
    this.notes,
  });

  factory Countersignature.create({
    required int assessmentId,
    required String signatoryName,
    required String signatoryRole,
    required CountersignatureOutcome outcome,
    String? notes,
  }) {
    return Countersignature(
      id: const Uuid().v4(),
      assessmentId: assessmentId,
      signatoryName: signatoryName,
      signatoryRole: signatoryRole,
      signedAt: DateTime.now(),
      outcome: outcome,
      notes: notes,
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'assessment_id': assessmentId,
        'signatory_name': signatoryName,
        'signatory_role': signatoryRole,
        'signed_at': signedAt.toIso8601String(),
        'outcome': outcome.name,
        'notes': notes,
      };

  factory Countersignature.fromMap(Map<String, dynamic> map) {
    return Countersignature(
      id: map['id'] as String,
      assessmentId: map['assessment_id'] as int,
      signatoryName: map['signatory_name'] as String,
      signatoryRole: map['signatory_role'] as String,
      signedAt: DateTime.parse(map['signed_at'] as String),
      outcome: countersignatureOutcomeFromString(map['outcome'] as String?),
      notes: map['notes'] as String?,
    );
  }

  Countersignature copyWith({
    String? id,
    int? assessmentId,
    String? signatoryName,
    String? signatoryRole,
    DateTime? signedAt,
    CountersignatureOutcome? outcome,
    String? notes,
  }) {
    return Countersignature(
      id: id ?? this.id,
      assessmentId: assessmentId ?? this.assessmentId,
      signatoryName: signatoryName ?? this.signatoryName,
      signatoryRole: signatoryRole ?? this.signatoryRole,
      signedAt: signedAt ?? this.signedAt,
      outcome: outcome ?? this.outcome,
      notes: notes ?? this.notes,
    );
  }

  @override
  String toString() =>
      'Countersignature(id=$id, assessmentId=$assessmentId, '
      'outcome=${outcome.name}, signedAt=$signedAt)';
}
