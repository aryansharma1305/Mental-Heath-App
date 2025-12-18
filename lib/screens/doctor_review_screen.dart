import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../services/supabase_service.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';
import '../widgets/custom_widgets.dart';

class DoctorReviewScreen extends StatefulWidget {
  const DoctorReviewScreen({super.key});

  @override
  State<DoctorReviewScreen> createState() => _DoctorReviewScreenState();
}

class _DoctorReviewScreenState extends State<DoctorReviewScreen> {
  final SupabaseService _supabaseService = SupabaseService();
  final AuthService _authService = AuthService();
  
  List<Map<String, dynamic>> _allResponses = [];
  Map<int, List<Map<String, dynamic>>> _responsesByTemplate = {};
  Map<String, Map<String, dynamic>> _responsesByPatient = {};
  bool _isLoading = true;
  int _selectedTab = 0; // 0 = By Template, 1 = By Patient

  @override
  void initState() {
    super.initState();
    _loadResponses();
  }

  Future<void> _loadResponses() async {
    setState(() => _isLoading = true);
    try {
      if (SupabaseService.isAvailable) {
        _allResponses = await _supabaseService.getQuestionResponses();
        
        // Group by template
        _responsesByTemplate = {};
        for (var response in _allResponses) {
          final templateId = response['template_id'] as int?;
          if (templateId != null) {
            _responsesByTemplate.putIfAbsent(templateId, () => []).add(response);
          }
        }
        
        // Group by patient
        _responsesByPatient = {};
        for (var response in _allResponses) {
          final patientId = response['patient_user_id'] as String?;
          if (patientId != null) {
            final key = patientId;
            if (!_responsesByPatient.containsKey(key)) {
              _responsesByPatient[key] = {
                'patient_id': patientId,
                'responses': <Map<String, dynamic>>[],
              };
            }
            (_responsesByPatient[key]!['responses'] as List).add(response);
          }
        }
      }
    } catch (e) {
      debugPrint('Error loading responses: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Review Assessments'),
        bottom: TabBar(
          onTap: (index) => setState(() => _selectedTab = index),
          tabs: const [
            Tab(icon: Icon(Icons.assignment), text: 'By Assessment'),
            Tab(icon: Icon(Icons.person), text: 'By Patient'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _selectedTab == 0
              ? _buildByTemplateView()
              : _buildByPatientView(),
    );
  }

  Widget _buildByTemplateView() {
    if (_responsesByTemplate.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.assignment_outlined, size: 80, color: Colors.grey[300]),
            const SizedBox(height: 16),
            Text(
              'No responses yet',
              style: GoogleFonts.inter(fontSize: 18, color: Colors.grey[600]),
            ),
            const SizedBox(height: 8),
            Text(
              'Patient responses will appear here',
              style: GoogleFonts.inter(fontSize: 14, color: Colors.grey[500]),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadResponses,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _responsesByTemplate.length,
        itemBuilder: (context, index) {
          final templateId = _responsesByTemplate.keys.elementAt(index);
          final responses = _responsesByTemplate[templateId]!;
          final templateName = responses.first['assessment_templates']?['name'] ?? 'Assessment $templateId';
          
          // Group by patient
          final Map<String, List<Map<String, dynamic>>> byPatient = {};
          for (var response in responses) {
            final patientId = response['patient_user_id'] as String? ?? 'unknown';
            byPatient.putIfAbsent(patientId, () => []).add(response);
          }

          return Card(
            margin: const EdgeInsets.only(bottom: 16),
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: ExpansionTile(
              leading: CircleAvatar(
                backgroundColor: AppTheme.primaryBlue,
                child: const Icon(Icons.assignment, color: Colors.white),
              ),
              title: Text(
                templateName,
                style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
              ),
              subtitle: Text('${byPatient.length} patient(s) • ${responses.length} response(s)'),
              children: byPatient.entries.map((entry) {
                final patientResponses = entry.value;
                final question = patientResponses.first['questions'];
                final questionText = question?['question_text'] ?? 'Question';
                
                return ListTile(
                  title: Text('Patient: ${entry.key}'),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: patientResponses.map((r) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                '${r['questions']?['question_text'] ?? 'Question'}: ${r['answer']}',
                                style: GoogleFonts.inter(fontSize: 14),
                              ),
                            ),
                            Text(
                              DateFormat('MMM d, y').format(
                                DateTime.parse(r['created_at']),
                              ),
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                );
              }).toList(),
            ),
          );
        },
      ),
    );
  }

  Widget _buildByPatientView() {
    if (_responsesByPatient.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.person_outline, size: 80, color: Colors.grey[300]),
            const SizedBox(height: 16),
            Text(
              'No patient responses yet',
              style: GoogleFonts.inter(fontSize: 18, color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadResponses,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _responsesByPatient.length,
        itemBuilder: (context, index) {
          final patientId = _responsesByPatient.keys.elementAt(index);
          final patientData = _responsesByPatient[patientId]!;
          final responses = patientData['responses'] as List<Map<String, dynamic>>;

          return Card(
            margin: const EdgeInsets.only(bottom: 16),
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: ExpansionTile(
              leading: CircleAvatar(
                backgroundColor: AppTheme.accentGreen,
                child: const Icon(Icons.person, color: Colors.white),
              ),
              title: Text(
                'Patient: ${patientId.substring(0, 8)}...',
                style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
              ),
              subtitle: Text('${responses.length} response(s)'),
              children: responses.map((response) {
                final question = response['questions'];
                final template = response['assessment_templates'];
                
                return ListTile(
                  title: Text(
                    question?['question_text'] ?? 'Question',
                    style: GoogleFonts.inter(fontWeight: FontWeight.w500),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 4),
                      Text(
                        'Answer: ${response['answer']}',
                        style: GoogleFonts.inter(fontSize: 14),
                      ),
                      if (template != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          'Assessment: ${template['name']}',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                      const SizedBox(height: 4),
                      Text(
                        'Date: ${DateFormat('MMM d, y • h:mm a').format(DateTime.parse(response['created_at']))}',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          );
        },
      ),
    );
  }
}
