import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../models/assessment.dart';
import '../models/clinical_note.dart';
import '../models/patient_profile.dart';
import '../services/assessment_questions.dart';
import '../services/auth_service.dart';
import '../services/database_service.dart';
import '../theme/app_theme.dart';
import 'assessment_detail_screen.dart';

class PatientProfilesScreen extends StatefulWidget {
  const PatientProfilesScreen({super.key});

  @override
  State<PatientProfilesScreen> createState() => _PatientProfilesScreenState();
}

class _PatientProfilesScreenState extends State<PatientProfilesScreen> {
  final DatabaseService _databaseService = DatabaseService();
  final TextEditingController _searchController = TextEditingController();
  List<PatientProfile> _patients = [];
  String _query = '';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPatients();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadPatients() async {
    final patients = await _databaseService.getAllPatients();
    if (!mounted) return;
    setState(() {
      _patients = patients;
      _isLoading = false;
    });
  }

  List<PatientProfile> get _filteredPatients {
    final query = _query.trim().toLowerCase();
    if (query.isEmpty) return _patients;
    return _patients.where((patient) {
      return patient.patientId.toLowerCase().contains(query) ||
          patient.displayName.toLowerCase().contains(query);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F4EF),
      appBar: AppBar(
        title: const Text('Patient Profiles'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: AppTheme.textDark,
      ),
      body: RefreshIndicator(
        onRefresh: _loadPatients,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            _buildIntroCard(),
            const SizedBox(height: 16),
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search by patient ID',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(18),
                  borderSide: BorderSide.none,
                ),
              ),
              onChanged: (value) => setState(() => _query = value),
            ),
            const SizedBox(height: 20),
            if (_isLoading)
              const Center(child: CircularProgressIndicator())
            else if (_filteredPatients.isEmpty)
              _buildEmptyState()
            else
              ..._filteredPatients.map(_buildPatientCard),
          ],
        ),
      ),
    );
  }

  Widget _buildIntroCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF17201A),
        borderRadius: BorderRadius.circular(26),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.folder_shared_outlined, color: Colors.white),
          const SizedBox(height: 14),
          Text(
            'One patient, all assessments',
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Profiles link repeated DSM-5, MHCA and capacity records so you can review clinical history over time.',
            style: GoogleFonts.inter(
              color: Colors.white.withValues(alpha: 0.78),
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
      ),
      child: const Column(
        children: [
          Icon(Icons.person_search_outlined, size: 44, color: Colors.grey),
          SizedBox(height: 12),
          Text('No patient profiles yet'),
          SizedBox(height: 6),
          Text(
            'Profiles are created automatically when an assessment is saved.',
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildPatientCard(PatientProfile patient) {
    final lastSeen = patient.lastAssessmentAt == null
        ? 'No assessments yet'
        : DateFormat('dd MMM yyyy').format(patient.lastAssessmentAt!);

    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: CircleAvatar(
          backgroundColor: AppTheme.primaryColor.withValues(alpha: 0.12),
          child: Text(
            patient.patientId.isNotEmpty ? patient.patientId[0] : '?',
            style: const TextStyle(color: AppTheme.primaryColor),
          ),
        ),
        title: Text(
          patient.displayName,
          style: GoogleFonts.poppins(fontWeight: FontWeight.w700),
        ),
        subtitle: Text(
          '${patient.assessmentCount} assessments • Last: $lastSeen',
          style: GoogleFonts.inter(),
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  PatientProfileDetailScreen(patientId: patient.patientId),
            ),
          );
          _loadPatients();
        },
      ),
    );
  }
}

class PatientProfileDetailScreen extends StatefulWidget {
  final String patientId;

  const PatientProfileDetailScreen({super.key, required this.patientId});

  @override
  State<PatientProfileDetailScreen> createState() =>
      _PatientProfileDetailScreenState();
}

