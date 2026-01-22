import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../theme/app_theme.dart';
import 'capacity_assessment_screen.dart';
import 'analytics_dashboard.dart';

class AssessmentHomeScreen extends StatefulWidget {
  const AssessmentHomeScreen({super.key});

  @override
  State<AssessmentHomeScreen> createState() => _AssessmentHomeScreenState();
}

class _AssessmentHomeScreenState extends State<AssessmentHomeScreen> {
  int _totalAssessments = 0;
  int _todayAssessments = 0;
  int _weekAssessments = 0;
  String _doctorName = 'Doctor';
  String _designation = '';
  String _hospital = '';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();
    
    // Load doctor profile
    final doctorJson = prefs.getString('doctor_profile');
    if (doctorJson != null) {
      try {
        final doctorData = jsonDecode(doctorJson);
        setState(() {
          _doctorName = doctorData['name'] ?? 'Doctor';
          _designation = doctorData['designation'] ?? '';
          _hospital = doctorData['hospital'] ?? '';
        });
      } catch (e) {
        debugPrint('Error loading doctor profile: $e');
      }
    }
    
    // Load assessment stats
    final assessmentsJson = prefs.getStringList('capacity_assessments') ?? [];
    
    final today = DateTime.now();
    final todayStart = DateTime(today.year, today.month, today.day);
    final weekStart = todayStart.subtract(const Duration(days: 7));
    
    int todayCount = 0;
    int weekCount = 0;
    
    for (var json in assessmentsJson) {
      try {
        final data = jsonDecode(json);
        final date = DateTime.parse(data['assessment_date'] ?? '');
        if (date.isAfter(todayStart)) {
          todayCount++;
        }
        if (date.isAfter(weekStart)) {
          weekCount++;
        }
      } catch (e) {
        // Skip invalid entries
      }
    }
    
