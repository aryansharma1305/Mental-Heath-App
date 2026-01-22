import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/question.dart';
import '../services/assessment_questions.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';

class DSM5AssessmentScreen extends StatefulWidget {
  const DSM5AssessmentScreen({super.key});

  @override
  State<DSM5AssessmentScreen> createState() => _DSM5AssessmentScreenState();
}

class _DSM5AssessmentScreenState extends State<DSM5AssessmentScreen> 
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _pageController = PageController();
  final AuthService _authService = AuthService();

  // Patient info
  final _patientNameController = TextEditingController();
  final _patientAgeController = TextEditingController();
  String _patientSex = 'Male';

  List<Question> _questions = [];
  final Map<String, int> _responses = {}; // questionId -> score (0-4)
  int _currentPage = 0;
  bool _isSubmitting = false;
  bool _showPatientInfo = true;
  
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _loadQuestions();
    _animationController.forward();
  }

  void _loadQuestions() {
    setState(() {
      _questions = AssessmentQuestions.getStandardQuestions();
    });
  }

  void _startAssessment() {
    if (_patientNameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter patient name'),
          backgroundColor: AppTheme.errorRed,
        ),
      );
      return;
    }
    
    if (_patientAgeController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter patient age'),
          backgroundColor: AppTheme.errorRed,
        ),
      );
      return;
    }

    setState(() {
      _showPatientInfo = false;
    });
  }

  void _nextPage() {
    final currentQuestion = _questions[_currentPage];
    
    if (!_responses.containsKey(currentQuestion.questionId)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a response'),
          backgroundColor: AppTheme.warningOrange,
        ),
      );
      return;
    }
    
    if (_currentPage < _questions.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _previousPage() {
    if (_currentPage > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _handleNextOrSubmit() {
    final currentQuestion = _questions[_currentPage];
    
    if (!_responses.containsKey(currentQuestion.questionId)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a response'),
          backgroundColor: AppTheme.warningOrange,
        ),
      );
      return;
    }
    
    if (_currentPage == _questions.length - 1) {
      _submitAssessment();
    } else {
      _nextPage();
    }
  }

  Future<void> _submitAssessment() async {
    setState(() => _isSubmitting = true);

    try {
      // Calculate total score
      int totalScore = 0;
      _responses.forEach((_, score) => totalScore += score);
      
      // Calculate domain scores
      final Map<String, dynamic> stringResponses = {};
      _responses.forEach((key, value) {
        stringResponses[key] = AssessmentQuestions.standardOptions[value];
      });
      final domainScores = AssessmentQuestions.calculateDomainScores(stringResponses);
      
      // Get flagged domains
      final flaggedDomains = AssessmentQuestions.getDomainsRequiringFollowUp(domainScores);
      
      // Get severity interpretation
      final severity = AssessmentQuestions.getSeverityInterpretation(totalScore);
      
      // Get current user
      final currentUser = await _authService.getCurrentUserModel();
      
      // Prepare assessment data
      final assessmentData = {
        'patient_name': _patientNameController.text.trim(),
        'patient_age': int.tryParse(_patientAgeController.text) ?? 0,
        'patient_sex': _patientSex,
        'assessment_date': DateTime.now().toIso8601String(),
        'assessor_id': currentUser?.id ?? 'unknown',
        'assessor_name': currentUser?.fullName ?? 'Unknown',
        'responses': _responses,
        'total_score': totalScore,
        'domain_scores': domainScores,
        'severity': severity,
        'flagged_domains': flaggedDomains,
        'created_at': DateTime.now().toIso8601String(),
      };
      
      // Save to local database
      await _saveToDatabase(assessmentData);
      
      if (mounted) {
        _showResultsDialog(totalScore, severity, domainScores, flaggedDomains);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving assessment: $e'),
            backgroundColor: AppTheme.errorRed,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  Future<void> _saveToDatabase(Map<String, dynamic> data) async {
    // Save to SharedPreferences for local storage
    final prefs = await SharedPreferences.getInstance();
    final existingJson = prefs.getStringList('dsm5_assessments') ?? [];
    existingJson.add(jsonEncode(data));
    await prefs.setStringList('dsm5_assessments', existingJson);
    debugPrint('Assessment saved successfully. Total: ${existingJson.length}');
  }

  void _showResultsDialog(int totalScore, String severity, 
      Map<String, int> domainScores, List<String> flaggedDomains) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.successGreen.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(Icons.check_circle, color: AppTheme.successGreen),
            ),
            const SizedBox(width: 12),
            const Text('Assessment Complete'),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildResultRow('Patient', _patientNameController.text),
              _buildResultRow('Total Score', '$totalScore / 92'),
              _buildResultRow('Severity', severity),
              const SizedBox(height: 16),
              if (flaggedDomains.isNotEmpty) ...[
                Text(
                  'Domains Requiring Follow-Up:',
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w600,
                    color: AppTheme.warningOrange,
                  ),
                ),
                const SizedBox(height: 8),
                ...flaggedDomains.map((domain) => Padding(
                  padding: const EdgeInsets.only(left: 8, bottom: 4),
                  child: Row(
                    children: [
                      Icon(Icons.flag, size: 16, color: AppTheme.warningOrange),
                      const SizedBox(width: 8),
                      Expanded(child: Text(domain)),
                    ],
                  ),
                )),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context, true);
            },
            child: const Text('Done'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _resetAssessment();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
            ),
            child: const Text('New Assessment'),
          ),
        ],
      ),
    );
  }

  Widget _buildResultRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: GoogleFonts.inter(color: AppTheme.textGrey)),
          Text(value, style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  void _resetAssessment() {
    setState(() {
      _patientNameController.clear();
      _patientAgeController.clear();
      _patientSex = 'Male';
      _responses.clear();
      _currentPage = 0;
      _showPatientInfo = true;
    });
    _pageController.jumpToPage(0);
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
          'DSM-5 Symptom Assessment',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            color: AppTheme.textDark,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: _showPatientInfo 
            ? _buildPatientInfoForm()
            : _buildAssessmentForm(),
      ),
    );
  }

  Widget _buildPatientInfoForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: AppTheme.purpleGradient,
              borderRadius: BorderRadius.circular(24),
              boxShadow: AppTheme.softShadow,
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.9),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(
                    Icons.person_add_outlined,
                    color: AppTheme.lavender,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Patient Information',
                        style: GoogleFonts.poppins(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textDark,
                        ),
                      ),
                      Text(
                        'Enter details before starting assessment',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: AppTheme.textGrey,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ).animate().fadeIn().slideY(begin: -0.2, end: 0),
          
          const SizedBox(height: 32),
          
          // Patient Name
          Text(
            'Patient Name',
            style: GoogleFonts.inter(
              fontWeight: FontWeight.w600,
              color: AppTheme.textDark,
            ),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: _patientNameController,
            decoration: InputDecoration(
              hintText: 'Enter full name',
              prefixIcon: const Icon(Icons.person_outline),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
            ),
          ).animate().fadeIn(delay: 100.ms).slideX(begin: -0.1, end: 0),
          
          const SizedBox(height: 24),
          
          // Age and Sex row
          Row(
            children: [
              // Age
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Age',
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textDark,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _patientAgeController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        hintText: 'Years',
                        prefixIcon: const Icon(Icons.cake_outlined),
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ],
                ),
              ).animate().fadeIn(delay: 200.ms).slideX(begin: -0.1, end: 0),
              
              const SizedBox(width: 16),
              
              // Sex
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Sex',
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textDark,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: DropdownButtonFormField<String>(
                        value: _patientSex,
                        decoration: InputDecoration(
                          prefixIcon: Icon(
                            _patientSex == 'Male' ? Icons.male : Icons.female,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide.none,
                          ),
                        ),
                        items: ['Male', 'Female'].map((sex) {
                          return DropdownMenuItem(
                            value: sex,
                            child: Text(sex),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() => _patientSex = value!);
                        },
                      ),
                    ),
                  ],
                ),
              ).animate().fadeIn(delay: 300.ms).slideX(begin: 0.1, end: 0),
            ],
          ),
          
          const SizedBox(height: 32),
          
          // Info card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.skyBlue.withOpacity(0.5),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.infoBlue.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: AppTheme.infoBlue),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'This assessment contains 23 questions about symptoms over the past 2 weeks.',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: AppTheme.textMedium,
                    ),
                  ),
                ),
              ],
            ),
          ).animate().fadeIn(delay: 400.ms),
          
          const SizedBox(height: 40),
          
          // Start button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _startAssessment,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.textDark,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 18),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 4,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Start Assessment',
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Icon(Icons.arrow_forward),
                ],
              ),
            ),
          ).animate().fadeIn(delay: 500.ms).scale(),
        ],
      ),
    );
  }

  Widget _buildAssessmentForm() {
    if (_questions.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    return Form(
      key: _formKey,
      child: Column(
        children: [
          // Progress Section
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Column(
              children: [
                // Progress bar
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: (_currentPage + 1) / _questions.length,
                    backgroundColor: AppTheme.dividerColor,
                    valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
                    minHeight: 8,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Question ${_currentPage + 1} of ${_questions.length}',
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textDark,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        _questions[_currentPage].category ?? '',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.primaryColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          // Questions PageView
          Expanded(
            child: PageView.builder(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(),
              onPageChanged: (page) => setState(() => _currentPage = page),
              itemCount: _questions.length,
              itemBuilder: (context, index) {
                return _buildQuestionCard(_questions[index]);
              },
            ),
          ),
          
          // Navigation buttons
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -4),
                ),
              ],
            ),
            child: Row(
              children: [
                if (_currentPage > 0)
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _previousPage,
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        side: BorderSide(color: AppTheme.dividerColor, width: 2),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.arrow_back, color: AppTheme.textGrey),
                          const SizedBox(width: 8),
                          Text(
                            'Previous',
                            style: GoogleFonts.inter(
                              fontWeight: FontWeight.w600,
                              color: AppTheme.textGrey,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                
                if (_currentPage > 0) const SizedBox(width: 16),
                
                Expanded(
                  flex: _currentPage == 0 ? 1 : 1,
                  child: ElevatedButton(
                    onPressed: _isSubmitting ? null : _handleNextOrSubmit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _currentPage == _questions.length - 1
                          ? AppTheme.successGreen
                          : AppTheme.textDark,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 2,
                    ),
                    child: _isSubmitting
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                _currentPage == _questions.length - 1
                                    ? 'Submit'
                                    : 'Next',
                                style: GoogleFonts.inter(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Icon(
                                _currentPage == _questions.length - 1
                                    ? Icons.check
                                    : Icons.arrow_forward,
                              ),
                            ],
                          ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuestionCard(Question question) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16),
          
          // Question card
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: AppTheme.softShadow,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'During the past TWO (2) WEEKS, how much have you been bothered by:',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: AppTheme.textGrey,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  question.text,
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textDark,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ).animate().fadeIn().slideY(begin: 0.1, end: 0),
          
          const SizedBox(height: 24),
          
          // Response options
          Text(
            'Select your response:',
            style: GoogleFonts.inter(
              fontWeight: FontWeight.w600,
              color: AppTheme.textDark,
            ),
          ),
          const SizedBox(height: 16),
          
          // Horizontal score buttons
          ..._buildScoreButtons(question),
        ],
      ),
    );
  }

  List<Widget> _buildScoreButtons(Question question) {
    final options = AssessmentQuestions.standardOptions;
    final selectedScore = _responses[question.questionId];
    
    final colors = [
      AppTheme.successGreen,
      AppTheme.mintGreen,
      AppTheme.softYellow,
      AppTheme.warningOrange,
      AppTheme.errorRed,
    ];
    
    return List.generate(options.length, (index) {
      final isSelected = selectedScore == index;
      final color = colors[index];
      
      return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: GestureDetector(
          onTap: () {
            setState(() {
              _responses[question.questionId] = index;
            });
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isSelected ? color.withOpacity(0.15) : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isSelected ? color : AppTheme.dividerColor,
                width: isSelected ? 2 : 1,
              ),
              boxShadow: isSelected ? [
                BoxShadow(
                  color: color.withOpacity(0.2),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ] : [],
            ),
            child: Row(
              children: [
                // Score circle
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: isSelected ? color : color.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      '$index',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: isSelected ? Colors.white : color,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                
                // Option text
                Expanded(
                  child: Text(
                    options[index],
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                      color: isSelected ? AppTheme.textDark : AppTheme.textMedium,
                    ),
                  ),
                ),
                
                // Check icon
                if (isSelected)
                  Icon(Icons.check_circle, color: color, size: 24),
              ],
            ),
          ),
        ),
      ).animate().fadeIn(delay: Duration(milliseconds: 50 * index));
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    _patientNameController.dispose();
    _patientAgeController.dispose();
    _animationController.dispose();
    super.dispose();
  }
}
