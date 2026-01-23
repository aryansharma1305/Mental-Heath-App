import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'dart:ui';
import '../theme/app_theme.dart';

class AnalyticsDashboard extends StatefulWidget {
  const AnalyticsDashboard({super.key});

  @override
  State<AnalyticsDashboard> createState() => _AnalyticsDashboardState();
}

class _AnalyticsDashboardState extends State<AnalyticsDashboard> with SingleTickerProviderStateMixin {
  bool _isLoading = true;
  List<Map<String, dynamic>> _assessments = [];
  Map<String, dynamic> _stats = {};
  String _doctorId = '';
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(duration: const Duration(seconds: 2), vsync: this)..repeat(reverse: true);
    _loadAnalytics();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _loadAnalytics() async {
    setState(() => _isLoading = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final doctorJson = prefs.getString('doctor_profile');
      if (doctorJson != null) {
        try {
          final data = jsonDecode(doctorJson);
          _doctorId = data['doctor_id'] ?? '';
        } catch (e) {}
      }

      final assessmentsJson = prefs.getStringList('capacity_assessments') ?? [];
      _assessments = assessmentsJson.map((json) {
        try { return jsonDecode(json) as Map<String, dynamic>; } catch (e) { return <String, dynamic>{}; }
      }).where((a) {
        if (a.isEmpty) return false;
        if (_doctorId.isEmpty) return true;
        return a['doctor_id'] == _doctorId;
      }).toList();

      _assessments.sort((a, b) {
        final dateA = DateTime.tryParse(a['assessment_date'] ?? '') ?? DateTime.now();
        final dateB = DateTime.tryParse(b['assessment_date'] ?? '') ?? DateTime.now();
        return dateB.compareTo(dateA);
      });
      _calculateStats();
    } catch (e) {}
    setState(() => _isLoading = false);
  }

  void _calculateStats() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final thisWeek = today.subtract(const Duration(days: 7));

    int weekCount = 0;
    double totalScore = 0;
    Map<String, int> domainTotals = {};
    int maleCount = 0, femaleCount = 0;
    Map<String, int> ageGroups = {'<20': 0, '20-40': 0, '40-60': 0, '60+': 0};
    int criticalCount = 0;

    for (var a in _assessments) {
      final date = DateTime.tryParse(a['assessment_date'] ?? '');
      if (date != null && date.isAfter(thisWeek)) weekCount++;
      totalScore += (a['score_percentage'] ?? 0.0) as double;

      final catScores = a['category_scores'] as Map<String, dynamic>? ?? {};
      catScores.forEach((k, v) {
        domainTotals[k] = (domainTotals[k] ?? 0) + (v as int);
      });

      if (a['patient_sex'] == 'Male') maleCount++;
      else if (a['patient_sex'] == 'Female') femaleCount++;

      final age = a['patient_age'] ?? 0;
      if (age < 20) ageGroups['<20'] = (ageGroups['<20'] ?? 0) + 1;
      else if (age < 40) ageGroups['20-40'] = (ageGroups['20-40'] ?? 0) + 1;
      else if (age < 60) ageGroups['40-60'] = (ageGroups['40-60'] ?? 0) + 1;
      else ageGroups['60+'] = (ageGroups['60+'] ?? 0) + 1;

      final domainsL2 = a['domains_needing_level2'] as List? ?? [];
      if (domainsL2.any((d) => d.toString().contains('Suicidal'))) criticalCount++;
    }

