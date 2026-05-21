import 'package:flutter/material.dart';

enum ConsentBasis {
  consentObtained,
  lacksCapacityBestInterest,
  lacksCapacityEmergency,
  refused,
}

extension ConsentBasisDisplay on ConsentBasis {
  String get label => switch (this) {
    ConsentBasis.consentObtained => 'Consent obtained',
    ConsentBasis.lacksCapacityBestInterest => 'Lacks capacity - best interest',
    ConsentBasis.lacksCapacityEmergency => 'Lacks capacity - emergency basis',
    ConsentBasis.refused => 'Refused',
  };

  bool get isEmergency => this == ConsentBasis.lacksCapacityEmergency;

  bool get lacksCapacity =>
      this == ConsentBasis.lacksCapacityBestInterest ||
      this == ConsentBasis.lacksCapacityEmergency;

  bool get allowsAssessment => this != ConsentBasis.refused;

  Color get color => switch (this) {
    ConsentBasis.consentObtained => const Color(0xFF2E7D32),
    ConsentBasis.lacksCapacityBestInterest => const Color(0xFFF57F17),
    ConsentBasis.lacksCapacityEmergency => const Color(0xFFB71C1C),
    ConsentBasis.refused => const Color(0xFF4A148C),
  };

  Color get background => switch (this) {
    ConsentBasis.consentObtained => const Color(0xFFE8F5E9),
    ConsentBasis.lacksCapacityBestInterest => const Color(0xFFFFF8E1),
    ConsentBasis.lacksCapacityEmergency => const Color(0xFFFFEBEE),
    ConsentBasis.refused => const Color(0xFFF3E5F5),
  };
}

ConsentBasis? consentBasisFromString(String? value) {
  if (value == null || value.isEmpty) return null;
  for (final basis in ConsentBasis.values) {
    if (basis.name == value) return basis;
  }
  return null;
}
