import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/assessment.dart';
import '../services/database_service.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';
import '../widgets/custom_widgets.dart';
import 'assessment_detail_screen.dart';

class DoctorReviewScreen extends StatefulWidget {
  const DoctorReviewScreen({super.key});

  @override
  State<DoctorReviewScreen> createState() => _DoctorReviewScreenState();
}

class _DoctorReviewScreenState extends State<DoctorReviewScreen> {
  final DatabaseService _databaseService = DatabaseService();
  final AuthService _authService = AuthService();
  
  List<Assessment> _pendingAssessments = [];
  List<Assessment> _reviewedAssessments = [];
  bool _isLoading = true;
  int _selectedTab = 0; // 0 = Pending, 1 = Reviewed

  @override
  void initState() {
    super.initState();
    _loadAssessments();
  }

  Future<void> _loadAssessments() async {
    setState(() => _isLoading = true);
    try {
      final allAssessments = await _databaseService.getAllAssessments();
      setState(() {
        _pendingAssessments = allAssessments
            .where((a) => a.overallCapacity == 'Pending Review')
            .toList();
        _reviewedAssessments = allAssessments
            .where((a) => a.overallCapacity != 'Pending Review')
            .toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _reviewAssessment(Assessment assessment, String capacity, String recommendations) async {
    try {
      final currentUser = await _authService.getCurrentUserModel();
      if (currentUser == null) return;

      final updatedAssessment = Assessment(
        id: assessment.id,
        patientId: assessment.patientId,
        patientName: assessment.patientName,
        assessmentDate: assessment.assessmentDate,
        assessorName: assessment.assessorName,
        assessorRole: assessment.assessorRole,
        decisionContext: assessment.decisionContext,
        responses: assessment.responses,
        overallCapacity: capacity,
        recommendations: recommendations,
        createdAt: assessment.createdAt,
        updatedAt: DateTime.now(),
      );

      await _databaseService.updateAssessment(updatedAssessment);
      await _loadAssessments();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Assessment reviewed successfully'),
            backgroundColor: AppTheme.accentGreen,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error reviewing assessment: $e')),
        );
      }
    }
  }

  void _showReviewDialog(Assessment assessment) {
    final capacityController = TextEditingController();
    final recommendationsController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Review Assessment - ${assessment.patientName}'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Overall Capacity:', style: AppTheme.labelLarge),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                ),
                items: [
                  'Has capacity for this decision',
                  'Lacks capacity for this decision',
                  'Fluctuating capacity - reassessment needed',
                  'Undetermined - more information needed',
                ].map((option) {
                  return DropdownMenuItem(
                    value: option,
                    child: Text(option),
                  );
                }).toList(),
                onChanged: (value) {
                  capacityController.text = value ?? '';
                },
              ),
              const SizedBox(height: 16),
              Text('Recommendations:', style: AppTheme.labelLarge),
              const SizedBox(height: 8),
              TextField(
                controller: recommendationsController,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: 'Enter recommendations...',
                ),
                maxLines: 4,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (capacityController.text.isNotEmpty) {
                _reviewAssessment(
                  assessment,
                  capacityController.text,
                  recommendationsController.text,
                );
                Navigator.pop(context);
              }
            },
            child: const Text('Submit Review'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Review Assessments'),
      ),
      body: Column(
        children: [
          // Tabs
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _selectedTab = 0),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: _selectedTab == 0
                          ? AppTheme.primaryBlue
                          : Colors.grey[200],
                      border: Border(
                        bottom: BorderSide(
                          color: _selectedTab == 0
                              ? AppTheme.primaryBlue
                              : Colors.transparent,
                          width: 3,
                        ),
                      ),
                    ),
                    child: Text(
                      'Pending (${_pendingAssessments.length})',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: _selectedTab == 0 ? Colors.white : Colors.black,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _selectedTab = 1),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: _selectedTab == 1
                          ? AppTheme.primaryBlue
                          : Colors.grey[200],
                      border: Border(
                        bottom: BorderSide(
                          color: _selectedTab == 1
                              ? AppTheme.primaryBlue
                              : Colors.transparent,
                          width: 3,
                        ),
                      ),
                    ),
                    child: Text(
                      'Reviewed (${_reviewedAssessments.length})',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: _selectedTab == 1 ? Colors.white : Colors.black,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          // Content
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _selectedTab == 0
                    ? _buildPendingList()
                    : _buildReviewedList(),
          ),
        ],
      ),
    );
  }

  Widget _buildPendingList() {
    if (_pendingAssessments.isEmpty) {
      return const Center(
        child: Text('No pending assessments'),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadAssessments,
      child: ListView.builder(
        itemCount: _pendingAssessments.length,
        itemBuilder: (context, index) {
          final assessment = _pendingAssessments[index];
          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: AppTheme.warningOrange,
                child: const Icon(Icons.pending, color: Colors.white),
              ),
              title: Text(assessment.patientName),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Date: ${DateFormat('MMM d, y').format(assessment.assessmentDate)}'),
                  Text('Assessed by: ${assessment.assessorName}'),
                ],
              ),
              trailing: ElevatedButton(
                onPressed: () => _showReviewDialog(assessment),
                child: const Text('Review'),
              ),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => AssessmentDetailScreen(
                      assessmentId: assessment.id!,
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildReviewedList() {
    if (_reviewedAssessments.isEmpty) {
      return const Center(
        child: Text('No reviewed assessments'),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadAssessments,
      child: ListView.builder(
        itemCount: _reviewedAssessments.length,
        itemBuilder: (context, index) {
          final assessment = _reviewedAssessments[index];
          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: _getCapacityColor(assessment.overallCapacity),
                child: const Icon(Icons.check, color: Colors.white),
              ),
              title: Text(assessment.patientName),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Date: ${DateFormat('MMM d, y').format(assessment.assessmentDate)}'),
                  Text('Capacity: ${assessment.overallCapacity}'),
                ],
              ),
              trailing: Chip(
                label: Text(
                  assessment.overallCapacity,
                  style: const TextStyle(fontSize: 12, color: Colors.white),
                ),
                backgroundColor: _getCapacityColor(assessment.overallCapacity),
              ),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => AssessmentDetailScreen(
                      assessmentId: assessment.id!,
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }

  Color _getCapacityColor(String capacity) {
    if (capacity.toLowerCase().contains('has capacity')) {
      return Colors.green;
    } else if (capacity.toLowerCase().contains('lacks capacity')) {
      return Colors.red;
    } else if (capacity.toLowerCase().contains('fluctuating')) {
      return Colors.orange;
    }
    return Colors.grey;
  }
}

