import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import '../models/assessment.dart';
import '../models/question.dart';
import '../services/database_service.dart';
import '../services/assessment_questions.dart';

class NewAssessmentScreen extends StatefulWidget {
  const NewAssessmentScreen({super.key});

  @override
  State<NewAssessmentScreen> createState() => _NewAssessmentScreenState();
}

class _NewAssessmentScreenState extends State<NewAssessmentScreen> {
  final _formKey = GlobalKey<FormState>();
  final _pageController = PageController();
  final DatabaseService _databaseService = DatabaseService();
  
  // Form controllers
  final _patientIdController = TextEditingController();
  final _decisionContextController = TextEditingController();
  final _recommendationsController = TextEditingController();
  
  DateTime _assessmentDate = DateTime.now();
  String _assessorName = '';
  String _assessorRole = '';
  String _overallCapacity = '';
  
  List<Question> _questions = [];
  final Map<String, QuestionResponse> _responses = {};
  int _currentPage = 0;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadUserInfo();
    _questions = AssessmentQuestions.getStandardQuestions();
  }

  Future<void> _loadUserInfo() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _assessorName = prefs.getString('full_name') ?? '';
      _assessorRole = prefs.getString('role') ?? '';
    });
  }

  void _nextPage() {
    if (_currentPage < 2) {
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

  Future<void> _saveAssessment() async {
    if (!_formKey.currentState!.validate()) return;
    if (_overallCapacity.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select overall capacity assessment')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Get the logged-in doctor's user ID
      final prefs = await SharedPreferences.getInstance();
      final assessorUserId = prefs.getString('user_id');
      
      final assessment = Assessment(
        patientId: _patientIdController.text,
        patientName: 'Anonymised', // Privacy: No names stored
        assessmentDate: _assessmentDate,
        assessorName: _assessorName,
        assessorRole: _assessorRole,
        assessorUserId: assessorUserId, // Save doctor's user ID
        decisionContext: _decisionContextController.text,
        responses: _responses.map((key, value) => MapEntry(key, value.toMap())),
        overallCapacity: _overallCapacity,
        recommendations: _recommendationsController.text,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await _databaseService.insertAssessment(assessment);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Assessment saved successfully')),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving assessment: $e')),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('New Assessment'),
        actions: [
          if (_currentPage == 2)
            TextButton(
              onPressed: _isLoading ? null : _saveAssessment,
              child: _isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Text(
                      'Save',
                      style: TextStyle(color: Colors.white),
                    ),
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: Column(
          children: [
            // Progress indicator
            LinearProgressIndicator(
              value: (_currentPage + 1) / 3,
              backgroundColor: Colors.grey[300],
            ),
            Expanded(
              child: PageView(
                controller: _pageController,
                onPageChanged: (page) => setState(() => _currentPage = page),
                children: [
                  _buildPatientInfoPage(),
                  _buildQuestionsPage(),
                  _buildSummaryPage(),
                ],
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
                  if (_currentPage < 2)
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

  Widget _buildPatientInfoPage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Patient Information',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 24),
          TextFormField(
            controller: _patientIdController,
            decoration: const InputDecoration(
              labelText: 'Anonymised Patient ID',
              helperText: 'For privacy, no names are stored',
              prefixIcon: Icon(Icons.badge),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter patient ID';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          ListTile(
            leading: const Icon(Icons.calendar_today),
            title: const Text('Assessment Date'),
            subtitle: Text(DateFormat('EEEE, MMMM d, y').format(_assessmentDate)),
            onTap: () async {
              final date = await showDatePicker(
                context: context,
                initialDate: _assessmentDate,
                firstDate: DateTime.now().subtract(const Duration(days: 30)),
                lastDate: DateTime.now().add(const Duration(days: 7)),
              );
              if (date != null) {
                setState(() => _assessmentDate = date);
              }
            },
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _decisionContextController,
            decoration: const InputDecoration(
              labelText: 'Decision Context',
              helperText: 'What decision is being assessed?',
              prefixIcon: Icon(Icons.description),
            ),
            maxLines: 3,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please describe the decision context';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Assessor Information',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text('Name: $_assessorName'),
                  Text('Role: $_assessorRole'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuestionsPage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Assessment Questions',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          ..._questions.map((question) => _buildQuestionWidget(question)),
        ],
      ),
    );
  }

  Widget _buildQuestionWidget(Question question) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              question.text,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            if (question.required)
              const Text(
                ' *',
                style: TextStyle(color: Colors.red),
              ),
            const SizedBox(height: 12),
            _buildQuestionInput(question),
          ],
        ),
      ),
    );
  }

  Widget _buildQuestionInput(Question question) {
    switch (question.type) {
      case QuestionType.yesNo:
        return Row(
          children: [
            Expanded(
              child: RadioListTile<String>(
                title: const Text('Yes'),
                value: 'Yes',
                groupValue: _responses[question.questionId]?.answer,
                onChanged: (value) {
                  setState(() {
                    _responses[question.questionId] = QuestionResponse(
                      questionId: question.questionId,
                      answer: value,
                    );
                  });
                },
              ),
            ),
            Expanded(
              child: RadioListTile<String>(
                title: const Text('No'),
                value: 'No',
                groupValue: _responses[question.questionId]?.answer,
                onChanged: (value) {
                  setState(() {
                    _responses[question.questionId] = QuestionResponse(
                      questionId: question.questionId,
                      answer: value,
                    );
                  });
                },
              ),
            ),
          ],
        );
      case QuestionType.multipleChoice:
        return Column(
          children: question.options!.map((option) {
            return RadioListTile<String>(
              title: Text(option),
              value: option,
                groupValue: _responses[question.questionId]?.answer,
              onChanged: (value) {
                setState(() {
                  _responses[question.questionId] = QuestionResponse(
                    questionId: question.questionId,
                    answer: value,
                  );
                });
              },
            );
          }).toList(),
        );
      case QuestionType.textInput:
        return TextFormField(
          decoration: const InputDecoration(
            hintText: 'Enter your response...',
          ),
          maxLines: 3,
          onChanged: (value) {
            _responses[question.questionId] = QuestionResponse(
              questionId: question.questionId,
              answer: value,
            );
          },
        );
      default:
        return const SizedBox();
    }
  }

  Widget _buildSummaryPage() {
    // Calculate domain scores from responses
    final responseMap = _responses.map((key, value) => MapEntry(key, value.toMap()));
    final scoreData = AssessmentQuestions.calculateCapacityScore(responseMap);
    final domainScores = scoreData['categoryScores'] as Map<String, int>? ?? {};
    final flaggedDomains = AssessmentQuestions.getDomainsRequiringFollowUp(domainScores);
    final percentage = scoreData['percentage'] as double;
    final recommendations = AssessmentQuestions.getRecommendations(percentage, domainScores);
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Assessment Summary',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          
          // DSM-5 Domain Scores Card
          Card(
            color: Colors.blue.shade50,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.assessment, color: Colors.blue.shade700),
                      const SizedBox(width: 8),
                      Text(
                        'DSM-5 Cross-Cutting Symptom Measure Results',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue.shade800,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Domain scores grid
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: domainScores.entries.map((entry) {
                      final isFlagged = flaggedDomains.contains(entry.key);
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: isFlagged ? Colors.red.shade100 : Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: isFlagged ? Colors.red.shade400 : Colors.grey.shade300,
                          ),
                        ),
                        child: Column(
                          children: [
                            Text(
                              entry.key.split('.').last.trim(),
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                                color: isFlagged ? Colors.red.shade800 : Colors.grey.shade700,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${entry.value}',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: isFlagged ? Colors.red.shade700 : Colors.blue.shade700,
                              ),
                            ),
                            if (isFlagged)
                              Text(
                                '⚠ Flagged',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: Colors.red.shade600,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 12),
                  // Scoring legend
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text(
                      'Scoring: 0=None, 1=Slight, 2=Mild, 3=Moderate, 4=Severe\n'
                      'Flagged: Substance Use/Psychosis/Suicidal Ideation ≥1, Others ≥2',
                      style: TextStyle(fontSize: 10, fontStyle: FontStyle.italic),
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          // Flagged Domains Alert
          if (flaggedDomains.isNotEmpty) ...[
            const SizedBox(height: 16),
            Card(
              color: Colors.red.shade50,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.warning_amber, color: Colors.red.shade700),
                        const SizedBox(width: 8),
                        Text(
                          'Domains Requiring Detailed Assessment',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.red.shade800,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ...flaggedDomains.map((domain) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2),
                      child: Row(
                        children: [
                          Icon(Icons.arrow_right, size: 16, color: Colors.red.shade600),
                          Expanded(child: Text(domain, style: const TextStyle(fontSize: 13))),
                        ],
                      ),
                    )),
                  ],
                ),
              ),
            ),
          ],
          
          // System Recommendations
          if (recommendations.isNotEmpty) ...[
            const SizedBox(height: 16),
            Card(
              color: Colors.orange.shade50,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.lightbulb_outline, color: Colors.orange.shade700),
                        const SizedBox(width: 8),
                        Text(
                          'Clinical Recommendations',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.orange.shade800,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ...recommendations.map((rec) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('• ', style: TextStyle(fontWeight: FontWeight.bold)),
                          Expanded(child: Text(rec, style: const TextStyle(fontSize: 13))),
                        ],
                      ),
                    )),
                  ],
                ),
              ),
            ),
          ],
          
          const SizedBox(height: 24),
          
          // Overall Capacity Assessment
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Overall Capacity Assessment',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Based on the above DSM-5 results, select the overall capacity determination:',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                  const SizedBox(height: 12),
                  ...AssessmentQuestions.getCapacityOptions().map((option) {
                    return RadioListTile<String>(
                      title: Text(option),
                      value: option,
                      groupValue: _overallCapacity,
                      onChanged: (value) {
                        setState(() => _overallCapacity = value!);
                      },
                    );
                  }),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _recommendationsController,
            decoration: const InputDecoration(
              labelText: 'Additional Recommendations and Next Steps',
              helperText: 'Include any additional recommendations beyond system suggestions',
            ),
            maxLines: 4,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please provide recommendations';
              }
              return null;
            },
          ),
          const SizedBox(height: 24),
          const Text(
            'Review Information',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Anonymised ID: ${_patientIdController.text}'),
                  Text('Date: ${DateFormat('MMMM d, y').format(_assessmentDate)}'),
                  Text('Assessor: $_assessorName'),
                  Text('Decision: ${_decisionContextController.text}'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _patientIdController.dispose();
    _decisionContextController.dispose();
    _recommendationsController.dispose();
    _pageController.dispose();
    super.dispose();
  }
}