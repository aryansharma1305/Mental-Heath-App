import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/assessment.dart';
import '../services/mhca_assessment_questions.dart';
import '../services/auth_service.dart';
import '../services/database_service.dart';
import '../theme/app_theme.dart';

class MHCAAssessmentScreen extends StatefulWidget {
  const MHCAAssessmentScreen({super.key});

  @override
  State<MHCAAssessmentScreen> createState() => _MHCAAssessmentScreenState();
}

class _MHCAAssessmentScreenState extends State<MHCAAssessmentScreen> {
  final AuthService _authService = AuthService();
  final PageController _pageController = PageController();

  // Patient header fields
  final _nameController = TextEditingController();
  final _ageSexController = TextEditingController();
  final _pNoController = TextEditingController();
  final _placeController = TextEditingController();
  final _nominatedRepNameController = TextEditingController();
  final _nominatedRepIdController = TextEditingController();
  final _diagnosisController = TextEditingController();
  final _doctorNameController = TextEditingController();

  String _advanceDirective = 'Absent';
  String _purpose = 'Treatment';

  // Assessment responses
  final Map<String, dynamic> _responses = {};
  final Map<String, String> _explanations = {};

  int _currentStep = 0; // 0=patientInfo, 1=gate, 2=sec1, 3=sec2, 4=sec3, 5=sec4, 6=consent
  bool _isSubmitting = false;

  // Steps labelling
  final List<String> _stepTitles = [
    'Patient Information',
    'Obvious Lack of Capacity',
    'Section 1: Understanding',
    'Section 2: Appreciating',
    'Section 3: Communicating',
    'Section 4: Determination',
    'Consent Declaration',
  ];

  int get _totalSteps => _stepTitles.length;

