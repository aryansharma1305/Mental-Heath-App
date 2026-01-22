import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../theme/app_theme.dart';

class AnalyticsDashboard extends StatefulWidget {
  const AnalyticsDashboard({super.key});

  @override
  State<AnalyticsDashboard> createState() => _AnalyticsDashboardState();
}

class _AnalyticsDashboardState extends State<AnalyticsDashboard> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _assessments = [];
  Map<String, dynamic> _stats = {};

  @override
  void initState() {
    super.initState();
    _loadAnalytics();
  }

  Future<void> _loadAnalytics() async {
    setState(() => _isLoading = true);
    
    try {
      final prefs = await SharedPreferences.getInstance();
      final assessmentsJson = prefs.getStringList('capacity_assessments') ?? [];
      
      _assessments = assessmentsJson.map((json) {
        try {
          return jsonDecode(json) as Map<String, dynamic>;
        } catch (e) {
          return <String, dynamic>{};
        }
      }).where((a) => a.isNotEmpty).toList();
      
      _assessments.sort((a, b) {
        final dateA = DateTime.tryParse(a['assessment_date'] ?? '') ?? DateTime.now();
        final dateB = DateTime.tryParse(b['assessment_date'] ?? '') ?? DateTime.now();
        return dateB.compareTo(dateA);
      });
      
      _calculateStats();
      
    } catch (e) {
      debugPrint('Error loading analytics: $e');
    }
    
    setState(() => _isLoading = false);
  }

  void _calculateStats() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final thisWeek = today.subtract(const Duration(days: 7));
    final thisMonth = DateTime(now.year, now.month, 1);
    
    int todayCount = 0;
    int weekCount = 0;
    int monthCount = 0;
    int hasCapacity = 0;
    int lacksCapacity = 0;
    int fluctuating = 0;
    double totalScore = 0;
    Map<String, int> ageGroups = {'0-18': 0, '19-40': 0, '41-60': 0, '60+': 0};
    Map<String, int> genderBreakdown = {'Male': 0, 'Female': 0};
    
    for (var assessment in _assessments) {
      final date = DateTime.tryParse(assessment['assessment_date'] ?? '');
      if (date != null) {
        if (date.isAfter(today)) todayCount++;
        if (date.isAfter(thisWeek)) weekCount++;
        if (date.isAfter(thisMonth)) monthCount++;
      }
      
      final capacity = assessment['overall_capacity']?.toString() ?? '';
      if (capacity.contains('Has capacity')) {
        hasCapacity++;
      } else if (capacity.contains('Lacks capacity')) {
        lacksCapacity++;
      } else if (capacity.contains('Fluctuating')) {
        fluctuating++;
      }
      
      totalScore += (assessment['score_percentage'] ?? 0.0) as double;
      
      final age = assessment['patient_age'] ?? 0;
      if (age <= 18) ageGroups['0-18'] = (ageGroups['0-18'] ?? 0) + 1;
      else if (age <= 40) ageGroups['19-40'] = (ageGroups['19-40'] ?? 0) + 1;
      else if (age <= 60) ageGroups['41-60'] = (ageGroups['41-60'] ?? 0) + 1;
      else ageGroups['60+'] = (ageGroups['60+'] ?? 0) + 1;
      
      final sex = assessment['patient_sex']?.toString() ?? '';
      if (sex == 'Male') genderBreakdown['Male'] = (genderBreakdown['Male'] ?? 0) + 1;
      else if (sex == 'Female') genderBreakdown['Female'] = (genderBreakdown['Female'] ?? 0) + 1;
    }
    
    _stats = {
      'total': _assessments.length,
      'today': todayCount,
      'thisWeek': weekCount,
      'thisMonth': monthCount,
      'hasCapacity': hasCapacity,
      'lacksCapacity': lacksCapacity,
      'fluctuating': fluctuating,
      'avgScore': _assessments.isNotEmpty ? totalScore / _assessments.length : 0.0,
      'ageGroups': ageGroups,
      'genderBreakdown': genderBreakdown,
    };
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
          'Analytics',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            color: AppTheme.textDark,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: AppTheme.softShadow,
              ),
              child: const Icon(Icons.refresh, color: AppTheme.textDark),
            ),
            onPressed: _loadAnalytics,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadAnalytics,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSummaryCards(),
                    const SizedBox(height: 24),
                    _buildCapacityOutcomes(),
                    const SizedBox(height: 24),
                    _buildDemographics(),
                    const SizedBox(height: 24),
                    _buildRecentAssessments(),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildSummaryCards() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Overview', style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textDark)),
        const SizedBox(height: 16),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 1.4,
          children: [
            _buildStatCard('Total', '${_stats['total'] ?? 0}', Icons.assessment, AppTheme.primaryColor),
            _buildStatCard('This Week', '${_stats['thisWeek'] ?? 0}', Icons.date_range, AppTheme.infoBlue),
            _buildStatCard('Avg Score', '${(_stats['avgScore'] ?? 0.0).toStringAsFixed(0)}%', Icons.trending_up, AppTheme.successGreen),
            _buildStatCard('This Month', '${_stats['thisMonth'] ?? 0}', Icons.calendar_month, AppTheme.lavender),
          ],
        ).animate().fadeIn().slideY(begin: 0.1, end: 0),
      ],
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: AppTheme.softShadow),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(10)), child: Icon(icon, color: color, size: 20)),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(value, style: GoogleFonts.poppins(fontSize: 24, fontWeight: FontWeight.bold, color: AppTheme.textDark)),
            Text(label, style: GoogleFonts.inter(fontSize: 12, color: AppTheme.textGrey)),
          ]),
        ],
      ),
    );
  }

  Widget _buildCapacityOutcomes() {
    final hasCapacity = _stats['hasCapacity'] ?? 0;
    final lacksCapacity = _stats['lacksCapacity'] ?? 0;
    final fluctuating = _stats['fluctuating'] ?? 0;
    final total = _stats['total'] ?? 0;
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: AppTheme.softShadow),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Capacity Outcomes', style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textDark)),
          const SizedBox(height: 20),
          if (total == 0)
            Center(child: Padding(padding: const EdgeInsets.all(20), child: Text('No assessments yet', style: GoogleFonts.inter(color: AppTheme.textGrey))))
          else ...[
            _buildOutcomeBar('Has Capacity', hasCapacity, total, AppTheme.successGreen),
            const SizedBox(height: 16),
            _buildOutcomeBar('Lacks Capacity', lacksCapacity, total, AppTheme.errorRed),
            const SizedBox(height: 16),
            _buildOutcomeBar('Fluctuating', fluctuating, total, AppTheme.warningOrange),
          ],
        ],
      ),
    ).animate().fadeIn(delay: 100.ms).slideY(begin: 0.1, end: 0);
  }

  Widget _buildOutcomeBar(String label, int count, int total, Color color) {
    final percentage = total > 0 ? count / total : 0.0;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(label, style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w500, color: AppTheme.textDark)),
        Text('$count (${(percentage * 100).toStringAsFixed(0)}%)', style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: color)),
      ]),
      const SizedBox(height: 8),
      ClipRRect(borderRadius: BorderRadius.circular(4), child: LinearProgressIndicator(value: percentage, backgroundColor: color.withOpacity(0.1), valueColor: AlwaysStoppedAnimation<Color>(color), minHeight: 8)),
    ]);
  }

  Widget _buildDemographics() {
    final ageGroups = _stats['ageGroups'] as Map<String, int>? ?? {};
    final genderBreakdown = _stats['genderBreakdown'] as Map<String, int>? ?? {};
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: AppTheme.softShadow),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Demographics', style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textDark)),
        const SizedBox(height: 20),
        Row(children: [
          Expanded(child: _buildDemoCard('Male', '${genderBreakdown['Male'] ?? 0}', Icons.male, AppTheme.infoBlue)),
          const SizedBox(width: 12),
          Expanded(child: _buildDemoCard('Female', '${genderBreakdown['Female'] ?? 0}', Icons.female, AppTheme.lavender)),
        ]),
        const SizedBox(height: 20),
        Text('Age Distribution', style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: AppTheme.textDark)),
        const SizedBox(height: 12),
        Row(children: [
          Expanded(child: _buildAgeChip('0-18', ageGroups['0-18'] ?? 0)),
          Expanded(child: _buildAgeChip('19-40', ageGroups['19-40'] ?? 0)),
          Expanded(child: _buildAgeChip('41-60', ageGroups['41-60'] ?? 0)),
          Expanded(child: _buildAgeChip('60+', ageGroups['60+'] ?? 0)),
        ]),
      ]),
    ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.1, end: 0);
  }

  Widget _buildDemoCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(16)),
      child: Row(children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(width: 12),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(value, style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.textDark)),
          Text(label, style: GoogleFonts.inter(fontSize: 12, color: AppTheme.textGrey)),
        ]),
      ]),
    );
  }

  Widget _buildAgeChip(String range, int count) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(color: AppTheme.skyBlue.withOpacity(0.5), borderRadius: BorderRadius.circular(12)),
      child: Column(children: [
        Text('$count', style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textDark)),
        Text(range, style: GoogleFonts.inter(fontSize: 11, color: AppTheme.textGrey)),
      ]),
    );
  }

  Widget _buildRecentAssessments() {
    final recent = _assessments.take(5).toList();
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: AppTheme.softShadow),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text('Recent Assessments', style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textDark)),
          Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4), decoration: BoxDecoration(color: AppTheme.primaryColor.withOpacity(0.1), borderRadius: BorderRadius.circular(12)), child: Text('Last 5', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: AppTheme.primaryColor))),
        ]),
        const SizedBox(height: 16),
        if (recent.isEmpty)
          Center(child: Padding(padding: const EdgeInsets.all(20), child: Column(children: [Icon(Icons.assessment_outlined, size: 48, color: Colors.grey[300]), const SizedBox(height: 12), Text('No assessments yet', style: GoogleFonts.inter(color: AppTheme.textGrey))])))
        else
          ...recent.map((a) => _buildAssessmentItem(a)),
      ]),
    ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.1, end: 0);
  }

  Widget _buildAssessmentItem(Map<String, dynamic> assessment) {
    final name = assessment['patient_name'] ?? 'Unknown';
    final date = DateTime.tryParse(assessment['assessment_date'] ?? '');
    final capacity = assessment['overall_capacity']?.toString() ?? '';
    final score = assessment['score_percentage'] ?? 0.0;
    Color statusColor = capacity.contains('Has capacity') ? AppTheme.successGreen : capacity.contains('Lacks capacity') ? AppTheme.errorRed : AppTheme.warningOrange;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: AppTheme.backgroundColor, borderRadius: BorderRadius.circular(12)),
      child: Row(children: [
        Container(width: 40, height: 40, decoration: BoxDecoration(color: statusColor.withOpacity(0.1), borderRadius: BorderRadius.circular(10)), child: Center(child: Text(name.isNotEmpty ? name[0].toUpperCase() : '?', style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold, color: statusColor)))),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(name, style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: AppTheme.textDark)),
          Text(date != null ? '${date.day}/${date.month}/${date.year}' : 'Unknown', style: GoogleFonts.inter(fontSize: 12, color: AppTheme.textGrey)),
        ])),
        Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4), decoration: BoxDecoration(color: statusColor.withOpacity(0.1), borderRadius: BorderRadius.circular(8)), child: Text('${score.toStringAsFixed(0)}%', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: statusColor))),
      ]),
    );
  }
}
