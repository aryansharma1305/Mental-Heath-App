import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'dart:convert';
import '../theme/app_theme.dart';

class MHCAResponsesScreen extends StatefulWidget {
  const MHCAResponsesScreen({super.key});

  @override
  State<MHCAResponsesScreen> createState() => _MHCAResponsesScreenState();
}

class _MHCAResponsesScreenState extends State<MHCAResponsesScreen> {
  List<Map<String, dynamic>> _assessments = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAssessments();
  }

  Future<void> _loadAssessments() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonList = prefs.getStringList('mhca_assessments') ?? [];

      final assessments = jsonList
          .map((json) => jsonDecode(json) as Map<String, dynamic>)
          .toList()
        ..sort((a, b) {
          final dateA = a['created_at'] as String? ?? '';
          final dateB = b['created_at'] as String? ?? '';
          return dateB.compareTo(dateA); // Newest first
        });

      setState(() {
        _assessments = assessments;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: AppTheme.softShadow,
            ),
            child: const Icon(Icons.arrow_back, color: AppTheme.textDark),
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'MHCA Records',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            color: AppTheme.textDark,
          ),
        ),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _assessments.isEmpty
              ? _buildEmptyState()
              : _buildAssessmentList(),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(40),
        margin: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: AppTheme.softShadow,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppTheme.skyBlue,
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.assignment_outlined,
                  size: 48, color: AppTheme.infoBlue),
            ),
            const SizedBox(height: 16),
            Text(
              'No MHCA Assessments Yet',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppTheme.textDark,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Completed MHCA treatment capacity assessments will appear here.',
              style: GoogleFonts.inter(
                fontSize: 14,
                color: AppTheme.textGrey,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ).animate().fadeIn().scale(),
    );
  }

  Widget _buildAssessmentList() {
    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: _assessments.length,
      itemBuilder: (context, index) {
        final assessment = _assessments[index];
        return _buildAssessmentCard(assessment, index);
      },
    );
  }

  Widget _buildAssessmentCard(Map<String, dynamic> assessment, int index) {
    final patientName =
        assessment['patient_name'] as String? ?? 'Unknown';
    final patientId = assessment['patient_id'] as String? ?? '';
    final purpose = assessment['purpose'] as String? ?? '';
    final determination = assessment['determination'] as String? ?? 'N/A';
    final createdAt = assessment['created_at'] as String?;

    String dateStr = '';
    if (createdAt != null) {
      try {
        final dt = DateTime.parse(createdAt);
        dateStr = DateFormat('MMM d, y • h:mm a').format(dt);
      } catch (_) {
        dateStr = createdAt;
      }
    }

    final hasCapacity = determination.contains('Has capacity');

    return GestureDetector(
      onTap: () => _showDetailDialog(assessment),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: AppTheme.softShadow,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    gradient: hasCapacity
                        ? AppTheme.greenGradient
                        : AppTheme.pinkGradient,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Center(
                    child: Icon(
                      hasCapacity
                          ? Icons.verified_outlined
                          : Icons.warning_amber_rounded,
                      color: Colors.white,
                      size: 22,
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        patientName,
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textDark,
                        ),
                      ),
                      if (patientId.isNotEmpty)
                        Text(
                          'ID: $patientId',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: AppTheme.textGrey,
                          ),
                        ),
                    ],
                  ),
                ),
                if (purpose.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppTheme.lavender,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      purpose,
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textDark,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: hasCapacity
                    ? AppTheme.successGreen.withOpacity(0.08)
                    : AppTheme.warningOrange.withOpacity(0.08),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(
                    hasCapacity ? Icons.check_circle : Icons.warning,
                    size: 16,
                    color: hasCapacity
                        ? AppTheme.successGreen
                        : AppTheme.warningOrange,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      determination,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: hasCapacity
                            ? AppTheme.successGreen
                            : AppTheme.warningOrange,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (dateStr.isNotEmpty) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.access_time, size: 14, color: AppTheme.textLight),
                  const SizedBox(width: 4),
                  Text(
                    dateStr,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: AppTheme.textLight,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ).animate()
          .fadeIn(delay: Duration(milliseconds: 100 * index))
          .slideX(begin: 0.1, end: 0),
    );
  }

  void _showDetailDialog(Map<String, dynamic> assessment) {
    final responses =
        assessment['responses'] as Map<String, dynamic>? ?? {};
    final explanations =
        assessment['explanations'] as Map<String, dynamic>? ?? {};

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.75,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            // Handle
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppTheme.dividerColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            // Title bar
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Text(
                    'Assessment Details',
                    style: GoogleFonts.poppins(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textDark,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            // Content
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  _detailRow('Patient',
                      assessment['patient_name'] as String? ?? ''),
                  _detailRow(
                      'ID', assessment['patient_id'] as String? ?? ''),
                  _detailRow('Age/Sex',
                      assessment['age_sex'] as String? ?? ''),
                  _detailRow('Place',
                      assessment['place_of_assessment'] as String? ?? ''),
                  _detailRow('Purpose',
                      assessment['purpose'] as String? ?? ''),
                  _detailRow('Diagnosis',
                      assessment['diagnosis'] as String? ?? ''),
                  _detailRow('Doctor',
                      assessment['doctor_name'] as String? ?? ''),
                  const Divider(height: 32),
                  Text('Responses',
                      style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textDark)),
                  const SizedBox(height: 12),
                  ...responses.entries.map((e) => _detailRow(
                      e.key.toUpperCase(),
                      e.value?.toString() ?? '')),
                  if (explanations.isNotEmpty) ...[
                    const Divider(height: 32),
                    Text('Explanations',
                        style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textDark)),
                    const SizedBox(height: 12),
                    ...explanations.entries
                        .where((e) =>
                            e.value != null &&
                            e.value.toString().isNotEmpty)
                        .map((e) => _detailRow(
                            e.key.toUpperCase(), e.value.toString())),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    if (value.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 13,
                color: AppTheme.textGrey,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.inter(
                fontSize: 13,
                color: AppTheme.textDark,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
