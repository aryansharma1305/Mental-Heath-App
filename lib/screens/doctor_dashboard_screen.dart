import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../services/supabase_service.dart';
import '../services/auth_service.dart';
import '../services/statistics_service.dart';
import '../models/assessment.dart';
import '../models/user.dart' as app_models;
import '../theme/app_theme.dart';
import 'doctor_review_screen.dart';
import 'assessment_list_screen.dart';
import 'assessment_detail_screen.dart';
import 'analytics_screen.dart';
import 'patient_management_screen.dart';
import 'doctor_analytics_screen.dart';
import 'assessment_templates_screen.dart';
import 'quick_notes_screen.dart';

class DoctorDashboardScreen extends StatefulWidget {
  const DoctorDashboardScreen({super.key});

  @override
  State<DoctorDashboardScreen> createState() => _DoctorDashboardScreenState();
}

class _DoctorDashboardScreenState extends State<DoctorDashboardScreen> {
  final SupabaseService _supabaseService = SupabaseService();
  final AuthService _authService = AuthService();
  final StatisticsService _statisticsService = StatisticsService();
  
  app_models.User? _currentUser;
  List<Assessment> _pendingAssessments = [];
  List<Assessment> _recentAssessments = [];
  Map<String, dynamic>? _doctorStats;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    setState(() => _isLoading = true);
    try {
      final user = await _authService.getCurrentUserModel();
      final userId = await _authService.getCurrentUserId();
      
      if (SupabaseService.isAvailable && user != null && userId != null) {
        // Load assessments created by this doctor only
        final doctorAssessments = await _supabaseService.getAssessmentsByAssessorId(userId);
        
        _pendingAssessments = doctorAssessments
            .where((a) => a.status == 'pending')
            .take(5)
            .toList();
        
        // Load recent assessments by this doctor
        _recentAssessments = doctorAssessments
            .where((a) => a.status != 'pending')
            .take(5)
            .toList();
        
        // Load doctor stats
        if (user.fullName.isNotEmpty) {
          _doctorStats = await _statisticsService.getAssessorPerformance(user.fullName);
        }
        
        setState(() {
          _currentUser = user;
          _isLoading = false;
        });
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
        title: Text(
          'Doctor Dashboard',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadDashboardData,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadDashboardData,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Welcome Section
                    _buildWelcomeSection(),
                    const SizedBox(height: 24),
                    
                    // Quick Stats
                    _buildQuickStats(),
                    const SizedBox(height: 24),
                    
                    // Quick Actions
                    _buildQuickActions(),
                    const SizedBox(height: 24),
                    
                    // Pending Reviews
                    if (_pendingAssessments.isNotEmpty) ...[
                      _buildSectionHeader('Pending Reviews', Icons.pending_actions),
                      const SizedBox(height: 12),
                      _buildPendingAssessmentsList(),
                      const SizedBox(height: 24),
                    ],
                    
                    // Recent Activity
                    if (_recentAssessments.isNotEmpty) ...[
                      _buildSectionHeader('Recent Activity', Icons.history),
                      const SizedBox(height: 12),
                      _buildRecentAssessmentsList(),
                    ],
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildWelcomeSection() {
    final greeting = _getGreeting();
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppTheme.primaryColor,
              AppTheme.primaryColor.withOpacity(0.7),
            ],
          ),
        ),
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            CircleAvatar(
              radius: 30,
              backgroundColor: Colors.white,
              child: Text(
                _currentUser?.fullName.substring(0, 1).toUpperCase() ?? 'D',
                style: GoogleFonts.poppins(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryColor,
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    greeting,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: Colors.white.withOpacity(0.9),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _currentUser?.fullName ?? 'Doctor',
                    style: GoogleFonts.poppins(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  if (_currentUser?.department != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      _currentUser!.department!,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: Colors.white.withOpacity(0.8),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning';
    if (hour < 17) return 'Good Afternoon';
    return 'Good Evening';
  }

  Widget _buildQuickStats() {
    final totalReviewed = _doctorStats?['totalAssessments'] ?? 0;
    final avgPerWeek = _doctorStats?['averagePerWeek'] ?? 0.0;
    
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            'Pending',
            '${_pendingAssessments.length}',
            Icons.pending,
            Colors.orange,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            'Reviewed',
            '$totalReviewed',
            Icons.verified,
            Colors.green,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            'Avg/Week',
            avgPerWeek.toStringAsFixed(1),
            Icons.trending_up,
            Colors.blue,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: color.withOpacity(0.1),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 8),
            Text(
              value,
              style: GoogleFonts.poppins(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 12,
                color: Colors.grey[700],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('Quick Actions', Icons.flash_on),
        const SizedBox(height: 12),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 1.5,
          children: [
            _buildActionCard(
              'Review Assessments',
              Icons.rate_review,
              AppTheme.primaryColor,
              () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const DoctorReviewScreen(),
                  ),
                );
              },
            ),
            _buildActionCard(
              'All Assessments',
              Icons.list_alt,
              AppTheme.infoBlue,
              () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const AssessmentListScreen(),
                  ),
                );
              },
            ),
            _buildActionCard(
              'Patient Management',
              Icons.people,
              AppTheme.successGreen,
              () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const PatientManagementScreen(),
                  ),
                );
              },
            ),
            _buildActionCard(
              'My Analytics',
              Icons.analytics,
              AppTheme.warningOrange,
              () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const DoctorAnalyticsScreen(),
                  ),
                );
              },
            ),
            _buildActionCard(
              'Templates',
              Icons.description,
              Colors.purple,
              () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const AssessmentTemplatesScreen(),
                  ),
                );
              },
            ),
            _buildActionCard(
              'Quick Notes',
              Icons.note_add,
              Colors.teal,
              () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const QuickNotesScreen(),
                  ),
                );
              },
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionCard(
    String title,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Card(
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
              Icon(icon, color: Colors.white, size: 32),
              const SizedBox(height: 8),
              Text(
                title,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: AppTheme.primaryColor, size: 20),
        const SizedBox(width: 8),
        Text(
          title,
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildPendingAssessmentsList() {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _pendingAssessments.length,
      itemBuilder: (context, index) {
        final assessment = _pendingAssessments[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          elevation: 1,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: Colors.orange,
              child: const Icon(Icons.pending, color: Colors.white),
            ),
            title: Text(
              assessment.patientName,
              style: GoogleFonts.inter(fontWeight: FontWeight.w600),
            ),
            subtitle: Text(
              DateFormat('MMM d, y • h:mm a').format(assessment.assessmentDate),
              style: GoogleFonts.inter(fontSize: 12),
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
              ).then((_) => _loadDashboardData());
            },
          ),
        );
      },
    );
  }

  Widget _buildRecentAssessmentsList() {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _recentAssessments.length,
      itemBuilder: (context, index) {
        final assessment = _recentAssessments[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          elevation: 1,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: _getStatusColor(assessment.status),
              child: const Icon(Icons.check, color: Colors.white),
            ),
            title: Text(
              assessment.patientName,
              style: GoogleFonts.inter(fontWeight: FontWeight.w600),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${_getStatusLabel(assessment.status)} • ${DateFormat('MMM d, y').format(assessment.assessmentDate)}',
                  style: GoogleFonts.inter(fontSize: 12),
                ),
              ],
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
          ),
        );
      },
    );
  }

  Color _getStatusColor(String? status) {
    switch (status) {
      case 'reviewed':
        return Colors.blue;
      case 'completed':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  String _getStatusLabel(String? status) {
    switch (status) {
      case 'reviewed':
        return 'Reviewed';
      case 'completed':
        return 'Completed';
      default:
        return 'Unknown';
    }
  }
}
