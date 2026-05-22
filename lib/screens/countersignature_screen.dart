import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../models/assessment.dart';
import '../models/countersignature.dart';
import '../services/auth_service.dart';
import '../services/countersignature_service.dart';
import '../theme/app_theme.dart';

// =============================================================================
// CountersignatureScreen
//
// Allows a second clinician to review and countersign a high/critical-risk
// assessment on the same device.  The "Confirm" step requires the second
// clinician to re-enter their own app credentials, proving they have
// authorised device access (local Option-A two-person check).
// =============================================================================
class CountersignatureScreen extends StatefulWidget {
  final Assessment assessment;

  const CountersignatureScreen({super.key, required this.assessment});

  @override
  State<CountersignatureScreen> createState() => _CountersignatureScreenState();
}

class _CountersignatureScreenState extends State<CountersignatureScreen> {
  final _formKey = GlobalKey<FormState>();
  final _signatoryNameCtrl = TextEditingController();
  final _signatoryRoleCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();

  CountersignatureOutcome _outcome = CountersignatureOutcome.approved;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _signatoryNameCtrl.dispose();
    _signatoryRoleCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  // --------------------------------------------------------------------------
  // Actions
  // --------------------------------------------------------------------------

  Future<void> _onConfirmTapped() async {
    if (!_formKey.currentState!.validate()) return;

    // Show credential dialog — second clinician must authenticate.
    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const _CredentialConfirmDialog(),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _isSubmitting = true);
    try {
      await CountersignatureService.instance.submitCountersignature(
        assessment: widget.assessment,
        signatoryName: _signatoryNameCtrl.text.trim(),
        signatoryRole: _signatoryRoleCtrl.text.trim(),
        outcome: _outcome,
        notes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _outcome == CountersignatureOutcome.requestedAmendment
                ? 'Amendment requested — original clinician will be notified.'
                : 'Assessment countersigned successfully.',
          ),
          backgroundColor: _outcome == CountersignatureOutcome.requestedAmendment
              ? Colors.orange.shade700
              : Colors.green.shade700,
          behavior: SnackBarBehavior.floating,
        ),
      );
      Navigator.pop(context, true); // pop with success signal
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: AppTheme.errorRed,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  // --------------------------------------------------------------------------
  // Build
  // --------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final a = widget.assessment;
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: Text(
          'Countersignature Review',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        backgroundColor: Colors.white,
        foregroundColor: AppTheme.textDark,
        elevation: 0,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // -- Assessment summary card ------------------------------------
            _AssessmentSummaryCard(assessment: a)
                .animate()
                .fadeIn(duration: 400.ms)
                .slideY(begin: 0.1, end: 0),

            const SizedBox(height: 24),

            // -- Outcome selection ------------------------------------------
            Text(
              'Outcome',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppTheme.textDark,
              ),
            ),
            const SizedBox(height: 8),
            _OutcomeSelector(
              selected: _outcome,
              onChanged: (v) => setState(() => _outcome = v),
            ).animate().fadeIn(delay: 100.ms),

            const SizedBox(height: 20),

            // -- Notes -------------------------------------------------------
            TextFormField(
              controller: _notesCtrl,
              maxLines: 3,
              decoration: _inputDecoration(
                label: _outcome == CountersignatureOutcome.requestedAmendment
                    ? 'Amendment notes *'
                    : 'Notes (optional)',
                hint: _outcome == CountersignatureOutcome.requestedAmendment
                    ? 'Describe what needs to be amended...'
                    : 'Any comments on this assessment...',
              ),
              validator: (v) {
                if (_outcome == CountersignatureOutcome.requestedAmendment &&
                    (v == null || v.trim().isEmpty)) {
                  return 'Please describe what needs to be amended.';
                }
                return null;
              },
            ).animate().fadeIn(delay: 150.ms),

            const SizedBox(height: 20),

            // -- Signatory details ------------------------------------------
            Text(
              'Countersignatory details',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppTheme.textDark,
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _signatoryNameCtrl,
              textCapitalization: TextCapitalization.words,
              decoration: _inputDecoration(
                label: 'Full name *',
                hint: 'Dr. Jane Smith',
              ),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Name is required.' : null,
            ).animate().fadeIn(delay: 200.ms),

            const SizedBox(height: 16),

            TextFormField(
              controller: _signatoryRoleCtrl,
              textCapitalization: TextCapitalization.words,
              decoration: _inputDecoration(
                label: 'Role / grade *',
                hint: 'Consultant, Registrar, etc.',
              ),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Role is required.' : null,
            ).animate().fadeIn(delay: 250.ms),

            const SizedBox(height: 32),

            // -- Confirm button --------------------------------------------
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton.icon(
                onPressed: _isSubmitting ? null : _onConfirmTapped,
                icon: _isSubmitting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.verified_user_rounded),
                label: Text(
                  _isSubmitting ? 'Confirming…' : 'Confirm with credentials',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _outcomeColor(_outcome),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 0,
                ),
              ),
            ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.2, end: 0),

            const SizedBox(height: 24),

            // -- Local sign-off disclaimer ---------------------------------
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.amber.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.amber.shade200),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.info_outline_rounded,
                    size: 18,
                    color: Colors.amber.shade800,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Local countersignature — not account-verified. '
                      'The second clinician authenticates on this shared device '
                      'using their app credentials.',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: Colors.amber.shade800,
                        height: 1.5,
                      ),
                    ),
                  ),
                ],
              ),
            ).animate().fadeIn(delay: 350.ms),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  InputDecoration _inputDecoration({
    required String label,
    required String hint,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: AppTheme.primaryColor, width: 2),
      ),
    );
  }

  Color _outcomeColor(CountersignatureOutcome outcome) => switch (outcome) {
        CountersignatureOutcome.approved => Colors.green.shade600,
        CountersignatureOutcome.approvedWithComments => Colors.blue.shade600,
        CountersignatureOutcome.requestedAmendment => Colors.orange.shade700,
      };
}