    setState(() {
      _totalAssessments = assessmentsJson.length;
      _todayAssessments = todayCount;
      _weekAssessments = weekCount;
    });
  }

  void _startNewAssessment() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const CapacityAssessmentScreen(),
      ),
    );
    
    if (result == true) {
      _loadData();
    }
  }

  void _openAnalytics() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const AnalyticsDashboard(),
      ),
    );
  }

  void _viewPastAssessments() async {
    final prefs = await SharedPreferences.getInstance();
    final assessmentsJson = prefs.getStringList('capacity_assessments') ?? [];
    
    if (!mounted) return;
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildAssessmentsSheet(assessmentsJson),
    );
  }

  Widget _buildAssessmentsSheet(List<String> assessmentsJson) {
    final assessments = assessmentsJson.map((json) {
      try {
        return jsonDecode(json) as Map<String, dynamic>;
      } catch (e) {
        return <String, dynamic>{};
      }
    }).where((a) => a.isNotEmpty).toList();
    
    assessments.sort((a, b) {
      final dateA = DateTime.tryParse(a['assessment_date'] ?? '') ?? DateTime.now();
      final dateB = DateTime.tryParse(b['assessment_date'] ?? '') ?? DateTime.now();
      return dateB.compareTo(dateA);
    });

    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Text(
                  'Assessment History',
                  style: GoogleFonts.poppins(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textDark,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${assessments.length} total',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: assessments.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.assessment_outlined, size: 64, color: Colors.grey[300]),
                        const SizedBox(height: 16),
                        Text('No assessments yet', style: GoogleFonts.inter(fontSize: 16, color: AppTheme.textGrey)),
                        const SizedBox(height: 8),
                        Text('Start your first assessment', style: GoogleFonts.inter(fontSize: 13, color: AppTheme.textGrey)),
                      ],
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: assessments.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) => _buildAssessmentCard(assessments[index]),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildAssessmentCard(Map<String, dynamic> assessment) {
    final date = DateTime.tryParse(assessment['assessment_date'] ?? '') ?? DateTime.now();
    final patientName = assessment['patient_name'] ?? 'Unknown';
    final patientAge = assessment['patient_age'] ?? 0;
    final patientSex = assessment['patient_sex'] ?? '';
    final capacity = assessment['overall_capacity'] ?? 'Not determined';
    final score = (assessment['score_percentage'] ?? 0.0) as double;
    
    Color statusColor;
    IconData statusIcon;
    
    if (capacity.toString().contains('Has capacity')) {
      statusColor = AppTheme.successGreen;
      statusIcon = Icons.check_circle;
    } else if (capacity.toString().contains('Lacks capacity')) {
      statusColor = AppTheme.errorRed;
      statusIcon = Icons.cancel;
    } else {
      statusColor = AppTheme.warningOrange;
      statusIcon = Icons.help;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.dividerColor),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(statusIcon, color: statusColor),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(patientName, style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600, color: AppTheme.textDark)),
                    const SizedBox(height: 4),
                    Text('$patientAge yrs • $patientSex • ${_formatDate(date)}', style: GoogleFonts.inter(fontSize: 12, color: AppTheme.textGrey)),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text('${score.toStringAsFixed(0)}%', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: statusColor)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.05),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(Icons.gavel, size: 16, color: statusColor),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    capacity.toString(),
                    style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w500, color: statusColor),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);
    
    if (diff.inDays == 0) {
      return 'Today ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    } else if (diff.inDays == 1) {
      return 'Yesterday';
    } else if (diff.inDays < 7) {
      return '${diff.inDays} days ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with doctor info
              Row(
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      gradient: AppTheme.primaryGradient,
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: [BoxShadow(color: AppTheme.primaryColor.withOpacity(0.3), blurRadius: 12, offset: const Offset(0, 4))],
                    ),
                    child: Center(
                      child: Text(
                        _doctorName.isNotEmpty ? _doctorName[0].toUpperCase() : 'D',
                        style: GoogleFonts.poppins(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Welcome back,', style: GoogleFonts.inter(fontSize: 13, color: AppTheme.textGrey)),
                        Text(_doctorName, style: GoogleFonts.poppins(fontSize: 22, fontWeight: FontWeight.bold, color: AppTheme.textDark), maxLines: 1, overflow: TextOverflow.ellipsis),
                        if (_designation.isNotEmpty)
                          Text(_designation, style: GoogleFonts.inter(fontSize: 12, color: AppTheme.textGrey)),
                      ],
                    ),
                  ),
                ],
              ).animate().fadeIn().slideX(begin: -0.1, end: 0),
              
              const SizedBox(height: 28),
              
              // Stats cards
              Row(
                children: [
                  Expanded(child: _buildStatCard('Today', '$_todayAssessments', Icons.today, AppTheme.skyBlue, AppTheme.infoBlue)),
                  const SizedBox(width: 12),
                  Expanded(child: _buildStatCard('Week', '$_weekAssessments', Icons.date_range, AppTheme.mintGreen, AppTheme.successGreen)),
                  const SizedBox(width: 12),
                  Expanded(child: _buildStatCard('Total', '$_totalAssessments', Icons.assessment, AppTheme.lavender.withOpacity(0.3), AppTheme.lavender)),
                ],
              ).animate().fadeIn(delay: 100.ms).slideY(begin: 0.1, end: 0),
              
              const SizedBox(height: 28),
              
              // Main action card - New Assessment
              GestureDetector(
                onTap: _startNewAssessment,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: AppTheme.primaryGradient,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [BoxShadow(color: AppTheme.primaryColor.withOpacity(0.3), blurRadius: 20, offset: const Offset(0, 10))],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(16)),
                            child: const Icon(Icons.add_circle_outline, color: Colors.white, size: 32),
                          ),
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
                            child: Row(
                              children: [
                                Text('Start', style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: AppTheme.primaryColor)),
                                const SizedBox(width: 4),
                                Icon(Icons.arrow_forward, size: 16, color: AppTheme.primaryColor),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Text('New Assessment', style: GoogleFonts.poppins(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
                      const SizedBox(height: 8),
                      Text('Conduct a Mental Capacity Assessment for a patient', style: GoogleFonts.inter(fontSize: 14, color: Colors.white.withOpacity(0.85))),
                    ],
                  ),
                ),
              ).animate().fadeIn(delay: 200.ms).scale(begin: const Offset(0.95, 0.95)),
              
              const SizedBox(height: 16),
              
              // Secondary actions row
              Row(
                children: [
                  // View History
                  Expanded(
                    child: GestureDetector(
                      onTap: _viewPastAssessments,
                      child: Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: AppTheme.dividerColor),
                          boxShadow: AppTheme.softShadow,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(color: AppTheme.lavender.withOpacity(0.2), borderRadius: BorderRadius.circular(12)),
                              child: Icon(Icons.history, color: AppTheme.lavender, size: 22),
                            ),
                            const SizedBox(height: 14),
                            Text('History', style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w600, color: AppTheme.textDark)),
                            const SizedBox(height: 4),
                            Text('$_totalAssessments records', style: GoogleFonts.inter(fontSize: 12, color: AppTheme.textGrey)),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Analytics
                  Expanded(
                    child: GestureDetector(
                      onTap: _openAnalytics,
                      child: Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: AppTheme.dividerColor),
                          boxShadow: AppTheme.softShadow,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(color: AppTheme.successGreen.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                              child: Icon(Icons.analytics_outlined, color: AppTheme.successGreen, size: 22),
                            ),
                            const SizedBox(height: 14),
                            Text('Analytics', style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w600, color: AppTheme.textDark)),
                            const SizedBox(height: 4),
                            Text('View insights', style: GoogleFonts.inter(fontSize: 12, color: AppTheme.textGrey)),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.1, end: 0),
              
              const SizedBox(height: 28),
              
              // Quick info
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.skyBlue.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppTheme.infoBlue.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: AppTheme.infoBlue),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Mental Capacity Assessment', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.textDark)),
                          const SizedBox(height: 4),
                          Text('13 questions evaluating understanding, retention, reasoning, and communication.', style: GoogleFonts.inter(fontSize: 12, color: AppTheme.textMedium, height: 1.4)),
                        ],
                      ),
                    ),
                  ],
                ),
              ).animate().fadeIn(delay: 400.ms),
              
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color bgColor, Color iconColor) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: AppTheme.softShadow,
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(height: 12),
          Text(value, style: GoogleFonts.poppins(fontSize: 22, fontWeight: FontWeight.bold, color: AppTheme.textDark)),
          Text(label, style: GoogleFonts.inter(fontSize: 11, color: AppTheme.textGrey)),
        ],
      ),
    );
  }
}
