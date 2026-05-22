import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:mental_capacity_assessment/l10n/app_localizations.dart';
import '../models/assessment.dart';
import '../models/user_role.dart';
import '../services/countersignature_service.dart';
import '../services/database_service.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';
import 'assessment_list_screen.dart';
import 'assessment_detail_screen.dart';
import 'countersignature_screen.dart';
import 'doctor_review_screen.dart';
import 'admin_panel_screen.dart';
import 'profile_screen.dart';
import 'analytics_screen.dart';
import 'help_support_screen.dart';
import 'dsm5_assessment_screen.dart';
import 'dsm5_responses_screen.dart';
import 'mhca_assessment_screen.dart';
import 'mhca_responses_screen.dart';
import 'patient_profiles_screen.dart';
import '../widgets/empty_state_widget.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  final DatabaseService _databaseService = DatabaseService();
  final AuthService _authService = AuthService();

  String _userName = '';
  UserRole _userRole = UserRole.patient;
  List<Assessment> _recentAssessments = [];
  List<Assessment> _pendingSignoffs = [];
  bool _isLoading = true;
  late AnimationController _animationController;
  late AnimationController _floatingController;
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    _floatingController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat(reverse: true);
    _loadUserInfo();
    _loadDashboardData();
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _floatingController.dispose();
    super.dispose();
  }

  Future<void> _loadUserInfo() async {
    final userModel = await _authService.getCurrentUserModel();
    setState(() {
      if (userModel != null) {
        _userName = userModel.fullName.split(' ')[0]; // First name only
        _userRole = userModel.role;
      } else {
        _userName = 'User';
        _userRole = UserRole.patient;
      }
    });
  }

  Future<void> _loadDashboardData() async {
    try {
      final assessments = await _databaseService.getAllAssessments();
      final pending = await CountersignatureService.instance.pendingSignOffs();
      setState(() {
        _recentAssessments = assessments.take(10).toList();
        _pendingSignoffs = pending;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _logout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.errorRed,
              foregroundColor: Colors.white,
            ),
            child: const Text('Logout'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _authService.logout();
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/login');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: SafeArea(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            // Custom App Bar
            SliverToBoxAdapter(child: _buildHeader()),

            // Main Content
            SliverToBoxAdapter(child: _buildMainContent(size)),
          ],
        ),
      ),
      bottomNavigationBar: _buildModernBottomNav(),
      floatingActionButton: _buildFloatingButton(),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          // Avatar with gradient border
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: AppTheme.pinkGradient,
              boxShadow: AppTheme.softShadow,
            ),
            padding: const EdgeInsets.all(3),
            child: CircleAvatar(
              radius: 28,
              backgroundColor: Colors.white,
              child: Text(
                _userName.isNotEmpty ? _userName[0].toUpperCase() : '?',
                style: GoogleFonts.poppins(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryColor,
                ),
              ),
            ),
          ).animate().scale(delay: 200.ms, duration: 600.ms),
          const SizedBox(width: 16),

          // Greeting
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Hello $_userName',
                  style: GoogleFonts.poppins(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textDark,
                  ),
                ).animate().fadeIn().slideX(begin: -0.2, end: 0),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        gradient: _userRole == UserRole.admin
                            ? AppTheme.purpleGradient
                            : _userRole.isHealthcareProfessional
                            ? AppTheme.blueGradient
                            : AppTheme.greenGradient,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        _userRole.displayName,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ).animate().fadeIn(delay: 200.ms),
              ],
            ),
          ),

          // Notification Icon
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: AppTheme.softShadow,
            ),
            child: IconButton(
              icon: Stack(
                children: [
                  const Icon(Icons.notifications_outlined, size: 24),
                  Positioned(
                    right: 0,
                    top: 0,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: AppTheme.errorRed,
                        shape: BoxShape.circle,
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 8,
                        minHeight: 8,
                      ),
                    ),
                  ),
                ],
              ),
              onPressed: () {
                // TODO: Show notifications
              },
            ),
          ).animate().scale(delay: 400.ms),
        ],
      ),
    );
  }

  Widget _buildMainContent(Size size) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),

          // Date Card with Floating Animation
          AnimatedBuilder(
            animation: _floatingController,
            builder: (context, child) {
              return Transform.translate(
                offset: Offset(0, 5 * _floatingController.value),
                child: child,
              );
            },
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: AppTheme.beigeGradient,
                borderRadius: BorderRadius.circular(24),
                boxShadow: AppTheme.softShadow,
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.9),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(
                      Icons.calendar_today_rounded,
                      color: AppTheme.accentColor,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${AppLocalizations.of(context)!.doctorWelcome},',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            color: Colors.white.withValues(alpha: 0.9),
                          ),
                        ),
                        Text(
                          DateFormat('EEEE, MMMM d, y').format(DateTime.now()),
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textDark,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.3, end: 0),
          ),

          const SizedBox(height: 32),

          // Quick Actions Header
          Text(
            'Quick Actions',
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppTheme.textDark,
            ),
          ).animate().fadeIn(delay: 400.ms),

          const SizedBox(height: 16),

          // Floating Action Cards
          _buildFloatingActionCards(),

          const SizedBox(height: 32),

          // Recent Activity Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                AppLocalizations.of(context)!.recentActivity,
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textDark,
                ),
              ),
              TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const AssessmentListScreen(),
                    ),
                  );
                },
                child: Text(
                  'View All',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.primaryColor,
                  ),
                ),
              ),
            ],
          ).animate().fadeIn(delay: 800.ms),

          const SizedBox(height: 16),

          // Pending countersignatures section
          if (_pendingSignoffs.isNotEmpty)
            _buildPendingSignoffSection(),

          const SizedBox(height: 16),

          // Recent Assessments
          _buildRecentAssessments(),

          const SizedBox(height: 100), // Space for FAB
        ],
      ),
    );
  }

  Widget _buildFloatingActionCards() {
    final actions = _getRoleBasedActions();

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 1.0,
      ),
      itemCount: actions.length > 6 ? 6 : actions.length,
      itemBuilder: (context, index) {
        final action = actions[index];
        final gradients = [
          AppTheme.pinkGradient,
          AppTheme.greenGradient,
          AppTheme.purpleGradient,
          AppTheme.blueGradient,
        ];

        return _FloatingActionCard(
          gradient: gradients[index % gradients.length],
          icon: action['icon'] as IconData,
          title: action['title'] as String,
          subtitle: action['subtitle'] as String,
          onTap: action['onTap'] as VoidCallback,
          delay: Duration(milliseconds: 500 + (index * 100)),
        );
      },
    );
  }

  List<Map<String, dynamic>> _getRoleBasedActions() {
    if (_userRole == UserRole.patient) {
      return [
        {
          'icon': Icons.psychology_outlined,
          'title': 'DSM-5 Assessment',
          'subtitle': 'Symptom screening',
          'onTap': () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const DSM5AssessmentScreen(),
              ),
            );
          },
        },
        {
          'icon': Icons.history,
          'title': 'My Assessments',
          'subtitle': 'View submitted',
          'onTap': () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const DSM5ResponsesScreen(),
              ),
            );
          },
        },
        {
          'icon': Icons.medical_information_outlined,
          'title': 'MHCA Assessment',
          'subtitle': 'Treatment capacity',
          'onTap': () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const MHCAAssessmentScreen(),
              ),
            );
          },
        },
        {
          'icon': Icons.folder_outlined,
          'title': 'MHCA Records',
          'subtitle': 'Past MHCA forms',
          'onTap': () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const MHCAResponsesScreen(),
              ),
            );
          },
        },
        {
          'icon': Icons.person_outline,
          'title': 'My Profile',
          'subtitle': 'Account details',
          'onTap': () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const ProfileScreen()),
            );
          },
        },
        {
          'icon': Icons.help_outline,
          'title': 'Help & Support',
          'subtitle': 'Get assistance',
          'onTap': () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const HelpSupportScreen(),
              ),
            );
          },
        },
      ];
    } else if (_userRole.canReviewAssessments) {
      return [
        {
          'icon': Icons.psychology_outlined,
          'title': 'Collect Data',
          'subtitle': 'DSM-5 Assessment',
          'onTap': () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const DSM5AssessmentScreen(),
              ),
            );
          },
        },
        {
          'icon': Icons.assessment_outlined,
          'title': 'View Responses',
          'subtitle': 'All collected data',
          'onTap': () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const DSM5ResponsesScreen(),
              ),
            );
          },
        },
        {
          'icon': Icons.medical_information_outlined,
          'title': 'MHCA Assessment',
          'subtitle': 'Treatment capacity',
          'onTap': () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const MHCAAssessmentScreen(),
              ),
            );
          },
        },
        {
          'icon': Icons.folder_outlined,
          'title': 'MHCA Records',
          'subtitle': 'Past MHCA forms',
          'onTap': () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const MHCAResponsesScreen(),
              ),
            );
          },
        },
        {
          'icon': Icons.folder_shared_outlined,
          'title': AppLocalizations.of(context)!.patientProfiles,
          'subtitle': AppLocalizations.of(context)!.patientProfilesDesc,
          'onTap': () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const PatientProfilesScreen(),
              ),
            );
          },
        },
        {
          'icon': Icons.analytics_outlined,
          'title': AppLocalizations.of(context)!.analytics,
          'subtitle': AppLocalizations.of(context)!.analyticsDesc,
          'onTap': () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const AnalyticsScreen()),
            );
          },
        },
        {
          'icon': Icons.person_outline,
          'title': 'My Profile',
          'subtitle': 'Account details',
          'onTap': () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const ProfileScreen()),
            );
          },
        },
      ];
    } else {
      // Admin
      return [
        {
          'icon': Icons.settings_outlined,
          'title': 'Admin Panel',
          'subtitle': 'Manage system',
          'onTap': () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const AdminPanelScreen()),
            );
          },
        },
        {
          'icon': Icons.quiz_outlined,
          'title': 'Questions',
          'subtitle': 'Manage questions',
          'onTap': () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const AdminPanelScreen()),
            );
          },
        },
        {
          'icon': Icons.medical_information_outlined,
          'title': 'MHCA Assessment',
          'subtitle': 'Treatment capacity',
          'onTap': () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const MHCAAssessmentScreen(),
              ),
            );
          },
        },
        {
          'icon': Icons.folder_outlined,
          'title': 'MHCA Records',
          'subtitle': 'Past MHCA forms',
          'onTap': () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const MHCAResponsesScreen(),
              ),
            );
          },
        },
        {
          'icon': Icons.rate_review_outlined,
          'title': 'Review',
          'subtitle': 'Check assessments',
          'onTap': () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const DoctorReviewScreen(),
              ),
            );
          },
        },
        {
          'icon': Icons.folder_shared_outlined,
          'title': AppLocalizations.of(context)!.patientProfiles,
          'subtitle': AppLocalizations.of(context)!.patientProfilesDesc,
          'onTap': () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const PatientProfilesScreen(),
              ),
            );
          },
        },
        {
          'icon': Icons.analytics_outlined,
          'title': AppLocalizations.of(context)!.analytics,
          'subtitle': AppLocalizations.of(context)!.analyticsDesc,
          'onTap': () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const AnalyticsScreen()),
            );
          },
        },
      ];
    }
  }

  Widget _buildPendingSignoffSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 4,
                height: 20,
                decoration: BoxDecoration(
                  color: Colors.orange.shade600,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                'Awaiting countersignature',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textDark,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.orange.shade100,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${_pendingSignoffs.length}',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Colors.orange.shade800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 110,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _pendingSignoffs.length,
              separatorBuilder: (_, idx) => const SizedBox(width: 12),
              itemBuilder: (_, i) {
                final a = _pendingSignoffs[i];
                return GestureDetector(
                  onTap: () async {
                    final done = await Navigator.push<bool>(
                      context,
                      MaterialPageRoute(
                        builder: (_) => CountersignatureScreen(assessment: a),
                      ),
                    );
                    if (done == true) _loadDashboardData();
                  },
                  child: Container(
                    width: 220,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                          color: Colors.orange.shade200, width: 1.5),
                      boxShadow: AppTheme.softShadow,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.pending_actions_rounded,
                                size: 16, color: Colors.orange.shade600),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                a.patientName,
                                style: GoogleFonts.inter(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 14,
                                  color: AppTheme.textDark,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          a.decisionContext,
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            color: Colors.grey.shade600,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Tap to countersign →',
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: Colors.orange.shade700,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 500.ms);
  }

  Widget _buildRecentAssessments() {
    if (_isLoading) {
      return Center(
        child: Container(
          padding: const EdgeInsets.all(40),
          child: const CircularProgressIndicator(),
        ),
      );
    }

    if (_recentAssessments.isEmpty) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: EmptyStateWidget(
          icon: Icons.assignment_outlined,
          iconColor: AppTheme.primaryColor,
          title: AppLocalizations.of(context)!.noAssessmentsYet,
          subtitle: AppLocalizations.of(context)!.createFirstAssessment,
          actionLabel: AppLocalizations.of(context)!.newAssessment,
          onAction: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const DSM5AssessmentScreen(),
            ),
          ),
        ),
      );
    }

    return Column(
      children: _recentAssessments.asMap().entries.map((entry) {
        final index = entry.key;
        final assessment = entry.value;
        return _AssessmentCard(
              assessment: assessment,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        AssessmentDetailScreen(assessmentId: assessment.id!),
                  ),
                );
              },
            )
            .animate()
            .fadeIn(delay: Duration(milliseconds: 900 + (index * 100)))
            .slideX(begin: 0.2, end: 0);
      }).toList(),
    );
  }

  Widget _buildFloatingButton() {
    return Container(
          margin: const EdgeInsets.only(top: 30),
          height: 64,
          width: 64,
          child: FloatingActionButton(
            elevation: 8,
            backgroundColor: AppTheme.textDark,
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [AppTheme.primaryColor, AppTheme.secondaryColor],
                ),
              ),
              child: const Icon(Icons.add, size: 32, color: Colors.white),
            ),
            onPressed: () {
              // Always go to DSM-5 Assessment for data collection
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const DSM5AssessmentScreen(),
                ),
              );
            },
          ),
        )
        .animate(onPlay: (controller) => controller.repeat(reverse: true))
        .shimmer(duration: 2000.ms, color: Colors.white.withValues(alpha: 0.3));
  }

  Widget _buildModernBottomNav() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _NavBarItem(
                icon: Icons.home_rounded,
                label: AppLocalizations.of(context)!.home,
                isSelected: _selectedIndex == 0,
                onTap: () => setState(() => _selectedIndex = 0),
              ),
              _NavBarItem(
                icon: Icons.list_alt_rounded,
                label: AppLocalizations.of(context)!.activity,
                isSelected: _selectedIndex == 1,
                onTap: () {
                  setState(() => _selectedIndex = 1);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const AssessmentListScreen(),
                    ),
                  );
                },
              ),
              const SizedBox(width: 64), // Space for FAB
              _NavBarItem(
                icon: Icons.person_rounded,
                label: AppLocalizations.of(context)!.profile,
                isSelected: _selectedIndex == 2,
                onTap: () {
                  setState(() => _selectedIndex = 2);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const ProfileScreen(),
                    ),
                  );
                },
              ),
              _NavBarItem(
                icon: Icons.logout_rounded,
                label: AppLocalizations.of(context)!.logout,
                isSelected: false,
                onTap: _logout,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Floating Action Card Widget
class _FloatingActionCard extends StatelessWidget {
  final LinearGradient gradient;
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final Duration delay;

  const _FloatingActionCard({
    required this.gradient,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    required this.delay,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Container(
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: BorderRadius.circular(24),
          boxShadow: AppTheme.softShadow,
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.9),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(icon, size: 28, color: AppTheme.textDark),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: Colors.white.withValues(alpha: 0.9),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ],
        ),
      ),
    ).animate().fadeIn(delay: delay).scale(delay: delay);
  }
}

