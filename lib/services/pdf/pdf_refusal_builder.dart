import 'dart:typed_data';

import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../models/assessment.dart';
import '../../models/consent_basis.dart';
import '../../models/risk_level.dart';
import 'pdf_theme.dart';
import 'sections/pdf_section_helpers.dart';

class PdfRefusalBuilder {
  Future<Uint8List> buildRefusalRecord(Assessment assessment) async {
    final doc = pw.Document();
    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(PdfTheme.pagePadding),
        footer: (context) =>
            pdfPageFooter(context, label: 'ID: ${assessment.patientId}'),
        build: (context) => [
          pw.Text(
            'Mental Capacity Assessment - Consent Refusal Record',
            style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: PdfTheme.sectionGap),
          pdfField('Patient', assessment.patientId),
          pdfField(
            'Date',
            DateFormat('dd MMM yyyy HH:mm').format(assessment.assessmentDate),
          ),
          pdfField('Assessment type', assessment.decisionContext),
          pdfField(
            'Clinician',
            assessment.consentRecordedBy ?? assessment.assessorName,
          ),
          pdfField(
            'Consent basis',
            assessment.consentBasis?.label ?? 'Refused',
          ),
          pdfField('Risk level', assessment.riskLevel.label),
          pw.SizedBox(height: PdfTheme.sectionGap),
          pdfSectionHeader('CLINICIAN NOTES'),
          pw.SizedBox(height: 6),
          pdfBodyText(assessment.consentNotes ?? 'No notes recorded.'),
          pw.SizedBox(height: PdfTheme.sectionGap),
          pdfBodyText(
            'This record documents that an assessment was attempted. '
            'The patient declined to proceed. No clinical assessment data was collected.',
          ),
          pw.Spacer(),
          PdfSignatureLine.build(),
        ],
      ),
    );
    return doc.save();
  }
}

class PdfSignatureLine {
  static pw.Widget build() {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Text('Signed: _______________________'),
        pw.Text('Date: __________________'),
      ],
    );
  }
}
