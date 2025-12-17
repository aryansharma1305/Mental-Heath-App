import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/question.dart';
import '../models/assessment.dart';
import '../services/question_service.dart';
import '../services/database_service.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';
import '../widgets/custom_widgets.dart';
import 'package:intl/intl.dart';

class PatientAssessmentScreen extends StatefulWidget {
  const PatientAssessmentScreen({super.key});

  @override
  State<PatientAssessmentScreen> createState() => _PatientAssessmentScreenState();
}

class _PatientAssessmentScreenState extends State<PatientAssessmentScreen> {
  final _formKey = GlobalKey<FormState>();
  final _pageController = PageController();
  final QuestionService _questionService = QuestionService();
  final DatabaseService _databaseService = DatabaseService();
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
      final questions = await _questionService.getActiveQuestions();
      setState(() {
        _questions = questions;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading questions: $e')),
        );
      }
    }
  }

  void _nextPage() {
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

      final assessment = Assessment(
        patientId: currentUser.id,
        patientName: currentUser.fullName,
        assessmentDate: DateTime.now(),
        assessorName: currentUser.fullName,
        assessorRole: currentUser.role.displayName,
        decisionContext: 'Self-assessment',
        responses: _responses,
        overallCapacity: 'Pending Review',
        recommendations: '',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await _databaseService.insertAssessment(assessment);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Assessment submitted successfully! A healthcare professional will review it.'),
            backgroundColor: AppTheme.accentGreen,
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error submitting assessment: $e')),
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
          child: Text('No questions available. Please contact an administrator.'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mental Capacity Assessment'),
        actions: [
          if (_currentPage == _questions.length - 1)
            TextButton(
              onPressed: _isSubmitting ? null : _submitAssessment,
              child: _isSubmitting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Submit', style: TextStyle(color: Colors.white)),
            ),
        ],
      ),
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
                  if (_currentPage > 0)
                    ElevatedButton(
                      onPressed: _previousPage,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.grey,
                      ),
                      child: const Text('Previous'),
                    )
                  else
                    const SizedBox(),
                  if (_currentPage < _questions.length - 1)
                    ElevatedButton(
                      onPressed: _nextPage,
                      child: const Text('Next'),
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
                color: AppTheme.primaryBlue.withOpacity(0.1),
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
          Text(
            question.text,
            style: AppTheme.headingSmall,
          ),
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
        return Column(
          children: [
            RadioListTile<String>(
              title: const Text('Yes'),
              value: 'Yes',
              groupValue: _responses[question.questionId]?.toString(),
              onChanged: (value) {
                setState(() => _responses[question.questionId] = value);
              },
            ),
            RadioListTile<String>(
              title: const Text('No'),
              value: 'No',
              groupValue: _responses[question.questionId]?.toString(),
              onChanged: (value) {
                setState(() => _responses[question.questionId] = value);
              },
            ),
          ],
        );
      case QuestionType.multipleChoice:
        return Column(
          children: question.options!.map((option) {
            return RadioListTile<String>(
              title: Text(option),
              value: option,
              groupValue: _responses[question.questionId]?.toString(),
              onChanged: (value) {
                setState(() => _responses[question.questionId] = value);
              },
            );
          }).toList(),
        );
      case QuestionType.scale:
        return Column(
          children: question.options!.map((option) {
            return RadioListTile<String>(
              title: Text(option),
              value: option,
              groupValue: _responses[question.questionId]?.toString(),
              onChanged: (value) {
                setState(() => _responses[question.questionId] = value);
              },
            );
          }).toList(),
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

