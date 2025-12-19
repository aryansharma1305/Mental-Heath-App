import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../services/supabase_service.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';
import '../models/assessment.dart';
import '../models/user.dart' as app_models;
import 'assessment_detail_screen.dart';

class DoctorReviewScreen extends StatefulWidget {
  const DoctorReviewScreen({super.key});

  @override
  State<DoctorReviewScreen> createState() => _DoctorReviewScreenState();
}

class _DoctorReviewScreenState extends State<DoctorReviewScreen> {
  final SupabaseService _supabaseService = SupabaseService();
  final AuthService _authService = AuthService();
  
  List<Assessment> _allAssessments = [];
  List<Assessment> _filteredAssessments = [];
  Map<String, app_models.User> _patientCache = {};
  bool _isLoading = true;
  int _selectedTab = 0; // 0 = All, 1 = Pending, 2 = Reviewed
  String _statusFilter = 'all'; // 'all', 'pending', 'reviewed', 'completed'
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadAssessments();
  }

  Future<void> _loadAssessments() async {
    setState(() => _isLoading = true);
    try {
      if (SupabaseService.isAvailable) {
        _allAssessments = await _supabaseService.getAssessmentsForReview();
        
        // Load patient information
        for (var assessment in _allAssessments) {
          if (assessment.patientId.isNotEmpty && !_patientCache.containsKey(assessment.patientId)) {
            final patient = await _supabaseService.getUserById(assessment.patientId);
            if (patient != null) {
              _patientCache[assessment.patientId] = patient;
            }
          }
        }
        
        _applyFilters();
      }
    } catch (e) {
      debugPrint('Error loading assessments: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _applyFilters() {
    setState(() {
      _filteredAssessments = _allAssessments.where((assessment) {
        // Status filter
        if (_statusFilter != 'all' && assessment.status != _statusFilter) {
          return false;
        }
        
        // Search filter
        if (_searchQuery.isNotEmpty) {
          final query = _searchQuery.toLowerCase();
          final patientName = assessment.patientName.toLowerCase();
          final patientId = assessment.patientId.toLowerCase();
          final assessorName = assessment.assessorName.toLowerCase();
          
          if (!patientName.contains(query) && 
              !patientId.contains(query) && 
              !assessorName.contains(query)) {
            return false;
          }
        }
        
        return true;
      }).toList();
      
      // Sort by date (newest first)
      _filteredAssessments.sort((a, b) => b.assessmentDate.compareTo(a.assessmentDate));
    });
  }

  Color _getStatusColor(String? status) {
    switch (status) {
      case 'pending':
        return Colors.orange;
      case 'reviewed':
        return Colors.blue;
      case 'completed':
        return Colors.green;
      default:
        return Colors.grey;
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

  String _getStatusLabel(String? status) {
    switch (status) {
      case 'pending':
        return 'Pending Review';
      case 'reviewed':
        return 'Reviewed';
      case 'completed':
        return 'Completed';
      default:
        return 'Unknown';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Review Assessments'),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () => _showFilterDialog(),
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadAssessments,
          ),
        ],
        bottom: TabBar(
          onTap: (index) {
            setState(() {
              _selectedTab = index;
              switch (index) {
                case 0:
                  _statusFilter = 'all';
                  break;
                case 1:
                  _statusFilter = 'pending';
                  break;
                case 2:
                  _statusFilter = 'reviewed';
                  break;
              }
              _applyFilters();
            });
          },
          tabs: const [
            Tab(icon: Icon(Icons.list), text: 'All'),
            Tab(icon: Icon(Icons.pending), text: 'Pending'),
            Tab(icon: Icon(Icons.verified), text: 'Reviewed'),
          ],
        ),
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search by patient name, ID, or assessor...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          setState(() {
                            _searchQuery = '';
                            _applyFilters();
                          });
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                  _applyFilters();
                });
              },
            ),
          ),
          
          // Results count
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Text(
                  '${_filteredAssessments.length} assessment${_filteredAssessments.length != 1 ? 's' : ''}',
                  style: GoogleFonts.inter(
                    color: Colors.grey[600],
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 8),
          
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
                              Icons.assignment_outlined,
                              size: 80,
                              color: Colors.grey[300],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              _searchQuery.isNotEmpty
                                  ? 'No assessments found'
                                  : 'No assessments to review',
                              style: GoogleFonts.inter(
                                fontSize: 18,
                                color: Colors.grey[600],
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _searchQuery.isNotEmpty
                                  ? 'Try adjusting your search terms'
                                  : 'Patient assessments will appear here',
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                color: Colors.grey[500],
                              ),
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
                            final patient = _patientCache[assessment.patientId];
                            
                            return Card(
                              margin: const EdgeInsets.only(bottom: 12),
                              elevation: 2,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: InkWell(
                                onTap: () async {
                                  final result = await Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => AssessmentDetailScreen(
                                        assessmentId: assessment.id!,
                                        allowReview: true,
                                      ),
                                    ),
                                  );
                                  
                                  if (result == true) {
                                    _loadAssessments();
                                  }
                                },
                                borderRadius: BorderRadius.circular(12),
                                child: Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          CircleAvatar(
                                            backgroundColor: _getCapacityColor(
                                              assessment.overallCapacity,
                                            ),
                                            radius: 24,
                                            child: const Icon(
                                              Icons.person,
                                              color: Colors.white,
                                              size: 24,
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  assessment.patientName,
                                                  style: GoogleFonts.poppins(
                                                    fontWeight: FontWeight.w600,
                                                    fontSize: 16,
                                                  ),
                                                ),
                                                if (patient != null) ...[
                                                  const SizedBox(height: 2),
                                                  Text(
                                                    patient.email,
                                                    style: GoogleFonts.inter(
                                                      fontSize: 12,
                                                      color: Colors.grey[600],
                                                    ),
                                                  ),
                                                ],
                                              ],
                                            ),
                                          ),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 8,
                                              vertical: 4,
                                            ),
                                            decoration: BoxDecoration(
                                              color: _getStatusColor(assessment.status),
                                              borderRadius: BorderRadius.circular(12),
                                            ),
                                            child: Text(
                                              _getStatusLabel(assessment.status),
                                              style: GoogleFonts.inter(
                                                color: Colors.white,
                                                fontSize: 11,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 12),
                                      Container(
                                        width: double.infinity,
                                        padding: const EdgeInsets.all(10),
                                        decoration: BoxDecoration(
                                          color: _getCapacityColor(
                                            assessment.overallCapacity,
                                          ).withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(8),
                                          border: Border.all(
                                            color: _getCapacityColor(
                                              assessment.overallCapacity,
                                            ).withOpacity(0.3),
                                          ),
                                        ),
                                        child: Text(
                                          assessment.overallCapacity,
                                          style: GoogleFonts.inter(
                                            fontWeight: FontWeight.w500,
                                            fontSize: 14,
                                            color: _getCapacityColor(
                                              assessment.overallCapacity,
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 12),
                                      Row(
                                        children: [
                                          Icon(
                                            Icons.calendar_today,
                                            size: 16,
                                            color: Colors.grey[600],
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            DateFormat('MMM d, y • h:mm a')
                                                .format(assessment.assessmentDate),
                                            style: GoogleFonts.inter(
                                              fontSize: 12,
                                              color: Colors.grey[600],
                                            ),
                                          ),
                                          const SizedBox(width: 16),
                                          Icon(
                                            Icons.person_outline,
                                            size: 16,
                                            color: Colors.grey[600],
                                          ),
                                          const SizedBox(width: 4),
                                          Expanded(
                                            child: Text(
                                              'Assessor: ${assessment.assessorName}',
                                              style: GoogleFonts.inter(
                                                fontSize: 12,
                                                color: Colors.grey[600],
                                              ),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ],
                                      ),
                                      if (assessment.doctorNotes != null &&
                                          assessment.doctorNotes!.isNotEmpty) ...[
                                        const SizedBox(height: 8),
                                        Container(
                                          padding: const EdgeInsets.all(8),
                                          decoration: BoxDecoration(
                                            color: Colors.blue[50],
                                            borderRadius: BorderRadius.circular(6),
                                          ),
                                          child: Row(
                                            children: [
                                              Icon(
                                                Icons.note,
                                                size: 16,
                                                color: Colors.blue[700],
                                              ),
                                              const SizedBox(width: 8),
                                              Expanded(
                                                child: Text(
                                                  assessment.doctorNotes!,
                                                  style: GoogleFonts.inter(
                                                    fontSize: 12,
                                                    color: Colors.blue[900],
                                                  ),
                                                  maxLines: 2,
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                      const SizedBox(height: 8),
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.end,
                                        children: [
                                          TextButton.icon(
                                            onPressed: () async {
                                              final result = await Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                  builder: (context) =>
                                                      AssessmentDetailScreen(
                                                    assessmentId: assessment.id!,
                                                    allowReview: true,
                                                  ),
                                                ),
                                              );
                                              
                                              if (result == true) {
                                                _loadAssessments();
                                              }
                                            },
                                            icon: const Icon(Icons.visibility, size: 16),
                                            label: const Text('View Details'),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
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

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Filter Assessments',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RadioListTile<String>(
              title: const Text('All'),
              value: 'all',
              groupValue: _statusFilter,
              onChanged: (value) {
                setState(() {
                  _statusFilter = value!;
                  _applyFilters();
                });
                Navigator.pop(context);
              },
            ),
            RadioListTile<String>(
              title: const Text('Pending'),
              value: 'pending',
              groupValue: _statusFilter,
              onChanged: (value) {
                setState(() {
                  _statusFilter = value!;
                  _applyFilters();
                });
                Navigator.pop(context);
              },
            ),
            RadioListTile<String>(
              title: const Text('Reviewed'),
              value: 'reviewed',
              groupValue: _statusFilter,
              onChanged: (value) {
                setState(() {
                  _statusFilter = value!;
                  _applyFilters();
                });
                Navigator.pop(context);
              },
            ),
            RadioListTile<String>(
              title: const Text('Completed'),
              value: 'completed',
              groupValue: _statusFilter,
              onChanged: (value) {
                setState(() {
                  _statusFilter = value!;
                  _applyFilters();
                });
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }
}
