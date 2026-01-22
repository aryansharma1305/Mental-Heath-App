import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../theme/app_theme.dart';
import '../services/assessment_questions.dart';

class ResponsesViewerScreen extends StatefulWidget {
  const ResponsesViewerScreen({super.key});

  @override
  State<ResponsesViewerScreen> createState() => _ResponsesViewerScreenState();
}

class _ResponsesViewerScreenState extends State<ResponsesViewerScreen> {
  List<Map<String, dynamic>> _assessments = [];
  bool _isLoading = true;
  String _searchQuery = '';
  String _filterBy = 'All';

  @override
  void initState() {
    super.initState();
    _loadAssessments();
  }

  Future<void> _loadAssessments() async {
    setState(() => _isLoading = true);
    
    try {
      final prefs = await SharedPreferences.getInstance();
      final assessmentsJson = prefs.getStringList('dsm5_assessments') ?? [];
      
      final assessments = assessmentsJson
          .map((json) => jsonDecode(json) as Map<String, dynamic>)
          .toList();
      
      // Sort by date descending
      assessments.sort((a, b) {
        final dateA = DateTime.parse(a['created_at'] ?? a['assessment_date']);
        final dateB = DateTime.parse(b['created_at'] ?? b['assessment_date']);
        return dateB.compareTo(dateA);
      });
      
      setState(() {
        _assessments = assessments;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading assessments: $e')),
        );
      }
    }
  }

  List<Map<String, dynamic>> get _filteredAssessments {
    return _assessments.where((assessment) {
      // Search filter
      if (_searchQuery.isNotEmpty) {
        final name = (assessment['patient_name'] ?? '').toString().toLowerCase();
        if (!name.contains(_searchQuery.toLowerCase())) {
          return false;
        }
      }
      
      // Severity filter
      if (_filterBy != 'All') {
        final severity = assessment['severity'] ?? '';
        if (!severity.toString().toLowerCase().contains(_filterBy.toLowerCase())) {
          return false;
        }
      }
      
      return true;
    }).toList();
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
          'Assessment Responses',
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
            onPressed: _loadAssessments,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          // Search and Filter Section
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Search bar
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: AppTheme.softShadow,
                  ),
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: 'Search by patient name...',
                      prefixIcon: const Icon(Icons.search),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 16,
                      ),
                    ),
                    onChanged: (value) {
                      setState(() => _searchQuery = value);
                    },
                  ),
                ).animate().fadeIn().slideY(begin: -0.2, end: 0),
                
                const SizedBox(height: 12),
                
                // Filter chips
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _FilterChip(
                        label: 'All',
                        isSelected: _filterBy == 'All',
                        onTap: () => setState(() => _filterBy = 'All'),
                      ),
                      _FilterChip(
                        label: 'Minimal',
                        isSelected: _filterBy == 'Minimal',
                        color: AppTheme.successGreen,
                        onTap: () => setState(() => _filterBy = 'Minimal'),
                      ),
                      _FilterChip(
                        label: 'Mild',
                        isSelected: _filterBy == 'Mild',
                        color: AppTheme.infoBlue,
                        onTap: () => setState(() => _filterBy = 'Mild'),
                      ),
                      _FilterChip(
                        label: 'Moderate',
                        isSelected: _filterBy == 'Moderate',
                        color: AppTheme.warningOrange,
                        onTap: () => setState(() => _filterBy = 'Moderate'),
                      ),
                      _FilterChip(
                        label: 'Severe',
                        isSelected: _filterBy == 'Severe',
                        color: AppTheme.errorRed,
                        onTap: () => setState(() => _filterBy = 'Severe'),
                      ),
                    ],
                  ),
                ).animate().fadeIn(delay: 100.ms),
              ],
            ),
          ),
          
          // Stats summary
          if (_assessments.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: AppTheme.blueGradient,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: AppTheme.softShadow,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _StatItem(
                      label: 'Total',
                      value: '${_assessments.length}',
                      icon: Icons.assessment,
                    ),
                    _StatItem(
                      label: 'Today',
                      value: '${_getTodayCount()}',
                      icon: Icons.today,
                    ),
                    _StatItem(
                      label: 'This Week',
                      value: '${_getWeekCount()}',
                      icon: Icons.date_range,
                    ),
                  ],
                ),
              ).animate().fadeIn(delay: 200.ms).scale(),
            ),
          
          const SizedBox(height: 16),
          
          // Assessments list
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredAssessments.isEmpty
                    ? _buildEmptyState()
                    : _buildAssessmentsList(),
          ),
        ],
      ),
    );
  }

  int _getTodayCount() {
    final today = DateTime.now();
    return _assessments.where((a) {
      final date = DateTime.parse(a['created_at'] ?? a['assessment_date']);
      return date.year == today.year &&
          date.month == today.month &&
          date.day == today.day;
    }).length;
  }

  int _getWeekCount() {
    final now = DateTime.now();
    final weekAgo = now.subtract(const Duration(days: 7));
    return _assessments.where((a) {
      final date = DateTime.parse(a['created_at'] ?? a['assessment_date']);
      return date.isAfter(weekAgo);
    }).length;
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppTheme.softPink,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.assessment_outlined,
              size: 64,
              color: AppTheme.primaryColor,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            _searchQuery.isEmpty && _filterBy == 'All'
                ? 'No assessments yet'
                : 'No matching assessments',
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: AppTheme.textDark,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _searchQuery.isEmpty && _filterBy == 'All'
                ? 'Completed assessments will appear here'
                : 'Try adjusting your search or filters',
            style: GoogleFonts.inter(
              color: AppTheme.textGrey,
            ),
          ),
        ],
      ),
    ).animate().fadeIn().scale();
  }

  Widget _buildAssessmentsList() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: _filteredAssessments.length,
      itemBuilder: (context, index) {
        final assessment = _filteredAssessments[index];
        return _AssessmentCard(
          assessment: assessment,
          onTap: () => _showAssessmentDetails(assessment),
        ).animate().fadeIn(delay: Duration(milliseconds: 50 * index))
            .slideX(begin: 0.1, end: 0);
      },
    );
  }

  void _showAssessmentDetails(Map<String, dynamic> assessment) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _AssessmentDetailsSheet(assessment: assessment),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final Color? color;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.isSelected,
    this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: isSelected
                ? (color ?? AppTheme.primaryColor)
                : Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isSelected
                  ? (color ?? AppTheme.primaryColor)
                  : AppTheme.dividerColor,
            ),
            boxShadow: isSelected ? AppTheme.softShadow : null,
          ),
          child: Text(
            label,
            style: GoogleFonts.inter(
              fontWeight: FontWeight.w600,
              color: isSelected ? Colors.white : AppTheme.textGrey,
            ),
          ),
        ),
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _StatItem({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: Colors.white70, size: 20),
        const SizedBox(height: 4),
        Text(
          value,
          style: GoogleFonts.poppins(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 12,
            color: Colors.white70,
          ),
        ),
      ],
    );
  }
}