  @override
  void dispose() {
    _nameController.dispose();
    _ageSexController.dispose();
    _pNoController.dispose();
    _placeController.dispose();
    _nominatedRepNameController.dispose();
    _nominatedRepIdController.dispose();
    _diagnosisController.dispose();
    _doctorNameController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  void _goToStep(int step) {
    setState(() => _currentStep = step);
    _pageController.animateToPage(
      step,
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeInOut,
    );
  }

  void _handleNext() {
    // Validate current step
    if (!_validateCurrentStep()) return;

    // Conditional branching
    if (_currentStep == 1) {
      // Gate question
      if (_responses['gate'] == 'Yes') {
        // Skip sections 1-3, go to Section 4 (per MHCA 2017 form)
        _showInfoBanner(
          'Sections 1–3 skipped',
          'Patient has obvious lack of capacity. Proceeding directly to Final Determination as per MHCA 2017.',
          Icons.info_outline,
        );
        _goToStep(5);
        return;
      }
    }

    if (_currentStep < _totalSteps - 1) {
      _goToStep(_currentStep + 1);
    } else {
      _submitAssessment();
    }
  }

  void _handlePrevious() {
    if (_currentStep == 5 && _responses['gate'] == 'Yes') {
      // Go back to gate question (sections 1-3 were skipped)
      _showInfoBanner(
        'Returning to Gate Question',
        'Sections 1–3 were skipped because of obvious lack of capacity. Change your answer to "No" to access those sections.',
        Icons.arrow_back,
      );
      _goToStep(1);
      return;
    }
    if (_currentStep > 0) {
      _goToStep(_currentStep - 1);
    }
  }

  void _showInfoBanner(String title, String message, IconData icon) {
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(icon, color: Colors.white, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: GoogleFonts.inter(
                          fontWeight: FontWeight.w700, fontSize: 13)),
                  const SizedBox(height: 2),
                  Text(message,
                      style: GoogleFonts.inter(fontSize: 11)),
                ],
              ),
            ),
          ],
        ),
        backgroundColor: AppTheme.infoBlue,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 4),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),
    );
  }

  bool _validateCurrentStep() {
    switch (_currentStep) {
      case 0:
        if (_nameController.text.trim().isEmpty) {
          _showError('Please enter patient name or anonymised ID');
          return false;
        }
        return true;
      case 1:
        if (!_responses.containsKey('gate')) {
          _showError('Please answer the question');
          return false;
        }
        return true;
      case 2:
        // Section 1 — require all 4 questions
        for (var q in MHCAAssessmentQuestions.getSection1Questions()) {
          if (!_responses.containsKey(q['id'])) {
            _showError('Please answer all questions in this section');
            return false;
          }
        }
        return true;
      case 3:
        // Section 2 — require 2a at minimum
        if (!_responses.containsKey('2a')) {
          _showError('Please answer question 2A');
          return false;
        }
        // Conditional: if 2a=Yes, require 2b. If 2a=No, require 2c
        if (_responses['2a'] == 'Yes' && !_responses.containsKey('2b')) {
          _showError('Please answer question 2B');
          return false;
        }
        if (_responses['2a'] == 'No' && !_responses.containsKey('2c')) {
          _showError('Please answer question 2C');
          return false;
        }
        return true;
      case 4:
        if (!_responses.containsKey('3a')) {
          _showError('Please answer the question');
          return false;
        }
        return true;
      case 5:
        if (!_responses.containsKey('determination')) {
          _showError('Please select a determination');
          return false;
        }
        return true;
      case 6:
        return true;
      default:
        return true;
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: AppTheme.errorRed,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Future<void> _submitAssessment() async {
    setState(() => _isSubmitting = true);

    try {
      final currentUser = await _authService.getCurrentUserModel();
      final determination =
          MHCAAssessmentQuestions.getDetermination(_responses);
      final summary = MHCAAssessmentQuestions.generateSummary(_responses);

      final assessmentData = {
        'patient_name': _nameController.text.trim(),
        'patient_id': _pNoController.text.trim().isNotEmpty
            ? _pNoController.text.trim()
            : 'MHCA-${DateTime.now().millisecondsSinceEpoch}',
        'age_sex': _ageSexController.text.trim(),
        'place_of_assessment': _placeController.text.trim(),
        'advance_directive': _advanceDirective,
        'purpose': _purpose,
        'nominated_rep_name': _nominatedRepNameController.text.trim(),
        'nominated_rep_id': _nominatedRepIdController.text.trim(),
        'diagnosis': _diagnosisController.text.trim(),
        'doctor_name': _doctorNameController.text.trim(),
        'assessment_date': DateTime.now().toIso8601String(),
        'assessor_id': currentUser?.id ?? 'unknown',
        'assessor_name': currentUser?.fullName ?? 'Unknown',
        'responses': _responses,
        'explanations': _explanations,
        'determination': determination,
        'summary': summary,
        'created_at': DateTime.now().toIso8601String(),
      };

      // Save to local database
      final assessment = Assessment(
        patientId: assessmentData['patient_id'] as String,
        patientName: assessmentData['patient_name'] as String,
        assessmentDate: DateTime.now(),
        assessorName: assessmentData['assessor_name'] as String,
        assessorRole: currentUser?.role.name ?? 'Doctor',
        assessorUserId:
            currentUser?.id != 'unknown' ? currentUser?.id : null,
        decisionContext: 'MHCA Treatment Capacity',
        responses: Map<String, dynamic>.from(_responses)
          ..addAll({'explanations': _explanations}),
        overallCapacity: determination,
        recommendations:
            'Purpose: $_purpose | Advance Directive: $_advanceDirective',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        status: 'completed',
        isSynced: false,
      );

      await DatabaseService().insertAssessment(assessment);

      // Also save to SharedPreferences as backup
      final prefs = await SharedPreferences.getInstance();
      final existing = prefs.getStringList('mhca_assessments') ?? [];
      existing.add(jsonEncode(assessmentData));
      await prefs.setStringList('mhca_assessments', existing);

      if (mounted) {
        _showResultsDialog(determination);
      }
    } catch (e) {
      if (mounted) {
        _showError('Error saving assessment: $e');
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  void _showResultsDialog(String determination) {
    final hasCapacity = determination.contains('Has capacity');

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
              child:
                  Icon(Icons.check_circle, color: AppTheme.successGreen),
            ),
            const SizedBox(width: 12),
            const Expanded(child: Text('Assessment Complete')),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildResultRow('Patient',
                  _nameController.text.trim()),
              _buildResultRow('Purpose', _purpose),
              const Divider(height: 24),
              Text(
                'Determination:',
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textDark,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: hasCapacity
                      ? AppTheme.successGreen.withOpacity(0.1)
                      : AppTheme.warningOrange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: hasCapacity
                        ? AppTheme.successGreen
                        : AppTheme.warningOrange,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      hasCapacity
                          ? Icons.verified
                          : Icons.warning_amber_rounded,
                      color: hasCapacity
                          ? AppTheme.successGreen
                          : AppTheme.warningOrange,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        determination,
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: hasCapacity
                              ? AppTheme.successGreen
                              : AppTheme.warningOrange,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
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
          Flexible(
            child: Text(value,
                style: GoogleFonts.inter(fontWeight: FontWeight.w600),
                textAlign: TextAlign.end),
          ),
        ],
      ),
    );
  }

  void _resetAssessment() {
    setState(() {
      _nameController.clear();
      _ageSexController.clear();
      _pNoController.clear();
      _placeController.clear();
      _nominatedRepNameController.clear();
      _nominatedRepIdController.clear();
      _diagnosisController.clear();
      _doctorNameController.clear();
      _advanceDirective = 'Absent';
      _purpose = 'Treatment';
      _responses.clear();
      _explanations.clear();
      _currentStep = 0;
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
          'MHCA Capacity Assessment',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            color: AppTheme.textDark,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Progress bar
            _buildProgressBar(),

            // Step content
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                onPageChanged: (p) => setState(() => _currentStep = p),
                children: [
                  _buildPatientInfoStep(),
                  _buildGateQuestionStep(),
                  _buildSection1Step(),
                  _buildSection2Step(),
                  _buildSection3Step(),
                  _buildSection4Step(),
                  _buildConsentStep(),
                ],
              ),
            ),

            // Navigation buttons
            _buildNavigationBar(),
          ],
        ),
      ),
    );
  }

  // ============================
  //  PROGRESS BAR
  // ============================
  bool _isStepSkipped(int step) {
    // Steps 2, 3, 4 (Sections 1-3) are skipped when gate='Yes'
    return _responses['gate'] == 'Yes' && (step == 2 || step == 3 || step == 4);
  }

  Widget _buildProgressBar() {
    final bool hasSkippedSteps = _responses['gate'] == 'Yes';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Column(
        children: [
          // Step indicator dots
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(_totalSteps, (index) {
              final isActive = index == _currentStep;
              final isCompleted = index < _currentStep && !_isStepSkipped(index);
              final isSkipped = _isStepSkipped(index);

              return Expanded(
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 2),
                  height: 6,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(3),
                    color: isActive
                        ? AppTheme.primaryColor
                        : isSkipped
                            ? Colors.grey.shade300
                            : isCompleted
                                ? AppTheme.successGreen
                                : AppTheme.dividerColor,
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Step ${_currentStep + 1} of $_totalSteps',
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textDark,
                ),
              ),
              Flexible(
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    _stepTitles[_currentStep],
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.primaryColor,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            ],
          ),
          if (hasSkippedSteps && _currentStep >= 5)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Row(
                children: [
                  Icon(Icons.info_outline, size: 14, color: AppTheme.infoBlue),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      'Sections 1–3 skipped (obvious lack of capacity)',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: AppTheme.infoBlue,
                        fontStyle: FontStyle.italic,
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

  // ============================
  //  NAVIGATION BAR
  // ============================
  Widget _buildNavigationBar() {
    final isLastStep = _currentStep == _totalSteps - 1;
    return Container(
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
          if (_currentStep > 0)
            Expanded(
              child: OutlinedButton(
                onPressed: _handlePrevious,
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
                    Text('Previous',
                        style: GoogleFonts.inter(
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textGrey)),
                  ],
                ),
              ),
            ),
          if (_currentStep > 0) const SizedBox(width: 16),
          Expanded(
            child: ElevatedButton(
              onPressed: _isSubmitting ? null : _handleNext,
              style: ElevatedButton.styleFrom(
                backgroundColor: isLastStep
                    ? AppTheme.successGreen
                    : AppTheme.textDark,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: _isSubmitting
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor:
                            AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          isLastStep ? 'Submit' : 'Next',
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Icon(isLastStep ? Icons.check : Icons.arrow_forward),
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================
  //  STEP 0: PATIENT INFO
  // ============================
  Widget _buildPatientInfoStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: AppTheme.blueGradient,
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
                  child: Icon(Icons.medical_information_outlined,
                      color: AppTheme.infoBlue, size: 28),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Capacity Assessment',
                          style: GoogleFonts.poppins(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.textDark)),
                      Text(
                          'Treatment Decisions including Admission\n(MHCA 2017, Sec 102/103)',
                          style: GoogleFonts.inter(
                              fontSize: 12, color: AppTheme.textGrey)),
                    ],
                  ),
                ),
              ],
            ),
          ).animate().fadeIn().slideY(begin: -0.2, end: 0),

          const SizedBox(height: 24),

          _buildTextField('Name / Anonymised ID *', _nameController,
              Icons.person_outline),
          _buildTextField(
              'Age / Sex', _ageSexController, Icons.cake_outlined),
          _buildTextField(
              'P. No', _pNoController, Icons.badge_outlined),
          _buildTextField('Place of Assessment', _placeController,
              Icons.location_on_outlined),

          const SizedBox(height: 16),

          // Advance Directive
          Text('Advance Directive',
              style: GoogleFonts.inter(
                  fontWeight: FontWeight.w600, color: AppTheme.textDark)),
          const SizedBox(height: 8),
          _buildChipSelector(
            MHCAAssessmentQuestions.advanceDirectiveOptions,
            _advanceDirective,
            (val) => setState(() => _advanceDirective = val),
          ),

          const SizedBox(height: 16),

          // Purpose
          Text('Purpose of this Assessment',
              style: GoogleFonts.inter(
                  fontWeight: FontWeight.w600, color: AppTheme.textDark)),
          const SizedBox(height: 8),
          _buildChipSelector(
            MHCAAssessmentQuestions.purposeOptions,
            _purpose,
            (val) => setState(() => _purpose = val),
          ),

          const SizedBox(height: 16),

          _buildTextField('Nominated Representative Name',
              _nominatedRepNameController, Icons.person_add_outlined),
          _buildTextField('Nominated Representative ID',
              _nominatedRepIdController, Icons.fingerprint),
          _buildTextField('Diagnosis (provisional)', _diagnosisController,
              Icons.medical_services_outlined),
          _buildTextField('Doctor / Assessor Name', _doctorNameController,
              Icons.local_hospital_outlined),

          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildTextField(
      String label, TextEditingController controller, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon),
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }

  Widget _buildChipSelector(
      List<String> options, String selectedValue, Function(String) onSelected) {
    return Wrap(
      spacing: 8,
      children: options.map((opt) {
        final isSelected = opt == selectedValue;
        return ChoiceChip(
          label: Text(opt),
          selected: isSelected,
          onSelected: (_) => onSelected(opt),
          selectedColor: AppTheme.primaryColor,
          labelStyle: GoogleFonts.inter(
            color: isSelected ? Colors.white : AppTheme.textDark,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
        );
      }).toList(),
    );
  }

  // ============================
  //  STEP 1: GATE QUESTION
  // ============================
  Widget _buildGateQuestionStep() {
    final gate = MHCAAssessmentQuestions.getGateQuestion();
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(
              gate['section'] as String, Icons.warning_amber_rounded,
              gradient: AppTheme.pinkGradient),
          const SizedBox(height: 16),
          _buildQuestionCard(
            gate['id'] as String,
            gate['text'] as String,
            gate['options'] as List<String>,
            note: gate['note'] as String?,
          ),
        ],
      ),
    );
  }

  // ============================
  //  STEP 2: SECTION 1
  // ============================
  Widget _buildSection1Step() {
    final questions = MHCAAssessmentQuestions.getSection1Questions();
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(
            '1. Understanding',
            Icons.lightbulb_outline,
            gradient: AppTheme.greenGradient,
            subtitle:
                'Understanding the information relevant to taking a decision '
                'on treatment or admission',
          ),
          const SizedBox(height: 16),
          ...questions.map((q) => _buildQuestionCard(
                q['id'] as String,
                '${q['label']}. ${q['text']}',
                q['options'] as List<String>,
                hasExplanation: q['hasExplanation'] == true,
              )),
        ],
      ),
    );
  }

  // ============================
  //  STEP 3: SECTION 2
  // ============================
  Widget _buildSection2Step() {
    final questions = MHCAAssessmentQuestions.getSection2Questions();
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(
            '2. Appreciating',
            Icons.psychology_outlined,
            gradient: AppTheme.purpleGradient,
            subtitle: 'Appreciating reasonably foreseeable consequence of a '
                'decision or lack of decision on the treatment or admission',
          ),
          const SizedBox(height: 16),
          ...questions.map((q) {
            // Conditional display
            if (q.containsKey('showWhen')) {
              final showWhen = q['showWhen'] as Map<String, String>;
              for (var entry in showWhen.entries) {
                if (_responses[entry.key] != entry.value) {
                  return const SizedBox.shrink();
                }
              }
            }
            return _buildQuestionCard(
              q['id'] as String,
              '${q['label']}. ${q['text']}',
              q['options'] as List<String>,
              hasExplanation: q['hasExplanation'] == true,
              note: q['branchNote'] as String?,
            );
          }),
        ],
      ),
    );
  }

  // ============================
  //  STEP 4: SECTION 3
  // ============================
  Widget _buildSection3Step() {
    final questions = MHCAAssessmentQuestions.getSection3Questions();
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(
            '3. Communicating',
            Icons.chat_outlined,
            gradient: AppTheme.beigeGradient,
            subtitle: 'Communicating the decision as per question (1) by means '
                'of speech, expression, gesture or any other means',
          ),
          const SizedBox(height: 16),
          ...questions.map((q) => _buildQuestionCard(
                q['id'] as String,
                '${q['label']}. ${q['text']}',
                q['options'] as List<String>,
                hasExplanation: q['hasExplanation'] == true,
              )),
        ],
      ),
    );
  }

  // ============================
  //  STEP 5: SECTION 4
  // ============================
  Widget _buildSection4Step() {
    final sec4 = MHCAAssessmentQuestions.getSection4();
    final options = sec4['options'] as List<String>;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(
            '4. Final Determination',
            Icons.gavel,
            gradient: AppTheme.blueGradient,
            subtitle: sec4['text'] as String,
          ),
          const SizedBox(height: 24),
          ...options.asMap().entries.map((entry) {
            final idx = entry.key;
            final opt = entry.value;
            final optKey = idx == 0 ? 'a' : 'b';
            final isSelected = _responses['determination'] == optKey;
            final color =
                idx == 0 ? AppTheme.successGreen : AppTheme.warningOrange;

            return Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: GestureDetector(
                onTap: () {
                  setState(() => _responses['determination'] = optKey);
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color:
                        isSelected ? color.withOpacity(0.1) : Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isSelected ? color : AppTheme.dividerColor,
                      width: isSelected ? 2 : 1,
                    ),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: color.withOpacity(0.2),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ]
                        : AppTheme.softShadow,
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: isSelected
                              ? color
                              : color.withOpacity(0.2),
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: isSelected
                              ? const Icon(Icons.check,
                                  color: Colors.white, size: 20)
                              : Text(
                                  optKey.toUpperCase(),
                                  style: GoogleFonts.poppins(
                                    fontWeight: FontWeight.bold,
                                    color: color,
                                  ),
                                ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Text(
                          opt,
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: isSelected
                                ? FontWeight.w600
                                : FontWeight.normal,
                            color: isSelected
                                ? AppTheme.textDark
                                : AppTheme.textMedium,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  // ============================
  //  STEP 6: CONSENT
  // ============================
  Widget _buildConsentStep() {
    final det = _responses['determination'];
    final isPatientConsent = det == 'a';
    final section = isPatientConsent
        ? MHCAAssessmentQuestions.getSection5()
        : MHCAAssessmentQuestions.getSection6();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(
            section['section'] as String,
            Icons.verified_user_outlined,
            gradient: AppTheme.greenGradient,
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: AppTheme.softShadow,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  isPatientConsent
                      ? Icons.person_outline
                      : Icons.people_outline,
                  size: 40,
                  color: AppTheme.primaryColor,
                ),
                const SizedBox(height: 16),
                Text(
                  section['text'] as String,
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    height: 1.6,
                    color: AppTheme.textDark,
                  ),
                ),
                const SizedBox(height: 24),
                if (!isPatientConsent) ...[
                  Text(
                    'Nominated Representative Name:',
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textDark,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _nominatedRepNameController.text.isNotEmpty
                        ? _nominatedRepNameController.text
                        : 'Not provided',
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      color: AppTheme.primaryColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.skyBlue.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                        color: AppTheme.infoBlue.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, color: AppTheme.infoBlue),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          isPatientConsent
                              ? 'The patient acknowledges and consents to making their own treatment decisions.'
                              : 'The nominated representative acknowledges consent on behalf of the patient.',
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            color: AppTheme.textMedium,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ).animate().fadeIn().slideY(begin: 0.1, end: 0),
        ],
      ),
    );
  }

  // ============================
  //  REUSABLE WIDGETS
  // ============================
  Widget _buildSectionHeader(String title, IconData icon,
      {LinearGradient? gradient, String? subtitle}) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: gradient ?? AppTheme.pinkGradient,
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
            child: Icon(icon, size: 28, color: AppTheme.textDark),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textDark)),
                if (subtitle != null)
                  Text(subtitle,
                      style: GoogleFonts.inter(
                          fontSize: 12, color: AppTheme.textGrey)),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn().slideY(begin: -0.1, end: 0);
  }

  Widget _buildQuestionCard(
    String questionId,
    String text,
    List<String> options, {
    bool hasExplanation = false,
    String? note,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: AppTheme.softShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            text,
            style: GoogleFonts.inter(
              fontSize: 15,
              fontWeight: FontWeight.w500,
              color: AppTheme.textDark,
              height: 1.5,
            ),
          ),
          if (note != null) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.softYellow,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline,
                      size: 16, color: AppTheme.warningOrange),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(note,
                        style: GoogleFonts.inter(
                            fontSize: 11, color: AppTheme.textGrey)),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 16),
          // Options
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: options.map((opt) {
              final isSelected = _responses[questionId] == opt;
              Color chipColor;
              if (opt == 'Yes') {
                chipColor = AppTheme.successGreen;
              } else if (opt == 'No') {
                chipColor = AppTheme.errorRed;
              } else {
                chipColor = AppTheme.warningOrange;
              }

              return GestureDetector(
                onTap: () {
                  setState(() => _responses[questionId] = opt);
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? chipColor.withOpacity(0.15)
                        : Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isSelected ? chipColor : AppTheme.dividerColor,
                      width: isSelected ? 2 : 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (isSelected)
                        Icon(Icons.check_circle,
                            size: 18, color: chipColor),
                      if (isSelected) const SizedBox(width: 6),
                      Text(
                        opt,
                        style: GoogleFonts.inter(
                          fontWeight:
                              isSelected ? FontWeight.w600 : FontWeight.normal,
                          color:
                              isSelected ? chipColor : AppTheme.textMedium,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
          // Explanation field
          if (hasExplanation) ...[
            const SizedBox(height: 16),
            TextFormField(
              initialValue: _explanations[questionId],
              onChanged: (val) => _explanations[questionId] = val,
              maxLines: 2,
              decoration: InputDecoration(
                hintText: 'Explanation (optional)',
                filled: true,
                fillColor: AppTheme.backgroundColor,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
              style: GoogleFonts.inter(fontSize: 13),
            ),
          ],
        ],
      ),
    ).animate().fadeIn(delay: 100.ms).slideY(begin: 0.05, end: 0);
  }
}
