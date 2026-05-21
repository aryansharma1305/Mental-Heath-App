import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

import '../models/assessment.dart';
import 'database_service.dart';
import 'pdf/pdf_refusal_builder.dart';
import 'pdf/pdf_report_builder.dart';

class PdfExportService {
  Future<String?> exportAssessmentToPdf(Assessment assessment) async {
    try {
      final status = await Permission.storage.request();
      if (!status.isGranted) {
        // Newer Android versions can still write to the app documents directory.
      }

      final db = DatabaseService();
      final patient = await db.getPatient(assessment.patientId);
      final priorAssessment = await db.getPriorAssessmentFor(assessment);
      final notes = assessment.id == null
          ? const []
          : await db.getClinicalNotesForAssessment(assessment.id!);
      final clinicalNote = notes.isEmpty ? null : notes.first.note;

      final bytes = assessment.isRefused
          ? await PdfRefusalBuilder().buildRefusalRecord(assessment)
          : await PdfReportBuilder().buildFullReport(
              assessment: assessment,
              patient: patient,
              priorAssessment: priorAssessment,
              clinicalNote: clinicalNote,
            );

      final directory = await getApplicationDocumentsDirectory();
      final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
      final safeId =
          (assessment.patientId.isEmpty ? 'UNKNOWN' : assessment.patientId)
              .replaceAll(RegExp(r'[^A-Za-z0-9_-]'), '_');
      final fileName = assessment.isRefused
          ? 'Consent_Refusal_${safeId}_$timestamp.pdf'
          : 'Assessment_${safeId}_$timestamp.pdf';
      final file = File('${directory.path}/$fileName');
      await file.writeAsBytes(bytes);
      return file.path;
    } catch (e, stackTrace) {
      debugPrint('PDF Export Error: $e');
      debugPrint('Stack trace: $stackTrace');
      return null;
    }
  }
}
