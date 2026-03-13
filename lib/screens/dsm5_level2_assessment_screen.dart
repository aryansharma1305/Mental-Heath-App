import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:convert';
import '../services/dsm5_level2_questions.dart';
import '../services/auth_service.dart';
import '../services/database_service.dart';
import '../models/assessment.dart';
import '../theme/app_theme.dart';

/// DSM-5-TR Level 2 Cross-Cutting Symptom Assessment Screen (Adults)
///
/// Accepts a list of flagged Level 1 domain strings and chains the user
/// through each corresponding Level 2 instrument in sequence.
class DSM5Level2AssessmentScreen extends StatefulWidget {
  final String patientId;
  final String? parentAssessmentId;
  final List<String> flaggedLevel1Domains;

  const DSM5Level2AssessmentScreen({
    super.key,
    required this.patientId,
    this.parentAssessmentId,
    required this.flaggedLevel1Domains,
  });

  @override
  State<DSM5Level2AssessmentScreen> createState() =>
      _DSM5Level2AssessmentScreenState();
}

class _DSM5Level2AssessmentScreenState
    extends State<DSM5Level2AssessmentScreen>
    with SingleTickerProviderStateMixin {
  final PageController _pageController = PageController();
  final AuthService _authService = AuthService();

  late List<Level2Domain> _domains;
  int _currentDomainIndex = 0;
  int _currentQuestionIndex = 0;

  // responses per domain: domainKey → { questionId → optionIndex }
  final Map<String, Map<String, int>> _allResponses = {};
  final List<Level2Result> _completedResults = [];

  bool _isSubmitting = false;
  bool _domainComplete = false;
  Level2Result? _currentResult;

  late AnimationController _animController;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _domains = DSM5Level2Questions.getDomainsForFlagged(widget.flaggedLevel1Domains);
    _animController.forward();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _animController.dispose();
    super.dispose();
  }

  // ──────────────────────────────────────────────
  // Computed helpers
  // ──────────────────────────────────────────────

  Level2Domain get _currentDomain => _domains[_currentDomainIndex];

  int get _totalQuestions => _currentDomain.questions.length;

  Map<String, int> get _currentResponses =>
      _allResponses.putIfAbsent(_currentDomain.domainKey, () => {});

  bool get _hasAnsweredCurrent {
    final qId = _currentDomain.questions[_currentQuestionIndex].id;
    return _currentResponses.containsKey(qId);
  }

  double get _overallProgress {
    final domainsCompleted = _completedResults.length;
    final currentFraction = (_currentQuestionIndex + 1) / _totalQuestions;
    return (domainsCompleted + currentFraction) / _domains.length;
  }

  // ──────────────────────────────────────────────
  // Navigation
  // ──────────────────────────────────────────────

  void _nextQuestion() {
    if (!_hasAnsweredCurrent) {
      _showSnack('Please select a response before continuing.', AppTheme.warningOrange);
      return;
    }
    if (_currentQuestionIndex < _totalQuestions - 1) {
      setState(() => _currentQuestionIndex++);
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _finishDomain();
    }
  }

  void _previousQuestion() {
    if (_currentQuestionIndex > 0) {
      setState(() => _currentQuestionIndex--);
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _finishDomain() {
    final result = DSM5Level2Questions.calculateResult(
      _currentDomain.domainKey,
      _currentResponses,
    );
    setState(() {
      _currentResult = result;
      _domainComplete = true;
    });
  }

  void _proceedToNextDomain() {
    if (_currentResult != null) {
      _completedResults.add(_currentResult!);
    }
    if (_currentDomainIndex < _domains.length - 1) {
      setState(() {
        _currentDomainIndex++;
        _currentQuestionIndex = 0;
        _domainComplete = false;
        _currentResult = null;
      });
      _pageController.jumpToPage(0);
      _animController
        ..reset()
        ..forward();
    } else {
      _submitAllResults();
    }
  }

  // ──────────────────────────────────────────────
  // Submit & Save
  // ──────────────────────────────────────────────

  Future<void> _submitAllResults() async {
    setState(() => _isSubmitting = true);
    try {
      final currentUser = await _authService.getCurrentUserModel();

      // Build a readable summary from all Level 2 results
      final resultSummary = _completedResults
          .map((r) => '${r.domainTitle}: ${r.severity} (${r.rawScore}/${r.maxScore})')
          .join(' | ');

      final responseMap = <String, dynamic>{};
      for (final r in _completedResults) {
        responseMap[r.domainKey] = r.toMap();
      }

      final assessment = Assessment(
        patientId: widget.patientId,
        patientName: 'Anonymised',
        assessmentDate: DateTime.now(),
        assessorName: currentUser?.fullName ?? 'Unknown',
        assessorRole: currentUser?.role.name ?? 'Doctor',
        assessorUserId: currentUser?.id,
        decisionContext: 'DSM-5 Level 2 Assessment',
        responses: responseMap,
        overallCapacity: resultSummary,
        recommendations: _completedResults
            .where((r) => r.requiresAction)
            .map((r) => r.domainTitle)
            .join(', '),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        status: 'completed',
        isSynced: false,
      );

      await DatabaseService().insertAssessment(assessment);

      if (mounted) {
        _showFinalSummarySheet();
      }
    } catch (e) {
      if (mounted) {
        _showSnack('Error saving results: $e', AppTheme.errorRed);
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  // ──────────────────────────────────────────────
  // Dialogs / Sheets
  // ──────────────────────────────────────────────

  void _showSnack(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: color),
    );
  }

  void _showFinalSummarySheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black54,
      builder: (_) => _FinalSummarySheet(
        results: _completedResults,
        onDone: () {
          Navigator.pop(context); // close sheet
          Navigator.pop(context, true); // return to Level 1 results
        },
      ),
    );
  }

  // ──────────────────────────────────────────────
  // Build
  // ──────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    if (_domains.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Level 2 Assessment')),
        body: const Center(child: Text('No Level 2 domains available.')),
      );
    }

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: _buildAppBar(),
      body: SafeArea(
        child: _domainComplete ? _buildDomainResultView() : _buildQuestionView(),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
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
          child: const Icon(Icons.arrow_back, color: AppTheme.textDark, size: 20),
        ),
        onPressed: () => _showExitConfirm(),
      ),
      title: Column(
        children: [
          Text(
            'Level 2 — ${_currentDomain.title}',
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.w600,
              fontSize: 15,
              color: AppTheme.textDark,
            ),
          ),
          Text(
            'Domain ${_currentDomainIndex + 1} of ${_domains.length}',
            style: GoogleFonts.inter(fontSize: 11, color: AppTheme.textGrey),
          ),
        ],
      ),
      centerTitle: true,
    );
  }

  void _showExitConfirm() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Exit Level 2?', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
        content: Text(
          'Progress in the current Level 2 domain will be lost.',
          style: GoogleFonts.inter(color: AppTheme.textMedium),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Continue Assessment'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.errorRed),
            child: const Text('Exit'),
          ),
        ],
      ),
    );
  }

  // ──────────────────────────────────────────────
  // Question View
  // ──────────────────────────────────────────────

  Widget _buildQuestionView() {
    final domain = _currentDomain;

    return Column(
      children: [
        // ── Progress bar ──
        _buildProgressHeader(domain),

        // ── Question PageView ──
        Expanded(
          child: PageView.builder(
            controller: _pageController,
            physics: const NeverScrollableScrollPhysics(),
            onPageChanged: (i) => setState(() => _currentQuestionIndex = i),
            itemCount: domain.questions.length,
            itemBuilder: (_, i) => _buildQuestionCard(domain, domain.questions[i]),
          ),
        ),

        // ── Navigation row ──
        _buildNavRow(),
      ],
    );
  }

  Widget _buildProgressHeader(Level2Domain domain) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Overall progress
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Overall Progress',
                style: GoogleFonts.inter(fontSize: 11, color: AppTheme.textGrey),
              ),
              Text(
                '${(_overallProgress * 100).toInt()}%',
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.primaryColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: _overallProgress,
              backgroundColor: AppTheme.dividerColor,
              valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
              minHeight: 6,
            ),
          ),
          const SizedBox(height: 10),

          // Instrument chip + question count
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF667eea).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    domain.instrument,
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF667eea),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppTheme.textDark.withOpacity(0.07),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'Q ${_currentQuestionIndex + 1}/${domain.questions.length}',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textDark,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuestionCard(Level2Domain domain, Level2Question question) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Scoring note banner
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.skyBlue.withOpacity(0.7),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppTheme.infoBlue.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, size: 16, color: AppTheme.infoBlue),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    domain.scoringNote,
                    style: GoogleFonts.inter(fontSize: 10, color: AppTheme.textMedium),
                  ),
                ),
              ],
            ),
          ).animate().fadeIn(),
          const SizedBox(height: 14),

          // Question card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: AppTheme.softShadow,
            ),
            child: Text(
              question.text,
              style: GoogleFonts.poppins(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: AppTheme.textDark,
                height: 1.5,
              ),
            ),
          ).animate().fadeIn().slideY(begin: 0.05, end: 0),

          const SizedBox(height: 20),

          // Response options
          Text(
            'Select your response:',
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppTheme.textGrey,
            ),
          ),
          const SizedBox(height: 10),

          ...List.generate(domain.optionLabels.length, (optIndex) {
            final isSelected = _currentResponses[question.id] == optIndex;
            final optValue = domain.optionValues[optIndex];
            final label = domain.optionLabels[optIndex];
            final color = _optionColor(optIndex, domain.optionLabels.length);

            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: GestureDetector(
                onTap: () => setState(() => _currentResponses[question.id] = optIndex),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: isSelected ? color.withOpacity(0.12) : Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isSelected ? color : AppTheme.dividerColor,
                      width: isSelected ? 2 : 1,
                    ),
                    boxShadow: isSelected
                        ? [BoxShadow(color: color.withOpacity(0.18), blurRadius: 8, offset: const Offset(0, 2))]
                        : [],
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: isSelected ? color : color.withOpacity(0.18),
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            '$optValue',
                            style: GoogleFonts.poppins(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: isSelected ? Colors.white : color,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Text(
                          label,
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                            color: isSelected ? AppTheme.textDark : AppTheme.textMedium,
                          ),
                        ),
                      ),
                      if (isSelected)
                        Icon(Icons.check_circle, color: color, size: 20),
                    ],
                  ),
                ),
              ),
            ).animate().fadeIn(delay: Duration(milliseconds: 40 * optIndex));
          }),
        ],
      ),
    );
  }

  Color _optionColor(int index, int total) {
    final colors = [
      AppTheme.successGreen,
      AppTheme.mintGreen,
      AppTheme.warningOrange,
      AppTheme.errorRed,
      const Color(0xFF9B59B6),
      const Color(0xFFE74C3C),
    ];
    final step = (colors.length - 1) / (total - 1).clamp(1, 999);
    final colorIndex = (index * step).round().clamp(0, colors.length - 1);
    return colors[colorIndex];
  }

  Widget _buildNavRow() {
    final isLast = _currentQuestionIndex == _totalQuestions - 1;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -4))],
      ),
      child: Row(
        children: [
          if (_currentQuestionIndex > 0)
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _previousQuestion,
                icon: const Icon(Icons.arrow_back, size: 16),
                label: const Text('Back'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  side: BorderSide(color: AppTheme.dividerColor, width: 2),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
              ),
            ),
          if (_currentQuestionIndex > 0) const SizedBox(width: 12),
          Expanded(
            child: ElevatedButton.icon(
              onPressed: _isSubmitting ? null : _nextQuestion,
              icon: _isSubmitting
                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : Icon(isLast ? Icons.check : Icons.arrow_forward, size: 16),
              label: Text(isLast ? 'Submit Domain' : 'Next'),
              style: ElevatedButton.styleFrom(
                backgroundColor: isLast ? AppTheme.successGreen : AppTheme.textDark,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ──────────────────────────────────────────────
  // Domain Result View (shown after each domain)
  // ──────────────────────────────────────────────

  Widget _buildDomainResultView() {
    final result = _currentResult!;
    final isLast = _currentDomainIndex == _domains.length - 1;
    final severityColor = _severityColor(result.severity);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          // ── Score card ──
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [severityColor, severityColor.withOpacity(0.7)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(28),
              boxShadow: AppTheme.mediumShadow,
            ),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.25),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    result.requiresAction ? Icons.warning_rounded : Icons.check_circle_rounded,
                    color: Colors.white,
                    size: 36,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  result.domainTitle,
                  style: GoogleFonts.poppins(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  result.instrument,
                  style: GoogleFonts.inter(fontSize: 11, color: Colors.white70),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _scorePill('Score', '${result.rawScore} / ${result.maxScore}'),
                    const SizedBox(width: 12),
                    _scorePill('Severity', result.severity),
                  ],
                ),
              ],
            ),
          ).animate().fadeIn().scale(begin: const Offset(0.95, 0.95)),

          const SizedBox(height: 20),

          // ── Clinical note ──
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: AppTheme.softShadow,
              border: Border.all(
                color: result.requiresAction ? AppTheme.warningOrange.withOpacity(0.4) : AppTheme.dividerColor,
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  result.requiresAction ? Icons.medical_services_outlined : Icons.info_outline,
                  color: result.requiresAction ? AppTheme.warningOrange : AppTheme.infoBlue,
                  size: 22,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        result.requiresAction ? 'Clinical Action Required' : 'Clinical Note',
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                          color: result.requiresAction ? AppTheme.warningOrange : AppTheme.textDark,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        result.clinicalNote,
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          color: AppTheme.textMedium,
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.1, end: 0),

          const SizedBox(height: 16),

          // ── Remaining domains ──
          if (!isLast) ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.skyBlue.withOpacity(0.5),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  Icon(Icons.list_alt, color: AppTheme.infoBlue),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Next: ${_domains[_currentDomainIndex + 1].title} (${_domains.length - _currentDomainIndex - 1} remaining)',
                      style: GoogleFonts.inter(fontSize: 13, color: AppTheme.textMedium),
                    ),
                  ),
                ],
              ),
            ).animate().fadeIn(delay: 300.ms),
            const SizedBox(height: 20),
          ],

          // ── Action button ──
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _isSubmitting ? null : _proceedToNextDomain,
              icon: _isSubmitting
                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : Icon(isLast ? Icons.done_all : Icons.arrow_forward),
              label: Text(
                isLast ? 'Finish & Save All Results' : 'Next Domain →',
                style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w600),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: isLast ? AppTheme.successGreen : AppTheme.textDark,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 18),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 3,
              ),
            ),
          ).animate().fadeIn(delay: 400.ms).scale(),
        ],
      ),
    );
  }

  Widget _scorePill(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          Text(label, style: GoogleFonts.inter(fontSize: 10, color: Colors.white70)),
          const SizedBox(height: 4),
          Text(
            value,
            style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.white),
          ),
        ],
      ),
    );
  }

  Color _severityColor(String severity) {
    final s = severity.toLowerCase();
    if (s.contains('severe') || s.contains('high') || s.contains('urgent') || s.contains('mania likely')) {
      return AppTheme.errorRed;
    }
    if (s.contains('moderate') || s.contains('hypomania') || s.contains('medium')) {
      return AppTheme.warningOrange;
    }
    if (s.contains('mild') || s.contains('low')) {
      return const Color(0xFF66BB6A);
    }
    return AppTheme.infoBlue;
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// Final Summary Bottom Sheet
// ──────────────────────────────────────────────────────────────────────────────

class _FinalSummarySheet extends StatelessWidget {
  final List<Level2Result> results;
  final VoidCallback onDone;

  const _FinalSummarySheet({required this.results, required this.onDone});

  @override
  Widget build(BuildContext context) {
    final actionsRequired = results.where((r) => r.requiresAction).toList();

    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (_, scrollController) => Container(
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
              decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppTheme.successGreen.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(Icons.done_all, color: AppTheme.successGreen),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Level 2 Complete',
                            style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 18)),
                        Text('${results.length} domain(s) assessed',
                            style: GoogleFonts.inter(fontSize: 12, color: AppTheme.textGrey)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                controller: scrollController,
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                children: [
                  if (actionsRequired.isNotEmpty) ...[
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppTheme.errorRed.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppTheme.errorRed.withOpacity(0.3)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.warning_rounded, color: AppTheme.errorRed, size: 18),
                              const SizedBox(width: 8),
                              Text('Clinical Action Required',
                                  style: GoogleFonts.poppins(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 13,
                                      color: AppTheme.errorRed)),
                            ],
                          ),
                          const SizedBox(height: 8),
                          ...actionsRequired.map((r) => Padding(
                                padding: const EdgeInsets.only(bottom: 4),
                                child: Text(
                                  '• ${r.domainTitle}: ${r.severity}',
                                  style: GoogleFonts.inter(fontSize: 12, color: AppTheme.textMedium),
                                ),
                              )),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                  ...results.map((r) => _ResultTile(result: r)),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: onDone,
                      icon: const Icon(Icons.check),
                      label: const Text('Done'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.textDark,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ResultTile extends StatelessWidget {
  final Level2Result result;
  const _ResultTile({required this.result});

  @override
  Widget build(BuildContext context) {
    final color = _color(result.severity);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: AppTheme.softShadow,
        border: Border.all(color: AppTheme.dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(result.domainTitle,
                    style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 14)),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: color.withOpacity(0.15), borderRadius: BorderRadius.circular(10)),
                child: Text(
                  '${result.rawScore}/${result.maxScore}',
                  style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: color),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            result.severity,
            style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: color),
          ),
          const SizedBox(height: 4),
          Text(
            result.clinicalNote,
            style: GoogleFonts.inter(fontSize: 11, color: AppTheme.textGrey, height: 1.4),
          ),
        ],
      ),
    );
  }

  Color _color(String severity) {
    final s = severity.toLowerCase();
    if (s.contains('severe') || s.contains('high') || s.contains('mania')) return AppTheme.errorRed;
    if (s.contains('moderate') || s.contains('hypomania') || s.contains('medium')) return AppTheme.warningOrange;
    if (s.contains('mild') || s.contains('low')) return const Color(0xFF66BB6A);
    return AppTheme.infoBlue;
  }
}
