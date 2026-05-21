import 'package:pdf/pdf.dart';

import '../../models/risk_level.dart';

class PdfTheme {
  static final headerBg = PdfColor.fromHex('#1A237E');
  static final sectionBg = PdfColor.fromHex('#F5F5F5');
  static final riskHigh = PdfColor.fromHex('#B71C1C');
  static final riskMod = PdfColor.fromHex('#F57F17');
  static final riskLow = PdfColor.fromHex('#2E7D32');
  static final riskCrit = PdfColor.fromHex('#4A148C');
  static final refusedClr = PdfColor.fromHex('#4A148C');
  static final bodyText = PdfColor.fromHex('#212121');
  static final mutedText = PdfColor.fromHex('#757575');
  static final divider = PdfColor.fromHex('#E0E0E0');

  static const double headingSize = 13;
  static const double bodySize = 10;
  static const double labelSize = 8.5;
  static const double footerSize = 8;

  static const double sectionGap = 12;
  static const double fieldGap = 4;
  static const double pagePadding = 32;

  static PdfColor riskColor(RiskLevel level) => switch (level) {
    RiskLevel.low => riskLow,
    RiskLevel.moderate => riskMod,
    RiskLevel.high => riskHigh,
    RiskLevel.critical => riskCrit,
  };
}
