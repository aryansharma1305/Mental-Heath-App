import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/assessment.dart';
import '../models/risk_level.dart';
import '../services/reminder_service.dart';

/// Prominent banner shown when a follow-up assessment is overdue.
///
/// Usage:
/// ```dart
/// if (ReminderService.instance.overdueFor(assessment))
///   OverdueBanner(
///     assessment: assessment,
///     onStartFollowUp: () => _startNewAssessment(),
///   )
/// ```
class OverdueBanner extends StatelessWidget {
  final Assessment assessment;
  final VoidCallback? onStartFollowUp;

  const OverdueBanner({
    super.key,
    required this.assessment,
    this.onStartFollowUp,
  });

  @override
  Widget build(BuildContext context) {
    final days = ReminderService.instance.daysOverdue(assessment);
    final risk = assessment.riskLevel;

    // Choose severity colours from the existing RiskLevel extension.
    final bg = risk.background;
    final fg = risk.color;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: fg, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: fg.withValues(alpha: 0.15),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Animated warning icon
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: fg.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.alarm, color: fg, size: 22),
          )
              .animate(onPlay: (c) => c.repeat(reverse: true))
              .scaleXY(begin: 1.0, end: 1.08, duration: 900.ms),

          const SizedBox(width: 12),

          // Text content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    _RiskBadge(risk: risk),
                    const SizedBox(width: 8),
                    Text(
                      'Follow-Up Overdue',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: fg,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  days == 0
                      ? 'Follow-up was due today.'
                      : 'Follow-up was due $days ${days == 1 ? 'day' : 'days'} ago.',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: fg.withValues(alpha: 0.85),
                  ),
                ),
                const SizedBox(height: 10),
                if (onStartFollowUp != null)
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: onStartFollowUp,
                      icon: Icon(Icons.add_circle_outline, size: 18, color: bg),
                      label: Text(
                        'Start Follow-Up Assessment',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: bg,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: fg,
                        foregroundColor: bg,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 10),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms).slideY(begin: -0.1, end: 0);
  }
}

// ---------------------------------------------------------------------------
// Small risk badge used inside the banner
// ---------------------------------------------------------------------------
class _RiskBadge extends StatelessWidget {
  final RiskLevel risk;
  const _RiskBadge({required this.risk});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: risk.color,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        risk.label.toUpperCase(),
        style: GoogleFonts.inter(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: Colors.white,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Compact overdue dot — used in list rows
// ---------------------------------------------------------------------------
class OverdueDot extends StatelessWidget {
  final Assessment assessment;
  const OverdueDot({super.key, required this.assessment});

  @override
  Widget build(BuildContext context) {
    if (!ReminderService.instance.overdueFor(assessment)) {
      return const SizedBox.shrink();
    }
    return Container(
      width: 8,
      height: 8,
      margin: const EdgeInsets.only(left: 4),
      decoration: BoxDecoration(
        color: assessment.riskLevel.color,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: assessment.riskLevel.color.withValues(alpha: 0.5),
            blurRadius: 4,
            spreadRadius: 1,
          ),
        ],
      ),
    )
        .animate(onPlay: (c) => c.repeat(reverse: true))
        .fadeIn(duration: 600.ms)
        .then()
        .fadeOut(duration: 600.ms);
  }
}
