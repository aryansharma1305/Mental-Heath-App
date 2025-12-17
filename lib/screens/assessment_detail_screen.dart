import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/assessment.dart';
import '../services/database_service.dart';

class AssessmentDetailScreen extends StatefulWidget {
  final int assessmentId;

  const AssessmentDetailScreen({
    super.key,
    required this.assessmentId,
  });

  @override
  State<AssessmentDetailScreen> createState() => _AssessmentDetailScreenState();
}

class _AssessmentDetailScreenState extends State<AssessmentDetailScreen> {
  final DatabaseService _databaseService = DatabaseService();
  Assessment? _assessment;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAssessment();
  }

  Future<void> _loadAssessment() async {
    try {
      final assessment = await _databaseService.getAssessment(widget.assessmentId);
      setState(() {
        _assessment = assessment;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading assessment: $e')),
        );
      }
    }
  }

  Future<void> _deleteAssessment() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Assessment'),
        content: const Text(
          'Are you sure you want to delete this assessment? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _databaseService.deleteAssessment(widget.assessmentId);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Assessment deleted successfully')),
          );
          Navigator.pop(context);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error deleting assessment: $e')),
          );
        }
      }
    }
  }

  Color _getCapacityColor(String capacity) {
    switch (capacity.toLowerCase()) {
      case 'has capacity for this decision':
        return Colors.green;
      case 'lacks capacity for this decision':
        return Colors.red;
      case 'fluctuating capacity - reassessment needed':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Assessment Details'),
        actions: [
          if (_assessment != null)
            PopupMenuButton<String>(
              onSelected: (value) {
                if (value == 'delete') {
                  _deleteAssessment();
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(Icons.delete, color: Colors.red),
                      SizedBox(width: 8),
                      Text('Delete', style: TextStyle(color: Colors.red)),
                    ],
                  ),
                ),
              ],
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _assessment == null
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error, size: 64, color: Colors.grey),
                      SizedBox(height: 16),
                      Text(
                        'Assessment not found',
                        style: TextStyle(fontSize: 18, color: Colors.grey),
                      ),
                    ],
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Patient Information Card
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  CircleAvatar(
                                    backgroundColor: _getCapacityColor(_assessment!.overallCapacity),
                                    radius: 30,
                                    child: const Icon(
                                      Icons.person,
                                      color: Colors.white,
                                      size: 30,
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          _assessment!.patientName,
                                          style: const TextStyle(
                                            fontSize: 24,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        Text(
                                          'ID: ${_assessment!.patientId}',
                                          style: const TextStyle(
                                            fontSize: 16,
                                            color: Colors.grey,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: _getCapacityColor(_assessment!.overallCapacity),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  _assessment!.overallCapacity,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Assessment Information Card
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Assessment Information',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 16),
                              _buildInfoRow(
                                'Assessment Date',
                                DateFormat('EEEE, MMMM d, y').format(_assessment!.assessmentDate),
                                Icons.calendar_today,
                              ),
                              _buildInfoRow(
                                'Assessor',
                                _assessment!.assessorName,
                                Icons.person_outline,
                              ),
                              _buildInfoRow(
                                'Role',
                                _assessment!.assessorRole,
                                Icons.work_outline,
                              ),
                              _buildInfoRow(
                                'Decision Context',
                                _assessment!.decisionContext,
                                Icons.description,
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Assessment Responses Card
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Assessment Responses',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'Detailed responses: ${_assessment!.responses.length} items recorded',
                                style: const TextStyle(color: Colors.grey),
                              ),
                              // Note: In a full implementation, you would parse and display
                              // the individual question responses here
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Recommendations Card
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Recommendations',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                _assessment!.recommendations,
                                style: const TextStyle(fontSize: 16),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Metadata Card
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Record Information',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 16),
                              _buildInfoRow(
                                'Created',
                                DateFormat('MMM d, y \'at\' h:mm a').format(_assessment!.createdAt),
                                Icons.add_circle_outline,
                              ),
                              _buildInfoRow(
                                'Last Updated',
                                DateFormat('MMM d, y \'at\' h:mm a').format(_assessment!.updatedAt),
                                Icons.update,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }

  Widget _buildInfoRow(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: Colors.grey),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontWeight: FontWeight.w500,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(fontSize: 16),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}