// =============================================================================
// _AssessmentSummaryCard
// =============================================================================
class _AssessmentSummaryCard extends StatelessWidget {
  final Assessment assessment;
  const _AssessmentSummaryCard({required this.assessment});

  @override
  Widget build(BuildContext context) {
    final a = assessment;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: AppTheme.softShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  a.patientName,
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textDark,
                  ),
                ),
              ),
              _RiskBadge(riskLevel: a.riskLevel),
            ],
          ),
          const SizedBox(height: 8),
          _InfoRow(
            icon: Icons.calendar_today_rounded,
            label: DateFormat('d MMM yyyy').format(a.assessmentDate),
          ),
          _InfoRow(
            icon: Icons.person_rounded,
            label: '${a.assessorName} · ${a.assessorRole}',
          ),
          _InfoRow(
            icon: Icons.assignment_rounded,
            label: a.decisionContext,
          ),
          const SizedBox(height: 12),
          const Divider(),
          const SizedBox(height: 8),
          Text(
            'Overall capacity: ${a.overallCapacity}',
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppTheme.textDark,
            ),
          ),
          if (a.recommendations.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              a.recommendations,
              style: GoogleFonts.inter(
                fontSize: 13,
                color: Colors.grey.shade700,
                height: 1.5,
              ),
              maxLines: 4,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  const _InfoRow({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Icon(icon, size: 15, color: Colors.grey.shade500),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 13,
                color: Colors.grey.shade700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RiskBadge extends StatelessWidget {
  final dynamic riskLevel;
  const _RiskBadge({required this.riskLevel});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: riskLevel.background,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        riskLevel.label.toUpperCase(),
        style: GoogleFonts.inter(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: riskLevel.color,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

// =============================================================================
// _OutcomeSelector
// =============================================================================
class _OutcomeSelector extends StatelessWidget {
  final CountersignatureOutcome selected;
  final ValueChanged<CountersignatureOutcome> onChanged;
  const _OutcomeSelector({required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: CountersignatureOutcome.values.map((outcome) {
        final isSelected = outcome == selected;
        return GestureDetector(
          onTap: () => onChanged(outcome),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: isSelected
                  ? _outcomeColor(outcome).withValues(alpha: 0.08)
                  : Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isSelected
                    ? _outcomeColor(outcome)
                    : Colors.grey.shade300,
                width: isSelected ? 2 : 1,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  isSelected
                      ? Icons.radio_button_checked_rounded
                      : Icons.radio_button_unchecked_rounded,
                  color: isSelected
                      ? _outcomeColor(outcome)
                      : Colors.grey.shade400,
                  size: 22,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    outcome.label,
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      fontWeight:
                          isSelected ? FontWeight.w600 : FontWeight.normal,
                      color: isSelected
                          ? _outcomeColor(outcome)
                          : AppTheme.textDark,
                    ),
                  ),
                ),
                Icon(_outcomeIcon(outcome),
                    size: 20,
                    color: isSelected
                        ? _outcomeColor(outcome)
                        : Colors.grey.shade400),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Color _outcomeColor(CountersignatureOutcome outcome) => switch (outcome) {
        CountersignatureOutcome.approved => Colors.green.shade600,
        CountersignatureOutcome.approvedWithComments => Colors.blue.shade600,
        CountersignatureOutcome.requestedAmendment => Colors.orange.shade700,
      };

  IconData _outcomeIcon(CountersignatureOutcome outcome) => switch (outcome) {
        CountersignatureOutcome.approved => Icons.check_circle_rounded,
        CountersignatureOutcome.approvedWithComments =>
          Icons.check_circle_outline_rounded,
        CountersignatureOutcome.requestedAmendment => Icons.edit_note_rounded,
      };
}

// =============================================================================
// _CredentialConfirmDialog
// The second clinician authenticates using their own app credentials.
// This is the "meaningful two-person check" for local sign-off.
// =============================================================================
class _CredentialConfirmDialog extends StatefulWidget {
  const _CredentialConfirmDialog();

  @override
  State<_CredentialConfirmDialog> createState() =>
      _CredentialConfirmDialogState();
}

class _CredentialConfirmDialogState extends State<_CredentialConfirmDialog> {
  final _usernameCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _obscure = true;
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _usernameCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _authenticate() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    final result = await AuthService().login(
      username: _usernameCtrl.text.trim(),
      password: _passwordCtrl.text,
    );
    if (!mounted) return;
    if (result['success'] == true) {
      Navigator.pop(context, true);
    } else {
      setState(() {
        _loading = false;
        _error = result['message'] as String? ?? 'Authentication failed.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Row(
        children: [
          Icon(Icons.lock_rounded, color: AppTheme.primaryColor),
          const SizedBox(width: 10),
          Text(
            'Confirm identity',
            style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
          ),
        ],
      ),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Enter your own credentials to countersign this assessment.',
              style: GoogleFonts.inter(
                fontSize: 13,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _usernameCtrl,
              decoration: const InputDecoration(
                labelText: 'Username',
                prefixIcon: Icon(Icons.person_outline),
              ),
              validator: (v) =>
                  (v == null || v.isEmpty) ? 'Required' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _passwordCtrl,
              obscureText: _obscure,
              decoration: InputDecoration(
                labelText: 'Password',
                prefixIcon: const Icon(Icons.lock_outline),
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscure
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                  ),
                  onPressed: () => setState(() => _obscure = !_obscure),
                ),
              ),
              validator: (v) =>
                  (v == null || v.isEmpty) ? 'Required' : null,
            ),
            if (_error != null) ...[
              const SizedBox(height: 10),
              Text(
                _error!,
                style: const TextStyle(color: Colors.red, fontSize: 13),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _loading ? null : () => Navigator.pop(context, false),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _loading ? null : _authenticate,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.primaryColor,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: _loading
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Text('Confirm'),
        ),
      ],
    );
  }
}
