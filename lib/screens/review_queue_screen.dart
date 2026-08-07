import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../models/risk_level.dart';
import '../services/database_service.dart';
import '../services/review_queue_service.dart';
import '../theme/app_theme.dart';
import 'assessment_detail_screen.dart';
import 'dsm5_assessment_screen.dart';

class ReviewQueueScreen extends StatefulWidget {
  const ReviewQueueScreen({super.key});

  @override
  State<ReviewQueueScreen> createState() => _ReviewQueueScreenState();
}

class _ReviewQueueScreenState extends State<ReviewQueueScreen> {
  final DatabaseService _databaseService = DatabaseService();
  final ReviewQueueService _queueService = ReviewQueueService();
  List<ReviewQueueItem> _items = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final assessments = await _databaseService.getAllAssessments();
    if (!mounted) return;
    setState(() {
      _items = _queueService.buildQueue(assessments);
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final summary = ReviewQueueSummary.fromItems(_items);
    return Scaffold(
      backgroundColor: const Color(0xFFF6F4EF),
      appBar: AppBar(
        title: const Text('Review Queue'),
        backgroundColor: Colors.transparent,
        foregroundColor: AppTheme.textDark,
        elevation: 0,
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            _header(summary),
            const SizedBox(height: 18),
            if (_loading)
              const Center(child: CircularProgressIndicator())
            else if (_items.isEmpty)
              _empty()
            else
              ..._items.map(_queueCard),
            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }

  Widget _header(ReviewQueueSummary summary) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: const Color(0xFF17201A),
        borderRadius: BorderRadius.circular(28),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.assignment_late_outlined, color: Colors.white),
          const SizedBox(height: 12),
          Text(
            'Patients needing clinical review',
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Built from risk level, refusal records, and follow-up recommendations.',
            style: GoogleFonts.inter(color: Colors.white70, height: 1.35),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _statChip('${summary.total} total'),
              _statChip('${summary.overdue} overdue'),
              _statChip('${summary.critical} critical'),
              _statChip('${summary.high} high'),
              _statChip('${summary.refusals} refusals'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _statChip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: GoogleFonts.inter(
          color: Colors.white,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _empty() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        children: [
          Icon(Icons.check_circle_outline, size: 48, color: Colors.green[700]),
          const SizedBox(height: 12),
          Text(
            'No patients need review',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'High-risk, critical, refused, and clinician-recommended follow-ups will appear here.',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(color: Colors.grey.shade700),
          ),
        ],
      ),
    );
  }

  Widget _queueCard(ReviewQueueItem item) {
    final assessment = item.assessment;
    final risk = assessment.riskLevel;
    return Card(
      elevation: 0,
      color: Colors.white,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _riskBadge(risk),
                const SizedBox(width: 8),
                if (item.isOverdue) _overdueBadge(item.daysOverdue),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              assessment.patientName.isEmpty
                  ? assessment.patientId
                  : assessment.patientName,
              style: GoogleFonts.poppins(
                fontSize: 17,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '${assessment.decisionContext} - ${assessment.patientId}',
              style: GoogleFonts.inter(color: Colors.grey.shade700),
            ),
            const SizedBox(height: 8),
            Text(
              item.reason,
              style: GoogleFonts.inter(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 4),
            Text(
              'Due ${DateFormat('dd MMM yyyy').format(item.dueAt)}',
              style: GoogleFonts.inter(color: Colors.grey.shade700),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: assessment.id == null
                        ? null
                        : () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => AssessmentDetailScreen(
                                assessmentId: assessment.id!,
                              ),
                            ),
                          ),
                    icon: const Icon(Icons.visibility_outlined),
                    label: const Text('View'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const DSM5AssessmentScreen(),
                      ),
                    ),
                    icon: const Icon(Icons.add_circle_outline),
                    label: const Text('Follow-up'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _riskBadge(RiskLevel risk) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: risk.background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        risk.label,
        style: GoogleFonts.inter(
          color: risk.color,
          fontWeight: FontWeight.w800,
          fontSize: 12,
        ),
      ),
    );
  }

  Widget _overdueBadge(int days) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: AppTheme.errorRed.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        days <= 0 ? 'Due today' : '$days days overdue',
        style: GoogleFonts.inter(
          color: AppTheme.errorRed,
          fontWeight: FontWeight.w800,
          fontSize: 12,
        ),
      ),
    );
  }
}
