import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:share_plus/share_plus.dart';
import 'package:intl/intl.dart';
import 'dart:convert';
import '../theme/app_theme.dart';
import '../services/auth_service.dart';
import '../services/assessment_questions.dart';
import '../models/assessment.dart';
import '../services/database_service.dart';
import '../services/pdf_export_service.dart';

class DSM5ResponsesScreen extends StatefulWidget {
  const DSM5ResponsesScreen({super.key});

  @override
  State<DSM5ResponsesScreen> createState() => _DSM5ResponsesScreenState();
}

class _DSM5ResponsesScreenState extends State<DSM5ResponsesScreen> {
  static const Color _ink = Color(0xFF172033);
  static const Color _muted = Color(0xFF697386);
  static const Color _surface = Color(0xFFF7F9FC);
  static const Color _panel = Color(0xFFFFFFFF);
  static const Color _teal = Color(0xFF0F9F8A);
  static const Color _blue = Color(0xFF3568D4);
  static const Color _rose = Color(0xFFE25563);

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
    if (mounted) setState(() => _isLoading = true);

    try {
      // Get current doctor ID
      final currentUser = await _authService.getCurrentUserModel();
      _currentDoctorId = currentUser?.id;

      // Load from Database
      List<Assessment> dbAssessments = [];
      if (_currentDoctorId != null) {
        dbAssessments = await DatabaseService().getAssessmentsByAssessorId(
          _currentDoctorId!,
        );
      } else {
        // Fallback or local only mode
        dbAssessments = await DatabaseService().getAllAssessments();
      }

      final List<Map<String, dynamic>> loadedAssessments = [];

      for (var assessment in dbAssessments) {
        // Filter for DSM-5 assessments
        if (assessment.decisionContext != 'DSM-5 Assessment') continue;

        try {
          final data = assessment.toMap();
          data['responses'] = assessment.responses;

          // Reconstruct extra fields needed for UI
          data['total_score'] = _calculateTotalScore(assessment.responses);
          data['severity'] =
              assessment.overallCapacity; // We mapped severity here
          data['domain_scores'] = _calculateDomainHighestScores(
            assessment.responses,
          );
          data['flagged_domains'] =
              AssessmentQuestions.getDomainsRequiringFollowUp(
                Map<String, int>.from(data['domain_scores'] as Map),
              );

          // Calculate highest domain score for display
          final domainScores = data['domain_scores'] as Map<String, dynamic>;
          int highestScore = 0;
          String highestDomain = '';
          domainScores.forEach((domain, score) {
            final scoreInt = score is int
                ? score
                : int.tryParse(score.toString()) ?? 0;
            if (scoreInt > highestScore) {
              highestScore = scoreInt;
              highestDomain = domain;
            }
          });
          data['_highest_score'] = highestScore;
          data['_highest_domain'] = highestDomain;

          loadedAssessments.add(data);
        } catch (e) {
          debugPrint('Error parsing assessment ${assessment.id}: $e');
        }
      }

      if (!mounted) return;
      setState(() {
        _allAssessments = loadedAssessments;
        _filteredAssessments =
            loadedAssessments; // Initial sort will happen in _applyFilters if called, or here
        _isLoading = false;
      });

      // Apply initial sort/filter
      _applyFilters();
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading assessments: $e')),
        );
      }
    }
  }

  int _calculateTotalScore(Map<String, dynamic> responses) {
    return AssessmentQuestions.calculateCapacityScore(responses)['totalScore']
        as int;
  }

  Map<String, dynamic> _calculateDomainHighestScores(
    Map<String, dynamic> responses,
  ) {
    return AssessmentQuestions.calculateDomainHighestScores(responses);
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
          final dateA =
              DateTime.tryParse(a['assessment_date'] ?? '') ?? DateTime.now();
          final dateB =
              DateTime.tryParse(b['assessment_date'] ?? '') ?? DateTime.now();
          return dateA.compareTo(dateB);
        case 'score_desc':
          return (b['total_score'] ?? 0).compareTo(a['total_score'] ?? 0);
        case 'score_asc':
          return (a['total_score'] ?? 0).compareTo(b['total_score'] ?? 0);
        default: // date_desc
          final dateA =
              DateTime.tryParse(a['assessment_date'] ?? '') ?? DateTime.now();
          final dateB =
              DateTime.tryParse(b['assessment_date'] ?? '') ?? DateTime.now();
          return dateB.compareTo(dateA);
      }
    });

    if (mounted) setState(() => _filteredAssessments = filtered);
  }

  int get _followUpCount => _filteredAssessments
      .where((a) => ((a['flagged_domains'] as List<dynamic>?) ?? []).isNotEmpty)
      .length;

  int get _averageScore {
    if (_filteredAssessments.isEmpty) return 0;
    final total = _filteredAssessments.fold<int>(
      0,
      (sum, a) => sum + ((a['total_score'] as int?) ?? 0),
    );
    return (total / _filteredAssessments.length).round();
  }

  String _formatDate(DateTime date) {
    return DateFormat('dd MMM yyyy - HH:mm').format(date);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _surface,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            stops: [0, 0.34, 1],
            colors: [Color(0xFF102338), Color(0xFFEFF5F7), Color(0xFFF8FAFC)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(),
              _buildSearchAndFilter(),
              _buildQuickStats(),
              Expanded(
                child: _isLoading
                    ? Center(child: CircularProgressIndicator(color: _teal))
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
      padding: const EdgeInsets.fromLTRB(18, 14, 18, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _buildHeaderIconButton(
                icon: Icons.arrow_back,
                onTap: () => Navigator.pop(context),
              ),
              const Spacer(),
              _buildHeaderIconButton(
                icon: Icons.refresh,
                onTap: _loadAssessments,
              ),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'DSM-5 Assessments',
                      style: GoogleFonts.poppins(
                        fontSize: 28,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        height: 1.05,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '${_filteredAssessments.length} shown from ${_allAssessments.length} saved records',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: Colors.white.withValues(alpha: 0.74),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.18),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.verified_outlined, color: _teal, size: 16),
                    const SizedBox(width: 6),
                    Text(
                      'Synced view',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    ).animate().fadeIn().slideY(begin: -0.12, end: 0);
  }

  Widget _buildHeaderIconButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.white.withValues(alpha: 0.12),
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.white.withValues(alpha: 0.14)),
          ),
          child: Icon(icon, color: Colors.white, size: 22),
        ),
      ),
    );
  }

  Widget _buildSearchAndFilter() {
    return Container(
          margin: const EdgeInsets.fromLTRB(18, 8, 18, 0),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: _panel,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.10),
                blurRadius: 24,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: Column(
            children: [
              TextField(
                controller: _searchController,
                onChanged: (_) => _applyFilters(),
                style: GoogleFonts.inter(fontSize: 14, color: _ink),
                decoration: InputDecoration(
                  hintText: 'Search patient ID or date',
                  hintStyle: GoogleFonts.inter(color: _muted),
                  prefixIcon: Icon(Icons.search, color: _muted),
                  suffixIcon: _searchController.text.isEmpty
                      ? null
                      : IconButton(
                          onPressed: () {
                            _searchController.clear();
                            _applyFilters();
                          },
                          icon: const Icon(Icons.close, size: 18),
                        ),
                  filled: true,
                  fillColor: _surface,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(vertical: 13),
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: _buildCompactDropdown(
                      value: _filterSeverity,
                      icon: Icons.tune,
                      items: const [
                        DropdownMenuItem(
                          value: 'all',
                          child: Text('All severity'),
                        ),
                        DropdownMenuItem(
                          value: 'minimal',
                          child: Text('Minimal'),
                        ),
                        DropdownMenuItem(value: 'mild', child: Text('Mild')),
                        DropdownMenuItem(
                          value: 'moderate',
                          child: Text('Moderate'),
                        ),
                        DropdownMenuItem(
                          value: 'severe',
                          child: Text('Severe'),
                        ),
                      ],
                      onChanged: (value) {
                        setState(() => _filterSeverity = value ?? 'all');
                        _applyFilters();
                      },
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildCompactDropdown(
                      value: _sortBy,
                      icon: Icons.sort,
                      items: const [
                        DropdownMenuItem(
                          value: 'date_desc',
                          child: Text('Newest'),
                        ),
                        DropdownMenuItem(
                          value: 'date_asc',
                          child: Text('Oldest'),
                        ),
                        DropdownMenuItem(
                          value: 'score_desc',
                          child: Text('High score'),
                        ),
                        DropdownMenuItem(
                          value: 'score_asc',
                          child: Text('Low score'),
                        ),
                      ],
                      onChanged: (value) {
                        setState(() => _sortBy = value ?? 'date_desc');
                        _applyFilters();
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        )
        .animate()
        .fadeIn(delay: const Duration(milliseconds: 80))
        .slideY(begin: -0.05, end: 0);
  }

  Widget _buildCompactDropdown({
    required String value,
    required IconData icon,
    required List<DropdownMenuItem<String>> items,
    required ValueChanged<String?> onChanged,
  }) {
    return Container(
      height: 46,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE3E8EF)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 17, color: _blue),
          const SizedBox(width: 6),
          Expanded(
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: value,
                isExpanded: true,
                icon: Icon(Icons.keyboard_arrow_down, color: _muted, size: 18),
                style: GoogleFonts.inter(
                  color: _ink,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
                items: items,
                onChanged: onChanged,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickStats() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 12, 18, 0),
      child: Row(
        children: [
          Expanded(
            child: _buildStatTile(
              label: 'Records',
              value: '${_filteredAssessments.length}',
              icon: Icons.folder_copy_outlined,
              color: _blue,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _buildStatTile(
              label: 'Follow-up',
              value: '$_followUpCount',
              icon: Icons.flag_outlined,
              color: _rose,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _buildStatTile(
              label: 'Avg score',
              value: '$_averageScore',
              icon: Icons.trending_up,
              color: _teal,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatTile({
    required String label,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5EAF1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 16),
              const Spacer(),
              Text(
                value,
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: _ink,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            label,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: _muted,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Container(
        margin: const EdgeInsets.all(24),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: _panel,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE5EAF1)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 68,
              height: 68,
              decoration: BoxDecoration(
                color: _teal.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(Icons.assessment_outlined, size: 34, color: _teal),
            ),
            const SizedBox(height: 18),
            Text(
              _allAssessments.isEmpty
                  ? 'No DSM-5 records yet'
                  : 'No matching records',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: _ink,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _allAssessments.isEmpty
                  ? 'Completed assessments will appear here with scoring and PDF export.'
                  : 'Adjust the search, severity filter, or sort order.',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(fontSize: 13, color: _muted),
            ),
          ],
        ),
      ),
    ).animate().fadeIn().scale(begin: const Offset(0.98, 0.98));
  }

  Widget _buildAssessmentsList() {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(18, 14, 18, 24),
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
    final domainScores =
        assessment['domain_scores'] as Map<String, dynamic>? ?? {};
    final flaggedDomains =
        (assessment['flagged_domains'] as List<dynamic>?)?.cast<String>() ?? [];
    final highestScore = assessment['_highest_score'] ?? 0;
    final highestDomain = assessment['_highest_domain'] ?? '';
    final hasFollowUp = flaggedDomains.isNotEmpty;
    final statusColor = hasFollowUp ? _rose : _teal;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: _panel,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: hasFollowUp
              ? _rose.withValues(alpha: 0.22)
              : const Color(0xFFE5EAF1),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header with gradient
          Container(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  _ink,
                  Color.lerp(_ink, _getSeverityColor(severity), 0.34)!,
                ],
              ),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(14),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.13),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.16),
                    ),
                  ),
                  child: Center(
                    child: Icon(
                      Icons.assignment_outlined,
                      color: Colors.white,
                      size: 22,
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
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        _formatDate(date),
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          color: Colors.white.withValues(alpha: 0.72),
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 11,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.14),
                        ),
                      ),
                      child: Text(
                        '$totalScore/92',
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      severity,
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        color: Colors.white.withValues(alpha: 0.72),
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Highest Domain Score - KEY FEATURE
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.08),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.monitor_heart_outlined,
                  color: statusColor,
                  size: 18,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text.rich(
                    TextSpan(
                      text: 'Highest score ',
                      children: [
                        TextSpan(
                          text: '$highestScore',
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        TextSpan(
                          text: highestDomain.toString().isEmpty
                              ? ''
                              : ' - ${_getShortDomainName(highestDomain.toString())}',
                        ),
                      ],
                    ),
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: statusColor,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.11),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    hasFollowUp ? 'Follow-up' : 'Routine',
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: statusColor,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Body
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Domain scores grid
                if (domainScores.isNotEmpty) ...[
                  Text(
                    'Domain highest scores',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: _ink,
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
                      color: _rose.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: _rose.withValues(alpha: 0.18)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.warning_amber, color: _rose, size: 16),
                            const SizedBox(width: 6),
                            Text(
                              'Requires Follow-Up Assessment',
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                color: _rose,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Wrap(
                          spacing: 4,
                          runSpacing: 4,
                          children: flaggedDomains
                              .map(
                                (domain) => Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 3,
                                  ),
                                  decoration: BoxDecoration(
                                    color: _rose,
                                    borderRadius: BorderRadius.circular(999),
                                  ),
                                  child: Text(
                                    _getShortDomainName(domain),
                                    style: GoogleFonts.inter(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w800,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              )
                              .toList(),
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
                          foregroundColor: _ink,
                          side: const BorderSide(color: Color(0xFFD9E1EA)),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(9),
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
                          backgroundColor: _blue,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(9),
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

  Widget _buildDomainScoresGrid(
    Map<String, dynamic> domainScores,
    List<String> flaggedDomains,
  ) {
    final entries = domainScores.entries.toList();

    return Wrap(
      spacing: 4,
      runSpacing: 4,
      children: entries.map((entry) {
        final scoreValue = entry.value is int
            ? entry.value
            : int.tryParse(entry.value.toString()) ?? 0;
        final isCritical =
            entry.key.contains('Suicidal') ||
            entry.key.contains('Psychosis') ||
            entry.key.contains('Substance');
        // Critical domains flag at ≥1, others at ≥2
        final isFlagged =
            flaggedDomains.contains(entry.key) ||
            (isCritical ? scoreValue >= 1 : scoreValue >= 2);

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
          decoration: BoxDecoration(
            color: isFlagged ? _rose.withValues(alpha: 0.10) : _surface,
            borderRadius: BorderRadius.circular(999),
            border: isFlagged
                ? Border.all(color: _rose.withValues(alpha: 0.24))
                : Border.all(color: const Color(0xFFE5EAF1)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (isFlagged)
                Padding(
                  padding: const EdgeInsets.only(right: 3),
                  child: Icon(Icons.flag, size: 10, color: _rose),
                ),
              Text(
                '${_getShortDomainName(entry.key)}: $scoreValue',
                style: GoogleFonts.inter(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  color: isFlagged ? _rose : _ink,
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
    final responses = _coerceResponses(assessment['responses']);
    final questions = AssessmentQuestions.getStandardQuestions();
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
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
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
                    Icon(
                      Icons.info_outline,
                      color: Colors.blue.shade700,
                      size: 18,
                    ),
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
                    final response = _responseForQuestion(
                      responses: responses,
                      questionId: question.questionId,
                      index: index,
                      expectedLength: questions.length,
                    );
                    final answer = response.answer;
                    final answerIndex = response.score;

                    final isCritical =
                        (question.category ?? '').contains('Suicidal') ||
                        (question.category ?? '').contains('Psychosis') ||
                        (question.category ?? '').contains('Substance');
                    final needsFollowUp = isCritical
                        ? answerIndex >= 1
                        : answerIndex >= 2;

                    return Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: needsFollowUp
                            ? _rose.withValues(alpha: 0.08)
                            : Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: needsFollowUp
                            ? Border.all(color: _rose.withValues(alpha: 0.3))
                            : null,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(
                                    0xFF667eea,
                                  ).withValues(alpha: 0.1),
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
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 3,
                                ),
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
                                Icon(
                                  Icons.flag,
                                  size: 12,
                                  color: AppTheme.errorRed,
                                ),
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

  ({String answer, int score}) _responseForQuestion({
    required Map<String, dynamic> responses,
    required String questionId,
    required int index,
    required int expectedLength,
  }) {
    dynamic value = responses[questionId];

    if (value == null &&
        responses.length == expectedLength &&
        index < responses.length) {
      value = responses.entries.elementAt(index).value;
    }

    if (value is Map) {
      value = value['answer'];
    }

    if (value is int) {
      final score = value.clamp(
        0,
        AssessmentQuestions.standardOptions.length - 1,
      );
      return (answer: AssessmentQuestions.standardOptions[score], score: score);
    }

    if (value is String) {
      final score = AssessmentQuestions.standardOptions.indexOf(value);
      return (answer: value, score: score);
    }

    return (answer: 'Not answered', score: -1);
  }

  Map<String, dynamic> _coerceResponses(dynamic value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) return Map<String, dynamic>.from(value);
    if (value is String && value.isNotEmpty) {
      try {
        final decoded = jsonDecode(value);
        if (decoded is Map) return Map<String, dynamic>.from(decoded);
      } catch (_) {
        return {};
      }
    }
    return {};
  }

  Future<void> _exportToPdf(Map<String, dynamic> assessmentData) async {
    var dialogShown = false;
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
      dialogShown = true;

      final responses = _coerceResponses(assessmentData['responses']);
      if (responses.isEmpty) {
        throw Exception('Assessment responses are missing or incomplete');
      }

      // Convert to Assessment model for PDF service
      final assessment = Assessment(
        id: assessmentData['patient_id']?.hashCode,
        patientId: assessmentData['patient_id'] ?? 'unknown',
        patientName: 'Anonymised',
        assessorName: assessmentData['assessor_name'] ?? 'Unknown',
        assessorRole: 'Doctor',
        decisionContext: 'DSM-5 Level 1 Cross-Cutting Symptom Measure',
        assessmentDate:
            DateTime.tryParse(assessmentData['assessment_date'] ?? '') ??
            DateTime.now(),
        responses: responses,
        overallCapacity: assessmentData['severity'] ?? 'Unknown',
        recommendations: _buildRecommendations(assessmentData),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        status: 'completed',
      );

      final filePath = await _pdfExportService.exportAssessmentToPdf(
        assessment,
      );

      if (mounted && dialogShown) {
        Navigator.of(context, rootNavigator: true).pop();
        dialogShown = false;
      }

      if (filePath != null) {
        // Share the PDF
        final result = await SharePlus.instance.share(
          ShareParams(
            files: [XFile(filePath)],
            text: 'DSM-5 Cross-Cutting Symptom Measure Report',
            title: 'DSM-5 Assessment Report',
          ),
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.check_circle, color: Colors.white),
                  const SizedBox(width: 8),
                  Text(
                    result.status == ShareResultStatus.success
                        ? 'PDF shared successfully!'
                        : 'PDF generated at: $filePath',
                  ),
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
      if (mounted && dialogShown) {
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
    final flaggedDomains =
        (data['flagged_domains'] as List<dynamic>?)?.cast<String>() ?? [];
    if (flaggedDomains.isEmpty) {
      return 'No domains flagged for immediate follow-up. Continue routine monitoring.';
    }

    final buffer = StringBuffer();
    buffer.writeln(
      'The following domains require detailed Level 2 assessment:',
    );
    for (var domain in flaggedDomains) {
      buffer.writeln('• $domain');
    }
    buffer.writeln(
      '\nFor Substance Use, Suicidal Ideation, and Psychosis domains, even a score of 1 (Slight) warrants follow-up assessment per DSM-5 guidelines.',
    );
    return buffer.toString();
  }
}
