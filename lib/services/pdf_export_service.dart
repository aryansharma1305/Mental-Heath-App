import 'dart:io';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:intl/intl.dart';
import '../models/assessment.dart';

class PdfExportService {
  Future<String?> exportAssessmentToPdf(Assessment assessment) async {
    try {
      // Request storage permission
      final status = await Permission.storage.request();
      if (!status.isGranted) {
        return null;
      }

      final pdf = pw.Document();

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(40),
          build: (context) => [
            // Header
            _buildHeader(assessment),
            pw.SizedBox(height: 20),
            
            // Patient Information
            _buildSectionTitle('Patient Information'),
            _buildPatientInfo(assessment),
            pw.SizedBox(height: 20),
            
            // Assessment Details
            _buildSectionTitle('Assessment Details'),
            _buildAssessmentDetails(assessment),
            pw.SizedBox(height: 20),
            
            // Responses
            _buildSectionTitle('Assessment Responses'),
            _buildResponses(assessment),
            pw.SizedBox(height: 20),
            
            // Recommendations
            _buildSectionTitle('Recommendations'),
            _buildRecommendations(assessment),
            pw.SizedBox(height: 20),
            
            // Footer
            _buildFooter(assessment),
          ],
        ),
      );

      // Get directory
      final directory = await getApplicationDocumentsDirectory();
      final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
      final fileName = 'Assessment_${assessment.patientName.replaceAll(' ', '_')}_$timestamp.pdf';
      final filePath = '${directory.path}/$fileName';
      
      final file = File(filePath);
      await file.writeAsBytes(await pdf.save());

      return filePath;
    } catch (e) {
      return null;
    }
  }

  pw.Widget _buildHeader(Assessment assessment) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(20),
      decoration: pw.BoxDecoration(
        color: PdfColors.grey200,
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'Mental Capacity Assessment Report',
            style: pw.TextStyle(
              fontSize: 24,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(height: 8),
          pw.Text(
            'Generated on: ${DateFormat('MMMM d, y • h:mm a').format(DateTime.now())}',
            style: pw.TextStyle(fontSize: 12),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildSectionTitle(String title) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 12),
      child: pw.Text(
        title,
        style: pw.TextStyle(
          fontSize: 18,
          fontWeight: pw.FontWeight.bold,
        ),
      ),
    );
  }

  pw.Widget _buildPatientInfo(Assessment assessment) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey300),
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          _buildInfoRow('Patient Name', assessment.patientName),
          _buildInfoRow('Patient ID', assessment.patientId),
          _buildInfoRow(
            'Overall Capacity',
            assessment.overallCapacity,
          ),
        ],
      ),
    );
  }

  pw.Widget _buildAssessmentDetails(Assessment assessment) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey300),
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          _buildInfoRow(
            'Assessment Date',
            DateFormat('MMMM d, y • h:mm a').format(assessment.assessmentDate),
          ),
          _buildInfoRow('Assessor Name', assessment.assessorName),
          _buildInfoRow('Assessor Role', assessment.assessorRole),
          _buildInfoRow('Decision Context', assessment.decisionContext),
          if (assessment.status != null)
            _buildInfoRow('Status', assessment.status!),
          if (assessment.doctorNotes != null && assessment.doctorNotes!.isNotEmpty)
            _buildInfoRow('Doctor Notes', assessment.doctorNotes!),
        ],
      ),
    );
  }

  pw.Widget _buildResponses(Assessment assessment) {
    if (assessment.responses.isEmpty) {
      return pw.Container(
        padding: const pw.EdgeInsets.all(16),
        child: pw.Text(
          'No responses recorded',
          style: pw.TextStyle(fontStyle: pw.FontStyle.italic),
        ),
      );
    }

    return pw.Container(
      padding: const pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey300),
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: assessment.responses.entries.map((entry) {
          return pw.Padding(
            padding: const pw.EdgeInsets.only(bottom: 12),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  entry.key,
                  style: pw.TextStyle(
                    fontSize: 12,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 4),
                pw.Text(
                  entry.value.toString(),
                  style: const pw.TextStyle(fontSize: 11),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  pw.Widget _buildRecommendations(Assessment assessment) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey300),
        borderRadius: pw.BorderRadius.circular(8),
        color: PdfColors.blue50,
      ),
      child: pw.Text(
        assessment.recommendations,
        style: const pw.TextStyle(fontSize: 12),
      ),
    );
  }

  pw.Widget _buildFooter(Assessment assessment) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(top: 20),
      padding: const pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(
        color: PdfColors.grey100,
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'Report Information',
            style: pw.TextStyle(
              fontSize: 12,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(height: 8),
          pw.Text(
            'Created: ${DateFormat('MMMM d, y • h:mm a').format(assessment.createdAt)}',
            style: const pw.TextStyle(fontSize: 10),
          ),
          pw.Text(
            'Last Updated: ${DateFormat('MMMM d, y • h:mm a').format(assessment.updatedAt)}',
            style: const pw.TextStyle(fontSize: 10),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildInfoRow(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 8),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.SizedBox(
            width: 120,
            child: pw.Text(
              '$label:',
              style: pw.TextStyle(
                fontSize: 11,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
          ),
          pw.Expanded(
            child: pw.Text(
              value,
              style: const pw.TextStyle(fontSize: 11),
            ),
          ),
        ],
      ),
    );
  }
}
