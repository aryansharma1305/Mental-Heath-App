import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';

import '../theme/app_theme.dart';
import '../widgets/template_picker_sheet.dart';
import 'mhca_assessment_screen.dart';
import 'consent_gate_screen.dart';
import 'dsm5_assessment_screen.dart';

/// Assessment type selection screen.
///
/// Replaces the legacy Supabase-backed template list with direct type cards.
/// Tapping "MHCA" shows the workflow template picker before navigation.
class SelectAssessmentScreen extends StatelessWidget {
  const SelectAssessmentScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: AppTheme.textDark,
        leading: IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: AppTheme.softShadow,
            ),
            child: const Icon(Icons.arrow_back, color: AppTheme.textDark),
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'New Assessment',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            color: AppTheme.textDark,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text(
              'Choose assessment type',
              style: GoogleFonts.inter(
                fontSize: 14,
                color: AppTheme.textGrey,
              ),
            ),
            const SizedBox(height: 16),
            _AssessmentTypeCard(
              icon: Icons.psychology,
              title: 'MHCA Assessment',
              subtitle: 'Mental Health Capacity Assessment (MHCA 2017)',
              gradient: AppTheme.primaryGradient,
              delay: 0,
              onTap: () => _startMhca(context),
            ),
            const SizedBox(height: 12),
            _AssessmentTypeCard(
              icon: Icons.medical_services_outlined,
              title: 'DSM-5 Assessment',
              subtitle: 'Cross-Cutting Symptom Measure',
              gradient: AppTheme.pinkGradient,
              delay: 60,
              onTap: () => _startDsm5(context),
            ),
            const SizedBox(height: 12),
            _AssessmentTypeCard(
              icon: Icons.assignment_turned_in_outlined,
              title: 'Capacity Assessment',
              subtitle: 'Decision-making capacity evaluation',
              gradient: const LinearGradient(
                colors: [Color(0xFF11998e), Color(0xFF38ef7d)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              delay: 120,
              onTap: () => _startCapacity(context),
            ),
          ],
        ),
      ),
    );
  }

  /// Shows the template picker then navigates to the MHCA screen.
  Future<void> _startMhca(BuildContext context) async {
    // Show template picker — returns null if clinician taps Skip.
    final template = await TemplatePickerSheet.show(
      context,
      assessmentType: 'MHCA',
    );

    if (!context.mounted) return;

    // Navigate with or without template.
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => MHCAAssessmentScreen(initialTemplate: template),
      ),
    );
  }

  void _startDsm5(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const DSM5AssessmentScreen()),
    );
  }

  void _startCapacity(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ConsentGateScreen(
          patientLabel: 'New patient',
          assessmentType: 'Capacity Assessment',
          recordedBy: '',
        ),
      ),
    );
  }
}

// ── Private tile widget ────────────────────────────────────────────────────

class _AssessmentTypeCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Gradient gradient;
  final int delay;
  final VoidCallback onTap;

  const _AssessmentTypeCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.gradient,
    required this.delay,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.12),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: Colors.white, size: 26),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: Colors.white.withValues(alpha: 0.85),
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              color: Colors.white.withValues(alpha: 0.7),
              size: 18,
            ),
          ],
        ),
      ),
    )
        .animate(delay: delay.ms)
        .fadeIn()
        .slideY(begin: 0.06, end: 0, curve: Curves.easeOut);
  }
}
