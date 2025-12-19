import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../services/supabase_service.dart';
import '../models/user.dart' as app_models;
import '../models/assessment.dart';
import '../theme/app_theme.dart';
import 'assessment_list_screen.dart';
import 'assessment_detail_screen.dart';

class PatientManagementScreen extends StatefulWidget {
  const PatientManagementScreen({super.key});

  @override
  State<PatientManagementScreen> createState() => _PatientManagementScreenState();
}

class _PatientManagementScreenState extends State<PatientManagementScreen> {
  final SupabaseService _supabaseService = SupabaseService();
  final TextEditingController _searchController = TextEditingController();
  
  List<app_models.User> _allPatients = [];
  List<app_models.User> _filteredPatients = [];
  Map<String, List<Assessment>> _patientAssessments = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPatients();
    _searchController.addListener(_filterPatients);
  }

  Future<void> _loadPatients() async {
    setState(() => _isLoading = true);
    try {
      if (SupabaseService.isAvailable) {
        // Get all assessments to find unique patients
        final assessments = await _supabaseService.getAllAssessments();
        final patientIds = <String>{};
        
        for (var assessment in assessments) {
          if (assessment.patientId.isNotEmpty) {
            patientIds.add(assessment.patientId);
          }
        }
        
        // Load patient details
        final patients = <app_models.User>[];
        for (var patientId in patientIds) {
          final patient = await _supabaseService.getUserById(patientId);
          if (patient != null && patient.role.name == 'patient') {
            patients.add(patient);
          }
        }
        
        // Load assessments for each patient
        for (var patient in patients) {
          final assessments = await _supabaseService.getAssessmentsByPatientId(patient.id);
          _patientAssessments[patient.id] = assessments;
        }
        
        setState(() {
          _allPatients = patients;
          _filteredPatients = patients;
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  void _filterPatients() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      if (query.isEmpty) {
        _filteredPatients = _allPatients;
      } else {
        _filteredPatients = _allPatients.where((patient) {
          return patient.fullName.toLowerCase().contains(query) ||
              patient.email.toLowerCase().contains(query) ||
              patient.username.toLowerCase().contains(query);
        }).toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Patient Management'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadPatients,
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
                hintText: 'Search patients by name, email, or username...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          
          // Results count
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Text(
                  '${_filteredPatients.length} patient${_filteredPatients.length != 1 ? 's' : ''}',
                  style: GoogleFonts.inter(
                    color: Colors.grey[600],
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 8),
          
          // Patient list
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredPatients.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.people_outline, size: 80, color: Colors.grey[300]),
                            const SizedBox(height: 16),
                            Text(
                              _searchController.text.isNotEmpty
                                  ? 'No patients found'
                                  : 'No patients yet',
                              style: GoogleFonts.inter(
                                fontSize: 18,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _loadPatients,
                        child: ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _filteredPatients.length,
                          itemBuilder: (context, index) {
                            final patient = _filteredPatients[index];
                            final assessments = _patientAssessments[patient.id] ?? [];
                            
                            return Card(
                              margin: const EdgeInsets.only(bottom: 12),
                              elevation: 2,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: ExpansionTile(
                                leading: CircleAvatar(
                                  backgroundColor: AppTheme.primaryColor,
                                  child: Text(
                                    patient.fullName.substring(0, 1).toUpperCase(),
                                    style: const TextStyle(color: Colors.white),
                                  ),
                                ),
                                title: Text(
                                  patient.fullName,
                                  style: GoogleFonts.poppins(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      patient.email,
                                      style: GoogleFonts.inter(fontSize: 12),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '${assessments.length} assessment${assessments.length != 1 ? 's' : ''}',
                                      style: GoogleFonts.inter(
                                        fontSize: 12,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                  ],
                                ),
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.all(16),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        _buildPatientInfo(patient),
                                        const SizedBox(height: 16),
                                        if (assessments.isNotEmpty) ...[
                                          Text(
                                            'Assessments',
                                            style: GoogleFonts.poppins(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          const SizedBox(height: 8),
                                          ...assessments.map((assessment) {
                                            return Card(
                                              margin: const EdgeInsets.only(bottom: 8),
                                              elevation: 1,
                                              child: ListTile(
                                                title: Text(
                                                  DateFormat('MMM d, y • h:mm a')
                                                      .format(assessment.assessmentDate),
                                                  style: GoogleFonts.inter(
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                                ),
                                                subtitle: Text(
                                                  'Status: ${_getStatusLabel(assessment.status)}',
                                                  style: GoogleFonts.inter(fontSize: 12),
                                                ),
                                                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                                                onTap: () {
                                                  Navigator.push(
                                                    context,
                                                    MaterialPageRoute(
                                                      builder: (context) =>
                                                          AssessmentDetailScreen(
                                                        assessmentId: assessment.id!,
                                                        allowReview: true,
                                                      ),
                                                    ),
                                                  );
                                                },
                                              ),
                                            );
                                          }).toList(),
                                        ] else
                                          Text(
                                            'No assessments yet',
                                            style: GoogleFonts.inter(
                                              fontSize: 14,
                                              color: Colors.grey[600],
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                ],
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

  Widget _buildPatientInfo(app_models.User patient) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildInfoRow(Icons.person, 'Username', patient.username),
        const SizedBox(height: 8),
        _buildInfoRow(Icons.email, 'Email', patient.email),
        if (patient.department != null) ...[
          const SizedBox(height: 8),
          _buildInfoRow(Icons.business, 'Department', patient.department!),
        ],
        const SizedBox(height: 8),
        _buildInfoRow(
          Icons.calendar_today,
          'Member Since',
          DateFormat('MMM d, y').format(patient.createdAt),
        ),
      ],
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey[600]),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: Colors.grey[700],
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: GoogleFonts.inter(fontSize: 12),
          ),
        ),
      ],
    );
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
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}
