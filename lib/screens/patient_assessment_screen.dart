import 'package:flutter/material.dart';
import '../models/question.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';

class PatientAssessmentScreen extends StatefulWidget {
  final int templateId;

  const PatientAssessmentScreen({super.key, required this.templateId});

  @override
  State<PatientAssessmentScreen> createState() =>
      _PatientAssessmentScreenState();
}

class _PatientAssessmentScreenState extends State<PatientAssessmentScreen> {
  final _formKey = GlobalKey<FormState>();
  final _pageController = PageController();
  final ApiService _apiService = ApiService();
  final AuthService _authService = AuthService();

  List<Question> _questions = [];
  final Map<String, dynamic> _responses = {};
  int _currentPage = 0;
  bool _isLoading = true;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _loadQuestions();
  }

  Future<void> _loadQuestions() async {
    try {
      // Load questions from the selected assessment template
      final templateData = await _apiService.getTemplateWithQuestions(
        widget.templateId,
      );
      final questions = templateData?['questions'] as List<Question>?;
      if (questions != null && questions.isNotEmpty) {
        setState(() {
          _questions = questions;
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Assessment template not found or has no questions.',
              ),
              backgroundColor: AppTheme.errorRed,
            ),
          );
          Navigator.pop(context);
        }
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error loading questions: $e')));
      }
    }
  }

  void _nextPage() {
    // Validate current question before moving forward
    final currentQuestion = _questions[_currentPage];

    // Check if required question is answered
    if (currentQuestion.required) {
      final response = _responses[currentQuestion.questionId];
      if (response == null || response.toString().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Please answer this required question before continuing.',
            ),
            backgroundColor: AppTheme.errorRed,
          ),
        );
        return;
      }
    }

    // Save response and move to next page
    if (_currentPage < _questions.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _handleNextOrSubmit() {
    // Validate current question
    final currentQuestion = _questions[_currentPage];

    if (currentQuestion.required) {
      final response = _responses[currentQuestion.questionId];
      if (response == null || response.toString().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please answer this required question.'),
            backgroundColor: AppTheme.errorRed,
          ),
        );
        return;
      }
    }

    // If last question, submit; otherwise, go to next
    if (_currentPage == _questions.length - 1) {
      _submitAssessment();
    } else {
      _nextPage();
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

  Future<void> _submitAssessment() async {
    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please answer all required questions')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final currentUser = await _authService.getCurrentUserModel();
      if (currentUser == null) {
        throw Exception('User not found');
      }

      // Save each response to question_responses table via API
      for (var question in _questions) {
        final response = _responses[question.questionId];
        if (response != null && question.id != null) {
          await _apiService.saveQuestionResponse(
            templateId: widget.templateId,
            questionId: question.id!,
            patientUserId: currentUser.id,
            answer: response.toString(),
          );
        }
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Assessment submitted successfully! A healthcare professional will review it.',
            ),
            backgroundColor: AppTheme.accentGreen,
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error submitting assessment: $e'),
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

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Assessment')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_questions.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Assessment')),
        body: const Center(
          child: Text(
            'No questions available. Please contact an administrator.',
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Mental Capacity Assessment')),
      body: Form(
        key: _formKey,
        child: Column(
          children: [
            // Progress indicator
            Container(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  LinearProgressIndicator(
                    value: (_currentPage + 1) / _questions.length,
                    backgroundColor: Colors.grey[300],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Question ${_currentPage + 1} of ${_questions.length}',
                    style: AppTheme.bodyMedium,
                  ),
                ],
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                physics:
                    const NeverScrollableScrollPhysics(), // Disable swipe - only button navigation
                onPageChanged: (page) => setState(() => _currentPage = page),
                itemCount: _questions.length,
                itemBuilder: (context, index) {
                  return _buildQuestionPage(_questions[index]);
                },
              ),
            ),
            // Navigation buttons
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Previous button
                  if (_currentPage > 0)
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _previousPage,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.grey[600],
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: const Text('Previous'),
                      ),
                    )
                  else
                    const SizedBox(),

                  // Spacing between buttons
                  if (_currentPage > 0) const SizedBox(width: 16),

                  // Next or Submit button
                  Expanded(
                    flex: _currentPage > 0 ? 1 : 2,
                    child: ElevatedButton(
                      onPressed: _isSubmitting ? null : _handleNextOrSubmit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _currentPage == _questions.length - 1
                            ? AppTheme.accentGreen
                            : AppTheme.primaryBlue,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: _isSubmitting
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.white,
                                ),
                              ),
                            )
                          : Text(
                              _currentPage == _questions.length - 1
                                  ? 'Submit Assessment'
                                  : 'Next',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
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

  Widget _buildQuestionPage(Question question) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (question.category != null) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppTheme.primaryBlue.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                question.category!,
                style: AppTheme.bodySmall.copyWith(
                  color: AppTheme.primaryBlue,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
          Text(question.text, style: AppTheme.headingSmall),
          if (question.required)
            Text(
              ' *',
              style: AppTheme.headingSmall.copyWith(color: Colors.red),
            ),
          const SizedBox(height: 32),
          _buildQuestionInput(question),
        ],
      ),
    );
  }

  Widget _buildQuestionInput(Question question) {
    switch (question.type) {
      case QuestionType.yesNo:
        return RadioGroup<String>(
          groupValue: _responses[question.questionId]?.toString(),
          onChanged: (value) {
            setState(() => _responses[question.questionId] = value);
          },
          child: const Column(
            children: [
              RadioListTile<String>(title: Text('Yes'), value: 'Yes'),
              RadioListTile<String>(title: Text('No'), value: 'No'),
            ],
          ),
        );
      case QuestionType.multipleChoice:
        return RadioGroup<String>(
          groupValue: _responses[question.questionId]?.toString(),
          onChanged: (value) {
            setState(() => _responses[question.questionId] = value);
          },
          child: Column(
            children: question.options!.map((option) {
              return RadioListTile<String>(title: Text(option), value: option);
            }).toList(),
          ),
        );
      case QuestionType.scale:
        return RadioGroup<String>(
          groupValue: _responses[question.questionId]?.toString(),
          onChanged: (value) {
            setState(() => _responses[question.questionId] = value);
          },
          child: Column(
            children: question.options!.map((option) {
              return RadioListTile<String>(title: Text(option), value: option);
            }).toList(),
          ),
        );
      case QuestionType.textInput:
        return TextFormField(
          decoration: const InputDecoration(
            hintText: 'Enter your response...',
            border: OutlineInputBorder(),
          ),
          maxLines: 5,
          onChanged: (value) {
            _responses[question.questionId] = value;
          },
          validator: question.required
              ? (value) {
                  if (value == null || value.isEmpty) {
                    return 'This field is required';
                  }
                  return null;
                }
              : null,
        );
      default:
        return const SizedBox();
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }
}
