import 'package:intl/intl.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../../models/assessment.dart';
import '../../../models/patient_profile.dart';
import '../pdf_theme.dart';

class PdfHeaderSection {
  static pw.Widget build(Assessment assessment, {PatientProfile? patient}) {
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.all(14),
      decoration: pw.BoxDecoration(
        color: PdfTheme.headerBg,
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'Mental Capacity Assessment Report',
            style: pw.TextStyle(
              color: PdfTheme.sectionBg,
              fontSize: 18,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(height: 6),
          pw.Text(
            'Patient: ${patient?.displayName ?? assessment.patientName} | ID: ${assessment.patientId}',
            style: pw.TextStyle(color: PdfTheme.sectionBg, fontSize: 10),
          ),
          pw.Text(
            'Generated: ${DateFormat('dd MMM yyyy HH:mm').format(DateTime.now())} | Confidential',
            style: pw.TextStyle(color: PdfTheme.sectionBg, fontSize: 9),
          ),
        ],
      ),
    );
  }
}
