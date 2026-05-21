import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../models/assessment.dart';
import '../../models/consent_basis.dart';
import '../../models/patient_profile.dart';
import '../../models/risk_level.dart';
import 'pdf_theme.dart';
import 'sections/pdf_consent_section.dart';
import 'sections/pdf_header_section.dart';
import 'sections/pdf_notes_section.dart';
import 'sections/pdf_recommendations_section.dart';
import 'sections/pdf_results_section.dart';
import 'sections/pdf_risk_section.dart';
import 'sections/pdf_section_helpers.dart';
import 'sections/pdf_signature_section.dart';
import 'sections/pdf_trend_section.dart';

class PdfReportBuilder {
  Future<Uint8List> buildFullReport({
    required Assessment assessment,
    PatientProfile? patient,
    Assessment? priorAssessment,
    String? clinicalNote,
    DateTime? generatedAt,
  }) async {
    final doc = pw.Document();
    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(PdfTheme.pagePadding),
        footer: (context) =>
            pdfPageFooter(context, label: 'ID: ${assessment.patientId}'),
        build: (context) => [
          PdfHeaderSection.build(
            assessment,
            patient: patient,
            generatedAt: generatedAt,
          ),
          pw.SizedBox(height: PdfTheme.sectionGap),
          PdfConsentSection.build(assessment),
          PdfRiskSection.build(
            assessment,
            rationale: _riskRationale(assessment),
          ),
          PdfResultsSection.build(assessment),
          if (priorAssessment != null)
            PdfTrendSection.build(assessment, priorAssessment),
          if (clinicalNote?.trim().isNotEmpty ?? false)
            PdfNotesSection.build(clinicalNote!.trim()),
          PdfRecommendationsSection.build(assessment.structuredRecommendations),
          PdfSignatureSection.build(
            clinicianName:
                assessment.consentRecordedBy ?? assessment.assessorName,
          ),
        ],
      ),
    );
    return doc.save();
  }

  String _riskRationale(Assessment assessment) {
    final basis = <String>[];
    basis.add('Stored risk label: ${assessment.riskLevel.label}');
    if (assessment.consentBasis?.isEmergency == true) {
      basis.add('emergency consent basis');
    }
    if (assessment.recommendations.trim().isNotEmpty) {
      basis.add('recommendations: ${assessment.recommendations}');
    }
    return basis.join('; ');
  }
}
