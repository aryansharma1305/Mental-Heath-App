import 'package:intl/intl.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../../../models/countersignature.dart';
import '../pdf_theme.dart';
import 'pdf_section_helpers.dart';

class PdfSignatureSection {
  /// Build the signature block.
  ///
  /// If [countersignature] is provided, the second row is filled with the
  /// countersignatory's name, role, outcome, and date rather than blank lines.
  static pw.Widget build({
    String? clinicianName,
    Countersignature? countersignature,
  }) {
    final dateFormatter = DateFormat('d MMM yyyy HH:mm');

    final csName = countersignature != null
        ? '${countersignature.signatoryName} (${countersignature.signatoryRole})'
        : '_________________';

    final csDate = countersignature != null
        ? dateFormatter.format(countersignature.signedAt)
        : '______________';

    final csOutcomeLabel = countersignature?.outcome.label;

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
          pw.Text('Countersignature: $csName'),
          pw.Text('Date: $csDate'),
        ],
      ),
      if (csOutcomeLabel != null) ...[
        pw.SizedBox(height: PdfTheme.fieldGap),
        pw.Text(
          'Outcome: $csOutcomeLabel',
          style: pw.TextStyle(
            fontSize: PdfTheme.labelSize,
            color: PdfTheme.bodyText,
          ),
        ),
      ],
      if (countersignature?.notes?.isNotEmpty ?? false) ...[
        pw.SizedBox(height: PdfTheme.fieldGap),
        pw.Text(
          'Notes: ${countersignature!.notes}',
          style: pw.TextStyle(
            fontSize: PdfTheme.labelSize,
            fontStyle: pw.FontStyle.italic,
          ),
        ),
      ],
      pw.SizedBox(height: PdfTheme.sectionGap),
      pw.Text(
        'LOCAL COUNTERSIGNATURE - device-authenticated only. '
        'Not cryptographically account-verified.',
        style: pw.TextStyle(
          fontSize: PdfTheme.footerSize,
          color: PdfTheme.mutedText,
          fontStyle: pw.FontStyle.italic,
        ),
      ),
    ]);
  }
}