// Assessment Card Widget
class _AssessmentCard extends StatelessWidget {
  final Assessment assessment;
  final VoidCallback onTap;

  const _AssessmentCard({required this.assessment, required this.onTap});

  Color _getStatusColor(String status) {
    if (status.toLowerCase().contains('has capacity')) {
      return AppTheme.successGreen;
    }
    if (status.toLowerCase().contains('lacks capacity')) {
      return AppTheme.errorRed;
    }
    return AppTheme.warningOrange;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: AppTheme.softShadow,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: _getStatusColor(
                      assessment.overallCapacity,
                    ).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(
                    Icons.person_outline,
                    color: _getStatusColor(assessment.overallCapacity),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        assessment.patientName,
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textDark,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        DateFormat(
                          'MMM d, y',
                        ).format(assessment.assessmentDate),
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: AppTheme.textGrey,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: _getStatusColor(
                      assessment.overallCapacity,
                    ).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.arrow_forward_ios,
                    size: 14,
                    color: _getStatusColor(assessment.overallCapacity),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// Bottom Nav Item
class _NavBarItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _NavBarItem({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? AppTheme.primaryColor.withValues(alpha: 0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isSelected ? AppTheme.primaryColor : AppTheme.textGrey,
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                color: isSelected ? AppTheme.primaryColor : AppTheme.textGrey,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
