import 'consent_basis.dart';

class ConsentRecord {
  final ConsentBasis basis;
  final String? notes;
  final DateTime recordedAt;
  final String recordedBy;

  const ConsentRecord({
    required this.basis,
    this.notes,
    required this.recordedAt,
    required this.recordedBy,
  });

  bool get allowsAssessment => basis.allowsAssessment;

  bool get isEmergency => basis.isEmergency;

  bool get lacksCapacity => basis.lacksCapacity;

  void validate() {
    if (basis == ConsentBasis.refused &&
        (notes == null || notes!.trim().isEmpty)) {
      throw ArgumentError('Consent refusal records require clinician notes.');
    }
    if (recordedBy.trim().isEmpty) {
      throw ArgumentError('Consent records require a recorded-by value.');
    }
  }
}
