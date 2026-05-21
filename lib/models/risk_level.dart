import 'package:flutter/material.dart';

enum RiskLevel { low, moderate, high, critical }

extension RiskLevelDisplay on RiskLevel {
  String get label => switch (this) {
    RiskLevel.low => 'Low',
    RiskLevel.moderate => 'Moderate',
    RiskLevel.high => 'High',
    RiskLevel.critical => 'Critical',
  };

  Color get color => switch (this) {
    RiskLevel.low => const Color(0xFF2E7D32),
    RiskLevel.moderate => const Color(0xFFF57F17),
    RiskLevel.high => const Color(0xFFB71C1C),
    RiskLevel.critical => const Color(0xFF4A148C),
  };

  Color get background => switch (this) {
    RiskLevel.low => const Color(0xFFE8F5E9),
    RiskLevel.moderate => const Color(0xFFFFF8E1),
    RiskLevel.high => const Color(0xFFFFEBEE),
    RiskLevel.critical => const Color(0xFFF3E5F5),
  };

  int get priority => switch (this) {
    RiskLevel.low => 0,
    RiskLevel.moderate => 1,
    RiskLevel.high => 2,
    RiskLevel.critical => 3,
  };
}

RiskLevel riskLevelFromString(String? value) {
  return RiskLevel.values.firstWhere(
    (level) => level.name == value?.toLowerCase(),
    orElse: () => RiskLevel.low,
  );
}
