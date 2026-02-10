import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:intl/intl.dart';
import '../models/assessment.dart';
import 'assessment_questions.dart';

class PdfExportService {
  
  /// Generate anonymised ID from assessment
  /// Uses the actual patient_id entered during assessment
  String _generateAnonymisedId(Assessment assessment) {
    // Return the actual patient ID as entered (e.g., "P001", "TEST123")
    final patientId = assessment.patientId.isNotEmpty 
        ? assessment.patientId 
        : 'UNKNOWN';
    return 'ID: $patientId';
  }

  /// Calculate domain highest scores from responses
  Map<String, int> _calculateDomainHighestScores(Map<String, dynamic> responses) {
    final questions = AssessmentQuestions.getStandardQuestions();
    final standardOptions = AssessmentQuestions.getResponseOptions();
    Map<String, int> domainHighestScores = {};
    
    for (var entry in responses.entries) {
      int score = 0;
      
      if (entry.value is int) {
        // Direct integer score (0-4)
        score = entry.value as int;
      } else if (entry.value is Map) {
        final answer = (entry.value as Map)['answer'];
        if (answer is int) {
          score = answer;
        } else {
          final answerStr = answer?.toString() ?? '';
          score = standardOptions.indexOf(answerStr);
          if (score < 0) score = 0;
        }
      } else {
        // String response - look up in options
        final answerStr = entry.value.toString();
        score = standardOptions.indexOf(answerStr);
        if (score < 0) score = 0;
      }
      
      // Find question to get domain/category
      final question = questions.firstWhere(
        (q) => q.questionId == entry.key,
        orElse: () => questions.first,
      );
      
      final domain = question.category ?? 'Unknown';
      if (score > (domainHighestScores[domain] ?? 0)) {
        domainHighestScores[domain] = score;
      }
    }
    
    return domainHighestScores;
  }

  /// Get the flagged domains based on DSM-5 criteria
  List<String> _getFlaggedDomains(Map<String, int> domainHighestScores) {
    List<String> flagged = [];
    
    domainHighestScores.forEach((domain, score) {
      // Per DSM-5: Substance Use, Suicidal Ideation, and Psychosis flag at score >= 1
      if ((domain.contains('Suicidal') || 
           domain.contains('Substance') || 
           domain.contains('Psychosis')) && score >= 1) {
        flagged.add(domain);
      } else if (score >= 2) {
        // All other domains flag at score >= 2 (Mild)
        flagged.add(domain);
      }
    });
    
    return flagged;
  }

  Future<String?> exportAssessmentToPdf(Assessment assessment) async {
    try {
      // Request storage permission
      final status = await Permission.storage.request();
      if (!status.isGranted) {
        // Try without permission on newer Android
      }

      final pdf = pw.Document();
      final anonymisedId = _generateAnonymisedId(assessment);
      final domainHighestScores = _calculateDomainHighestScores(assessment.responses);
      final flaggedDomains = _getFlaggedDomains(domainHighestScores);
      final overallScoreData = AssessmentQuestions.calculateCapacityScore(assessment.responses);

      // Try to load logos (will be null if not available)
      pw.MemoryImage? engCollegeLogo;
      pw.MemoryImage? psychiatryLogo;
      
      try {
        final engLogoData = await rootBundle.load('assets/logos/images.jpeg');
        engCollegeLogo = pw.MemoryImage(engLogoData.buffer.asUint8List());
      } catch (e) {
        // Logo not available
      }
      
      try {
        final psyLogoData = await rootBundle.load('assets/logos/WhatsApp Image 2026-02-09 at 8.47.19 AM.jpeg');
        psychiatryLogo = pw.MemoryImage(psyLogoData.buffer.asUint8List());
      } catch (e) {
        // Logo not available
      }

      // Page 1 & 2: Assessment Report
      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(40),
          footer: (context) => _buildPageFooter(context, anonymisedId),
          build: (context) => [
            // Header with Logos
            _buildLogoHeader(anonymisedId, engCollegeLogo, psychiatryLogo),
            pw.SizedBox(height: 20),
            
            // Assessment Info (anonymised)
            _buildSectionTitle('Assessment Information'),
            _buildAnonymisedAssessmentInfo(assessment, anonymisedId),
            pw.SizedBox(height: 20),
            
            // Domain Scores Table
            _buildSectionTitle('Domain Scores Summary'),
            _buildDomainScoresTable(domainHighestScores, flaggedDomains),
            pw.SizedBox(height: 20),
            
            // Highest Domain Score
            _buildHighestDomainScore(domainHighestScores),
            pw.SizedBox(height: 20),
            
            // Flagged Domains Alert
            if (flaggedDomains.isNotEmpty) ...[
              _buildFlaggedDomainsAlert(flaggedDomains),
              pw.SizedBox(height: 20),
            ],
            
            // Overall Capacity
            _buildSectionTitle('Overall Capacity Determination'),
            _buildCapacityDetermination(assessment, overallScoreData),
            pw.SizedBox(height: 20),
            
            // Recommendations
            _buildSectionTitle('Recommendations'),
            _buildEnhancedRecommendations(assessment, flaggedDomains, overallScoreData),
          ],
        ),
      );

