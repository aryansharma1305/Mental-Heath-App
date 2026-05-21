import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/consent_basis.dart';
import '../models/consent_record.dart';
import '../theme/app_theme.dart';

class ConsentGateScreen extends StatefulWidget {
  final String patientLabel;
  final String assessmentType;
  final String recordedBy;

  const ConsentGateScreen({
    super.key,
    required this.patientLabel,
    required this.assessmentType,
    required this.recordedBy,
  });

  @override
  State<ConsentGateScreen> createState() => _ConsentGateScreenState();
}

class _ConsentGateScreenState extends State<ConsentGateScreen> {
  final _formKey = GlobalKey<FormState>();
  final _notesController = TextEditingController();
  final _recordedByController = TextEditingController();
  ConsentBasis _basis = ConsentBasis.consentObtained;

  @override
  void initState() {
    super.initState();
    _recordedByController.text = widget.recordedBy;
  }

  @override
  void dispose() {
    _notesController.dispose();
    _recordedByController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isRefused = _basis == ConsentBasis.refused;

    return Scaffold(
      backgroundColor: const Color(0xFFF6F4EF),
      appBar: AppBar(
        title: const Text('Consent Recording'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: AppTheme.textDark,
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              _buildHeader(),
              const SizedBox(height: 20),
              RadioGroup<ConsentBasis>(
                groupValue: _basis,
                onChanged: (value) {
                  if (value != null) setState(() => _basis = value);
                },
                child: Column(
                  children: ConsentBasis.values
                      .map(_buildConsentOption)
                      .toList(),
                ),
              ),
              const SizedBox(height: 18),
              TextFormField(
                controller: _notesController,
                minLines: 3,
                maxLines: 6,
                decoration: InputDecoration(
                  labelText: isRefused
                      ? 'Refusal notes required'
                      : 'Consent notes optional',
                  hintText: 'Record clinical context and patient statement',
                  border: const OutlineInputBorder(),
                  filled: true,
                  fillColor: Colors.white,
                ),
                validator: (value) {
                  if (isRefused && (value == null || value.trim().isEmpty)) {
                    return 'Notes are required when consent is refused';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _recordedByController,
                decoration: const InputDecoration(
                  labelText: 'Recorded by',
                  border: OutlineInputBorder(),
                  filled: true,
                  fillColor: Colors.white,
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Recorded by is required';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),
              if (isRefused)
                FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: ConsentBasis.refused.color,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  onPressed: () => _submit(refused: true),
                  icon: const Icon(Icons.block),
                  label: const Text('Refused - Save and stop'),
                )
              else
                FilledButton.icon(
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  onPressed: () => _submit(refused: false),
                  icon: const Icon(Icons.arrow_forward),
                  label: const Text('Continue assessment'),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF17201A),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.assessmentType,
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Patient: ${widget.patientLabel}',
            style: GoogleFonts.inter(color: Colors.white70),
          ),
          const SizedBox(height: 12),
          Text(
            'Select the consent basis before collecting clinical assessment data.',
            style: GoogleFonts.inter(color: Colors.white70, height: 1.4),
          ),
        ],
      ),
    );
  }

  Widget _buildConsentOption(ConsentBasis basis) {
    final selected = _basis == basis;
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 10),
      color: selected ? basis.background : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(
          color: selected ? basis.color : Colors.transparent,
          width: 1.2,
        ),
      ),
      child: RadioListTile<ConsentBasis>(
        value: basis,
        title: Text(
          basis.label,
          style: GoogleFonts.inter(fontWeight: FontWeight.w700),
        ),
        activeColor: basis.color,
      ),
    );
  }

  void _submit({required bool refused}) {
    if (!_formKey.currentState!.validate()) return;
    final record = ConsentRecord(
      basis: _basis,
      notes: _notesController.text.trim().isEmpty
          ? null
          : _notesController.text.trim(),
      recordedAt: DateTime.now(),
      recordedBy: _recordedByController.text.trim(),
    );
    record.validate();
    Navigator.pop(context, record);
  }
}
