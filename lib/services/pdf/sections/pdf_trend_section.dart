import 'package:intl/intl.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../../models/assessment.dart';
import '../../../models/risk_level.dart';
import '../../assessment_questions.dart';
import '../pdf_theme.dart';
import 'pdf_section_helpers.dart';

class PdfTrendSection {
  static pw.Widget build(Assessment current, Assessment prior) {
    final currentScore = _dsm5Total(current);
    final priorScore = _dsm5Total(prior);
    final scoreDelta = currentScore - priorScore;
    final deltaLabel = scoreDelta > 0 ? '+$scoreDelta' : '$scoreDelta';
    final direction = scoreDelta > 0
        ? 'deterioration'
        : scoreDelta < 0
        ? 'improvement'
        : 'no change';
    final riskChanged = current.riskLevel != prior.riskLevel;

    return pdfSection([
      pdfSectionHeader('TREND CONTEXT'),
      pdfField(
        'Previous assessment',
        DateFormat('dd MMM yyyy HH:mm').format(prior.assessmentDate),
      ),
      pdfField('Previous score', '$priorScore - ${prior.riskLevel.label}'),
      pdfField('Current score', '$currentScore - ${current.riskLevel.label}'),
      pdfField('Change', '$deltaLabel points - $direction'),
      if (riskChanged)
        pw.Padding(
          padding: const pw.EdgeInsets.only(top: PdfTheme.fieldGap),
          child: pdfBadge(
            'Risk level changed: ${prior.riskLevel.label} to ${current.riskLevel.label}',
            PdfTheme.riskColor(current.riskLevel),
          ),
        ),
    ]);
  }

  static int _dsm5Total(Assessment assessment) {
    final scoreData = AssessmentQuestions.calculateCapacityScore(
      assessment.responses,
    );
    return (scoreData['totalScore'] as num?)?.toInt() ?? 0;
  }
}
