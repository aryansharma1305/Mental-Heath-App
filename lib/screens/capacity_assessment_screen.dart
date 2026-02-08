import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'dart:ui';
import '../theme/app_theme.dart';
import '../models/question.dart';
import '../services/assessment_questions.dart';
import '../services/assessment_questions.dart';
import '../services/tts_service.dart';
import 'package:mental_capacity_assessment/l10n/app_localizations.dart';

class CapacityAssessmentScreen extends StatefulWidget {
  const CapacityAssessmentScreen({super.key});

  @override
  State<CapacityAssessmentScreen> createState() => _CapacityAssessmentScreenState();
}

class _CapacityAssessmentScreenState extends State<CapacityAssessmentScreen> with TickerProviderStateMixin {
  final _pageController = PageController();
  final _patientIdController = TextEditingController(); // Anonymised ID only
  String _doctorName = 'Doctor';
  String _doctorId = '';

  List<Question> _questions = [];
  final Map<String, String> _responses = {};
  int _currentPage = 0;
  bool _isSubmitting = false;
  bool _showPatientInfo = true;
  late AnimationController _progressController;
  final TTSService _ttsService = TTSService();

  @override
  void initState() {
    super.initState();
    _progressController = AnimationController(duration: const Duration(milliseconds: 500), vsync: this);
    _ttsService.init();
    _loadQuestions();
    _loadDoctorProfile();
  }

  @override
  void dispose() {
    _progressController.dispose();
    _pageController.dispose();
    _patientIdController.dispose();
    _ttsService.stop();
    super.dispose();
  }

  Future<void> _loadDoctorProfile() async {
    final prefs = await SharedPreferences.getInstance();
    final doctorJson = prefs.getString('doctor_profile');
    if (doctorJson != null) {
      try {
        final data = jsonDecode(doctorJson);
        setState(() {
          _doctorName = data['name'] ?? 'Doctor';
          _doctorId = data['doctor_id'] ?? '';
        });
      } catch (e) {}
    }
  }

  void _loadQuestions() {
    setState(() {
      _questions = AssessmentQuestions.getStandardQuestions();
    });
  }

