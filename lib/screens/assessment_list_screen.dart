import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/assessment.dart';
import '../services/database_service.dart';
import 'assessment_detail_screen.dart';

class AssessmentListScreen extends StatefulWidget {
  const AssessmentListScreen({super.key});

  @override
  State<AssessmentListScreen> createState() => _AssessmentListScreenState();
}

class _AssessmentListScreenState extends State<AssessmentListScreen> {
  final DatabaseService _databaseService = DatabaseService();
  final TextEditingController _searchController = TextEditingController();
  
  List<Assessment> _assessments = [];
  List<Assessment> _filteredAssessments = [];
  bool _isLoading = true;
  String _sortBy = 'date_desc';

  @override
  void initState() {
    super.initState();
    _loadAssessments();
  }

  Future<void> _loadAssessments() async {
    setState(() => _isLoading = true);
    try {
      final assessments = await _databaseService.getAllAssessments();
      setState(() {
        _assessments = assessments;
        _filteredAssessments = assessments;
        _isLoading = false;
      });
      _sortAssessments();
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading assessments: $e')),
        );
      }
    }
  }

  void _filterAssessments(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredAssessments = _assessments;
      } else {
        _filteredAssessments = _assessments.where((assessment) {
          return assessment.patientName.toLowerCase().contains(query.toLowerCase()) ||
                 assessment.patientId.toLowerCase().contains(query.toLowerCase()) ||
                 assessment.assessorName.toLowerCase().contains(query.toLowerCase());
        }).toList();
      }
    });
    _sortAssessments();
  }

  void _sortAssessments() {
    setState(() {
      switch (_sortBy) {
        case 'date_desc':
          _filteredAssessments.sort((a, b) => b.assessmentDate.compareTo(a.assessmentDate));
          break;
        case 'date_asc':
          _filteredAssessments.sort((a, b) => a.assessmentDate.compareTo(b.assessmentDate));
          break;
        case 'name_asc':
          _filteredAssessments.sort((a, b) => a.patientName.compareTo(b.patientName));
          break;
        case 'name_desc':
          _filteredAssessments.sort((a, b) => b.patientName.compareTo(a.patientName));
          break;
      }
    });
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
        title: const Text('All Assessments'),
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              setState(() => _sortBy = value);
              _sortAssessments();
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'date_desc',
                child: Text('Sort by Date (Newest)'),
              ),
              const PopupMenuItem(
                value: 'date_asc',
                child: Text('Sort by Date (Oldest)'),
              ),
              const PopupMenuItem(
                value: 'name_asc',
                child: Text('Sort by Name (A-Z)'),
              ),
              const PopupMenuItem(
                value: 'name_desc',
                child: Text('Sort by Name (Z-A)'),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search by patient name, ID, or assessor...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          _filterAssessments('');
                        },
                      )
                    : null,
              ),
              onChanged: _filterAssessments,
            ),
          ),
          
          // Results count
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Text(
                  '${_filteredAssessments.length} assessment${_filteredAssessments.length != 1 ? 's' : ''}',
                  style: const TextStyle(
                    color: Colors.grey,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          
          // Assessment list
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredAssessments.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              _searchController.text.isNotEmpty
                                  ? Icons.search_off
                                  : Icons.assignment,
                              size: 64,
                              color: Colors.grey,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              _searchController.text.isNotEmpty
                                  ? 'No assessments found'
                                  : 'No assessments yet',
                              style: const TextStyle(
                                fontSize: 18,
                                color: Colors.grey,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _searchController.text.isNotEmpty
                                  ? 'Try adjusting your search terms'
                                  : 'Create your first assessment',
                              style: const TextStyle(color: Colors.grey),
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _loadAssessments,
                        child: ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _filteredAssessments.length,
                          itemBuilder: (context, index) {
                            final assessment = _filteredAssessments[index];
                            return Card(
                              margin: const EdgeInsets.only(bottom: 12),
                              child: ListTile(
                                contentPadding: const EdgeInsets.all(16),
                                leading: CircleAvatar(
                                  backgroundColor: _getCapacityColor(assessment.overallCapacity),
                                  child: const Icon(Icons.person, color: Colors.white),
                                ),
                                title: Text(
                                  assessment.patientName,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const SizedBox(height: 4),
                                    Text('ID: ${assessment.patientId}'),
                                    Text('Assessor: ${assessment.assessorName}'),
                                    Text(
                                      'Date: ${DateFormat('MMM d, y').format(assessment.assessmentDate)}',
                                    ),
                                    const SizedBox(height: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: _getCapacityColor(assessment.overallCapacity),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        assessment.overallCapacity,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                trailing: const Icon(Icons.arrow_forward_ios),
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
                      ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}