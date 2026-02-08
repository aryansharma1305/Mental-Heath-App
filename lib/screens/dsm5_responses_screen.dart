import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:share_plus/share_plus.dart';
import 'package:intl/intl.dart';
import 'dart:convert';
import '../theme/app_theme.dart';
import '../services/auth_service.dart';
import '../services/assessment_questions.dart';
import '../models/assessment.dart';
import '../services/pdf_export_service.dart';

class DSM5ResponsesScreen extends StatefulWidget {
  const DSM5ResponsesScreen({super.key});

  @override
  State<DSM5ResponsesScreen> createState() => _DSM5ResponsesScreenState();
}

class _DSM5ResponsesScreenState extends State<DSM5ResponsesScreen> {
  final AuthService _authService = AuthService();
  final PdfExportService _pdfExportService = PdfExportService();
  final TextEditingController _searchController = TextEditingController();
  
  List<Map<String, dynamic>> _allAssessments = [];
  List<Map<String, dynamic>> _filteredAssessments = [];
  bool _isLoading = true;
  String? _currentDoctorId;
  String _sortBy = 'date_desc';
  String _filterSeverity = 'all';

  @override
  void initState() {
    super.initState();
    _loadAssessments();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadAssessments() async {
    setState(() => _isLoading = true);
    
    try {
      // Get current doctor ID
      final currentUser = await _authService.getCurrentUserModel();
      _currentDoctorId = currentUser?.id;

      // Load from SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      final assessmentsJson = prefs.getStringList('dsm5_assessments') ?? [];
      
      final List<Map<String, dynamic>> loadedAssessments = [];
      
      for (var json in assessmentsJson) {
        try {
          final data = jsonDecode(json) as Map<String, dynamic>;
          
          // Filter by doctor ID - show all for logged-in doctor
          final assessorId = data['assessor_id'] as String?;
          if (_currentDoctorId != null && 
              assessorId != null && 
              assessorId != _currentDoctorId &&
              assessorId != 'unknown') {
            continue; // Skip assessments from other doctors
          }
          
          // Calculate highest domain score for display
          final domainScores = data['domain_scores'] as Map<String, dynamic>? ?? {};
          int highestScore = 0;
          String highestDomain = '';
          domainScores.forEach((domain, score) {
            final scoreInt = score is int ? score : int.tryParse(score.toString()) ?? 0;
            if (scoreInt > highestScore) {
              highestScore = scoreInt;
              highestDomain = domain;
            }
          });
          data['_highest_score'] = highestScore;
          data['_highest_domain'] = highestDomain;
          
          loadedAssessments.add(data);
        } catch (e) {
          debugPrint('Error parsing assessment: $e');
        }
      }
      
      // Sort by date (newest first)
      loadedAssessments.sort((a, b) {
        final dateA = DateTime.tryParse(a['assessment_date'] ?? '') ?? DateTime.now();
        final dateB = DateTime.tryParse(b['assessment_date'] ?? '') ?? DateTime.now();
        return dateB.compareTo(dateA);
      });
      
      setState(() {
        _allAssessments = loadedAssessments;
        _filteredAssessments = loadedAssessments;
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

  void _applyFilters() {
    List<Map<String, dynamic>> filtered = List.from(_allAssessments);
    
    // Search filter
    final query = _searchController.text.toLowerCase();
    if (query.isNotEmpty) {
      filtered = filtered.where((a) {
        final patientId = (a['patient_id'] ?? '').toString().toLowerCase();
        final date = a['assessment_date'] ?? '';
        return patientId.contains(query) || date.contains(query);
      }).toList();
    }
    
    // Severity filter
    if (_filterSeverity != 'all') {
      filtered = filtered.where((a) {
        final severity = (a['severity'] ?? '').toString().toLowerCase();
        return severity.contains(_filterSeverity.toLowerCase());
      }).toList();
    }
    
    // Sort
    filtered.sort((a, b) {
      switch (_sortBy) {
        case 'date_asc':
          final dateA = DateTime.tryParse(a['assessment_date'] ?? '') ?? DateTime.now();
          final dateB = DateTime.tryParse(b['assessment_date'] ?? '') ?? DateTime.now();
          return dateA.compareTo(dateB);
        case 'score_desc':
          return (b['total_score'] ?? 0).compareTo(a['total_score'] ?? 0);
        case 'score_asc':
          return (a['total_score'] ?? 0).compareTo(b['total_score'] ?? 0);
        default: // date_desc
          final dateA = DateTime.tryParse(a['assessment_date'] ?? '') ?? DateTime.now();
          final dateB = DateTime.tryParse(b['assessment_date'] ?? '') ?? DateTime.now();
          return dateB.compareTo(dateA);
      }
    });
    
    setState(() => _filteredAssessments = filtered);
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
          child: Column(
            children: [
              _buildHeader(),
              _buildSearchAndFilter(),
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator(color: Colors.white))
                    : _filteredAssessments.isEmpty
                        ? _buildEmptyState()
                        : _buildAssessmentsList(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(Icons.arrow_back, color: Colors.white),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'My DSM-5 Assessments',
                  style: GoogleFonts.poppins(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                Text(
                  '${_filteredAssessments.length} of ${_allAssessments.length} assessments',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: _loadAssessments,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(Icons.refresh, color: Colors.white),
            ),
          ),
        ],
      ),
    ).animate().fadeIn().slideY(begin: -0.2, end: 0);
  }

  Widget _buildSearchAndFilter() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Search bar
          TextField(
            controller: _searchController,
            onChanged: (_) => _applyFilters(),
            decoration: InputDecoration(
              hintText: 'Search by Patient ID or Date...',
              hintStyle: GoogleFonts.inter(color: Colors.grey),
              prefixIcon: const Icon(Icons.search, color: Colors.grey),
              filled: true,
              fillColor: Colors.grey.shade100,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
          const SizedBox(height: 12),
          // Filter row
          Row(
            children: [
              // Severity filter
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _filterSeverity,
                      isExpanded: true,
                      icon: const Icon(Icons.filter_list, size: 18),
                      items: const [
                        DropdownMenuItem(value: 'all', child: Text('All Severity')),
                        DropdownMenuItem(value: 'minimal', child: Text('Minimal')),
                        DropdownMenuItem(value: 'mild', child: Text('Mild')),
                        DropdownMenuItem(value: 'moderate', child: Text('Moderate')),
                        DropdownMenuItem(value: 'severe', child: Text('Severe')),
                      ],
                      onChanged: (value) {
                        setState(() => _filterSeverity = value ?? 'all');
                        _applyFilters();
                      },
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              // Sort dropdown
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _sortBy,
                      isExpanded: true,
                      icon: const Icon(Icons.sort, size: 18),
                      items: const [
                        DropdownMenuItem(value: 'date_desc', child: Text('Newest First')),
                        DropdownMenuItem(value: 'date_asc', child: Text('Oldest First')),
                        DropdownMenuItem(value: 'score_desc', child: Text('Highest Score')),
                        DropdownMenuItem(value: 'score_asc', child: Text('Lowest Score')),
                      ],
                      onChanged: (value) {
                        setState(() => _sortBy = value ?? 'date_desc');
                        _applyFilters();
                      },
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    ).animate().fadeIn(delay: const Duration(milliseconds: 100)).slideY(begin: -0.1, end: 0);
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.assessment_outlined,
              size: 64,
              color: Colors.white.withOpacity(0.8),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            _allAssessments.isEmpty ? 'No assessments yet' : 'No matching assessments',
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _allAssessments.isEmpty 
                ? 'Complete a DSM-5 assessment to see results here'
                : 'Try adjusting your search or filters',
            style: GoogleFonts.inter(
              fontSize: 14,
              color: Colors.white70,
            ),
          ),
        ],
      ),
    ).animate().fadeIn().scale();
  }

  Widget _buildAssessmentsList() {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
      itemCount: _filteredAssessments.length,
      itemBuilder: (context, index) {
        return _buildAssessmentCard(_filteredAssessments[index], index)
            .animate()
            .fadeIn(delay: Duration(milliseconds: 50 * index))
            .slideX(begin: 0.1, end: 0);
      },
    );
  }

  Widget _buildAssessmentCard(Map<String, dynamic> assessment, int index) {
    final patientId = assessment['patient_id'] ?? 'Unknown';
    final dateStr = assessment['assessment_date'] ?? '';
    final date = DateTime.tryParse(dateStr) ?? DateTime.now();
    final totalScore = assessment['total_score'] ?? 0;
    final severity = assessment['severity'] ?? 'Unknown';
    final domainScores = assessment['domain_scores'] as Map<String, dynamic>? ?? {};
    final flaggedDomains = (assessment['flagged_domains'] as List<dynamic>?)?.cast<String>() ?? [];
    final highestScore = assessment['_highest_score'] ?? 0;
    final highestDomain = assessment['_highest_domain'] ?? '';
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header with gradient
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  _getSeverityColor(severity),
                  _getSeverityColor(severity).withOpacity(0.7),
                ],
              ),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Text(
                      '${index + 1}',
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: _getSeverityColor(severity),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'ID: $patientId',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        DateFormat('dd MMM yyyy • HH:mm').format(date),
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          color: Colors.white70,
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '$totalScore/92',
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      severity,
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          // Highest Domain Score - KEY FEATURE
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF667eea).withOpacity(0.08),
            ),
            child: Row(
              children: [
                Icon(Icons.star, color: const Color(0xFF667eea), size: 18),
                const SizedBox(width: 8),
                Text(
                  'Highest Domain Score: ',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF667eea),
                  ),
                ),
                Text(
                  '$highestScore',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF667eea),
                  ),
                ),
                Text(
                  ' (${_getShortDomainName(highestDomain)})',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: const Color(0xFF667eea).withOpacity(0.7),
                  ),
                ),
              ],
            ),
          ),
          
          // Body
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Domain scores grid
                if (domainScores.isNotEmpty) ...[
                  Text(
                    'Domain Scores (Threshold: ≥2, Critical Domains: ≥1):',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textDark,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _buildDomainScoresGrid(domainScores, flaggedDomains),
                ],
                
                // Flagged domains alert
                if (flaggedDomains.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.errorRed.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppTheme.errorRed.withOpacity(0.3)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.warning_amber, color: AppTheme.errorRed, size: 16),
                            const SizedBox(width: 6),
                            Text(
                              'Requires Follow-Up Assessment',
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.errorRed,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Wrap(
                          spacing: 4,
                          runSpacing: 4,
                          children: flaggedDomains.map((domain) => Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: AppTheme.errorRed,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              domain,
                              style: GoogleFonts.inter(
                                fontSize: 10,
                                fontWeight: FontWeight.w500,
                                color: Colors.white,
                              ),
                            ),
                          )).toList(),
                        ),
                      ],
                    ),
                  ),
                ],
                
                const SizedBox(height: 12),
                
                // Action buttons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _showDetailDialog(assessment),
                        icon: const Icon(Icons.visibility, size: 16),
                        label: const Text('Details'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _exportToPdf(assessment),
                        icon: const Icon(Icons.picture_as_pdf, size: 16),
                        label: const Text('PDF'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF667eea),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDomainScoresGrid(Map<String, dynamic> domainScores, List<String> flaggedDomains) {
    final entries = domainScores.entries.toList();
    
    return Wrap(
      spacing: 4,
      runSpacing: 4,
      children: entries.map((entry) {
        final scoreValue = entry.value is int ? entry.value : int.tryParse(entry.value.toString()) ?? 0;
        final isCritical = entry.key.contains('Suicidal') || 
                          entry.key.contains('Psychosis') || 
                          entry.key.contains('Substance');
        // Critical domains flag at ≥1, others at ≥2
        final isFlagged = isCritical ? scoreValue >= 1 : scoreValue >= 2;
        
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: isFlagged
                ? AppTheme.errorRed.withOpacity(0.15)
                : Colors.grey.shade100,
            borderRadius: BorderRadius.circular(6),
            border: isFlagged
                ? Border.all(color: AppTheme.errorRed.withOpacity(0.5))
                : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (isFlagged)
                Padding(
                  padding: const EdgeInsets.only(right: 3),
                  child: Icon(Icons.flag, size: 10, color: AppTheme.errorRed),
                ),
              Text(
                '${_getShortDomainName(entry.key)}: $scoreValue',
                style: GoogleFonts.inter(
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                  color: isFlagged ? AppTheme.errorRed : AppTheme.textDark,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  String _getShortDomainName(String fullName) {
    final parts = fullName.split('. ');
    return parts.length > 1 ? parts[1] : fullName;
  }

  Color _getSeverityColor(String severity) {
    if (severity.contains('Severe')) return AppTheme.errorRed;
    if (severity.contains('Moderate')) return AppTheme.warningOrange;
    if (severity.contains('Mild')) return const Color(0xFFFFB74D);
    return AppTheme.successGreen;
  }

  void _showDetailDialog(Map<String, dynamic> assessment) {
    final responses = assessment['responses'] as Map<String, dynamic>? ?? {};
    final questions = AssessmentQuestions.getStandardQuestions();
    final domainScores = assessment['domain_scores'] as Map<String, dynamic>? ?? {};
    final highestScore = assessment['_highest_score'] ?? 0;
    final highestDomain = assessment['_highest_domain'] ?? '';
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.9,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (context, scrollController) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
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
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Text(
                      'Assessment Details',
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
              ),
              
              // Highest Domain Score Header
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [const Color(0xFF667eea), const Color(0xFF764ba2)],
                  ),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  children: [
                    Icon(Icons.star, color: Colors.white, size: 22),
                    const SizedBox(width: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Highest Domain Score',
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            color: Colors.white70,
                          ),
                        ),
                        Text(
                          '$highestScore - ${_getShortDomainName(highestDomain)}',
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        'Total: ${assessment['total_score']}/92',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 8),
              const Divider(height: 1),
              
              // Interpretation note
              Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.blue.shade100),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.info_outline, color: Colors.blue.shade700, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Score ≥2 (Mild) suggests follow-up. For Substance Use, Suicidal Ideation & Psychosis, score ≥1 warrants detailed assessment.',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          color: Colors.blue.shade900,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              
              Expanded(
                child: ListView.builder(
                  controller: scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: questions.length,
                  itemBuilder: (context, index) {
                    final question = questions[index];
                    // Try multiple key formats
                    final qId = question.questionId;
                    String answer = 'Not answered';
                    int answerIndex = -1;
                    
                    // Try to find the response
                    if (responses.containsKey(qId)) {
                      final resp = responses[qId];
                      if (resp is String) {
                        answer = resp;
                        answerIndex = AssessmentQuestions.standardOptions.indexOf(resp);
                      } else if (resp is int) {
                        answerIndex = resp;
                        if (resp >= 0 && resp < AssessmentQuestions.standardOptions.length) {
                          answer = AssessmentQuestions.standardOptions[resp];
                        }
                      }
                    } else {
                      // Try matching by order index
                      for (var key in responses.keys) {
                        if (key.contains('${question.order}') || key == question.order.toString()) {
                          final resp = responses[key];
                          if (resp is String) {
                            answer = resp;
                            answerIndex = AssessmentQuestions.standardOptions.indexOf(resp);
                          } else if (resp is int) {
                            answerIndex = resp;
                            if (resp >= 0 && resp < AssessmentQuestions.standardOptions.length) {
                              answer = AssessmentQuestions.standardOptions[resp];
                            }
                          }
                          break;
                        }
                      }
                    }
                    
                    final isCritical = (question.category ?? '').contains('Suicidal') || 
                                      (question.category ?? '').contains('Psychosis') || 
                                      (question.category ?? '').contains('Substance');
                    final needsFollowUp = isCritical ? answerIndex >= 1 : answerIndex >= 2;
                    
                    return Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: needsFollowUp 
                            ? AppTheme.errorRed.withOpacity(0.08)
                            : Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: needsFollowUp 
                            ? Border.all(color: AppTheme.errorRed.withOpacity(0.3))
                            : null,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF667eea).withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  question.category ?? '',
                                  style: GoogleFonts.inter(
                                    fontSize: 9,
                                    fontWeight: FontWeight.w600,
                                    color: const Color(0xFF667eea),
                                  ),
                                ),
                              ),
                              const Spacer(),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: _getScoreColor(answerIndex),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  'Score: ${answerIndex >= 0 ? answerIndex : "?"}',
                                  style: GoogleFonts.inter(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Q${index + 1}: ${question.text}',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: AppTheme.textDark,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            answer,
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              color: AppTheme.textGrey,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                          if (needsFollowUp) ...[
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                Icon(Icons.flag, size: 12, color: AppTheme.errorRed),
                                const SizedBox(width: 4),
                                Text(
                                  isCritical 
                                      ? 'Critical domain - requires follow-up'
                                      : 'Consider detailed assessment',
                                  style: GoogleFonts.inter(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w500,
                                    color: AppTheme.errorRed,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getScoreColor(int score) {
    if (score <= 0) return AppTheme.successGreen;
    if (score == 1) return const Color(0xFF8BC34A);
    if (score == 2) return AppTheme.warningOrange;
    if (score == 3) return const Color(0xFFFF7043);
    return AppTheme.errorRed;
  }

  Future<void> _exportToPdf(Map<String, dynamic> assessmentData) async {
    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => Center(
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircularProgressIndicator(),
                const SizedBox(height: 16),
                Text('Generating PDF...', style: GoogleFonts.inter()),
              ],
            ),
          ),
        ),
      );

      // Convert to Assessment model for PDF service
      final assessment = Assessment(
        id: assessmentData['patient_id']?.hashCode,
        patientId: assessmentData['patient_id'] ?? 'unknown',
        patientName: 'Anonymised',
        assessorName: assessmentData['assessor_name'] ?? 'Unknown',
        assessorRole: 'Doctor',
        decisionContext: 'DSM-5 Level 1 Cross-Cutting Symptom Measure',
        assessmentDate: DateTime.tryParse(assessmentData['assessment_date'] ?? '') ?? DateTime.now(),
        responses: Map<String, dynamic>.from(assessmentData['responses'] ?? {}),
        overallCapacity: assessmentData['severity'] ?? 'Unknown',
        recommendations: _buildRecommendations(assessmentData),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        status: 'completed',
      );

      final filePath = await _pdfExportService.exportAssessmentToPdf(assessment);
      
      if (mounted) Navigator.pop(context);

      if (filePath != null) {
        // Share the PDF
        final result = await Share.shareXFiles(
          [XFile(filePath)], 
          text: 'DSM-5 Cross-Cutting Symptom Measure Report',
        );
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.check_circle, color: Colors.white),
                  const SizedBox(width: 8),
                  Text(result.status == ShareResultStatus.success 
                      ? 'PDF shared successfully!'
                      : 'PDF generated at: $filePath'),
                ],
              ),
              backgroundColor: AppTheme.successGreen,
              duration: const Duration(seconds: 4),
            ),
          );
        }
      } else {
        throw Exception('Failed to generate PDF');
      }
    } catch (e) {
      if (mounted) {
        Navigator.of(context, rootNavigator: true).pop();
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error exporting PDF: $e'),
            backgroundColor: AppTheme.errorRed,
          ),
        );
      }
    }
  }

  String _buildRecommendations(Map<String, dynamic> data) {
    final flaggedDomains = (data['flagged_domains'] as List<dynamic>?)?.cast<String>() ?? [];
    if (flaggedDomains.isEmpty) {
      return 'No domains flagged for immediate follow-up. Continue routine monitoring.';
    }
    
    final buffer = StringBuffer();
    buffer.writeln('The following domains require detailed Level 2 assessment:');
    for (var domain in flaggedDomains) {
      buffer.writeln('• $domain');
    }
    buffer.writeln('\nFor Substance Use, Suicidal Ideation, and Psychosis domains, even a score of 1 (Slight) warrants follow-up assessment per DSM-5 guidelines.');
    return buffer.toString();
  }
}