  void _startAssessment() {
    if (_patientIdController.text.trim().isEmpty) {
      _showError('Please enter anonymised patient ID');
      return;
    }
    setState(() => _showPatientInfo = false);
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(message),
      backgroundColor: AppTheme.errorRed,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ));
  }

  void _nextPage() {
    if (_currentPage < _questions.length - 1) {
      _pageController.nextPage(duration: const Duration(milliseconds: 400), curve: Curves.easeInOut);
    }
  }

  void _previousPage() {
    if (_currentPage > 0) {
      _pageController.previousPage(duration: const Duration(milliseconds: 400), curve: Curves.easeInOut);
    }
  }

  void _selectOption(Question question, String option) {
    setState(() {
      _responses[question.questionId] = option;
    });
    
    // Check for critical response (suicidal ideation)
    if (question.category?.contains('Suicidal') == true) {
      final optionIndex = question.options?.indexOf(option) ?? 0;
      if (optionIndex >= 1) {
        _showCriticalAlert();
      }
    }
    
    Future.delayed(const Duration(milliseconds: 300), () {
      if (_currentPage < _questions.length - 1) {
        _nextPage();
      } else {
        _submitAssessment();
      }
    });
  }

  void _showCriticalAlert() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: AppTheme.errorRed.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
              child: Icon(Icons.warning_amber_rounded, color: AppTheme.errorRed),
            ),
            const SizedBox(width: 12),
            Text(AppLocalizations.of(context)!.criticalAlertTitle, style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: AppTheme.errorRed)),
          ],
        ),
        content: Text(AppLocalizations.of(context)!.criticalAlertMessage, style: GoogleFonts.inter()),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.errorRed),
            child: Text(AppLocalizations.of(context)!.acknowledged, style: GoogleFonts.inter(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Future<void> _submitAssessment() async {
    setState(() => _isSubmitting = true);
    try {
      final scoreData = AssessmentQuestions.calculateCapacityScore(_responses);
      final percentage = scoreData['percentage'] as double;
      final categoryScores = scoreData['categoryScores'] as Map<String, int>;
      final determination = AssessmentQuestions.getCapacityDetermination(percentage);
      final recommendations = AssessmentQuestions.getRecommendations(percentage, categoryScores);
      final domainsNeedingLevel2 = AssessmentQuestions.getDomainsNeedingLevel2(_responses);

      final assessmentData = {
        'assessment_id': 'DSM_${DateTime.now().millisecondsSinceEpoch}',
        'doctor_id': _doctorId,
        'patient_id': _patientIdController.text.trim(),
        'patient_name': 'Anonymised', // Privacy: No identifiable info
        'assessment_date': DateTime.now().toIso8601String(),
        'assessor_name': _doctorName,
        'responses': _responses,
        'total_score': scoreData['totalScore'],
        'max_score': scoreData['maxScore'],
        'score_percentage': percentage,
        'category_scores': categoryScores,
        'overall_capacity': determination,
        'recommendations': recommendations,
        'domains_needing_level2': domainsNeedingLevel2,
      };

      final prefs = await SharedPreferences.getInstance();
      final existing = prefs.getStringList('capacity_assessments') ?? [];
      existing.add(jsonEncode(assessmentData));
      await prefs.setStringList('capacity_assessments', existing);

      if (mounted) _showResultsDialog(determination, percentage, recommendations, domainsNeedingLevel2, categoryScores);
    } catch (e) {
      _showError('Error: $e');
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  void _showResultsDialog(String determination, double score, List<String> recommendations, List<String> domainsNeedingLevel2, Map<String, int> domainScores) {
    Color getColor() => score < 25 ? AppTheme.successGreen : score < 50 ? AppTheme.warningOrange : AppTheme.errorRed;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        child: Container(
          padding: const EdgeInsets.all(24),
          constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.85),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Score circle
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(colors: [getColor(), getColor().withOpacity(0.7)]),
                    boxShadow: [BoxShadow(color: getColor().withOpacity(0.4), blurRadius: 20, offset: const Offset(0, 10))],
                  ),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('${score.toInt()}', style: GoogleFonts.poppins(fontSize: 36, fontWeight: FontWeight.bold, color: Colors.white)),
                        Text(AppLocalizations.of(context)!.scoreLabel, style: GoogleFonts.inter(fontSize: 12, color: Colors.white70)),
                      ],
                    ),
                  ),
                ).animate().scale(duration: 500.ms, curve: Curves.easeOutBack),
                const SizedBox(height: 20),
                Text(AppLocalizations.of(context)!.assessmentComplete, style: GoogleFonts.poppins(fontSize: 22, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Text('${AppLocalizations.of(context)!.anonymisedId}: ${_patientIdController.text}', style: GoogleFonts.inter(fontSize: 16, color: AppTheme.textGrey)),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(color: getColor().withOpacity(0.1), borderRadius: BorderRadius.circular(16)),
                  child: Row(children: [
                    Icon(Icons.analytics, color: getColor()),
                    const SizedBox(width: 12),
                    Expanded(child: Text(determination, style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: getColor()))),
                  ]),
                ),
                if (domainsNeedingLevel2.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(color: AppTheme.warningOrange.withOpacity(0.1), borderRadius: BorderRadius.circular(16)),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(children: [
                          Icon(Icons.priority_high, color: AppTheme.warningOrange),
                          const SizedBox(width: 8),
                          Text(AppLocalizations.of(context)!.level2Recommended, style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.warningOrange)),
                        ]),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: domainsNeedingLevel2.map((d) => Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
                            child: Text(d.replaceAll(RegExp(r'^[IVXL]+\.\s*'), ''), style: GoogleFonts.inter(fontSize: 11, color: AppTheme.warningOrange)),
                          )).toList(),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                Text(AppLocalizations.of(context)!.domainBreakdown, style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                ...domainScores.entries.map((e) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(children: [
                    Expanded(child: Text(e.key.replaceAll(RegExp(r'^[IVXL]+\.\s*'), ''), style: GoogleFonts.inter(fontSize: 12, color: AppTheme.textMedium))),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(color: e.value >= 2 ? AppTheme.warningOrange.withOpacity(0.2) : AppTheme.successGreen.withOpacity(0.2), borderRadius: BorderRadius.circular(8)),
                      child: Text('${e.value}', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: e.value >= 2 ? AppTheme.warningOrange : AppTheme.successGreen)),
                    ),
                  ]),
                )),
                const SizedBox(height: 20),
                Row(children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () { Navigator.pop(context); Navigator.pop(context, true); },
                      style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
                      child: Text(AppLocalizations.of(context)!.done, style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () { Navigator.pop(context); _resetAssessment(); },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF667eea),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      child: Text(AppLocalizations.of(context)!.newAssessmentButton, style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: Colors.white)),
                    ),
                  ),
                ]),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _resetAssessment() {
    setState(() {
      _patientIdController.clear();
      _responses.clear();
      _currentPage = 0;
      _showPatientInfo = true;
      _pageController.jumpToPage(0);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [const Color(0xFF667eea), const Color(0xFF764ba2), const Color(0xFFf093fb).withOpacity(0.8)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildAppBar(),
              if (!_showPatientInfo) _buildProgressBar(),
              Expanded(child: _showPatientInfo ? _buildPatientInfoForm() : _buildAssessmentForm()),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAppBar() {
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(AppLocalizations.of(context)!.assessmentTitle, style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                Text(AppLocalizations.of(context)!.assessmentSubtitle, style: GoogleFonts.inter(fontSize: 12, color: Colors.white70)),
              ],
            ),
          ),
          if (!_showPatientInfo)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(12)),
              child: Text('${_currentPage + 1}/${_questions.length}', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.white)),
            ),
        ],
      ),
    ).animate().fadeIn().slideY(begin: -0.2, end: 0);
  }

  Widget _buildProgressBar() {
    final progress = (_currentPage + 1) / _questions.length;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: LinearProgressIndicator(
          value: progress,
          backgroundColor: Colors.white.withOpacity(0.2),
          valueColor: const AlwaysStoppedAnimation(Colors.white),
          minHeight: 6,
        ),
      ),
    ).animate().fadeIn(delay: 200.ms);
  }

  Widget _buildPatientInfoForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(28), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 20, offset: const Offset(0, 10))]),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(gradient: LinearGradient(colors: [const Color(0xFF667eea), const Color(0xFF764ba2)]), borderRadius: BorderRadius.circular(14)), child: const Icon(Icons.person_add, color: Colors.white)),
                  const SizedBox(width: 14),
                  Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(AppLocalizations.of(context)!.patientInfoTitle, style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold)),
                    Text(AppLocalizations.of(context)!.patientInfoSubtitle, style: GoogleFonts.inter(fontSize: 13, color: AppTheme.textGrey)),
                  ]),
                ]),
                const SizedBox(height: 24),
                Text(AppLocalizations.of(context)!.enterIdLabel, style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.textDark)),
                const SizedBox(height: 8),
                TextField(controller: _patientIdController, decoration: _inputDecoration(AppLocalizations.of(context)!.enterIdHint, Icons.badge_outlined)),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _startAssessment,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF667eea),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      elevation: 5,
                    ),
                    child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                      Text(AppLocalizations.of(context)!.startAssessment, style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white)),
                      const SizedBox(width: 8),
                      const Icon(Icons.arrow_forward, color: Colors.white),
                    ]),
                  ),
                ),
              ],
            ),
          ).animate().fadeIn().scale(begin: const Offset(0.95, 0.95)),
          const SizedBox(height: 20),
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: Colors.white.withOpacity(0.15), borderRadius: BorderRadius.circular(16)),
                child: Row(children: [
                  const Icon(Icons.info_outline, color: Colors.white, size: 20),
                  const SizedBox(width: 12),
                  Expanded(child: Text(AppLocalizations.of(context)!.dsm5Info, style: GoogleFonts.inter(fontSize: 12, color: Colors.white))),
                ]),
              ),
            ),
          ).animate().fadeIn(delay: 300.ms),
        ],
      ),
    );
  }

  InputDecoration _inputDecoration(String hint, IconData icon) {
    return InputDecoration(
      hintText: hint,
      prefixIcon: Icon(icon, color: AppTheme.textGrey),
      filled: true,
      fillColor: const Color(0xFFF8F9FA),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFF667eea), width: 2)),
    );
  }

  Widget _buildAssessmentForm() {
    return PageView.builder(
      controller: _pageController,
      physics: const NeverScrollableScrollPhysics(),
      onPageChanged: (page) => setState(() => _currentPage = page),
      itemCount: _questions.length,
      itemBuilder: (context, index) => _buildQuestionCard(_questions[index], index),
    );
  }

  Widget _buildQuestionCard(Question question, int index) {
    final selectedOption = _responses[question.questionId];
    final options = question.options ?? [];
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(28), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 20, offset: const Offset(0, 10))]),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(color: const Color(0xFF667eea).withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
                  child: Text(question.category ?? 'Question', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: const Color(0xFF667eea))),
                ),
                const SizedBox(height: 16),
                Text(AppLocalizations.of(context)!.pastTwoWeeks, style: GoogleFonts.inter(fontSize: 12, color: AppTheme.textGrey)),
                const SizedBox(height: 8),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(question.text, style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w600, color: AppTheme.textDark, height: 1.4)),
                    ),
                    IconButton(
                      onPressed: () => _ttsService.speak(question.text),
                      icon: const Icon(Icons.volume_up_rounded, color: Color(0xFF667eea)),
                      tooltip: 'Read Aloud',
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                ...List.generate(options.length, (i) {
                  final option = options[i];
                  final isSelected = selectedOption == option;
                  final optionColors = [AppTheme.successGreen, const Color(0xFF8BC34A), AppTheme.warningOrange, const Color(0xFFFF7043), AppTheme.errorRed];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: GestureDetector(
                      onTap: () => _selectOption(question, option),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: isSelected ? optionColors[i].withOpacity(0.1) : const Color(0xFFF8F9FA),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: isSelected ? optionColors[i] : Colors.transparent, width: 2),
                        ),
                        child: Row(children: [
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            width: 28,
                            height: 28,
                            decoration: BoxDecoration(
                              color: isSelected ? optionColors[i] : Colors.white,
                              shape: BoxShape.circle,
                              border: Border.all(color: isSelected ? optionColors[i] : AppTheme.dividerColor, width: 2),
                            ),
                            child: isSelected ? const Icon(Icons.check, color: Colors.white, size: 16) : Center(child: Text('$i', style: GoogleFonts.inter(fontSize: 12, color: AppTheme.textGrey))),
                          ),
                          const SizedBox(width: 14),
                          Expanded(child: Text(option, style: GoogleFonts.inter(fontSize: 14, fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal, color: isSelected ? optionColors[i] : AppTheme.textDark))),
                        ]),
                      ),
                    ),
                  ).animate(delay: Duration(milliseconds: 50 * i)).fadeIn().slideX(begin: 0.1, end: 0);
                }),
              ],
            ),
          ).animate().fadeIn().slideY(begin: 0.05, end: 0),
          const SizedBox(height: 20),
          if (_currentPage > 0)
            GestureDetector(
              onTap: _previousPage,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(14)),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      const Icon(Icons.arrow_back, color: Colors.white, size: 18),
                      const SizedBox(width: 8),
                      Text(AppLocalizations.of(context)!.previous, style: GoogleFonts.inter(fontSize: 14, color: Colors.white)),
                    ]),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
