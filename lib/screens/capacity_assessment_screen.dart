import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/question.dart';
import '../services/assessment_questions.dart';
import '../theme/app_theme.dart';

class CapacityAssessmentScreen extends StatefulWidget {
  const CapacityAssessmentScreen({super.key});

  @override
  State<CapacityAssessmentScreen> createState() => _CapacityAssessmentScreenState();
}

class _CapacityAssessmentScreenState extends State<CapacityAssessmentScreen> {
  final _pageController = PageController();
  
  // Patient info
  final _patientNameController = TextEditingController();
  final _patientAgeController = TextEditingController();
  String _patientSex = 'Male';
  String _doctorName = 'Doctor';

  List<Question> _questions = [];
  final Map<String, String> _responses = {}; // questionId -> selected option
  int _currentPage = 0;
  bool _isSubmitting = false;
  bool _showPatientInfo = true;

  @override
  void initState() {
    super.initState();
    _loadQuestions();
    _loadDoctorProfile();
  }

  Future<void> _loadDoctorProfile() async {
    final prefs = await SharedPreferences.getInstance();
    final doctorJson = prefs.getString('doctor_profile');
    if (doctorJson != null) {
      try {
        final doctorData = jsonDecode(doctorJson);
        setState(() {
          _doctorName = doctorData['name'] ?? 'Doctor';
        });
      } catch (e) {
        debugPrint('Error loading doctor profile: $e');
      }
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    _patientNameController.dispose();
    _patientAgeController.dispose();
    super.dispose();
  }

  void _loadQuestions() {
    setState(() {
      _questions = AssessmentQuestions.getStandardQuestions();
    });
  }

  void _startAssessment() {
    if (_patientNameController.text.trim().isEmpty) {
      _showError('Please enter patient name');
      return;
    }
    
    if (_patientAgeController.text.trim().isEmpty) {
      _showError('Please enter patient age');
      return;
    }

    setState(() {
      _showPatientInfo = false;
    });
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppTheme.errorRed,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  void _nextPage() {
    final currentQuestion = _questions[_currentPage];
    
    if (!_responses.containsKey(currentQuestion.questionId)) {
      _showError('Please select a response');
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
      _showError('Please select a response');
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
      // Calculate scores
      final scoreData = AssessmentQuestions.calculateCapacityScore(_responses);
      final percentage = scoreData['percentage'] as double;
      final categoryScores = scoreData['categoryScores'] as Map<String, int>;
      
      // Get capacity determination
      final overallCapacity = AssessmentQuestions.getCapacityDetermination(percentage);
      
      // Get recommendations
      final recommendations = AssessmentQuestions.getRecommendations(percentage, categoryScores);
      
      // Prepare assessment data
      final assessmentData = {
        'patient_name': _patientNameController.text.trim(),
        'patient_age': int.tryParse(_patientAgeController.text) ?? 0,
        'patient_sex': _patientSex,
        'assessment_date': DateTime.now().toIso8601String(),
        'assessor_name': _doctorName,
        'responses': _responses,
        'total_score': scoreData['totalScore'],
        'max_score': scoreData['maxScore'],
        'score_percentage': percentage,
        'category_scores': categoryScores,
        'overall_capacity': overallCapacity,
        'recommendations': recommendations,
        'created_at': DateTime.now().toIso8601String(),
      };
      
      // Save to local storage
      await _saveToDatabase(assessmentData);
      
      if (mounted) {
        _showResultsDialog(overallCapacity, percentage, recommendations);
      }
    } catch (e) {
      if (mounted) {
        _showError('Error saving assessment: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  Future<void> _saveToDatabase(Map<String, dynamic> data) async {
    final prefs = await SharedPreferences.getInstance();
    final existingJson = prefs.getStringList('capacity_assessments') ?? [];
    existingJson.add(jsonEncode(data));
    await prefs.setStringList('capacity_assessments', existingJson);
    debugPrint('Assessment saved. Total: ${existingJson.length}');
  }

  void _showResultsDialog(String capacity, double percentage, List<String> recommendations) {
    Color capacityColor;
    IconData capacityIcon;
    
    if (capacity.contains('Has capacity')) {
      capacityColor = AppTheme.successGreen;
      capacityIcon = Icons.check_circle;
    } else if (capacity.contains('Lacks capacity')) {
      capacityColor = AppTheme.errorRed;
      capacityIcon = Icons.cancel;
    } else {
      capacityColor = AppTheme.warningOrange;
      capacityIcon = Icons.help;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Success icon
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: capacityColor.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(capacityIcon, color: capacityColor, size: 48),
              ),
              const SizedBox(height: 20),
              
              Text(
                'Assessment Complete',
                style: GoogleFonts.poppins(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textDark,
                ),
              ),
              const SizedBox(height: 24),
              
              // Patient info
              _buildResultRow('Patient', _patientNameController.text),
              _buildResultRow('Score', '${percentage.toStringAsFixed(0)}%'),
              
              const SizedBox(height: 16),
              
              // Capacity determination
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: capacityColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: capacityColor.withOpacity(0.3)),
                ),
                child: Column(
                  children: [
                    Text(
                      'Determination',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: AppTheme.textGrey,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      capacity,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: capacityColor,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              
              // Recommendations
              if (recommendations.isNotEmpty) ...[
                const SizedBox(height: 16),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Recommendations:',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textGrey,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                ...recommendations.take(3).map((rec) => Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.arrow_right, size: 16, color: AppTheme.textGrey),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          rec,
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: AppTheme.textMedium,
                          ),
                        ),
                      ),
                    ],
                  ),
                )),
              ],
              
