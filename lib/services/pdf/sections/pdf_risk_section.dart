import 'package:pdf/widgets.dart' as pw;

import '../../../models/assessment.dart';
import '../../../models/risk_level.dart';
import '../pdf_theme.dart';
import 'pdf_section_helpers.dart';

class PdfRiskSection {
  static pw.Widget build(Assessment assessment, {String? rationale}) {
    final risk = assessment.riskLevel;
    return pdfSection([
      pdfSectionHeader('RISK LEVEL'),
      pw.SizedBox(height: PdfTheme.fieldGap),
      pdfBadge(risk.label.toUpperCase(), PdfTheme.riskColor(risk)),
      if (rationale?.trim().isNotEmpty ?? false)
        pdfField('Basis', rationale!.trim()),
    ]);
  }
}
