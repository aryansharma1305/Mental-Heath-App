import 'package:pdf/widgets.dart' as pw;

import '../../../models/assessment.dart';
import '../../../models/risk_level.dart';
import '../../assessment_questions.dart';
import '../pdf_theme.dart';
import 'pdf_section_helpers.dart';

class PdfResultsSection {
  static pw.Widget build(Assessment assessment) {
    final isDsm5 = assessment.decisionContext.toLowerCase().contains('dsm-5');
    final scoreData = AssessmentQuestions.calculateCapacityScore(
      assessment.responses,
    );
    final totalScore = scoreData['totalScore'] ?? 0;
    final maxScore = scoreData['maxScore'] ?? 0;
    final domainHighestScores =
        AssessmentQuestions.calculateDomainHighestScores(assessment.responses);
    final triggeredDomains = AssessmentQuestions.getDomainsRequiringFollowUp(
      domainHighestScores,
    );

    return pdfSection([
      pdfSectionHeader('ASSESSMENT RESULTS'),
      pdfField('Assessment type', assessment.decisionContext),
      pdfField('Status', assessment.assessmentStatus),
      pdfField('Overall finding', assessment.overallCapacity),
      if (isDsm5) pdfField('Total score', '$totalScore / $maxScore'),
      if (isDsm5 && domainHighestScores.isNotEmpty) ...[
        pdfDivider(),
        pdfSubheading('Domain scores'),
        ...domainHighestScores.entries.map(
          (entry) => _domainRow(entry.key, entry.value, triggeredDomains),
        ),
      ],
      if (!isDsm5) ...[
        pdfDivider(),
        pdfField(
          'Capacity finding',
          _capacityFound(assessment) ? 'Has capacity' : 'Lacks capacity',
        ),
      ],
    ]);
  }

  static pw.Widget _domainRow(
    String domain,
    int score,
    List<String> triggeredDomains,
  ) {
    final isTriggered = triggeredDomains.contains(domain);
    return pw.Padding(
      padding: const pw.EdgeInsets.only(top: 3),
      child: pw.Row(
        children: [
          pw.Expanded(child: pdfBodyText(domain)),
          pw.SizedBox(width: 24, child: pdfBodyText('$score')),
          if (isTriggered)
            pdfBadge('Level 2', PdfTheme.riskColor(RiskLevel.high)),
        ],
      ),
    );
  }

  static bool _capacityFound(Assessment assessment) {
    final finding = assessment.overallCapacity.toLowerCase();
    return finding.contains('has capacity') && !finding.contains('lacks');
  }
}
