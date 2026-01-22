import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import '../services/supabase_service.dart';
import '../services/auth_service.dart';
import '../services/statistics_service.dart';
import '../models/assessment.dart';
import '../theme/app_theme.dart';
import 'assessment_detail_screen.dart';

class DoctorAnalyticsScreen extends StatefulWidget {
  const DoctorAnalyticsScreen({super.key});

  @override
  State<DoctorAnalyticsScreen> createState() => _DoctorAnalyticsScreenState();
}

class _DoctorAnalyticsScreenState extends State<DoctorAnalyticsScreen> {
  final SupabaseService _supabaseService = SupabaseService();
  final AuthService _authService = AuthService();
  final StatisticsService _statisticsService = StatisticsService();
  
  Map<String, dynamic>? _performanceStats;
  List<Assessment> _myAssessments = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAnalytics();
  }

  Future<void> _loadAnalytics() async {
    setState(() => _isLoading = true);
    try {
      final user = await _authService.getCurrentUserModel();
      if (user != null && SupabaseService.isAvailable) {
        // Load performance stats
        _performanceStats = await _statisticsService.getAssessorPerformance(user.fullName);
        
        // Load all assessments by this doctor
        final allAssessments = await _supabaseService.getAllAssessments();
        _myAssessments = allAssessments
            .where((a) => a.assessorName == user.fullName)
            .toList();
        
        setState(() => _isLoading = false);
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Performance Analytics'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadAnalytics,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadAnalytics,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Summary Cards
                    _buildSummaryCards(),
                    const SizedBox(height: 24),
                    
                    // Capacity Distribution
                    _buildCapacityDistribution(),
                    const SizedBox(height: 24),
                    
                    // Monthly Performance
                    _buildMonthlyPerformance(),
                    const SizedBox(height: 24),
                    
                    // Recent Assessments
                    _buildRecentAssessments(),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildSummaryCards() {
    final total = _performanceStats?['totalAssessments'] ?? 0;
    final avgPerWeek = _performanceStats?['averagePerWeek'] ?? 0.0;
    final capacityDist = _performanceStats?['capacityDistribution'] as Map<String, int>? ?? {};
    
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.5,
      children: [
        _buildStatCard(
          'Total Reviewed',
          '$total',
          Icons.assessment,
          AppTheme.primaryColor,
        ),
        _buildStatCard(
          'Avg/Week',
          avgPerWeek.toStringAsFixed(1),
          Icons.trending_up,
          AppTheme.successGreen,
        ),
        _buildStatCard(
          'Has Capacity',
          '${capacityDist['Has capacity for this decision'] ?? 0}',
          Icons.check_circle,
          Colors.green,
        ),
        _buildStatCard(
          'Lacks Capacity',
          '${capacityDist['Lacks capacity for this decision'] ?? 0}',
          Icons.cancel,
          Colors.red,
        ),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [color.withOpacity(0.8), color],
          ),
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white, size: 28),
            const SizedBox(height: 8),
            Text(
              value,
              style: GoogleFonts.poppins(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            Text(
              title,
              style: GoogleFonts.inter(
                fontSize: 12,
                color: Colors.white.withOpacity(0.9),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCapacityDistribution() {
    final capacityDist = _performanceStats?['capacityDistribution'] as Map<String, int>? ?? {};
    if (capacityDist.isEmpty) {
      return const SizedBox.shrink();
    }

    final total = capacityDist.values.fold(0, (sum, count) => sum + count);
    final pieSections = capacityDist.entries.map((entry) {
      final percentage = (entry.value / total * 100);
      Color color;
      switch (entry.key.toLowerCase()) {
        case 'has capacity for this decision':
          color = Colors.green;
          break;
        case 'lacks capacity for this decision':
          color = Colors.red;
          break;
        case 'fluctuating capacity - reassessment needed':
          color = Colors.orange;
          break;
        default:
          color = Colors.grey;
      }

      return PieChartSectionData(
        value: entry.value.toDouble(),
        title: '${percentage.toStringAsFixed(1)}%',
        color: color,
        radius: 80,
        titleStyle: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      );
    }).toList();

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Capacity Distribution',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                SizedBox(
                  width: 200,
                  height: 200,
                  child: PieChart(
                    PieChartData(
                      sections: pieSections,
                      sectionsSpace: 2,
                      centerSpaceRadius: 40,
                    ),
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: capacityDist.entries.map((entry) {
                      Color color;
                      switch (entry.key.toLowerCase()) {
                        case 'has capacity for this decision':
                          color = Colors.green;
                          break;
                        case 'lacks capacity for this decision':
                          color = Colors.red;
                          break;
                        case 'fluctuating capacity - reassessment needed':
                          color = Colors.orange;
                          break;
                        default:
                          color = Colors.grey;
                      }
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Row(
                          children: [
                            Container(
                              width: 16,
                              height: 16,
                              decoration: BoxDecoration(
                                color: color,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                entry.key,
                                style: GoogleFonts.inter(fontSize: 12),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Text(
                              '${entry.value}',
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMonthlyPerformance() {
    // Group assessments by month
    final monthlyData = <String, int>{};
    for (var assessment in _myAssessments) {
      final monthKey = DateFormat('MMM y').format(assessment.assessmentDate);
      monthlyData[monthKey] = (monthlyData[monthKey] ?? 0) + 1;
    }

    if (monthlyData.isEmpty) {
      return const SizedBox.shrink();
    }

    final sortedMonths = monthlyData.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));
    final maxValue = sortedMonths.map((e) => e.value).reduce((a, b) => a > b ? a : b);

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Monthly Performance',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: 200,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: maxValue.toDouble() * 1.2,
                  barTouchData: BarTouchData(enabled: true),
                  titlesData: FlTitlesData(
                    show: true,
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          if (value.toInt() >= sortedMonths.length) {
                            return const Text('');
                          }
                          return Text(
                            sortedMonths[value.toInt()].key,
                            style: GoogleFonts.inter(fontSize: 10),
                          );
                        },
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 40,
                        getTitlesWidget: (value, meta) {
                          return Text(
                            value.toInt().toString(),
                            style: GoogleFonts.inter(fontSize: 10),
                          );
                        },
                      ),
                    ),
                    rightTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    topTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                  ),
                  gridData: FlGridData(show: false),
                  borderData: FlBorderData(show: false),
                  barGroups: sortedMonths.asMap().entries.map((entry) {
                    return BarChartGroupData(
                      x: entry.key,
                      barRods: [
                        BarChartRodData(
                          toY: entry.value.value.toDouble(),
                          color: AppTheme.primaryColor,
                          width: 20,
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(4),
                          ),
                        ),
                      ],
                    );
                  }).toList(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentAssessments() {
    final recent = _myAssessments
        .take(5)
        .toList()
      ..sort((a, b) => b.assessmentDate.compareTo(a.assessmentDate));

    if (recent.isEmpty) {
      return const SizedBox.shrink();
    }

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Recent Assessments',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ...recent.map((assessment) {
              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: _getCapacityColor(assessment.overallCapacity),
                  child: const Icon(Icons.person, color: Colors.white, size: 20),
                ),
                title: Text(
                  assessment.patientName,
                  style: GoogleFonts.inter(fontWeight: FontWeight.w500),
                ),
                subtitle: Text(
                  '${DateFormat('MMM d, y').format(assessment.assessmentDate)} • ${assessment.overallCapacity}',
                  style: GoogleFonts.inter(fontSize: 12),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => AssessmentDetailScreen(
                        assessmentId: assessment.id!,
                        allowReview: true,
                      ),
                    ),
                  );
                },
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  Color _getCapacityColor(String capacity) {
    switch (capacity.toLowerCase()) {
      case 'has capacity for this decision':
        return Colors.green;
      case 'lacks capacity for this decision':
        return Colors.red;
      case 'fluctuating capacity - reassessment needed':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }
}
