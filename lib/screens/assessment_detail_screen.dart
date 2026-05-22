import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../models/assessment.dart';
import '../models/countersignature.dart';
import '../services/countersignature_service.dart';
import '../services/database_service.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../services/pdf_export_service.dart';
import '../services/reminder_service.dart';
import '../models/user_role.dart';
import '../theme/app_theme.dart';
import '../widgets/overdue_banner.dart';
import 'countersignature_screen.dart';

class AssessmentDetailScreen extends StatefulWidget {
  final int assessmentId;
  final bool allowReview;

  const AssessmentDetailScreen({
    super.key,
    required this.assessmentId,
    this.allowReview = false,
  });

  @override
  State<AssessmentDetailScreen> createState() => _AssessmentDetailScreenState();
}

class _AssessmentDetailScreenState extends State<AssessmentDetailScreen> {
  final ApiService _apiService = ApiService();
  final AuthService _authService = AuthService();
  final PdfExportService _pdfExportService = PdfExportService();
  final TextEditingController _notesController = TextEditingController();

  Assessment? _assessment;
  Countersignature? _countersignature;
  bool _isLoading = true;
  bool _isReviewing = false;
  UserRole? _currentUserRole;

  @override
  void initState() {
    super.initState();
    _loadAssessment();
    _loadUserRole();
  }

  Future<void> _loadUserRole() async {
    final role = await _authService.getCurrentUserRole();
    setState(() {
      _currentUserRole = role;
    });
  }

  Future<void> _loadAssessment() async {
    setState(() => _isLoading = true);
    try {
      Assessment? assessment;
      try {
        final assessments = await _apiService.getAllAssessments();
        assessment = assessments.firstWhere((a) => a.id == widget.assessmentId);
      } catch (e) {
        // Fallback to local DB below
      }
      // Fallback: load from local DB (offline-first)
      assessment ??=
          await DatabaseService().getAssessment(widget.assessmentId);

      Countersignature? cs;
      if (assessment?.id != null) {
        cs = await CountersignatureService.instance
            .getCountersignature(assessment!.id!);
      }
      setState(() {
        _assessment = assessment;
        _countersignature = cs;
        if (assessment?.doctorNotes != null) {
          _notesController.text = assessment!.doctorNotes!;
        }
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error loading assessment: $e')));
      }
    }
  }

  Future<void> _submitReview(String status) async {
    if (_assessment == null) return;

    setState(() => _isReviewing = true);

    try {
      final currentUser = await _authService.getCurrentUserModel();
      if (currentUser == null) {
        throw Exception('User not found');
      }

      await _apiService.reviewAssessment(
        assessmentId: widget.assessmentId,
        reviewerId: currentUser.id,
        status: status,
        doctorNotes: _notesController.text.trim().isNotEmpty
            ? _notesController.text.trim()
            : null,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              status == 'completed'
                  ? 'Assessment marked as completed'
                  : 'Review submitted successfully',
            ),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true); // Return true to indicate update
      }
    } catch (e) {
      setState(() => _isReviewing = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error submitting review: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _exportToPdf() async {
    if (_assessment == null) return;

    try {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Generating PDF...'),
          duration: Duration(seconds: 1),
        ),
      );

      final filePath = await _pdfExportService.exportAssessmentToPdf(
        _assessment!,
      );

      if (filePath != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('PDF exported successfully!\nSaved to: $filePath'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 4),
          ),
        );
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to export PDF. Please check permissions.'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error exporting PDF: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _showReviewDialog() async {
    if (_assessment == null) return;

    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Review Assessment',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Add your review notes:',
                style: GoogleFonts.inter(fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _notesController,
                maxLines: 5,
                decoration: InputDecoration(
                  hintText: 'Enter your review notes...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, 'reviewed'),
            child: const Text('Mark as Reviewed'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, 'completed'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
            child: const Text('Mark as Completed'),
          ),
        ],
      ),
    );

