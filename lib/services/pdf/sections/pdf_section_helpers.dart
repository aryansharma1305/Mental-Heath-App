import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../pdf_theme.dart';

pw.Widget pdfSectionHeader(String title) {
  return pw.Container(
    width: double.infinity,
    padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 7),
    decoration: pw.BoxDecoration(
      color: PdfTheme.sectionBg,
      border: pw.Border(
        left: pw.BorderSide(color: PdfTheme.headerBg, width: 3),
      ),
    ),
    child: pw.Text(
      title,
      style: pw.TextStyle(
        fontSize: PdfTheme.headingSize,
        fontWeight: pw.FontWeight.bold,
        color: PdfTheme.bodyText,
      ),
    ),
  );
}

pw.Widget pdfField(String label, String value) {
  return pw.Padding(
    padding: const pw.EdgeInsets.only(top: PdfTheme.fieldGap),
    child: pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.SizedBox(
          width: 110,
          child: pw.Text(
            label,
            style: pw.TextStyle(
              fontSize: PdfTheme.labelSize,
              fontWeight: pw.FontWeight.bold,
              color: PdfTheme.mutedText,
            ),
          ),
        ),
        pw.Expanded(
          child: pw.Text(
            value,
            style: pw.TextStyle(
              fontSize: PdfTheme.bodySize,
              color: PdfTheme.bodyText,
            ),
          ),
        ),
      ],
    ),
  );
}

pw.Widget pdfSection(List<pw.Widget> children) {
  return pw.Padding(
    padding: const pw.EdgeInsets.only(bottom: PdfTheme.sectionGap),
    child: pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: children,
    ),
  );
}

pw.Widget pdfBadge(String label, PdfColor color) {
  return pw.Container(
    padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    decoration: pw.BoxDecoration(
      border: pw.Border.all(color: color),
      borderRadius: pw.BorderRadius.circular(10),
    ),
    child: pw.Text(
      label,
      style: pw.TextStyle(
        color: color,
        fontWeight: pw.FontWeight.bold,
        fontSize: PdfTheme.labelSize,
      ),
    ),
  );
}