class _PatientProfileDetailScreenState
    extends State<PatientProfileDetailScreen> {
  final DatabaseService _databaseService = DatabaseService();
  final AuthService _authService = AuthService();
  PatientProfile? _patient;
  List<Assessment> _assessments = [];
  List<ClinicalNote> _notes = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final patient = await _databaseService.getPatient(widget.patientId);
    final assessments = await _databaseService.getAssessmentsByPatientCode(
      widget.patientId,
    );
    final notes = await _databaseService.getClinicalNotesForPatient(
      widget.patientId,
    );

    if (!mounted) return;
    setState(() {
      _patient = patient;
      _assessments = assessments;
      _notes = notes;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F4EF),
      appBar: AppBar(
        title: Text(_patient?.displayName ?? widget.patientId),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: AppTheme.textDark,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddNoteDialog,
        icon: const Icon(Icons.note_add_outlined),
        label: const Text('Add note'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadProfile,
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  _buildHeader(),
                  const SizedBox(height: 18),
                  _buildTrendCard(),
                  const SizedBox(height: 18),
                  _buildAssessments(),
                  const SizedBox(height: 18),
                  _buildNotes(),
                  const SizedBox(height: 90),
                ],
              ),
            ),
    );
  }

  Widget _buildHeader() {
    final latest = _assessments.isEmpty ? null : _assessments.first;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(26),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Patient ID',
            style: GoogleFonts.inter(color: Colors.grey.shade600),
          ),
          Text(
            widget.patientId,
            style: GoogleFonts.poppins(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              color: AppTheme.textDark,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _chip('${_assessments.length} assessments', Icons.assignment),
              _chip('${_notes.length} notes', Icons.sticky_note_2_outlined),
              if (latest != null)
                _chip(
                  'Latest: ${DateFormat('dd MMM').format(latest.assessmentDate)}',
                  Icons.event,
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTrendCard() {
    final trend = _dsm5Trend();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF102A43),
        borderRadius: BorderRadius.circular(26),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Longitudinal DSM-5 trend',
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Built from raw question-level responses so scores can be recalculated if logic changes.',
            style: GoogleFonts.inter(color: Colors.white70),
          ),
          const SizedBox(height: 18),
          if (trend.length < 2)
            const Text(
              'At least two DSM-5 assessments are needed to draw a trend.',
              style: TextStyle(color: Colors.white70),
            )
          else
            SizedBox(
              height: 180,
              child: LineChart(
                LineChartData(
                  gridData: const FlGridData(show: false),
                  titlesData: const FlTitlesData(show: false),
                  borderData: FlBorderData(show: false),
                  lineBarsData: [
                    LineChartBarData(
                      spots: [
                        for (var i = 0; i < trend.length; i++)
                          FlSpot(i.toDouble(), trend[i].score.toDouble()),
                      ],
                      isCurved: true,
                      color: const Color(0xFF8FE3CF),
                      barWidth: 4,
                      dotData: const FlDotData(show: true),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildAssessments() {
    return _section(
      title: 'Assessment history',
      child: _assessments.isEmpty
          ? const Text('No assessments linked to this patient yet.')
          : Column(
              children: _assessments.map((assessment) {
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(assessment.decisionContext),
                  subtitle: Text(
                    '${assessment.overallCapacity} • ${DateFormat('dd MMM yyyy HH:mm').format(assessment.assessmentDate)}',
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: assessment.id == null
                      ? null
                      : () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => AssessmentDetailScreen(
                                assessmentId: assessment.id!,
                              ),
                            ),
                          );
                        },
                );
              }).toList(),
            ),
    );
  }

  Widget _buildNotes() {
    return _section(
      title: 'Clinical notes',
      child: _notes.isEmpty
          ? const Text('No notes recorded yet.')
          : Column(
              children: _notes.map((note) {
                return Container(
                  width: double.infinity,
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF7F1E7),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(note.note, style: GoogleFonts.inter(height: 1.35)),
                      const SizedBox(height: 8),
                      Text(
                        '${note.authorName} • ${DateFormat('dd MMM yyyy HH:mm').format(note.createdAt)}',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: Colors.grey.shade700,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
    );
  }

  Widget _section({required String title, required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }

  Widget _chip(String label, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppTheme.primaryColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: AppTheme.primaryColor),
          const SizedBox(width: 6),
          Text(label, style: const TextStyle(color: AppTheme.primaryColor)),
        ],
      ),
    );
  }

  List<_TrendPoint> _dsm5Trend() {
    final dsm5 =
        _assessments
            .where((a) => a.decisionContext.toLowerCase().contains('dsm-5'))
            .toList()
          ..sort((a, b) => a.assessmentDate.compareTo(b.assessmentDate));

    return dsm5.map((assessment) {
      return _TrendPoint(
        date: assessment.assessmentDate,
        score: _scoreAssessment(assessment),
      );
    }).toList();
  }

  int _scoreAssessment(Assessment assessment) {
    return AssessmentQuestions.calculateTotalScore(assessment.responses);
  }

  Future<void> _showAddNoteDialog() async {
    final controller = TextEditingController();
    final noteText = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add clinical note'),
        content: TextField(
          controller: controller,
          minLines: 4,
          maxLines: 8,
          decoration: const InputDecoration(
            hintText:
                'Record clinical context, observations, or follow-up plan',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    controller.dispose();

    if (noteText == null || noteText.isEmpty) return;
    final currentUser = await _authService.getCurrentUserModel();
    final now = DateTime.now();
    await _databaseService.insertClinicalNote(
      ClinicalNote(
        patientId: widget.patientId,
        note: noteText,
        authorName: currentUser?.fullName ?? 'Unknown clinician',
        authorUserId: currentUser?.id,
        createdAt: now,
        updatedAt: now,
      ),
    );
    await _loadProfile();
  }
}

class _TrendPoint {
  final DateTime date;
  final int score;

  const _TrendPoint({required this.date, required this.score});
}
