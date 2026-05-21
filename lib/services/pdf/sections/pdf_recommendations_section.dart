import 'package:pdf/widgets.dart' as pw;

import '../../../models/assessment_recommendations.dart';
import 'pdf_section_helpers.dart';

class PdfRecommendationsSection {
  static pw.Widget build(AssessmentRecommendations recommendations) {
    return pdfSection([
      pdfSectionHeader('RECOMMENDATIONS'),
      pdfField(
        '[ ] Follow-up assessment recommended',
        recommendations.followUpRecommended ? 'Yes' : 'No',
      ),
      pdfField(
        '[ ] Refer to specialist',
        recommendations.referToSpecialist ? 'Yes' : 'No',
      ),
      pdfField(
        '[ ] No further action at this time',
        recommendations.noFurtherAction ? 'Yes' : 'No',
      ),
      if (recommendations.freeText?.trim().isNotEmpty ?? false)
        pdfField('Free text', recommendations.freeText!.trim()),
    ]);
  }
}
