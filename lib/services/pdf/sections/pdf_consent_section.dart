import 'package:intl/intl.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../../models/assessment.dart';
import '../../../models/consent_basis.dart';
import 'pdf_section_helpers.dart';

class PdfConsentSection {
  static pw.Widget build(Assessment assessment) {
    final recordedAt = assessment.consentRecordedAt;
    return pdfSection([
      pdfSectionHeader('CONSENT'),
      pdfField('Basis', assessment.consentBasis?.label ?? 'Not recorded'),
      pdfField('Recorded by', assessment.consentRecordedBy ?? 'Not recorded'),
      pdfField(
        'Recorded at',
        recordedAt == null
            ? 'Not recorded'
            : DateFormat('dd MMM yyyy HH:mm').format(recordedAt),
      ),
      if (assessment.consentNotes?.trim().isNotEmpty ?? false)
        pdfField('Notes', assessment.consentNotes!.trim()),
    ]);
  }
}
