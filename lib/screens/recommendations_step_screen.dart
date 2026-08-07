import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/assessment_recommendations.dart';
import '../theme/app_theme.dart';

class RecommendationsStepScreen extends StatefulWidget {
  final String title;
  final String subtitle;
  final AssessmentRecommendations initialRecommendations;

  const RecommendationsStepScreen({
    super.key,
    this.title = 'Recommendations',
    this.subtitle =
        'Confirm the follow-up actions before saving this assessment.',
    this.initialRecommendations = const AssessmentRecommendations(),
  });

  @override
  State<RecommendationsStepScreen> createState() =>
      _RecommendationsStepScreenState();
}

class _RecommendationsStepScreenState extends State<RecommendationsStepScreen> {
  late bool _followUpRecommended;
  late bool _referToSpecialist;
  late bool _noFurtherAction;
  late final TextEditingController _notesController;

  @override
  void initState() {
    super.initState();
    final initial = widget.initialRecommendations;
    _followUpRecommended = initial.followUpRecommended;
    _referToSpecialist = initial.referToSpecialist;
    _noFurtherAction = initial.noFurtherAction;
    _notesController = TextEditingController(text: initial.freeText);
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  void _save() {
    Navigator.pop(
      context,
      AssessmentRecommendations(
        followUpRecommended: _followUpRecommended,
        referToSpecialist: _referToSpecialist,
        noFurtherAction: _noFurtherAction,
        freeText: _notesController.text.trim().isEmpty
            ? null
            : _notesController.text.trim(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F4EF),
      appBar: AppBar(
        title: const Text('Recommendation Step'),
        backgroundColor: Colors.transparent,
        foregroundColor: AppTheme.textDark,
        elevation: 0,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text(
              widget.title,
              style: GoogleFonts.inter(
                fontSize: 28,
                fontWeight: FontWeight.w800,
                color: AppTheme.textDark,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              widget.subtitle,
              style: GoogleFonts.inter(
                fontSize: 15,
                height: 1.4,
                color: AppTheme.textLight,
              ),
            ),
            const SizedBox(height: 24),
            _RecommendationTile(
              icon: Icons.event_repeat_outlined,
              title: 'Follow-up assessment recommended',
              subtitle: 'Adds this patient to the review queue when due.',
              value: _followUpRecommended,
              onChanged: (value) => setState(() {
                _followUpRecommended = value;
                if (value) _noFurtherAction = false;
              }),
            ),
            _RecommendationTile(
              icon: Icons.local_hospital_outlined,
              title: 'Refer to specialist',
              subtitle:
                  'Use when scores or presentation need specialist input.',
              value: _referToSpecialist,
              onChanged: (value) => setState(() {
                _referToSpecialist = value;
                if (value) _noFurtherAction = false;
              }),
            ),
            _RecommendationTile(
              icon: Icons.check_circle_outline,
              title: 'No further action at this time',
              subtitle: 'Use only when no active review or referral is needed.',
              value: _noFurtherAction,
              onChanged: (value) => setState(() {
                _noFurtherAction = value;
                if (value) {
                  _followUpRecommended = false;
                  _referToSpecialist = false;
                }
              }),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _notesController,
              minLines: 4,
              maxLines: 6,
              textInputAction: TextInputAction.newline,
              decoration: InputDecoration(
                labelText: 'Recommendation notes',
                hintText:
                    'Add clinical context, review timing, or referral details.',
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(18),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(18),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(18),
                  borderSide: const BorderSide(color: AppTheme.primaryBlue),
                ),
              ),
            ),
            const SizedBox(height: 28),
            ElevatedButton.icon(
              onPressed: _save,
              icon: const Icon(Icons.save_outlined),
              label: const Text('Save recommendations and complete'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryBlue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RecommendationTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _RecommendationTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: value ? AppTheme.primaryBlue : Colors.grey.shade300,
          width: value ? 1.5 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: SwitchListTile.adaptive(
        value: value,
        onChanged: onChanged,
        activeThumbColor: AppTheme.primaryBlue,
        secondary: Icon(
          icon,
          color: value ? AppTheme.primaryBlue : AppTheme.textLight,
        ),
        title: Text(
          title,
          style: GoogleFonts.inter(
            fontWeight: FontWeight.w700,
            color: AppTheme.textDark,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: GoogleFonts.inter(color: AppTheme.textLight, height: 1.35),
        ),
      ),
    );
  }
}