              const SizedBox(height: 24),
              
              // Buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        _resetAssessment();
                      },
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        side: BorderSide(color: AppTheme.dividerColor),
                      ),
                      child: Text(
                        'New Assessment',
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textMedium,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        Navigator.pop(context, true);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        'Done',
                        style: GoogleFonts.inter(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildResultRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 14,
              color: AppTheme.textGrey,
            ),
          ),
          Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppTheme.textDark,
            ),
          ),
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
          'Mental Capacity Assessment',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            color: AppTheme.textDark,
            fontSize: 18,
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
          // Header card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: AppTheme.primaryGradient,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.primaryColor.withOpacity(0.3),
                  blurRadius: 15,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(
                    Icons.person_add_outlined,
                    color: Colors.white,
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
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        'Enter details to begin assessment',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          color: Colors.white.withOpacity(0.85),
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
            textCapitalization: TextCapitalization.words,
            decoration: InputDecoration(
              hintText: 'Enter full name',
              prefixIcon: const Icon(Icons.person_outline),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(color: AppTheme.dividerColor),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(color: AppTheme.primaryColor, width: 2),
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
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide(color: AppTheme.dividerColor),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide(color: AppTheme.primaryColor, width: 2),
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
                        border: Border.all(color: AppTheme.dividerColor),
                      ),
                      child: DropdownButtonFormField<String>(
                        value: _patientSex,
                        decoration: InputDecoration(
                          prefixIcon: Icon(
                            _patientSex == 'Male' ? Icons.male : Icons.female,
                          ),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
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
                    'This assessment contains 13 questions to evaluate mental capacity for decision-making.',
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

    return Column(
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
    );
  }

  Widget _buildQuestionCard(Question question) {
    final selectedOption = _responses[question.questionId];

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),
          
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
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppTheme.lavender.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'Q${question.order}',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.lavender,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  question.text,
                  style: GoogleFonts.poppins(
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textDark,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ).animate().fadeIn().slideY(begin: 0.1, end: 0),
          
          const SizedBox(height: 20),
          
          // Options
          Text(
            'Select your response:',
            style: GoogleFonts.inter(
              fontWeight: FontWeight.w600,
              color: AppTheme.textDark,
            ),
          ),
          const SizedBox(height: 12),
          
          ...List.generate(question.options?.length ?? 0, (index) {
            final option = question.options![index];
            final isSelected = selectedOption == option;
            
            // Color coding: first options are green (positive), last are red (concerning)
            final colors = [
              AppTheme.successGreen,
              const Color(0xFF8BC34A),
              AppTheme.warningOrange,
              const Color(0xFFFF7043),
              AppTheme.errorRed,
            ];
            final color = colors[index];
            
            return GestureDetector(
              onTap: () {
                setState(() {
                  _responses[question.questionId] = option;
                });
              },
              child: Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isSelected ? color.withOpacity(0.1) : Colors.white,
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
                  ] : null,
                ),
                child: Row(
                  children: [
                    Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isSelected ? color : Colors.transparent,
                        border: Border.all(
                          color: isSelected ? color : AppTheme.textGrey,
                          width: 2,
                        ),
                      ),
                      child: isSelected
                          ? const Icon(Icons.check, size: 14, color: Colors.white)
                          : null,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        option,
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                          color: isSelected ? color : AppTheme.textDark,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ).animate(delay: Duration(milliseconds: 50 * index))
              .fadeIn()
              .slideX(begin: 0.05, end: 0);
          }),
          
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}