      // Page 3 removed - keeping PDF to 2 pages only

      // Get directory
      final directory = await getApplicationDocumentsDirectory();
      final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
      final fileName = 'Assessment_${anonymisedId}_$timestamp.pdf';
      final filePath = '${directory.path}/$fileName';
      
      final file = File(filePath);
      await file.writeAsBytes(await pdf.save());

      return filePath;
    } catch (e, stackTrace) {
      debugPrint('PDF Export Error: $e');
      debugPrint('Stack trace: $stackTrace');
      return null;
    }
  }

  pw.Widget _buildLogoHeader(String anonymisedId, pw.MemoryImage? engLogo, pw.MemoryImage? psyLogo) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(
        color: PdfColors.grey100,
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Column(
        children: [
          // Logos row
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              if (engLogo != null)
                pw.Image(engLogo, width: 60, height: 60)
              else
                pw.Container(
                  width: 60,
                  height: 60,
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(color: PdfColors.grey400),
                    borderRadius: pw.BorderRadius.circular(4),
                  ),
                  child: pw.Center(
                    child: pw.Text('SRM', 
                      style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold),
                      textAlign: pw.TextAlign.center,
                    ),
                  ),
                ),
              pw.Expanded(
                child: pw.Column(
                  children: [
                    pw.Text(
                      'DSM-5 Level 1 Cross-Cutting Symptom Measure',
                      style: pw.TextStyle(
                        fontSize: 16,
                        fontWeight: pw.FontWeight.bold,
                      ),
                      textAlign: pw.TextAlign.center,
                    ),
                    pw.SizedBox(height: 4),
                    pw.Text(
                      'Mental Capacity Assessment Report',
                      style: pw.TextStyle(fontSize: 12),
                      textAlign: pw.TextAlign.center,
                    ),
                  ],
                ),
              ),
              if (psyLogo != null)
                pw.Image(psyLogo, width: 60, height: 60)
              else
                pw.Container(
                  width: 60,
                  height: 60,
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(color: PdfColors.grey400),
                    borderRadius: pw.BorderRadius.circular(4),
                  ),
                  child: pw.Center(
                    child: pw.Text('PSYCH\nDEPT', 
                      style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold),
                      textAlign: pw.TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
          pw.SizedBox(height: 12),
          pw.Divider(color: PdfColors.grey400),
          pw.SizedBox(height: 8),
          // Anonymised ID and timestamp
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(
                'Anonymised ID: $anonymisedId',
                style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold),
              ),
              pw.Text(
                'Generated: ${DateFormat('dd MMM yyyy - HH:mm:ss').format(DateTime.now())}',
                style: pw.TextStyle(fontSize: 10),
              ),
            ],
          ),
        ],
      ),
    );
  }

  pw.Widget _buildPageFooter(pw.Context context, String anonymisedId) {
    return pw.Container(
      alignment: pw.Alignment.centerRight,
      margin: const pw.EdgeInsets.only(top: 10),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            'ID: $anonymisedId',
            style: pw.TextStyle(fontSize: 9, color: PdfColors.grey600),
          ),
          pw.Text(
            'Page ${context.pageNumber} of ${context.pagesCount}',
            style: pw.TextStyle(fontSize: 9, color: PdfColors.grey600),
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
          fontSize: 16,
          fontWeight: pw.FontWeight.bold,
          color: PdfColors.blue900,
        ),
      ),
    );
  }

  pw.Widget _buildAnonymisedAssessmentInfo(Assessment assessment, String anonymisedId) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey300),
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          _buildInfoRow('Anonymised ID', anonymisedId),
          _buildInfoRow(
            'Assessment Date',
            DateFormat('dd MMMM yyyy - HH:mm').format(assessment.assessmentDate),
          ),
          _buildInfoRow('Assessor Role', assessment.assessorRole),
          _buildInfoRow('Decision Context', assessment.decisionContext),
        ],
      ),
    );
  }

  pw.Widget _buildDomainScoresTable(Map<String, int> domainHighestScores, List<String> flaggedDomains) {
    // Define all 13 domains in order
    final domainOrder = [
      'I. Depression',
      'II. Anger',
      'III. Mania',
      'IV. Anxiety',
      'V. Somatic Symptoms',
      'VI. Suicidal Ideation',
      'VII. Psychosis',
      'VIII. Sleep Problems',
      'IX. Memory',
      'X. Repetitive Thoughts',
      'XI. Dissociation',
      'XII. Personality Functioning',
      'XIII. Substance Use',
    ];

    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey400),
      columnWidths: {
        0: const pw.FlexColumnWidth(3),
        1: const pw.FlexColumnWidth(1.5),
        2: const pw.FlexColumnWidth(1.5),
        3: const pw.FlexColumnWidth(2),
      },
      children: [
        // Header row
        pw.TableRow(
          decoration: pw.BoxDecoration(color: PdfColors.blue100),
          children: [
            _buildTableCell('Domain', isHeader: true),
            _buildTableCell('Highest\nScore', isHeader: true),
            _buildTableCell('Threshold', isHeader: true),
            _buildTableCell('Status', isHeader: true),
          ],
        ),
        // Data rows
        ...domainOrder.map((domain) {
          final score = domainHighestScores[domain] ?? 0;
          final isFlagged = flaggedDomains.contains(domain);
          final isCriticalDomain = domain.contains('Suicidal') || 
                                   domain.contains('Substance') || 
                                   domain.contains('Psychosis');
          final threshold = isCriticalDomain ? '>=1' : '>=2';
          
          return pw.TableRow(
            decoration: isFlagged 
                ? pw.BoxDecoration(color: PdfColors.red50)
                : null,
            children: [
              _buildTableCell(domain),
              _buildTableCell(score.toString(), 
                color: isFlagged ? PdfColors.red700 : null,
                bold: isFlagged,
              ),
              _buildTableCell(threshold),
              _buildTableCell(
                isFlagged ? '[!] FLAGGED' : 'Normal',
                color: isFlagged ? PdfColors.red700 : PdfColors.green700,
                bold: true,
              ),
            ],
          );
        }).toList(),
      ],
    );
  }

  pw.Widget _buildTableCell(String text, {bool isHeader = false, PdfColor? color, bool bold = false}) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(6),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontSize: isHeader ? 10 : 9,
          fontWeight: (isHeader || bold) ? pw.FontWeight.bold : pw.FontWeight.normal,
          color: color,
        ),
        textAlign: pw.TextAlign.center,
      ),
    );
  }

  pw.Widget _buildHighestDomainScore(Map<String, int> domainHighestScores) {
    String highestDomain = 'None';
    int highestScore = 0;
    
    domainHighestScores.forEach((domain, score) {
      if (score > highestScore) {
        highestScore = score;
        highestDomain = domain;
      }
    });

    final scoreLabels = ['None', 'Slight', 'Mild', 'Moderate', 'Severe'];
    final scoreLabel = highestScore < scoreLabels.length ? scoreLabels[highestScore] : 'Unknown';

    return pw.Container(
      padding: const pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(
        color: highestScore >= 2 ? PdfColors.orange100 : PdfColors.green100,
        borderRadius: pw.BorderRadius.circular(8),
        border: pw.Border.all(
          color: highestScore >= 2 ? PdfColors.orange400 : PdfColors.green400,
        ),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'HIGHEST DOMAIN SCORE',
            style: pw.TextStyle(
              fontSize: 12,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.grey700,
            ),
          ),
          pw.SizedBox(height: 8),
          pw.Row(
            children: [
              pw.Text(
                '$highestScore',
                style: pw.TextStyle(
                  fontSize: 28,
                  fontWeight: pw.FontWeight.bold,
                  color: highestScore >= 2 ? PdfColors.orange800 : PdfColors.green800,
                ),
              ),
              pw.SizedBox(width: 12),
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    scoreLabel,
                    style: pw.TextStyle(
                      fontSize: 14,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.Text(
                    highestDomain,
                    style: pw.TextStyle(fontSize: 11, color: PdfColors.grey600),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  pw.Widget _buildFlaggedDomainsAlert(List<String> flaggedDomains) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(
        color: PdfColors.red50,
        borderRadius: pw.BorderRadius.circular(8),
        border: pw.Border.all(color: PdfColors.red300),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            '[!] DOMAINS REQUIRING DETAILED ASSESSMENT',
            style: pw.TextStyle(
              fontSize: 12,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.red800,
            ),
          ),
          pw.SizedBox(height: 8),
          pw.Text(
            'Based on the scores, further detailed assessment is recommended for the following domains:',
            style: pw.TextStyle(fontSize: 10),
          ),
          pw.SizedBox(height: 8),
          ...flaggedDomains.map((domain) => pw.Padding(
            padding: const pw.EdgeInsets.only(left: 16, bottom: 4),
            child: pw.Row(
              children: [
                pw.Container(
                  width: 6,
                  height: 6,
                  decoration: pw.BoxDecoration(
                    color: PdfColors.red600,
                    shape: pw.BoxShape.circle,
                  ),
                ),
                pw.SizedBox(width: 8),
                pw.Text(domain, style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
              ],
            ),
          )).toList(),
          pw.SizedBox(height: 8),
          pw.Container(
            padding: const pw.EdgeInsets.all(8),
            decoration: pw.BoxDecoration(
              color: PdfColors.white,
              borderRadius: pw.BorderRadius.circular(4),
            ),
            child: pw.Text(
              'Note: For Substance Use, Suicidal Ideation, and Psychosis domains, a rating of slight (1) or greater indicates the need for detailed assessment. For other domains, a rating of mild (2) or greater suggests further inquiry.',
              style: pw.TextStyle(fontSize: 9, fontStyle: pw.FontStyle.italic),
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildCapacityDetermination(Assessment assessment, Map<String, dynamic> overallScoreData) {
    final percentage = overallScoreData['percentage'] as double;
    final determination = AssessmentQuestions.getCapacityDetermination(percentage);
    
    return pw.Container(
      padding: const pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey300),
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          _buildInfoRow('Overall Capacity', assessment.overallCapacity),
          pw.SizedBox(height: 8),
          _buildInfoRow('Symptom Severity', determination),
          _buildInfoRow(
            'Total Score', 
            '${overallScoreData['totalScore']} / ${overallScoreData['maxScore']} (${percentage.toStringAsFixed(1)}%)',
          ),
        ],
      ),
    );
  }

  pw.Widget _buildEnhancedRecommendations(Assessment assessment, List<String> flaggedDomains, Map<String, dynamic> overallScoreData) {
    final domainScores = overallScoreData['categoryScores'] as Map<String, int>? ?? {};
    final percentage = overallScoreData['percentage'] as double;
    final recommendations = AssessmentQuestions.getRecommendations(percentage, domainScores);
    
    return pw.Container(
      padding: const pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.blue200),
        borderRadius: pw.BorderRadius.circular(8),
        color: PdfColors.blue50,
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          if (assessment.recommendations.isNotEmpty) ...[
            pw.Text(
              'Clinical Recommendations:',
              style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 4),
            pw.Text(
              assessment.recommendations,
              style: const pw.TextStyle(fontSize: 10),
            ),
            pw.SizedBox(height: 12),
          ],
          pw.Text(
            'System-Generated Recommendations:',
            style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 4),
          ...recommendations.map((rec) => pw.Padding(
            padding: const pw.EdgeInsets.only(bottom: 4),
            child: pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text('- ', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
                pw.Expanded(child: pw.Text(rec, style: const pw.TextStyle(fontSize: 10))),
              ],
            ),
          )).toList(),
        ],
      ),
    );
  }

  pw.Widget _buildScoringInterpretation() {
    return pw.Container(
      padding: const pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey300),
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'DSM-5 Level 1 Cross-Cutting Symptom Measure Scoring',
            style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 12),
          pw.Text(
            'Each item on the measure is rated on a 5-point scale:',
            style: const pw.TextStyle(fontSize: 10),
          ),
          pw.SizedBox(height: 8),
          _buildScoreRow('0', 'None', 'Not at all'),
          _buildScoreRow('1', 'Slight', 'Rare, less than a day or two'),
          _buildScoreRow('2', 'Mild', 'Several days'),
          _buildScoreRow('3', 'Moderate', 'More than half the days'),
          _buildScoreRow('4', 'Severe', 'Nearly every day'),
          pw.SizedBox(height: 12),
          pw.Container(
            padding: const pw.EdgeInsets.all(10),
            decoration: pw.BoxDecoration(
              color: PdfColors.amber50,
              borderRadius: pw.BorderRadius.circular(4),
              border: pw.Border.all(color: PdfColors.amber200),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'Interpretation Guidelines:',
                  style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold),
                ),
                pw.SizedBox(height: 6),
                pw.Text(
                  '- A rating of mild (2) or greater on any item within a domain (except for Substance Use, Suicidal Ideation, and Psychosis) may serve as a guide for additional inquiry and follow-up to determine if a more detailed assessment for that domain is necessary.',
                  style: const pw.TextStyle(fontSize: 9),
                ),
                pw.SizedBox(height: 4),
                pw.Text(
                  '- For Substance Use, Suicidal Ideation, and Psychosis, a rating of slight (1) or greater on any item within the domain may serve as a guide for additional inquiry and follow-up to determine if a more detailed assessment is needed.',
                  style: const pw.TextStyle(fontSize: 9),
                ),
                pw.SizedBox(height: 4),
                pw.Text(
                  '- The DSM-5 Level 2 Cross-Cutting Symptom Measures may be used to provide more detailed information on the symptoms associated with some of the Level 1 domains.',
                  style: const pw.TextStyle(fontSize: 9),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildScoreRow(String score, String label, String description) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 2),
      child: pw.Row(
        children: [
          pw.Container(
            width: 24,
            height: 24,
            decoration: pw.BoxDecoration(
              color: PdfColors.blue100,
              borderRadius: pw.BorderRadius.circular(4),
            ),
            child: pw.Center(
              child: pw.Text(score, style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold)),
            ),
          ),
          pw.SizedBox(width: 8),
          pw.SizedBox(
            width: 60,
            child: pw.Text(label, style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
          ),
          pw.Text('- $description', style: const pw.TextStyle(fontSize: 10)),
        ],
      ),
    );
  }

  pw.Widget _buildDomainInterpretationTable() {
    return pw.Container(
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'Domain Flagging Thresholds:',
            style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 8),
          pw.Table(
            border: pw.TableBorder.all(color: PdfColors.grey400),
            columnWidths: {
              0: const pw.FlexColumnWidth(3),
              1: const pw.FlexColumnWidth(1.5),
              2: const pw.FlexColumnWidth(3),
            },
            children: [
              pw.TableRow(
                decoration: pw.BoxDecoration(color: PdfColors.blue100),
                children: [
                  _buildTableCell('Domain', isHeader: true),
                  _buildTableCell('Threshold', isHeader: true),
                  _buildTableCell('Interpretation', isHeader: true),
                ],
              ),
              _buildDomainRow('I. Depression', '>=2', 'Consider PHQ-9'),
              _buildDomainRow('II. Anger', '>=2', 'Assess anger management'),
              _buildDomainRow('III. Mania', '>=2', 'Screen for bipolar disorder'),
              _buildDomainRow('IV. Anxiety', '>=2', 'Consider GAD-7'),
              _buildDomainRow('V. Somatic Symptoms', '>=2', 'Evaluate somatic complaints'),
              _buildDomainRow('VI. Suicidal Ideation', '>=1', 'CRITICAL: Immediate risk assessment', highlight: true),
              _buildDomainRow('VII. Psychosis', '>=1', 'Psychiatric evaluation needed', highlight: true),
              _buildDomainRow('VIII. Sleep Problems', '>=2', 'Sleep hygiene assessment'),
              _buildDomainRow('IX. Memory', '>=2', 'Cognitive screening'),
              _buildDomainRow('X. Repetitive Thoughts', '>=2', 'OCD screening'),
              _buildDomainRow('XI. Dissociation', '>=2', 'Trauma assessment'),
              _buildDomainRow('XII. Personality', '>=2', 'Personality evaluation'),
              _buildDomainRow('XIII. Substance Use', '>=1', 'Substance use assessment', highlight: true),
            ],
          ),
        ],
      ),
    );
  }

  pw.TableRow _buildDomainRow(String domain, String threshold, String interpretation, {bool highlight = false}) {
    return pw.TableRow(
      decoration: highlight ? pw.BoxDecoration(color: PdfColors.red50) : null,
      children: [
        _buildTableCell(domain, bold: highlight),
        _buildTableCell(threshold, bold: highlight, color: highlight ? PdfColors.red700 : null),
        _buildTableCell(interpretation),
      ],
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