class _AssessmentCard extends StatelessWidget {
  final Map<String, dynamic> assessment;
  final VoidCallback onTap;

  const _AssessmentCard({
    required this.assessment,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final severity = assessment['severity'] ?? 'Unknown';
    final totalScore = assessment['total_score'] ?? 0;
    final patientName = assessment['patient_name'] ?? 'Unknown';
    final patientAge = assessment['patient_age'] ?? '';
    final patientSex = assessment['patient_sex'] ?? '';
    final dateStr = assessment['created_at'] ?? assessment['assessment_date'];
    final date = DateTime.parse(dateStr);
    
    Color severityColor;
    if (severity.toString().contains('Minimal')) {
      severityColor = AppTheme.successGreen;
    } else if (severity.toString().contains('Mild')) {
      severityColor = AppTheme.infoBlue;
    } else if (severity.toString().contains('Moderate')) {
      severityColor = AppTheme.warningOrange;
    } else {
      severityColor = AppTheme.errorRed;
    }

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: AppTheme.softShadow,
        ),
        child: Row(
          children: [
            // Score indicator
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: severityColor.withOpacity(0.15),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Center(
                child: Text(
                  '$totalScore',
                  style: GoogleFonts.poppins(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: severityColor,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            
            // Patient info
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
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.person_outline, size: 14, color: AppTheme.textGrey),
                      const SizedBox(width: 4),
                      Text(
                        '$patientAge yrs, $patientSex',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: AppTheme.textGrey,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Icon(Icons.calendar_today, size: 14, color: AppTheme.textGrey),
                      const SizedBox(width: 4),
                      Text(
                        DateFormat('MMM d, y').format(date),
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: AppTheme.textGrey,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            
            // Severity badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: severityColor.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                severity.toString().split(' ')[0],
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: severityColor,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Icon(Icons.chevron_right, color: AppTheme.textLight),
          ],
        ),
      ),
    );
  }
}

class _AssessmentDetailsSheet extends StatelessWidget {
  final Map<String, dynamic> assessment;

  const _AssessmentDetailsSheet({required this.assessment});

  @override
  Widget build(BuildContext context) {
    final severity = assessment['severity'] ?? 'Unknown';
    final totalScore = assessment['total_score'] ?? 0;
    final patientName = assessment['patient_name'] ?? 'Unknown';
    final patientAge = assessment['patient_age'] ?? '';
    final patientSex = assessment['patient_sex'] ?? '';
    final domainScores = assessment['domain_scores'] as Map<String, dynamic>? ?? {};
    final flaggedDomains = (assessment['flagged_domains'] as List<dynamic>?)?.cast<String>() ?? [];
    final responses = assessment['responses'] as Map<String, dynamic>? ?? {};
    final dateStr = assessment['created_at'] ?? assessment['assessment_date'];
    final date = DateTime.parse(dateStr);

    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppTheme.dividerColor,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          
          // Header
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: AppTheme.purpleGradient,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(Icons.assessment, color: Colors.white),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        patientName,
                        style: GoogleFonts.poppins(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textDark,
                        ),
                      ),
                      Text(
                        '$patientAge yrs, $patientSex • ${DateFormat('MMM d, y h:mm a').format(date)}',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          color: AppTheme.textGrey,
                        ),
                      ),
                    ],
                  ),
                ),
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
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Summary card
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: AppTheme.beigeGradient,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        Column(
                          children: [
                            Text(
                              '$totalScore',
                              style: GoogleFonts.poppins(
                                fontSize: 36,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.textDark,
                              ),
                            ),
                            Text(
                              'of 92',
                              style: GoogleFonts.inter(
                                color: AppTheme.textGrey,
                              ),
                            ),
                          ],
                        ),
                        Container(
                          width: 1,
                          height: 60,
                          color: AppTheme.dividerColor,
                        ),
                        Column(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: _getSeverityColor(severity).withOpacity(0.2),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                severity.toString().split(' ')[0],
                                style: GoogleFonts.inter(
                                  fontWeight: FontWeight.w600,
                                  color: _getSeverityColor(severity),
                                ),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Severity',
                              style: GoogleFonts.inter(
                                color: AppTheme.textGrey,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Flagged domains
                  if (flaggedDomains.isNotEmpty) ...[
                    Text(
                      'Domains Requiring Follow-Up',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textDark,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: flaggedDomains.map((domain) {
                        return Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: AppTheme.warningOrange.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: AppTheme.warningOrange.withOpacity(0.3),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.flag,
                                size: 16,
                                color: AppTheme.warningOrange,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                domain,
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.warningOrange,
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 24),
                  ],
                  
                  // Domain scores
                  Text(
                    'Domain Scores',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textDark,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ...domainScores.entries.map((entry) {
                    final domain = entry.key;
                    final score = entry.value as int;
                    final maxScore = _getMaxScoreForDomain(domain);
                    final progress = score / maxScore;
                    
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  domain,
                                  style: GoogleFonts.inter(
                                    fontSize: 13,
                                    color: AppTheme.textMedium,
                                  ),
                                ),
                              ),
                              Text(
                                '$score / $maxScore',
                                style: GoogleFonts.inter(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.textDark,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: progress,
                              backgroundColor: AppTheme.dividerColor,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                _getProgressColor(progress),
                              ),
                              minHeight: 6,
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                  
                  const SizedBox(height: 24),
                  
                  // Raw responses
                  ExpansionTile(
                    title: Text(
                      'Individual Responses',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textDark,
                      ),
                    ),
                    children: [
                      ...responses.entries.map((entry) {
                        final questionId = entry.key;
                        final score = entry.value;
                        return ListTile(
                          dense: true,
                          leading: CircleAvatar(
                            radius: 14,
                            backgroundColor: _getScoreColor(score as int),
                            child: Text(
                              '$score',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          title: Text(
                            'Question ${questionId.replaceAll(RegExp(r'[^0-9]'), '')}',
                            style: GoogleFonts.inter(fontSize: 13),
                          ),
                          trailing: Text(
                            AssessmentQuestions.standardOptions[score],
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              color: AppTheme.textGrey,
                            ),
                          ),
                        );
                      }),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getSeverityColor(String severity) {
    if (severity.contains('Minimal')) return AppTheme.successGreen;
    if (severity.contains('Mild')) return AppTheme.infoBlue;
    if (severity.contains('Moderate')) return AppTheme.warningOrange;
    return AppTheme.errorRed;
  }

  Color _getProgressColor(double progress) {
    if (progress <= 0.25) return AppTheme.successGreen;
    if (progress <= 0.5) return AppTheme.infoBlue;
    if (progress <= 0.75) return AppTheme.warningOrange;
    return AppTheme.errorRed;
  }

  Color _getScoreColor(int score) {
    switch (score) {
      case 0: return AppTheme.successGreen;
      case 1: return AppTheme.mintGreen;
      case 2: return AppTheme.infoBlue;
      case 3: return AppTheme.warningOrange;
      case 4: return AppTheme.errorRed;
      default: return AppTheme.textGrey;
    }
  }

  int _getMaxScoreForDomain(String domain) {
    // Questions per domain
    const domainQuestionCounts = {
      'I. Depression': 2,
      'II. Anger': 1,
      'III. Mania': 2,
      'IV. Anxiety': 3,
      'V. Somatic Symptoms': 2,
      'VI. Suicidal Ideation': 1,
      'VII. Psychosis': 2,
      'VIII. Sleep Problems': 1,
      'IX. Memory': 1,
      'X. Repetitive Thoughts & Behaviors': 2,
      'XI. Dissociation': 1,
      'XII. Personality Functioning': 2,
      'XIII. Substance Use': 3,
    };
    return (domainQuestionCounts[domain] ?? 1) * 4;
  }
}