    if (result != null) {
      await _submitReview(result);
    }
  }

  // ---------------------------------------------------------------------------
  // Countersignature helpers
  // ---------------------------------------------------------------------------

  Color _csStatusColor(String? status) => switch (status) {
        'pending' => Colors.orange.shade600,
        'countersigned' => Colors.green.shade600,
        'amendment_requested' => Colors.red.shade600,
        _ => Colors.grey,
      };

  String _csStatusLabel(String? status) => switch (status) {
        'pending' => 'Awaiting Sign-off',
        'countersigned' => 'Countersigned',
        'amendment_requested' => 'Amendment Needed',
        _ => '',
      };

  /// Amendment editing: only doctorNotes and recommendations may be changed.
  Future<void> _showAmendmentEditDialog() async {
    if (_assessment == null) return;
    final notesCtrl =
        TextEditingController(text: _assessment!.doctorNotes ?? '');
    final recsCtrl =
        TextEditingController(text: _assessment!.recommendations);

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Apply amendment',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'You may only edit clinical notes and recommendations.\n'
                'Clinical scores and responses are immutable.',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: notesCtrl,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Doctor notes',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: recsCtrl,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Recommendations',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              foregroundColor: Colors.white,
            ),
            child: const Text('Save & resubmit'),
          ),
        ],
      ),
    );

    notesCtrl.dispose();
    recsCtrl.dispose();

    if (confirmed != true || !mounted) return;

    try {
      final updated = CountersignatureService.instance.applyAmendmentEdits(
        _assessment!,
        doctorNotes: notesCtrl.text.trim(),
        recommendations: recsCtrl.text.trim(),
      );
      await DatabaseService().updateAssessment(updated);
      if (_assessment!.id != null) {
        await CountersignatureService.instance
            .requestCountersignature(_assessment!.id!);
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Amendment saved. Countersignature re-requested.'),
            backgroundColor: Colors.green,
          ),
        );
        _loadAssessment();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error applying amendment: $e'),
            backgroundColor: Colors.red,
          ),
        );
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
    final canReview =
        widget.allowReview && (_currentUserRole?.canReviewAssessments ?? false);
    final a = _assessment;
    final isPending = a?.countersignatureStatus == 'pending';
    final isAmendmentRequested =
        a?.countersignatureStatus == 'amendment_requested';
    final isCountersigned = a?.countersignatureStatus == 'countersigned';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Assessment Details'),
        actions: [
          // Countersignature status badge
          if (a != null && a.countersignatureStatus != null)
            Padding(
              padding: const EdgeInsets.only(right: 4),
              child: Center(
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _csStatusColor(a.countersignatureStatus),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _csStatusLabel(a.countersignatureStatus),
                    style: const TextStyle(
                      fontSize: 11,
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ),
          if (_assessment != null)
            IconButton(
              icon: const Icon(Icons.download),
              tooltip: 'Export PDF',
              onPressed: _exportToPdf,
            ),
          if (canReview && _assessment != null)
            IconButton(
              icon: const Icon(Icons.rate_review),
              tooltip: 'Review Assessment',
              onPressed: _isReviewing ? null : _showReviewDialog,
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _assessment == null
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error, size: 64, color: Colors.grey[300]),
                  const SizedBox(height: 16),
                  Text(
                    'Assessment not found',
                    style: GoogleFonts.inter(
                      fontSize: 18,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Overdue follow-up banner — shown before anything else.
                  if (ReminderService.instance.overdueFor(_assessment!))
                    OverdueBanner(
                      assessment: _assessment!,
                      onStartFollowUp: () {
                        Navigator.pop(context, 'start_follow_up');
                      },
                    ),

                  // Pending countersignature banner
                  if (isPending)
                    _CountersignaturePendingBanner(
                      onCountersignNow: () async {
                        final done = await Navigator.push<bool>(
                          context,
                          MaterialPageRoute(
                            builder: (_) => CountersignatureScreen(
                              assessment: _assessment!,
                            ),
                          ),
                        );
                        if (done == true) _loadAssessment();
                      },
                    ),

                  // Amendment requested banner
                  if (isAmendmentRequested)
                    _AmendmentRequestedBanner(
                      note: _assessment!.amendmentNote,
                      onEditNow: () => _showAmendmentEditDialog(),
                    ),

                  // Countersigned confirmation banner
                  if (isCountersigned && _countersignature != null)
                    _CountersignedBanner(cs: _countersignature!),

                  // Status Badge
                  if (_assessment!.status != null)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: _getStatusColor(_assessment!.status),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        _getStatusLabel(_assessment!.status),
                        style: GoogleFonts.inter(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),

                  // Patient Information Card
                  Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              CircleAvatar(
                                backgroundColor: _getCapacityColor(
                                  _assessment!.overallCapacity,
                                ),
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
                                      style: GoogleFonts.poppins(
                                        fontSize: 24,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Text(
                                      'ID: ${_assessment!.patientId}',
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
                          const SizedBox(height: 16),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: _getCapacityColor(
                                _assessment!.overallCapacity,
                              ),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              _assessment!.overallCapacity,
                              style: GoogleFonts.inter(
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
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Assessment Information',
                            style: GoogleFonts.poppins(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),
                          _buildInfoRow(
                            'Assessment Date',
                            DateFormat(
                              'EEEE, MMMM d, y • h:mm a',
                            ).format(_assessment!.assessmentDate),
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
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Assessment Responses',
                            style: GoogleFonts.poppins(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),
                          if (_assessment!.responses.isNotEmpty)
                            ..._assessment!.responses.entries.map((entry) {
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      entry.key,
                                      style: GoogleFonts.inter(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 14,
                                        color: Colors.grey[700],
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Container(
                                      width: double.infinity,
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: Colors.grey[100],
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        entry.value.toString(),
                                        style: GoogleFonts.inter(fontSize: 14),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            })
                          else
                            Text(
                              'No responses recorded',
                              style: GoogleFonts.inter(
                                color: Colors.grey[600],
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Recommendations Card
                  Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Recommendations',
                            style: GoogleFonts.poppins(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.blue[50],
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              _assessment!.recommendations,
                              style: GoogleFonts.inter(fontSize: 14),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Doctor Notes Card (if exists)
                  if (_assessment!.doctorNotes != null &&
                      _assessment!.doctorNotes!.isNotEmpty)
                    Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.note, color: Colors.blue[700]),
                                const SizedBox(width: 8),
                                Text(
                                  'Doctor Review Notes',
                                  style: GoogleFonts.poppins(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.blue[50],
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                _assessment!.doctorNotes!,
                                style: GoogleFonts.inter(fontSize: 14),
                              ),
                            ),
                            if (_assessment!.reviewedAt != null) ...[
                              const SizedBox(height: 8),
                              Text(
                                'Reviewed on: ${DateFormat('MMM d, y • h:mm a').format(_assessment!.reviewedAt!)}',
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),

                  // Metadata Card
                  Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Record Information',
                            style: GoogleFonts.poppins(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),
                          _buildInfoRow(
                            'Created',
                            DateFormat(
                              'MMM d, y \'at\' h:mm a',
                            ).format(_assessment!.createdAt),
                            Icons.add_circle_outline,
                          ),
                          _buildInfoRow(
                            'Last Updated',
                            DateFormat(
                              'MMM d, y \'at\' h:mm a',
                            ).format(_assessment!.updatedAt),
                            Icons.update,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Review Button (if allowed)
                  if (canReview)
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _isReviewing ? null : _showReviewDialog,
                        icon: const Icon(Icons.rate_review),
                        label: Text(
                          _assessment!.status == 'completed'
                              ? 'Update Review'
                              : 'Review Assessment',
                          style: GoogleFonts.inter(fontWeight: FontWeight.w600),
                        ),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          backgroundColor: AppTheme.primaryColor,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                  const SizedBox(height: 16),
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
          Icon(icon, size: 20, color: Colors.grey[600]),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w500,
                    color: Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 2),
                Text(value, style: GoogleFonts.inter(fontSize: 14)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }
}

// =============================================================================
// Banner widgets for countersignature states
// =============================================================================
class _CountersignaturePendingBanner extends StatelessWidget {
  final VoidCallback onCountersignNow;
  const _CountersignaturePendingBanner({required this.onCountersignNow});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.orange.shade300),
      ),
      child: Row(
        children: [
          Icon(Icons.pending_actions_rounded,
              color: Colors.orange.shade700, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Awaiting countersignature',
              style: GoogleFonts.inter(
                fontWeight: FontWeight.w600,
                color: Colors.orange.shade800,
              ),
            ),
          ),
          TextButton(
            onPressed: onCountersignNow,
            style: TextButton.styleFrom(
              foregroundColor: Colors.orange.shade800,
            ),
            child: const Text('Sign now'),
          ),
        ],
      ),
    );
  }
}

class _AmendmentRequestedBanner extends StatelessWidget {
  final String? note;
  final VoidCallback onEditNow;
  const _AmendmentRequestedBanner(
      {required this.note, required this.onEditNow});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.red.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.edit_note_rounded,
                  color: Colors.red.shade700, size: 22),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Amendment requested',
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w700,
                    color: Colors.red.shade800,
                  ),
                ),
              ),
              TextButton(
                onPressed: onEditNow,
                style: TextButton.styleFrom(
                  foregroundColor: Colors.red.shade800,
                ),
                child: const Text('Edit'),
              ),
            ],
          ),
          if (note != null && note!.isNotEmpty) ...[
            const SizedBox(height: 6),
            Padding(
              padding: const EdgeInsets.only(left: 32),
              child: Text(
                note!,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: Colors.red.shade700,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _CountersignedBanner extends StatelessWidget {
  final Countersignature cs;
  const _CountersignedBanner({required this.cs});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.green.shade50,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.green.shade300),
      ),
      child: Row(
        children: [
          Icon(Icons.verified_user_rounded,
              color: Colors.green.shade700, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Countersigned by ${cs.signatoryName}',
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w700,
                    color: Colors.green.shade800,
                  ),
                ),
                Text(
                  '${cs.signatoryRole} • ${DateFormat('d MMM yyyy HH:mm').format(cs.signedAt)}',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: Colors.green.shade700,
                  ),
                ),
                if (cs.outcome == CountersignatureOutcome.approvedWithComments &&
                    cs.notes != null)
                  Text(
                    'Note: ${cs.notes}',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: Colors.green.shade700,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
