import 'package:pdf/widgets.dart' as pw;

import '../pdf_theme.dart';
import 'pdf_section_helpers.dart';

class PdfSignatureSection {
  static pw.Widget build({String? clinicianName}) {
    return pdfSection([
      pdfSectionHeader('SIGNATURE'),
      pw.SizedBox(height: PdfTheme.sectionGap),
      pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text('Clinician: ${clinicianName ?? '_________________'}'),
          pw.Text('Date: ______________'),
        ],
      ),
      pw.SizedBox(height: PdfTheme.sectionGap),
      pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text('Countersignature: _________________'),
          pw.Text('Date: ______________'),
        ],
      ),
    ]);
  }
}
