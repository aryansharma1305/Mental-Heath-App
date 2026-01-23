import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'dart:ui';
import '../theme/app_theme.dart';
import 'capacity_assessment_screen.dart';
import 'analytics_dashboard.dart';
import 'settings_screen.dart';

class AssessmentHomeScreen extends StatefulWidget {
  const AssessmentHomeScreen({super.key});

  @override
  State<AssessmentHomeScreen> createState() => _AssessmentHomeScreenState();
}

class _AssessmentHomeScreenState extends State<AssessmentHomeScreen> with TickerProviderStateMixin {
  int _totalAssessments = 0;
  int _todayAssessments = 0;
  int _weekAssessments = 0;
  String _doctorName = 'Doctor';
  String _doctorId = '';
  String _designation = '';
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);
    _loadData();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();
    
    final doctorJson = prefs.getString('doctor_profile');
    if (doctorJson != null) {
      try {
        final doctorData = jsonDecode(doctorJson);
        setState(() {
          _doctorName = doctorData['name'] ?? 'Doctor';
          _doctorId = doctorData['doctor_id'] ?? '';
          _designation = doctorData['designation'] ?? '';
        });
      } catch (e) {
        debugPrint('Error loading doctor profile: $e');
      }
    }
    
    final assessmentsJson = prefs.getStringList('capacity_assessments') ?? [];
    
    final today = DateTime.now();
    final todayStart = DateTime(today.year, today.month, today.day);
    final weekStart = todayStart.subtract(const Duration(days: 7));
    
    int todayCount = 0;
    int weekCount = 0;
    int totalCount = 0;
    
    for (var json in assessmentsJson) {
      try {
        final data = jsonDecode(json);
        final assessorId = data['doctor_id'] ?? '';
        if (_doctorId.isNotEmpty && assessorId != _doctorId) continue;
        
        totalCount++;
        final date = DateTime.parse(data['assessment_date'] ?? '');
        if (date.isAfter(todayStart)) todayCount++;
        if (date.isAfter(weekStart)) weekCount++;
      } catch (e) {}
    }
    
    setState(() {
      _totalAssessments = totalCount;
      _todayAssessments = todayCount;
      _weekAssessments = weekCount;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              const Color(0xFF667eea),
              const Color(0xFF764ba2),
              const Color(0xFFf093fb),
            ],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(),
                const SizedBox(height: 24),
                _buildStatsRow(),
                const SizedBox(height: 24),
                _buildMainAction(),
                const SizedBox(height: 16),
                _buildSecondaryActions(),
                const SizedBox(height: 24),
                _buildRecentActivity(),
                const SizedBox(height: 24),
                _buildQuickInfo(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        // Animated avatar
        AnimatedBuilder(
          animation: _pulseController,
          builder: (context, child) {
            return Container(
              width: 65,
              height: 65,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                gradient: LinearGradient(
                  colors: [Colors.white, Colors.white.withOpacity(0.8)],
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.white.withOpacity(0.3 + _pulseController.value * 0.2),
                    blurRadius: 15 + _pulseController.value * 5,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  _doctorName.isNotEmpty ? _doctorName[0].toUpperCase() : 'D',
                  style: GoogleFonts.poppins(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    foreground: Paint()
                      ..shader = LinearGradient(
                        colors: [const Color(0xFF667eea), const Color(0xFF764ba2)],
                      ).createShader(const Rect.fromLTWH(0, 0, 30, 30)),
                  ),
                ),
              ),
            );
          },
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Welcome back,', style: GoogleFonts.inter(fontSize: 13, color: Colors.white70)),
              Text(_doctorName, style: GoogleFonts.poppins(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)),
              if (_designation.isNotEmpty)
                Text(_designation, style: GoogleFonts.inter(fontSize: 12, color: Colors.white60)),
            ],
          ),
        ),
        _buildGlassButton(Icons.settings_outlined, () => _openSettings()),
      ],
    ).animate().fadeIn().slideX(begin: -0.1, end: 0);
  }

  Widget _buildGlassButton(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.white.withOpacity(0.2)),
            ),
            child: Icon(icon, color: Colors.white, size: 22),
          ),
        ),
      ),
    );
  }

  Widget _buildStatsRow() {
    return Row(
      children: [
        Expanded(child: _buildGlassStat('Today', '$_todayAssessments', Icons.today)),
        const SizedBox(width: 12),
        Expanded(child: _buildGlassStat('Week', '$_weekAssessments', Icons.date_range)),
        const SizedBox(width: 12),
        Expanded(child: _buildGlassStat('Total', '$_totalAssessments', Icons.assessment)),
      ],
    ).animate().fadeIn(delay: 100.ms).slideY(begin: 0.2, end: 0);
  }

  Widget _buildGlassStat(String label, String value, IconData icon) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white.withOpacity(0.25),
                Colors.white.withOpacity(0.1),
              ],
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withOpacity(0.2)),
          ),
          child: Column(
            children: [
              Icon(icon, color: Colors.white, size: 22),
              const SizedBox(height: 10),
              Text(value, style: GoogleFonts.poppins(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white)),
              Text(label, style: GoogleFonts.inter(fontSize: 12, color: Colors.white70)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMainAction() {
    return GestureDetector(
      onTap: _startNewAssessment,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 30, offset: const Offset(0, 15)),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 70,
              height: 70,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [const Color(0xFF667eea), const Color(0xFF764ba2)],
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [BoxShadow(color: const Color(0xFF667eea).withOpacity(0.4), blurRadius: 15, offset: const Offset(0, 8))],
              ),
              child: const Icon(Icons.add_rounded, color: Colors.white, size: 35),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('New Assessment', style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.textDark)),
                  const SizedBox(height: 4),
                  Text('DSM-5 Cross-Cutting Measure', style: GoogleFonts.inter(fontSize: 13, color: AppTheme.textGrey)),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF667eea).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text('23 Questions • 13 Domains', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: const Color(0xFF667eea))),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF5F5F5),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(Icons.arrow_forward, color: Color(0xFF667eea)),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(delay: 200.ms).scale(begin: const Offset(0.95, 0.95));
  }

  Widget _buildSecondaryActions() {
    return Row(
      children: [
        Expanded(child: _buildActionCard('History', '$_totalAssessments', Icons.history, const Color(0xFFf093fb), _viewPastAssessments)),
        const SizedBox(width: 12),
        Expanded(child: _buildActionCard('Analytics', 'Insights', Icons.analytics_outlined, const Color(0xFF667eea), _openAnalytics)),
      ],
    ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.1, end: 0);
  }

  Widget _buildActionCard(String title, String subtitle, IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 20, offset: const Offset(0, 8))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [color, color.withOpacity(0.7)]),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: Colors.white, size: 24),
            ),
            const SizedBox(height: 16),
            Text(title, style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600, color: AppTheme.textDark)),
            Text(subtitle, style: GoogleFonts.inter(fontSize: 13, color: AppTheme.textGrey)),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentActivity() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Colors.white.withOpacity(0.25), Colors.white.withOpacity(0.1)],
            ),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white.withOpacity(0.2)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Quick Stats', style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(12)),
                    child: Text('Live', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.white)),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  _buildMiniStat('Completion Rate', '100%', Icons.check_circle_outline),
                  const SizedBox(width: 16),
                  _buildMiniStat('Avg Time', '~5 min', Icons.timer_outlined),
                ],
              ),
            ],
          ),
        ),
      ),
    ).animate().fadeIn(delay: 400.ms);
  }

  Widget _buildMiniStat(String label, String value, IconData icon) {
    return Expanded(
      child: Row(
        children: [
          Icon(icon, color: Colors.white70, size: 20),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(value, style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white)),
              Text(label, style: GoogleFonts.inter(fontSize: 11, color: Colors.white60)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickInfo() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 15)],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF3E0),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.lightbulb_outline, color: Color(0xFFFF9800), size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Pro Tip', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.textDark)),
                Text('Score ≥2 (Mild) triggers Level 2 assessment recommendation', style: GoogleFonts.inter(fontSize: 11, color: AppTheme.textGrey)),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 500.ms);
  }

  void _startNewAssessment() async {
    final result = await Navigator.push(context, MaterialPageRoute(builder: (context) => const CapacityAssessmentScreen()));
    if (result == true) _loadData();
  }

  void _openAnalytics() {
    Navigator.push(context, MaterialPageRoute(builder: (context) => const AnalyticsDashboard())).then((_) => _loadData());
  }

  void _openSettings() {
    Navigator.push(context, MaterialPageRoute(builder: (context) => const SettingsScreen())).then((_) => _loadData());
  }

  void _viewPastAssessments() async {
    final prefs = await SharedPreferences.getInstance();
    final assessmentsJson = prefs.getStringList('capacity_assessments') ?? [];
    if (!mounted) return;
    showModalBottomSheet(context: context, isScrollControlled: true, backgroundColor: Colors.transparent, builder: (context) => _buildAssessmentsSheet(assessmentsJson));
  }

  Widget _buildAssessmentsSheet(List<String> assessmentsJson) {
    final assessments = assessmentsJson.map((json) { try { return jsonDecode(json) as Map<String, dynamic>; } catch (e) { return <String, dynamic>{}; } }).where((a) { if (a.isEmpty) return false; final assessorId = a['doctor_id'] ?? ''; if (_doctorId.isEmpty) return true; return assessorId == _doctorId; }).toList();
    assessments.sort((a, b) { final dateA = DateTime.tryParse(a['assessment_date'] ?? '') ?? DateTime.now(); final dateB = DateTime.tryParse(b['assessment_date'] ?? '') ?? DateTime.now(); return dateB.compareTo(dateA); });
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      child: Column(
        children: [
          Container(margin: const EdgeInsets.only(top: 12), width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2))),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(children: [
              Text('Assessment History', style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.textDark)),
              const Spacer(),
              Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6), decoration: BoxDecoration(gradient: LinearGradient(colors: [const Color(0xFF667eea), const Color(0xFF764ba2)]), borderRadius: BorderRadius.circular(20)), child: Text('${assessments.length}', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white))),
            ]),
          ),
          const Divider(height: 1),
          Expanded(
            child: assessments.isEmpty
                ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.assessment_outlined, size: 64, color: Colors.grey[300]), const SizedBox(height: 16), Text('No assessments yet', style: GoogleFonts.inter(fontSize: 16, color: AppTheme.textGrey))]))
                : ListView.separated(padding: const EdgeInsets.all(16), itemCount: assessments.length, separatorBuilder: (_, __) => const SizedBox(height: 12), itemBuilder: (context, index) => _buildAssessmentCard(assessments[index])),
          ),
        ],
      ),
    );
  }

  Widget _buildAssessmentCard(Map<String, dynamic> assessment) {
    final patientName = assessment['patient_name'] ?? 'Unknown';
    final score = (assessment['score_percentage'] ?? 0.0) as double;
    final date = DateTime.tryParse(assessment['assessment_date'] ?? '') ?? DateTime.now();
    Color getColor() => score < 25 ? AppTheme.successGreen : score < 50 ? AppTheme.warningOrange : AppTheme.errorRed;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppTheme.dividerColor), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10)]),
      child: Row(children: [
        Container(width: 50, height: 50, decoration: BoxDecoration(gradient: LinearGradient(colors: [getColor(), getColor().withOpacity(0.7)]), borderRadius: BorderRadius.circular(14)), child: Center(child: Text('${score.toInt()}%', style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white)))),
        const SizedBox(width: 14),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(patientName, style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w600, color: AppTheme.textDark)),
          Text('${date.day}/${date.month}/${date.year}', style: GoogleFonts.inter(fontSize: 12, color: AppTheme.textGrey)),
        ])),
        Icon(Icons.chevron_right, color: AppTheme.textGrey),
      ]),
    );
  }
}
