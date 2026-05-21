import 'package:pdf/widgets.dart' as pw;

import 'pdf_section_helpers.dart';

class PdfNotesSection {
  static pw.Widget build(String note) {
    return pdfSection([
      pdfSectionHeader('CLINICAL NOTES'),
      pw.SizedBox(height: 6),
      pdfBodyText(note),
    ]);
  }
}