    _stats = {
      'total': _assessments.length,
      'thisWeek': weekCount,
      'avgScore': _assessments.isNotEmpty ? totalScore / _assessments.length : 0.0,
      'domainTotals': domainTotals,
      'maleCount': maleCount,
      'femaleCount': femaleCount,
      'ageGroups': ageGroups,
      'criticalCount': criticalCount,
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF667eea), Color(0xFF764ba2), Color(0xFFf093fb)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(),
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator(color: Colors.white))
                    : RefreshIndicator(onRefresh: _loadAnalytics, child: _buildContent()),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(12)),
                  child: const Icon(Icons.arrow_back, color: Colors.white),
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text('Analytics Dashboard', style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
          ),
          GestureDetector(
            onTap: _loadAnalytics,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(12)),
                  child: const Icon(Icons.refresh, color: Colors.white),
                ),
              ),
            ),
          ),
        ],
      ),
    ).animate().fadeIn().slideY(begin: -0.2, end: 0);
  }

  Widget _buildContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildOverviewCards(),
          const SizedBox(height: 20),
          _buildCriticalAlert(),
          const SizedBox(height: 20),
          _buildDomainChart(),
          const SizedBox(height: 20),
          _buildDemographics(),
          const SizedBox(height: 20),
          _buildRecentList(),
        ],
      ),
    );
  }

  Widget _buildOverviewCards() {
    return Row(
      children: [
        Expanded(child: _buildGlassCard('Total', '${_stats['total'] ?? 0}', Icons.assessment_outlined)),
        const SizedBox(width: 12),
        Expanded(child: _buildGlassCard('This Week', '${_stats['thisWeek'] ?? 0}', Icons.date_range)),
        const SizedBox(width: 12),
        Expanded(child: _buildGlassCard('Avg Score', '${((_stats['avgScore'] ?? 0.0) as double).toStringAsFixed(0)}%', Icons.trending_up)),
      ],
    ).animate().fadeIn(delay: 100.ms);
  }

  Widget _buildGlassCard(String label, String value, IconData icon) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [Colors.white.withOpacity(0.25), Colors.white.withOpacity(0.1)]),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withOpacity(0.2)),
          ),
          child: Column(
            children: [
              Icon(icon, color: Colors.white, size: 24),
              const SizedBox(height: 8),
              Text(value, style: GoogleFonts.poppins(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
              Text(label, style: GoogleFonts.inter(fontSize: 11, color: Colors.white70)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCriticalAlert() {
    final count = _stats['criticalCount'] ?? 0;
    if (count == 0) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.errorRed.withOpacity(0.3), width: 2),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: AppTheme.errorRed.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
            child: Icon(Icons.warning_amber_rounded, color: AppTheme.errorRed),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Critical Alerts', style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600, color: AppTheme.errorRed)),
                Text('$count patient(s) reported suicidal ideation', style: GoogleFonts.inter(fontSize: 12, color: AppTheme.textGrey)),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 150.ms).shake(delay: 500.ms, hz: 2, rotation: 0.02);
  }

  Widget _buildDomainChart() {
    final domains = _stats['domainTotals'] as Map<String, int>? ?? {};
    if (domains.isEmpty) return const SizedBox.shrink();
    final sorted = domains.entries.toList()..sort((a, b) => b.value.compareTo(a.value));

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [Color(0xFF667eea), Color(0xFF764ba2)]),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.bar_chart, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 12),
            Text('Domain Analysis', style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold)),
          ]),
          const SizedBox(height: 20),
          ...sorted.take(8).map((e) {
            final name = e.key.replaceAll(RegExp(r'^[IVXL]+\.\s*'), '');
            final maxVal = sorted.first.value.toDouble();
            final pct = maxVal > 0 ? e.value / maxVal : 0.0;
            final color = e.value > 10 ? AppTheme.errorRed : e.value > 5 ? AppTheme.warningOrange : AppTheme.successGreen;
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Expanded(child: Text(name, style: GoogleFonts.inter(fontSize: 12, color: AppTheme.textDark))),
                    Text('${e.value}', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: color)),
                  ]),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(value: pct, backgroundColor: color.withOpacity(0.1), valueColor: AlwaysStoppedAnimation(color), minHeight: 8),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    ).animate().fadeIn(delay: 200.ms);
  }

  Widget _buildDemographics() {
    final male = _stats['maleCount'] ?? 0;
    final female = _stats['femaleCount'] ?? 0;
    final ages = _stats['ageGroups'] as Map<String, int>? ?? {};

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Demographics', style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          Row(children: [
            Expanded(child: _buildDemoCard('Male', '$male', Icons.male, const Color(0xFF667eea))),
            const SizedBox(width: 12),
            Expanded(child: _buildDemoCard('Female', '$female', Icons.female, const Color(0xFFf093fb))),
          ]),
          const SizedBox(height: 16),
          Text('Age Distribution', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),
          Row(children: ages.entries.map((e) => Expanded(child: _buildAgeChip(e.key, e.value))).toList()),
        ],
      ),
    ).animate().fadeIn(delay: 250.ms);
  }

  Widget _buildDemoCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(16)),
      child: Row(children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(width: 10),
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
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [const Color(0xFF667eea).withOpacity(0.15), const Color(0xFF764ba2).withOpacity(0.1)]),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(children: [
        Text('$count', style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold)),
        Text(range, style: GoogleFonts.inter(fontSize: 10, color: AppTheme.textGrey)),
      ]),
    );
  }

  Widget _buildRecentList() {
    final recent = _assessments.take(5).toList();
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Text('Recent Assessments', style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold)),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [Color(0xFF667eea), Color(0xFF764ba2)]),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text('${recent.length}', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.white)),
            ),
          ]),
          const SizedBox(height: 14),
          if (recent.isEmpty)
            Center(child: Text('No assessments yet', style: GoogleFonts.inter(color: AppTheme.textGrey)))
          else
            ...recent.map((a) => _buildRecentItem(a)),
        ],
      ),
    ).animate().fadeIn(delay: 300.ms);
  }

  Widget _buildRecentItem(Map<String, dynamic> a) {
    final name = a['patient_name'] ?? 'Unknown';
    final score = (a['score_percentage'] ?? 0.0) as double;
    final date = DateTime.tryParse(a['assessment_date'] ?? '') ?? DateTime.now();
    Color getColor() => score < 25 ? AppTheme.successGreen : score < 50 ? AppTheme.warningOrange : AppTheme.errorRed;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: const Color(0xFFF8F9FA), borderRadius: BorderRadius.circular(14)),
      child: Row(children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(gradient: LinearGradient(colors: [getColor(), getColor().withOpacity(0.7)]), borderRadius: BorderRadius.circular(12)),
          child: Center(child: Text('${score.toInt()}', style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white))),
        ),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(name, style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600)),
          Text('${date.day}/${date.month}/${date.year}', style: GoogleFonts.inter(fontSize: 11, color: AppTheme.textGrey)),
        ])),
        Icon(Icons.chevron_right, color: AppTheme.textGrey, size: 20),
      ]),
    );
  }
}
